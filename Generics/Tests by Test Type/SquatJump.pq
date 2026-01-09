let
// Create variable for test type: Squat Jump
    testType = "QEG7m7DhYsD6BrcQ8pic",

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

// Second call for Squat Jump data

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

    // expand data from response table
    expandData = Table.ExpandRecordColumn(expandTable, "data", {"id", "timestamp", "segment", "testType", "athlete", "Right Avg. Propulsive Force(N)", "Relative Propulsive Net Impulse(N.s/kg)", "Propulsive Phase(s)", "Time To Takeoff(s)", "Left Force at Peak Propulsive Force(N)", "Jump Height(m)", "Avg. Propulsive Velocity(m/s)", "Takeoff Velocity(m/s)", "Time to Stabilization(ms)", "Avg. Propulsive Power(W)", "L|R Peak Propulsive Force(%)", "Right Force at Peak Propulsive Force(N)", "Relative Propulsive Impulse(N.s/kg)", "Relative Peak Landing Force(%)", "System Weight(N)", "Peak Relative Propulsive Force(%)", "Peak Relative Propulsive Power(W/kg)", "Peak Velocity(m/s)", "L|R Avg. Landing Force(%)", "Landing Stiffness(N/m)", "Propulsive RFD(N/s)", "Avg. Relative Propulsive Power(W/kg)", "Right Force at Peak Landing Force(N)", "L|R Avg. Propulsive Force(%)", "Propulsive Net Impulse(N.s)", "Avg. Relative Propulsive Force(%)", "L|R Peak Landing Force(%)", "Left Avg. Landing Force(N)", "Left Avg. Propulsive Force(N)", "Avg. Landing Force(N)", "Peak Propulsive Power(W)", "Peak Propulsive Force(N)", "Peak Landing Force(N)", "Left Force at Peak Landing Force(N)", "L|R Propulsive Impulse Index(%)", "L|R Landing Impulse Index(%)", "Avg. Propulsive Force(N)", "Right Avg. Landing Force(N)", "Propulsive Impulse(N.s)", "Flight Time(s)", "Jump Momentum(kg.m/s)", "active"}, {"id", "timestamp", "segment", "testType", "athlete", "Right Avg. Propulsive Force(N)", "Relative Propulsive Net Impulse(N.s/kg)", "Propulsive Phase(s)", "Time To Takeoff(s)", "Left Force at Peak Propulsive Force(N)", "Jump Height(m)", "Avg. Propulsive Velocity(m/s)", "Takeoff Velocity(m/s)", "Time to Stabilization(ms)", "Avg. Propulsive Power(W)", "L|R Peak Propulsive Force(%)", "Right Force at Peak Propulsive Force(N)", "Relative Propulsive Impulse(N.s/kg)", "Relative Peak Landing Force(%)", "System Weight(N)", "Peak Relative Propulsive Force(%)", "Peak Relative Propulsive Power(W/kg)", "Peak Velocity(m/s)", "L|R Avg. Landing Force(%)", "Landing Stiffness(N/m)", "Propulsive RFD(N/s)", "Avg. Relative Propulsive Power(W/kg)", "Right Force at Peak Landing Force(N)", "L|R Avg. Propulsive Force(%)", "Propulsive Net Impulse(N.s)", "Avg. Relative Propulsive Force(%)", "L|R Peak Landing Force(%)", "Left Avg. Landing Force(N)", "Left Avg. Propulsive Force(N)", "Avg. Landing Force(N)", "Peak Propulsive Power(W)", "Peak Propulsive Force(N)", "Peak Landing Force(N)", "Left Force at Peak Landing Force(N)", "L|R Propulsive Impulse Index(%)", "L|R Landing Impulse Index(%)", "Avg. Propulsive Force(N)", "Right Avg. Landing Force(N)", "Propulsive Impulse(N.s)", "Flight Time(s)", "Jump Momentum(kg.m/s)", "active"}),
    
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
    outputTable = Table.ReorderColumns(changeType,{"id", "active", "timestamp", "segment", "test.id", "test.name", "test.canonicalId", "athlete.id", "athlete.name", "athlete.active", "athlete.teams", "athlete.groups", "Right Avg. Propulsive Force(N)", "Relative Propulsive Net Impulse(N.s/kg)", "Propulsive Phase(s)", "Time To Takeoff(s)", "Left Force at Peak Propulsive Force(N)", "Jump Height(m)", "Avg. Propulsive Velocity(m/s)", "Takeoff Velocity(m/s)", "Time to Stabilization(ms)", "Avg. Propulsive Power(W)", "L|R Peak Propulsive Force(%)", "Right Force at Peak Propulsive Force(N)", "Relative Propulsive Impulse(N.s/kg)", "Relative Peak Landing Force(%)", "System Weight(N)", "Peak Relative Propulsive Force(%)", "Peak Relative Propulsive Power(W/kg)", "Peak Velocity(m/s)", "L|R Avg. Landing Force(%)", "Landing Stiffness(N/m)", "Propulsive RFD(N/s)", "Avg. Relative Propulsive Power(W/kg)", "Right Force at Peak Landing Force(N)", "L|R Avg. Propulsive Force(%)", "Propulsive Net Impulse(N.s)", "Avg. Relative Propulsive Force(%)", "L|R Peak Landing Force(%)", "Left Avg. Landing Force(N)", "Left Avg. Propulsive Force(N)", "Avg. Landing Force(N)", "Peak Propulsive Power(W)", "Peak Propulsive Force(N)", "Peak Landing Force(N)", "Left Force at Peak Landing Force(N)", "L|R Propulsive Impulse Index(%)", "L|R Landing Impulse Index(%)", "Avg. Propulsive Force(N)", "Right Avg. Landing Force(N)", "Propulsive Impulse(N.s)", "Flight Time(s)", "Jump Momentum(kg.m/s)", "count", "lastSyncTime", "lastTestTime", "date"})
in
    outputTable