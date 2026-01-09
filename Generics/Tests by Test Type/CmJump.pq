let
// Create variable for test type: CMJ
    testType = "7nNduHeM5zETPjHxvm7s",

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

// Second call for CMJ data

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
    expandTableData = Table.ExpandRecordColumn(expandTable, "data", {"id", "timestamp", "segment", "testType", "athlete", "Right Avg. Propulsive Force(N)", "Relative Propulsive Net Impulse(N.s/kg)", "Propulsive Phase(s)", "Peak Relative Braking Force(%)", "Positive Impulse(N.s)", "Impulse Ratio", "Countermovement Depth(m)", "Left Force at Peak Propulsive Force(N)", "Jump Height(m)", "Unweighting Phase(s)", "Relative Propulsive Impulse(N.s/kg)", "L|R Avg. Braking RFD(%)", "Peak Relative Propulsive Power(W/kg)", "Stiffness(N/m)", "Avg. Relative Braking Power(W/kg)", "Unweighting Phase %", "Right Force at Peak Braking Force(N)", "RSI", "L|R Avg. Propulsive Force(%)", "Right Avg. Braking Force(N)", "Avg. Relative Propulsive Force(%)", "Left Avg. Landing Force(N)", "L|R Avg. Braking Force(%)", "Peak Propulsive Power(W)", "Force at Min Displacement(N)", "Avg. Braking Power(W)", "Peak Landing Force(N)", "Relative Braking Impulse(N.s/kg)", "Right Avg. Landing Force(N)", "Avg. Propulsive Force(N)", "Flight Time(s)", "Relative Braking Net Impulse(N.s/kg)", "Jump Momentum(kg.m/s)", "Peak Braking Force(N)", "Avg. Braking Velocity(m/s)", "Left Avg. Braking Force(N)", "Time To Takeoff(s)", "Avg. Propulsive Velocity(m/s)", "Takeoff Velocity(m/s)", "L|R Peak Braking Force(%)", "Avg. Propulsive Power(W)", "Right Avg. Braking RFD(N/s)", "L|R Peak Propulsive Force(%)", "Right Force at Peak Propulsive Force(N)", "Avg. Relative Braking Force(%)", "Relative Peak Landing Force(%)", "Peak Relative Braking Power(W/kg)", "mRSI", "System Weight(N)", "Peak Relative Propulsive Force(%)", "Peak Velocity(m/s)", "L|R Avg. Landing Force(%)", "Positive Net Impulse(N.s)", "Landing Stiffness(N/m)", "Relative Force at Min Displacement(%)", "Braking Net Impulse(N.s)", "Braking Phase %", "Left Avg. Braking RFD(N/s)", "Avg. Relative Propulsive Power(W/kg)", "Propulsive Phase %", "Braking Impulse(N.s)", "Right Force at Peak Landing Force(N)", "Propulsive Net Impulse(N.s)", "L|R Peak Landing Force(%)", "Peak Braking Power(W)", "Avg. Braking Force(N)", "Left Avg. Propulsive Force(N)", "Braking Phase(s)", "Avg. Landing Force(N)", "Peak Braking Velocity(m/s)", "Peak Propulsive Force(N)", "Braking RFD(N/s)", "Left Force at Peak Landing Force(N)", "L|R Propulsive Impulse Index(%)", "Left Force at Peak Braking Force(N)", "Propulsive Impulse(N.s)", "L|R Braking Impulse Index(%)", "active", "Time to Stabilization(ms)", "L|R Landing Impulse Index(%)"}, {"id", "timestamp", "segment", "testType", "athlete", "Right Avg. Propulsive Force(N)", "Relative Propulsive Net Impulse(N.s/kg)", "Propulsive Phase(s)", "Peak Relative Braking Force(%)", "Positive Impulse(N.s)", "Impulse Ratio", "Countermovement Depth(m)", "Left Force at Peak Propulsive Force(N)", "Jump Height(m)", "Unweighting Phase(s)", "Relative Propulsive Impulse(N.s/kg)", "L|R Avg. Braking RFD(%)", "Peak Relative Propulsive Power(W/kg)", "Stiffness(N/m)", "Avg. Relative Braking Power(W/kg)", "Unweighting Phase %", "Right Force at Peak Braking Force(N)", "RSI", "L|R Avg. Propulsive Force(%)", "Right Avg. Braking Force(N)", "Avg. Relative Propulsive Force(%)", "Left Avg. Landing Force(N)", "L|R Avg. Braking Force(%)", "Peak Propulsive Power(W)", "Force at Min Displacement(N)", "Avg. Braking Power(W)", "Peak Landing Force(N)", "Relative Braking Impulse(N.s/kg)", "Right Avg. Landing Force(N)", "Avg. Propulsive Force(N)", "Flight Time(s)", "Relative Braking Net Impulse(N.s/kg)", "Jump Momentum(kg.m/s)", "Peak Braking Force(N)", "Avg. Braking Velocity(m/s)", "Left Avg. Braking Force(N)", "Time To Takeoff(s)", "Avg. Propulsive Velocity(m/s)", "Takeoff Velocity(m/s)", "L|R Peak Braking Force(%)", "Avg. Propulsive Power(W)", "Right Avg. Braking RFD(N/s)", "L|R Peak Propulsive Force(%)", "Right Force at Peak Propulsive Force(N)", "Avg. Relative Braking Force(%)", "Relative Peak Landing Force(%)", "Peak Relative Braking Power(W/kg)", "mRSI", "System Weight(N)", "Peak Relative Propulsive Force(%)", "Peak Velocity(m/s)", "L|R Avg. Landing Force(%)", "Positive Net Impulse(N.s)", "Landing Stiffness(N/m)", "Relative Force at Min Displacement(%)", "Braking Net Impulse(N.s)", "Braking Phase %", "Left Avg. Braking RFD(N/s)", "Avg. Relative Propulsive Power(W/kg)", "Propulsive Phase %", "Braking Impulse(N.s)", "Right Force at Peak Landing Force(N)", "Propulsive Net Impulse(N.s)", "L|R Peak Landing Force(%)", "Peak Braking Power(W)", "Avg. Braking Force(N)", "Left Avg. Propulsive Force(N)", "Braking Phase(s)", "Avg. Landing Force(N)", "Peak Braking Velocity(m/s)", "Peak Propulsive Force(N)", "Braking RFD(N/s)", "Left Force at Peak Landing Force(N)", "L|R Propulsive Impulse Index(%)", "Left Force at Peak Braking Force(N)", "Propulsive Impulse(N.s)", "L|R Braking Impulse Index(%)", "active", "Time to Stabilization(ms)", "L|R Landing Impulse Index(%)"}),

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
    outputTable = Table.ReorderColumns(changeType,{"id", "active", "timestamp", "segment", "test.id", "test.name", "test.canonicalId", "athlete.id", "athlete.name", "athlete.active", "athlete.teams", "athlete.groups", "athlete.external", "Right Avg. Propulsive Force(N)", "Relative Propulsive Net Impulse(N.s/kg)", "Propulsive Phase(s)", "Peak Relative Braking Force(%)", "Positive Impulse(N.s)", "Impulse Ratio", "Countermovement Depth(m)", "Left Force at Peak Propulsive Force(N)", "Jump Height(m)", "Unweighting Phase(s)", "Relative Propulsive Impulse(N.s/kg)", "L|R Avg. Braking RFD(%)", "Peak Relative Propulsive Power(W/kg)", "Stiffness(N/m)", "Avg. Relative Braking Power(W/kg)", "Unweighting Phase %", "Right Force at Peak Braking Force(N)", "RSI", "L|R Avg. Propulsive Force(%)", "Right Avg. Braking Force(N)", "Avg. Relative Propulsive Force(%)", "Left Avg. Landing Force(N)", "L|R Avg. Braking Force(%)", "Peak Propulsive Power(W)", "Force at Min Displacement(N)", "Avg. Braking Power(W)", "Peak Landing Force(N)", "Relative Braking Impulse(N.s/kg)", "Right Avg. Landing Force(N)", "Avg. Propulsive Force(N)", "Flight Time(s)", "Relative Braking Net Impulse(N.s/kg)", "Jump Momentum(kg.m/s)", "Peak Braking Force(N)", "Avg. Braking Velocity(m/s)", "Left Avg. Braking Force(N)", "Time To Takeoff(s)", "Avg. Propulsive Velocity(m/s)", "Takeoff Velocity(m/s)", "L|R Peak Braking Force(%)", "Avg. Propulsive Power(W)", "Right Avg. Braking RFD(N/s)", "L|R Peak Propulsive Force(%)", "Right Force at Peak Propulsive Force(N)", "Avg. Relative Braking Force(%)", "Relative Peak Landing Force(%)", "Peak Relative Braking Power(W/kg)", "mRSI", "System Weight(N)", "Peak Relative Propulsive Force(%)", "Peak Velocity(m/s)", "L|R Avg. Landing Force(%)", "Positive Net Impulse(N.s)", "Landing Stiffness(N/m)", "Relative Force at Min Displacement(%)", "Braking Net Impulse(N.s)", "Braking Phase %", "Left Avg. Braking RFD(N/s)", "Avg. Relative Propulsive Power(W/kg)", "Propulsive Phase %", "Braking Impulse(N.s)", "Right Force at Peak Landing Force(N)", "Propulsive Net Impulse(N.s)", "L|R Peak Landing Force(%)", "Peak Braking Power(W)", "Avg. Braking Force(N)", "Left Avg. Propulsive Force(N)", "Braking Phase(s)", "Avg. Landing Force(N)", "Peak Braking Velocity(m/s)", "Peak Propulsive Force(N)", "Braking RFD(N/s)", "Left Force at Peak Landing Force(N)", "L|R Propulsive Impulse Index(%)", "Left Force at Peak Braking Force(N)", "Propulsive Impulse(N.s)", "L|R Braking Impulse Index(%)", "Time to Stabilization(ms)", "L|R Landing Impulse Index(%)", "count", "lastSyncTime", "lastTestTime", "date"})
in
    outputTable