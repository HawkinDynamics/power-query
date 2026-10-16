#!/usr/bin/env python3
"""
Verify that every Power Query in the live .pbit template matches its
hand-authored source in data-queries/ and functions/.

The .pbit is rebuilt by hand in Power BI Desktop by pasting in those .pq files,
so the two can drift without anyone noticing. This is the check CI runs.
extract-pbit-queries.py is not a substitute: it writes extracted-queries/,
which is gitignored, so diffing its output can never fail.

Usage:
    python check-pbit-sync.py [<Template Files dir>]

Exits 1 if any query in a live .pbit has no source file or differs from it.
Line endings and trailing whitespace are ignored.

Compared:
    functions (shared expressions)  ->  functions/<name>.pq
    M table partitions              ->  data-queries/<name>.pq
Skipped:
    parameters (they have no source file), calculated (DAX) tables such as
    AllTests, and Power BI's auto date tables. Source files with no counterpart
    in the template, such as ForceTime.pq, are allowed.

Files under any archive/ directory are ignored, as in extract-pbit-queries.py.
"""

import difflib
import glob
import json
import os
import sys
import zipfile

# Model query name -> source file name, for the three that differ.
SOURCE_NAME = {
    "CMJRebound": "CMJ_Rebound",
    "MultiRebound": "MultiReb",
    "TS_Iso": "TS_Isometric",
}


def normalize(text):
    return [line.rstrip() for line in text.replace("\r\n", "\n").strip().split("\n")]


def as_text(expression):
    return "\n".join(expression) if isinstance(expression, list) else expression


def template_queries(pbit_path):
    """Yield (kind, name, m_code) for every function and M table in the .pbit."""
    with zipfile.ZipFile(pbit_path) as z:
        raw = z.read("DataModelSchema").decode("utf-16-le").lstrip("﻿")
    model = json.loads(raw).get("model", {})

    for expr in model.get("expressions", []):
        code = as_text(expr.get("expression", ""))
        if "IsParameterQuery=true" in code:
            continue
        yield "functions", expr["name"], code

    for table in model.get("tables", []):
        for partition in table.get("partitions", []):
            source = partition.get("source", {})
            if source.get("type") != "m":
                continue
            yield "data-queries", table["name"], as_text(source.get("expression", ""))


def check(template_dir):
    pbits = sorted(glob.glob(os.path.join(template_dir, "*.pbit")))
    if not pbits:
        print(f"::error::No live .pbit found in {template_dir}")
        return 1

    failures = 0
    for pbit in pbits:
        checked = 0
        for kind, name, code in template_queries(pbit):
            checked += 1
            source_file = os.path.join(template_dir, kind, SOURCE_NAME.get(name, name) + ".pq")
            label = f"{os.path.basename(pbit)}: {name}"

            if not os.path.isfile(source_file):
                failures += 1
                print(f"::error::{label} has no source file ({kind}/{os.path.basename(source_file)})")
                continue

            with open(source_file, encoding="utf-8") as f:
                source = normalize(f.read())
            if source == normalize(code):
                continue

            failures += 1
            print(f"::error::{label} differs from {kind}/{os.path.basename(source_file)}")
            diff = difflib.unified_diff(
                source,
                normalize(code),
                f"{kind}/{os.path.basename(source_file)}",
                os.path.basename(pbit),
                n=1,
                lineterm="",
            )
            for line in list(diff)[:20]:
                print(f"    {line}")

        print(f"{os.path.basename(pbit)}: checked {checked} queries")

    if failures:
        print(
            f"{failures} query(s) out of sync. "
            "Update the .pq source or rebuild the .pbit in Power BI Desktop."
        )
        return 1
    print("All template queries match their .pq source.")
    return 0


if __name__ == "__main__":
    default = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Template Files")
    sys.exit(check(sys.argv[1] if len(sys.argv) > 1 else default))
