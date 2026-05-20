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
    // Base URL (built by funcAuth from API Region + Organization Name)
    url = Text.From(validated{0}[url]),
    // === Test ID ===
    // Replace this placeholder with the test ID whose waveform you want.
    // Test IDs come from the `id` field on Get Tests responses.
    testId = #"Test ID",
    endpoint = url & "/forcetime",
    output = funcForceTime(accessToken, endpoint, testId)
in
    output
