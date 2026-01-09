let
// Create variable for test type: Isometric Tests
    testType = "2uS5XD5kXmWgIZ5HhQ3A",

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

// Second call for Isometric Tests data

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

    // expand data columns from table
    expandData = Table.ExpandRecordColumn(expandTable, "data", {"id", "timestamp", "segment", "testType", "athlete", "Time to Peak Force(s)", "Relative Force at 50 ms (BW)(N/kg)", "Relative Force at 250 ms (BW)(N/kg)", "Net Force at 100 ms(N)", "Relative Force at 150 ms (BW)(N/kg)", "RFD 0-150 ms(N/s)", "Right Force at 200 ms(N)", "Right Force at 0 ms(N)", "Relative Force at 150 ms(%)", "Left Force at 0 ms(N)", "Left Force at 100 ms(N)", "Impulse 0-100ms(N.s)", "Force at 50 ms(N)", "Force at 200 ms(N)", "RFD 0-100 ms(N/s)", "Net Impulse 0-250ms(N.s)", "Length of Pull(s)", "Net Force at 50 ms(N)", "Impulse 0-50ms(N.s)", "Initiation Threshold(N)", "Right Force at 250 ms(N)", "Relative Force at 100 ms(%)", "L|R Peak Force(%)", "Relative Force at 0 ms(%)", "Left Force at 200 ms(N)", "Force at 150 ms(N)", "Right Peak Force(N)", "Left Force at 250 ms(N)", "Net Impulse 0-200ms(N.s)", "Impulse 0-150ms(N.s)", "Net Force at 250 ms(N)", "RFD 0-50 ms(N/s)", "Force at 0 ms(N)", "Relative Force at 50 ms(%)", "Net Force at 200 ms(N)", "RFD 0-250 ms(N/s)", "Right Force at 100 ms(N)", "Relative Force at 250 ms(%)", "Impulse 0-200ms(N.s)", "Force at 100 ms(N)", "Relative Force at 200 ms(%)", "RFD 0-200 ms(N/s)", "Left Peak Force(N)", "Net Impulse 0-150ms(N.s)", "Relative Peak Force (BW)(N/kg)", "Net Peak Force(N)", "Peak Force(N)", "Relative Force at 200 ms (BW)(N/kg)", "Relative Peak Force(%)", "Relative Force at 0 ms (BW)(N/kg)", "Right Force at 150 ms(N)", "Force at 250 ms(N)", "Net Impulse 0-50ms(N.s)", "Relative Force at 100 ms (BW)(N/kg)", "Left Force at 50 ms(N)", "Left Force at 150 ms(N)", "Impulse 0-250ms(N.s)", "Right Force at 50 ms(N)", "Net Impulse 0-100ms(N.s)", "Net Force at 150 ms(N)", "System Weight(N)", "Net Force at 0 ms(N)", "active"}, {"id", "timestamp", "segment", "testType", "athlete", "Time to Peak Force(s)", "Relative Force at 50 ms (BW)(N/kg)", "Relative Force at 250 ms (BW)(N/kg)", "Net Force at 100 ms(N)", "Relative Force at 150 ms (BW)(N/kg)", "RFD 0-150 ms(N/s)", "Right Force at 200 ms(N)", "Right Force at 0 ms(N)", "Relative Force at 150 ms(%)", "Left Force at 0 ms(N)", "Left Force at 100 ms(N)", "Impulse 0-100ms(N.s)", "Force at 50 ms(N)", "Force at 200 ms(N)", "RFD 0-100 ms(N/s)", "Net Impulse 0-250ms(N.s)", "Length of Pull(s)", "Net Force at 50 ms(N)", "Impulse 0-50ms(N.s)", "Initiation Threshold(N)", "Right Force at 250 ms(N)", "Relative Force at 100 ms(%)", "L|R Peak Force(%)", "Relative Force at 0 ms(%)", "Left Force at 200 ms(N)", "Force at 150 ms(N)", "Right Peak Force(N)", "Left Force at 250 ms(N)", "Net Impulse 0-200ms(N.s)", "Impulse 0-150ms(N.s)", "Net Force at 250 ms(N)", "RFD 0-50 ms(N/s)", "Force at 0 ms(N)", "Relative Force at 50 ms(%)", "Net Force at 200 ms(N)", "RFD 0-250 ms(N/s)", "Right Force at 100 ms(N)", "Relative Force at 250 ms(%)", "Impulse 0-200ms(N.s)", "Force at 100 ms(N)", "Relative Force at 200 ms(%)", "RFD 0-200 ms(N/s)", "Left Peak Force(N)", "Net Impulse 0-150ms(N.s)", "Relative Peak Force (BW)(N/kg)", "Net Peak Force(N)", "Peak Force(N)", "Relative Force at 200 ms (BW)(N/kg)", "Relative Peak Force(%)", "Relative Force at 0 ms (BW)(N/kg)", "Right Force at 150 ms(N)", "Force at 250 ms(N)", "Net Impulse 0-50ms(N.s)", "Relative Force at 100 ms (BW)(N/kg)", "Left Force at 50 ms(N)", "Left Force at 150 ms(N)", "Impulse 0-250ms(N.s)", "Right Force at 50 ms(N)", "Net Impulse 0-100ms(N.s)", "Net Force at 150 ms(N)", "System Weight(N)", "Net Force at 0 ms(N)", "active"}),
    
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
    outputTable = Table.ReorderColumns(changeType,{"id", "active", "timestamp", "segment", "test.id", "test.name", "test.canonicalId", "athlete.id", "athlete.name", "athlete.active", "athlete.teams", "athlete.groups", "Time to Peak Force(s)", "Relative Force at 50 ms (BW)(N/kg)", "Relative Force at 250 ms (BW)(N/kg)", "Net Force at 100 ms(N)", "Relative Force at 150 ms (BW)(N/kg)", "RFD 0-150 ms(N/s)", "Right Force at 200 ms(N)", "Right Force at 0 ms(N)", "Relative Force at 150 ms(%)", "Left Force at 0 ms(N)", "Left Force at 100 ms(N)", "Impulse 0-100ms(N.s)", "Force at 50 ms(N)", "Force at 200 ms(N)", "RFD 0-100 ms(N/s)", "Net Impulse 0-250ms(N.s)", "Length of Pull(s)", "Net Force at 50 ms(N)", "Impulse 0-50ms(N.s)", "Initiation Threshold(N)", "Right Force at 250 ms(N)", "Relative Force at 100 ms(%)", "L|R Peak Force(%)", "Relative Force at 0 ms(%)", "Left Force at 200 ms(N)", "Force at 150 ms(N)", "Right Peak Force(N)", "Left Force at 250 ms(N)", "Net Impulse 0-200ms(N.s)", "Impulse 0-150ms(N.s)", "Net Force at 250 ms(N)", "RFD 0-50 ms(N/s)", "Force at 0 ms(N)", "Relative Force at 50 ms(%)", "Net Force at 200 ms(N)", "RFD 0-250 ms(N/s)", "Right Force at 100 ms(N)", "Relative Force at 250 ms(%)", "Impulse 0-200ms(N.s)", "Force at 100 ms(N)", "Relative Force at 200 ms(%)", "RFD 0-200 ms(N/s)", "Left Peak Force(N)", "Net Impulse 0-150ms(N.s)", "Relative Peak Force (BW)(N/kg)", "Net Peak Force(N)", "Peak Force(N)", "Relative Force at 200 ms (BW)(N/kg)", "Relative Peak Force(%)", "Relative Force at 0 ms (BW)(N/kg)", "Right Force at 150 ms(N)", "Force at 250 ms(N)", "Net Impulse 0-50ms(N.s)", "Relative Force at 100 ms (BW)(N/kg)", "Left Force at 50 ms(N)", "Left Force at 150 ms(N)", "Impulse 0-250ms(N.s)", "Right Force at 50 ms(N)", "Net Impulse 0-100ms(N.s)", "Net Force at 150 ms(N)", "System Weight(N)", "Net Force at 0 ms(N)", "count", "lastSyncTime", "lastTestTime", "date"})
in
    outputTable