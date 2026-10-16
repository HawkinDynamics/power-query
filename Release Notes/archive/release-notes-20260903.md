# Release Notes - v1.0.20260903

**Release Date:** September 3, 2026

**Release Type:** Feature Release (new optional parameters, non-breaking)

---

## Overview

This release exposes the three response-shape query parameters added to the Hawkin Cloud API in v1.16 (`useNulls`, `rounding`, `nestMetrics`) to the Power Query scripts. They exist so customers migrating from a legacy named API endpoint to `/api/v1` can reproduce that endpoint's payload from Power BI or Excel; new integrations should leave the defaults, which match today's behaviour exactly.

No existing parameter, function signature position, or column changed. Every new argument is optional and defaults to the current behaviour, so v1.0.20260527 reports work unchanged.

---

## What's New

### Generics scripts (`Generics/Tests by Test Type/*.pq`)

Three new knobs in the **User Configuration Section** of every test script:

```m
useNulls = true,       // false = keep the string "N/A" for non-calculable metrics
rounding = false,      // true  = API rounds each metric to its display precision
nestMetrics = false,   // true  = one row per test x metric
```

### `funcTests` (Power BI template flow)

Three optional trailing arguments, in this order: `useNulls`, `rounding`, `nestMetrics`. Existing calls with seven arguments are unchanged.

```m
funcTests(accessToken, endpoint, testTypeId, from_date, to_date, include_inactive_tests, include_eid, use_nulls, rounding, nest_metrics)
```

### Behaviour

| Flag          | Default | When changed                                                                                                                                                                                                                |
| ------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `useNulls`    | `true`  | `false` keeps the API's `"N/A"` string for non-calculable metrics. Metric columns are then left untyped (`any`) instead of `number`, because the text value would fail the numeric cast.                                    |
| `rounding`    | `false` | `true` has the API round each metric to its standard display precision. No effect when `nestMetrics = true`.                                                                                                                |
| `nestMetrics` | `false` | `true` returns one row per test × metric. The per-metric columns are replaced by `metric.id`, `metric.label`, `metric.units` and `metric.value`. A test with no numeric metrics keeps a single row with null metric fields. |

---

## Not in this release

- The `.pbit` / `.xltx` template files and the template `data-queries/*.pq` are unchanged. They do not yet surface the three flags as Power BI parameters; a template rebuild that adds `Use Nulls`, `Round Metrics` and `Nest Metrics` parameters and passes them to `funcTests` will follow. Until then, template users can pass the flags directly in the `funcTests(...)` call of a data query.
- No PDF copy of these notes has been generated yet.
