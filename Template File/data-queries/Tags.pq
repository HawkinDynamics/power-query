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

    endpoint = url & "tags",

    output = funcTags(accessToken, endpoint)
in
    output
