(accessToken as text, endpoint as text) as table =>
let
    Source2 = Json.Document(Web.Contents(endpoint, [Headers=[Authorization="Bearer " & accessToken]])),
    responseTable = Table.FromRecords({Source2}),

    // expand table from response
    expandTable = Table.ExpandListColumn(responseTable, "data"),
    #"Removed Columns" = Table.RemoveColumns(expandTable,{"count"}),
    #"Expanded data" = Table.ExpandRecordColumn(#"Removed Columns", "data", {"id", "name"}, {"id", "name"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded data",{{"id", type text}, {"name", type text}})
in
    #"Changed Type"