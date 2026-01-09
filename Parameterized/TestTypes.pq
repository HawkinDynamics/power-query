let
/* -------------------------------------------------------------------------- */
/* The script assumes you have already created the following parameters:      */
/* secretKey, orgName, region                                                 */
/*                                                                            */
/* Ensure you have created these parameters before running this script.       */
/* -------------------------------------------------------------------------- */

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

// second call for roster data

    // Set slug
    slug = if orgName = null then "v1" else orgName,

    // Build URL
    url = baseURL & slug & "/test_types",

    // Make call to get athlete data
    Source2 = Json.Document(Web.Contents(url, [Headers=[Authorization="Bearer " & accessToken]])),
    responseTable = Table.FromRecords({Source2}),
    
    // Convert JSON list of records to table
    RecordList = Source2,
    ConvertedTable = Table.FromList(RecordList, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    
    // Expand the records into columns
    ExpandedTable = Table.ExpandRecordColumn(ConvertedTable, "Column1", Record.FieldNames(RecordList{0}))
in
    ExpandedTable
