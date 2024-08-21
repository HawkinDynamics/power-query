let
// first call to get access token
	// enter your integration key here
	SecretKey = "YOUR_INTEGRATION_KEY",
    
    // First call to get access token
    GET = Json.Document(Web.Contents("https://cloud.hawkindynamics.com/api/token", [Headers=[Authorization="Bearer " & SecretKey]])),
    ResponseTable = Table.FromRecords({GET}),
    NewTable = Table.TransformColumnTypes(ResponseTable,{{"access_token", type text}, {"token_type", type text}, {"expires_at", Int64.Type}}),
    
    // Extract access token from response table
    tokenList = NewTable[access_token],
    accessToken = Text.From(tokenList{0}),
    
// Enter Test ID here
    testId = "UNIQIE_TEST_ID",
    
// Second call for CMJ data
    Source2 = Json.Document(Web.Contents("https://cloud.hawkindynamics.com/api/dev/forcetime/" & testId, [Headers=[Authorization="Bearer " & accessToken]])),
    
    // Convert JSON response to table
    RecordTable = Table.FromRecords({Source2}),

    // Isolate and expand Time
    isolateTime = Table.RemoveColumns(RecordTable,{"testType", "id", "athlete", "timestamp", "RightForce(N)", "LeftForce(N)", "CombinedForce(N)", "Velocity(m/s)", "Displacement(m)", "Power(W)", "XLeftForce(N)", "XRightForce(N)", "YLeftForce(N)", "YRightForce(N)", "XLeftMoments", "XRightMoments", "YLeftMoments", "YRightMoments", "rsi"}),
    expandTime = Table.ExpandListColumn(isolateTime, "Time(s)"),

    // Isolate and expand RightForce
    isolateRight = Table.RemoveColumns(RecordTable,{"testType", "id", "athlete", "timestamp", "Time(s)", "LeftForce(N)", "CombinedForce(N)", "Velocity(m/s)", "Displacement(m)", "Power(W)", "XLeftForce(N)", "XRightForce(N)", "YLeftForce(N)", "YRightForce(N)", "XLeftMoments", "XRightMoments", "YLeftMoments", "YRightMoments", "rsi"}),
    expandRight = Table.ExpandListColumn(isolateRight, "RightForce(N)"),

    // Isolate and expand LeftForce
    isolateLeft = Table.RemoveColumns(RecordTable,{"testType", "id", "athlete", "timestamp", "Time(s)", "RightForce(N)", "CombinedForce(N)", "Velocity(m/s)", "Displacement(m)", "Power(W)", "XLeftForce(N)", "XRightForce(N)", "YLeftForce(N)", "YRightForce(N)", "XLeftMoments", "XRightMoments", "YLeftMoments", "YRightMoments", "rsi"}),
    expandLeft = Table.ExpandListColumn(isolateLeft, "LeftForce(N)"),

    // Isolate and expand CombinedForce
    isolateCombined = Table.RemoveColumns(RecordTable,{"testType", "id", "athlete", "timestamp", "Time(s)", "RightForce(N)", "LeftForce(N)", "Velocity(m/s)", "Displacement(m)", "Power(W)", "XLeftForce(N)", "XRightForce(N)", "YLeftForce(N)", "YRightForce(N)", "XLeftMoments", "XRightMoments", "YLeftMoments", "YRightMoments", "rsi"}),
    expandCombined = Table.ExpandListColumn(isolateCombined, "CombinedForce(N)"),

    // Isolate and expand Velocity
    isolateVelocity = Table.RemoveColumns(RecordTable,{"testType", "id", "athlete", "timestamp", "Time(s)", "RightForce(N)", "LeftForce(N)", "CombinedForce(N)", "Displacement(m)", "Power(W)", "XLeftForce(N)", "XRightForce(N)", "YLeftForce(N)", "YRightForce(N)", "XLeftMoments", "XRightMoments", "YLeftMoments", "YRightMoments", "rsi"}),
    expandVelocity = Table.ExpandListColumn(isolateVelocity, "Velocity(m/s)"),

    // Isolate and expand Displacement
    isolateDisplacement = Table.RemoveColumns(RecordTable,{"testType", "id", "athlete", "timestamp", "Time(s)", "RightForce(N)", "LeftForce(N)", "CombinedForce(N)", "Velocity(m/s)", "Power(W)", "XLeftForce(N)", "XRightForce(N)", "YLeftForce(N)", "YRightForce(N)", "XLeftMoments", "XRightMoments", "YLeftMoments", "YRightMoments", "rsi"}),
    expandDisplacement = Table.ExpandListColumn(isolateDisplacement, "Displacement(m)"),

    // Isolate and expand Power
    isolatePower = Table.RemoveColumns(RecordTable,{"testType", "id", "athlete", "timestamp", "Time(s)", "RightForce(N)", "LeftForce(N)", "CombinedForce(N)", "Velocity(m/s)", "Displacement(m)", "XLeftForce(N)", "XRightForce(N)", "YLeftForce(N)", "YRightForce(N)", "XLeftMoments", "XRightMoments", "YLeftMoments", "YRightMoments", "rsi"}),
    expandPower = Table.ExpandListColumn(isolatePower, "Power(W)"),

    // Add Index to all tables
    addIndexToTime = Table.AddIndexColumn(expandTime, "Index", 1, 1, Int64.Type),
    addIndexToRight = Table.AddIndexColumn(expandRight, "Index", 1, 1, Int64.Type),
    addIndexToLeft = Table.AddIndexColumn(expandLeft, "Index", 1, 1, Int64.Type),
    addIndexToCombined = Table.AddIndexColumn(expandCombined, "Index", 1, 1, Int64.Type),
    addIndexToVelocity = Table.AddIndexColumn(expandVelocity, "Index", 1, 1, Int64.Type),
    addIndexToDisplacement = Table.AddIndexColumn(expandDisplacement, "Index", 1, 1, Int64.Type),
    addIndexToPower = Table.AddIndexColumn(expandPower, "Index", 1, 1, Int64.Type),

    // Merge tables on Index
    mergedTables1 = Table.NestedJoin(addIndexToTime, "Index", addIndexToRight, "Index", "RightForce", JoinKind.Inner),
    mergedTables2 = Table.ExpandTableColumn(mergedTables1, "RightForce", {"RightForce(N)"}, {"RightForce(N)"}),

    mergedTables3 = Table.NestedJoin(mergedTables2, "Index", addIndexToLeft, "Index", "LeftForce", JoinKind.Inner),
    mergedTables4 = Table.ExpandTableColumn(mergedTables3, "LeftForce", {"LeftForce(N)"}, {"LeftForce(N)"}),

    mergedTables5 = Table.NestedJoin(mergedTables4, "Index", addIndexToCombined, "Index", "CombinedForce", JoinKind.Inner),
    mergedTables6 = Table.ExpandTableColumn(mergedTables5, "CombinedForce", {"CombinedForce(N)"}, {"CombinedForce(N)"}),

    mergedTables7 = Table.NestedJoin(mergedTables6, "Index", addIndexToVelocity, "Index", "Velocity", JoinKind.Inner),
    mergedTables8 = Table.ExpandTableColumn(mergedTables7, "Velocity", {"Velocity(m/s)"}, {"Velocity(m/s)"}),

    mergedTables9 = Table.NestedJoin(mergedTables8, "Index", addIndexToDisplacement, "Index", "Displacement", JoinKind.Inner),
    mergedTables10 = Table.ExpandTableColumn(mergedTables9, "Displacement", {"Displacement(m)"}, {"Displacement(m)"}),

    mergedTables11 = Table.NestedJoin(mergedTables10, "Index", addIndexToPower, "Index", "Power", JoinKind.Inner),
    mergedTables12 = Table.ExpandTableColumn(mergedTables11, "Power", {"Power(W)"}, {"Power(W)"}),

    // format coumn types
    changedtype = Table.TransformColumnTypes(mergedTables12,{{"Time(s)", type number}, {"RightForce(N)", Int64.Type}, {"LeftForce(N)", Int64.Type}, {"CombinedForce(N)", Int64.Type}, {"Velocity(m/s)", type number}, {"Displacement(m)", type number}, {"Power(W)", type number}}),

    // remove index column
    outputTable = Table.RemoveColumns(changedtype,{"Index"})
in
    outputTable
