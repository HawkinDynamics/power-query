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

// Create variable for test type
    testType = "r4fhrkPdYlLxYQxEeM78",

// second call for Multi Rebound data
    Source2 = Json.Document(Web.Contents("https://cloud.hawkindynamics.com/api/dev?" & "testTypeId=" & testType, [Headers=[Authorization="Bearer " & accessToken]])),
    responseTable = Table.FromRecords({Source2}),

    // expand table from responce
    expandTable = Table.ExpandListColumn(responseTable, "data"),

    // expand data columns
    expandData = Table.ExpandRecordColumn(expandTable, "data", {"id", "timestamp", "segment", "testType", "athlete", "Top 3 Jumps Avg. Jump Height(m)", "Total Contact Time(s)", "Top 5 Jumps Avg. Jump Height(m)", "Top 5 Jumps Avg. mRSI", "Number of Jumps(Count)", "Top 3 Jumps Avg. mRSI", "Top 5 Jumps Peak mRSI", "Top 5 Jumps Avg. RSI", "L|R Avg. Force(%)", "Top 3 Jumps Peak RSI", "Top 5 Jumps Peak RSI", "Top 3 Jumps Peak mRSI", "Peak Jump mRSI", "Top 3 Jumps Avg. RSI", "Peak Jump RSI", "Avg. RSI", "Avg. Jump Height(m)", "Peak Force(N)", "Avg. mRSI", "System Weight(N)", "L|R Peak Force(%)", "Peak Jump Height(m)", "Peak RSI", "Total Flight Time(s)", "Avg. Force(N)", "Peak mRSI", "active"}, {"id", "timestamp", "segment", "testType", "athlete", "Top 3 Jumps Avg. Jump Height(m)", "Total Contact Time(s)", "Top 5 Jumps Avg. Jump Height(m)", "Top 5 Jumps Avg. mRSI", "Number of Jumps(Count)", "Top 3 Jumps Avg. mRSI", "Top 5 Jumps Peak mRSI", "Top 5 Jumps Avg. RSI", "L|R Avg. Force(%)", "Top 3 Jumps Peak RSI", "Top 5 Jumps Peak RSI", "Top 3 Jumps Peak mRSI", "Peak Jump mRSI", "Top 3 Jumps Avg. RSI", "Peak Jump RSI", "Avg. RSI", "Avg. Jump Height(m)", "Peak Force(N)", "Avg. mRSI", "System Weight(N)", "L|R Peak Force(%)", "Peak Jump Height(m)", "Peak RSI", "Total Flight Time(s)", "Avg. Force(N)", "Peak mRSI", "active"}),
    
    // Expand test type data
    expandTestData = Table.ExpandRecordColumn(expandData, "testType", {"id", "name", "canonicalId"}, {"test.id", "test.name", "test.canonicalId"}),
    
    // Expand athlete data
    expandAthleteData = Table.ExpandRecordColumn(expandTestData, "athlete", {"id", "name", "active", "teams", "groups"}, {"athlete.id", "athlete.name", "athlete.active", "athlete.teams", "athlete.groups"}),
    
    // extract athlete teams
    extractTeams = Table.TransformColumns(expandAthleteData, {"athlete.teams", each Text.Combine(List.Transform(_, Text.From), ","), type text}),
    
    // extract athlete groups
    extractGroups = Table.TransformColumns(extractTeams, {"athlete.groups", each Text.Combine(List.Transform(_, Text.From), ","), type text}),
    
    // add date column
    addedDate = Table.AddColumn(extractGroups, "date", each DateTimeZone.ToLocal(DateTime.AddZone(#datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, 0, [timestamp]),0))),

    // chane column formats
    changeType = Table.TransformColumnTypes(addedDate,{{"timestamp", Int64.Type}, {"lastSyncTime", Int64.Type}, {"lastTestTime", Int64.Type}, {"count", Int64.Type}, {"date", type date}, {"id", type text}, {"segment", type text}, {"test.id", type text}, {"test.name", type text}, {"test.canonicalId", type text}, {"athlete.id", type text}, {"athlete.name", type text}, {"athlete.teams", type text}, {"athlete.groups", type text}, {"active", type logical}}),

    // reorder columns
    outputTable = Table.ReorderColumns(changeType,{"id", "active", "timestamp", "segment", "test.id", "test.name", "test.canonicalId", "athlete.id", "athlete.name", "athlete.active", "athlete.teams", "athlete.groups", "Top 3 Jumps Avg. Jump Height(m)", "Total Contact Time(s)", "Top 5 Jumps Avg. Jump Height(m)", "Top 5 Jumps Avg. mRSI", "Number of Jumps(Count)", "Top 3 Jumps Avg. mRSI", "Top 5 Jumps Peak mRSI", "Top 5 Jumps Avg. RSI", "L|R Avg. Force(%)", "Top 3 Jumps Peak RSI", "Top 5 Jumps Peak RSI", "Top 3 Jumps Peak mRSI", "Peak Jump mRSI", "Top 3 Jumps Avg. RSI", "Peak Jump RSI", "Avg. RSI", "Avg. Jump Height(m)", "Peak Force(N)", "Avg. mRSI", "System Weight(N)", "L|R Peak Force(%)", "Peak Jump Height(m)", "Peak RSI", "Total Flight Time(s)", "Avg. Force(N)", "Peak mRSI", "count", "lastSyncTime", "lastTestTime", "date"})
in
    outputTable