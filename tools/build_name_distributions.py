#!/usr/bin/env python3
"""Validate an agreed aggregate source and build app-ready name distributions.

This tool deliberately accepts prepared aggregates only. It does not scrape census,
genealogy, or civil-record services and cannot receive person-level rows.
"""

from __future__ import annotations

import argparse
import csv
import json
from collections import defaultdict
from pathlib import Path


REQUIRED = {
    "subject_id", "dataset", "year", "geography", "count", "suppressed",
    "source_url", "rights_state", "note",
}


def parse_bool(value: str) -> bool:
    normalized = value.strip().lower()
    if normalized in {"true", "1", "yes"}:
        return True
    if normalized in {"false", "0", "no"}:
        return False
    raise ValueError(f"invalid boolean: {value!r}")


def build(rows: list[dict[str, str]]) -> dict[str, list[dict]]:
    output: dict[str, list[dict]] = defaultdict(list)
    for line, row in enumerate(rows, start=2):
        if set(row) != REQUIRED:
            missing = REQUIRED - set(row)
            extra = set(row) - REQUIRED
            raise ValueError(f"line {line}: columns mismatch; missing={missing}, extra={extra}")
        if not row["subject_id"].startswith("name."):
            raise ValueError(f"line {line}: subject_id must be a published name id")
        if row["rights_state"] not in {"cleared", "link-only"}:
            raise ValueError(f"line {line}: rights_state is not releaseable")
        if not row["dataset"].strip() or not row["geography"].strip():
            raise ValueError(f"line {line}: dataset and geography must be visible")
        year = int(row["year"])
        if not 1000 <= year <= 2100:
            raise ValueError(f"line {line}: implausible dataset year")
        suppressed = parse_bool(row["suppressed"])
        if suppressed and row["count"].strip():
            raise ValueError(f"line {line}: suppressed rows must not carry a count")
        count = None if suppressed else int(row["count"])
        if count is not None and count < 0:
            raise ValueError(f"line {line}: count cannot be negative")

        output[row["subject_id"]].append(
            {
                "dataset": row["dataset"].strip(),
                "year": year,
                "note": row["note"].strip(),
                "geography": row["geography"].strip(),
                "count": count,
                "suppressed": suppressed,
                "sourceURL": row["source_url"].strip() or None,
            }
        )
    return dict(output)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    with args.input.open(newline="", encoding="utf-8-sig") as handle:
        rows = list(csv.DictReader(handle))
    result = build(rows)
    args.output.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Validated {sum(map(len, result.values()))} aggregate rows for {len(result)} names")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
