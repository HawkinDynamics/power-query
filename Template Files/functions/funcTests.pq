(
    accessToken as text,
    endpoint as text,
    testTypeId as text,
    optional fromDate as nullable number,
    optional toDate as nullable number,
    optional includeInactive as nullable logical,
    optional includeEid as nullable logical
) as table =>
    let
        // Optional time-window params — only emitted when the caller passes a value.
        // Default behavior (no from/to) returns every test in the org via cursor pagination.
        fromParam = if fromDate <> null then "&from=" & Text.From(fromDate) else "",
        toParam = if toDate <> null then "&to=" & Text.From(toDate) else "",
        // Optional flags. The API defaults includeInactive=true and includeEid=false,
        // so we only emit a query param when the caller wants the non-default behavior.
        inactiveParam = if includeInactive = false then "&includeInactive=false" else "",
        eidParam = if includeEid = true then "&includeEid=true" else "",
        // Build base URL with paginate=true (responses are capped at 1,000 records / page)
        baseQueryURL = endpoint
            & "?testTypeId="
            & testTypeId
            & fromParam
            & toParam
            & inactiveParam
            & eidParam
            & "&paginate=true",
        // Cursor-based pagination loop. On each iteration we read the previous page's
        // nextCursor; null means we've exhausted the result set.
        allPages = List.Generate(
            () =>
                [
                    response = Json.Document(
                        Web.Contents(baseQueryURL, [
                            Headers = [Authorization = "Bearer " & accessToken]
                        ])
                    )
                ],
            each _[response] <> null,
            each
                let
                    cursor = try _[response][nextCursor] otherwise null
                in
                    if cursor = null then
                        [response = null]
                    else
                        [
                            response = Json.Document(
                                Web.Contents(
                                    baseQueryURL & "&cursor=" & cursor,
                                    [
                                        Headers = [Authorization = "Bearer " & accessToken]
                                    ]
                                )
                            )
                        ],
            each _[response]
        ),
        // Concatenate page data and roll up envelope metadata from the final page
        combinedData = List.Combine(List.Transform(allPages, each _[data])),
        lastPage = List.Last(allPages),
        combinedResponse = [
            data = combinedData,
            lastSyncTime = try lastPage[lastSyncTime] otherwise null,
            lastTestTime = try lastPage[lastTestTime] otherwise null,
            count = List.Count(combinedData)
        ],
        responseTable = Table.FromRecords({combinedResponse}),
        // expand table from response
        expandTable = Table.ExpandListColumn(responseTable, "data"),
        // get all unique field names across all data records
        allFields = List.Distinct(
            List.Combine(List.Transform(expandTable[data], each if _ is record then Record.FieldNames(_) else {}))
        ),
        // if no data returned, return an empty table
        outputTable =
            if List.IsEmpty(allFields) then
                #table({}, {})
            else
                let
                    // expand data columns dynamically
                    expandData = Table.ExpandRecordColumn(expandTable, "data", allFields, allFields),
                    // expand test data columns
                    expandTestData = Table.ExpandRecordColumn(
                        expandData,
                        "testType",
                        {"id", "name", "canonicalId", "tags"},
                        {"test.id", "test.name", "test.canonicalId", "test.tags"}
                    ),
                    // extract test tags as comma-separated strings
                    addTagIds = Table.AddColumn(
                        expandTestData,
                        "test.tags.id",
                        each try Text.Combine(List.Transform([test.tags], each _[id]), ", ") otherwise null,
                        type text
                    ),
                    addTagNames = Table.AddColumn(
                        addTagIds,
                        "test.tags.name",
                        each try Text.Combine(List.Transform([test.tags], each _[name]), ", ") otherwise null,
                        type text
                    ),
                    removeTagsList = Table.RemoveColumns(addTagNames, {"test.tags"}),
                    // expand athlete data columns
                    expandAthleteData = Table.ExpandRecordColumn(
                        removeTagsList,
                        "athlete",
                        {"id", "name", "active", "teams", "groups", "external"},
                        {
                            "athlete.id",
                            "athlete.name",
                            "athlete.active",
                            "athlete.teams",
                            "athlete.groups",
                            "athlete.external"
                        }
                    ),
                    // extract team data, comma separated
                    extractTeams = Table.TransformColumns(
                        expandAthleteData,
                        {"athlete.teams", each Text.Combine(List.Transform(_, Text.From), ","), type text}
                    ),
                    // extract group data, comma separated
                    extractGroups = Table.TransformColumns(
                        extractTeams,
                        {"athlete.groups", each Text.Combine(List.Transform(_, Text.From), ","), type text}
                    ),
                    // add date column
                    addedDate = Table.AddColumn(
                        extractGroups,
                        "date",
                        each
                            DateTimeZone.ToLocal(
                                DateTime.AddZone(#datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, 0, [timestamp]), 0)
                            )
                    ),
                    // Ensure the top-level `active` column exists. The API only emits this
                    // field on each test record when includeInactive=true is sent; for the
                    // default (active-only) pull every returned test is active by definition,
                    // so we synthesize the column as a sanity-check passthrough.
                    withActive =
                        if List.Contains(Table.ColumnNames(addedDate), "active") then
                            addedDate
                        else
                            Table.AddColumn(addedDate, "active", each true, type logical),
                    // define known column types
                    knownTypes = {
                        {"timestamp", Int64.Type},
                        {"lastSyncTime", Int64.Type},
                        {"lastTestTime", Int64.Type},
                        {"count", Int64.Type},
                        {"date", type date},
                        {"id", type text},
                        {"segment", type text},
                        {"eid", type text},
                        {"test.id", type text},
                        {"test.name", type text},
                        {"test.canonicalId", type text},
                        {"test.tags.id", type text},
                        {"test.tags.name", type text},
                        {"athlete.id", type text},
                        {"athlete.name", type text},
                        {"athlete.teams", type text},
                        {"athlete.groups", type text},
                        {"athlete.external", type any},
                        {"active", type logical}
                    },
                    knownNames = List.Transform(knownTypes, each _{0}),
                    // type all remaining (metric) columns as number
                    allColumns = Table.ColumnNames(withActive),
                    metricColumns = List.RemoveItems(allColumns, knownNames),
                    metricTypes = List.Transform(metricColumns, each {_, type number}),
                    // Drop entries from knownTypes whose column isn't actually present
                    // in the dataset. eid is only returned when includeEid=true,
                    // so referencing it unconditionally would error in the default case.
                    existingKnownTypes = List.Select(knownTypes, each List.Contains(allColumns, _{0})),
                    // change column formats
                    changeType = Table.TransformColumnTypes(
                        withActive, List.Combine({existingKnownTypes, metricTypes})
                    ),
                    // reorder columns: known prefix, then metrics alphabetically, then metadata
                    prefixCols = {
                        "id",
                        "active",
                        "timestamp",
                        "segment",
                        "eid",
                        "test.id",
                        "test.name",
                        "test.canonicalId",
                        "test.tags.id",
                        "test.tags.name",
                        "athlete.id",
                        "athlete.name",
                        "athlete.active",
                        "athlete.teams",
                        "athlete.groups",
                        "athlete.external"
                    },
                    suffixCols = {"count", "lastSyncTime", "lastTestTime", "date"},
                    sortedMetrics = List.Sort(metricColumns, Order.Ascending),
                    reorderList = List.Combine({prefixCols, sortedMetrics, suffixCols}),
                    // only reorder columns that actually exist in the table
                    validReorder = List.Intersect({reorderList, allColumns}),
                    result = Table.ReorderColumns(changeType, validReorder)
                in
                    result
    in
        outputTable
