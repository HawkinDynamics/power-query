# Release Notes - v1.0.20260427

**Release Date:** April 27, 2026

**Release Type:** Major Release (API v1.13+ Modernization, Breaking Changes)

---

## Overview

This release modernizes the entire Power Query layer to align with Hawkin Dynamics Cloud API v1.13+. The biggest change is moving test fetching to **cursor-based server pagination** — the client-side 30-day chunking loop is gone. Three new optional query parameters (`includeInactive` for tests, `includeInactive` for athletes, `includeEid`) are wired through every script. PBI parameters have been renamed for end-user clarity, and `Organization Start Date` has been removed.

This is a **breaking release** for anyone running a customized version of the Parameterized Template scripts: function signatures changed and `Organization Start Date` is gone. Generics users (standalone scripts) only need to refresh the new files; their user-config blocks are forward-compatible.

---

## Cursor-Based Pagination (replaces 30-day chunking)

### Background

The Hawkin API enforces a per-response memory cap. Previously the Parameterized Template handled this client-side by splitting the requested date range into 30-day chunks and looping `funcTests` over each. As of API v1.13, the API itself supports cursor-based pagination (`paginate=true` + `cursor=…`), which is more efficient and handles arbitrarily large result sets without client guesswork.

### What changed

- `funcTests.pq` now appends `&paginate=true` to every request and walks the cursor chain via `List.Generate` until `nextCursor` is null. Page data is concatenated and the envelope metadata (`lastSyncTime`, `lastTestTime`, `count`) is rolled up from the final page.
- All 11 test-type data queries (CMJ, CMJ_Rebound, DropJump, DropLanding, FreeRun, Isometric, MultiReb, SquatJump, TS_Free, TS_Isometric, WeighIn) — in both **Parameterized Template** and **Template Files** — now make a **single** `funcTests` call. The `rangeList` / `epochPairs` / `Table.Combine` chunking machinery has been removed.
- Generic standalone test-type scripts (`Generics/Tests by Test Type/*.pq`) also paginate internally now — the same `List.Generate` loop runs against `baseQueryURL & "&cursor=…"`.

---

## New Optional API Parameters

Three new query parameters are now supported across the whole stack.

### `includeInactive` for Tests

- **PBI parameter:** `Include Inactive Tests` (Logical, default `FALSE`)
- **Function:** `funcTests` accepts `optional includeInactive as nullable logical`
- **Behavior:** When `false`, sends `&includeInactive=false` (returns active tests only). When `true` or omitted, the API default applies (includes inactive).
- Generics: per-test-type scripts gained an `includeInactive = false` user-config variable.

### `includeInactive` for Athletes

- **PBI parameter:** `Include Inactive Athletes` (Logical, default `FALSE`)
- **Function:** `funcAthletes` accepts `optional includeInactive as nullable logical`
- **Behavior:** When `true`, appends `?includeInactive` flag to the athletes URL (the athletes endpoint uses a flag, not a value). When `false` or omitted, only active athletes are returned.
- Generics: `Athletes.pq` gained an `includeInactive = false` user-config variable.

### `includeEid`

- **PBI parameter:** `Include Equipment ID` (Logical, default `FALSE`)
- **Function:** `funcTests` accepts `optional includeEid as nullable logical`
- **Behavior:** When `true`, sends `&includeEid=true` and the API returns an `eid` field (equipment ID — the hardware that produced the trial) on each test record. When `false` or omitted, the field is not present in the response.
- Generics: per-test-type scripts gained an `includeEid = false` user-config variable.

### Graceful absence handling

Because `eid` only appears in responses when explicitly requested, the column-typing pipeline now filters `knownTypes` to columns actually present in the dataset before calling `Table.TransformColumnTypes`. This avoids "column not found" errors when `includeEid` is left at the default `false`. Same approach is used in both `funcTests.pq` and the per-test-type generics.

---

## Optional `from` / `to` Date Filters

`Organization Start Date` has been **deleted**. Test data queries no longer require any date input. By default, every test for the given test type is returned (paging through all results internally). Two new optional PBI parameters let users narrow the window when desired:

- **`from`** (Date, optional) — earliest test date
- **`to`** (Date, optional) — latest test date

In the data queries these are converted from PBI Date values to Unix epoch seconds and passed into `funcTests`, which only emits `&from=` / `&to=` query params when the value is non-null.

---

## PBI Parameter Renames

The Parameterized Template's PBI parameters have been renamed for end-user readability. Inside the `.pq` code, snake_case locals are bound to these display names for coding consistency.

| Old (display name) | New (display name)          | Snake-case local in code    |
| ------------------ | --------------------------- | --------------------------- |
| `SecretKey`        | `API Integration Key`       | `api_integration_key`       |
| `reg`              | `API Region`                | `api_region`                |
| `orgName`          | `Organization Name`         | `organization_name`         |
| _(deleted)_        | `Organization Start Date`   | —                           |
| _(new)_            | `Include Equipment ID`      | `include_eid`               |
| _(new)_            | `Include Inactive Tests`    | `include_inactive_tests`    |
| _(new)_            | `Include Inactive Athletes` | `include_inactive_athletes` |
| _(new)_            | `from`                      | `from_date`                 |
| _(new)_            | `to`                        | `to_date`                   |

---

## Function Signature Changes

### `funcTests.pq` (breaking)

**Before:**

```
(sync, accessToken, endpoint, fromDate as number, toDate as number, testTypeId)
```

**After:**

```
(accessToken, endpoint, testTypeId,
 optional fromDate as nullable number,
 optional toDate as nullable number,
 optional includeInactive as nullable logical,
 optional includeEid as nullable logical)
```

Changes:

- `sync` parameter dropped — the Power BI workflow doesn't use incremental sync
- Required args reduced to `accessToken`, `endpoint`, `testTypeId`
- `fromDate` / `toDate` made optional + nullable
- New `includeInactive` and `includeEid` optional flags

`eid` is now a recognized "known column" (typed as `text`, ordered after `segment`) when present in the response.

### `funcAuth.pq` (breaking)

**Before:**

```
(accessToken, reg, orgName, startDate as datetime)
```

**After:**

```
(accessToken, reg, orgName as nullable text)
```

The `startDate` parameter was removed (along with its `org_start` output column) since `Organization Start Date` is no longer used. `orgName` now also accepts `null` (in addition to `""`) as the "use default v1" sentinel.

### `funcAthletes.pq`

**Before:**

```
(accessToken, endpoint)
```

**After:**

```
(accessToken, endpoint, optional includeInactive as nullable logical)
```

Adds optional `includeInactive` flag. Backward compatible — existing 2-arg callers continue to work.

---

## Files Changed

### Parameterized Template

- `functions/funcTests.pq` — full rewrite (new signature, pagination, eid support)
- `functions/funcAuth.pq` — drops startDate parameter and org_start column
- `functions/funcAthletes.pq` — adds optional includeInactive
- `data-queries/Auth.pq` — drops Organization Start Date reference; uses snake_case locals
- `data-queries/Athletes.pq` — wires Include Inactive Athletes through to funcAthletes
- `data-queries/CMJ.pq`, `CMJ_Rebound.pq`, `DropJump.pq`, `DropLanding.pq`, `FreeRun.pq`, `Isometric.pq`, `MultiReb.pq`, `SquatJump.pq`, `TS_Free.pq`, `TS_Isometric.pq`, `WeighIn.pq` — full rewrite: chunking removed, single `funcTests` call, new PBI parameters wired in

### Template Files

Mirror set of the same edits as Parameterized Template. The `.pbit` template will need to be regenerated in Power BI Desktop to reflect the new parameter set.

### Generics (top-level + bundled trees)

- `Athletes.pq` (×2) — adds `includeInactive` user-config knob and `?includeInactive` URL flag
- `Tests by Test Type/*.pq` (×11 in each tree) — `startDate`/`endDate` user-config renamed to `fromDate`/`toDate`; URL builder uses `&from=`/`&to=` (matching API spec); adds `includeInactive` and `includeEid` user-config knobs; cursor pagination loop; eid added to known column list with graceful absence handling

---

## Upgrade Instructions

### Template Files (Power BI .pbit) users

1. Open the regenerated `.pbit` in Power BI Desktop.
2. When prompted, enter values for the new parameters: `API Integration Key`, `API Region`, `Organization Name`. Leave `from`, `to`, `Include Equipment ID`, `Include Inactive Tests`, `Include Inactive Athletes` blank/false unless you want non-default behavior.
3. Click **Load**.

If you have a workbook already configured with the previous template, you'll need to either rebuild from the new `.pbit` or manually:

- Delete the `Organization Start Date` parameter
- Rename `SecretKey` → `API Integration Key`, `reg` → `API Region`, `orgName` → `Organization Name`
- Add the six new parameters listed above
- Replace each query body with the new version from `Template Files/data-queries/`

### Parameterized Template users (custom report builders)

1. Replace `functions/funcTests.pq`, `functions/funcAuth.pq`, `functions/funcAthletes.pq` with the new versions.
2. Replace `data-queries/Auth.pq`, `data-queries/Athletes.pq`, and all 11 test-type data queries with the new versions.
3. In Power BI's Manage Parameters: rename existing parameters per the table above, delete `Organization Start Date`, and add the six new parameters. The `Logical`-typed parameters (`Include Equipment ID`, `Include Inactive Tests`, `Include Inactive Athletes`) should default to `FALSE`. The `Date`-typed parameters (`from`, `to`) should be optional/blank by default.
4. Refresh.

### Generics users (standalone scripts)

1. Replace your script(s) with the updated versions from `Generics/`.
2. The user-config block now exposes new knobs: `fromDate`, `toDate`, `includeInactive`, `includeEid`. Defaults are backward-compatible (no date filter, active tests only, no equipment ID). Update values only if you want the new behavior.
3. **Note:** if you previously customized `startDate` / `endDate` in a generic script, those have been renamed to `fromDate` / `toDate` and the URL builder now sends `&from=` / `&to=` (matching the API spec, replacing the previous `&startDate=` / `&endDate=` which the API didn't actually consume).

---

## Compatibility

- **API Version:** Hawkin Dynamics Cloud API **v1.13+** required. Earlier versions did not support `paginate`, `includeInactive`, or `includeEid` and will return errors or unexpected behavior.
- **Power BI Desktop:** Compatible with all recent versions.
- **Excel Power Query:** Generic scripts remain Excel-compatible. Parameterized Template / Template Files require Power BI (PBI parameters and inter-query function references aren't supported in Excel).
- **Backward Compatibility:** Breaking — function signatures changed and parameters were renamed/deleted. See Upgrade Instructions above.

---

**Previous Releases**

- [v1.0.20260323](release-notes-20260323.md) — Dynamic schema handling, function consolidation, folder restructure
- [v1.0.20260109](release-notes-20260109.md) — Bug fixes for endpoint URLs, updated templates
