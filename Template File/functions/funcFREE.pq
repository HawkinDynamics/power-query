(sync as nullable logical, accessToken as text, endpoint as text, fromDate as number, toDate as number) as table =>
let
    from = if sync = true then "&syncFrom=" & Text.From(fromDate) else "&from=" & Text.From(fromDate),
    to = if sync = true then "&syncTo=" & Text.From(toDate) else "&to=" & Text.From(toDate),

    fullURL = endpoint & "?testTypeId=5pRSUQVSJVnxijpPMck3" & from & to,
    Source2 = Json.Document(Web.Contents(fullURL, [Headers=[Authorization="Bearer " & accessToken]])),
    responseTable = Table.FromRecords({Source2}),

    // expand table from response
    expandTable = Table.ExpandListColumn(responseTable, "data"),

    // expand data columns
    expandData = Table.ExpandRecordColumn(expandTable, "data", {"id", "timestamp", "segment", "testType", "athlete", "L|R Avg. Force(%)", "Peak Right Force(N)", "Avg. Right Force(N)", "Peak Left Force(N)", "SD Left Force(N)", "Peak Force(N)", "L|R Peak Force(%)", "SD Right Force(N)", "Avg. Left Force(N)", "SD Total Force(N)", "Avg. Force(N)", "active"}, {"id", "timestamp", "segment", "testType", "athlete", "L|R Avg. Force(%)", "Peak Right Force(N)", "Avg. Right Force(N)", "Peak Left Force(N)", "SD Left Force(N)", "Peak Force(N)", "L|R Peak Force(%)", "SD Right Force(N)", "Avg. Left Force(N)", "SD Total Force(N)", "Avg. Force(N)", "active"}),
    
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

    // change column formats
    changeType = Table.TransformColumnTypes(addedDate,{{"timestamp", Int64.Type}, {"lastSyncTime", Int64.Type}, {"lastTestTime", Int64.Type}, {"count", Int64.Type}, {"date", type date}, {"id", type text}, {"segment", type text}, {"test.id", type text}, {"test.name", type text}, {"test.canonicalId", type text}, {"athlete.id", type text}, {"athlete.name", type text}, {"athlete.teams", type text}, {"athlete.groups", type text}, {"active", type logical}}),

    // reorder columns
    outputTable = Table.ReorderColumns(changeType,{"id", "active", "timestamp", "segment", "test.id", "test.name", "test.canonicalId", "athlete.id", "athlete.name", "athlete.active", "athlete.teams", "athlete.groups", "L|R Avg. Force(%)", "Peak Right Force(N)", "Avg. Right Force(N)", "Peak Left Force(N)", "SD Left Force(N)", "Peak Force(N)", "L|R Peak Force(%)", "SD Right Force(N)", "Avg. Left Force(N)", "SD Total Force(N)", "Avg. Force(N)", "count", "lastSyncTime", "lastTestTime", "date"})
in
    outputTable