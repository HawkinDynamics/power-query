// Power Query function to get Hawkin Dynamics API access token
(accessToken as text, reg as text, orgName as nullable text) as table =>
let
    // Region
    baseURL = if
        reg = "Europe" then "https://eu.cloud.hawkindynamics.com/api/" else if
        reg = "Asia/Pacific" then "https://apac.cloud.hawkindynamics.com/api/" else if
        reg = "Americas" then "https://cloud.hawkindynamics.com/api/" else
        "https://cloud.dev.hawkindynamics.com/api/",

    // Org Name
    org = if orgName = "" or orgName = null then "v1" else orgName,

    // URL complete
    url = baseURL & org,

    // Token
    accessKey = accessToken,

    // Call to get access token
    Source = Json.Document(
        Web.Contents(
            baseURL & "token",
            [
                Headers = [Authorization = "Bearer " & accessKey]
            ]
        )
    ),

    // Convert response to table and define types
    ResponseTable = Table.FromRecords({Source}),
    NewTable = Table.TransformColumnTypes(
        ResponseTable,
        {
            {"access_token", type text},
            {"token_type", type text},
            {"expires_at", Int64.Type}
        }
    ),

    return = Table.AddColumn(NewTable, "url", each url)
in
    return
