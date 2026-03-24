// Returns the current UTC time as epoch seconds
(getMilliseconds as nullable logical) as number =>
let
    currentDateTimeUTC = DateTimeZone.UtcNow(),
    epochBase = #datetimezone(1970, 1, 1, 0, 0, 0, 0, 0),
    duration = currentDateTimeUTC - epochBase,
    epochTime = if getMilliseconds = true then
        Number.RoundDown(Duration.TotalSeconds(duration) * 1000)
    else
        Number.RoundDown(Duration.TotalSeconds(duration))
in
    epochTime