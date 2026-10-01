// Single entry point for every Hawkin API request.
//
// This is the ONLY place in the template where a URL literal appears, and that
// is deliberate. Power BI's service refuses to schedule refresh on a "dynamic
// data source" — one whose URL can't be determined until the query runs. The
// documented exception is Web.Contents with the RelativePath and Query options
// against a static base URL. Two rules keep this function refreshable, both
// confirmed in Power BI Desktop's Data source settings:
//
// 1. The options record is written inline, as a record literal inside each
//    Web.Contents call. Building it in code first (a variable assembled with
//    Record.AddField or an if/else) hides it from Power BI's analysis and turns
//    every call into a dynamic data source, even with a literal host. That is
//    why the same record is repeated in each branch. The values inside it can
//    be computed; the record itself cannot. An empty Query ([]) is fine.
//
// 2. The host is a literal in each Web.Contents call. Branching between
//    complete calls works. A host string computed at runtime is part of what
//    broke the original template; don't reintroduce it.
//
// Power BI registers every branch as a data source, so the published model asks
// for credentials (Anonymous) on all three hosts, including regions an org
// never calls. That is also why there is no Dev branch: it would put an
// internal host in every customer's credential list. To point a working copy at
// the dev API, edit the default branch locally.
//
// See: https://learn.microsoft.com/en-us/powerquery-m/web-contents
(reg as nullable text, relPath as text, query as record, bearerToken as text) as binary =>
    if reg = "Europe" then
        Web.Contents(
            "https://eu.cloud.hawkindynamics.com",
            [RelativePath = relPath, Query = query, Headers = [Authorization = "Bearer " & bearerToken]]
        )
    else if reg = "Asia/Pacific" then
        Web.Contents(
            "https://apac.cloud.hawkindynamics.com",
            [RelativePath = relPath, Query = query, Headers = [Authorization = "Bearer " & bearerToken]]
        )
    else
        Web.Contents(
            "https://cloud.hawkindynamics.com",
            [RelativePath = relPath, Query = query, Headers = [Authorization = "Bearer " & bearerToken]]
        )
