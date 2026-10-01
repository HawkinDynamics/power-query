// Exchanges the long-lived integration key for a short-lived access token.
//
// Returns the token as text. Previous versions returned a table carrying the
// token, expiry and base URL, which the data queries then read row values out
// of. That made every data query a dynamic data source (its URL came from
// another query's data) and blocked scheduled refresh in the Power BI service,
// so the URL no longer travels through data — each query rebuilds it from the
// API Region and Organization Name parameters instead.
//
// The expiry check the old table supported is gone with it: every query
// authenticates for itself, so a token is never reused long enough to expire
// mid-refresh. Power Query caches identical requests within a refresh, so this
// does not mean one token round trip per table in practice.
//
// The token endpoint sits at /api/token with no version prefix, unlike the
// /api/v1/* data endpoints.
(integrationKey as text, reg as nullable text) as text =>
let
    response = Json.Document(funcGet(reg, "api/token", [], integrationKey)),
    accessToken = Text.From(response[access_token])
in
    accessToken
