#!/usr/bin/env python3
"""Run a contract-gated Irish audio batch against the canonical app assets.

The authoring validator remains offline. This runner is the deliberately small
provider boundary around it: it only imports requests after every offline gate
passes, queries numeric subscription usage, writes provider responses to a
temporary staging directory, validates them with ffprobe, and creates new files
in the primary main worktree without replacing an existing clip.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


TOOLS_DIR = Path(__file__).resolve().parent
ROOT = TOOLS_DIR.parent
DEFAULT_BATCH = "content/audio/authoring/batches/mayo.d31.capture-prep.2026-08-02.json"
CANONICAL_AUDIO_RELATIVE = Path("ios/AnTuras/Resources/Audio")
LOCKED_VOICE_ID = "NPWroowF4phQhaPWjXPj"
LOCKED_VOICE_NAME = "Irish Cultural Guide"
LOCKED_MODEL_ID = "eleven_v3"
LOCKED_LANGUAGE_CODE = "ga"
LOCKED_OUTPUT_FORMAT = "mp3_44100_192"
APPROVED_CREDIT_CAP = 25_000


class GateError(RuntimeError):
    """A required preflight gate did not pass."""


@dataclass(frozen=True)
class UsageSnapshot:
    captured_at: str
    used_credits: float
    remaining_credits: float

    def as_dict(self) -> dict[str, object]:
        return {
            "captured_at": self.captured_at,
            "used_credits": self.used_credits,
            "remaining_credits": self.remaining_credits,
        }


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def iso_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_project_env(root: Path) -> None:
    """Load the existing project .env without replacing exported variables."""
    path = root / ".env"
    if not path.is_file():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def resolve_inside(root: Path, raw: str | Path) -> Path:
    candidate = (root / raw).resolve() if not Path(raw).is_absolute() else Path(raw).resolve()
    try:
        candidate.relative_to(root.resolve())
    except ValueError as error:
        raise GateError(f"path escapes repository root: {raw}") from error
    return candidate


def primary_worktree(repo_root: Path) -> Path:
    """Return the checked-out main worktree, never the current safe worktree."""
    result = subprocess.run(
        [
            "git",
            "--no-optional-locks",
            "-C",
            str(repo_root),
            "worktree",
            "list",
            "--porcelain",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    blocks: list[dict[str, str]] = []
    block: dict[str, str] = {}
    for line in result.stdout.splitlines() + [""]:
        if not line:
            if block:
                blocks.append(block)
                block = {}
            continue
        key, _, value = line.partition(" ")
        block[key] = value
    for block in blocks:
        if block.get("branch") == "refs/heads/main":
            return Path(block["worktree"]).resolve()
    raise GateError("could not resolve the primary main worktree")


def canonical_root_from_args(raw: Path | None) -> Path:
    if raw is not None:
        candidate = raw.expanduser().resolve()
    else:
        configured = os.environ.get("ANTURAS_CANONICAL_ROOT")
        candidate = (
            Path(configured).expanduser().resolve()
            if configured
            else primary_worktree(ROOT)
        )
    if not candidate.is_dir():
        raise GateError(f"canonical repository root does not exist: {candidate}")
    branch = subprocess.run(
        [
            "git",
            "--no-optional-locks",
            "-C",
            str(candidate),
            "branch",
            "--show-current",
        ],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    if branch != "main":
        raise GateError(
            "canonical repository must be the main worktree; "
            f"resolved branch is {branch or '<detached>'}"
        )
    return candidate


def canonical_audio_path(canonical_root: Path, output_path: str) -> Path:
    """Resolve and strictly validate a batch line's canonical output path."""
    expected_parent = (canonical_root / CANONICAL_AUDIO_RELATIVE).resolve()
    if not isinstance(output_path, str) or not output_path:
        raise GateError("batch line has no output path")
    path = resolve_inside(canonical_root, output_path)
    if path.parent != expected_parent or path.suffix != ".mp3":
        raise GateError(
            f"output path must be under {CANONICAL_AUDIO_RELATIVE}/: {output_path}"
        )
    if path.name.startswith(".") or path.name.endswith(".part"):
        raise GateError(f"temporary/hidden output is not canonical: {output_path}")
    return path


def numeric(value: object) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def usage_snapshot(payload: dict[str, Any]) -> UsageSnapshot:
    used = payload.get("character_count")
    limit = payload.get("character_limit")
    remaining = payload.get("remaining_characters")
    if not numeric(used) or not numeric(limit):
        raise GateError(
            "ElevenLabs usage response lacks numeric character_count/character_limit"
        )
    if remaining is None:
        remaining = limit - used
    if not numeric(remaining) or used < 0 or limit < 0 or remaining < 0:
        raise GateError("ElevenLabs usage response contains invalid numeric usage")
    return UsageSnapshot(
        captured_at=iso_now(),
        used_credits=float(used),
        remaining_credits=float(remaining),
    )


def query_usage(session: Any) -> UsageSnapshot:
    try:
        response = session.get(
            "https://api.elevenlabs.io/v1/user/subscription", timeout=30
        )
        response.raise_for_status()
        return usage_snapshot(response.json())
    except Exception as error:
        raise GateError(f"ElevenLabs usage query failed: {error}") from error


def verify_voice(session: Any) -> None:
    response = session.get(
        f"https://api.elevenlabs.io/v1/voices/{LOCKED_VOICE_ID}", timeout=30
    )
    response.raise_for_status()
    payload = response.json()
    if payload.get("name") != LOCKED_VOICE_NAME:
        raise GateError(
            f"locked voice id resolved to {payload.get('name')!r}, "
            f"expected {LOCKED_VOICE_NAME!r}"
        )


def probe_audio(path: Path) -> dict[str, object]:
    try:
        result = subprocess.run(
            [
                "ffprobe",
                "-v",
                "error",
                "-show_entries",
                "format=duration:stream=codec_name,sample_rate,channels",
                "-of",
                "json",
                str(path),
            ],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as error:
        raise GateError("ffprobe is required to validate generated MP3 output") from error
    payload = json.loads(result.stdout)
    stream = (payload.get("streams") or [{}])[0]
    duration = float((payload.get("format") or {}).get("duration", 0))
    if (
        stream.get("codec_name") != "mp3"
        or int(stream.get("sample_rate", 0)) != 44_100
        or duration <= 0
    ):
        raise GateError(f"invalid generated MP3: {path}")
    return {
        "duration_seconds": round(duration, 3),
        "codec": stream.get("codec_name"),
        "sample_rate_hz": int(stream.get("sample_rate")),
        "channels": stream.get("channels"),
    }


def runtime_manifest_record(
    line: dict[str, Any], target: Path, media: dict[str, object], batch_id: str
) -> dict[str, object]:
    return {
        "slug": line["inventory_slug"],
        "text": line["normalized_text"],
        "sources": [f"structured_batch:{batch_id}"],
        "kind": "phrase",
        "file": target.name,
        "bytes": target.stat().st_size,
        "sha256": sha256_file(target),
        "duration_seconds": media["duration_seconds"],
        "codec": media["codec"],
        "sample_rate_hz": media["sample_rate_hz"],
        "channels": media["channels"],
        "qa_state": "generated_unreviewed",
    }


def validate_runtime_manifest(
    manifest: dict[str, Any], lines: list[dict[str, Any]], targets: dict[str, Path]
) -> None:
    expected = {
        "schema_version": 2,
        "provider": "ElevenLabs",
        "voice": {"name": LOCKED_VOICE_NAME, "id": LOCKED_VOICE_ID},
        "model_id": LOCKED_MODEL_ID,
        "language_code": LOCKED_LANGUAGE_CODE,
        "output_format": LOCKED_OUTPUT_FORMAT,
    }
    for key, value in expected.items():
        if manifest.get(key) != value:
            raise GateError(f"runtime audio manifest {key} is not locked correctly")
    by_slug = {
        row.get("slug"): row
        for row in manifest.get("lines", [])
        if isinstance(row, dict)
    }
    for line in lines:
        slug = line["inventory_slug"]
        target = targets[slug]
        row = by_slug.get(slug)
        if row is not None and row.get("text") != line["normalized_text"]:
            raise GateError(f"runtime manifest text conflict for {slug}")
        if row is not None and not target.exists():
            raise GateError(f"runtime manifest references missing clip for {slug}")
        if target.exists() and row is not None and row.get("sha256") != sha256_file(target):
            raise GateError(f"runtime manifest checksum conflict for {slug}")


def immutable_batch_identity(batch: dict[str, Any]) -> str:
    projection = {
        "batch_id": batch.get("batch_id"),
        "voice_profile": batch.get("voice_profile"),
        "spend": {
            "approved_cap": batch.get("spend", {}).get("approved_cap"),
            "estimate_basis": batch.get("spend", {}).get("estimate_basis"),
            "credits_per_character": batch.get("spend", {}).get("credits_per_character"),
            "estimated_batch_credits": batch.get("spend", {}).get("estimated_batch_credits"),
            "estimated_cumulative_credits": batch.get("spend", {}).get("estimated_cumulative_credits"),
        },
        "lines": [
            {
                "line_id": line.get("line_id"),
                "member_ids": line.get("member_ids"),
                "normalized_text": line.get("normalized_text"),
                "text_sha256": line.get("text_sha256"),
                "inventory_slug": line.get("inventory_slug"),
                "capture_disposition": line.get("capture_disposition"),
                "estimated_characters": line.get("estimated_characters"),
                "estimated_credits": line.get("estimated_credits"),
            }
            for line in batch.get("lines", [])
        ],
    }
    encoded = json.dumps(
        projection, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")
    return sha256_bytes(encoded)


def preflight(
    canonical_root: Path,
    batch_raw: str,
    *,
    validated_contract: Any | None = None,
    contract_errors: list[str] | None = None,
) -> dict[str, Any]:
    import structured_audio_authoring as authoring

    if validated_contract is None:
        errors, contract = authoring.validate_contract(root=canonical_root)
    else:
        errors = list(contract_errors or [])
        contract = validated_contract
    batch_path = resolve_inside(canonical_root, batch_raw)
    if not batch_path.is_file():
        errors.append(f"batch manifest is missing: {batch_raw}")
        return {"ok": False, "errors": errors, "batch_path": str(batch_path)}
    batch = load_json(batch_path)
    if errors:
        return {"ok": False, "errors": errors, "batch_path": str(batch_path)}

    gate_errors: list[str] = []
    lines = batch.get("lines") or []
    execution = batch.get("execution") or {}
    if execution.get("state") != "approved" or execution.get("provider_calls_allowed") is not True:
        gate_errors.append("batch execution is not approved for provider calls")
    active_lines = []
    for line in lines:
        request = line.get("request") or {}
        claim = line.get("claim") or {}
        if request.get("status") == "cancelled" or (
            line.get("provider_result", {}).get("status") == "succeeded"
        ):
            continue
        active_lines.append(line)
        if request.get("status") != "approved":
            gate_errors.append(f"line {line.get('line_id')} is not approved")
        if claim.get("status") != "claimed" or not claim.get("owner_id") or not claim.get("lease_expires_at"):
            gate_errors.append(f"line {line.get('line_id')} has no active generation claim")
        else:
            try:
                expires = datetime.fromisoformat(
                    claim["lease_expires_at"].replace("Z", "+00:00")
                )
                if expires <= datetime.now(timezone.utc):
                    gate_errors.append(f"line {line.get('line_id')} generation claim has expired")
            except ValueError:
                gate_errors.append(
                    f"line {line.get('line_id')} claim lease is not an ISO timestamp"
                )

    spend = batch.get("spend") or {}
    if batch.get("manifest_identity_sha256") != immutable_batch_identity(batch):
        gate_errors.append("deterministic batch manifest identity does not match its contents")

    audio_dir = (canonical_root / CANONICAL_AUDIO_RELATIVE).resolve()
    if not audio_dir.is_dir():
        gate_errors.append(f"canonical audio directory is missing: {audio_dir}")
    targets: dict[str, Path] = {}
    existing: list[dict[str, object]] = []
    for line in lines:
        try:
            target = canonical_audio_path(
                canonical_root, line.get("audio", {}).get("output_path")
            )
        except GateError as error:
            gate_errors.append(str(error))
            continue
        targets[line["inventory_slug"]] = target
        if target.is_symlink():
            gate_errors.append(f"canonical target must not be a symlink: {target}")
        if target.exists():
            try:
                media = probe_audio(target)
                existing.append(
                    {
                        "slug": line["inventory_slug"],
                        "path": str(target),
                        "sha256": sha256_file(target),
                        "bytes": target.stat().st_size,
                        "media": media,
                    }
                )
            except GateError as error:
                gate_errors.append(str(error))

    manifest_path = audio_dir / "manifest.json"
    if manifest_path.is_file():
        try:
            validate_runtime_manifest(
                load_json(manifest_path), lines, targets
            )
        except GateError as error:
            gate_errors.append(str(error))
    else:
        gate_errors.append(f"canonical audio manifest is missing: {manifest_path}")

    # A fresh generation batch must not silently regenerate or claim ownership
    # of a clip already bundled by an earlier batch.
    existing_active = [
        item for item in existing
        if any(
            line.get("inventory_slug") == item["slug"]
            and (line.get("request") or {}).get("status") == "approved"
            for line in active_lines
        )
    ]
    if existing_active:
        gate_errors.append(
            "approved generation lines must be missing; existing clips must be explicitly cancelled for reuse"
        )

    return {
        "ok": not errors and not gate_errors,
        "errors": errors + gate_errors,
        "batch_path": str(batch_path),
        "batch": batch,
        "lines": lines,
        "targets": {slug: str(path) for slug, path in targets.items()},
        "existing": existing,
        "active_lines": active_lines,
        "canonical_root": str(canonical_root),
        "canonical_audio_dir": str(audio_dir),
        "locked_voice": {
            "provider": "ElevenLabs",
            "voice_name": LOCKED_VOICE_NAME,
            "voice_id": LOCKED_VOICE_ID,
            "model_id": LOCKED_MODEL_ID,
            "language_code": LOCKED_LANGUAGE_CODE,
            "output_format": LOCKED_OUTPUT_FORMAT,
        },
        "estimated_batch_credits": spend.get("estimated_batch_credits"),
        "contract_members": len(contract.members),
    }


def atomic_write_json(path: Path, payload: dict[str, Any]) -> None:
    temporary = path.with_suffix(path.suffix + ".part")
    temporary.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    temporary.replace(path)


def copy_without_overwrite(staged: Path, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    try:
        with staged.open("rb") as source, target.open("xb") as destination:
            shutil.copyfileobj(source, destination)
            destination.flush()
            os.fsync(destination.fileno())
    except FileExistsError as error:
        raise GateError(f"refusing to overwrite existing canonical clip: {target}") from error


def generate(batch_info: dict[str, Any]) -> dict[str, Any]:
    if not batch_info.get("ok"):
        raise GateError("generation blocked by preflight gates")
    load_project_env(Path(batch_info["canonical_root"]))
    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key:
        raise GateError("ELEVENLABS_API_KEY is not set")

    import requests

    batch = copy.deepcopy(batch_info["batch"])
    batch_lines_by_id = {
        line["line_id"]: line for line in batch.get("lines", [])
    }
    active_lines = [
        batch_lines_by_id[line["line_id"]]
        for line in batch_info["active_lines"]
    ]
    canonical_root = Path(batch_info["canonical_root"])
    batch_path = Path(batch_info["batch_path"])
    manifest_path = Path(batch_info["canonical_audio_dir"]) / "manifest.json"
    before_batch_digest = sha256_file(batch_path)
    before_runtime_digest = sha256_file(manifest_path)
    staging = Path(
        tempfile.mkdtemp(
            prefix=f"antur-audio-{batch['batch_id']}.", dir="/private/tmp"
        )
    )
    session = requests.Session()
    session.headers.update({"xi-api-key": key, "Content-Type": "application/json"})
    generated: list[dict[str, Any]] = []
    try:
        usage_before = query_usage(session)
        estimated = float(batch["spend"]["estimated_batch_credits"])
        cap_authorization = batch.get("spend", {}).get("cap_authorization", {})
        cap_status = cap_authorization.get("status")
        cap_removed = cap_status == "removed"
        payload_limited = cap_status == "payload_limited"
        payload_baseline = float(cap_authorization.get("baseline_used_credits", 0))
        payload_limit = float(cap_authorization.get("payload_credit_limit", 0))
        if payload_limited:
            payload_used = max(0.0, usage_before.used_credits - payload_baseline)
            if payload_used + estimated > payload_limit:
                raise GateError(
                    "current D32 payload usage plus estimated batch exceeds the explicitly authorized payload limit"
                )
        if not cap_removed and usage_before.used_credits + estimated > APPROVED_CREDIT_CAP:
            if not payload_limited:
                raise GateError(
                    "current numeric usage plus estimated batch exceeds the authorized spending limit"
                )
        if not cap_removed and usage_before.remaining_credits < estimated:
            raise GateError(
                "current numeric remaining usage is below the estimated batch cost"
            )
        verify_voice(session)
        for line in active_lines:
            target = Path(batch_info["targets"][line["inventory_slug"]])
            staged = staging / target.name
            response = session.post(
                f"https://api.elevenlabs.io/v1/text-to-speech/{LOCKED_VOICE_ID}",
                params={"output_format": LOCKED_OUTPUT_FORMAT},
                json={
                    "text": line["normalized_text"],
                    "model_id": LOCKED_MODEL_ID,
                    "language_code": LOCKED_LANGUAGE_CODE,
                },
                timeout=120,
            )
            response.raise_for_status()
            if (
                "audio" not in response.headers.get("content-type", "")
                and not response.content.startswith(b"ID3")
            ):
                raise GateError(
                    f"provider returned a non-audio response for {line['inventory_slug']}"
                )
            staged.write_bytes(response.content)
            media = probe_audio(staged)
            generated.append(
                {
                    "line": line,
                    "target": target,
                    "staged": staged,
                    "media": media,
                    "provider_request_id": response.headers.get("request-id")
                    or response.headers.get("x-request-id")
                    or f"response:{sha256_file(staged)}",
                }
            )
        usage_after = query_usage(session)
        actual_batch_credits = usage_after.used_credits - usage_before.used_credits
        payload_over_limit = (
            payload_limited
            and usage_after.used_credits - payload_baseline > payload_limit
        )
        if actual_batch_credits < 0 or payload_over_limit or (
            not cap_removed and not payload_limited
            and usage_after.used_credits > APPROVED_CREDIT_CAP
        ):
            raise GateError("post-generation numeric usage violates the authorized spending limit")

        runtime_manifest = load_json(manifest_path)
        validate_runtime_manifest(
            runtime_manifest,
            active_lines,
            {slug: Path(path) for slug, path in batch_info["targets"].items()},
        )
        for item in generated:
            target = item["target"]
            if target.exists():
                raise GateError(f"canonical target appeared during generation: {target}")
            copy_without_overwrite(item["staged"], target)

        manifest_lines = list(runtime_manifest.get("lines", []))
        for item in generated:
            manifest_lines.append(
                runtime_manifest_record(
                    item["line"], item["target"], item["media"], batch["batch_id"]
                )
            )
        runtime_manifest["lines"] = sorted(
            manifest_lines, key=lambda row: row["slug"]
        )
        runtime_manifest["generated_at"] = iso_now()
        if sha256_file(manifest_path) != before_runtime_digest:
            raise GateError(
                "canonical runtime manifest changed during generation; "
                "refusing to overwrite it"
            )

        for item in generated:
            line = item["line"]
            line["claim"].update({"status": "completed"})
            line["retry"].update(
                {
                    "attempt_count": line["retry"]["attempt_count"] + 1,
                    "last_attempt_at": iso_now(),
                    "next_retry_at": None,
                }
            )
            line["provider_result"] = {
                "status": "succeeded",
                "provider_request_id": item["provider_request_id"],
                "started_at": usage_before.captured_at,
                "completed_at": usage_after.captured_at,
                "reported_credits": float(line["estimated_credits"]),
                "reported_characters": int(line["estimated_characters"]),
            }
            target = item["target"]
            line["audio"].update(
                {
                    "sha256": sha256_file(target),
                    "bytes": target.stat().st_size,
                    "duration_seconds": item["media"]["duration_seconds"],
                }
            )
            line["audio_qa"] = {"status": "pending", "record": None}
        batch["spend"].update(
            {
                "actual_batch_credits": round(actual_batch_credits, 3),
                "actual_cumulative_credits": round(usage_after.used_credits, 3),
                "usage_before": usage_before.as_dict(),
                "usage_after": usage_after.as_dict(),
            }
        )
        batch["counts"].update(
            {
                "planned": 0,
                "approved": sum(
                    1 for line in batch["lines"]
                    if (line.get("request") or {}).get("status") == "approved"
                ),
                "succeeded": len(generated),
                "failed": 0,
            }
        )
        if sha256_file(batch_path) != before_batch_digest:
            raise GateError(
                "batch manifest changed during generation; refusing to overwrite it"
            )
        atomic_write_json(manifest_path, runtime_manifest)
        atomic_write_json(batch_path, batch)
        return {
            "generated": len(generated),
            "actual_batch_credits": round(actual_batch_credits, 3),
            "usage_before": usage_before.as_dict(),
            "usage_after": usage_after.as_dict(),
            "validation": "MP3/44.1 kHz/positive duration, canonical path, checksums, runtime manifest, batch identity",
            "location": str(canonical_root / CANONICAL_AUDIO_RELATIVE),
            "files": [str(item["target"]) for item in generated],
        }
    finally:
        shutil.rmtree(staging, ignore_errors=True)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--canonical-root", type=Path, help="main worktree used for contract and app assets"
    )
    parser.add_argument(
        "--batch", default=DEFAULT_BATCH, help="registered batch path relative to canonical root"
    )
    parser.add_argument(
        "--generate", action="store_true", help="run the provider only after every gate passes"
    )
    parser.add_argument("--json", action="store_true", help="emit machine-readable preflight output")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        canonical_root = canonical_root_from_args(args.canonical_root)
        info = preflight(canonical_root, args.batch)
        if args.generate:
            result = generate(info)
            print(json.dumps(result, ensure_ascii=False, indent=2))
            return 0
        if args.json:
            print(json.dumps(info, ensure_ascii=False, indent=2, default=str))
        else:
            print(f"Canonical root: {info.get('canonical_root', canonical_root)}")
            print(
                "Canonical audio: "
                f"{info.get('canonical_audio_dir', canonical_root / CANONICAL_AUDIO_RELATIVE)}"
            )
            print(f"Batch: {info.get('batch_path', args.batch)}")
            for error in info.get("errors", []):
                print(f"BLOCKED: {error}")
            if not info.get("errors"):
                print(
                    "READY: all offline gates passed; use --generate to query usage and generate"
                )
        return 0 if info.get("ok") else 2
    except (GateError, subprocess.CalledProcessError, json.JSONDecodeError) as error:
        print(f"BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
