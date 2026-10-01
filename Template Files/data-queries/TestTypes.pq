let
    // Connection settings come straight from the template parameters. Parameters
    // are not data sources, so Power BI can still identify the endpoint during
    // static analysis and schedule refresh on the published model. Reading the
    // URL and token out of the old Auth table is what made this query a dynamic
    // data source and broke refresh in the service.
    reg = if #"API Region" = null then "Americas" else #"API Region",
    org = #"Organization Name",

    // Authenticate per query rather than sharing a token through a loaded
    // table. Power Query caches identical requests within a refresh, so this is
    // not one token round trip per table.
    accessToken = funcAuth(#"API Integration Key", reg),

    Source2 = Json.Document(funcGet(reg, funcOrgPath(org, "test_types"), [], accessToken)),
    #"Converted to Table" = Table.FromList(Source2, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "name"}, {"id", "name"})
in
    #"Expanded Column1"
