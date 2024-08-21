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
    Source2 = Json.Document(Web.Contents("https://cloud.hawkindynamics.com/api/dev/test_types", [Headers=[Authorization="Bearer " & accessToken]])),
    
    // Convert JSON list of records to table
    RecordList = Source2,
    ConvertedTable = Table.FromList(RecordList, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    
    // Expand the records into columns
    ExpandedTable = Table.ExpandRecordColumn(ConvertedTable, "Column1", Record.FieldNames(RecordList{0}))
in
    ExpandedTable
