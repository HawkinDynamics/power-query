# Release Notes - v1.0.20260519

**Release Date:** May 19, 2026

**Release Type:** Minor Release (Athlete profile fields, ForceTime modernization, non-breaking)

---

## Overview

This release aligns the Power Query layer with **Hawkin Dynamics Cloud API v1.14**, which adds six new optional fields to the `/athletes` endpoint. The Athletes table now surfaces athlete profile data when populated, and the ForceTime waveform query has been modernized to share the same authentication and pagination pattern as the other queries.

No function signatures changed and no PBI parameters were renamed — existing customized templates will continue to work after dropping in the new files. The new athlete profile columns appear only when at least one athlete in the response has the field populated.

---

## New Athlete Profile Columns

`funcAthletes` now expands six optional fields from each athlete record:

| Column             | Type   | Description                                                                                                 |
| ------------------ | ------ | ----------------------------------------------------------------------------------------------------------- |
| `image`            | text   | URL to the athlete's photo. `null` when explicitly cleared; column absent when never set.                   |
| `position`         | text   | Free-text playing position (e.g. "Forward", "Catcher"). Absent when blank.                                  |
| `dob`              | date   | Date of birth, typed as `date` (Power Query parses the ISO-8601 string automatically). Absent when blank.   |
| `sport`            | text   | Free-text sport name (e.g. "Basketball"). Absent when blank.                                                |
| `height`           | number | Athlete height in **centimeters**, range `[1, 300]` when present. Absent when not set or invalid.           |
| `lastTestedOn`     | number | Unix epoch **milliseconds** of the athlete's most recent test session. Absent when no tests on file.        |
| `lastTestedOnDate` | date   | Derived date column from `lastTestedOn` (epoch ms → local date). Only added when `lastTestedOn` is present. |

### Graceful absence handling

Per the v1.14 spec, optional fields are **omitted from the JSON response when absent** — they never appear as `null` (except `image`, which has a three-state model: omitted = never set, `null` = explicitly cleared, string = URL). `funcAthletes` accommodates this with three guards so the function never errors on missing fields:

1. **Conditional expansion** — `Table.ExpandRecordColumn` only receives field names that exist in at least one record (`presentFields` is built dynamically from the response).
2. **Conditional derived columns** — `lastTestedOnDate` is only added when `lastTestedOn` is present in the dataset.
3. **Filtered type casts** — `knownTypes` entries are filtered against `Table.ColumnNames(...)` before `Table.TransformColumnTypes` runs, so missing columns are never type-cast.

The result: an organization where no athletes have any of the new profile fields will see exactly the same Athletes table as before. Customers who have populated these fields get extra columns automatically.

---

## ForceTime Modernization

The ForceTime waveform query has been rewritten to match the architecture of the other queries.

### What changed

- **New function:** `functions/funcForceTime.pq` — fetches the raw force-time waveform for a single test and returns it as a wide table (one row per sample, one column per waveform array). Arrays not returned by the API for the given test type are silently skipped, so the function works across all 11 test types without per-type customization.
- **Data query rewrite:** `data-queries/ForceTime.pq` — was a self-contained script that re-authenticated and hardcoded the waveform fields. Now delegates to `funcForceTime` via the shared `funcAuth` / `Auth` token flow (same pattern as `funcTests`). Drops the hardcoded `XLeftForce(N)` / `XRightForce(N)` / `YLeftForce(N)` / `YRightForce(N)` / `XLeftMoments` / etc. expand ladder.
- **Test ID parameter:** Exposed as a PBI parameter (`Test ID`) so users can switch which test's waveform is loaded without editing the query body.

### Dynamic waveform field detection

`funcForceTime` uses `Record.HasFields` to detect which of the documented waveform arrays (`Time(s)`, `LeftForce(N)`, `RightForce(N)`, `CombinedForce(N)`, `Velocity(m/s)`, `Displacement(m)`, `Power(W)`) the API actually returned, then assembles only those into the output table. New waveform fields the API adds in future versions can be surfaced by extending the `candidateFields` list — no schema migration required.

---

## Athletes Data Query

`data-queries/Athletes.pq` now drops the envelope `count` field from the per-athlete output:

```m
output = funcAthletes(accessToken, endpoint, include_inactive_athletes),
#"Removed Columns" = Table.RemoveColumns(output, {"count"})
```

`funcAthletes` propagates the response-envelope `count` field on every row (since each row inherits it during the `Table.ExpandListColumn` step). The new step removes it so the Athletes table only contains per-athlete columns. No behavior change to other queries.

---

## Files Changed

### Template Files (Parameterized Template)

- `functions/funcAthletes.pq` — expanded to surface the six new profile fields + derived `lastTestedOnDate` column. Added graceful field-absence guards.
- `functions/funcForceTime.pq` — **new** function for fetching force-time waveforms.
- `data-queries/Athletes.pq` — drops the envelope `count` column.
- `data-queries/ForceTime.pq` — full rewrite to delegate to `funcForceTime` via `funcAuth`.

### Generics (standalone scripts)

- `Generics/Athletes.pq` — same field-expansion + graceful-absence guards as `funcAthletes`. Standalone script remains self-contained.
- `Generics/ForceTime.pq` — modernized with the standardized config block and dynamic waveform field detection (drops the hardcoded expand/merge ladder).

### Template files (binaries)

- `hawkin-connect-pbi-template-v1.20260519.pbit` — public Power BI template.
- `hawkin-connect-template-builder-v1.20260519.pbix` — Power BI Desktop editable source.
- `hawkin-connect-excel-template-v1.20260519.xltx` — public Excel template.
- `hawkin-connect-excel-template-builder-v1.20260519.xlsx` — Excel editable source.

The prior `v1.20260427` template binaries have been moved to `Template Files/archive/`.

---

## Upgrade Instructions

### Template Files (Power BI `.pbit`) users

1. Download the new `hawkin-connect-pbi-template-v1.20260519.pbit`.
2. Open it in Power BI Desktop.
3. When prompted, enter values for the existing parameters (`API Integration Key`, `API Region`, `Organization Name`). The new release introduces no new PBI parameters.
4. Click **Load**.

Existing workbooks built from the `v1.20260427` template can either be rebuilt from the new `.pbit` or have their `funcAthletes` / `funcForceTime` / `Athletes` / `ForceTime` queries updated in place (replace each query body with the new version from `Template Files/`).

### Excel template users

1. Download the new `hawkin-connect-excel-template-v1.20260519.xltx`.
2. Open it in Excel and re-enter your Integration Key in the parameter cells.

### Generics users (standalone scripts)

1. Replace `Athletes.pq` and `ForceTime.pq` with the new versions from `Generics/`.
2. No user-config knobs were added or removed — existing values carry over.

---

## Compatibility

- **API Version:** Hawkin Dynamics Cloud API **v1.14+** is required to see the new athlete profile fields. The Power Query code is backward-compatible with v1.13 responses (the new fields simply won't appear when the API doesn't return them).
- **Power BI Desktop:** Compatible with all recent versions.
- **Excel Power Query:** Generic scripts remain Excel-compatible. Parameterized Template / Template Files require Power BI.
- **Backward Compatibility:** Non-breaking. No function signatures or PBI parameters changed.

---

**Previous Releases**

- [v1.0.20260427](release-notes-20260427.md) — API v1.13+ modernization: server pagination, `from`/`to`/`Include Equipment ID`/`Include Inactive Tests`/`Include Inactive Athletes` parameters, function signature changes
- [v1.0.20260323](release-notes-20260323.md) — Dynamic schema handling, function consolidation, folder restructure
- [v1.0.20260109](release-notes-20260109.md) — Bug fixes for endpoint URLs, updated templates
