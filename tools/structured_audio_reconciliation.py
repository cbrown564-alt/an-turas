#!/usr/bin/env python3
"""Reconcile the Irish audio ledger without mutating any project files.

The v2 authoring store, registered generation batches, runtime inventory, bundled
catalogue, checksum archives, and generated Xcode resource group are separate
records.  This module compares them and reports their state transitions without
promoting one record into another.  It never calls a provider and never repairs,
deletes, or overwrites a file.
"""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import unicodedata
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

import structured_audio_authoring as authoring
import audio_technical_anomalies as technical_audio


ROOT = authoring.ROOT
BUNDLE_RELATIVE = Path("ios/AnTuras/Resources/Audio")
MANIFEST_RELATIVE = BUNDLE_RELATIVE / "manifest.json"
INVENTORY_RELATIVE = Path("content/audio/irish-inventory-v1.json")
ARCHIVE_RELATIVE = Path("content/audio/archive")
PBX_PROJECT_RELATIVE = Path("ios/AnTuras.xcodeproj/project.pbxproj")
REPORT_SCHEMA_VERSION = 1
REPORT_CONTRACT = "irish_audio_reconciliation_report"
EXTENDED_ARTIFACT_SCHEMA_VERSION = 1
ATLAS_SUBJECTS_RELATIVE = Path("ios/AnTuras/Resources/personal-atlas-subjects.json")
ATLAS_HEADWORDS_RELATIVE = Path("content/audio/atlas-headwords-v1.json")
PEDAGOGY_DRAFT_GLOB = "content/*/*.pack.draft.json"
PEDAGOGY_RUNTIME_GLOB = "ios/AnTuras/Resources/CountyStories/*.json"
EXTERNAL_REFERENCE_RELATIVES = (
    Path("content/personal-atlas/logainm-audit.json"),
    Path("content/personal-atlas/logainm-hierarchy-repairs.json"),
    Path("content/personal-atlas/logainm-ni-review.json"),
)
REVIEWED_V2_AUDIO_QA = frozenset({"passed", "flagged", "failed"})
REVIEWED_RUNTIME_QA = frozenset({"spot_flagged", "qa_passed", "failed"})
GENERATED_INVENTORY_QA = frozenset(
    {"generated_unreviewed", "spot_flagged", "qa_passed"}
)
KNOWN_RUNTIME_QA = frozenset(
    {"pending_generation", "generated_unreviewed", "spot_flagged", "qa_passed", "failed"}
)
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")


def iso_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def parse_timestamp(value: object) -> datetime | None:
    if not isinstance(value, str) or not value.strip():
        return None
    try:
        parsed = datetime.fromisoformat(value.strip().replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        return None
    return parsed.astimezone(timezone.utc)


def normalize_text(value: object) -> str:
    if not isinstance(value, str):
        return ""
    return " ".join(unicodedata.normalize("NFC", value).strip().split())


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative_path(root: Path, path: Path) -> str:
    try:
        return path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return str(path.resolve())


def finding(
    code: str,
    severity: str,
    scope: str,
    identifier: str,
    detail: str,
    recommendation: str,
    **metadata: object,
) -> dict[str, object]:
    record: dict[str, object] = {
        "code": code,
        "severity": severity,
        "scope": scope,
        "identifier": identifier,
        "detail": detail,
        "recommendation": recommendation,
    }
    record.update(metadata)
    return record


def _run_git(root: Path, args: list[str]) -> str | None:
    try:
        result = subprocess.run(
            [
                "git",
                "-c",
                "core.fsmonitor=false",
                "--no-optional-locks",
                "-C",
                str(root),
                *args,
            ],
            check=True,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    return result.stdout


def _parse_worktrees(payload: str) -> list[dict[str, str]]:
    records: list[dict[str, str]] = []
    current: dict[str, str] = {}
    for raw in payload.splitlines() + [""]:
        if not raw:
            if current:
                records.append(current)
                current = {}
            continue
        key, _, value = raw.partition(" ")
        current[key] = value
    return records


def worktree_report(root: Path) -> dict[str, object]:
    branch = (_run_git(root, ["branch", "--show-current"]) or "").strip()
    worktree_payload = _run_git(root, ["worktree", "list", "--porcelain"])
    records = _parse_worktrees(worktree_payload or "")
    main_root: Path | None = None
    for record in records:
        if record.get("branch") == "refs/heads/main" and record.get("worktree"):
            main_root = Path(record["worktree"]).resolve()
            break
    resolved_root = root.resolve()
    return {
        "audit_root": str(resolved_root),
        "current_branch": branch or None,
        "is_main_branch": branch == "main",
        "primary_main_worktree": str(main_root) if main_root else None,
        "is_primary_main_worktree": main_root == resolved_root if main_root else False,
        "provider_destination": (
            str(main_root / BUNDLE_RELATIVE) if main_root else None
        ),
        "provider_destination_is_current": main_root == resolved_root if main_root else False,
        "mutation_policy": "read_only; this report never changes the provider destination",
    }


def _metadata_findings(manifest: dict[str, Any]) -> list[dict[str, object]]:
    expected = {
        "schema_version": 2,
        "provider": "ElevenLabs",
        "voice": {"name": "Irish Cultural Guide", "id": "NPWroowF4phQhaPWjXPj"},
        "model_id": "eleven_v3",
        "language_code": "ga",
        "output_format": "mp3_44100_192",
    }
    results: list[dict[str, object]] = []
    for key, value in expected.items():
        if manifest.get(key) != value:
            results.append(
                finding(
                    "bundle_manifest_voice_or_format_drift",
                    "error",
                    "runtime_manifest",
                    key,
                    f"runtime manifest {key!r} is {manifest.get(key)!r}, expected the locked value",
                    "Preserve the Irish Cultural Guide / eleven_v3 / ga / mp3_44100_192 lock and inspect the manifest manually.",
                    expected=value,
                    actual=manifest.get(key),
                )
            )
    return results


def scan_runtime_bundle(
    root: Path,
    manifest: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Inspect the bundle directory and manifest without requiring valid audio."""
    bundle_dir = (root / BUNDLE_RELATIVE).resolve()
    manifest_path = root / MANIFEST_RELATIVE
    findings: list[dict[str, object]] = []
    rows: list[dict[str, Any]] = []
    if manifest is None and manifest_path.is_file():
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            findings.append(
                finding(
                    "bundle_manifest_unreadable",
                    "error",
                    "runtime_manifest",
                    relative_path(root, manifest_path),
                    f"cannot read the runtime manifest: {error}",
                    "Preserve the existing file and restore or inspect it manually before any bundle update.",
                )
            )
            manifest = {}
    elif manifest is None:
        manifest = {}

    if not manifest_path.is_file():
        findings.append(
            finding(
                "bundle_manifest_missing",
                "error",
                "runtime_manifest",
                relative_path(root, manifest_path),
                "canonical runtime audio manifest is missing",
                "Restore or inspect the authoritative manifest manually before any bundle or provider operation.",
            )
        )

    if not isinstance(manifest, dict):
        findings.append(
            finding(
                "bundle_manifest_invalid",
                "error",
                "runtime_manifest",
                relative_path(root, manifest_path),
                "runtime manifest must be a JSON object",
                "Do not regenerate or overwrite the manifest automatically; restore the authoritative catalogue manually.",
            )
        )
        manifest = {}
    findings.extend(_metadata_findings(manifest))

    raw_rows = manifest.get("lines")
    if not isinstance(raw_rows, list):
        findings.append(
            finding(
                "bundle_manifest_lines_invalid",
                "error",
                "runtime_manifest",
                relative_path(root, manifest_path),
                "runtime manifest lines must be a list",
                "Inspect the manifest and retain the last known-good snapshot before resuming capture.",
            )
        )
        raw_rows = []
    rows = [row for row in raw_rows if isinstance(row, dict)]
    if len(rows) != len(raw_rows):
        findings.append(
            finding(
                "bundle_manifest_row_invalid",
                "error",
                "runtime_manifest",
                relative_path(root, manifest_path),
                "runtime manifest contains a non-object line",
                "Preserve the manifest and resolve the malformed line manually.",
            )
        )

    actual_files: dict[str, Path] = {}
    if not bundle_dir.is_dir():
        findings.append(
            finding(
                "bundle_directory_missing",
                "error",
                "bundle",
                relative_path(root, bundle_dir),
                "canonical audio bundle directory is missing",
                "Do not create or repopulate it automatically from a non-canonical worktree; inspect the main worktree destination.",
            )
        )
    else:
        for path in sorted(bundle_dir.glob("*.mp3")):
            actual_files[path.name] = path
            if path.is_symlink():
                findings.append(
                    finding(
                        "bundle_symlink_file",
                        "error",
                        "bundle",
                        relative_path(root, path),
                        "canonical bundle MP3 is a symlink",
                        "Replace only through an explicit, reviewed recovery operation; this audit never follows a symlink as a canonical asset.",
                    )
                )

    by_slug: dict[str, dict[str, Any]] = {}
    by_text: dict[str, list[dict[str, Any]]] = defaultdict(list)
    referenced_files: set[str] = set()
    checksum_verified_rows: list[dict[str, Any]] = []
    missing_files: list[str] = []
    checksum_mismatches: list[str] = []
    byte_mismatches: list[str] = []
    integrity_by_file: dict[str, dict[str, Any]] = {}
    for index, row in enumerate(rows):
        identifier = str(row.get("slug") or f"row-{index}")
        slug = row.get("slug")
        text = row.get("text")
        if not isinstance(slug, str) or not slug:
            findings.append(
                finding(
                    "bundle_manifest_slug_invalid",
                    "error",
                    "runtime_manifest",
                    identifier,
                    "manifest row has no non-empty slug",
                    "Resolve the row manually before changing the bundle.",
                )
            )
            continue
        if slug in by_slug:
            findings.append(
                finding(
                    "duplicate_bundle_slug",
                    "error",
                    "runtime_manifest",
                    slug,
                    "runtime manifest contains duplicate slug rows",
                    "Merge or retire the duplicate manually; do not let a later row silently win.",
                )
            )
        by_slug[slug] = row
        if not isinstance(text, str) or not text.strip():
            findings.append(
                finding(
                    "bundle_manifest_text_invalid",
                    "error",
                    "runtime_manifest",
                    slug,
                    "manifest row has no non-empty Irish text",
                    "Resolve the text identity manually before any capture or bundle update.",
                )
            )
        else:
            normalized = normalize_text(text)
            by_text[normalized].append(row)
            if authoring.canonical_audio_slug(normalized) != slug:
                findings.append(
                    finding(
                        "bundle_slug_text_drift",
                        "error",
                        "runtime_manifest",
                        slug,
                        "manifest slug does not match its canonical normalized Irish text",
                        "Preserve the clip and resolve the text/slug identity manually.",
                        normalized_text=normalized,
                        expected_slug=authoring.canonical_audio_slug(normalized),
                    )
                )
        if row.get("qa_state") not in KNOWN_RUNTIME_QA:
            findings.append(
                finding(
                    "bundle_manifest_qa_state_invalid",
                    "warning",
                    "runtime_manifest",
                    slug,
                    f"manifest row has unknown qa_state {row.get('qa_state')!r}",
                    "Keep QA state explicit and resolve it through the audio review record.",
                )
            )

        filename = row.get("file")
        if not isinstance(filename, str) or not filename or Path(filename).name != filename:
            findings.append(
                finding(
                    "bundle_manifest_file_path_invalid",
                    "error",
                    "runtime_manifest",
                    slug,
                    "manifest file must be a basename inside the canonical Audio directory",
                    "Do not follow a path outside the canonical bundle; resolve the row manually.",
                )
            )
            continue
        referenced_files.add(filename)
        if filename != f"{slug}.mp3":
            findings.append(
                finding(
                    "bundle_manifest_file_slug_drift",
                    "error",
                    "runtime_manifest",
                    slug,
                    f"manifest file {filename!r} does not match the slug",
                    "Resolve the identity manually; never silently rename or replace an MP3.",
                )
            )
        path = actual_files.get(filename)
        if path is None:
            missing_files.append(slug)
            findings.append(
                finding(
                    "missing_bundle_file",
                    "error",
                    "bundle",
                    slug,
                    f"manifest references missing bundled file {filename!r}",
                    "Recover or re-capture the exact line only after inspecting the batch and claim history; do not overwrite an existing file.",
                    file=relative_path(root, bundle_dir / filename),
                )
            )
            continue
        actual_sha = sha256_file(path)
        actual_bytes = path.stat().st_size
        integrity_by_file[filename] = {
            "sha256": actual_sha,
            "bytes": actual_bytes,
        }
        if row.get("sha256") != actual_sha:
            checksum_mismatches.append(slug)
            findings.append(
                finding(
                    "bundle_checksum_mismatch",
                    "error",
                    "bundle",
                    slug,
                    "runtime manifest checksum does not match the bundled MP3",
                    "Preserve the bytes and manifest; resolve the mismatch manually before release or regeneration.",
                    file=relative_path(root, path),
                    recorded_sha256=row.get("sha256"),
                    actual_sha256=actual_sha,
                )
            )
        if row.get("bytes") != actual_bytes:
            byte_mismatches.append(slug)
            findings.append(
                finding(
                    "bundle_byte_count_mismatch",
                    "error",
                    "bundle",
                    slug,
                    "runtime manifest byte count does not match the bundled MP3",
                    "Preserve the bytes and manifest; resolve the mismatch manually.",
                    recorded_bytes=row.get("bytes"),
                    actual_bytes=actual_bytes,
                )
            )
        if row.get("sha256") == actual_sha and row.get("bytes") == actual_bytes:
            checksum_verified_rows.append(row)

    duplicate_texts = {
        text: rows_for_text
        for text, rows_for_text in by_text.items()
        if len(rows_for_text) > 1
    }
    for text, rows_for_text in sorted(duplicate_texts.items()):
        slugs = sorted(str(row.get("slug")) for row in rows_for_text)
        findings.append(
            finding(
                "duplicate_bundle_normalized_text",
                "error",
                "runtime_manifest",
                ",".join(slugs),
                "runtime manifest contains duplicate normalized Irish text rows",
                "Merge the identity manually before adding another clip; do not deduplicate by deleting a file.",
                normalized_text=text,
                slugs=slugs,
            )
        )

    orphan_files = sorted(set(actual_files) - referenced_files)
    for filename in orphan_files:
        if filename not in integrity_by_file:
            integrity_by_file[filename] = {
                "sha256": sha256_file(actual_files[filename]),
                "bytes": actual_files[filename].stat().st_size,
            }
        findings.append(
            finding(
                "orphan_bundle_file",
                "warning",
                "bundle",
                filename,
                "MP3 exists in the canonical Audio directory but is not referenced by the runtime manifest",
                "Keep the file intact and decide manually whether to register, archive, or retire it; this audit never deletes it.",
                file=relative_path(root, actual_files[filename]),
            )
        )

    technical_entries: list[dict[str, Any]] = []
    for row in rows:
        filename = row.get("file")
        if not isinstance(filename, str) or Path(filename).name != filename:
            continue
        path = actual_files.get(filename)
        integrity = integrity_by_file.get(filename, {})
        technical_entries.append(
            {
                "slug": row.get("slug"),
                "file": filename,
                "path": path,
                "text": row.get("text"),
                "sources": row.get("sources"),
                "recorded_sha256": row.get("sha256"),
                "actual_sha256": integrity.get("sha256"),
            }
        )
    for filename in orphan_files:
        integrity = integrity_by_file[filename]
        technical_entries.append(
            {
                "slug": Path(filename).stem,
                "file": filename,
                "path": actual_files[filename],
                "text": None,
                "sources": [],
                "recorded_sha256": None,
                "actual_sha256": integrity["sha256"],
            }
        )
    technical_report = technical_audio.audit_inventory(
        technical_entries,
        source_manifest=relative_path(root, manifest_path),
    )
    for row in technical_report["rows"]:
        status = row["status"]
        if status not in {"quarantine", "review"}:
            continue
        reasons = row["reasons"]
        disposition = "quarantine" if status == "quarantine" else "review"
        severity = "error" if disposition == "quarantine" else "warning"
        findings.append(
            finding(
                "audio_technical_quarantine" if disposition == "quarantine" else "audio_technical_review_required",
                severity,
                "bundle",
                str(row.get("slug") or row.get("file")),
                f"local technical audio inspection requires {disposition}: {', '.join(reasons)}",
                "Keep the clip out of learner release and inspect or replace it through an explicit reviewed audio operation; this reconciliation never mutates files or QA state.",
                disposition=disposition,
                reasons=reasons,
                file=row.get("file"),
                measurements=row.get("measurements"),
                provenance=row.get("provenance"),
                technical_audit=technical_report["contract"],
            )
        )
    if technical_report["summary"]["decoder_unavailable"]:
        findings.append(
            finding(
                "audio_technical_audit_unavailable",
                "error",
                "bundle",
                technical_report["decoder"]["program"],
                "the configured local decoder was unavailable, so technical audio inspection could not complete",
                "Install or restore the declared local decoder before treating the tranche as technically inspected; no provider or network fallback is allowed.",
                technical_audit=technical_report["contract"],
            )
        )

    return {
        "manifest_path": relative_path(root, manifest_path),
        "manifest_exists": manifest_path.is_file(),
        "manifest": manifest,
        "rows": rows,
        "by_slug": by_slug,
        "by_text": by_text,
        "actual_files": actual_files,
        "referenced_files": sorted(referenced_files),
        "missing_files": sorted(missing_files),
        "orphan_files": orphan_files,
        "checksum_mismatches": sorted(checksum_mismatches),
        "byte_mismatches": sorted(byte_mismatches),
        "checksum_verified_rows": checksum_verified_rows,
        "technical_audio": technical_report,
        "findings": findings,
    }


def scan_inventory(
    root: Path,
    inventory: dict[str, Any],
    bundle: dict[str, Any],
) -> dict[str, Any]:
    findings: list[dict[str, object]] = []
    raw_entries = inventory.get("entries") if isinstance(inventory, dict) else None
    if not isinstance(raw_entries, list):
        raw_entries = []
        findings.append(
            finding(
                "inventory_entries_invalid",
                "error",
                "inventory",
                relative_path(root, root / INVENTORY_RELATIVE),
                "runtime inventory entries must be a list",
                "Preserve the inventory and resolve its shape manually before any capture.",
            )
        )
    entries = [entry for entry in raw_entries if isinstance(entry, dict)]
    by_slug: dict[str, dict[str, Any]] = {}
    by_text: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for index, entry in enumerate(entries):
        slug = entry.get("slug")
        text = entry.get("text")
        identifier = str(slug or f"entry-{index}")
        if not isinstance(slug, str) or not slug:
            findings.append(
                finding(
                    "inventory_slug_invalid",
                    "error",
                    "inventory",
                    identifier,
                    "inventory entry has no non-empty slug",
                    "Resolve the inventory identity manually before any regeneration.",
                )
            )
            continue
        if slug in by_slug:
            findings.append(
                finding(
                    "duplicate_inventory_slug",
                    "error",
                    "inventory",
                    slug,
                    "inventory contains duplicate slug rows",
                    "Merge or retire the duplicate manually; do not silently replace its clip.",
                )
            )
        by_slug[slug] = entry
        normalized = normalize_text(text)
        if not normalized:
            findings.append(
                finding(
                    "inventory_text_invalid",
                    "error",
                    "inventory",
                    slug,
                    "inventory entry has no non-empty text",
                    "Resolve the text identity manually before any capture or release decision.",
                )
            )
            continue
        by_text[normalized].append(entry)
        expected_slug = authoring.canonical_audio_slug(normalized)
        if slug != expected_slug:
            findings.append(
                finding(
                    "inventory_slug_text_drift",
                    "error",
                    "inventory",
                    slug,
                    "inventory slug does not match canonical normalized Irish text",
                    "Preserve the existing clip and resolve the text/slug identity manually.",
                    normalized_text=normalized,
                    expected_slug=expected_slug,
                )
            )
        qa_state = entry.get("qa_state")
        if qa_state not in KNOWN_RUNTIME_QA:
            findings.append(
                finding(
                    "inventory_qa_state_invalid",
                    "warning",
                    "inventory",
                    slug,
                    f"inventory entry has unknown qa_state {qa_state!r}",
                    "Keep the QA state explicit and tied to a review record.",
                )
            )

    for text, rows in sorted(by_text.items()):
        if len(rows) > 1:
            slugs = sorted(str(row.get("slug")) for row in rows)
            findings.append(
                finding(
                    "duplicate_inventory_normalized_text",
                    "error",
                    "inventory",
                    ",".join(slugs),
                    "inventory contains duplicate normalized Irish text rows",
                    "Merge the identity manually; do not infer that duplicate rows are separate voice lines.",
                    normalized_text=text,
                    slugs=slugs,
                )
            )

    counts = inventory.get("counts") if isinstance(inventory, dict) else None
    expected_counts = {
        "total": len(entries),
        "headword": sum(1 for entry in entries if entry.get("kind") == "headword"),
        "phrase": sum(1 for entry in entries if entry.get("kind") == "phrase"),
        "conversation": sum(1 for entry in entries if entry.get("kind") == "conversation"),
        "already_generated": sum(
            1 for entry in entries if entry.get("qa_state") in GENERATED_INVENTORY_QA
        ),
        "pending_generation": sum(
            1 for entry in entries if entry.get("qa_state") == "pending_generation"
        ),
    }
    if counts != expected_counts:
        findings.append(
            finding(
                "inventory_counts_drift",
                "error",
                "inventory",
                relative_path(root, root / INVENTORY_RELATIVE),
                "inventory counts do not match its entries",
                "Recompute the inventory counts through an explicit reviewed update; this audit does not rewrite them.",
                recorded_counts=counts,
                computed_counts=expected_counts,
            )
        )

    bundle_by_slug = bundle["by_slug"]
    inventory_not_bundled: list[str] = []
    bundle_not_inventory: list[str] = []
    qa_drift: list[str] = []
    for slug, entry in by_slug.items():
        row = bundle_by_slug.get(slug)
        if row is None:
            inventory_not_bundled.append(slug)
            if entry.get("qa_state") in GENERATED_INVENTORY_QA:
                findings.append(
                    finding(
                        "inventory_clip_missing_from_bundle",
                        "error",
                        "inventory",
                        slug,
                        "inventory marks the line generated but the runtime bundle has no row",
                        "Inspect the inventory and bundle records; re-capture only through a new authorized batch, never by overwriting.",
                    )
                )
            continue
        if normalize_text(entry.get("text")) != normalize_text(row.get("text")):
            findings.append(
                finding(
                    "inventory_bundle_text_conflict",
                    "error",
                    "inventory_bundle",
                    slug,
                    "inventory and runtime manifest disagree about normalized Irish text",
                    "Preserve both records and resolve the text identity manually before release.",
                )
            )
        if entry.get("qa_state") != row.get("qa_state"):
            qa_drift.append(slug)
    if qa_drift:
        findings.append(
            finding(
                "inventory_bundle_qa_drift",
                "warning",
                "inventory_bundle",
                "runtime-qa-metadata",
                "inventory QA states are not reflected in the corresponding runtime manifest rows",
                "Keep the independent QA state records; reconcile the display metadata manually without treating bundling as QA approval.",
                count=len(qa_drift),
                slugs=sorted(qa_drift),
            )
        )
    for slug, row in bundle_by_slug.items():
        if slug not in by_slug:
            bundle_not_inventory.append(slug)
    if bundle_not_inventory:
        findings.append(
            finding(
                "bundle_lines_outside_inventory",
                "warning",
                "inventory_bundle",
                "runtime-only",
                "runtime bundle contains legacy or otherwise unregistered lines outside the v1 inventory",
                "Keep legacy clips intact and retain their source attribution; decide manually whether each line belongs in a reviewed v2 batch.",
                count=len(bundle_not_inventory),
                slugs=sorted(bundle_not_inventory),
            )
        )

    return {
        "entries": entries,
        "by_slug": by_slug,
        "by_text": by_text,
        "counts": expected_counts,
        "recorded_counts": counts,
        "inventory_not_bundled": sorted(inventory_not_bundled),
        "bundle_not_inventory": sorted(bundle_not_inventory),
        "qa_drift": sorted(qa_drift),
        "reviewed_entries": [
            entry for entry in entries if entry.get("qa_state") in REVIEWED_RUNTIME_QA
        ],
        "passed_entries": [
            entry for entry in entries if entry.get("qa_state") == "qa_passed"
        ],
        "findings": findings,
    }


def _batch_line_authorized(
    batch: dict[str, Any],
    line: dict[str, Any],
    contract: authoring.LoadedContract,
) -> bool:
    execution = batch.get("execution") or {}
    request = line.get("request") or {}
    if execution.get("state") != "approved" or execution.get("provider_calls_allowed") is not True:
        return False
    if request.get("status") != "approved":
        return False
    for member_id in line.get("member_ids") or []:
        member = contract.members.get(member_id)
        if member is None:
            return False
        states = member.get("states") or {}
        capture = states.get("capture_request") or {}
        if states.get("authoring", {}).get("status") != "complete":
            return False
        if capture.get("status") != "requested":
            return False
        if line.get("line_id") not in capture.get("batch_line_ids", []):
            return False
    return bool(line.get("member_ids"))


def _canonical_batch_output(root: Path, line: dict[str, Any]) -> Path | None:
    slug = line.get("inventory_slug")
    expected = f"ios/AnTuras/Resources/Audio/{slug}.mp3"
    audio = line.get("audio") or {}
    output = audio.get("output_path")
    if not isinstance(slug, str) or not slug or output != expected:
        return None
    path = authoring.resolve_repo_path(root, output)
    if path is None:
        return None
    return path


def provider_success_issues(
    root: Path,
    batch: dict[str, Any],
    line: dict[str, Any],
) -> dict[str, Any]:
    """Return independent validity flags for a claimed provider success."""
    result = line.get("provider_result") or {}
    audio = line.get("audio") or {}
    issues: list[str] = []
    checksum_ok = False
    target = _canonical_batch_output(root, line)
    if result.get("status") != "succeeded":
        return {"valid": False, "issues": [], "checksum_ok": False, "target": target}
    if (batch.get("execution") or {}).get("state") not in {"approved", "closed"}:
        issues.append("batch_not_approved_or_closed")
    if (line.get("request") or {}).get("status") != "approved":
        issues.append("line_request_not_approved")
    claim = line.get("claim") or {}
    if claim.get("status") != "completed":
        issues.append("claim_not_completed")
    retry = line.get("retry") or {}
    if not isinstance(retry.get("attempt_count"), int) or retry.get("attempt_count", 0) < 1:
        issues.append("attempt_count_missing")
    for field in ("provider_request_id", "started_at", "completed_at"):
        if not isinstance(result.get(field), str) or not result[field].strip():
            issues.append(f"provider_result_{field}_missing")
    if all(result.get(field) is None for field in ("reported_credits", "reported_characters")):
        issues.append("provider_cost_missing")
    if target is None:
        issues.append("canonical_output_path_invalid")
    elif target.is_symlink():
        issues.append("canonical_output_is_symlink")
    elif not target.is_file():
        issues.append("canonical_output_missing")
    else:
        actual_sha = sha256_file(target)
        actual_bytes = target.stat().st_size
        checksum_ok = audio.get("sha256") == actual_sha and audio.get("bytes") == actual_bytes
        if not SHA256_RE.fullmatch(str(audio.get("sha256") or "")):
            issues.append("audio_sha256_invalid")
        elif audio.get("sha256") != actual_sha:
            issues.append("audio_checksum_mismatch")
        if audio.get("bytes") != actual_bytes:
            issues.append("audio_byte_count_mismatch")
    duration = audio.get("duration_seconds")
    if not isinstance(duration, (int, float)) or isinstance(duration, bool) or duration <= 0:
        issues.append("audio_duration_missing_or_invalid")
    return {
        "valid": not issues,
        "issues": sorted(set(issues)),
        "checksum_ok": checksum_ok,
        "target": target,
    }


def _claim_state(
    line: dict[str, Any],
    as_of: datetime,
) -> dict[str, Any]:
    claim = line.get("claim") or {}
    status = claim.get("status")
    lease = claim.get("lease_expires_at")
    parsed = parse_timestamp(lease)
    invalid_lease = status == "claimed" and lease is not None and parsed is None
    stale = status == "claimed" and parsed is not None and parsed <= as_of
    return {
        "status": status,
        "owner_id": claim.get("owner_id"),
        "claimed_at": claim.get("claimed_at"),
        "lease_expires_at": lease,
        "lease_expires_at_parsed": parsed.isoformat() if parsed else None,
        "invalid_lease": invalid_lease,
        "stale": stale,
        "active": status == "claimed" and not stale and not invalid_lease,
    }


def scan_archives(
    root: Path,
    bundle: dict[str, Any],
) -> dict[str, Any]:
    findings: list[dict[str, object]] = []
    snapshots: list[dict[str, Any]] = []
    archive_dir = root / ARCHIVE_RELATIVE
    current_by_slug = bundle["by_slug"]
    for path in sorted(archive_dir.glob("*.json")) if archive_dir.is_dir() else []:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            findings.append(
                finding(
                    "archive_unreadable",
                    "warning",
                    "archive",
                    relative_path(root, path),
                    f"checksum archive cannot be read: {error}",
                    "Preserve the archive and inspect it manually; do not regenerate over the historical snapshot.",
                )
            )
            continue
        rows = payload.get("clips") if isinstance(payload, dict) else None
        if not isinstance(rows, list):
            findings.append(
                finding(
                    "archive_shape_invalid",
                    "warning",
                    "archive",
                    relative_path(root, path),
                    "checksum archive clips must be a list",
                    "Preserve the historical archive and resolve its shape manually.",
                )
            )
            continue
        by_slug: dict[str, dict[str, Any]] = {}
        for row in rows:
            if not isinstance(row, dict) or not isinstance(row.get("slug"), str):
                continue
            slug = row["slug"]
            if slug in by_slug:
                findings.append(
                    finding(
                        "duplicate_archive_slug",
                        "warning",
                        "archive",
                        f"{path.name}:{slug}",
                        "checksum archive contains duplicate slug rows",
                        "Preserve the archive and resolve duplicate historical records manually.",
                    )
                )
            by_slug[slug] = row
        current_slugs = set(current_by_slug)
        snapshot_slugs = set(by_slug)
        missing = sorted(current_slugs - snapshot_slugs)
        extra = sorted(snapshot_slugs - current_slugs)
        checksum_mismatch = sorted(
            slug
            for slug in current_slugs & snapshot_slugs
            if by_slug[slug].get("sha256") != current_by_slug[slug].get("sha256")
        )
        if missing or extra or checksum_mismatch:
            findings.append(
                finding(
                    "archive_snapshot_drift",
                    "warning",
                    "archive",
                    path.name,
                    "historical checksum snapshot does not exactly match the current runtime manifest",
                    "Treat the archive as a historical snapshot; create a new named archive only through an explicit reviewed operation.",
                    missing_current_slugs=missing,
                    extra_historical_slugs=extra,
                    checksum_mismatch_slugs=checksum_mismatch,
                )
            )
        snapshots.append(
            {
                "path": relative_path(root, path),
                "label": payload.get("label"),
                "generated_at": payload.get("generated_at"),
                "clip_count": len(by_slug),
                "current_bundle_missing": missing,
                "historical_extra": extra,
                "checksum_mismatches": checksum_mismatch,
            }
        )
    return {"snapshots": snapshots, "findings": findings}


def scan_xcode_resources(root: Path, actual_files: dict[str, Path]) -> dict[str, Any]:
    path = root / PBX_PROJECT_RELATIVE
    findings: list[dict[str, object]] = []
    if not path.is_file():
        findings.append(
            finding(
                "generated_xcode_project_missing",
                "warning",
                "bundle_resources",
                relative_path(root, path),
                "generated Xcode project is missing, so resource membership cannot be checked",
                "Regenerate the project through its documented project.yml workflow before shipping resource changes.",
            )
        )
        return {"path": relative_path(root, path), "referenced_files": [], "missing": [], "extra": [], "findings": findings}
    try:
        payload = path.read_text(encoding="utf-8")
    except OSError as error:
        findings.append(
            finding(
                "generated_xcode_project_unreadable",
                "warning",
                "bundle_resources",
                relative_path(root, path),
                f"generated Xcode project cannot be read: {error}",
                "Preserve the project and inspect its generated resource group manually.",
            )
        )
        return {"path": relative_path(root, path), "referenced_files": [], "missing": [], "extra": [], "findings": findings}
    referenced = set(re.findall(r"/\* ([^*/\n]+\.mp3) \*/", payload))
    actual = set(actual_files)
    missing = sorted(actual - referenced)
    extra = sorted(referenced - actual)
    if missing:
        findings.append(
            finding(
                "xcode_audio_resource_missing",
                "error",
                "bundle_resources",
                relative_path(root, path),
                "bundled MP3 files are absent from the generated Xcode Audio group",
                "Regenerate ios/AnTuras.xcodeproj from ios/project.yml after reviewing the resource set; do not hand-delete project references.",
                files=missing,
            )
        )
    if extra:
        findings.append(
            finding(
                "xcode_audio_resource_orphan",
                "warning",
                "bundle_resources",
                relative_path(root, path),
                "generated Xcode project references MP3 files absent from the Audio directory",
                "Inspect the generated project and filesystem manually before changing either one.",
                files=extra,
            )
        )
    return {
        "path": relative_path(root, path),
        "referenced_files": sorted(referenced),
        "missing": missing,
        "extra": extra,
        "findings": findings,
    }


def _batch_records(
    root: Path,
    contract: authoring.LoadedContract,
    bundle: dict[str, Any],
    as_of: datetime,
) -> tuple[list[dict[str, Any]], list[dict[str, object]]]:
    records: list[dict[str, Any]] = []
    findings: list[dict[str, object]] = []
    duplicate_keys: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for batch in contract.batches:
        if not isinstance(batch, dict):
            continue
        batch_id = str(batch.get("batch_id") or "<missing-batch>")
        voice_profile = batch.get("voice_profile") or {}
        voice_id = str(voice_profile.get("id") or "<missing-voice-profile>")
        for line in batch.get("lines") or []:
            if not isinstance(line, dict):
                continue
            line_id = str(line.get("line_id") or "<missing-line>")
            normalized = normalize_text(line.get("normalized_text"))
            claim = _claim_state(line, as_of)
            result = line.get("provider_result") or {}
            success = provider_success_issues(root, batch, line)
            target = success.get("target")
            target_path = target if isinstance(target, Path) else _canonical_batch_output(root, line)
            slug = line.get("inventory_slug")
            runtime_row = bundle["by_slug"].get(slug) if isinstance(slug, str) else None
            runtime_checksum_verified = bool(
                runtime_row is not None
                and runtime_row in bundle["checksum_verified_rows"]
            )
            authorized = _batch_line_authorized(batch, line, contract)
            record = {
                "batch_id": batch_id,
                "line_id": line_id,
                "batch_path": None,
                "normalized_text": normalized,
                "text_sha256": line.get("text_sha256"),
                "voice_profile_id": voice_id,
                "inventory_slug": slug,
                "member_ids": sorted(line.get("member_ids") or []),
                "execution_state": (batch.get("execution") or {}).get("state"),
                "provider_calls_allowed": (batch.get("execution") or {}).get("provider_calls_allowed"),
                "request_status": (line.get("request") or {}).get("status"),
                "authorized": authorized,
                "claim": claim,
                "provider_result_status": result.get("status"),
                "attempt_count": (line.get("retry") or {}).get("attempt_count"),
                "max_attempts": (line.get("retry") or {}).get("max_attempts"),
                "retryable": bool((line.get("error") or {}).get("retriable")),
                "output_path": (line.get("audio") or {}).get("output_path"),
                "target_exists": bool(target_path and target_path.is_file()),
                "target_is_symlink": bool(target_path and target_path.is_symlink()),
                "checksum_verified": bool(success.get("checksum_ok")),
                "provider_success_valid": bool(success.get("valid")),
                "provider_success_issues": success.get("issues", []),
                "runtime_manifest_present": runtime_row is not None,
                "runtime_checksum_verified": runtime_checksum_verified,
                "audio_qa_status": (line.get("audio_qa") or {}).get("status"),
            }
            records.append(record)
            duplicate_keys[(normalized, voice_id)].append(record)

            if claim["invalid_lease"]:
                findings.append(
                    finding(
                        "invalid_claim_lease",
                        "error",
                        "batch_line",
                        f"{batch_id}:{line_id}",
                        "claimed line has an invalid lease timestamp",
                        "Preserve the claim history and resolve the lease manually before any resume.",
                        lease_expires_at=claim.get("lease_expires_at"),
                    )
                )
            elif claim["stale"]:
                findings.append(
                    finding(
                        "stale_claim_lease",
                        "error",
                        "batch_line",
                        f"{batch_id}:{line_id}",
                        "claimed line lease has expired before this reconciliation",
                        "Do not auto-clear or extend the lease. Manually inspect the worker history, then release or re-claim with an explicit record before resuming.",
                        owner_id=claim.get("owner_id"),
                        claimed_at=claim.get("claimed_at"),
                        lease_expires_at=claim.get("lease_expires_at"),
                    )
                )
            if result.get("status") == "in_progress":
                findings.append(
                    finding(
                        "interrupted_provider_attempt",
                        "error",
                        "batch_line",
                        f"{batch_id}:{line_id}",
                        "provider result remains in_progress and has no durable success or failure disposition",
                        "Inspect the provider request and staged/canonical output manually. Resume only after the claim and attempt history are reconciled.",
                        attempt_count=(line.get("retry") or {}).get("attempt_count"),
                        lease_expires_at=claim.get("lease_expires_at"),
                    )
                )
            if result.get("status") == "succeeded" and not success["valid"]:
                findings.append(
                    finding(
                        "invalid_provider_success",
                        "error",
                        "batch_line",
                        f"{batch_id}:{line_id}",
                        "provider result is marked succeeded but its durable result record is incomplete or inconsistent",
                        "Preserve the provider response, audio bytes, checksum, and manifest. Do not mark the line succeeded again or overwrite the target automatically.",
                        issues=success["issues"],
                    )
                )
            if result.get("status") == "succeeded" and success["valid"] and not runtime_row:
                findings.append(
                    finding(
                        "captured_line_not_bundled",
                        "warning",
                        "batch_line",
                        f"{batch_id}:{line_id}",
                        "valid provider success has no runtime manifest row",
                        "Register the exact clip through an explicit reviewed bundle update; capture success does not imply bundling or release.",
                    )
                )

    for (normalized, voice_id), rows in sorted(duplicate_keys.items()):
        if len(rows) <= 1 or not normalized:
            continue
        identifiers = sorted(f"{row['batch_id']}:{row['line_id']}" for row in rows)
        findings.append(
            finding(
                "duplicate_batch_normalized_text_voice",
                "warning",
                "batch_manifests",
                ",".join(identifiers),
                "registered v2 batches contain duplicate normalized Irish text under the same voice profile",
                "Deduplicate by explicit line ownership and preserve the original batch records; never assume duplicate text means duplicate audio is safe to overwrite.",
                normalized_text=normalized,
                voice_profile_id=voice_id,
                line_ids=identifiers,
            )
        )
    return records, findings


def _batch_paths(contract: authoring.LoadedContract) -> dict[str, str]:
    paths: dict[str, str] = {}
    refs = contract.store.get("batch_documents") or []
    for ref in refs:
        if isinstance(ref, dict) and isinstance(ref.get("batch_id"), str):
            paths[ref["batch_id"]] = str(ref.get("path"))
    return paths


def _stage_counts(
    contract: authoring.LoadedContract,
    batch_records: list[dict[str, Any]],
    inventory_scan: dict[str, Any],
    bundle_scan: dict[str, Any],
) -> dict[str, dict[str, int]]:
    complete_members = [
        member
        for member in contract.members.values()
        if (member.get("states", {}).get("authoring", {}).get("status") == "complete")
    ]
    authored_texts = {
        normalize_text((member.get("irish") or {}).get("normalized_text"))
        for member in complete_members
        if normalize_text((member.get("irish") or {}).get("normalized_text"))
    }
    authorized = [record for record in batch_records if record["authorized"]]
    authorized_texts = {record["normalized_text"] for record in authorized if record["normalized_text"]}
    raw_successes = [
        record for record in batch_records if record["provider_result_status"] == "succeeded"
    ]
    valid_successes = [record for record in raw_successes if record["provider_success_valid"]]
    checksum_successes = [record for record in valid_successes if record["checksum_verified"]]
    bundled_v2 = [record for record in checksum_successes if record["runtime_checksum_verified"]]
    v2_audio_qa = [
        record for record in batch_records if record["audio_qa_status"] in REVIEWED_V2_AUDIO_QA
    ]
    v2_audio_qa_members = {
        member_id
        for record in v2_audio_qa
        for member_id in record["member_ids"]
    }
    eligible_members = [
        member
        for member in complete_members
        if member.get("states", {}).get("learner_release", {}).get("status") == "eligible"
    ]
    eligible_texts = {
        normalize_text((member.get("irish") or {}).get("normalized_text"))
        for member in eligible_members
        if normalize_text((member.get("irish") or {}).get("normalized_text"))
    }
    runtime_rows = bundle_scan["rows"]
    runtime_checksum_rows = bundle_scan["checksum_verified_rows"]
    verified_runtime_slugs = {str(row.get("slug")) for row in runtime_checksum_rows}
    verified_runtime_texts = {
        normalize_text(row.get("text")) for row in runtime_checksum_rows
    }
    return {
        "authored": {
            "families": len(contract.families),
            "members": len(complete_members),
            "unique_texts": len(authored_texts),
        },
        "authorized": {
            "batch_line_records": len(authorized),
            "member_references": sum(len(record["member_ids"]) for record in authorized),
            "members": len({member_id for record in authorized for member_id in record["member_ids"]}),
            "unique_texts": len(authorized_texts),
        },
        "captured": {
            "v2_provider_success_records": len(raw_successes),
            "v2_valid_provider_success_records": len(valid_successes),
            "v2_unique_texts": len({record["normalized_text"] for record in valid_successes}),
            "runtime_manifest_records": len(runtime_rows),
            "inventory_generated_entries": sum(
                1 for entry in inventory_scan["entries"] if entry.get("qa_state") in GENERATED_INVENTORY_QA
            ),
        },
        "checksum_verified": {
            "v2_records": len(checksum_successes),
            "v2_unique_texts": len({record["normalized_text"] for record in checksum_successes}),
            "runtime_manifest_records": len(runtime_checksum_rows),
            "bundle_files": len(runtime_checksum_rows),
            "archive_snapshots": 0,
        },
        "bundled": {
            "runtime_manifest_records": len(runtime_rows),
            "bundle_files": len(bundle_scan["actual_files"]),
            "inventory_entries": len(
                set(inventory_scan["by_slug"]) & verified_runtime_slugs
            ),
            "v2_checksum_verified_records": len(bundled_v2),
            "v2_checksum_verified_unique_texts": len(
                {record["normalized_text"] for record in bundled_v2}
            ),
        },
        "audio_qa_reviewed": {
            "v2_line_records": len(v2_audio_qa),
            "v2_members": len(v2_audio_qa_members),
            "inventory_entries": len(inventory_scan["reviewed_entries"]),
            "inventory_passed_entries": len(inventory_scan["passed_entries"]),
            "runtime_manifest_records": sum(
                1 for row in runtime_rows if row.get("qa_state") in REVIEWED_RUNTIME_QA
            ),
        },
        "learner_release_eligible": {
            "members": len(eligible_members),
            "unique_texts": len(eligible_texts),
        },
        "legacy_or_unlinked": {
            "complete_members_with_verified_runtime_clip": len(
                {
                    member_id
                    for member_id, member in contract.members.items()
                    if member.get("states", {}).get("authoring", {}).get("status") == "complete"
                    and normalize_text((member.get("irish") or {}).get("normalized_text"))
                    in verified_runtime_texts
                }
            ),
            "v2_members_with_legacy_unverified_audio_qa": sum(
                1
                for member in complete_members
                if member.get("states", {}).get("audio_qa", {}).get("status") == "legacy_unverified"
            ),
        },
    }


def classify_bundled_clips(
    bundle: dict[str, Any],
    registered_batch_ids: Iterable[str],
) -> tuple[dict[str, Any], list[dict[str, object]]]:
    """Classify runtime rows without treating inventory membership as v2 capture."""
    registered = set(registered_batch_ids)
    verified_slugs = {
        str(row.get("slug")) for row in bundle["checksum_verified_rows"]
    }
    new_rows: list[dict[str, Any]] = []
    legacy_rows: list[dict[str, Any]] = []
    findings: list[dict[str, object]] = []
    unknown_source_rows: list[str] = []
    for row in bundle["rows"]:
        sources = row.get("sources") or []
        structured_sources = [
            source
            for source in sources
            if isinstance(source, str) and source.startswith("structured_batch:")
        ]
        if structured_sources:
            new_rows.append(row)
            source_batch_ids = {
                source.split(":", 1)[1]
                for source in structured_sources
                if source.split(":", 1)[1]
            }
            unknown_source_rows.extend(
                str(row.get("slug"))
                for batch_id in source_batch_ids
                if batch_id not in registered
            )
        else:
            legacy_rows.append(row)
    if unknown_source_rows:
        findings.append(
            finding(
                "bundle_new_source_unregistered",
                "warning",
                "runtime_manifest",
                "structured_batch_sources",
                "runtime manifest contains new-v2 source labels that are not registered in the authoring store",
                "Register or resolve the exact batch provenance manually; a source label alone does not authorize capture or release.",
                slugs=sorted(set(unknown_source_rows)),
            )
        )
    return (
        {
            "new_v2_records": len(new_rows),
            "legacy_records": len(legacy_rows),
            "unattributed_records": sum(
                1 for row in legacy_rows if not (row.get("sources") or [])
            ),
            "new_v2_checksum_verified": sum(
                1 for row in new_rows if str(row.get("slug")) in verified_slugs
            ),
            "legacy_checksum_verified": sum(
                1 for row in legacy_rows if str(row.get("slug")) in verified_slugs
            ),
            "new_v2_slugs": sorted(str(row.get("slug")) for row in new_rows),
            "legacy_slugs": sorted(str(row.get("slug")) for row in legacy_rows),
        },
        findings,
    )


def _first_nonempty(mapping: dict[str, Any], keys: Iterable[str]) -> object:
    for key in keys:
        value = mapping.get(key)
        if value is not None and value != "":
            return value
    return None


def _record_provenance(record: dict[str, Any]) -> bool:
    """Return whether a record carries an inspectable provenance pointer."""
    for key in (
        "evidence",
        "evidenceIds",
        "sources",
        "source",
        "citation",
        "stableURL",
        "attribution",
        "resourceIDs",
    ):
        value = record.get(key)
        if value not in (None, "", [], {}):
            return True
    return False


def _record_status(record: dict[str, Any]) -> str | None:
    value = _first_nonempty(record, ("status", "releaseState", "depth", "state"))
    return str(value) if value is not None else None


def _status_is_open(status: str | None) -> bool:
    if not status:
        return False
    lowered = status.lower()
    return any(
        token in lowered
        for token in (
            "open",
            "pending",
            "draft",
            "provisional",
            "foundation",
            "pilot",
            "in_progress",
            "in-progress",
            "retry",
        )
    )


def _status_is_failed(status: str | None) -> bool:
    return bool(status and any(token in status.lower() for token in ("fail", "error")))


def _status_is_interrupted(status: str | None) -> bool:
    return bool(status and status.lower() in {"in_progress", "in-progress", "interrupted"})


def _artifact_checksum_state(root: Path, path: Path, payload: dict[str, Any]) -> dict[str, Any]:
    actual = sha256_file(path)
    recorded = _first_nonempty(payload, ("sha256", "checksum", "content_sha256"))
    valid_recorded = isinstance(recorded, str) and bool(SHA256_RE.fullmatch(recorded))
    return {
        "path": relative_path(root, path),
        "actual_sha256": actual,
        "recorded_sha256": recorded if valid_recorded else None,
        "verified": valid_recorded and recorded == actual,
        "missing_recorded_checksum": not valid_recorded,
        "mismatched": valid_recorded and recorded != actual,
    }


def _summarize_extended_artifact(
    root: Path,
    path: Path,
    kind: str,
    records: list[dict[str, Any]],
    *,
    payload: dict[str, Any],
    metadata: dict[str, Any] | None = None,
) -> tuple[dict[str, Any], list[dict[str, object]]]:
    """Summarize a non-audio JSON artifact without promoting its contents."""
    findings: list[dict[str, object]] = []
    by_id: dict[str, list[dict[str, Any]]] = defaultdict(list)
    by_text: dict[str, list[dict[str, Any]]] = defaultdict(list)
    declared_ids = 0
    missing_ids = 0
    provenance_records = 0
    statuses: Counter[str] = Counter()
    kinds: Counter[str] = Counter()
    counties: set[str] = set()
    for index, record in enumerate(records):
        record_id = _first_nonempty(record, ("id", "stable_id", "stableId", "slug"))
        if isinstance(record_id, str) and record_id.strip():
            declared_ids += 1
            by_id[record_id.strip()].append(record)
        else:
            missing_ids += 1
        text_value = _first_nonempty(
            record,
            ("text", "ga", "irish", "normalized_text", "canonicalDisplay", "body", "value"),
        )
        normalized = normalize_text(text_value)
        if normalized:
            by_text[normalized].append(record)
        if _record_provenance(record):
            provenance_records += 1
        status = _record_status(record)
        if status:
            statuses[status] += 1
        record_kind = record.get("kind")
        if isinstance(record_kind, str) and record_kind:
            kinds[record_kind] += 1
        county = record.get("county")
        if isinstance(county, str) and county.strip():
            counties.add(county.strip())

    duplicate_ids = {
        identifier: len(rows)
        for identifier, rows in by_id.items()
        if len(rows) > 1
    }
    duplicate_texts = {
        text: len(rows)
        for text, rows in by_text.items()
        if len(rows) > 1
    }
    checksum = _artifact_checksum_state(root, path, payload)
    open_status_records = sum(count for status, count in statuses.items() if _status_is_open(status))
    failed_records = sum(count for status, count in statuses.items() if _status_is_failed(status))
    interrupted_records = sum(count for status, count in statuses.items() if _status_is_interrupted(status))
    manual_recovery = len(duplicate_ids) + (1 if checksum["mismatched"] else 0)
    summary: dict[str, Any] = {
        "kind": kind,
        "path": relative_path(root, path),
        "records": len(records),
        "declared_stable_ids": declared_ids,
        "missing_stable_ids": missing_ids,
        "unique_stable_ids": len(by_id),
        "unique_normalized_texts": len(by_text),
        "counties": sorted(counties),
        "record_kinds": dict(sorted(kinds.items())),
        "statuses": dict(sorted(statuses.items())),
        "provenance": {
            "records_with_provenance": provenance_records,
            "records_missing_provenance": len(records) - provenance_records,
        },
        "collision_state": {
            "duplicate_stable_ids": duplicate_ids,
            "duplicate_normalized_texts": duplicate_texts,
        },
        "checksum_state": checksum,
        "resumability": {
            "open_or_review_pending_records": open_status_records,
            "failed_records": failed_records,
            "interrupted_records": interrupted_records,
            "resumable_records": open_status_records + failed_records,
            "manual_recovery_required": manual_recovery,
        },
    }
    if metadata:
        summary.update(metadata)

    if missing_ids:
        findings.append(
            finding(
                "artifact_records_missing_stable_id",
                "warning",
                kind,
                relative_path(root, path),
                f"{missing_ids} artifact records do not declare a stable id",
                "Keep the source artifact unchanged and assign a durable id through its owner schema before relying on it for resumable work.",
                missing_records=missing_ids,
            )
        )
    if duplicate_ids:
        findings.append(
            finding(
                "artifact_duplicate_stable_id",
                "error",
                kind,
                relative_path(root, path),
                "artifact contains duplicate declared stable ids",
                "Resolve the collision manually and preserve both source records until ownership is explicit.",
                duplicate_ids=duplicate_ids,
            )
        )
    if duplicate_texts:
        findings.append(
            finding(
                "artifact_duplicate_normalized_text",
                "warning",
                kind,
                relative_path(root, path),
                "artifact contains repeated normalized text values",
                "Retain intentional place or story reuse, but bind each use to a stable id; do not deduplicate by deleting source material.",
                duplicate_count=len(duplicate_texts),
            )
        )
    if len(records) and len(records) != provenance_records:
        findings.append(
            finding(
                "artifact_records_missing_provenance",
                "warning",
                kind,
                relative_path(root, path),
                f"{len(records) - provenance_records} artifact records lack an inspectable provenance pointer",
                "Keep the artifact provisional until the owner adds a source, evidence, citation, or equivalent durable pointer.",
                missing_records=len(records) - provenance_records,
            )
        )
    if checksum["missing_recorded_checksum"]:
        findings.append(
            finding(
                "artifact_checksum_not_recorded",
                "warning",
                kind,
                relative_path(root, path),
                "artifact exists but does not record a SHA-256 for reconciliation",
                "Record the checksum in the owning manifest or retain this file as unverified; never infer verification from file presence alone.",
                actual_sha256=checksum["actual_sha256"],
            )
        )
    if checksum["mismatched"]:
        findings.append(
            finding(
                "artifact_checksum_mismatch",
                "error",
                kind,
                relative_path(root, path),
                "artifact recorded checksum does not match its current bytes",
                "Preserve the artifact and checksum record and resolve the mismatch manually before bundling or resuming work.",
                recorded_sha256=checksum["recorded_sha256"],
                actual_sha256=checksum["actual_sha256"],
            )
        )
    return summary, findings


def _load_extended_json(root: Path, path: Path) -> tuple[dict[str, Any] | None, list[dict[str, object]]]:
    if not path.is_file():
        return None, [
            finding(
                "artifact_file_missing",
                "error",
                "extended_artifact",
                relative_path(root, path),
                "canonical extended artifact is missing",
                "Restore or inspect the owner artifact manually; this audit never reconstructs, deletes, or overwrites it.",
            )
        ]
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return None, [
            finding(
                "artifact_file_unreadable",
                "error",
                "extended_artifact",
                relative_path(root, path),
                f"cannot read extended artifact: {error}",
                "Preserve the last known-good artifact and resolve it through its owner workflow.",
            )
        ]
    if not isinstance(payload, dict):
        return None, [
            finding(
                "artifact_payload_invalid",
                "error",
                "extended_artifact",
                relative_path(root, path),
                "extended artifact must be a JSON object",
                "Resolve the artifact shape manually before bundling or recovery.",
            )
        ]
    return payload, []


def _atlas_artifact_records(payload: dict[str, Any], kind: str) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    if kind == "atlas_names_places":
        records = [record for record in payload.get("subjects", []) if isinstance(record, dict)]
        return records, {
            "subject_kinds": dict(
                sorted(Counter(str(record.get("kind")) for record in records).items())
            ),
            "content_date": payload.get("contentDate"),
            "attribution_present": bool(payload.get("attribution")),
        }
    records: list[dict[str, Any]] = []
    for county, county_payload in (payload.get("counties") or {}).items():
        if not isinstance(county_payload, dict):
            continue
        source = county_payload.get("source")
        for index, word in enumerate(county_payload.get("words") or [], start=1):
            if not isinstance(word, dict):
                continue
            records.append(
                {
                    **word,
                    "county": county,
                    "status": payload.get("status"),
                    "_source": source,
                    "_placement_index": index,
                }
            )
    return records, {
        "headword_status": payload.get("status"),
        "content_date": payload.get("generated_at"),
        "attribution_present": False,
    }


def _pedagogy_artifact_records(payload: dict[str, Any]) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    pack = payload.get("pack", payload)
    records: list[dict[str, Any]] = []
    for chapter in pack.get("chapters", []) if isinstance(pack, dict) else []:
        if not isinstance(chapter, dict):
            continue
        for page in chapter.get("pages", []) or []:
            if isinstance(page, dict):
                records.append(page)
    gates = [gate for gate in pack.get("reviewGates", []) if isinstance(gate, dict)] if isinstance(pack, dict) else []
    resources = [resource for resource in pack.get("resources", []) if isinstance(resource, dict)] if isinstance(pack, dict) else []
    narration_pages = sum(record.get("kind") == "narrative" for record in records)
    return records, {
        "pack_id": pack.get("id") if isinstance(pack, dict) else None,
        "revision": pack.get("revision") if isinstance(pack, dict) else None,
        "narration_pages": narration_pages,
        "review_gates": dict(sorted(Counter(str(gate.get("status")) for gate in gates).items())),
        "review_gates_open": sum(str(gate.get("status")) not in {"complete", "passed"} for gate in gates),
        "resource_records": len(resources),
        "resource_ids": sorted(str(resource.get("id")) for resource in resources if resource.get("id")),
    }


def _external_artifact_records(payload: dict[str, Any], path: Path) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    if path.name == "logainm-hierarchy-repairs.json":
        records = []
        for identifier, record in (payload.get("records") or {}).items():
            if isinstance(record, dict):
                records.append({"id": str(identifier), **record})
        return records, {"snapshot_at": payload.get("reviewedAt"), "record_type": "hierarchy_repair"}
    if path.name == "logainm-ni-review.json":
        ni = payload.get("northernIreland") or {}
        records = [
            {"id": f"county:{item.get('county')}", **item}
            for item in ni.get("counties", [])
            if isinstance(item, dict) and item.get("county")
        ]
        return records, {
            "snapshot_at": payload.get("snapshotFetchedAt"),
            "record_type": "county_comparison",
            "summary": ni.get("summary", {}),
        }
    records = [
        {"id": f"county:{item.get('county')}", **item}
        for item in payload.get("counties", [])
        if isinstance(item, dict) and item.get("county")
    ]
    return records, {
        "snapshot_at": payload.get("snapshotFetchedAt"),
        "generated_at": payload.get("generatedAt"),
        "record_type": "source_coverage_comparison",
        "summary": payload.get("summary", {}),
    }


def _compare_pedagogy_artifacts(artifacts: list[dict[str, Any]]) -> tuple[dict[str, Any], list[dict[str, object]]]:
    findings: list[dict[str, object]] = []
    by_pack: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for artifact in artifacts:
        pack_id = artifact.get("pack_id")
        if pack_id:
            by_pack[str(pack_id)].append(artifact)
    pairs = 0
    missing_side = 0
    page_id_drift = 0
    text_drift = 0
    for pack_id, pair in sorted(by_pack.items()):
        if len(pair) < 2:
            missing_side += 1
            continue
        source = next((item for item in pair if ".pack.draft.json" in item["path"]), None)
        runtime = next((item for item in pair if "CountyStories/" in item["path"]), None)
        if not source or not runtime:
            missing_side += 1
            continue
        pairs += 1
        source_ids = set(source.pop("_page_ids", [])) if "_page_ids" in source else set()
        runtime_ids = set(runtime.pop("_page_ids", [])) if "_page_ids" in runtime else set()
        if source_ids != runtime_ids:
            page_id_drift += 1
        source_texts = source.pop("_page_texts", {}) if "_page_texts" in source else {}
        runtime_texts = runtime.pop("_page_texts", {}) if "_page_texts" in runtime else {}
        if source_texts != runtime_texts:
            text_drift += 1
    if missing_side:
        findings.append(
            finding(
                "pedagogy_narration_pair_missing",
                "warning",
                "pedagogy_narration",
                "pack_pairs",
                f"{missing_side} story pack ids do not have both draft and runtime artifacts",
                "Keep draft/runtime ownership explicit and resume only from the named side after a manual comparison.",
                missing_pairs=missing_side,
            )
        )
    if page_id_drift or text_drift:
        findings.append(
            finding(
                "pedagogy_narration_runtime_drift",
                "warning",
                "pedagogy_narration",
                "pack_pairs",
                "draft and runtime narration artifacts differ in page ids or normalized text",
                "Inspect the owner pack and generated runtime resource manually; do not overwrite one side from the other automatically.",
                page_id_drift=page_id_drift,
                text_drift=text_drift,
            )
        )
    return {
        "paired_pack_ids": pairs,
        "missing_pair_sides": missing_side,
        "page_id_drift": page_id_drift,
        "text_drift": text_drift,
    }, findings


def scan_extended_artifacts(root: Path) -> tuple[dict[str, Any], list[dict[str, object]]]:
    """Reconcile atlas, pedagogy narration, and external-reference artifacts."""
    findings: list[dict[str, object]] = []
    category_artifacts: dict[str, list[dict[str, Any]]] = defaultdict(list)

    atlas_specs = [
        (ATLAS_SUBJECTS_RELATIVE, "atlas_names_places"),
        (ATLAS_HEADWORDS_RELATIVE, "atlas_headwords"),
    ]
    for relative, kind in atlas_specs:
        path = root / relative
        payload, load_findings = _load_extended_json(root, path)
        findings.extend(load_findings)
        if payload is None:
            continue
        records, metadata = _atlas_artifact_records(payload, kind)
        summary, artifact_findings = _summarize_extended_artifact(
            root, path, kind, records, payload=payload, metadata=metadata
        )
        category_artifacts["atlas_names_places"].append(summary)
        findings.extend(artifact_findings)

    for pattern, kind in ((PEDAGOGY_DRAFT_GLOB, "pedagogy_narration_draft"), (PEDAGOGY_RUNTIME_GLOB, "pedagogy_narration_runtime")):
        for path in sorted(root.glob(pattern)):
            payload, load_findings = _load_extended_json(root, path)
            findings.extend(load_findings)
            if payload is None:
                continue
            records, metadata = _pedagogy_artifact_records(payload)
            page_ids = [str(record.get("id")) for record in records if record.get("id")]
            page_texts = {
                str(record.get("id")): normalize_text(record.get("body"))
                for record in records
                if record.get("id") and record.get("kind") == "narrative"
            }
            metadata.update({"_page_ids": page_ids, "_page_texts": page_texts})
            summary, artifact_findings = _summarize_extended_artifact(
                root, path, kind, records, payload=payload, metadata=metadata
            )
            category_artifacts["pedagogy_narration"].append(summary)
            findings.extend(artifact_findings)

    for relative in EXTERNAL_REFERENCE_RELATIVES:
        path = root / relative
        payload, load_findings = _load_extended_json(root, path)
        findings.extend(load_findings)
        if payload is None:
            continue
        records, metadata = _external_artifact_records(payload, path)
        summary, artifact_findings = _summarize_extended_artifact(
            root, path, "external_reference_comparison", records, payload=payload, metadata=metadata
        )
        category_artifacts["external_reference_comparison"].append(summary)
        findings.extend(artifact_findings)

    def aggregate(category: str) -> dict[str, Any]:
        artifacts = category_artifacts.get(category, [])
        all_records = sum(int(item["records"]) for item in artifacts)
        declared = sum(int(item["declared_stable_ids"]) for item in artifacts)
        missing = sum(int(item["missing_stable_ids"]) for item in artifacts)
        provenance = sum(int(item["provenance"]["records_with_provenance"]) for item in artifacts)
        duplicate_ids = sum(len(item["collision_state"]["duplicate_stable_ids"]) for item in artifacts)
        duplicate_texts = sum(len(item["collision_state"]["duplicate_normalized_texts"]) for item in artifacts)
        checksum_records = [item["checksum_state"] for item in artifacts]
        open_records = sum(
            int(item["resumability"]["open_or_review_pending_records"])
            + int(item.get("review_gates_open", 0))
            for item in artifacts
        )
        failed_records = sum(int(item["resumability"]["failed_records"]) for item in artifacts)
        interrupted_records = sum(int(item["resumability"]["interrupted_records"]) for item in artifacts)
        resumable = sum(
            int(item["resumability"]["resumable_records"])
            + int(item.get("review_gates_open", 0))
            for item in artifacts
        )
        counties = sorted({county for item in artifacts for county in item.get("counties", [])})
        result = {
            "schema_version": EXTENDED_ARTIFACT_SCHEMA_VERSION,
            "artifacts": artifacts,
            "artifact_count": len(artifacts),
            "records": all_records,
            "stable_ids": {
                "declared": declared,
                "missing": missing,
                "unique": sum(int(item["unique_stable_ids"]) for item in artifacts),
            },
            "unique_normalized_texts": sum(int(item["unique_normalized_texts"]) for item in artifacts),
            "counties": counties,
            "provenance": {
                "records_with_provenance": provenance,
                "records_missing_provenance": all_records - provenance,
            },
            "collision_state": {
                "artifacts_with_duplicate_stable_ids": duplicate_ids,
                "artifacts_with_duplicate_normalized_texts": duplicate_texts,
            },
            "checksum_state": {
                "artifact_files": len(checksum_records),
                "verified": sum(bool(item["verified"]) for item in checksum_records),
                "missing_recorded_checksum": sum(bool(item["missing_recorded_checksum"]) for item in checksum_records),
                "mismatched": sum(bool(item["mismatched"]) for item in checksum_records),
            },
            "remaining_resumable_work": {
                "open_or_review_pending_records": open_records,
                "failed_records": failed_records,
                "interrupted_records": interrupted_records,
                "resumable_records": resumable,
                "manual_recovery_required": sum(int(item["resumability"]["manual_recovery_required"]) for item in artifacts),
            },
        }
        if category == "atlas_names_places":
            result["subject_kinds"] = dict(
                sorted(
                    Counter(
                        kind
                        for item in artifacts
                        for kind, count in item.get("subject_kinds", {}).items()
                        for _ in range(count)
                    ).items()
                )
            )
            result["names"] = result["subject_kinds"].get("name", 0)
            result["places"] = result["subject_kinds"].get("place", 0)
        if category == "pedagogy_narration":
            result["narration_pages"] = sum(int(item.get("narration_pages", 0)) for item in artifacts)
            result["review_gates_open"] = sum(int(item.get("review_gates_open", 0)) for item in artifacts)
            result["comparison"], comparison_findings = _compare_pedagogy_artifacts(artifacts)
            findings.extend(comparison_findings)
        if category == "external_reference_comparison":
            snapshots = sorted(
                {
                    str(item.get("snapshot_at"))[:10]
                    for item in artifacts
                    if item.get("snapshot_at")
                }
            )
            result["comparison"] = {
                "snapshot_dates": snapshots,
                "snapshot_drift": len(snapshots) > 1,
                "hierarchy_repair_records": sum(
                    int(item["records"])
                    for item in artifacts
                    if item.get("record_type") == "hierarchy_repair"
                ),
                "open_countyless_records": next(
                    (
                        int(item.get("summary", {}).get("countylessRecords", 0))
                        for item in artifacts
                        if item.get("record_type") == "source_coverage_comparison"
                    ),
                    0,
                ),
                "open_multi_county_records": next(
                    (
                        int(item.get("summary", {}).get("multipleCountyRecords", 0))
                        for item in artifacts
                        if item.get("record_type") == "source_coverage_comparison"
                    ),
                    0,
                ),
            }
            result["remaining_resumable_work"]["open_comparison_queue"] = (
                result["comparison"]["open_countyless_records"]
                + result["comparison"]["open_multi_county_records"]
            )
            if result["comparison"]["snapshot_drift"]:
                findings.append(
                    finding(
                        "external_reference_snapshot_drift",
                        "warning",
                        category,
                        "snapshot_dates",
                        "external-reference artifacts do not share one snapshot date",
                        "Compare the named snapshots manually before resuming an ingest or promoting a comparison result.",
                        snapshot_dates=snapshots,
                    )
                )
        return result

    return {
        "atlas_names_places": aggregate("atlas_names_places"),
        "pedagogy_narration": aggregate("pedagogy_narration"),
        "external_reference_comparison": aggregate("external_reference_comparison"),
    }, findings


def _preflight_candidate(record: dict[str, Any]) -> bool:
    if record.get("execution_state") != "approved":
        return False
    if record.get("provider_calls_allowed") is not True:
        return False
    if record.get("request_status") != "approved":
        return False
    if record.get("target_exists") or not (record.get("claim") or {}).get("active"):
        return False
    result = record.get("provider_result_status")
    if result == "not_started":
        return True
    if result != "failed" or not record.get("retryable"):
        return False
    attempts = record.get("attempt_count")
    maximum = record.get("max_attempts")
    return (
        isinstance(attempts, int)
        and isinstance(maximum, int)
        and attempts < maximum
    )


def live_scoreboard(
    contract: authoring.LoadedContract,
    batch_records: list[dict[str, Any]],
    bundle: dict[str, Any],
    inventory_scan: dict[str, Any],
    archive_scan: dict[str, Any],
    bundle_classification: dict[str, Any],
    extended_artifacts: dict[str, Any],
    *,
    observed_at: str,
) -> dict[str, Any]:
    """Build the compact production-loop scoreboard from one reconciliation pass."""
    all_members = list(contract.members.values())
    complete_members = [
        member
        for member in all_members
        if member.get("states", {}).get("authoring", {}).get("status") == "complete"
    ]
    authored_texts = {
        normalize_text((member.get("irish") or {}).get("normalized_text"))
        for member in complete_members
        if normalize_text((member.get("irish") or {}).get("normalized_text"))
    }
    counties = sorted(
        {
            str(family.get("county"))
            for family in contract.families
            if isinstance(family.get("county"), str) and family.get("county")
        }
    )
    line_statuses = {
        "registered": len(batch_records),
        "approved": sum(record.get("request_status") == "approved" for record in batch_records),
        "claimed": sum((record.get("claim") or {}).get("status") == "claimed" for record in batch_records),
        "succeeded": sum(record.get("provider_result_status") == "succeeded" for record in batch_records),
        "failed": sum(record.get("provider_result_status") == "failed" for record in batch_records),
        "cancelled": sum(record.get("request_status") == "cancelled" for record in batch_records),
        "unique_normalized_texts": len(
            {record.get("normalized_text") for record in batch_records if record.get("normalized_text")}
        ),
    }
    stale_claims = sum(
        bool((record.get("claim") or {}).get("stale")) for record in batch_records
    )
    invalid_claims = sum(
        bool((record.get("claim") or {}).get("invalid_lease")) for record in batch_records
    )
    interrupted = sum(
        record.get("provider_result_status") == "in_progress" for record in batch_records
    )
    retryable_failures = sum(
        record.get("provider_result_status") == "failed"
        and record.get("retryable")
        and isinstance(record.get("attempt_count"), int)
        and isinstance(record.get("max_attempts"), int)
        and record["attempt_count"] < record["max_attempts"]
        for record in batch_records
    )
    authorized_not_succeeded = sum(
        record.get("authorized")
        and record.get("provider_result_status") != "succeeded"
        for record in batch_records
    )
    preflight_candidates = sum(_preflight_candidate(record) for record in batch_records)
    return {
        "schema_version": REPORT_SCHEMA_VERSION,
        "contract": "irish_audio_live_scoreboard",
        "observed_at": observed_at,
        "read_only": True,
        "authored": {
            "families": len(contract.families),
            "members": len(all_members),
            "complete_members": len(complete_members),
            "unique_texts": len(authored_texts),
            "counties": counties,
            "county_count": len(counties),
        },
        "registered_lines": line_statuses,
        "authorized_lines": sum(record.get("authorized") for record in batch_records),
        "bundled_clips": {
            "total": len(bundle["rows"]),
            "new_v2": bundle_classification["new_v2_records"],
            "legacy": bundle_classification["legacy_records"],
            "unattributed": bundle_classification["unattributed_records"],
            "new_v2_checksum_verified": bundle_classification["new_v2_checksum_verified"],
            "legacy_checksum_verified": bundle_classification["legacy_checksum_verified"],
            "inventory_backed": len(
                set(inventory_scan["by_slug"]) & set(bundle["by_slug"])
            ),
        },
        "checksum_state": {
            "bundle_manifest_records": len(bundle["rows"]),
            "bundle_files": len(bundle["actual_files"]),
            "verified": len(bundle["checksum_verified_rows"]),
            "unverified_manifest_records": len(bundle["rows"]) - len(bundle["checksum_verified_rows"]),
            "missing_files": len(bundle["missing_files"]),
            "mismatched_files": len(bundle["checksum_mismatches"]),
            "orphan_files": len(bundle["orphan_files"]),
            "exact_archive_snapshots": sum(
                not snapshot["checksum_mismatches"]
                and not snapshot["current_bundle_missing"]
                and not snapshot["historical_extra"]
                for snapshot in archive_scan["snapshots"]
            ),
        },
        "technical_audio": bundle["technical_audio"]["summary"],
        "remaining_resumable_work": {
            "authorized_not_succeeded_lines": authorized_not_succeeded,
            "approved_not_started_lines": sum(
                record.get("request_status") == "approved"
                and record.get("provider_result_status") == "not_started"
                for record in batch_records
            ),
            "claim_resolution_required_lines": stale_claims + invalid_claims,
            "stale_claims": stale_claims,
            "invalid_claim_leases": invalid_claims,
            "interrupted_attempts": interrupted,
            "retryable_failed_lines": retryable_failures,
            "preflight_candidates": preflight_candidates,
            "manual_recovery_required": stale_claims + invalid_claims + interrupted,
        },
        "extended_artifacts": extended_artifacts,
    }


def reconcile(
    root: Path = ROOT,
    *,
    as_of: datetime | None = None,
) -> dict[str, Any]:
    """Return a read-only reconciliation report for one repository checkout."""
    root = root.resolve()
    as_of = (as_of or datetime.now(timezone.utc)).astimezone(timezone.utc)
    contract_errors: list[str] = []
    try:
        contract_errors, contract = authoring.validate_contract(root=root)
    except (OSError, json.JSONDecodeError, TypeError, KeyError) as error:
        contract = authoring.LoadedContract(
            store={}, families=[], members={}, inventory={}, placements={}, voice_profiles={}, batches=[]
        )
        contract_errors = [f"authoring contract could not be loaded: {error}"]

    inventory_path = root / INVENTORY_RELATIVE
    try:
        inventory_payload = json.loads(inventory_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        inventory_payload = {}
        contract_errors.append(f"runtime inventory could not be loaded: {error}")

    bundle = scan_runtime_bundle(root)
    inventory_scan = scan_inventory(root, inventory_payload, bundle)
    archive_scan = scan_archives(root, bundle)
    xcode_scan = scan_xcode_resources(root, bundle["actual_files"])
    batch_records, batch_findings = _batch_records(root, contract, bundle, as_of)
    bundle_classification, bundle_classification_findings = classify_bundled_clips(
        bundle,
        (batch.get("batch_id") for batch in contract.batches if isinstance(batch, dict)),
    )
    extended_artifacts, extended_artifact_findings = scan_extended_artifacts(root)

    all_findings = [
        *bundle["findings"],
        *inventory_scan["findings"],
        *archive_scan["findings"],
        *xcode_scan["findings"],
        *batch_findings,
        *bundle_classification_findings,
        *extended_artifact_findings,
    ]
    for error in contract_errors:
        all_findings.append(
            finding(
                "authoring_contract_invalid",
                "error",
                "authoring_contract",
                "content/audio/authoring/phrase-family-store-v2.json",
                error,
                "Resolve the contract error before treating any capture or release count as authoritative.",
            )
        )

    batch_paths = _batch_paths(contract)
    for record in batch_records:
        record["batch_path"] = batch_paths.get(record["batch_id"])
    stage_counts = _stage_counts(contract, batch_records, inventory_scan, bundle)
    stage_counts["checksum_verified"]["archive_snapshots"] = sum(
        1 for snapshot in archive_scan["snapshots"] if not snapshot["checksum_mismatches"]
    )
    observed_at = iso_now()
    finding_counts = {
        "total": len(all_findings),
        "by_severity": dict(sorted(Counter(str(item["severity"]) for item in all_findings).items())),
        "by_code": dict(sorted(Counter(str(item["code"]) for item in all_findings).items())),
    }
    return {
        "schema_version": REPORT_SCHEMA_VERSION,
        "contract": REPORT_CONTRACT,
        "observed_at": observed_at,
        "as_of": as_of.isoformat(),
        "scope": "read-only reconciliation; capture, checksum, bundle, audio QA, and learner release remain independent states",
        "worktree": worktree_report(root),
        "contract_check": {
            "valid": not contract_errors,
            "error_count": len(contract_errors),
            "errors": contract_errors,
        },
        "sources": {
            "authoring_store": "content/audio/authoring/phrase-family-store-v2.json",
            "inventory": INVENTORY_RELATIVE.as_posix(),
            "runtime_manifest": MANIFEST_RELATIVE.as_posix(),
            "checksum_archives": ARCHIVE_RELATIVE.as_posix(),
            "generated_xcode_project": PBX_PROJECT_RELATIVE.as_posix(),
            "extended_artifacts": {
                "atlas_names_places": [
                    ATLAS_SUBJECTS_RELATIVE.as_posix(),
                    ATLAS_HEADWORDS_RELATIVE.as_posix(),
                ],
                "pedagogy_narration": [PEDAGOGY_DRAFT_GLOB, PEDAGOGY_RUNTIME_GLOB],
                "external_reference_comparison": [
                    path.as_posix() for path in EXTERNAL_REFERENCE_RELATIVES
                ],
            },
        },
        "stage_counts": stage_counts,
        "extended_artifacts": extended_artifacts,
        "scoreboard": live_scoreboard(
            contract,
            batch_records,
            bundle,
            inventory_scan,
            archive_scan,
            bundle_classification,
            extended_artifacts,
            observed_at=observed_at,
        ),
        "state_counts": {
            "batch_provider_results": dict(
                sorted(Counter(str(record["provider_result_status"]) for record in batch_records).items())
            ),
            "batch_claims": dict(
                sorted(Counter(str(record["claim"]["status"]) for record in batch_records).items())
            ),
            "inventory_qa": dict(
                sorted(Counter(str(entry.get("qa_state")) for entry in inventory_scan["entries"]).items())
            ),
            "runtime_manifest_qa": dict(
                sorted(Counter(str(row.get("qa_state")) for row in bundle["rows"]).items())
            ),
        },
        "asset_checks": {
            "bundle_manifest_records": len(bundle["rows"]),
            "bundle_files": len(bundle["actual_files"]),
            "missing_bundle_files": bundle["missing_files"],
            "orphan_bundle_files": bundle["orphan_files"],
            "bundle_checksum_mismatches": bundle["checksum_mismatches"],
            "bundle_byte_count_mismatches": bundle["byte_mismatches"],
            "technical_audio": bundle["technical_audio"]["summary"],
            "inventory_not_bundled": inventory_scan["inventory_not_bundled"],
            "bundle_not_in_inventory": inventory_scan["bundle_not_inventory"],
            "inventory_bundle_qa_drift": inventory_scan["qa_drift"],
            "archive_snapshots": archive_scan["snapshots"],
            "xcode_audio_resources": {
                "referenced_files": len(xcode_scan["referenced_files"]),
                "missing_references": xcode_scan["missing"],
                "orphan_references": xcode_scan["extra"],
            },
        },
        "batch_lines": batch_records,
        "findings": all_findings,
        "finding_counts": finding_counts,
        "blocking": any(item["severity"] == "error" for item in all_findings),
        "read_only": True,
    }


def build_resume_plan(
    report: dict[str, Any],
    *,
    batch_id: str | None = None,
) -> dict[str, Any]:
    """Build a non-mutating recovery plan from a reconciliation report."""
    selected = [
        record
        for record in report.get("batch_lines", [])
        if batch_id is None or record.get("batch_id") == batch_id
    ]
    plans: list[dict[str, Any]] = []
    for record in selected:
        result = record.get("provider_result_status")
        request = record.get("request_status")
        claim = record.get("claim") or {}
        target_exists = bool(record.get("target_exists"))
        if request == "cancelled":
            disposition = "leave_cancelled"
            reasons = ["line_request_cancelled"]
        elif result == "succeeded":
            disposition = "do_not_resume"
            reasons = [
                "valid_provider_success" if record.get("provider_success_valid") else "invalid_provider_success"
            ]
        elif result == "in_progress":
            disposition = "manual_recovery_required"
            reasons = ["interrupted_provider_attempt"]
        elif claim.get("stale") or claim.get("invalid_lease"):
            disposition = "manual_claim_resolution_required"
            reasons = ["stale_or_invalid_claim_lease"]
        elif record.get("execution_state") != "approved" or record.get("provider_calls_allowed") is not True:
            disposition = "not_authorized"
            reasons = ["batch_execution_not_approved"]
        elif request != "approved":
            disposition = "not_requested_for_capture"
            reasons = ["line_request_not_approved"]
        elif target_exists:
            disposition = "manual_existing_target_review"
            reasons = ["canonical_target_already_exists"]
        elif not claim.get("active"):
            disposition = "manual_claim_required"
            reasons = ["active_claim_required"]
        elif result == "failed" and not record.get("retryable"):
            disposition = "not_retryable"
            reasons = ["provider_error_not_retryable"]
        elif result == "failed" and (
            not isinstance(record.get("attempt_count"), int)
            or not isinstance(record.get("max_attempts"), int)
            or record["attempt_count"] >= record["max_attempts"]
        ):
            disposition = "attempt_budget_exhausted"
            reasons = ["retry_attempt_limit_reached"]
        else:
            disposition = "preflight_candidate_only"
            reasons = ["missing_target_and_active_claim"]
        plans.append(
            {
                "batch_id": record.get("batch_id"),
                "line_id": record.get("line_id"),
                "normalized_text": record.get("normalized_text"),
                "inventory_slug": record.get("inventory_slug"),
                "disposition": disposition,
                "reasons": reasons,
                "provider_calls_allowed_by_plan": False,
                "automatic_mutations": [],
                "claim": claim,
                "target_exists": target_exists,
            }
        )
    batch_paths = sorted(
        {
            str(record.get("batch_path"))
            for record in selected
            if record.get("batch_path")
        }
    )
    commands = [
        "python3 -B tools/structured_audio_authoring.py reconcile --json",
    ]
    if batch_id:
        commands.append(
            f"python3 -B tools/structured_audio_authoring.py resume-plan --batch-id {batch_id} --json"
        )
    for path in batch_paths:
        commands.append(
            f"tools/run-structured-audio-generation.sh --json --batch {path}"
        )
    return {
        "schema_version": REPORT_SCHEMA_VERSION,
        "contract": "irish_audio_resume_plan",
        "observed_at": iso_now(),
        "scope": "non-destructive recovery planning only; no provider call, file write, claim change, or release promotion",
        "batch_filter": batch_id,
        "report_blocking": report.get("blocking", False),
        "plans": plans,
        "commands": commands,
        "read_only": True,
    }


def main(argv: list[str] | None = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--batch-id")
    parser.add_argument("--at", help="deterministic ISO timestamp for lease checks")
    parser.add_argument("--resume-plan", action="store_true")
    parser.add_argument("--scoreboard", action="store_true")
    parser.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    args = parser.parse_args(argv)
    as_of = parse_timestamp(args.at) if args.at else None
    if args.at and as_of is None:
        parser.error("--at must be an ISO timestamp with a timezone")
    report = reconcile(args.root, as_of=as_of)
    if args.resume_plan:
        print(json.dumps(build_resume_plan(report, batch_id=args.batch_id), ensure_ascii=False, indent=2))
    else:
        payload = report["scoreboard"] if args.scoreboard else report
        print(json.dumps(payload, ensure_ascii=False, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
