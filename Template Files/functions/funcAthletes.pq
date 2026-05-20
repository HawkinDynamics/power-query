(accessToken as text, endpoint as text, optional includeInactive as nullable logical) as table =>
let
    // Athletes endpoint accepts `?includeInactive` as a flag (no value); presence means
    // include inactive. Default behavior (no flag) returns active athletes only.
    inactiveParam = if includeInactive = true then "?includeInactive" else "",
    Source2 = Json.Document(Web.Contents(endpoint & inactiveParam, [Headers=[Authorization="Bearer " & accessToken]])),
    responseTable = Table.FromRecords({Source2}),

    // expand table from response
    expandTable = Table.ExpandListColumn(responseTable, "data"),

    // The API may include optional profile fields (image, position, dob,
    // sport, height, lastTestedOn) on each record; collect every field
    // name actually present so we expand only what's there.
    candidateFields = {"id", "name", "active", "teams", "groups", "external", "image", "position", "dob", "sport", "height", "lastTestedOn"},
    presentFields = List.Select(
        candidateFields,
        each List.AnyTrue(
            List.Transform(
                expandTable[data],
                (r) => r is record and Record.HasFields(r, _)
            )
        )
    ),

    // expand data columns (only fields actually present in the response)
    expanData = Table.ExpandRecordColumn(expandTable, "data", presentFields, presentFields),

    // extract teams
    extractTeams = Table.TransformColumns(expanData, {"teams", each Text.Combine(List.Transform(_, Text.From), ","), type text}),

    // extract groups
    extractGroups = Table.TransformColumns(extractTeams, {"groups", each Text.Combine(List.Transform(_, Text.From), ","), type text}),

    // dynamically expand external properties
    externalFields = if List.Contains(presentFields, "external") then
        List.Distinct(
            List.Combine(
                List.Transform(
                    extractGroups[external],
                    each if _ is record then Record.FieldNames(_) else {}
                )
            )
        )
    else
        {},
    expandExternal = if List.Count(externalFields) > 0 then
        Table.ExpandRecordColumn(extractGroups, "external", externalFields, List.Transform(externalFields, each "external." & _))
    else if List.Contains(presentFields, "external") then
        Table.RemoveColumns(extractGroups, {"external"})
    else
        extractGroups,

    // Derive a Date column from lastTestedOn (epoch milliseconds) when the
    // field is present. The original numeric column is kept for callers
    // that want the raw timestamp.
    addLastTestedOn = if List.Contains(Table.ColumnNames(expandExternal), "lastTestedOn") then
        Table.AddColumn(
            expandExternal,
            "lastTestedOnDate",
            each
                if [lastTestedOn] = null then null
                else Date.From(
                    DateTimeZone.ToLocal(
                        DateTime.AddZone(
                            #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, 0, [lastTestedOn] / 1000),
                            0
                        )
                    )
                ),
            type nullable date
        )
    else
        expandExternal,

    // format known column data types
    knownTypes = {
        {"id", type text},
        {"name", type text},
        {"teams", type text},
        {"groups", type text},
        {"active", type logical},
        {"image", type text},
        {"position", type text},
        {"dob", type date},
        {"sport", type text},
        {"height", type number},
        {"lastTestedOn", Int64.Type},
        {"lastTestedOnDate", type date},
        {"count", Int64.Type}
    },
    // type any external columns as text
    externalTypes = List.Transform(externalFields, each {"external." & _, type text}),
    // Only cast columns that actually exist in the table.
    finalColumns = Table.ColumnNames(addLastTestedOn),
    existingKnownTypes = List.Select(knownTypes, each List.Contains(finalColumns, _{0})),
    outputTable = Table.TransformColumnTypes(addLastTestedOn, List.Combine({existingKnownTypes, externalTypes}))

in
    outputTable