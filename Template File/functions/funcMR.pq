(sync as nullable logical, accessToken as text, endpoint as text, fromDate as number, toDate as number) as table =>
let
    from = if sync = true then "&syncFrom=" & Text.From(fromDate) else "&from=" & Text.From(fromDate),
    to = if sync = true then "&syncTo=" & Text.From(toDate) else "&to=" & Text.From(toDate),

    fullURL = endpoint & "?testTypeId=r4fhrkPdYlLxYQxEeM78" & from & to,
    Source2 = Json.Document(Web.Contents(fullURL, [Headers=[Authorization="Bearer " & accessToken]])),
    responseTable = Table.FromRecords({Source2}),

    // expand table from response
    expandTable = Table.ExpandListColumn(responseTable, "data"),

    // expand data columns
    expandTableData = Table.ExpandRecordColumn(expandTable, "data", {"id", "timestamp", "segment", "testType", "athlete", "Top 3 Jumps Avg. Jump Height(m)", "Total Contact Time(s)", "Top 5 Jumps Avg. Jump Height(m)", "Top 5 Jumps Avg. mRSI", "Number of Jumps(Count)", "Top 3 Jumps Avg. mRSI", "Top 5 Jumps Peak mRSI", "Top 5 Jumps Avg. RSI", "L|R Avg. Force(%)", "Top 3 Jumps Peak RSI", "Top 5 Jumps Peak RSI", "Top 3 Jumps Peak mRSI", "Peak Jump mRSI", "Top 3 Jumps Avg. RSI", "Peak Jump RSI", "Avg. RSI", "Avg. Jump Height(m)", "Peak Force(N)", "Avg. mRSI", "System Weight(N)", "L|R Peak Force(%)", "Peak Jump Height(m)", "Peak RSI", "Total Flight Time(s)", "Avg. Force(N)", "Peak mRSI"}, {"id", "timestamp", "segment", "testType", "athlete", "Top 3 Jumps Avg. Jump Height(m)", "Total Contact Time(s)", "Top 5 Jumps Avg. Jump Height(m)", "Top 5 Jumps Avg. mRSI", "Number of Jumps(Count)", "Top 3 Jumps Avg. mRSI", "Top 5 Jumps Peak mRSI", "Top 5 Jumps Avg. RSI", "L|R Avg. Force(%)", "Top 3 Jumps Peak RSI", "Top 5 Jumps Peak RSI", "Top 3 Jumps Peak mRSI", "Peak Jump mRSI", "Top 3 Jumps Avg. RSI", "Peak Jump RSI", "Avg. RSI", "Avg. Jump Height(m)", "Peak Force(N)", "Avg. mRSI", "System Weight(N)", "L|R Peak Force(%)", "Peak Jump Height(m)", "Peak RSI", "Total Flight Time(s)", "Avg. Force(N)", "Peak mRSI"}),

    // expand test data columns
    expandTestData = Table.ExpandRecordColumn(expandTableData, "testType", {"id", "name", "canonicalId", "tags"}, {"test.id", "test.name", "test.canonicalId", "test.tags"}),
	
	// expand testType tags data
    expandTestTypeTags = Table.ExpandListColumn(expandTestData, "test.tags"),
	
	// expand testTypeTags columns
    expandedTagsData = Table.ExpandRecordColumn(expandTestTypeTags, "test.tags", {"id", "name", "description"}, {"test.tags.id", "test.tags.name", "test.tags.description"}),

    // expand athlete data columns
    expandAthleteData = Table.ExpandRecordColumn(expandedTagsData, "athlete", {"id", "name", "active", "teams", "groups", "external"}, {"athlete.id", "athlete.name", "athlete.active", "athlete.teams", "athlete.groups", "athlete.external"}),

    // extract group data, comma seperated
    extractGroups = Table.TransformColumns(expandAthleteData, {"athlete.teams", each Text.Combine(List.Transform(_, Text.From), ","), type text}),

    // extract team data, comma seperated
    extractTeams = Table.TransformColumns(extractGroups, {"athlete.groups", each Text.Combine(List.Transform(_, Text.From), ","), type text}),

    // add date column
    addedDate = Table.AddColumn(extractTeams, "date", each DateTimeZone.ToLocal(DateTime.AddZone(#datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, 0, [timestamp]),0))),

    // change column formats
    changeType = Table.TransformColumnTypes(addedDate,{{"timestamp", Int64.Type}, {"lastSyncTime", Int64.Type}, {"lastTestTime", Int64.Type}, {"count", Int64.Type}, {"date", type date}, {"id", type text}, {"segment", type text}, {"test.id", type text}, {"test.name", type text}, {"test.canonicalId", type text}, {"test.tags.id", type text},{"test.tags.name", type text},{"test.tags.description", type text},{"athlete.id", type text}, {"athlete.name", type text}, {"athlete.teams", type text}, {"athlete.groups", type text}})
    
in
    changeType