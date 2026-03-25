let
// Orgnaization Data

    // Enter OrgName if applicable. Leave blank if not applicable.
    orgName = "",
    // Set Region. Options are "Americas", "Europe", "Asia/Pacific". Leave blank for default.
    reg = "Americas",
	// enter your integration key here
	SecretKey = "YOUR_INTEGRATION_KEY",

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

// second call for roster data

    // Set slug
    slug = if orgName = null then "v1" else orgName,

    // Build URL
    url = baseURL & slug & "/groups",

    // Make call to get athlete data
    Source2 = Json.Document(Web.Contents(url, [Headers=[Authorization="Bearer " & accessToken]])),
    responseTable = Table.FromRecords({Source2}),

    // expand table from response
    expandTable = Table.ExpandListColumn(responseTable, "data"),

    // expand data from columns
    expandData = Table.ExpandRecordColumn(expandTable, "data", {"id", "name"}, {"id", "name"}),

    // format columns for data type
    outputTable = Table.TransformColumnTypes(expandData,{{"id", type text}, {"name", type text}, {"count", Int64.Type}})

in
    outputTable
