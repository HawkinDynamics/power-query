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

    // === Test Type ===
    testTypeId = "gyBETpRXpdr63Ab2E0V8",

    // === PBI Parameters (snake_case locals for coding consistency) ===
    include_inactive_tests = #"Include Inactive Tests",
    include_eid = #"Include Equipment ID",

    // Optional date filters. Users enter Date values in PBI; we convert to Unix
    // epoch seconds for the API. Null when the parameter is left blank, in which
    // case funcTests omits the from / to query params and pagination returns
    // every test for this test type.
    from_date = if #"from" <> null then
                    Duration.TotalSeconds(DateTimeZone.From(#"from") - #datetimezone(1970, 1, 1, 0, 0, 0, 0, 0))
                else null,
    to_date = if #"to" <> null then
                  Duration.TotalSeconds(DateTimeZone.From(#"to") - #datetimezone(1970, 1, 1, 0, 0, 0, 0, 0))
              else null,

    // === Fetch tests ===
    // funcTests handles cursor pagination internally; a single call returns
    // every page combined.
    result = funcTests(accessToken, reg, org, testTypeId, from_date, to_date, include_inactive_tests, include_eid),
    #"Filtered Rows" = Table.SelectRows(result, each ([id] <> null))
in
    #"Filtered Rows"
