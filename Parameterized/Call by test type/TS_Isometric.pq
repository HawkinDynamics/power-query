/* -------------------------------------------------------------------------- */
/* The script assumes you have already created the following parameters:      */
/* secretKey, orgName, region                                                 */
/*                                                                            */
/* Ensure you have created these parameters before running this script.       */
/* -------------------------------------------------------------------------- */

let
/* -------------------------------------------------------------------------- */
/* USER CONFIGURATION SECTION                                                 */
/* INSTRUCTIONS: ONLY EDIT VALUES IN THIS SECTION                             */
/* -------------------------------------------------------------------------- */

    // Date Filters -----
    // Start Date in Unix Timestamp. Leave as "" for no start date.
    startDate = "",
    // End Date in Unix Timestamp. Leave as "" for no end date.
    endDate = "",

/* -------------------------------------------------------------------------- */
/* STOP! DO NOT EDIT BELOW THIS LINE                                          */
/* Editing below may break the API connection logic.                          */
/* -------------------------------------------------------------------------- */

// Create variable for test type: TruStength Isometric Tests
    testType = "umnEZPgi6zaxuw0KhUpM",

// first call to get access token
    // Region
    baseURL = if 
        region = "Europe" then "https://eu.cloud.hawkindynamics.com/api/" else if
        region = "Asia/Pacific" then "https://apac.cloud.hawkindynamics.com/api/" else
        "https://cloud.hawkindynamics.com/api/",

	// makes call to get access token
    Source = Json.Document(Web.Contents(baseURL & "token", [Headers=[Authorization="Bearer " & secretKey]])),
    ResponseTable = Table.FromRecords({Source}),
    NewTable = Table.TransformColumnTypes(ResponseTable,{{"access_token", type text}, {"token_type", type text}, {"expires_at", Int64.Type}}),
    
	// extract access token from response table
    tokenList = NewTable[access_token],
    accessToken = Text.From(tokenList{0}),

// Second call for TS Isometric Test data

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

    // expand table
    expandTable = Table.ExpandListColumn(responseTable, "data"),

    // expand data columns
    expandTableData = Table.ExpandRecordColumn(expandTable, "data", {"id", "timestamp", "segment", "testType", "athlete", "Peak RFD(N/s)", "Duration(s)", "Peak Force(N)", "Pretension(N)", "Total Impulse(N.s)", "Avg. Force(N)", "active"}, {"id", "timestamp", "segment", "testType", "athlete", "Peak RFD(N/s)", "Duration(s)", "Peak Force(N)", "Pretension(N)", "Total Impulse(N.s)", "Avg. Force(N)", "active"}),

    // expand test data columns
    expandTestData = Table.ExpandRecordColumn(expandTableData, "testType", {"id", "name", "canonicalId"}, {"test.id", "test.name", "test.canonicalId"}),

    // expand athlete data columns
    expandAthleteData = Table.ExpandRecordColumn(expandTestData, "athlete", {"id", "name", "active", "teams", "groups", "external"}, {"athlete.id", "athlete.name", "athlete.active", "athlete.teams", "athlete.groups", "athlete.external"}),

    // extract group data, comma seperated
    extractGroups = Table.TransformColumns(expandAthleteData, {"athlete.teams", each Text.Combine(List.Transform(_, Text.From), ","), type text}),

    // extract team data, comma seperated
    extractTeams = Table.TransformColumns(extractGroups, {"athlete.groups", each Text.Combine(List.Transform(_, Text.From), ","), type text}),

    // add date column
    addedDate = Table.AddColumn(extractTeams, "date", each DateTimeZone.ToLocal(DateTime.AddZone(#datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, 0, [timestamp]),0))),

    // change column formats
    changeType = Table.TransformColumnTypes(addedDate,{{"timestamp", Int64.Type}, {"lastSyncTime", Int64.Type}, {"lastTestTime", Int64.Type}, {"count", Int64.Type}, {"date", type date}, {"id", type text}, {"segment", type text}, {"test.id", type text}, {"test.name", type text}, {"test.canonicalId", type text}, {"athlete.id", type text}, {"athlete.name", type text}, {"athlete.teams", type text}, {"athlete.groups", type text}, {"active", type logical}}),

    // reorder columns
    outputTable = Table.ReorderColumns(changeType,{"id", "active", "timestamp", "segment", "test.id", "test.name", "test.canonicalId", "athlete.id", "athlete.name", "athlete.active", "athlete.teams", "athlete.groups", "athlete.external", "Peak RFD(N/s)", "Duration(s)", "Peak Force(N)", "Pretension(N)", "Total Impulse(N.s)", "Avg. Force(N)", "count", "lastSyncTime", "lastTestTime", "date"})
in
    outputTable
