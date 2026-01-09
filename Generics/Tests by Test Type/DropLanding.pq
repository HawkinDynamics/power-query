let
// Create variable for test type: Drop Landing
    testType = "rKgI4y3ItTAzUekTUpvR",

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

// Second call for weigh in data

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

    // expand table from responce
    expandTable = Table.ExpandListColumn(responseTable, "data"),

    // expand data columns
    expandData = Table.ExpandRecordColumn(expandTable, "data", {"id", "timestamp", "segment", "testType", "athlete", "L|R Avg. Impact Force(%)", "Avg. Impact Power(W)", "Avg. Stabilization Velocity(m/s)", "Peak Relative Force(%)", "Time To Stabilization(ms)", "Avg. Impact Force(N)", "Avg. Relative Impact Force(%)", "System Weight(N)", "L|R Peak Force(%)", "Stiffness(N/m)", "Impact Phase %", "Left Avg. Stabilization Force(N)", "L|R Avg. Stabilization Force(%)", "Stabilization Phase %", "Right Impact RFD(N/s)", "Peak Impact Power(W)", "Avg. Stabilization Force(N)", "Avg. Relative Stabilization Power(W/kg)", "Impact Phase(s)", "Peak Relative Impact Power(W/kg)", "Avg. Stabilization Power(W)", "Avg. Relative Impact Power(W/kg)", "Impact RFD(N/s)", "Left Impact RFD(N/s)", "Drop Height(m)", "Right Force at Peak Force(N)", "L|R Impact RFD(%)", "Left Force at Peak Force(N)", "Right Avg. Stabilization Force(N)", "Peak Force(N)", "Left Avg. Impact Force(N)", "Contact Velocity(m/s)", "Stabilization Phase(s)", "Peak Relative Stabilization Power(W/kg)", "Stability Depth(m)", "Avg. Impact Velocity(m/s)", "Right Avg. Impact Force(N)", "Peak Stabilization Power(W)", "active"}, {"id", "timestamp", "segment", "testType", "athlete", "L|R Avg. Impact Force(%)", "Avg. Impact Power(W)", "Avg. Stabilization Velocity(m/s)", "Peak Relative Force(%)", "Time To Stabilization(ms)", "Avg. Impact Force(N)", "Avg. Relative Impact Force(%)", "System Weight(N)", "L|R Peak Force(%)", "Stiffness(N/m)", "Impact Phase %", "Left Avg. Stabilization Force(N)", "L|R Avg. Stabilization Force(%)", "Stabilization Phase %", "Right Impact RFD(N/s)", "Peak Impact Power(W)", "Avg. Stabilization Force(N)", "Avg. Relative Stabilization Power(W/kg)", "Impact Phase(s)", "Peak Relative Impact Power(W/kg)", "Avg. Stabilization Power(W)", "Avg. Relative Impact Power(W/kg)", "Impact RFD(N/s)", "Left Impact RFD(N/s)", "Drop Height(m)", "Right Force at Peak Force(N)", "L|R Impact RFD(%)", "Left Force at Peak Force(N)", "Right Avg. Stabilization Force(N)", "Peak Force(N)", "Left Avg. Impact Force(N)", "Contact Velocity(m/s)", "Stabilization Phase(s)", "Peak Relative Stabilization Power(W/kg)", "Stability Depth(m)", "Avg. Impact Velocity(m/s)", "Right Avg. Impact Force(N)", "Peak Stabilization Power(W)", "active"}),

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
    outputTable = Table.ReorderColumns(changeType,{"id", "active", "timestamp", "segment", "test.id", "test.name", "test.canonicalId", "athlete.id", "athlete.name", "athlete.active", "athlete.teams", "athlete.groups", "L|R Avg. Impact Force(%)", "Avg. Impact Power(W)", "Avg. Stabilization Velocity(m/s)", "Peak Relative Force(%)", "Time To Stabilization(ms)", "Avg. Impact Force(N)", "Avg. Relative Impact Force(%)", "System Weight(N)", "L|R Peak Force(%)", "Stiffness(N/m)", "Impact Phase %", "Left Avg. Stabilization Force(N)", "L|R Avg. Stabilization Force(%)", "Stabilization Phase %", "Right Impact RFD(N/s)", "Peak Impact Power(W)", "Avg. Stabilization Force(N)", "Avg. Relative Stabilization Power(W/kg)", "Impact Phase(s)", "Peak Relative Impact Power(W/kg)", "Avg. Stabilization Power(W)", "Avg. Relative Impact Power(W/kg)", "Impact RFD(N/s)", "Left Impact RFD(N/s)", "Drop Height(m)", "Right Force at Peak Force(N)", "L|R Impact RFD(%)", "Left Force at Peak Force(N)", "Right Avg. Stabilization Force(N)", "Peak Force(N)", "Left Avg. Impact Force(N)", "Contact Velocity(m/s)", "Stabilization Phase(s)", "Peak Relative Stabilization Power(W/kg)", "Stability Depth(m)", "Avg. Impact Velocity(m/s)", "Right Avg. Impact Force(N)", "Peak Stabilization Power(W)", "count", "lastSyncTime", "lastTestTime", "date"})
in
    outputTable
