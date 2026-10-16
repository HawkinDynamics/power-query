# Release Notes - v1.0.20260918

**Release Date:** September 18, 2026

**Release Type:** Bug Fix Release (scheduled refresh in the Power BI Service; breaking for customized queries)

---

## Overview

Reports built from v1.0.20260527 and earlier templates could not refresh once published to the Power BI Service. They worked in Power BI Desktop, but scheduled and on-demand refresh in the service failed.

The cause was not a limit on REST APIs. The Power BI Service refreshes web sources without a gateway. It does refuse to refresh a **dynamic data source**: a query whose URL can't be determined until the query runs. Every query in the template built its request URL at runtime, and the data tables read that URL out of the loaded `Auth` table. The service could not identify any of them. See Microsoft's [Refresh and dynamic data sources](https://learn.microsoft.com/en-us/power-bi/connect-data/refresh-data#refresh-and-dynamic-data-sources).

This release rebuilds the request layer so every URL is a static literal, with the variable parts passed through the `RelativePath` and `Query` options of `Web.Contents`. That is the pattern Microsoft documents as refreshable.

Parameters are unchanged. Reports built from the template can be republished without reconfiguring anything in Power BI Desktop. Custom queries that call the template's functions directly, or reference the `Auth` table, need updating — see **Breaking Changes**.

---

## The Fix

All API requests now go through one function, `funcGet`, which holds the only URL literals in the template:

```m
// Before (v1.0.20260527) — URL computed at runtime, read from the Auth table
endpoint = currentAuth{0}[url],
Web.Contents(endpoint & "?testTypeId=" & testTypeId & "&paginate=true", ...)

// After (v1.0.20260918) — static base URL, variable parts in the options record
Web.Contents("https://cloud.hawkindynamics.com", [
    RelativePath = "api/v1",
    Query = [testTypeId = testTypeId, paginate = "true"],
    Headers = [Authorization = "Bearer " & accessToken]
])
```

Each data query now reads `API Region` and `Organization Name` straight from the template parameters and requests its own access token. Parameters are not data sources, so the service can identify every endpoint during publish.

The same change fixes two other problems:

- **Formula Firewall.** Passing the token from the `Auth` table into another query's request header is a cross-query data source reference. Power BI Desktop allowed it because it relaxes privacy levels locally, and those settings are not published to the service.
- **Expired-token fallback.** All 17 data queries called `funcAuth()` with no arguments when the cached token had expired. `funcAuth` takes three arguments, so that branch threw an error whenever it ran. Per-query authentication removes the branch.

Pagination cursors now travel in the `Query` record as well, so every page of a paginated pull hits the same static URL. The `from` / `to` epoch values are rounded to whole seconds before they are sent.

---

## Breaking Changes

These only affect reports with **custom queries** that call the template's functions directly. Reports built from the template without query edits are unaffected.

| Before                                                   | After                                                                          |
| -------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `Auth` table in the model                                | Removed. The access token is no longer stored in the published semantic model. |
| `funcAuth(key, region, org)` returns a table             | `funcAuth(key, region)` returns the access token as text                       |
| `funcTests(token, endpoint, testTypeId, ...)`            | `funcTests(token, region, org, testTypeId, ...)`                               |
| `funcAthletes(token, endpoint, ...)`                     | `funcAthletes(token, region, org, ...)`                                        |
| `funcTeams` / `funcGroups` / `funcTags(token, endpoint)` | `funcTeams` / `funcGroups` / `funcTags(token, region, org)`                    |
| `epochNow`, `DateToEpoch`                                | Removed. Neither was referenced by the template.                               |

To update a custom query, replace its auth block with the pattern the template's own data queries use:

```m
reg = if #"API Region" = null then "Americas" else #"API Region",
org = #"Organization Name",
accessToken = funcAuth(#"API Integration Key", reg),
```

If a custom query makes its own `Web.Contents` call instead of going through `funcGet`, write the host as a literal and the options record inline, inside the call. Building the options record in a variable first makes the query a dynamic data source, and the published report won't refresh.

---

## Also in This Build: v1.16 Response-Shape Parameters

v1.0.20260903 added the `useNulls`, `rounding` and `nestMetrics` arguments to `funcTests` in the repository, but the published `.pbit` was not rebuilt, so the template's `funcTests` did not accept them. This build includes them.

You can pass the flags directly in a data query's `funcTests(...)` call. Dedicated Power BI parameters for the three flags (`Use Nulls`, `Round Metrics`, `Nest Metrics`) are still pending.

---

## Files Changed

### Template Files (Parameterized Template)

- `functions/funcGet.pq` — **new.** Single entry point for every API request.
- `functions/funcOrgPath.pq` — **new.** Builds the versioned API path for an org.
- `functions/funcGroups.pq` — **new to the repository.** Already present in the `.pbit`, but had not been committed.
- `functions/funcAuth.pq` — returns the access token as text.
- `functions/funcTests.pq`, `funcAthletes.pq`, `funcTeams.pq`, `funcTags.pq`, `funcForceTime.pq` — take `region` and `org` instead of a prebuilt `endpoint`; request through `funcGet`.
- `data-queries/*.pq` — all 17 rebuilt on template parameters instead of the `Auth` table.
- `data-queries/Auth.pq` — **removed.**
- `functions/epochNow.pq` — **removed.** Only used by the token-expiry check that per-query authentication replaces.

### Template files (binaries)

- `hawkin-connect-pbi-template-v1.20260918.pbit` — public Power BI template.

The prior `v1.20260527` Power BI binaries have been moved to `Template Files/archive/`. The Excel template was not rebuilt and stays at `v1.20260527` (see **Not Changed**).

The `release-notes-20260527.md` and `release-notes-20260903.md` documentation has been moved to `Release Notes/archive/`.

---

## Upgrade Instructions

### New reports

1. Download the new `hawkin-connect-pbi-template-v1.20260918.pbit`.
2. Open it in Power BI Desktop.
3. Enter values for the existing parameters (`API Integration Key`, `API Region`, `Organization Name`). No new parameters were added.
4. Click **Load**.
5. Publish, then complete the one-time credential setup below.

### Existing reports built from an earlier template

The fix touches most queries, so replacing a single query body is not enough. Two options:

- **Rebuild** from the new `.pbit`, then recreate your report pages. This is the simplest path if the report has few customizations.
- **Update in place.** Download `hawkin-connect-power-bi-v1.20260918.zip`, which contains every new query body. In Power BI Desktop, open **Transform data**. For each query below, open its **Advanced Editor** and replace the contents with the file of the same name from the zip:
  1. Create two blank queries named `funcGet` and `funcOrgPath`, using the files in the zip's `functions/` folder. Do these first — every other query depends on them.
  2. Replace `funcAuth`, `funcAthletes`, `funcTeams`, `funcGroups`, `funcTags` and `funcTests`, also from `functions/`.
  3. Replace each data query (`Athletes`, `CMJ`, `Teams` and so on) from the zip's `extracted-queries/` folder. Skip `AllTests.pq` and any `LocalDateTable_` or `DateTableTemplate_` file — Power BI generates those.
  4. Delete the `Auth`, `epochNow` and `DateToEpoch` queries, if present.
  5. Open **Data source settings** → **Data sources in current file**. There should be no dynamic data source warning.

  Queries will show errors partway through. They clear once every step is done.

### One-time setup after publishing

The template contains a literal request for each regional API host, and Power BI registers all of them as data sources when you publish. The service will not run a scheduled refresh until **every** listed source has credentials, including regions your organization does not use.

1. In the Power BI Service, open the semantic model's **Settings** → **Data source credentials**.
2. For each `hawkindynamics.com` source, select **Edit credentials**.
3. Set **Authentication method** to **Anonymous** and **Privacy level** to **Organizational**, then **Sign in**.
4. Expand **Refresh** and set your schedule.

If saving a credential fails with a connection error, select **Skip test connection** in the same dialog and sign in again.

Anonymous is correct: your integration key is sent in a request header the queries build themselves, not through the credential dialog.

---

## Not Changed

- **Excel template.** The dynamic data source restriction is specific to the Power BI Service. Excel evaluates queries on the desktop and was not affected, so `hawkin-connect-excel-template-v1.20260527.xltx` remains current.
- **Generics scripts.** `Generics/*.pq` still build their URLs at runtime. They work in Power BI Desktop and Excel, but a report built from them **will not refresh in the Power BI Service**. Use the Template Files flow for any report you intend to publish.

---

## Compatibility

- **API Version:** Hawkin Dynamics Cloud API **v1.14+**. The optional `useNulls`, `rounding` and `nestMetrics` flags require **v1.16**; they are only sent when set to a non-default value.
- **Power BI Desktop:** Compatible with all recent versions.
- **Power BI Service:** Scheduled refresh supported without a gateway.

---

## Related

- Previous release: [`release-notes-20260903.md`](archive/release-notes-20260903.md) (archived).
- Previous template release: [`release-notes-20260527.md`](archive/release-notes-20260527.md) (archived).
- Microsoft: [Data refresh in Power BI](https://learn.microsoft.com/en-us/power-bi/connect-data/refresh-data) · [`Web.Contents`](https://learn.microsoft.com/en-us/powerquery-m/web-contents)
- Hawkin Cloud API spec: `docs/hawkin-api.md`.
