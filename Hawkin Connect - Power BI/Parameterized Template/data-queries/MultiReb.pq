let

    // Current Auth Info
    currentAuth = Auth,

    // Get Expiration
    expiration = currentAuth{0}[expires_at],
    // Current date time
    currentDT = epochNow(false),
    // Validate
    validated = if expiration > currentDT then currentAuth else funcAuth(),
    
	// extract access token from response table
    accessToken = Text.From(validated{0}[access_token]),
    // === Parameters ===
    
    orgStartDate = DateTimeZone.From(#"Organization Start Date"),  // Replace with your actual parameter
    endpoint = currentAuth{0}[url], // Replace or parameterize
    sync = false,                                  // Optional: true if doing a sync call
    testTypeId = "r4fhrkPdYlLxYQxEeM78",

    // === Current DateTime and Epoch Conversion ===
    now = DateTimeZone.UtcNow(),
    startEpoch = Duration.TotalSeconds(orgStartDate - #datetimezone(1970, 1, 1, 0, 0, 0, 0, 0)),
    endEpoch = Duration.TotalSeconds(now - #datetimezone(1970, 1, 1, 0, 0, 0, 0, 0)),

    // === Generate List of 30-Day Epoch Ranges ===
    stepSize = 60 * 60 * 24 * 30, // 30 days in seconds
    rangeList = List.Generate(
        () => startEpoch,
        each _ < endEpoch,
        each _ + stepSize
    ),

    // Create list of [from, to] epoch pairs
    epochPairs = List.Transform(
        rangeList,
        each {_, if (_ + stepSize) < endEpoch then (_ + stepSize) else endEpoch}
    ),

    // === Call funcsCMJ for Each Pair ===
    callFunc = List.Transform(epochPairs, each @funcTests(sync, accessToken, endpoint, _{0}, _{1}, testTypeId)),

    // === Combine All Tables ===
    combined = Table.Combine(callFunc),
    #"Filtered Rows" = Table.SelectRows(combined, each ([id] <> null))
in
    #"Filtered Rows"