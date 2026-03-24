let
// Create variable for test type: TruStength Free Run
    testType = "4KlQgKmBxbOY6uKTLDFL",

/* -------------------------------------------------------------------------- */
/* USER CONFIGURATION SECTION                          */
/* INSTRUCTIONS: ONLY EDIT VALUES IN THIS SECTION                 */
/* -------------------------------------------------------------------------- */

    // 1. Integration Settings
    // !! ENTER YOUR INTEGRATION KEY HERE !!
    SecretKey = "YOUR_INTEGRATION_KEY",

    // 3. Organization Data
    // Enter OrgName if applicable. Leave blank (null) if not applicable.
    orgName = null,
    
    // Set Region. Options: "Americas", "Europe", "Asia/Pacific". 
    reg = "Americas",

    // 4. Date Filters
    // Start Date in Unix Timestamp. Leave as "" for no start date.
    startDate = "",
    // End Date in Unix Timestamp. Leave as "" for no end date.
    endDate = "",

/* -------------------------------------------------------------------------- */
/* STOP! DO NOT EDIT BELOW THIS LINE                     */
/* Editing below may break the API connection logic.              */
/* -------------------------------------------------------------------------- */

// first call to get access token
    // Region
    baseURL = if 
        reg = "Europe" then "https://eu.cloud.hawkindynamics.com/api/" else if
        reg = "Asia/Pacific" then "https://apac.cloud.hawkindynamics.com/api/" else
        "https://cloud.hawkindynamics.com/api/",

	// makes call to get access token
    Source = Json.Document(Web.Contents(baseURL & "token", [Headers=[Authorization="Bearer " & SecretKey]])),
    ResponseTable = Table.FromRecords({Source}),
    NewTable = Table.TransformColumnTypes(ResponseTable,{{"access_token", type text}, {"token_type", type text}, {"expires_at", Int64.Type}}),
    
	// extract access token from response table
    tokenList = NewTable[access_token],
    accessToken = Text.From(tokenList{0}),

// Second call for TS Free Run data

    // Set slug
    slug = if orgName = null then "v1" else orgName,

    // Combine optional parameters
    optionalParams = 
        (if startDate <> "" then "&startDate=" & startDate else "") &
        (if endDate <> "" then "&endDate=" & endDate else "") ,

    // Build URL
    url = baseURL & slug & "?testTypeId=" & testType & optionalParams,

    // Make call to get athlete data
    Source2 = Json.Document(Web.Contents(url, [Headers=[Authorization="Bearer " & accessToken]])),
    responseTable = Table.FromRecords({Source2}),

    // expand table from response
    expandTable = Table.ExpandListColumn(responseTable, "data"),

    // get all unique field names across all data records
    allFields = List.Distinct(
        List.Combine(
            List.Transform(
                expandTable[data],
                each if _ is record then Record.FieldNames(_) else {}
            )
        )
    ),

    // expand data columns dynamically
    expandData = Table.ExpandRecordColumn(expandTable, "data", allFields, allFields),

    // expand test data columns
    expandTestData = Table.ExpandRecordColumn(expandData, "testType", {"id", "name", "canonicalId", "tags"}, {"test.id", "test.name", "test.canonicalId", "test.tags"}),

    // extract test tags as comma-separated strings
    addTagIds = Table.AddColumn(expandTestData, "test.tags.id", each try Text.Combine(List.Transform([test.tags], each _[id]), ", ") otherwise null, type text),
    addTagNames = Table.AddColumn(addTagIds, "test.tags.name", each try Text.Combine(List.Transform([test.tags], each _[name]), ", ") otherwise null, type text),
    removeTagsList = Table.RemoveColumns(addTagNames, {"test.tags"}),

    // expand athlete data columns
    expandAthleteData = Table.ExpandRecordColumn(removeTagsList, "athlete", {"id", "name", "active", "teams", "groups", "external"}, {"athlete.id", "athlete.name", "athlete.active", "athlete.teams", "athlete.groups", "athlete.external"}),

    // extract team data, comma separated
    extractTeams = Table.TransformColumns(expandAthleteData, {"athlete.teams", each Text.Combine(List.Transform(_, Text.From), ","), type text}),

    // extract group data, comma separated
    extractGroups = Table.TransformColumns(extractTeams, {"athlete.groups", each Text.Combine(List.Transform(_, Text.From), ","), type text}),

    // add date column
    addedDate = Table.AddColumn(extractGroups, "date", each DateTimeZone.ToLocal(DateTime.AddZone(#datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, 0, [timestamp]),0))),

    // define known column types
    knownTypes = {{"timestamp", Int64.Type}, {"lastSyncTime", Int64.Type}, {"lastTestTime", Int64.Type}, {"count", Int64.Type}, {"date", type date}, {"id", type text}, {"segment", type text}, {"test.id", type text}, {"test.name", type text}, {"test.canonicalId", type text}, {"test.tags.id", type text}, {"test.tags.name", type text}, {"athlete.id", type text}, {"athlete.name", type text}, {"athlete.teams", type text}, {"athlete.groups", type text}, {"athlete.external", type any}, {"active", type logical}},
    knownNames = List.Transform(knownTypes, each _{0}),

    // type all remaining (metric) columns as number
    allColumns = Table.ColumnNames(addedDate),
    metricColumns = List.RemoveItems(allColumns, knownNames),
    metricTypes = List.Transform(metricColumns, each {_, type number}),

    // change column formats
    changeType = Table.TransformColumnTypes(addedDate, List.Combine({knownTypes, metricTypes})),

    // reorder columns: known prefix, then metrics alphabetically, then metadata
    prefixCols = {"id", "active", "timestamp", "segment", "test.id", "test.name", "test.canonicalId", "test.tags.id", "test.tags.name", "athlete.id", "athlete.name", "athlete.active", "athlete.teams", "athlete.groups", "athlete.external"},
    suffixCols = {"count", "lastSyncTime", "lastTestTime", "date"},
    sortedMetrics = List.Sort(metricColumns, Order.Ascending),
    reorderList = List.Combine({prefixCols, sortedMetrics, suffixCols}),
    // only reorder columns that actually exist in the table
    validReorder = List.Intersect({reorderList, allColumns}),
    outputTable = Table.ReorderColumns(changeType, validReorder)
in
    outputTable