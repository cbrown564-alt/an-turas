#!/usr/bin/env python3
"""Validate An Turas Irish authoring records and build provider-neutral TTS batches.

This tool is offline. It never calls a speech provider and never infers generation
success from inventory membership. County/story phrase-family documents are the
canonical authoring records; batch manifests are explicit, resumable handoffs.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import sys
import unicodedata
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Iterable, Sequence


ROOT = Path(__file__).resolve().parents[1]
STORE_PATH = ROOT / "content/audio/authoring/phrase-family-store-v2.json"
ATLAS_PATH = ROOT / "content/audio/atlas-headwords-v1.json"
INVENTORY_PATH = ROOT / "content/audio/irish-inventory-v1.json"
VOICE_PROFILES_PATH = ROOT / "content/audio/authoring/voice-profiles-v1.json"

AUTHORING_STATES = {"draft", "complete", "retired"}
PROVENANCE_ORIGINS = {
    "repository_draft",
    "attested_external",
    "invented_pedagogical",
    "legacy_unknown",
}
REVIEW_STATES = {
    "not_requested",
    "pending",
    "approved",
    "changes_requested",
    "rejected",
}
CAPTURE_REQUEST_STATES = {"not_requested", "planned", "requested", "cancelled"}
AUDIO_QA_STATES = {
    "not_generated",
    "pending",
    "passed",
    "flagged",
    "failed",
    "legacy_unverified",
}
RELEASE_STATES = {"blocked", "eligible", "retired"}
SETTINGS = {"present_day", "historical_bounded"}
LEARNER_ROLES = {"present_day_self", "self_observer"}
LEARNING_STAGES = {
    "introduction",
    "retrieval",
    "phrase_or_sentence_use",
    "later_reuse",
}
MEMBER_ROLES = {
    "context_introduction",
    "productive_pattern",
    "dialogue_turn",
    "morphology_contrast",
    "listening_contrast",
    "later_reuse",
    "story_opening",
    "story_recap",
}
RESPONSE_FAMILIES = {
    "pictureMapSelection",
    "sentenceConstruction",
    "freeTyping",
    "fillGap",
    "listenChoose",
    "listenType",
    "recordCompare",
    "matching",
    "readListenRespond",
    "grammarDiscovery",
}
CONTAINERS = {
    "none",
    "conversation",
    "radioListening",
    "contextualMistakeReview",
    "wordsYouCarry",
    "completion",
}
RISK_FLAGS = {
    "invented_text",
    "initial_mutation",
    "fada",
    "dialect_register",
    "historical_roleplay",
    "pronoun_reference",
    "long_sentence",
    "audio_pronunciation",
    "source_ambiguity",
    "sense_ambiguity",
}
FAMILY_STATES = {"draft", "active", "representative_contract_example", "retired"}
SOURCE_SUPPORT = {
    "repository_text",
    "external_attestation",
    "pattern_only",
    "exercise_context",
    "migration_only",
}
LOCKED_VOICE_PROFILE = {
    "id": "voice.irish-cultural-guide.eleven-v3.v1",
    "revision": 1,
    "provider": "ElevenLabs",
    "voice_name": "Irish Cultural Guide",
    "voice_id": "NPWroowF4phQhaPWjXPj",
    "model_id": "eleven_v3",
    "language_code": "ga",
    "output_format": "mp3_44100_192",
    "voice_settings": {"mode": "provider_defaults", "overrides": {}},
}
CAPTURE_DISPOSITION = "generated_unreviewed"
APPROVED_CREDIT_CAP = 25_000
CREDITS_PER_CHARACTER = 1.0
ESTIMATE_BASIS = "estimated_credits = Unicode character count × credits_per_character"
IRISH_PRIORITY_ORDER = [
    "exercise-bound phrase families",
    "reusable dialogue roles",
    "place/story openings and recaps",
    "controlled listening contrasts required by a defined learning action",
]


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def normalize_spoken_text(text: str) -> str:
    """Return the canonical text identity: NFC with outer/internal whitespace folded."""
    return " ".join(unicodedata.normalize("NFC", text).strip().split())


def canonical_audio_slug(text: str) -> str:
    """Match the frozen inventory and production-audio slug convention."""
    fadas = {"á": "aa", "é": "ee", "í": "ii", "ó": "oo", "ú": "uu"}
    flat: list[str] = []
    for char in normalize_spoken_text(text).lower():
        if char in fadas:
            flat.append(fadas[char])
        elif char.isascii() and char.isalpha():
            flat.append(char)
        else:
            flat.append(" ")
    return "-".join("".join(flat).split())


def text_sha256(text: str) -> str:
    return hashlib.sha256(normalize_spoken_text(text).encode("utf-8")).hexdigest()


def identifier_slug(text: str) -> str:
    decomposed = unicodedata.normalize("NFD", text.casefold())
    folded = "".join(
        char for char in decomposed if unicodedata.category(char) != "Mn"
    )
    return "-".join("".join(c if c.isalnum() else " " for c in folded).split())


def folded_for_match(text: str) -> str:
    decomposed = unicodedata.normalize("NFD", text.casefold())
    return "".join(
        char for char in decomposed if unicodedata.category(char) != "Mn"
    )


def stable_identifier(value: Any) -> bool:
    """Whether an authored id is safe to preserve as a durable reference."""
    return (
        isinstance(value, str)
        and bool(value.strip())
        and value == value.strip()
        and not any(char.isspace() for char in value)
        and "/" not in value
        and "\\" not in value
    )


def canonicalize_family_document(
    family: dict[str, Any], errors: list[str] | None = None
) -> dict[str, Any]:
    """Return a deterministic, NFC-normalized copy of a Track A family document.

    This function only normalizes identity-bearing text fields. It never invents or
    repairs missing authoring, provenance, review, capture, QA, or release state.
    """
    local_errors = errors if errors is not None else []
    normalized_family = copy.deepcopy(family)
    family_id = normalized_family.get("id")
    if not stable_identifier(family_id):
        local_errors.append("family: id must be a stable non-whitespace path-safe identifier")

    placements = normalized_family.get("atlas_placements")
    if isinstance(placements, list):
        placement_ids = [item.get("id") for item in placements if isinstance(item, dict)]
        if any(not stable_identifier(value) for value in placement_ids):
            local_errors.append(f"family:{family_id}: atlas placement ids must be stable identifiers")
        normalized_family["atlas_placements"] = sorted(
            placements, key=lambda item: str(item.get("id", ""))
        )

    members = normalized_family.get("members")
    if not isinstance(members, list):
        local_errors.append(f"family:{family_id}: members must be a list")
        return normalized_family

    seen_member_ids: set[str] = set()
    for member in members:
        if not isinstance(member, dict):
            local_errors.append(f"family:{family_id}: member must be an object")
            continue
        member_id = member.get("id")
        if not stable_identifier(member_id):
            local_errors.append(
                f"family:{family_id}: member id must be a stable non-whitespace path-safe identifier"
            )
        elif member_id in seen_member_ids:
            local_errors.append(f"family:{family_id}: duplicate member id {member_id!r}")
        else:
            seen_member_ids.add(member_id)

        irish = member.get("irish")
        if isinstance(irish, dict) and isinstance(irish.get("text"), str):
            normalized = normalize_spoken_text(irish["text"])
            irish["text"] = normalized
            irish["normalized_text"] = normalized
            irish["inventory_slug"] = canonical_audio_slug(normalized)
            irish["text_sha256"] = text_sha256(normalized)
        target = member.get("target")
        if isinstance(target, dict):
            for field in ("citation_form", "target_form"):
                if isinstance(target.get(field), str):
                    target[field] = unicodedata.normalize("NFC", target[field].strip())

    normalized_family["members"] = sorted(
        members, key=lambda item: str(item.get("id", ""))
    )
    target = normalized_family.get("target")
    if isinstance(target, dict):
        for field in ("citation_form",):
            if isinstance(target.get(field), str):
                target[field] = unicodedata.normalize("NFC", target[field].strip())
    return normalized_family


def collect_family_documents(root: Path, inputs: Sequence[str]) -> list[tuple[Path, dict[str, Any]]]:
    """Load explicit Track A files or directories in deterministic path order."""
    paths: set[Path] = set()
    for raw in inputs:
        candidate = resolve_repo_path(root, raw)
        if candidate is None:
            raise ValueError(f"family input is outside the repository or invalid: {raw!r}")
        if candidate.is_dir():
            paths.update(path for path in candidate.rglob("*.v2.json") if path.is_file())
        elif candidate.is_file() and candidate.suffixes[-2:] == [".v2", ".json"]:
            paths.add(candidate)
        else:
            raise ValueError(f"family input must be a .v2.json file or directory: {raw!r}")
    if not paths:
        raise ValueError("family input matched no .v2.json documents")
    documents: list[tuple[Path, dict[str, Any]]] = []
    for path in sorted(paths):
        try:
            payload = load_json(path)
        except (OSError, json.JSONDecodeError) as exc:
            raise ValueError(f"cannot read family document {path}: {exc}") from exc
        if not isinstance(payload, dict):
            raise ValueError(f"family document must be a JSON object: {path}")
        documents.append((path, payload))
    return documents


def family_partition_key(family: dict[str, Any]) -> tuple[str, str, str]:
    story_ref = family.get("story_ref") or {}
    target = family.get("target") or {}
    return (
        str(family.get("county", "")),
        str(story_ref.get("record_id", "")),
        str(target.get("sense_id", "")),
    )


def harvest_batch_id(partition: tuple[str, str, str]) -> str:
    county, story_id, sense_id = partition
    return ".".join(
        [
            "d32",
            "harvest",
            identifier_slug(county),
            identifier_slug(story_id),
            identifier_slug(sense_id),
        ]
    )


def registered_text_voice_index(
    contract: LoadedContract,
) -> dict[tuple[str, str], list[str]]:
    """Index all registered lines so a rerun can resume instead of re-requesting."""
    indexed: dict[tuple[str, str], list[str]] = {}
    for batch in contract.batches:
        voice_id = (batch.get("voice_profile") or {}).get("id", "")
        for line in batch.get("lines", []):
            if not isinstance(line, dict):
                continue
            digest = line.get("text_sha256")
            if isinstance(digest, str) and digest:
                indexed.setdefault((digest, voice_id), []).append(str(batch.get("batch_id")))
    return indexed


def merge_harvest_contract(
    contract: LoadedContract,
    families: Sequence[dict[str, Any]],
) -> LoadedContract:
    """Overlay normalized Track A families while preserving the canonical contract."""
    merged = copy.deepcopy(contract)
    family_by_id = {family.get("id"): family for family in merged.families}
    member_by_id = dict(merged.members)
    for family in families:
        family_id = family.get("id")
        family_by_id[family_id] = family
        for member in family.get("members", []):
            if isinstance(member, dict):
                member_by_id[member.get("id")] = member
    merged.families = [family_by_id[key] for key in sorted(family_by_id)]
    merged.members = {key: member_by_id[key] for key in sorted(member_by_id)}
    return merged


def prepare_harvest(
    contract: LoadedContract,
    documents: Sequence[tuple[Path, dict[str, Any]]],
    *,
    root: Path = ROOT,
    created_at: str,
) -> dict[str, Any]:
    """Normalize Track A families and prepare resumable, provider-blocked batches.

    Registered text/voice lines are reported and skipped. Duplicate candidate text is
    represented by one line with sorted member references; the report retains every
    duplicate so an author can inspect the merge. Incomplete members are reported as
    blocked and never enter a generation manifest.
    """
    errors: list[str] = []
    normalized_documents: list[dict[str, Any]] = []
    source_paths: dict[str, str] = {}
    family_by_id: dict[str, dict[str, Any]] = {}
    for path, document in documents:
        normalized = canonicalize_family_document(document, errors)
        family_id = normalized.get("id")
        if family_id in family_by_id:
            errors.append(f"duplicate family id {family_id!r} in Track A inputs")
        else:
            family_by_id[family_id] = normalized
        relative = str(path.resolve().relative_to(root.resolve()))
        source_paths[family_id] = relative
        if normalized.get("schema_version") != 2 or normalized.get("contract") != "irish_phrase_family":
            errors.append(f"family:{family_id}: invalid v2 family schema/contract")
        county = normalized.get("county")
        if county not in {
            placement.get("county") for placement in contract.placements.values()
        }:
            errors.append(f"family:{family_id}: unknown county")
        validate_ref(
            normalized.get("story_ref"),
            root,
            f"family:{family_id}.story_ref",
            errors,
        )
        target = normalized.get("target")
        if not isinstance(target, dict) or not all(
            isinstance(target.get(field), str) and target[field].strip()
            for field in ("lexeme_id", "citation_form", "sense_id", "part_of_speech", "english_sense")
        ):
            errors.append(f"family:{family_id}: complete target identity is required")
        for atlas_ref in normalized.get("atlas_placements", []):
            placement_id = atlas_ref.get("id") if isinstance(atlas_ref, dict) else None
            placement = contract.placements.get(placement_id)
            if placement is None:
                errors.append(f"family:{family_id}: unknown atlas placement {placement_id!r}")
                continue
            if placement["county"] != county or placement["citation_form"] != (target or {}).get("citation_form"):
                errors.append(f"family:{family_id}: atlas placement identity mismatch")
            if atlas_ref.get("gloss") != placement["gloss"]:
                errors.append(f"family:{family_id}: atlas placement gloss mismatch")
        for member in normalized.get("members", []):
            validate_member(
                member,
                normalized,
                root,
                contract.placements,
                contract.inventory,
                errors,
            )
        normalized_documents.append(
            {"path": relative, "family": normalized}
        )

    merged = merge_harvest_contract(contract, list(family_by_id.values()))
    candidates_by_text: dict[str, list[tuple[str, str, tuple[str, str, str]]]] = {}
    blocked: list[dict[str, str]] = []
    member_seen: set[str] = set()
    for family_id in sorted(family_by_id):
        family = family_by_id[family_id]
        partition = family_partition_key(family)
        for member in family.get("members", []):
            if not isinstance(member, dict):
                continue
            member_id = member.get("id")
            if member_id in member_seen:
                errors.append(f"duplicate member id {member_id!r} across Track A inputs")
                continue
            member_seen.add(member_id)
            authoring_status = (member.get("states") or {}).get("authoring", {}).get("status")
            irish = member.get("irish")
            normalized_text = irish.get("normalized_text") if isinstance(irish, dict) else None
            if authoring_status != "complete" or not isinstance(normalized_text, str) or not normalized_text:
                blocked.append(
                    {
                        "member_id": str(member_id),
                        "reason": "authoring_incomplete_or_missing_canonical_irish",
                    }
                )
                continue
            digest = text_sha256(normalized_text)
            candidates_by_text.setdefault(normalized_text, []).append(
                (str(member_id), digest, partition)
            )

    locked_voice_id = contract.store.get("irish_generation_lock", {}).get(
        "required_voice_profile_id", ""
    )
    registered = registered_text_voice_index(contract)
    duplicate_findings: list[dict[str, Any]] = []
    skipped_registered: list[dict[str, Any]] = []
    partition_members: dict[tuple[str, str, str], set[str]] = {}
    for normalized_text in sorted(candidates_by_text):
        candidates = sorted(candidates_by_text[normalized_text], key=lambda item: (item[2], item[0]))
        digest = candidates[0][1]
        member_ids = sorted({item[0] for item in candidates})
        partitions = sorted({item[2] for item in candidates})
        if len(member_ids) > 1:
            duplicate_findings.append(
                {
                    "normalized_text": normalized_text,
                    "text_sha256": digest,
                    "voice_profile_id": locked_voice_id,
                    "member_ids": member_ids,
                    "partitions": [list(partition) for partition in partitions],
                    "action": "merge_one_manifest_line",
                }
            )
        prior_batches = registered.get((digest, locked_voice_id), [])
        if prior_batches:
            skipped_registered.append(
                {
                    "normalized_text": normalized_text,
                    "text_sha256": digest,
                    "member_ids": member_ids,
                    "registered_batch_ids": sorted(set(prior_batches)),
                    "action": "reuse_registered_line",
                }
            )
            continue
        owner_partition = partitions[0]
        partition_members.setdefault(owner_partition, set()).update(member_ids)

    batches: list[dict[str, Any]] = []
    for partition in sorted(partition_members):
        batch_id = harvest_batch_id(partition)
        purpose = (
            "D32 emergency harvest — "
            f"{partition[0]} / {partition[1]} / {partition[2]}"
        )
        batch = build_batch(
            merged,
            batch_id=batch_id,
            member_ids=sorted(partition_members[partition]),
            voice_profile_id=locked_voice_id,
            created_at=created_at,
            purpose=purpose,
        )
        # Harvest preparation never authorizes provider calls. Any later approval is
        # an explicit operation on the named manifest and line, outside this planner.
        if batch["execution"]["state"] != "draft" or batch["execution"]["provider_calls_allowed"]:
            raise ValueError("harvest planner produced a provider-enabled draft")
        batches.append(batch)

    return {
        "errors": errors,
        "normalized_documents": normalized_documents,
        "batches": batches,
        "contract": merged,
        "blocked_members": blocked,
        "duplicate_findings": duplicate_findings,
        "skipped_registered": skipped_registered,
        "source_paths": source_paths,
    }


def harvest_report(plan: dict[str, Any]) -> dict[str, Any]:
    """Small stable report shape for handoffs and machine checks."""
    return {
        "scope": "D32 provisional harvest preparation; not learner-release approval",
        "batch_ids": [batch["batch_id"] for batch in plan.get("batches", [])],
        "batch_line_counts": {
            batch["batch_id"]: batch["counts"]["lines"]
            for batch in plan.get("batches", [])
        },
        "normalized_family_documents": [
            document["path"] for document in plan.get("normalized_documents", [])
        ],
        "blocked_members": plan.get("blocked_members", []),
        "duplicate_findings": plan.get("duplicate_findings", []),
        "skipped_registered": plan.get("skipped_registered", []),
    }


def parse_timestamp(value: str, label: str) -> datetime:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{label} must be an explicit ISO timestamp")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ValueError(f"{label} must be an explicit ISO timestamp: {value!r}") from exc
    if parsed.tzinfo is None:
        raise ValueError(f"{label} must include a timezone: {value!r}")
    return parsed


def emergency_partition_key_for_member(
    contract: LoadedContract, member_id: str
) -> tuple[str, str]:
    families = [
        family
        for family in contract.families
        if any(
            isinstance(member, dict) and member.get("id") == member_id
            for member in family.get("members", [])
        )
    ]
    if len(families) != 1:
        raise ValueError(f"member {member_id!r} must belong to exactly one family")
    family = families[0]
    story_ref = family.get("story_ref") or {}
    county = family.get("county")
    story_id = story_ref.get("record_id")
    if not stable_identifier(county) or not stable_identifier(story_id):
        raise ValueError(f"member {member_id!r} has an unsafe county/story partition")
    return str(county), str(story_id)


def build_emergency_batches(
    plan: dict[str, Any],
    *,
    created_at: str,
    batch_prefix: str,
    max_lines_per_batch: int,
) -> list[dict[str, Any]]:
    """Partition new planner lines into practical, resumable county/story batches."""
    if not stable_identifier(batch_prefix) or not batch_prefix.strip("."):
        raise ValueError("batch prefix must be a stable dotted identifier")
    if not isinstance(max_lines_per_batch, int) or max_lines_per_batch < 1:
        raise ValueError("max_lines_per_batch must be a positive integer")
    contract = plan.get("contract")
    if not isinstance(contract, LoadedContract):
        raise ValueError("harvest plan is missing its loaded contract")

    family_for_member = {
        member.get("id"): family
        for family in contract.families
        for member in family.get("members", [])
        if isinstance(member, dict) and member.get("id")
    }
    grouped_lines: dict[str, dict[str, Any]] = {}
    for seed_batch in plan.get("batches", []):
        for line in seed_batch.get("lines", []):
            text = line.get("normalized_text")
            member_ids = sorted(set(line.get("member_ids") or []))
            if not isinstance(text, str) or not text or not member_ids:
                continue
            partition = emergency_partition_key_for_member(contract, member_ids[0])
            existing = grouped_lines.get(text)
            if existing is None:
                grouped_lines[text] = {
                    "member_ids": set(member_ids),
                    "partition": partition,
                }
            else:
                existing["member_ids"].update(member_ids)

    grouped: dict[tuple[str, str], list[tuple[str, list[str]]]] = {}
    for text in sorted(grouped_lines):
        entry = grouped_lines[text]
        grouped.setdefault(entry["partition"], []).append(
            (text, sorted(entry["member_ids"]))
        )

    batches: list[dict[str, Any]] = []
    for (county, story_id), entries in sorted(grouped.items()):
        for offset in range(0, len(entries), max_lines_per_batch):
            chunk = entries[offset : offset + max_lines_per_batch]
            member_ids = sorted({member_id for _, ids in chunk for member_id in ids})
            sense_ids = sorted(
                {
                    family_for_member[member_id].get("target", {}).get("sense_id", "")
                    for _, ids in chunk
                    for member_id in ids
                    if member_id in family_for_member
                }
            )
            part_number = offset // max_lines_per_batch + 1
            batch_id = (
                f"{batch_prefix}.{identifier_slug(county)}."
                f"{identifier_slug(story_id)}.part-{part_number:02d}"
            )
            purpose = (
                f"D32 emergency harvest — {county} / {story_id} / "
                f"senses {', '.join(sense_ids)} / part {part_number:02d}"
            )
            batches.append(
                build_batch(
                    contract,
                    batch_id=batch_id,
                    member_ids=member_ids,
                    voice_profile_id=contract.store["irish_generation_lock"][
                        "required_voice_profile_id"
                    ],
                    created_at=created_at,
                    purpose=purpose,
                )
            )
    return sorted(batches, key=lambda batch: batch["batch_id"])


def approve_emergency_harvest(
    plan: dict[str, Any],
    *,
    approved_by: str,
    approved_at: str,
    requested_by: str,
    claim_owner: str,
    claimed_at: str,
    lease_expires_at: str,
) -> dict[str, Any]:
    """Authorize only D32 capture; retain every independent review/release gate."""
    for label, value in (
        ("approved_by", approved_by),
        ("requested_by", requested_by),
        ("claim_owner", claim_owner),
    ):
        if not stable_identifier(value):
            raise ValueError(f"{label} must be a stable identifier")
    approved_time = parse_timestamp(approved_at, "approved_at")
    claimed_time = parse_timestamp(claimed_at, "claimed_at")
    lease_time = parse_timestamp(lease_expires_at, "lease_expires_at")
    if lease_time <= claimed_time:
        raise ValueError("lease_expires_at must be later than claimed_at")
    if approved_time > claimed_time:
        raise ValueError("approved_at must not be later than claimed_at")
    contract = plan.get("contract")
    if not isinstance(contract, LoadedContract):
        raise ValueError("harvest plan is missing its loaded contract")

    for batch in plan.get("batches", []):
        batch["execution"] = {
            "state": "approved",
            "provider_calls_allowed": True,
            "approved_by": approved_by,
            "approved_at": approved_at,
        }
        for line in batch.get("lines", []):
            line["claim"] = {
                "status": "claimed",
                "owner_id": claim_owner,
                "claimed_at": claimed_at,
                "lease_expires_at": lease_expires_at,
            }
            line["request"] = {
                "status": "approved",
                "approved_by": approved_by,
                "approved_at": approved_at,
            }
            line_id = line["line_id"]
            for member_id in line["member_ids"]:
                member = contract.members[member_id]
                capture = member["states"]["capture_request"]
                if capture["status"] == "requested":
                    if (capture.get("authorization") or {}).get("basis") != "d32_emergency_harvest":
                        raise ValueError(
                            f"member {member_id!r} already has a non-D32 capture request"
                        )
                elif capture["status"] not in {"not_requested", "planned", "cancelled"}:
                    raise ValueError(
                        f"member {member_id!r} has an unsafe capture state {capture['status']!r}"
                    )
                capture.update(
                    {
                        "status": "requested",
                        "requested_by": requested_by,
                        "requested_at": claimed_at,
                        "authorization": {
                            "basis": "d32_emergency_harvest",
                            "authorized_by": approved_by,
                            "authorized_at": approved_at,
                            "reason": (
                                "Explicit D32 emergency-harvest authorization for provisional "
                                "capture; review and learner release remain blocked."
                            ),
                            "fixture_only": False,
                            "harvest_deadline": "2026-08-11",
                            "learner_release_blocked": True,
                        },
                        "batch_line_ids": sorted(
                            set(capture.get("batch_line_ids", [])) | {line_id}
                        ),
                    }
                )
        batch["counts"] = expected_batch_counts(batch)
    for document in plan.get("normalized_documents", []):
        family = document["family"]
        for index, member in enumerate(family.get("members", [])):
            member_id = member.get("id") if isinstance(member, dict) else None
            if member_id in contract.members:
                family["members"][index] = contract.members[member_id]
    plan["batches"] = sorted(plan.get("batches", []), key=lambda batch: batch["batch_id"])
    plan["emergency_approved"] = True
    plan["claim_owner"] = claim_owner
    plan["lease_expires_at"] = lease_expires_at
    return plan


def write_emergency_harvest(plan: dict[str, Any], *, root: Path = ROOT) -> list[str]:
    """Persist approved manifests and family requests, then register sorted refs."""
    if not plan.get("emergency_approved"):
        raise ValueError("emergency harvest must be explicitly approved before writing")
    batches = plan.get("batches", [])
    if not batches:
        return []
    store_path = root / STORE_PATH.relative_to(ROOT)
    store = load_json(store_path)
    family_refs = {
        ref.get("family_id"): ref.get("path")
        for ref in store.get("family_documents", [])
        if isinstance(ref, dict)
    }
    for document in plan.get("normalized_documents", []):
        family = document["family"]
        if family_refs.get(family.get("id")) != document["path"]:
            raise ValueError(
                "emergency harvest requires canonical registered family paths: "
                f"{family.get('id')!r}"
            )
    batch_dir = root / "content/audio/authoring/batches"
    existing_batch_ids = {
        ref.get("batch_id")
        for ref in store.get("batch_documents", [])
        if isinstance(ref, dict)
    }
    for batch in batches:
        if batch["batch_id"] in existing_batch_ids:
            raise ValueError(f"refusing to replace registered batch {batch['batch_id']!r}")
        errors: list[str] = []
        validate_batch(batch, plan["contract"], root, errors)
        if errors:
            raise ValueError("approved manifest failed validation:\n" + "\n".join(errors))
        if (batch_dir / f"{batch['batch_id']}.json").exists():
            raise ValueError(f"refusing to overwrite manifest {batch['batch_id']!r}")

    written: list[str] = []
    for document in plan.get("normalized_documents", []):
        path = root / document["path"]
        path.write_text(
            json.dumps(document["family"], ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        written.append(document["path"])
    batch_dir.mkdir(parents=True, exist_ok=True)
    new_refs: list[dict[str, str]] = []
    for batch in batches:
        path = batch_dir / f"{batch['batch_id']}.json"
        path.write_text(
            json.dumps(batch, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        relative = str(path.relative_to(root))
        written.append(relative)
        new_refs.append({"batch_id": batch["batch_id"], "path": relative})
    store["batch_documents"] = sorted(
        [ref for ref in store.get("batch_documents", []) if isinstance(ref, dict)] + new_refs,
        key=lambda ref: ref.get("batch_id", ""),
    )
    store_path.write_text(
        json.dumps(store, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    written.append(str(store_path.relative_to(root)))
    return written


def is_unique_string_list(value: Any, *, allow_empty: bool = True) -> bool:
    return (
        isinstance(value, list)
        and (allow_empty or bool(value))
        and all(isinstance(item, str) and bool(item) for item in value)
        and len(value) == len(set(value))
    )


def is_sorted_unique_string_list(value: Any, *, allow_empty: bool = True) -> bool:
    return is_unique_string_list(value, allow_empty=allow_empty) and value == sorted(value)


def resolve_repo_path(root: Path, raw: str) -> Path | None:
    if not isinstance(raw, str) or not raw.strip():
        return None
    candidate = (root / raw).resolve()
    try:
        candidate.relative_to(root.resolve())
    except ValueError:
        return None
    return candidate


def walk_objects(value: Any) -> Iterable[dict[str, Any]]:
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk_objects(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_objects(child)


def record_by_id(payload: Any, record_id: str) -> dict[str, Any] | None:
    return next(
        (record for record in walk_objects(payload) if record.get("id") == record_id),
        None,
    )


def nested_value(record: dict[str, Any], dotted_field: str) -> Any:
    value: Any = record
    for component in dotted_field.split("."):
        if not isinstance(value, dict):
            return None
        value = value.get(component)
    return value


def validate_ref(
    ref: Any,
    root: Path,
    label: str,
    errors: list[str],
    *,
    expected_text: str | None = None,
) -> dict[str, Any] | None:
    if not isinstance(ref, dict):
        errors.append(f"{label}: reference must be an object")
        return None
    path = resolve_repo_path(root, ref.get("path"))
    if path is None:
        errors.append(f"{label}: invalid repository path")
        return None
    if not path.is_file():
        errors.append(f"{label}: source path does not exist: {ref.get('path')!r}")
        return None
    try:
        payload = load_json(path)
    except (json.JSONDecodeError, OSError) as exc:
        errors.append(f"{label}: cannot read JSON source: {exc}")
        return None
    record_id = ref.get("record_id")
    if not isinstance(record_id, str) or not record_id.strip():
        errors.append(f"{label}: record_id is required")
        return None
    record = record_by_id(payload, record_id)
    if record is None:
        errors.append(
            f"{label}: record_id {record_id!r} not found in {ref.get('path')!r}"
        )
        return None
    if expected_text is not None:
        text_field = ref.get("text_field")
        if not isinstance(text_field, str) or not text_field:
            errors.append(f"{label}: text_field is required for an exact-text source")
        elif normalize_spoken_text(str(nested_value(record, text_field) or "")) != expected_text:
            errors.append(
                f"{label}: {text_field!r} does not contain the canonical Irish text"
            )
    return record


def atlas_placements(atlas: dict[str, Any]) -> dict[str, dict[str, Any]]:
    placements: dict[str, dict[str, Any]] = {}
    for county, county_record in atlas.get("counties", {}).items():
        for position, word in enumerate(county_record.get("words", []), start=1):
            ga = word.get("ga")
            placement_id = f"atlas.{county}.{position:02d}.{identifier_slug(str(ga))}"
            placements[placement_id] = {
                "id": placement_id,
                "county": county,
                "position": position,
                "citation_form": ga,
                "gloss": word.get("en"),
            }
    return placements


def inventory_index(
    inventory: dict[str, Any], root: Path, errors: list[str]
) -> dict[str, dict[str, Any]]:
    indexed: dict[str, dict[str, Any]] = {}
    slug_owners: dict[str, str] = {}
    entries = inventory.get("entries")
    if not isinstance(entries, list):
        errors.append("inventory: entries must be a list")
        return indexed
    for position, entry in enumerate(entries):
        if not isinstance(entry, dict):
            errors.append(f"inventory.entries[{position}]: entry must be an object")
            continue
        text = entry.get("text")
        if not isinstance(text, str) or not text.strip():
            errors.append(f"inventory.entries[{position}]: non-empty text is required")
            continue
        normalized = normalize_spoken_text(text)
        if normalized in indexed:
            errors.append(f"inventory: duplicate normalized text {normalized!r}")
        indexed[normalized] = entry
        expected_slug = canonical_audio_slug(normalized)
        prior_text = slug_owners.get(expected_slug)
        if prior_text is not None and prior_text != normalized:
            errors.append(
                f"inventory: slug {expected_slug!r} collides for {prior_text!r} and {normalized!r}"
            )
        slug_owners[expected_slug] = normalized
        if entry.get("slug") != expected_slug:
            errors.append(
                f"inventory:{normalized}: slug {entry.get('slug')!r} != {expected_slug!r}"
            )
        if entry.get("qa_state") in {"generated_unreviewed", "spot_flagged", "qa_passed"}:
            audio_path = root / "ios/AnTuras/Resources/Audio" / f"{expected_slug}.mp3"
            if not audio_path.is_file():
                errors.append(
                    f"inventory:{normalized}: generated state has no canonical MP3"
                )
    return indexed


@dataclass
class LoadedContract:
    store: dict[str, Any]
    families: list[dict[str, Any]]
    members: dict[str, dict[str, Any]]
    inventory: dict[str, dict[str, Any]]
    placements: dict[str, dict[str, Any]]
    voice_profiles: dict[str, dict[str, Any]]
    batches: list[dict[str, Any]]


def validate_review(review: Any, label: str, errors: list[str]) -> None:
    if not isinstance(review, dict):
        errors.append(f"{label}: review must be an object")
        return
    status = review.get("status")
    if status not in REVIEW_STATES:
        errors.append(f"{label}: invalid review status {status!r}")
        return
    record = review.get("record")
    if status in {"approved", "changes_requested", "rejected"}:
        if not isinstance(record, dict):
            errors.append(f"{label}: disposition requires a review record")
            return
        for field in ("reviewer_ref", "reviewed_at", "scope", "evidence_ref"):
            if not isinstance(record.get(field), str) or not record[field].strip():
                errors.append(f"{label}: review record requires {field}")
    elif record is not None:
        errors.append(f"{label}: pending/not-requested review must not claim a record")


def validate_member(
    member: Any,
    family: dict[str, Any],
    root: Path,
    placements: dict[str, dict[str, Any]],
    inventory: dict[str, dict[str, Any]],
    errors: list[str],
) -> None:
    label = f"member:{member.get('id', '<missing>')}" if isinstance(member, dict) else "member"
    if not isinstance(member, dict):
        errors.append(f"{label}: member must be an object")
        return
    member_id = member.get("id")
    if not isinstance(member_id, str) or not member_id.strip():
        errors.append(f"{label}: id is required")
    if member.get("family_id") != family.get("id"):
        errors.append(f"{label}: family_id does not match its family document")

    states = member.get("states")
    if not isinstance(states, dict):
        errors.append(f"{label}: states must be an object")
        return
    authoring = states.get("authoring")
    authoring_status = authoring.get("status") if isinstance(authoring, dict) else None
    if authoring_status not in AUTHORING_STATES:
        errors.append(f"{label}: invalid authoring status {authoring_status!r}")
    complete = authoring_status == "complete"
    if isinstance(authoring, dict):
        if not isinstance(authoring.get("revision"), int) or authoring["revision"] < 1:
            errors.append(f"{label}: authoring requires a positive revision")
        if complete:
            for field in ("author_ref", "completed_at"):
                if not isinstance(authoring.get(field), str) or not authoring[field].strip():
                    errors.append(f"{label}: complete authoring requires {field}")

    target = member.get("target")
    family_target = family.get("target")
    if not isinstance(target, dict):
        errors.append(f"{label}: target must be an object")
    else:
        for field in ("lexeme_id", "citation_form", "sense_id", "part_of_speech"):
            if target.get(field) != (family_target or {}).get(field):
                errors.append(f"{label}: target.{field} does not match family target")
        if complete and (
            not isinstance(target.get("target_form"), str)
            or not target["target_form"].strip()
        ):
            errors.append(f"{label}: complete member requires target_form")

    irish = member.get("irish")
    english = member.get("english")
    normalized: str | None = None
    if complete:
        if not isinstance(irish, dict) or not isinstance(irish.get("text"), str):
            errors.append(f"{label}: complete member requires Irish text")
        else:
            normalized = normalize_spoken_text(irish["text"])
            if not normalized:
                errors.append(f"{label}: complete member requires non-empty Irish text")
            if irish.get("normalized_text") != normalized:
                errors.append(f"{label}: normalized_text is not canonical NFC/whitespace")
            if irish.get("inventory_slug") != canonical_audio_slug(normalized):
                errors.append(f"{label}: inventory_slug is not canonical")
            if irish.get("text_sha256") != text_sha256(normalized):
                errors.append(f"{label}: text_sha256 is not canonical")
            target_form = (target or {}).get("target_form")
            if isinstance(target_form, str) and folded_for_match(target_form) not in folded_for_match(normalized):
                errors.append(f"{label}: target_form does not occur in Irish text")
        if not isinstance(english, dict) or not isinstance(english.get("intent"), str) or not english["intent"].strip():
            errors.append(f"{label}: complete member requires idiomatic English intent")

    binding = member.get("binding")
    if not isinstance(binding, dict):
        errors.append(f"{label}: binding must be an object")
    else:
        if binding.get("county") != family.get("county"):
            errors.append(f"{label}: binding county does not match family county")
        if binding.get("story_ref") != family.get("story_ref"):
            errors.append(f"{label}: binding story_ref does not match family story_ref")
        if binding.get("setting") not in SETTINGS:
            errors.append(f"{label}: invalid setting")
        if binding.get("learner_role") not in LEARNER_ROLES:
            errors.append(f"{label}: invalid learner_role")
        if binding.get("setting") == "historical_bounded" and binding.get("learner_role") != "self_observer":
            errors.append(f"{label}: historical-bounded members keep the learner as observer")
        place = binding.get("place")
        if not isinstance(place, dict) or not all(
            isinstance(place.get(field), str) and place[field].strip()
            for field in ("id", "label")
        ):
            errors.append(f"{label}: binding.place requires id and label")
        placement_ids = binding.get("atlas_placement_ids")
        if not isinstance(placement_ids, list) or not placement_ids:
            errors.append(f"{label}: at least one atlas placement is required")
        else:
            if not is_unique_string_list(placement_ids, allow_empty=False):
                errors.append(f"{label}: atlas placement ids must be unique non-empty strings")
            family_ids = {
                p.get("id")
                for p in family.get("atlas_placements", [])
                if isinstance(p, dict)
            }
            for placement_id in placement_ids:
                if not isinstance(placement_id, str):
                    continue
                if placement_id not in family_ids or placement_id not in placements:
                    errors.append(f"{label}: unknown/mismatched atlas placement {placement_id!r}")

    learning = member.get("learning")
    if not isinstance(learning, dict):
        errors.append(f"{label}: learning metadata must be an object")
    else:
        stages = learning.get("stages")
        if not isinstance(stages, list) or (complete and not stages):
            errors.append(f"{label}: complete member requires at least one learning stage")
            stages = []
        elif not is_unique_string_list(stages):
            errors.append(f"{label}: learning stages must be unique non-empty strings")
        for value in stages:
            if not isinstance(value, str) or value not in LEARNING_STAGES:
                errors.append(f"{label}: invalid learning stage {value!r}")
        roles = learning.get("roles")
        if not isinstance(roles, list) or not roles:
            errors.append(f"{label}: at least one member role is required")
        else:
            if not is_unique_string_list(roles, allow_empty=False):
                errors.append(f"{label}: member roles must be unique non-empty strings")
            for value in roles:
                if not isinstance(value, str) or value not in MEMBER_ROLES:
                    errors.append(f"{label}: invalid member role {value!r}")
        for field in ("dialect", "register", "purpose"):
            if not isinstance(learning.get(field), str) or not learning[field].strip():
                errors.append(f"{label}: learning.{field} is required")
        if not isinstance(learning.get("fixture_only"), bool):
            errors.append(f"{label}: learning.fixture_only must be boolean")

    consumers = member.get("exercise_consumers")
    if complete and (not isinstance(consumers, list) or not consumers):
        errors.append(f"{label}: complete member requires an exercise consumer")
    elif isinstance(consumers, list):
        for index, consumer in enumerate(consumers):
            clabel = f"{label}.exercise_consumers[{index}]"
            if not isinstance(consumer, dict):
                errors.append(f"{clabel}: consumer must be an object")
                continue
            if consumer.get("response_family") not in RESPONSE_FAMILIES:
                errors.append(f"{clabel}: invalid response family")
            if consumer.get("container") not in CONTAINERS:
                errors.append(f"{clabel}: invalid container")
            record = validate_ref(consumer, root, clabel, errors)
            exercise = record.get("exercise") if isinstance(record, dict) else None
            if isinstance(exercise, dict):
                if exercise.get("family") != consumer.get("response_family"):
                    errors.append(f"{clabel}: response family does not match exercise")
                if member_id not in (exercise.get("phraseFamilyMemberIDs") or []):
                    errors.append(f"{clabel}: exercise does not bind this member id")
            elif record is not None:
                errors.append(f"{clabel}: referenced record is not an exercise page")

    provenance = member.get("provenance")
    invented: bool | None = None
    origin = None
    if not isinstance(provenance, dict):
        errors.append(f"{label}: provenance must be an object")
    else:
        origin = provenance.get("origin")
        invented = provenance.get("invented")
        if origin not in PROVENANCE_ORIGINS:
            errors.append(f"{label}: invalid provenance origin {origin!r}")
        if origin == "invented_pedagogical" and invented is not True:
            errors.append(f"{label}: invented_pedagogical origin requires invented=true")
        if origin in {"repository_draft", "attested_external"} and invented is not False:
            errors.append(f"{label}: sourced origin requires invented=false")
        if origin == "legacy_unknown" and invented is not None:
            errors.append(f"{label}: legacy_unknown requires invented=null")
        refs = provenance.get("source_refs")
        if not isinstance(refs, list) or not refs:
            errors.append(f"{label}: provenance requires structured source_refs")
        else:
            for index, source_ref in enumerate(refs):
                slabel = f"{label}.provenance.source_refs[{index}]"
                supports = source_ref.get("supports") if isinstance(source_ref, dict) else None
                if supports not in SOURCE_SUPPORT:
                    errors.append(f"{slabel}: invalid supports value")
                if origin == "invented_pedagogical" and supports in {"repository_text", "external_attestation"}:
                    errors.append(f"{slabel}: invented text cannot claim textual attestation")
                validate_ref(
                    source_ref,
                    root,
                    slabel,
                    errors,
                    expected_text=(
                        normalized
                        if complete and supports in {"repository_text", "external_attestation"}
                        else None
                    ),
                )

    risk_flags = member.get("risk_flags")
    if not isinstance(risk_flags, list):
        errors.append(f"{label}: risk_flags must be a list")
    else:
        if not is_unique_string_list(risk_flags):
            errors.append(f"{label}: risk flags must be unique non-empty strings")
        unknown = [
            repr(value)
            for value in risk_flags
            if not isinstance(value, str) or value not in RISK_FLAGS
        ]
        if unknown:
            errors.append(f"{label}: unknown risk flags {sorted(unknown)!r}")
        if invented is True and "invented_text" not in risk_flags:
            errors.append(f"{label}: invented text requires invented_text risk")

    reviews = states.get("reviews")
    if not isinstance(reviews, dict):
        errors.append(f"{label}: reviews must be an object")
        reviews = {}
    for review_name in ("editorial", "pedagogy", "irish_language"):
        validate_review(reviews.get(review_name), f"{label}.reviews.{review_name}", errors)

    capture = states.get("capture_request")
    capture_status = capture.get("status") if isinstance(capture, dict) else None
    if capture_status not in CAPTURE_REQUEST_STATES:
        errors.append(f"{label}: invalid capture request status {capture_status!r}")
    if authoring_status != "complete" and capture_status not in {"not_requested", "cancelled"}:
        errors.append(f"{label}: incomplete/retired text cannot request capture")
    if capture_status == "requested":
        authorization = capture.get("authorization") if isinstance(capture, dict) else None
        for field in ("requested_by", "requested_at"):
            if not isinstance(capture.get(field), str) or not capture[field].strip():
                errors.append(f"{label}: requested capture requires {field}")
        if not isinstance(authorization, dict):
            errors.append(f"{label}: requested capture requires authorization")
        else:
            basis = authorization.get("basis")
            for field in ("authorized_by", "authorized_at", "reason"):
                if not isinstance(authorization.get(field), str) or not authorization[field].strip():
                    errors.append(f"{label}: capture authorization requires {field}")
            pedagogy_status = (reviews.get("pedagogy") or {}).get("status")
            if invented is True:
                if basis == "pedagogy_approved":
                    if pedagogy_status != "approved":
                        errors.append(f"{label}: invented capture requires approved pedagogy review")
                elif basis == "fixture_owner_exception":
                    if not (learning or {}).get("fixture_only") or authorization.get("fixture_only") is not True:
                        errors.append(f"{label}: fixture exception must be explicitly fixture-only")
                elif basis == "d32_emergency_harvest":
                    if authorization.get("harvest_deadline") != "2026-08-11":
                        errors.append(f"{label}: D32 harvest authorization requires the 2026-08-11 deadline")
                    if authorization.get("learner_release_blocked") is not True:
                        errors.append(f"{label}: D32 harvest authorization must keep learner release blocked")
                else:
                    errors.append(f"{label}: unsafe authorization for invented capture")
            elif basis not in {"repository_draft_owner", "pedagogy_approved", "d32_emergency_harvest"}:
                errors.append(f"{label}: invalid authorization for sourced capture")
    elif isinstance(capture, dict) and capture.get("authorization") is not None:
        errors.append(f"{label}: only requested capture may carry authorization")
    if isinstance(capture, dict):
        batch_line_ids = capture.get("batch_line_ids")
        if not is_sorted_unique_string_list(batch_line_ids):
            errors.append(f"{label}: capture batch_line_ids must be a sorted unique list")

    audio_qa = states.get("audio_qa")
    audio_qa_status = audio_qa.get("status") if isinstance(audio_qa, dict) else None
    if audio_qa_status not in AUDIO_QA_STATES:
        errors.append(f"{label}: invalid audio QA status {audio_qa_status!r}")
    if audio_qa_status in {"passed", "flagged", "failed"}:
        record = audio_qa.get("record") if isinstance(audio_qa, dict) else None
        if not isinstance(record, dict):
            errors.append(f"{label}: audio QA disposition requires a record")
        else:
            for field in ("reviewer_ref", "reviewed_at", "clip_sha256", "note"):
                if not isinstance(record.get(field), str) or not record[field].strip():
                    errors.append(f"{label}: audio QA record requires {field}")
        if not isinstance(audio_qa.get("batch_line_id"), str) or not audio_qa["batch_line_id"]:
            errors.append(f"{label}: audio QA disposition requires batch_line_id")

    release = states.get("learner_release")
    release_status = release.get("status") if isinstance(release, dict) else None
    if release_status not in RELEASE_STATES:
        errors.append(f"{label}: invalid learner-release status {release_status!r}")
    if release_status == "eligible":
        for review_name in ("editorial", "pedagogy", "irish_language"):
            if (reviews.get(review_name) or {}).get("status") != "approved":
                errors.append(f"{label}: release requires approved {review_name} review")
        if audio_qa_status != "passed":
            errors.append(f"{label}: release requires passed audio QA")
        if release.get("reasons"):
            errors.append(f"{label}: eligible release must not list blockers")
    elif release_status == "blocked" and not release.get("reasons"):
        errors.append(f"{label}: blocked release must state reasons")

    if normalized is not None and normalized in inventory:
        entry = inventory[normalized]
        inventory_invented = entry.get("source") == "invented"
        if invented is not None and inventory_invented != invented:
            errors.append(
                f"{label}: provenance conflicts with inventory source {entry.get('source')!r}"
            )
        if entry.get("slug") != (irish or {}).get("inventory_slug"):
            errors.append(f"{label}: member slug conflicts with inventory")
    elif audio_qa_status in {"passed", "flagged", "legacy_unverified"}:
        errors.append(f"{label}: audio QA state requires an inventory entry")


def load_voice_profiles(root: Path, errors: list[str]) -> dict[str, dict[str, Any]]:
    path = root / VOICE_PROFILES_PATH.relative_to(ROOT)
    if not path.is_file():
        errors.append("voice profiles: canonical document is missing")
        return {}
    payload = load_json(path)
    if payload.get("schema_version") != 1 or payload.get("contract") != "irish_voice_profiles":
        errors.append("voice profiles: invalid schema/contract")
    profiles: dict[str, dict[str, Any]] = {}
    profile_rows = payload.get("profiles")
    if not isinstance(profile_rows, list):
        errors.append("voice profiles: profiles must be a list")
        return profiles
    for profile in profile_rows:
        if not isinstance(profile, dict):
            errors.append("voice profiles: profile must be an object")
            continue
        profile_id = profile.get("id")
        if not isinstance(profile_id, str) or not profile_id:
            errors.append("voice profiles: profile id is required")
            continue
        if profile_id in profiles:
            errors.append(f"voice profiles: duplicate profile {profile_id!r}")
        profiles[profile_id] = profile
        for field in ("provider", "voice_id", "model_id", "language_code", "output_format"):
            if not isinstance(profile.get(field), str) or not profile[field]:
                errors.append(f"voice profile {profile_id}: {field} is required")
        if not isinstance(profile.get("revision"), int) or profile["revision"] < 1:
            errors.append(f"voice profile {profile_id}: positive revision is required")
        if profile != LOCKED_VOICE_PROFILE:
            errors.append(
                f"voice profile {profile_id}: exact user-locked Irish configuration changed"
            )
    return profiles


def immutable_batch_projection(batch: dict[str, Any]) -> dict[str, Any]:
    return {
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


def batch_identity_sha256(batch: dict[str, Any]) -> str:
    encoded = json.dumps(
        immutable_batch_projection(batch),
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def expected_batch_counts(batch: dict[str, Any]) -> dict[str, int]:
    lines = batch.get("lines", [])
    return {
        "lines": len(lines),
        "member_references": sum(len(line.get("member_ids", [])) for line in lines),
        "planned": sum(1 for line in lines if line.get("request", {}).get("status") == "planned"),
        "approved": sum(1 for line in lines if line.get("request", {}).get("status") == "approved"),
        "succeeded": sum(1 for line in lines if line.get("provider_result", {}).get("status") == "succeeded"),
        "failed": sum(1 for line in lines if line.get("provider_result", {}).get("status") == "failed"),
    }


def validate_batch(
    batch: dict[str, Any],
    contract: LoadedContract,
    root: Path,
    errors: list[str],
) -> None:
    label = f"batch:{batch.get('batch_id', '<missing>')}"
    if batch.get("schema_version") != 1 or batch.get("contract") != "irish_generation_batch":
        errors.append(f"{label}: invalid schema/contract")
    for field in ("batch_id", "created_at", "purpose"):
        if not isinstance(batch.get(field), str) or not batch[field].strip():
            errors.append(f"{label}: {field} is required")
    execution = batch.get("execution")
    if not isinstance(execution, dict):
        errors.append(f"{label}: execution must be an object")
        execution = {}
    execution_state = execution.get("state")
    if execution_state not in {"draft", "approved", "closed"}:
        errors.append(f"{label}: invalid execution state")
    if execution_state == "draft" and execution.get("provider_calls_allowed") is not False:
        errors.append(f"{label}: draft manifest must forbid provider calls")
    if execution_state == "draft" and any(
        execution.get(field) is not None for field in ("approved_by", "approved_at")
    ):
        errors.append(f"{label}: draft manifest must not claim execution approval")
    if execution_state == "approved":
        if execution.get("provider_calls_allowed") is not True:
            errors.append(f"{label}: approved manifest must explicitly allow provider calls")
        for field in ("approved_by", "approved_at"):
            if not isinstance(execution.get(field), str) or not execution[field]:
                errors.append(f"{label}: approved execution requires {field}")
    if execution_state == "closed":
        if execution.get("provider_calls_allowed") is not False:
            errors.append(f"{label}: closed manifest must forbid provider calls")
        for field in ("approved_by", "approved_at"):
            if not isinstance(execution.get(field), str) or not execution[field]:
                errors.append(f"{label}: closed execution retains {field}")

    voice = batch.get("voice_profile")
    required_profile_id = contract.store.get("irish_generation_lock", {}).get(
        "required_voice_profile_id"
    )
    if isinstance(voice, dict) and voice.get("id") != required_profile_id:
        errors.append(f"{label}: Irish voice/model profile violates the user lock")
    profile = contract.voice_profiles.get(voice.get("id")) if isinstance(voice, dict) else None
    if profile is None:
        errors.append(f"{label}: unknown voice profile")
    elif voice != profile:
        errors.append(f"{label}: voice profile snapshot is stale or incomplete")

    spend = batch.get("spend")
    if not isinstance(spend, dict):
        errors.append(f"{label}: spend must be an object")
        spend = {}
    cap_auth = spend.get("cap_authorization")
    cap_removed = isinstance(cap_auth, dict) and cap_auth.get("status") == "removed"
    if not cap_removed and spend.get("approved_cap") != APPROVED_CREDIT_CAP:
        errors.append(f"{label}: spend approved_cap must remain {APPROVED_CREDIT_CAP}")
    if cap_removed:
        for field in ("authorized_by", "authorized_at", "reason"):
            if not isinstance(cap_auth.get(field), str) or not cap_auth[field].strip():
                errors.append(f"{label}: removed cap requires {field}")
    if spend.get("estimate_basis") != ESTIMATE_BASIS:
        errors.append(f"{label}: spend estimate_basis is not canonical")
    if spend.get("credits_per_character") != CREDITS_PER_CHARACTER:
        errors.append(f"{label}: spend credits_per_character is not canonical")
    for field in ("estimated_batch_credits", "estimated_cumulative_credits"):
        value = spend.get(field)
        if not isinstance(value, (int, float)) or isinstance(value, bool) or value < 0:
            errors.append(f"{label}: spend {field} must be a non-negative number")
    for field in ("actual_batch_credits", "actual_cumulative_credits"):
        value = spend.get(field)
        if value is not None and (
            not isinstance(value, (int, float)) or isinstance(value, bool) or value < 0
        ):
            errors.append(f"{label}: spend {field} must be null or a non-negative number")
    for field in ("usage_before", "usage_after"):
        snapshot = spend.get(field)
        if snapshot is not None and not isinstance(snapshot, dict):
            errors.append(f"{label}: spend {field} must be null or an object")

    lines = batch.get("lines")
    if not isinstance(lines, list):
        errors.append(f"{label}: lines must be a list")
        return
    ids = [line.get("line_id") for line in lines if isinstance(line, dict)]
    if not is_sorted_unique_string_list(ids):
        errors.append(f"{label}: lines must use unique deterministic line_id ordering")
    seen_text_ids: set[tuple[str, str]] = set()
    seen_slugs: dict[str, str] = {}
    for index, line in enumerate(lines):
        llabel = f"{label}.lines[{index}]"
        if not isinstance(line, dict):
            errors.append(f"{llabel}: line must be an object")
            continue
        text = line.get("normalized_text")
        if not isinstance(text, str) or not text:
            errors.append(f"{llabel}: normalized_text is required")
            continue
        normalized = normalize_spoken_text(text)
        if text != normalized:
            errors.append(f"{llabel}: text is not canonical")
        if line.get("text_sha256") != text_sha256(normalized):
            errors.append(f"{llabel}: text_sha256 mismatch")
        slug = canonical_audio_slug(normalized)
        if line.get("inventory_slug") != slug:
            errors.append(f"{llabel}: inventory_slug mismatch")
        estimated_characters = line.get("estimated_characters")
        if estimated_characters != len(normalized):
            errors.append(f"{llabel}: estimated_characters mismatch")
        estimated_credits = line.get("estimated_credits")
        if estimated_credits != round(len(normalized) * CREDITS_PER_CHARACTER, 3):
            errors.append(f"{llabel}: estimated_credits mismatch")
        if line.get("capture_disposition") != CAPTURE_DISPOSITION:
            errors.append(
                f"{llabel}: capture_disposition must be {CAPTURE_DISPOSITION!r}"
            )
        prior_slug_text = seen_slugs.get(slug)
        if prior_slug_text is not None and prior_slug_text != normalized:
            errors.append(f"{llabel}: inventory_slug collides with another batch line")
        seen_slugs[slug] = normalized
        voice_id = (voice or {}).get("id")
        text_key = (line.get("text_sha256"), voice_id)
        if text_key in seen_text_ids:
            errors.append(f"{llabel}: duplicate text/voice line; member refs must be merged")
        seen_text_ids.add(text_key)
        member_ids = line.get("member_ids")
        if not is_sorted_unique_string_list(member_ids, allow_empty=False):
            errors.append(f"{llabel}: member_ids must be a sorted unique non-empty list")
            member_ids = []
        for member_id in member_ids:
            member = contract.members.get(member_id)
            if member is None:
                errors.append(f"{llabel}: unknown member {member_id!r}")
                continue
            if member.get("states", {}).get("authoring", {}).get("status") != "complete":
                errors.append(f"{llabel}: batch references incomplete member {member_id!r}")
            if member.get("irish", {}).get("normalized_text") != normalized:
                errors.append(f"{llabel}: member text does not match line")
            if line.get("request", {}).get("status") == "approved":
                capture_request = member.get("states", {}).get("capture_request", {})
                if capture_request.get("status") != "requested":
                    errors.append(f"{llabel}: approved line requires requested member capture")
                elif line.get("line_id") not in capture_request.get("batch_line_ids", []):
                    errors.append(f"{llabel}: member capture request does not name this batch line")

        expected_line_seed = "\n".join(
            [line.get("text_sha256", ""), str(voice_id), str((voice or {}).get("revision"))]
        )
        expected_line_id = (
            f"{batch.get('batch_id')}.line."
            f"{hashlib.sha256(expected_line_seed.encode('utf-8')).hexdigest()[:16]}"
        )
        if line.get("line_id") != expected_line_id:
            errors.append(f"{llabel}: deterministic line_id mismatch")

        claim = line.get("claim")
        claim_status = claim.get("status") if isinstance(claim, dict) else None
        if not isinstance(claim, dict) or claim.get("status") not in {"unclaimed", "claimed", "released", "completed"}:
            errors.append(f"{llabel}: invalid claim state")
        elif claim.get("status") == "unclaimed":
            if any(claim.get(field) is not None for field in ("owner_id", "claimed_at", "lease_expires_at")):
                errors.append(f"{llabel}: unclaimed line must not carry ownership")
        else:
            for field in ("owner_id", "claimed_at"):
                if not isinstance(claim.get(field), str) or not claim[field]:
                    errors.append(f"{llabel}: claimed line requires {field}")
            if claim_status == "claimed" and (
                not isinstance(claim.get("lease_expires_at"), str)
                or not claim["lease_expires_at"]
            ):
                errors.append(f"{llabel}: active claim requires lease_expires_at")

        request = line.get("request")
        if not isinstance(request, dict) or request.get("status") not in {"planned", "approved", "cancelled"}:
            errors.append(f"{llabel}: invalid request state")
        elif request.get("status") == "approved" and execution_state != "approved":
            errors.append(f"{llabel}: line cannot be approved in an unapproved batch")
        elif execution_state == "approved" and request.get("status") not in {"approved", "cancelled"}:
            errors.append(
                f"{llabel}: approved batch requires an approved or explicitly cancelled line request"
            )
        if isinstance(request, dict) and request.get("status") == "approved":
            for field in ("approved_by", "approved_at"):
                if not isinstance(request.get(field), str) or not request[field]:
                    errors.append(f"{llabel}: approved line request requires {field}")

        retry = line.get("retry")
        if not isinstance(retry, dict):
            errors.append(f"{llabel}: retry must be an object")
            retry = {}
        attempt_count = retry.get("attempt_count")
        max_attempts = retry.get("max_attempts")
        if not isinstance(attempt_count, int) or attempt_count < 0:
            errors.append(f"{llabel}: invalid attempt_count")
        if not isinstance(max_attempts, int) or max_attempts < 1:
            errors.append(f"{llabel}: invalid max_attempts")
        if isinstance(attempt_count, int) and isinstance(max_attempts, int) and attempt_count > max_attempts:
            errors.append(f"{llabel}: attempt_count exceeds max_attempts")

        result = line.get("provider_result")
        result_status = result.get("status") if isinstance(result, dict) else None
        if isinstance(request, dict) and request.get("status") == "cancelled":
            if result_status != "not_started":
                errors.append(f"{llabel}: cancelled line must not claim provider work")
            output = resolve_repo_path(root, (line.get("audio") or {}).get("output_path"))
            if output is None or not output.is_file():
                errors.append(f"{llabel}: cancelled line must retain an existing canonical audio file")
        if result_status not in {"not_started", "in_progress", "succeeded", "failed"}:
            errors.append(f"{llabel}: invalid provider result state")
        if execution_state == "draft" and result_status != "not_started":
            errors.append(f"{llabel}: draft batch cannot claim a provider result")
        if result_status != "not_started":
            if execution_state not in {"approved", "closed"} or request.get("status") != "approved":
                errors.append(f"{llabel}: provider work requires approved batch and line request")
            if claim_status in {None, "unclaimed"}:
                errors.append(f"{llabel}: provider work requires an explicit claim owner")
        if result_status == "in_progress" and claim_status != "claimed":
            errors.append(f"{llabel}: in-progress provider work requires a claimed line")
        if result_status == "succeeded" and claim_status != "completed":
            errors.append(f"{llabel}: succeeded provider work requires a completed claim")
        if isinstance(result, dict):
            for field in ("reported_credits", "reported_characters"):
                value = result.get(field)
                if value is not None and (
                    not isinstance(value, (int, float))
                    or isinstance(value, bool)
                    or value < 0
                    or (field == "reported_characters" and not isinstance(value, int))
                ):
                    errors.append(f"{llabel}: {field} must be null or a non-negative number")
            if result_status in {"not_started", "in_progress"} and any(
                result.get(field) is not None
                for field in ("reported_credits", "reported_characters")
            ):
                errors.append(f"{llabel}: unfinished provider result must not claim reported cost")
            if result_status == "succeeded" and all(
                result.get(field) is None
                for field in ("reported_credits", "reported_characters")
            ):
                errors.append(f"{llabel}: succeeded provider result requires reported cost")
        error = line.get("error")
        if result_status == "failed":
            if not isinstance(error, dict) or not all(
                field in error for field in ("code", "message", "retriable", "occurred_at")
            ):
                errors.append(f"{llabel}: failed result requires structured error metadata")
            if not isinstance(attempt_count, int) or attempt_count < 1:
                errors.append(f"{llabel}: failed result requires an attempt")
        elif error is not None:
            errors.append(f"{llabel}: non-failed result must not carry an error")

        audio = line.get("audio")
        expected_output = f"ios/AnTuras/Resources/Audio/{slug}.mp3"
        if not isinstance(audio, dict) or audio.get("output_path") != expected_output:
            errors.append(f"{llabel}: audio output path must use the canonical slug")
            audio = {}
        if result_status == "succeeded":
            for field in ("provider_request_id", "completed_at"):
                if not isinstance(result.get(field), str) or not result[field]:
                    errors.append(f"{llabel}: succeeded result requires {field}")
            output = resolve_repo_path(root, audio.get("output_path"))
            if output is None or not output.is_file():
                errors.append(f"{llabel}: succeeded result has no audio file")
            else:
                digest = hashlib.sha256(output.read_bytes()).hexdigest()
                if audio.get("sha256") != digest:
                    errors.append(f"{llabel}: audio checksum mismatch")
                if audio.get("bytes") != output.stat().st_size:
                    errors.append(f"{llabel}: audio byte count mismatch")
            if not isinstance(attempt_count, int) or attempt_count < 1:
                errors.append(f"{llabel}: succeeded result requires an attempt")
        elif any(audio.get(field) is not None for field in ("sha256", "bytes", "duration_seconds")):
            errors.append(f"{llabel}: unfinished result must not claim audio result metadata")

        audio_qa = line.get("audio_qa")
        if not isinstance(audio_qa, dict) or audio_qa.get("status") not in {"not_started", "pending", "passed", "flagged", "failed"}:
            errors.append(f"{llabel}: invalid line audio QA state")
        elif audio_qa.get("status") in {"passed", "flagged", "failed"} and not isinstance(audio_qa.get("record"), dict):
            errors.append(f"{llabel}: audio QA disposition requires a record")
        if isinstance(audio_qa, dict) and audio_qa.get("status") != "not_started" and result_status != "succeeded":
            errors.append(f"{llabel}: audio QA cannot begin before provider success")

    if batch.get("counts") != expected_batch_counts(batch):
        errors.append(f"{label}: stored counts do not match line state")
    if isinstance(spend, dict):
        estimated_batch = round(
            sum(
                line.get("estimated_credits", 0)
                for line in lines
                if isinstance(line, dict)
                and line.get("request", {}).get("status") != "cancelled"
            ),
            3,
        )
        if spend.get("estimated_batch_credits") != estimated_batch:
            errors.append(f"{label}: estimated_batch_credits does not match lines")
        cumulative = spend.get("estimated_cumulative_credits")
        if isinstance(cumulative, (int, float)) and cumulative < estimated_batch:
            errors.append(f"{label}: estimated cumulative spend is below batch estimate")
    if batch.get("manifest_identity_sha256") != batch_identity_sha256(batch):
        errors.append(f"{label}: manifest identity checksum mismatch")


def validate_contract(root: Path = ROOT, store_path: Path | None = None) -> tuple[list[str], LoadedContract]:
    errors: list[str] = []
    resolved_store_path = store_path or (root / STORE_PATH.relative_to(ROOT))
    store = load_json(resolved_store_path)
    if store.get("schema_version") != 2 or store.get("contract") != "irish_phrase_family_authoring_store":
        errors.append("store: invalid schema/contract")

    schema_refs = store.get("schema_documents")
    if not isinstance(schema_refs, list):
        errors.append("store: schema_documents must be a list")
        schema_refs = []
    for schema_ref in schema_refs:
        schema_path = resolve_repo_path(root, schema_ref.get("path") if isinstance(schema_ref, dict) else "")
        if schema_path is None or not schema_path.is_file():
            errors.append("store: schema document is missing")
            continue
        schema = load_json(schema_path)
        if schema.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
            errors.append(f"store: {schema_ref.get('path')} is not a draft-2020-12 schema")

    atlas = load_json(root / ATLAS_PATH.relative_to(ROOT))
    placements = atlas_placements(atlas)
    inventory_errors: list[str] = []
    inventory = inventory_index(
        load_json(root / INVENTORY_PATH.relative_to(ROOT)), root, inventory_errors
    )
    errors.extend(inventory_errors)
    voice_profiles = load_voice_profiles(root, errors)
    generation_lock = store.get("irish_generation_lock")
    required_profile_id = (
        generation_lock.get("required_voice_profile_id")
        if isinstance(generation_lock, dict)
        else None
    )
    if not isinstance(generation_lock, dict):
        errors.append("store: Irish generation lock is required")
    else:
        if generation_lock.get("status") != "user_locked":
            errors.append("store: Irish generation configuration must remain user_locked")
        if generation_lock.get("alternative_voice_or_model_bakeoff_allowed") is not False:
            errors.append("store: alternate Irish voice/model bakeoffs must be forbidden")
        if generation_lock.get("v2_v3_migration_allowed") is not False:
            errors.append("store: Irish V2/V3 migration must be forbidden")
        applies_to = generation_lock.get("applies_to")
        if not isinstance(applies_to, list) or set(applies_to) != {"teaching", "story", "dialogue"} or len(applies_to) != 3:
            errors.append("store: Irish generation lock must cover teaching, story, and dialogue")
    if required_profile_id not in voice_profiles:
        errors.append("store: locked Irish voice profile is missing")
    if set(voice_profiles) != {required_profile_id}:
        errors.append("store: unapproved alternate Irish voice/model profile is present")

    capacity = store.get("capacity_policy")
    if not isinstance(capacity, dict):
        errors.append("store: capacity_policy is required")
    else:
        capture_target = capacity.get("capture_inventory_target", {})
        release_target = capacity.get("first_release_target", {})
        capture_min = capture_target.get("minimum_utterances")
        capture_max = capture_target.get("maximum_utterances")
        release_min = release_target.get("minimum_utterances")
        release_max = release_target.get("maximum_utterances")
        if (capture_min, capture_max) != (3000, 5000):
            errors.append("store: capture planning target must remain 3,000–5,000")
        if (release_min, release_max) != (1200, 1500):
            errors.append("store: first-release planning target must remain 1,200–1,500")
        if not isinstance(release_max, int) or not isinstance(capture_max, int) or release_max > capture_max:
            errors.append("store: release target cannot exceed capture target")
        allowed_capacity_statuses = {
            "planning_target_not_industry_standard",
            "d32_emergency_harvest_until_2026-08-11",
        }
        if capacity.get("status") not in allowed_capacity_statuses:
            errors.append("store: capacity target must use a recognized planning or emergency-harvest status")
        if capacity.get("status") == "d32_emergency_harvest_until_2026-08-11":
            emergency = capacity.get("emergency_harvest")
            if not isinstance(emergency, dict) or emergency.get("enabled") is not True:
                errors.append("store: D32 emergency harvest must be explicitly enabled")
            if not isinstance(emergency, dict) or emergency.get("learner_release_allowed_before_review") is not False:
                errors.append("store: D32 emergency harvest must keep learner release blocked before review")
        if capacity.get("irish_priority_order") != IRISH_PRIORITY_ORDER:
            errors.append("store: Irish pre-expiry priority order changed")
        reserves = capacity.get("reserves")
        if not isinstance(reserves, dict) or "bounded minority" not in str(
            reserves.get("speaking_clearly", "")
        ):
            errors.append("store: Speaking Clearly must remain a bounded separate-project reserve")

    family_refs = store.get("family_documents")
    if not isinstance(family_refs, list):
        errors.append("store: family_documents must be a list")
        family_refs = []
    family_ids = [ref.get("family_id") for ref in family_refs if isinstance(ref, dict)]
    if not is_sorted_unique_string_list(family_ids):
        errors.append("store: family documents require sorted unique family_id strings")

    families: list[dict[str, Any]] = []
    members: dict[str, dict[str, Any]] = {}
    for index, family_ref in enumerate(family_refs):
        flabel = f"store.family_documents[{index}]"
        if not isinstance(family_ref, dict):
            errors.append(f"{flabel}: family reference must be an object")
            continue
        path = resolve_repo_path(root, family_ref.get("path"))
        if path is None or not path.is_file():
            errors.append(f"{flabel}: family document is missing")
            continue
        family = load_json(path)
        families.append(family)
        if family.get("schema_version") != 2 or family.get("contract") != "irish_phrase_family":
            errors.append(f"{flabel}: invalid family schema/contract")
        if family.get("id") != family_ref.get("family_id"):
            errors.append(f"{flabel}: outer family id does not match document id")
        county = family.get("county")
        if family.get("status") not in FAMILY_STATES:
            errors.append(f"family:{family.get('id')}: invalid family status")
        claims = family.get("claims")
        if not isinstance(claims, dict):
            errors.append(f"family:{family.get('id')}: claims must be an object")
        else:
            for field in ("linguistic_approval", "historical_authenticity"):
                if not isinstance(claims.get(field), bool):
                    errors.append(f"family:{family.get('id')}: claims.{field} must be boolean")
            if not isinstance(claims.get("note"), str) or not claims["note"].strip():
                errors.append(f"family:{family.get('id')}: claims.note is required")
            if family.get("status") == "representative_contract_example" and any(
                claims.get(field) is not False
                for field in ("linguistic_approval", "historical_authenticity")
            ):
                errors.append(
                    f"family:{family.get('id')}: representative examples cannot claim approval or authenticity"
                )
        if county not in atlas.get("counties", {}):
            errors.append(f"family:{family.get('id')}: unknown county")
        validate_ref(family.get("story_ref"), root, f"family:{family.get('id')}.story_ref", errors)
        target = family.get("target")
        if not isinstance(target, dict) or not all(
            isinstance(target.get(field), str) and target[field].strip()
            for field in ("lexeme_id", "citation_form", "sense_id", "part_of_speech", "english_sense")
        ):
            errors.append(f"family:{family.get('id')}: complete target identity is required")
        atlas_refs = family.get("atlas_placements")
        if not isinstance(atlas_refs, list) or not atlas_refs:
            errors.append(f"family:{family.get('id')}: atlas placements are required")
        else:
            for atlas_ref in atlas_refs:
                placement = placements.get(atlas_ref.get("id")) if isinstance(atlas_ref, dict) else None
                if placement is None:
                    errors.append(f"family:{family.get('id')}: unknown atlas placement")
                    continue
                if placement["county"] != county:
                    errors.append(f"family:{family.get('id')}: placement county mismatch")
                if placement["citation_form"] != (target or {}).get("citation_form"):
                    errors.append(f"family:{family.get('id')}: placement citation mismatch")
                if atlas_ref.get("gloss") != placement["gloss"]:
                    errors.append(f"family:{family.get('id')}: placement gloss mismatch")
        family_members = family.get("members")
        if not isinstance(family_members, list):
            errors.append(f"family:{family.get('id')}: members must be a list")
            continue
        for member in family_members:
            member_id = member.get("id") if isinstance(member, dict) else None
            if isinstance(member_id, str):
                if member_id in members:
                    errors.append(f"store: duplicate member id {member_id!r}")
                else:
                    members[member_id] = member
            validate_member(member, family, root, placements, inventory, errors)

    slug_owners: dict[str, str] = {}
    for member in members.values():
        irish = member.get("irish")
        if not isinstance(irish, dict):
            continue
        slug = irish.get("inventory_slug")
        normalized = irish.get("normalized_text")
        if not isinstance(slug, str) or not isinstance(normalized, str):
            continue
        prior_text = slug_owners.get(slug)
        if prior_text is not None and prior_text != normalized:
            errors.append(
                f"store: member inventory slug {slug!r} collides for distinct texts"
            )
        slug_owners[slug] = normalized

    retired_refs = store.get("retired_inputs")
    if not isinstance(retired_refs, list):
        errors.append("store: retired_inputs must be a list")
        retired_refs = []
    for retired_ref in retired_refs:
        path = resolve_repo_path(root, retired_ref.get("path") if isinstance(retired_ref, dict) else "")
        if path is None or not path.is_file():
            errors.append("store: retired migration input is missing")
            continue
        retired = load_json(path)
        if retired.get("status") != "retired_migration_input_only" or retired.get("generation_allowed") is not False:
            errors.append("store: legacy migration input must explicitly forbid generation")

    provisional = LoadedContract(
        store=store,
        families=families,
        members=members,
        inventory=inventory,
        placements=placements,
        voice_profiles=voice_profiles,
        batches=[],
    )
    batches: list[dict[str, Any]] = []
    batch_refs = store.get("batch_documents")
    if not isinstance(batch_refs, list):
        errors.append("store: batch_documents must be a list")
        batch_refs = []
    batch_ids = [ref.get("batch_id") for ref in batch_refs if isinstance(ref, dict)]
    if not is_sorted_unique_string_list(batch_ids):
        errors.append("store: batch documents require sorted unique batch_id strings")
    for batch_ref in batch_refs:
        path = resolve_repo_path(root, batch_ref.get("path") if isinstance(batch_ref, dict) else "")
        if path is None or not path.is_file():
            errors.append("store: batch manifest is missing")
            continue
        batch = load_json(path)
        batches.append(batch)
        if batch.get("batch_id") != batch_ref.get("batch_id"):
            errors.append("store: outer batch id does not match manifest")
        if path.name != f"{batch_ref.get('batch_id')}.json":
            errors.append("store: batch filename must exactly match batch_id")
        validate_batch(batch, provisional, root, errors)
    provisional.batches = batches
    return errors, provisional


def coverage_report(contract: LoadedContract) -> dict[str, Any]:
    placement_rows = list(contract.placements.values())
    spelling_counties: dict[str, set[str]] = {}
    spelling_glosses: dict[str, set[str]] = {}
    for placement in placement_rows:
        spelling_counties.setdefault(placement["citation_form"], set()).add(placement["county"])
        spelling_glosses.setdefault(placement["citation_form"], set()).add(placement["gloss"])
    covered_ids = {
        placement.get("id")
        for family in contract.families
        for placement in family.get("atlas_placements", [])
    }
    complete_members = [
        member
        for member in contract.members.values()
        if member.get("states", {}).get("authoring", {}).get("status") == "complete"
    ]
    policy = contract.store.get("capacity_policy", {})
    return {
        "scope": "computed coverage; not a release or linguistic-approval claim",
        "atlas": {
            "county_placements": len(placement_rows),
            "orthographic_headwords": len(spelling_counties),
            "orthographic_headwords_in_multiple_counties": sum(
                1 for counties in spelling_counties.values() if len(counties) > 1
            ),
            "orthographic_headwords_with_multiple_glosses": sum(
                1 for glosses in spelling_glosses.values() if len(glosses) > 1
            ),
            "placement_gloss_pairs": len(
                {(row["citation_form"], row["gloss"]) for row in placement_rows}
            ),
        },
        "authoring_store": {
            "family_documents": len(contract.families),
            "members": len(contract.members),
            "complete_members": len(complete_members),
            "unique_spoken_texts": len(
                {
                    member.get("irish", {}).get("normalized_text")
                    for member in complete_members
                }
            ),
            "distinct_senses": len(
                {family.get("target", {}).get("sense_id") for family in contract.families}
            ),
            "atlas_placements_covered": len(covered_ids),
            "counties_covered": sorted({family.get("county") for family in contract.families}),
            "capture_requested_members": sum(
                1
                for member in complete_members
                if member.get("states", {}).get("capture_request", {}).get("status") == "requested"
            ),
            "learner_release_eligible_members": sum(
                1
                for member in complete_members
                if member.get("states", {}).get("learner_release", {}).get("status") == "eligible"
            ),
        },
        "planning_targets": {
            "capture_inventory": policy.get("capture_inventory_target"),
            "first_learner_release_inventory": policy.get("first_release_target"),
        },
    }


def build_batch(
    contract: LoadedContract,
    *,
    batch_id: str,
    member_ids: list[str],
    voice_profile_id: str,
    created_at: str,
    purpose: str,
) -> dict[str, Any]:
    if not isinstance(purpose, str) or not purpose.strip():
        raise ValueError("batch purpose is required")
    required_profile_id = contract.store.get("irish_generation_lock", {}).get(
        "required_voice_profile_id"
    )
    if voice_profile_id != required_profile_id:
        raise ValueError("Irish generation must use the user-locked voice/model profile")
    profile = contract.voice_profiles.get(voice_profile_id)
    if profile is None:
        raise ValueError(f"unknown voice profile {voice_profile_id!r}")
    grouped: dict[str, list[str]] = {}
    for member_id in sorted(set(member_ids)):
        member = contract.members.get(member_id)
        if member is None:
            raise ValueError(f"unknown member {member_id!r}")
        if member.get("states", {}).get("authoring", {}).get("status") != "complete":
            raise ValueError(f"member {member_id!r} is not complete")
        normalized = member["irish"]["normalized_text"]
        grouped.setdefault(normalized, []).append(member_id)
    lines: list[dict[str, Any]] = []
    for normalized, grouped_member_ids in grouped.items():
        digest = text_sha256(normalized)
        line_seed = "\n".join([digest, voice_profile_id, str(profile["revision"])])
        line_id = f"{batch_id}.line.{hashlib.sha256(line_seed.encode('utf-8')).hexdigest()[:16]}"
        slug = canonical_audio_slug(normalized)
        lines.append(
            {
                "line_id": line_id,
                "member_ids": sorted(grouped_member_ids),
                "normalized_text": normalized,
                "text_sha256": digest,
                "inventory_slug": slug,
                "estimated_characters": len(normalized),
                "estimated_credits": round(len(normalized) * CREDITS_PER_CHARACTER, 3),
                "capture_disposition": CAPTURE_DISPOSITION,
                "claim": {
                    "status": "unclaimed",
                    "owner_id": None,
                    "claimed_at": None,
                    "lease_expires_at": None,
                },
                "request": {"status": "planned", "approved_by": None, "approved_at": None},
                "retry": {
                    "attempt_count": 0,
                    "max_attempts": 3,
                    "last_attempt_at": None,
                    "next_retry_at": None,
                },
                "provider_result": {
                    "status": "not_started",
                    "provider_request_id": None,
                    "started_at": None,
                    "completed_at": None,
                    "reported_credits": None,
                    "reported_characters": None,
                },
                "error": None,
                "audio": {
                    "output_path": f"ios/AnTuras/Resources/Audio/{slug}.mp3",
                    "sha256": None,
                    "bytes": None,
                    "duration_seconds": None,
                },
                "audio_qa": {"status": "not_started", "record": None},
            }
        )
    lines.sort(key=lambda line: line["line_id"])
    batch = {
        "schema_version": 1,
        "contract": "irish_generation_batch",
        "batch_id": batch_id,
        "created_at": created_at,
        "purpose": purpose,
        "voice_profile": copy.deepcopy(profile),
        "execution": {
            "state": "draft",
            "provider_calls_allowed": False,
            "approved_by": None,
            "approved_at": None,
        },
        "lines": lines,
    }
    estimated_batch_credits = round(sum(line["estimated_credits"] for line in lines), 3)
    prior_estimated_credits = round(
        sum(
            batch_record.get("spend", {}).get("estimated_batch_credits", 0)
            for batch_record in contract.batches
            if batch_record.get("batch_id") != batch_id
        ),
        3,
    )
    batch["spend"] = {
        "approved_cap": APPROVED_CREDIT_CAP,
        "estimate_basis": ESTIMATE_BASIS,
        "credits_per_character": CREDITS_PER_CHARACTER,
        "estimated_batch_credits": estimated_batch_credits,
        "estimated_cumulative_credits": round(prior_estimated_credits + estimated_batch_credits, 3),
        "actual_batch_credits": None,
        "actual_cumulative_credits": None,
        "usage_before": None,
        "usage_after": None,
    }
    batch["counts"] = expected_batch_counts(batch)
    batch["manifest_identity_sha256"] = batch_identity_sha256(batch)
    return batch


def write_harvest_outputs(
    plan: dict[str, Any],
    *,
    root: Path = ROOT,
    output_dir: str | None = None,
    normalized_output_dir: str | None = None,
    register: bool = False,
) -> list[str]:
    """Write deterministic draft manifests and optional normalized family copies."""
    written: list[str] = []
    output_path: Path | None = None
    store: dict[str, Any] | None = None
    store_path: Path | None = None
    if register:
        canonical_batch_dir = root / "content/audio/authoring/batches"
        output_path = resolve_repo_path(root, output_dir or "")
        if output_path != canonical_batch_dir:
            raise ValueError(
                "--register requires --output-dir content/audio/authoring/batches"
            )
        store_path = root / STORE_PATH.relative_to(ROOT)
        store = load_json(store_path)
        family_refs = {
            ref.get("family_id"): ref.get("path")
            for ref in store.get("family_documents", [])
            if isinstance(ref, dict)
        }
        for document in plan.get("normalized_documents", []):
            family_id = document["family"].get("id")
            if family_refs.get(family_id) != document["path"]:
                raise ValueError(
                    "--register requires every input family to already be registered "
                    f"at its canonical path: {family_id!r}"
                )
    if output_dir is not None:
        output_path = resolve_repo_path(root, output_dir)
        if output_path is None:
            raise ValueError("harvest output directory must be inside the repository")
        output_path.mkdir(parents=True, exist_ok=True)
        prepared_contract = plan.get("contract")
        if isinstance(prepared_contract, LoadedContract):
            for batch in plan.get("batches", []):
                validation_errors: list[str] = []
                validate_batch(batch, prepared_contract, root, validation_errors)
                if validation_errors:
                    raise ValueError(
                        "prepared manifest failed contract validation:\n"
                        + "\n".join(validation_errors)
                    )
        for batch in plan.get("batches", []):
            destination = output_path / f"{batch['batch_id']}.json"
            if destination.exists():
                raise ValueError(f"refusing to overwrite existing manifest: {destination}")
            destination.write_text(
                json.dumps(batch, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
            )
            written.append(str(destination.relative_to(root)))

    if normalized_output_dir is not None:
        normalized_path = resolve_repo_path(root, normalized_output_dir)
        if normalized_path is None:
            raise ValueError("normalized family output directory must be inside the repository")
        normalized_path.mkdir(parents=True, exist_ok=True)
        for document in plan.get("normalized_documents", []):
            source_name = Path(document["path"]).name
            destination = normalized_path / source_name
            if destination.exists():
                raise ValueError(f"refusing to overwrite normalized family: {destination}")
            destination.write_text(
                json.dumps(document["family"], ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            written.append(str(destination.relative_to(root)))

    if register:
        assert store is not None and store_path is not None
        existing_ids = {
            ref.get("batch_id") for ref in store.get("batch_documents", []) if isinstance(ref, dict)
        }
        new_refs: list[dict[str, str]] = []
        for batch in plan.get("batches", []):
            if batch["batch_id"] in existing_ids:
                raise ValueError(f"refusing to replace registered batch: {batch['batch_id']}")
            new_refs.append(
                {
                    "batch_id": batch["batch_id"],
                    "path": f"content/audio/authoring/batches/{batch['batch_id']}.json",
                }
            )
        store["batch_documents"] = sorted(
            [ref for ref in store.get("batch_documents", []) if isinstance(ref, dict)] + new_refs,
            key=lambda ref: ref.get("batch_id", ""),
        )
        store_path.write_text(
            json.dumps(store, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        written.append(str(store_path.relative_to(root)))
    return written


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("check", help="validate the canonical store and registered batches")
    subparsers.add_parser("report", help="print separate atlas/authoring/release coverage")
    reconcile = subparsers.add_parser(
        "reconcile",
        help="read-only reconciliation across authoring, batches, inventory, bundle, and archives",
    )
    reconcile.add_argument(
        "--at",
        help="deterministic ISO timestamp with timezone for lease checks",
    )
    reconcile.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    reconcile.add_argument(
        "--scoreboard",
        action="store_true",
        help="emit only the compact live production-loop scoreboard",
    )
    resume = subparsers.add_parser(
        "resume-plan",
        help="print a non-destructive recovery/resume plan for registered batch lines",
    )
    resume.add_argument("--batch-id", help="limit the plan to one registered batch")
    resume.add_argument(
        "--at",
        help="deterministic ISO timestamp with timezone for lease checks",
    )
    resume.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    build = subparsers.add_parser("build-batch", help="write a deterministic draft batch manifest")
    build.add_argument("--batch-id", required=True)
    build.add_argument("--member-id", action="append", required=True)
    build.add_argument("--voice-profile-id", required=True)
    build.add_argument("--created-at", required=True, help="explicit ISO timestamp; never inferred")
    build.add_argument("--purpose", required=True, help="documented learning/capture purpose")
    build.add_argument("--output", required=True)
    prepare = subparsers.add_parser(
        "prepare-harvest",
        help="normalize Track A families and prepare resumable D32 draft batches",
    )
    prepare.add_argument(
        "--input",
        action="append",
        required=True,
        help="Track A .v2.json family file or directory; repeat for multiple inputs",
    )
    prepare.add_argument("--created-at", required=True, help="explicit ISO timestamp; never inferred")
    prepare.add_argument(
        "--output-dir",
        help="write new provider-blocked manifests to this repository directory",
    )
    prepare.add_argument(
        "--normalized-output-dir",
        help="write NFC-normalized family copies to this repository directory",
    )
    prepare.add_argument(
        "--register",
        action="store_true",
        help="register written manifests in the sorted canonical store batch_documents list",
    )
    emergency = subparsers.add_parser(
        "emergency-harvest",
        help="ingest a Track A tranche, approve D32 capture, claim lines, and register manifests",
    )
    emergency.add_argument(
        "--input",
        action="append",
        required=True,
        help="Track A .v2.json family file or directory; repeat for multiple inputs",
    )
    emergency.add_argument("--created-at", required=True, help="explicit ISO timestamp")
    emergency.add_argument("--approved-by", required=True, help="explicit D32 approval identity")
    emergency.add_argument("--approved-at", required=True, help="explicit D32 approval timestamp")
    emergency.add_argument("--requested-by", required=True, help="capture-request author identity")
    emergency.add_argument("--claim-owner", required=True, help="deterministic Track C claim owner")
    emergency.add_argument("--claimed-at", required=True, help="claim timestamp")
    emergency.add_argument("--lease-expires-at", required=True, help="claim lease expiry timestamp")
    emergency.add_argument(
        "--max-lines-per-batch",
        type=int,
        default=100,
        help="maximum unique normalized text/voice lines per county/story manifest",
    )
    emergency.add_argument(
        "--batch-prefix",
        default="d32.harvest",
        help="stable dotted prefix for generated batch ids",
    )
    args = parser.parse_args(argv)

    if args.command in {"reconcile", "resume-plan"}:
        from structured_audio_reconciliation import (
            build_resume_plan,
            parse_timestamp,
            reconcile as reconcile_contract,
        )

        as_of = parse_timestamp(args.at) if args.at else None
        if args.at and as_of is None:
            parser.error("--at must be an ISO timestamp with a timezone")
        report = reconcile_contract(ROOT, as_of=as_of)
        if args.command == "resume-plan":
            print(
                json.dumps(
                    build_resume_plan(report, batch_id=args.batch_id),
                    ensure_ascii=False,
                    indent=2,
                )
            )
        else:
            payload = report["scoreboard"] if args.scoreboard else report
            print(json.dumps(payload, ensure_ascii=False, indent=2, default=str))
        return 0

    errors, contract = validate_contract()
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    if args.command == "check":
        print("valid content/audio/authoring/phrase-family-store-v2.json")
        return 0
    if args.command == "report":
        print(json.dumps(coverage_report(contract), ensure_ascii=False, indent=2))
        return 0
    if args.command == "prepare-harvest":
        try:
            documents = collect_family_documents(ROOT, args.input)
            plan = prepare_harvest(
                contract,
                documents,
                root=ROOT,
                created_at=args.created_at,
            )
        except (OSError, ValueError) as exc:
            print(str(exc), file=sys.stderr)
            return 1
        if plan["errors"]:
            print("\n".join(plan["errors"]), file=sys.stderr)
            return 1
        if args.register and not args.output_dir:
            print("--register requires --output-dir", file=sys.stderr)
            return 1
        if args.output_dir or args.normalized_output_dir or args.register:
            try:
                written = write_harvest_outputs(
                    plan,
                    root=ROOT,
                    output_dir=args.output_dir,
                    normalized_output_dir=args.normalized_output_dir,
                    register=args.register,
                )
            except (OSError, ValueError) as exc:
                print(str(exc), file=sys.stderr)
                return 1
            plan["written"] = written
        report = harvest_report(plan)
        if plan.get("written"):
            report["written"] = plan["written"]
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 0
    if args.command == "emergency-harvest":
        try:
            documents = collect_family_documents(ROOT, args.input)
            plan = prepare_harvest(
                contract,
                documents,
                root=ROOT,
                created_at=args.created_at,
            )
            if plan["errors"]:
                print("\n".join(plan["errors"]), file=sys.stderr)
                return 1
            plan["batches"] = build_emergency_batches(
                plan,
                created_at=args.created_at,
                batch_prefix=args.batch_prefix,
                max_lines_per_batch=args.max_lines_per_batch,
            )
            approve_emergency_harvest(
                plan,
                approved_by=args.approved_by,
                approved_at=args.approved_at,
                requested_by=args.requested_by,
                claim_owner=args.claim_owner,
                claimed_at=args.claimed_at,
                lease_expires_at=args.lease_expires_at,
            )
            written = write_emergency_harvest(plan, root=ROOT)
            final_errors, _ = validate_contract()
            if final_errors:
                print("\n".join(final_errors), file=sys.stderr)
                return 1
        except (OSError, ValueError) as exc:
            print(str(exc), file=sys.stderr)
            return 1
        report = harvest_report(plan)
        report.update(
            {
                "emergency_approved": True,
                "provider_calls_allowed": True,
                "claim_owner": args.claim_owner,
                "lease_expires_at": args.lease_expires_at,
                "written": written,
            }
        )
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 0
    batch = build_batch(
        contract,
        batch_id=args.batch_id,
        member_ids=args.member_id,
        voice_profile_id=args.voice_profile_id,
        created_at=args.created_at,
        purpose=args.purpose,
    )
    output = resolve_repo_path(ROOT, args.output)
    batch_directory = ROOT / "content/audio/authoring/batches"
    if output is None or output.parent != batch_directory or output.suffix != ".json":
        print("output must be a JSON file directly inside content/audio/authoring/batches", file=sys.stderr)
        return 1
    if output.stem != args.batch_id:
        print("output filename must exactly match batch_id", file=sys.stderr)
        return 1
    if output.exists():
        print("refusing to overwrite an existing batch manifest", file=sys.stderr)
        return 1
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(batch, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {output.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
