#!/usr/bin/env python3
"""Print a deterministic, provider-free phrase-family batch report."""

from __future__ import annotations

import argparse
import json

from corpus_contract import build_batch


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--county", default="mayo")
    parser.add_argument("--all", action="store_true", help="Include non-pending members")
    parser.add_argument("--credits-per-character", type=float, default=1.0)
    args = parser.parse_args()
    report = build_batch(
        args.county,
        only_pending=not args.all,
        credits_per_character=args.credits_per_character,
    )
    print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if report["contract_status"] == "eligible" else 2


if __name__ == "__main__":
    raise SystemExit(main())

