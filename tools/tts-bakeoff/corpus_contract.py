#!/usr/bin/env python3
"""Offline contract checks for resumable Irish audio batches.

This module deliberately has no provider, network, credential, or audio-generation
dependency.  It turns phrase-family drafts into deterministic batch candidates and
reports the metadata that must be authored before a provider call is permitted.
"""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

VOICE_ID = "NPWroowF4phQhaPWjXPj"
VOICE_NAME = "Irish Cultural Guide"
MODEL_ID = "eleven_v3"
LANGUAGE_CODE = "ga"
OUTPUT_FORMAT = "mp3_44100_192"
CAPTURE_DISPOSITION = "generated_unreviewed"
REPO_ROOT = Path(__file__).resolve().parents[2]

_FADA_SLUG = {"á": "aa", "é": "ee", "í": "ii", "ó": "oo", "ú": "uu"}


@dataclass(frozen=True)
class ContractIssue:
    code: str
    item_id: str
    detail: str

    def as_dict(self) -> dict[str, str]:
        return {"code": self.code, "item_id": self.item_id, "detail": self.detail}


def slug(text: str) -> str:
    """Match the production catalog's deterministic filename rule."""
    chars: list[str] = []
    for char in text.lower():
        if char in _FADA_SLUG:
            chars.append(_FADA_SLUG[char])
        elif char.isascii() and char.isalpha():
            chars.append(char)
        else:
            chars.append(" ")
    return "-".join("".join(chars).split())


def resumable_id(county: str, family_id: str, member_id: str) -> str:
    return f"{county}/{family_id}/{member_id}"


def load_family_files(county: str) -> list[tuple[Path, dict[str, Any]]]:
    folder = REPO_ROOT / "content" / county / "phrase-families"
    return [
        (path, json.loads(path.read_text()))
        for path in sorted(folder.glob("*.v1.json"))
    ]


def collect_items(county: str) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    for path, family in load_family_files(county):
        family_id = str(family.get("id", ""))
        for member in family.get("members", []):
            member_id = str(member.get("id", ""))
            text = member.get("text")
            if not isinstance(text, str):
                text = ""
            items.append(
                {
                    "county": county,
                    "family_id": family_id,
                    "family_file": str(path.relative_to(REPO_ROOT)),
                    "member_id": member_id,
                    "item_id": resumable_id(county, family_id, member_id),
                    "text": text.strip(),
                    "qa_state": member.get("qa_state"),
                    "member": member,
                    "family": family,
                }
            )
    return sorted(items, key=lambda item: item["item_id"])


def validate_item(item: dict[str, Any]) -> list[ContractIssue]:
    member = item["member"]
    item_id = item["item_id"]
    issues: list[ContractIssue] = []

    if not item["text"]:
        issues.append(ContractIssue("missing_text", item_id, "text must be non-empty"))

    provenance = member.get("provenance")
    if not isinstance(provenance, dict):
        issues.append(
            ContractIssue(
                "missing_provenance",
                item_id,
                "requires provenance.kind and provenance.refs",
            )
        )
    else:
        if not isinstance(provenance.get("kind"), str) or not provenance["kind"].strip():
            issues.append(ContractIssue("invalid_provenance", item_id, "kind is required"))
        if not isinstance(provenance.get("refs"), list) or not all(
            isinstance(ref, str) and ref.strip() for ref in provenance["refs"]
        ):
            issues.append(
                ContractIssue("invalid_provenance", item_id, "refs must be non-empty strings")
            )

    if member.get("county") != item["county"]:
        issues.append(
            ContractIssue(
                "missing_or_mismatched_county",
                item_id,
                f"item county must be {item['county']!r}",
            )
        )

    if not isinstance(member.get("sense"), str) or not member["sense"].strip():
        issues.append(ContractIssue("missing_sense", item_id, "sense must be explicit"))

    exercise = member.get("exercise")
    if not isinstance(exercise, dict) or not isinstance(exercise.get("ids"), list) or not exercise[
        "ids"
    ]:
        issues.append(
            ContractIssue(
                "missing_exercise_metadata",
                item_id,
                "requires exercise.ids with at least one consuming exercise",
            )
        )

    if member.get("capture_disposition") != CAPTURE_DISPOSITION:
        issues.append(
            ContractIssue(
                "missing_capture_disposition",
                item_id,
                f"capture_disposition must be {CAPTURE_DISPOSITION!r}",
            )
        )

    return issues


def validate_items(items: list[dict[str, Any]]) -> list[ContractIssue]:
    issues: list[ContractIssue] = []
    for item in items:
        issues.extend(validate_item(item))
    return issues


def build_batch(county: str, *, only_pending: bool = True, credits_per_character: float = 1.0) -> dict[str, Any]:
    items = collect_items(county)
    if only_pending:
        items = [item for item in items if item["qa_state"] == "pending_generation"]

    issues = validate_items(items)
    issues_by_item: dict[str, list[str]] = {}
    for issue in issues:
        issues_by_item.setdefault(issue.item_id, []).append(issue.code)

    entries: list[dict[str, Any]] = []
    cumulative = 0.0
    for item in items:
        characters = len(item["text"])
        estimate = round(characters * credits_per_character, 3)
        cumulative = round(cumulative + estimate, 3)
        entries.append(
            {
                "resumable_id": item["item_id"],
                "family_file": item["family_file"],
                "text_sha256": hashlib.sha256(item["text"].encode("utf-8")).hexdigest(),
                "text": item["text"],
                "slug": slug(item["text"]),
                "output": f"ios/AnTuras/Resources/Audio/{slug(item['text'])}.mp3",
                "estimated_characters": characters,
                "estimated_credits": estimate,
                "estimated_cumulative_credits": cumulative,
                "contract_status": "blocked" if issues_by_item.get(item["item_id"]) else "eligible",
                "contract_issues": issues_by_item.get(item["item_id"], []),
                "capture_disposition": CAPTURE_DISPOSITION,
                "output_validation": {
                    "required": True,
                    "sha256": None,
                    "reported_credits": None,
                },
            }
        )

    return {
        "schema_version": 1,
        "batch_id": f"{county}-phrase-family-pending-v1",
        "provider": "ElevenLabs",
        "voice": {"name": VOICE_NAME, "id": VOICE_ID},
        "model_id": MODEL_ID,
        "language_code": LANGUAGE_CODE,
        "output_format": OUTPUT_FORMAT,
        "estimate_basis": "estimated_credits = UTF-8 character count × credits_per_character",
        "credits_per_character": credits_per_character,
        "approved_cap": 25000,
        "estimated_batch_credits": cumulative,
        "estimated_cumulative_credits": cumulative,
        "contract_status": "blocked" if issues else "eligible",
        "items": entries,
        "issues": [issue.as_dict() for issue in issues],
    }

