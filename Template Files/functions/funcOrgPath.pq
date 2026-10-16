// Builds the versioned API path prefix for an org.
//
// The Organization Name parameter is optional; blank means the default "v1"
// path. Returns e.g. "api/v1" or "api/v1/athletes" when a suffix is given.
//
// Text only — no Web.Contents here. The result is passed to funcGet as
// RelativePath, which is allowed to be dynamic.
(org as nullable text, optional suffix as nullable text) as text =>
let
    resolved = if org = null or org = "" then "v1" else org,
    base = "api/" & resolved,
    path = if suffix = null or suffix = "" then base else base & "/" & suffix
in
    path
