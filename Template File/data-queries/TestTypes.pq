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

    endpoint = url & "test_types",

    Source2 = Json.Document(Web.Contents(endpoint, [Headers=[Authorization="Bearer " & accessToken]])),
    #"Converted to Table" = Table.FromList(Source2, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "name"}, {"id", "name"})
in
    #"Expanded Column1"