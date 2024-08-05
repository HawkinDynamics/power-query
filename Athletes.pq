let
// first call to get access token
	// enter your integration key here
	SecretKey = "YOUR_INTEGRATION_KEY",
	
	// makes call to get access token
    Source = Json.Document(Web.Contents(" https://cloud.hawkindynamics.com/api/token", [Headers=[Authorization="Bearer " & SecretKey]])),
    ResponseTable = Table.FromRecords({Source}),
    NewTable = Table.TransformColumnTypes(ResponseTable,{{"access_token", type text}, {"token_type", type text}, {"expires_at", Int64.Type}}),
    
	// extract access token from response table
    tokenList = NewTable[access_token],
    accessToken = Text.From(tokenList{0}),

// second call for roster data
    Source2 = Json.Document(Web.Contents("https://cloud.hawkindynamics.com/api/dev/athletes", [Headers=[Authorization="Bearer " & accessToken]])),
    responseTable = Table.FromRecords({Source2}),

    // expand table from response
    expandTable = Table.ExpandListColumn(responseTable, "data"),

    // expand data columns
    expanData = Table.ExpandRecordColumn(expandTable, "data", {"id", "name", "active", "teams", "groups", "external"}, {"id", "name", "active", "teams", "groups", "external"}),

    // extract teams
    extractTeams = Table.TransformColumns(expanData, {"teams", each Text.Combine(List.Transform(_, Text.From), ","), type text}),
    
    // extract groups
    extractGroups = Table.TransformColumns(extractTeams, {"groups", each Text.Combine(List.Transform(_, Text.From), ","), type text}),

    // format column  data types
    outputTable = Table.TransformColumnTypes(extractGroups,{{"id", type text}, {"name", type text}, {"teams", type text}, {"groups", type text}, {"active", type logical}, {"count", Int64.Type}})

in
    outputTable