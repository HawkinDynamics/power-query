let
    // 
	// enter your integration key here
	SecretKey = #"API Integration Key",
    // org name
    orgName = if #"Organization Name" = null then "v1" else #"Organization Name",
    // region
    reg = if #"API Region" = null then "Americas" else #"API Region",
    // Start date
    startDate = if #"Organization Start Date" = null then #datetime(2017, 1, 1, 0, 0, 0) else #"Organization Start Date",

    // Run Auth Function
    authTable = funcAuth(SecretKey,reg,orgName, startDate)
in
    authTable