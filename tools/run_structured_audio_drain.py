#!/usr/bin/env python3
"""Drain registered, explicitly approved Irish audio batches safely.

This worker is intentionally orchestration only. The single-batch runner owns
all provider, destination, checksum, claim, lease, and usage gates. Draft,
closed, and completed manifests are reported and skipped; unregistered files
are never discovered or executed.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

TOOLS_DIR = Path(__file__).resolve().parent
ROOT = TOOLS_DIR.parent

import structured_audio_authoring as authoring  # noqa: E402
import structured_audio_generation as generation  # noqa: E402


def registered_batches(root: Path, contract: Any) -> list[tuple[str, dict[str, Any]]]:
    rows: list[tuple[str, dict[str, Any]]] = []
    for ref in contract.store.get("batch_documents", []):
        if not isinstance(ref, dict):
            continue
        batch_id = ref.get("batch_id")
        raw_path = ref.get("path")
        if not isinstance(batch_id, str) or not isinstance(raw_path, str):
            continue
        path = generation.resolve_inside(root, raw_path)
        rows.append((raw_path, generation.load_json(path)))
    return rows


def drain(root: Path, dry_run: bool = False) -> dict[str, Any]:
    errors, contract = authoring.validate_contract(root=root)
    if errors:
        return {"ok": False, "blocked": [{"scope": "contract", "errors": errors}]}

    result: dict[str, Any] = {
        "ok": True,
        "dry_run": dry_run,
        "batches": [],
        "generated": 0,
        "skipped": 0,
        "failed": 0,
        "blocked": [],
    }
    for batch_path, batch in registered_batches(root, contract):
        batch_id = batch.get("batch_id")
        execution = batch.get("execution") or {}
        row: dict[str, Any] = {"batch_id": batch_id, "batch_path": batch_path}
        if execution.get("state") != "approved" or execution.get("provider_calls_allowed") is not True:
            row.update({"status": "skipped", "reason": "batch is not explicitly approved for provider calls"})
            result["skipped"] += 1
            result["batches"].append(row)
            continue

        # The complete authoring contract is immutable for the duration of one
        # drain. Reusing the validated snapshot avoids an O(batches * corpus)
        # rescan before provider work while preserving every per-batch gate.
        info = generation.preflight(
            root,
            batch_path,
            validated_contract=contract,
            contract_errors=errors,
        )
        if not info.get("ok"):
            row.update({"status": "blocked", "errors": info.get("errors", [])})
            result["blocked"].append(row)
            result["batches"].append(row)
            continue
        if not info.get("active_lines"):
            row.update({"status": "skipped", "reason": "no eligible missing lines", "active_lines": 0})
            result["skipped"] += 1
            result["batches"].append(row)
            continue
        if dry_run:
            row.update({"status": "ready", "active_lines": len(info["active_lines"])})
            result["batches"].append(row)
            continue

        try:
            capture = generation.generate(info)
        except (generation.GateError, OSError, ValueError) as error:
            row.update({"status": "failed", "error": str(error)})
            result["failed"] += 1
            result["batches"].append(row)
            result["ok"] = False
            break
        row.update({"status": "generated", **capture})
        result["generated"] += int(capture.get("generated", 0))
        result["batches"].append(row)

    result["next_cursor"] = "complete" if not result["blocked"] and not result["failed"] else "blocked"
    return result


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--canonical-root", type=Path)
    parser.add_argument("--dry-run", action="store_true", help="scan gates without provider calls")
    parser.add_argument("--json", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        root = generation.canonical_root_from_args(args.canonical_root)
        result = drain(root, dry_run=args.dry_run)
        if args.json:
            print(json.dumps(result, ensure_ascii=False, indent=2))
        else:
            print(f"Canonical root: {root}")
            print(f"Generated: {result['generated']}  Skipped: {result['skipped']}  Failed: {result['failed']}")
            for row in result["blocked"]:
                print(f"BLOCKED {row.get('batch_id', row.get('scope'))}: {row.get('errors', row.get('error'))}")
        return 0 if result["ok"] else 2
    except (generation.GateError, ValueError, OSError, json.JSONDecodeError) as error:
        print(f"BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
