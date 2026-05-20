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
    // Base URL
    url = Text.From(validated{0}[url]),
    endpoint = url & "/athletes",
    // Optional: include inactive athletes (PBI parameter, default false)
    include_inactive_athletes = #"Include Inactive Athletes",
    output = funcAthletes(accessToken, endpoint, include_inactive_athletes),
    #"Removed Columns" = Table.RemoveColumns(output, {"count"})
in
    #"Removed Columns"
