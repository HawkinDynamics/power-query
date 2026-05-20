let
    api_integration_key = #"API Integration Key",
    api_region = if #"API Region" = null then "Americas" else #"API Region",
    organization_name = if #"Organization Name" = null then "v1" else #"Organization Name",

    // Run Auth Function
    authTable = funcAuth(api_integration_key, api_region, organization_name)
in
    authTable
