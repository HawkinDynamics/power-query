# Release Notes - v1.0.20260527

**Release Date:** May 27, 2026

**Release Type:** Bug Fix Release (corrects `lastTestedOn` unit handling, non-breaking)

---

## Overview

This release fixes one bug in the v1.0.20260519 templates: the derived `lastTestedOnDate` column was producing incorrect dates because `lastTestedOn` was treated as Unix epoch **milliseconds**, but the Hawkin Cloud API actually returns it in Unix epoch **seconds**. The `lastTestedOn` raw column itself was always correct — only the derived date column was off.

No function signatures changed and no PBI / Excel parameters were renamed. Customers on v1.0.20260519 templates can drop in the new files without reconfiguring anything.

---

## The Fix

`funcAthletes` and the `Generics/Athletes.pq` standalone script previously divided `lastTestedOn` by 1,000 when constructing the date:

```m
// Before (v1.0.20260519) — assumed ms
#datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, 0, [lastTestedOn] / 1000)

// After (v1.0.20260527) — value is already seconds
#datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, 0, [lastTestedOn])
```

If you had a v1.0.20260519 report rendering `lastTestedOnDate`, dates were collapsed to the very beginning of the Unix epoch (i.e. ~1970 plus a few hours/days). The new build produces the correct calendar date for each athlete's most recent test session.

The raw `lastTestedOn` numeric column was unaffected — only the derived `lastTestedOnDate` column was wrong.

---

## Files Changed

### Template Files (Parameterized Template)

- `functions/funcAthletes.pq` — removed `/ 1000` from the `#duration` call.

### Generics (standalone scripts)

- `Generics/Athletes.pq` — same one-line correction.

### Template files (binaries)

- `hawkin-connect-pbi-template-v1.20260527.pbit` — public Power BI template.
- `hawkin-connect-template-builder-v1.20260527.pbix` — Power BI Desktop editable source.
- `hawkin-connect-excel-template-v1.20260527.xltx` — public Excel template.
- `hawkin-connect-excel-template-builder-v1.20260527.xlsx` — Excel editable source.

The prior `v1.20260519` template binaries have been moved to `Template Files/archive/`. The `release-notes-20260519.md` documentation has been moved to `Release Notes/archive/`.

---

## Upgrade Instructions

### Template Files (Power BI `.pbit`) users

1. Download the new `hawkin-connect-pbi-template-v1.20260527.pbit`.
2. Open it in Power BI Desktop.
3. Enter values for the existing parameters (`API Integration Key`, `API Region`, `Organization Name`). No new parameters were added.
4. Click **Load**.

Existing workbooks built from a v1.0.20260519 template can either be rebuilt from the new `.pbit`, or have their `funcAthletes` query body updated in place (replace with the new version from `Template Files/functions/funcAthletes.pq`).

### Excel template users

1. Download the new `hawkin-connect-excel-template-v1.20260527.xltx`.
2. Open it in Excel and re-enter your Integration Key in the parameter cells.

### Generics users (standalone scripts)

1. Replace `Generics/Athletes.pq` with the new version.

---

## Compatibility

- **API Version:** Hawkin Dynamics Cloud API **v1.14+**, same as v1.0.20260519.
- **Power BI Desktop:** Compatible with all recent versions.
- **Power Query M:** Same Power Query M version as v1.0.20260519.

---

## Related

- Original v1.14 feature release: [`release-notes-20260519.md`](archive/release-notes-20260519.md) (archived).
- Hawkin Cloud API spec: `docs/hawkin-api.md` (v1.14).
