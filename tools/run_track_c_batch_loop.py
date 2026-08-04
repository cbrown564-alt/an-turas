#!/usr/bin/env python3
"""Resumable Track C drain loop with per-batch checkpoints.

Validates the contract once, then generates each approved missing-line batch
individually so a killed process can resume without losing prior captures.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import traceback
from pathlib import Path
from typing import Any

TOOLS_DIR = Path(__file__).resolve().parent
ROOT = TOOLS_DIR.parent

import run_structured_audio_drain as drain_worker  # noqa: E402
import structured_audio_authoring as authoring  # noqa: E402
import structured_audio_generation as generation  # noqa: E402


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--canonical-root", type=Path, required=True)
    parser.add_argument("--payload-id", required=True)
    parser.add_argument("--progress-log", type=Path, required=True)
    parser.add_argument("--result-json", type=Path, required=True)
    parser.add_argument(
        "--max-batches",
        type=int,
        default=0,
        help="optional cap on batches this invocation will attempt (0 = all)",
    )
    return parser.parse_args(argv)


def log(path: Path, message: str) -> None:
    line = f"{time.strftime('%Y-%m-%dT%H:%M:%S%z')} {message}\n"
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(line)
        handle.flush()
    print(line, end="", flush=True)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    root = generation.canonical_root_from_args(args.canonical_root)
    started = time.time()
    result: dict[str, Any] = {
        "ok": True,
        "payload_id": args.payload_id,
        "generated": 0,
        "batches_attempted": 0,
        "batches_generated": 0,
        "batches_skipped": 0,
        "batches_failed": 0,
        "failed": [],
        "generated_batches": [],
    }

    log(args.progress_log, f"start canonical_root={root} payload_id={args.payload_id}")
    errors, contract = authoring.validate_contract(root=root)
    if errors:
        log(args.progress_log, f"contract_invalid count={len(errors)}")
        args.result_json.write_text(json.dumps({"ok": False, "errors": errors[:50]}, indent=2) + "\n")
        return 1
    log(
        args.progress_log,
        f"validated families={len(contract.families)} batches={len(contract.batches)} "
        f"seconds={time.time() - started:.1f}",
    )

    attempted = 0
    for batch_path, batch in drain_worker.registered_batches(root, contract):
        execution = batch.get("execution") or {}
        if execution.get("state") != "approved" or execution.get("provider_calls_allowed") is not True:
            continue
        auth = ((batch.get("spend") or {}).get("cap_authorization") or {})
        if auth.get("payload_id") != args.payload_id:
            continue

        info = generation.preflight(
            root,
            batch_path,
            validated_contract=contract,
            contract_errors=errors,
        )
        if not info.get("ok"):
            result["batches_skipped"] += 1
            log(
                args.progress_log,
                f"skip_blocked {batch.get('batch_id')} errors={info.get('errors', [])[:2]}",
            )
            continue
        if not info.get("active_lines"):
            result["batches_skipped"] += 1
            continue

        if args.max_batches and attempted >= args.max_batches:
            log(args.progress_log, f"max_batches_reached {args.max_batches}")
            break

        attempted += 1
        result["batches_attempted"] += 1
        batch_id = batch.get("batch_id")
        active = len(info["active_lines"])
        log(args.progress_log, f"generate_begin {batch_id} active_lines={active}")
        capture = None
        for retry in range(6):
            try:
                capture = generation.generate(info)
                break
            except Exception as exc:  # noqa: BLE001 - retry rate limits, else checkpoint
                message = str(exc)
                transient = any(
                    token in message
                    for token in (
                        "429",
                        "Too Many Requests",
                        "Connection reset by peer",
                        "Connection aborted",
                        "ConnectionError",
                        "Read timed out",
                        "RemoteDisconnected",
                    )
                )
                if transient and retry < 5:
                    delay = min(90.0, 10.0 * (2**retry))
                    log(
                        args.progress_log,
                        f"generate_retry {batch_id} attempt={retry + 1} delay={delay:.0f}s error={exc}",
                    )
                    time.sleep(delay)
                    # Refresh preflight after a rate-limit pause.
                    info = generation.preflight(
                        root,
                        batch_path,
                        validated_contract=contract,
                        contract_errors=errors,
                    )
                    if not info.get("ok") or not info.get("active_lines"):
                        break
                    continue
                result["ok"] = False
                result["batches_failed"] += 1
                detail = {
                    "batch_id": batch_id,
                    "error": str(exc),
                    "traceback": traceback.format_exc(),
                }
                result["failed"].append(detail)
                log(args.progress_log, f"generate_failed {batch_id} error={exc}")
                args.result_json.write_text(
                    json.dumps(result, ensure_ascii=False, indent=2) + "\n"
                )
                return 1

        if capture is None:
            result["batches_skipped"] += 1
            log(args.progress_log, f"skip_after_retry {batch_id}")
            continue

        generated = int(capture.get("generated", 0))
        result["generated"] += generated
        result["batches_generated"] += 1
        result["generated_batches"].append(
            {
                "batch_id": batch_id,
                "generated": generated,
                "actual_batch_credits": capture.get("actual_batch_credits"),
            }
        )
        log(
            args.progress_log,
            f"generate_ok {batch_id} generated={generated} "
            f"credits={capture.get('actual_batch_credits')} "
            f"total_generated={result['generated']} attempted={attempted}",
        )
        # Pace provider usage queries; subscription endpoint rate-limits bursts.
        time.sleep(1.5)
        args.result_json.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")

    result["elapsed_seconds"] = round(time.time() - started, 1)
    args.result_json.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    log(
        args.progress_log,
        f"complete ok={result['ok']} generated={result['generated']} "
        f"batches_generated={result['batches_generated']} "
        f"batches_failed={result['batches_failed']} "
        f"elapsed={result['elapsed_seconds']}",
    )
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
