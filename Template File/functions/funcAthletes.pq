(accessToken as text, endpoint as text) as table =>
let
    Source2 = Json.Document(Web.Contents(endpoint, [Headers=[Authorization="Bearer " & accessToken]])),
    responseTable = Table.FromRecords({Source2}),

    // expand table from response
    expandTable = Table.ExpandListColumn(responseTable, "data"),

    // expand data columns
    expanData = Table.ExpandRecordColumn(expandTable, "data", {"id", "name", "active", "teams", "groups", "external"}, {"id", "name", "active", "teams", "groups", "external"}),

    // extract teams
    extractTeams = Table.TransformColumns(expanData, {"teams", each Text.Combine(List.Transform(_, Text.From), ","), type text}),
    
    // extract groups
    extractGroups = Table.TransformColumns(extractTeams, {"groups", each Text.Combine(List.Transform(_, Text.From), ","), type text}),

    // format column  data types
    outputTable = Table.TransformColumnTypes(extractGroups,{{"id", type text}, {"name", type text}, {"teams", type text}, {"groups", type text}, {"active", type logical}, {"count", Int64.Type}})

in
    outputTable