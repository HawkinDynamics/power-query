#!/usr/bin/env python3
"""
Extract Power Query (M) expressions from a .pbit file into individual .pq text files.

Usage:
    python extract-pbit-queries.py [<file.pbit> ...]

When called without arguments, scans `packages/power-query/Template Files/`
for live .pbit files. When called with one or more .pbit paths (e.g. from
lint-staged), extracts each in turn.

For every input file, queries are written to `<pbit-parent>/extracted-queries/`.

Files under any `archive/` directory are skipped — their .pq is historical
and would clobber the live extracted-queries/ output.

.pbit files are zip archives. The Power Query M code lives inside
DataModelSchema (UTF-16-LE JSON) → model.tables[].partitions[].source.expression.
"""

import glob
import json
import os
import sys
import zipfile


def extract_queries(pbit_path: str, output_dir: str) -> list[str]:
    """Extract all M expressions from a .pbit file and write them as .pq files."""
    with zipfile.ZipFile(pbit_path) as z:
        raw = z.read("DataModelSchema")

    schema = json.loads(raw.decode("utf-16-le"))
    tables = schema.get("model", {}).get("tables", [])

    os.makedirs(output_dir, exist_ok=True)
    written = []

    for table in tables:
        name = table.get("name", "")
        for partition in table.get("partitions", []):
            source = partition.get("source", {})
            expression = source.get("expression")
            if not expression:
                continue

            # Expression can be a string or list of lines
            if isinstance(expression, list):
                code = "\n".join(expression)
            else:
                code = expression

            # Sanitize filename
            safe_name = name.replace("/", "_").replace("\\", "_").replace(" ", "_")
            out_path = os.path.join(output_dir, f"{safe_name}.pq")

            with open(out_path, "w", encoding="utf-8") as f:
                f.write(code)
                f.write("\n")

            written.append(safe_name)

    return written


def is_archived(pbit_path: str) -> bool:
    parts = os.path.normpath(pbit_path).split(os.sep)
    return "archive" in parts


def discover_live_pbits() -> list[str]:
    """Find all live (non-archived) .pbit files under Template Files/."""
    here = os.path.dirname(os.path.abspath(__file__))
    pattern = os.path.join(here, "Template Files", "**", "*.pbit")
    return [p for p in glob.glob(pattern, recursive=True) if not is_archived(p)]


def main():
    if len(sys.argv) >= 2:
        pbit_paths = sys.argv[1:]
    else:
        pbit_paths = discover_live_pbits()
        if not pbit_paths:
            print("No live .pbit files found under Template Files/", file=sys.stderr)
            sys.exit(0)

    failures = 0
    for pbit_path in pbit_paths:
        if not os.path.isfile(pbit_path):
            print(f"Error: {pbit_path} not found", file=sys.stderr)
            failures += 1
            continue

        if is_archived(pbit_path):
            print(f"Skipping archived template: {pbit_path}")
            continue

        output_dir = os.path.join(os.path.dirname(pbit_path), "extracted-queries")
        try:
            written = extract_queries(pbit_path, output_dir)
        except Exception as e:
            print(f"Error extracting {pbit_path}: {e}", file=sys.stderr)
            failures += 1
            continue

        print(f"Extracted {len(written)} queries from {os.path.basename(pbit_path)} to {output_dir}/")

    if failures:
        sys.exit(1)


if __name__ == "__main__":
    main()
