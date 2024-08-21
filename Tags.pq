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

// second call for group data
    Source2 = Json.Document(Web.Contents("https://cloud.hawkindynamics.com/api/dev/tags", [Headers=[Authorization="Bearer " & accessToken]])),
    responseTable = Table.FromRecords({Source2}),

    // expand table from response
    expandTable = Table.ExpandListColumn(responseTable, "data"),

    // expand data from columns
    expandData = Table.ExpandRecordColumn(expandTable, "data", {"id", "name", "description"}, {"id", "name", "description"}),

    // format columns for data type
    outputTable = Table.TransformColumnTypes(expandData,{{"id", type text}, {"name", type text}, {"description", type text}})

in
    outputTable
