let
/* -------------------------------------------------------------------------- */
/* USER CONFIGURATION SECTION                                                 */
/* INSTRUCTIONS: ONLY EDIT VALUES IN THIS SECTION                             */
/* -------------------------------------------------------------------------- */

    // 1. Integration Settings
    // !! ENTER YOUR INTEGRATION KEY HERE !!
    SecretKey = "YOUR_INTEGRATION_KEY",

    // 2. Test ID
    // !! ENTER THE TEST ID FOR THE WAVEFORM YOU WANT !!
    // Test IDs come from the `id` field on Get Tests responses.
    testId = "REPLACE_WITH_TEST_ID",

    // 3. Organization Data
    // Enter OrgName if applicable. Leave null if not applicable.
    orgName = null,

    // Set Region. Options: "Americas", "Europe", "Asia/Pacific".
    reg = "Americas",

/* -------------------------------------------------------------------------- */
/* STOP! DO NOT EDIT BELOW THIS LINE                                          */
/* Editing below may break the API connection logic.                          */
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

// second call for force-time waveform

    // Set slug
    slug = if orgName = null then "v1" else orgName,

    // Build URL
    url = baseURL & slug & "/forcetime/" & testId,

    // Fetch waveform
    waveform = Json.Document(Web.Contents(url, [Headers=[Authorization="Bearer " & accessToken]])),

    // Reshape into a wide table: one row per sample, one column per
    // waveform array. Arrays not returned by the API for this test type
    // are silently skipped.
    candidateFields = {
        "Time(s)",
        "LeftForce(N)",
        "RightForce(N)",
        "CombinedForce(N)",
        "Velocity(m/s)",
        "Displacement(m)",
        "Power(W)"
    },
    presentFields = List.Select(candidateFields, each Record.HasFields(waveform, _)),
    columnLists = List.Transform(presentFields, each Record.Field(waveform, _)),
    output = Table.FromColumns(columnLists, presentFields),
    typed = Table.TransformColumnTypes(output, List.Transform(presentFields, each {_, type number}))
in
    typed
