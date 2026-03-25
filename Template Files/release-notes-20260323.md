# Release Notes - v1.0.20260323
**Release Date:** March 23, 2026

**Release Type:** Feature Release (Architecture Refactor, Dynamic Schema, Folder Restructure)

----------

## Overview
This release introduces a major architectural improvement: dynamic schema handling across all test data queries, consolidation of 12 individual test-type functions into a single reusable `funcTests.pq`, and a reorganization of the repository folder structure for clarity. A new Power BI template reflecting all changes is included.

----------

## Folder Restructure

### Renamed Directories
- `Parameterized/` renamed to **`Parameterized Template/`** — now contains both data-queries and reusable functions, matching the template-based workflow.
- `Template File/` renamed to **`Template Files/`** — pluralized for consistency; contains the same data-queries and functions plus pre-built `.pbit` template files.

### What This Means for Users
- If you previously used scripts from `Parameterized/` or `Template File/`, navigate to the new folder names.
- The `Generics/` folder remains unchanged.

----------

## Dynamic Schema Handling
### Replaces Hardcoded Column Lists
**Issue:** All test data queries previously used hardcoded lists of metric column names when expanding API response records. When the API added or renamed metrics, queries would silently drop new columns or fail entirely.

### Resolution:
All test-type scripts (both Generics and Parameterized Template) now use dynamic field discovery:

```m
allFields = List.Distinct(
    List.Combine(
        List.Transform(
            expandTable[data],
            each if _ is record then Record.FieldNames(_) else {}
        )
    )
),
expandData = Table.ExpandRecordColumn(expandTable, "data", allFields, allFields)
```

This means new metrics added to the API will automatically appear as columns without requiring script updates.

### Dynamic Column Typing
- All known metadata columns (id, timestamp, athlete info, etc.) are typed explicitly.
- All remaining columns (metrics) are automatically typed as `type number`.
- Columns are reordered: metadata prefix, then metrics alphabetically, then summary suffix.

----------

## Function Consolidation
### 12 Functions Replaced by 1
**Before:** Each test type had its own function file (funcCMJ.pq, funcCMJR.pq, funcDJ.pq, funcDL.pq, funcFREE.pq, funcISO.pq, funcMR.pq, funcSJ.pq, funcTSfree.pq, funcTSiso.pq, funcWI.pq, funcGroups.pq).

**After:** A single `funcTests.pq` handles all test types via a `testTypeId` parameter.

#### Files Removed:
- funcCMJ.pq, funcCMJR.pq, funcDJ.pq, funcDL.pq, funcFREE.pq, funcGroups.pq, funcISO.pq, funcMR.pq, funcSJ.pq, funcTSfree.pq, funcTSiso.pq, funcWI.pq

#### Files Added:
- `funcTests.pq` — universal test data function with dynamic schema handling and empty data guard

### Empty Data Guard
`funcTests.pq` now gracefully returns an empty table when no data exists for a given time period, preventing errors during 30-day chunked API calls.

----------

## Test Tag Support
All test data queries now extract and expand test tags:
- `test.tags.id` — comma-separated tag IDs
- `test.tags.name` — comma-separated tag names

Previously, tag data was not extracted from the API response.

----------

## Athlete External Field
All test data queries now include `athlete.external` in the expanded athlete record, providing access to external identifier data.

----------

## Updated Template
### Power BI Template (hd-api-template-v1.20260323.pbit)
- Incorporates all dynamic schema and function consolidation changes
- Uses the unified `funcTests.pq` function
- Includes test tag extraction
- Available in both `Parameterized Template/` and `Template Files/` directories

----------

## Files Changed

### Generics/Tests by Test Type/ (11 files modified)
All test-type scripts updated with dynamic schema handling, tag support, and athlete.external expansion:
- CmJump.pq, CmJumpRebound.pq, DropJump.pq, DropLanding.pq, FreeRun.pq, Isometric.pq, MultiReb.pq, SquatJump.pq, TS_Free.pq, TS_Isometric.pq, WeighIn.pq

### Template Files/ & Parameterized Template/ (functions)
- 12 individual function files removed, replaced by `funcTests.pq`

### Template Files/ & Parameterized Template/ (data-queries, 11 files modified)
- CMJ.pq, CMJ_Rebound.pq, DropJump.pq, DropLanding.pq, FreeRun.pq, Isometric.pq, MultiReb.pq, SquatJump.pq, TS_Free.pq, TS_Isometric.pq, WeighIn.pq

----------

## Upgrade Instructions

### For Template Users (Power BI):
1. Download **hd-api-template-v1.20260323.pbit** from the `Template Files/` directory
2. Open in Power BI Desktop
3. Enter your Integration Key, Region, and Organization ID when prompted
4. Click **Load** — all queries will use the new dynamic schema automatically

### For Parameterized Script Users:
1. Replace your existing function files with the new `funcTests.pq` from `Parameterized Template/functions/`
2. Update your data-query files from `Parameterized Template/data-queries/`
3. You can remove any old individual function files (funcCMJ.pq, etc.)

### For Generics Users:
1. Replace your test-type scripts from `Generics/Tests by Test Type/` with the updated versions
2. No other changes required — the configuration section at the top of each file remains the same

----------

## Compatibility
- **Backward Compatible:** Yes — no breaking changes to query output structure
- **Power BI Desktop:** Compatible with all versions released in 2024–2026
- **API Version:** Supports Hawkin Dynamics Cloud API v1.12

----------

**Previous Releases**
- [v1.0.20260109](release-notes-20260109.md) — Bug fixes for endpoint URLs, updated templates
