(sync as nullable logical, accessToken as text, endpoint as text, fromDate as number, toDate as number) as table =>
let
    from = if sync = true then "&syncFrom=" & Text.From(fromDate) else "&from=" & Text.From(fromDate),
    to = if sync = true then "&syncTo=" & Text.From(toDate) else "&to=" & Text.From(toDate),

    fullURL = endpoint & "?testTypeId=4KlQgKmBxbOY6uKTLDFL" & from & to,
    Source2 = Json.Document(Web.Contents(fullURL, [Headers=[Authorization="Bearer " & accessToken]])),
    responseTable = Table.FromRecords({Source2}),

    // expand table
    expandTable = Table.ExpandListColumn(responseTable, "data"),

    // expand data columns
    expandTableData = Table.ExpandRecordColumn(expandTable, "data", {"id", "timestamp", "segment", "testType", "athlete", "Peak RFD(N/s)", "Duration(s)", "Peak Force(N)", "Pretension(N)", "Total Impulse(N.s)", "Avg. Force(N)", "active"}, {"id", "timestamp", "segment", "testType", "athlete", "Peak RFD(N/s)", "Duration(s)", "Peak Force(N)", "Pretension(N)", "Total Impulse(N.s)", "Avg. Force(N)", "active"}),

    // expand test data columns
    expandTestData = Table.ExpandRecordColumn(expandTableData, "testType", {"id", "name", "canonicalId"}, {"test.id", "test.name", "test.canonicalId"}),

    // expand athlete data columns
    expandAthleteData = Table.ExpandRecordColumn(expandTestData, "athlete", {"id", "name", "active", "teams", "groups", "external"}, {"athlete.id", "athlete.name", "athlete.active", "athlete.teams", "athlete.groups", "athlete.external"}),

    // extract group data, comma separated
    extractGroups = Table.TransformColumns(expandAthleteData, {"athlete.teams", each Text.Combine(List.Transform(_, Text.From), ","), type text}),

    // extract team data, comma separated
    extractTeams = Table.TransformColumns(extractGroups, {"athlete.groups", each Text.Combine(List.Transform(_, Text.From), ","), type text}),

    // add date column
    addedDate = Table.AddColumn(extractTeams, "date", each DateTimeZone.ToLocal(DateTime.AddZone(#datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, 0, [timestamp]),0))),

    // change column formats
    changeType = Table.TransformColumnTypes(addedDate,{{"timestamp", Int64.Type}, {"lastSyncTime", Int64.Type}, {"lastTestTime", Int64.Type}, {"count", Int64.Type}, {"date", type date}, {"id", type text}, {"segment", type text}, {"test.id", type text}, {"test.name", type text}, {"test.canonicalId", type text}, {"athlete.id", type text}, {"athlete.name", type text}, {"athlete.teams", type text}, {"athlete.groups", type text}, {"active", type logical}}),

    // reorder columns
    outputTable = Table.ReorderColumns(changeType,{"id", "active", "timestamp", "segment", "test.id", "test.name", "test.canonicalId", "athlete.id", "athlete.name", "athlete.active", "athlete.teams", "athlete.groups", "athlete.external", "Peak RFD(N/s)", "Duration(s)", "Peak Force(N)", "Pretension(N)", "Total Impulse(N.s)", "Avg. Force(N)", "count", "lastSyncTime", "lastTestTime", "date"})
in
    outputTable