let
    // Current Auth Info
    currentAuth = Auth,

    // Get Expiration
    expiration = currentAuth{0}[expires_at],
    // Current date time
    currentDT = epochNow(false),
    // Validate
    validated = if expiration > currentDT then currentAuth else funcAuth(),

    // extract access token from response table
    accessToken = Text.From(validated{0}[access_token]),
    // Endpoint URL (built by funcAuth from API Region + Organization Name)
    endpoint = currentAuth{0}[url],

    // === Test Type ===
    testTypeId = "umnEZPgi6zaxuw0KhUpM",

    // === PBI Parameters (snake_case locals for coding consistency) ===
    include_inactive_tests = #"Include Inactive Tests",
    include_eid = #"Include Equipment ID",

    // Optional date filters. Users enter Date values in PBI; we convert to Unix
    // epoch seconds for the API. Null when the parameter is left blank, in which
    // case funcTests omits the &from / &to query params and pagination returns
    // every test for this test type.
    from_date = if #"from" <> null then
                    Duration.TotalSeconds(DateTimeZone.From(#"from") - #datetimezone(1970, 1, 1, 0, 0, 0, 0, 0))
                else null,
    to_date = if #"to" <> null then
                  Duration.TotalSeconds(DateTimeZone.From(#"to") - #datetimezone(1970, 1, 1, 0, 0, 0, 0, 0))
              else null,

    // === Fetch tests ===
    // funcTests handles cursor pagination internally; a single call returns
    // every page combined. The previous client-side 30-day chunking loop is
    // obsolete with API v1.13+ pagination.
    result = funcTests(accessToken, endpoint, testTypeId, from_date, to_date, include_inactive_tests, include_eid),
    #"Filtered Rows" = Table.SelectRows(result, each ([id] <> null))
in
    #"Filtered Rows"
