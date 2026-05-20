// Fetch the raw force-time waveform for a single test and return it as
// a wide table: one row per sample, one column per waveform array.
// Arrays not returned by the API for the given test type are silently
// skipped, so the function works across all 11 test types.
(accessToken as text, endpoint as text, testId as text) as table =>
let
    Source = Json.Document(
        Web.Contents(
            endpoint & "/" & testId,
            [Headers = [Authorization = "Bearer " & accessToken]]
        )
    ),

    // Documented waveform fields per the API spec. The API may add new
    // arrays in the future; extend this list to surface them.
    candidateFields = {
        "Time(s)",
        "LeftForce(N)",
        "RightForce(N)",
        "CombinedForce(N)",
        "Velocity(m/s)",
        "Displacement(m)",
        "Power(W)"
    },
    presentFields = List.Select(candidateFields, each Record.HasFields(Source, _)),

    columnLists = List.Transform(presentFields, each Record.Field(Source, _)),
    output = Table.FromColumns(columnLists, presentFields),
    typed = Table.TransformColumnTypes(
        output,
        List.Transform(presentFields, each {_, type number})
    )
in
    typed
