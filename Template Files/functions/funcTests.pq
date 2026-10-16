(
    accessToken as text,
    reg as nullable text,
    org as nullable text,
    testTypeId as text,
    optional fromDate as nullable number,
    optional toDate as nullable number,
    optional includeInactive as nullable logical,
    optional includeEid as nullable logical,
    optional useNulls as nullable logical,
    optional rounding as nullable logical,
    optional nestMetrics as nullable logical
) as table =>
    let
        // Query parameters travel in the Query record instead of being appended
        // to the URL. Building them into the URL string made this a dynamic data
        // source, which blocks scheduled refresh in the Power BI service --
        // funcGet carries the full explanation.
        //
        // Optional params are emitted only for non-default behavior, matching
        // the previous string-building logic: the API defaults includeInactive
        // to true and includeEid to false, and omitting from/to returns every
        // test of this type via pagination.
        baseQuery = [testTypeId = testTypeId, paginate = "true"],
        withFrom =
            if fromDate <> null then
                Record.AddField(baseQuery, "from", Text.From(Int64.From(fromDate)))
            else
                baseQuery,
        withTo =
            if toDate <> null then
                Record.AddField(withFrom, "to", Text.From(Int64.From(toDate)))
            else
                withFrom,
        withInactive =
            if includeInactive = false then
                Record.AddField(withTo, "includeInactive", "false")
            else
                withTo,
        withEid =
            if includeEid = true then
                Record.AddField(withInactive, "includeEid", "true")
            else
                withInactive,

        // Response-shape overrides (API v1.16) for customers migrating from a
        // legacy named endpoint. Only the non-default value is emitted.
        withUseNulls =
            if useNulls = false then
                Record.AddField(withEid, "useNulls", "false")
            else
                withEid,
        withRounding =
            if rounding = true then
                Record.AddField(withUseNulls, "rounding", "true")
            else
                withUseNulls,
        query =
            if nestMetrics = true then
                Record.AddField(withRounding, "nestMetrics", "true")
            else
                withRounding,

        // Tests live at the versioned root itself (GET /api/v1), not a subpath.
        relPath = funcOrgPath(org),

        // Cursor-based pagination loop. On each iteration we read the previous
        // page's nextCursor; null means the result set is exhausted. The cursor
        // goes into the Query record so every page still hits the same static
        // base URL. The API requires all other params to stay identical across a
        // pagination sequence, which deriving each page from `query` guarantees.
        allPages = List.Generate(
            () => [response = Json.Document(funcGet(reg, relPath, query, accessToken))],
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
                                funcGet(
                                    reg,
                                    relPath,
                                    Record.AddField(query, "cursor", cursor),
                                    accessToken
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
                    // nestMetrics = true (API v1.16): each record carries a `metrics` list
                    // instead of flat metric fields. Expand it to one row per test x metric.
                    // An empty list is padded with a single null so the test keeps a row.
                    hasNested = List.Contains(allFields, "metrics"),
                    padMetrics =
                        if hasNested then
                            Table.TransformColumns(
                                expandData,
                                {"metrics", each if _ = null or List.IsEmpty(_) then {null} else _}
                            )
                        else
                            expandData,
                    expandMetricsList =
                        if hasNested then Table.ExpandListColumn(padMetrics, "metrics") else padMetrics,
                    expandMetrics =
                        if hasNested then
                            Table.ExpandRecordColumn(
                                expandMetricsList,
                                "metrics",
                                {"metricId", "metricLabel", "metricUnits", "metricValue"},
                                {"metric.id", "metric.label", "metric.units", "metric.value"}
                            )
                        else
                            expandMetricsList,
                    // expand test data columns
                    expandTestData = Table.ExpandRecordColumn(
                        expandMetrics,
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
                        {"active", type logical},
                        {"metric.id", type text},
                        {"metric.label", type text},
                        {"metric.units", type text},
                        {"metric.value", type number}
                    },
                    knownNames = List.Transform(knownTypes, each _{0}),
                    // type all remaining (metric) columns as number. With useNulls = false the
                    // API returns the string "N/A" for non-calculable metrics, so leave those
                    // columns untyped.
                    allColumns = Table.ColumnNames(withActive),
                    metricColumns = List.RemoveItems(allColumns, knownNames),
                    metricTypes = List.Transform(
                        metricColumns, each {_, if useNulls = false then type any else type number}
                    ),
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
                        "athlete.external",
                        "metric.id",
                        "metric.label",
                        "metric.units",
                        "metric.value"
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
