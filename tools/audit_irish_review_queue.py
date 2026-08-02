#!/usr/bin/env python3
"""Run the mechanical part of the D32 Irish high-risk review.

This audit is deliberately conservative. It reports source, identity, bind-rule,
translation-consistency, mutation-trigger, and batch-state risks. It does not judge
Irish grammar, dialect, pronunciation, pedagogy, history, or audio quality, and it
never changes a review or release state.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import unicodedata
from collections import defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[1]
INVENTORY_PATH = Path("content/audio/irish-inventory-v1.json")
LAUNCH_PATH = Path("content/audio/launch-phrases-conversations-v1.json")
SPOT_LISTEN_PATH = Path("content/audio/SPOT-LISTEN-2026-07-31.md")
BATCHES_PATH = Path("content/audio/authoring/batches")
LEGACY_FAMILIES_PATH = Path("content/mayo/phrase-families")
V2_FAMILIES_GLOB = "content/*/phrase-families/authoring-v2/*.v2.json"

LOCKED_VOICE = {
    "provider": "ElevenLabs",
    "voice_id": "NPWroowF4phQhaPWjXPj",
    "model_id": "eleven_v3",
    "language_code": "ga",
    "output_format": "mp3_44100_192",
    "voice_settings": {"mode": "provider_defaults", "overrides": {}},
}

MUTATION_TRIGGER_RE = re.compile(
    r"\b(?:an|ar an|sa|chuig an|go dtí an|don|leis an|ón)\s+"
    r"([A-Za-zÁÉÍÓÚáéíóú]+)"
)

NAMED_ENTITY_PATTERNS = (
    "Gráinne",
    "Maigh Eo",
    "Londain",
    "Gleann Dá Loch",
    "Baile Átha Cliath",
    "Áth Troim",
    "Sihtric",
    "Colmán",
    "Flann",
    "Umhaill",
    "Cuan Mó",
)

PRONOUN_RE = re.compile(
    r"\b(?:mé|tú|sé|sí|é|í|duit|ort|uait|dom|agam|agat|ann|di|linn)\b",
    re.IGNORECASE,
)

ENGLISH_ACTIONS = {
    "ask",
    "buy",
    "come",
    "do",
    "give",
    "go",
    "learn",
    "live",
    "look",
    "make",
    "pray",
    "read",
    "sell",
    "stand",
    "take",
}
ENGLISH_ACTION_RE = re.compile(
    r"\b(?:ask|buy|came|come|do|give|go|learn|live|look|make|pray|read|sell|stand|take|went)\b",
    re.IGNORECASE,
)
ENGLISH_QUESTION_RE = re.compile(
    r"^(?:what|where|who|which|are|do|does|is|can|have|has)\b|\?$",
    re.IGNORECASE,
)
ENGLISH_COMMAND_RE = re.compile(
    r"^(?:ask|buy|come|do|give|go|learn|live|look|make|pray|read|sell|stand|take)\b",
    re.IGNORECASE,
)
ENGLISH_LOCATION_RE = re.compile(
    r"\b(?:here|there|at|in|on|to|from|into|back|house|town|settlement|city|river|market|sea|bay|castle|road)\b",
    re.IGNORECASE,
)

CAPTURE_BLOCKED = "capture_blocked"
REVIEW_BEFORE_RELEASE = "review_before_release"
OPERATIONAL_WATCH = "operational_watch"
FINDING_GATES = frozenset(
    {CAPTURE_BLOCKED, REVIEW_BEFORE_RELEASE, OPERATIONAL_WATCH}
)


@dataclass(frozen=True)
class Finding:
    finding_id: str
    priority: str
    gate: str
    category: str
    record_id: str
    text: str
    message: str
    evidence: tuple[str, ...]
    disposition: str


def normalize_text(text: Any) -> str:
    """Return the inventory identity form without making linguistic changes."""

    if not isinstance(text, str):
        return ""
    return " ".join(unicodedata.normalize("NFC", text).strip().split())


def canonical_audio_slug(text: str) -> str:
    """Match the frozen audio slug convention used by the authoring contract."""

    fadas = {"á": "aa", "é": "ee", "í": "ii", "ó": "oo", "ú": "uu"}
    pieces: list[str] = []
    for char in normalize_text(text).lower():
        if char in fadas:
            pieces.append(fadas[char])
        elif char.isascii() and char.isalpha():
            pieces.append(char)
        else:
            pieces.append(" ")
    return "-".join("".join(pieces).split())


def text_sha256(text: str) -> str:
    return hashlib.sha256(normalize_text(text).encode("utf-8")).hexdigest()


def relative(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def load_json(root: Path, path: Path) -> Any:
    return json.loads((root / path).read_text(encoding="utf-8"))


def text_risk_flags(text: str) -> list[str]:
    """Return review prompts, not linguistic verdicts."""

    flags: list[str] = []
    if any(char in text for char in "áéíóúÁÉÍÓÚ"):
        flags.append("fada_or_diacritic")
    if MUTATION_TRIGGER_RE.search(text):
        flags.append("mutation_trigger")
    if any(pattern in text for pattern in NAMED_ENTITY_PATTERNS):
        flags.append("personal_or_place_name")
    if PRONOUN_RE.search(text):
        flags.append("pronoun_or_reference")
    if len(text) >= 48 or ";" in text or " agus " in text:
        flags.append("long_or_coordinated_line")
    if text.startswith("Cárb"):
        flags.append("dialect_or_contraction")
    return flags


def english_intent_signature(intent: str) -> tuple[str, frozenset[str], bool]:
    """Reduce English only to coarse, mechanically visible conflict markers."""

    normalized = " ".join(intent.strip().split())
    if ENGLISH_QUESTION_RE.search(normalized):
        mode = "question"
    elif ENGLISH_COMMAND_RE.search(normalized):
        mode = "command"
    else:
        mode = "statement"

    actions: set[str] = set()
    for match in ENGLISH_ACTION_RE.finditer(normalized):
        word = match.group(0).lower()
        actions.add({"came": "come", "went": "go"}.get(word, word))
    return mode, frozenset(actions & ENGLISH_ACTIONS), bool(ENGLISH_LOCATION_RE.search(normalized))


def has_mechanical_intent_conflict(intents: set[str]) -> bool:
    """Detect only coarse conflicts; paraphrase alone is not a hard finding."""

    signatures = [english_intent_signature(intent) for intent in intents]
    modes = {signature[0] for signature in signatures}
    actions = {signature[1] for signature in signatures}
    locations = {signature[2] for signature in signatures}
    return len(modes) > 1 or len(actions) > 1 or len(locations) > 1


def intent_conflict_gate(intents: set[str]) -> str:
    """Classify a coarse English conflict without judging the Irish line."""

    signatures = [english_intent_signature(intent) for intent in intents]
    modes = {signature[0] for signature in signatures}
    actions = {signature[1] for signature in signatures}
    if len(modes) > 1 or len(actions) > 1:
        return CAPTURE_BLOCKED
    return REVIEW_BEFORE_RELEASE


def finding(
    finding_id: str,
    priority: str,
    category: str,
    record_id: str,
    text: str,
    message: str,
    evidence: Iterable[str],
    disposition: str,
    gate: str = REVIEW_BEFORE_RELEASE,
) -> Finding:
    if gate not in FINDING_GATES:
        raise ValueError(f"Unknown finding gate: {gate}")
    return Finding(
        finding_id=finding_id,
        priority=priority,
        gate=gate,
        category=category,
        record_id=record_id,
        text=text,
        message=message,
        evidence=tuple(evidence),
        disposition=disposition,
    )


def identity_findings(
    *,
    finding_prefix: str,
    record_id: str,
    text: str,
    declared_normalized_text: Any,
    declared_slug: Any,
    declared_sha256: Any,
    source_label: str,
    evidence: Iterable[str],
) -> list[Finding]:
    """Check stable text identity fields without changing the spoken text."""

    refs = tuple(evidence)
    findings: list[Finding] = []
    if not text:
        findings.append(
            finding(
                f"{finding_prefix}.empty-text",
                "P0",
                "schema_identity",
                record_id,
                "",
                f"{source_label} has no non-empty normalized spoken text.",
                refs,
                "Hold: complete the canonical text identity before capture.",
                gate=CAPTURE_BLOCKED,
            )
        )
        return findings

    expected_slug = canonical_audio_slug(text)
    expected_sha256 = text_sha256(text)
    if declared_normalized_text != text:
        findings.append(
            finding(
                f"{finding_prefix}.normalized-text",
                "P0",
                "schema_identity",
                record_id,
                text,
                f"{source_label} normalized_text does not match the canonical NFC/whitespace form.",
                refs,
                "Hold: reconcile the exact normalized text before capture; do not silently rewrite Irish.",
                gate=CAPTURE_BLOCKED,
            )
        )
    if declared_slug != expected_slug:
        findings.append(
            finding(
                f"{finding_prefix}.slug",
                "P0",
                "schema_identity",
                record_id,
                text,
                f"{source_label} inventory_slug {declared_slug!r} does not match the canonical slug {expected_slug!r}.",
                refs,
                "Hold: correct identity metadata before capture; do not infer a clip from a slug.",
                gate=CAPTURE_BLOCKED,
            )
        )
    if declared_sha256 != expected_sha256:
        findings.append(
            finding(
                f"{finding_prefix}.text-sha256",
                "P0",
                "schema_identity",
                record_id,
                text,
                f"{source_label} text_sha256 does not match the canonical normalized spoken text.",
                refs,
                "Hold: recompute identity metadata from the exact text before capture.",
                gate=CAPTURE_BLOCKED,
            )
        )
    return findings


def load_inventory(root: Path) -> tuple[list[dict[str, Any]], dict[str, dict[str, Any]], list[Finding]]:
    payload = load_json(root, INVENTORY_PATH)
    entries = payload.get("entries", [])
    by_text: dict[str, dict[str, Any]] = {}
    by_slug: dict[str, str] = {}
    findings: list[Finding] = []

    for index, entry in enumerate(entries):
        text = entry.get("text") if isinstance(entry, dict) else None
        record_id = f"inventory.entry.{index + 1:03d}"
        if not isinstance(text, str) or not text.strip():
            findings.append(
                finding(
                    f"inventory.invalid-text.{index + 1:03d}",
                    "P0",
                    "inventory_identity",
                    record_id,
                    "",
                    "Inventory entry has no non-empty spoken text.",
                    [relative(root / INVENTORY_PATH, root)],
                    "Hold: repair the inventory record before capture or release.",
                    gate=CAPTURE_BLOCKED,
                )
            )
            continue

        normalized = normalize_text(text)
        slug = entry.get("slug")
        expected_slug = canonical_audio_slug(normalized)
        if normalized in by_text:
            findings.append(
                finding(
                    f"inventory.duplicate-text.{expected_slug}",
                    "P0",
                    "inventory_identity",
                    record_id,
                    normalized,
                    "Duplicate normalized spoken text appears in the inventory.",
                    [
                        relative(root / INVENTORY_PATH, root),
                        f"prior inventory entry: {by_text[normalized].get('slug')}",
                    ],
                    "Hold: deduplicate by normalized text before batching.",
                    gate=CAPTURE_BLOCKED,
                )
            )
        else:
            by_text[normalized] = entry

        if slug != expected_slug:
            findings.append(
                finding(
                    f"inventory.slug-mismatch.{expected_slug}",
                    "P0",
                    "inventory_identity",
                    record_id,
                    normalized,
                    f"Inventory slug {slug!r} does not match the canonical slug {expected_slug!r}.",
                    [relative(root / INVENTORY_PATH, root)],
                    "Hold: correct identity metadata; do not regenerate from a mismatched slug.",
                    gate=CAPTURE_BLOCKED,
                )
            )

        prior_text = by_slug.get(expected_slug)
        if prior_text is not None and prior_text != normalized:
            findings.append(
                finding(
                    f"inventory.slug-collision.{expected_slug}",
                    "P0",
                    "inventory_identity",
                    record_id,
                    normalized,
                    f"Canonical slug {expected_slug!r} is shared by distinct normalized texts.",
                    [relative(root / INVENTORY_PATH, root)],
                    "Hold: resolve the slug collision before capture.",
                    gate=CAPTURE_BLOCKED,
                )
            )
        by_slug[expected_slug] = normalized

    return entries, by_text, findings


def launch_rows(root: Path) -> list[dict[str, Any]]:
    payload = load_json(root, LAUNCH_PATH)
    rows: list[dict[str, Any]] = []
    for county, county_record in sorted(payload.get("counties", {}).items()):
        for kind in ("phrases", "conversation"):
            for index, line in enumerate(county_record.get(kind, []), start=1):
                text = normalize_text(line.get("text", ""))
                rows.append(
                    {
                        "id": f"launch.{county}.{kind}.{index:02d}",
                        "county": county,
                        "kind": kind,
                        "text": text,
                        "english": line.get("gloss", ""),
                        "path": relative(root / LAUNCH_PATH, root),
                    }
                )
    return rows


def pack_audio_rows(root: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for path in sorted((root / "content").glob("*/*.pack.draft.json")):
        payload = json.loads(path.read_text(encoding="utf-8"))
        pack = payload.get("pack", {})
        for chapter in pack.get("chapters", []):
            for page in chapter.get("pages", []):
                exercise = page.get("exercise") or {}
                text = exercise.get("audioText")
                if not isinstance(text, str) or not text.strip():
                    continue
                rows.append(
                    {
                        "id": f"pack.{page.get('id')}.exercise",
                        "text": normalize_text(text),
                        "english": exercise.get("translation") or "",
                        "family": exercise.get("family"),
                        "path": relative(path, root),
                        "page_id": page.get("id"),
                    }
                )
    return rows


def legacy_member_rows(root: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for path in sorted((root / LEGACY_FAMILIES_PATH).glob("*.v1.json")):
        payload = json.loads(path.read_text(encoding="utf-8"))
        for member in payload.get("members", []):
            rows.append(
                {
                    "id": f"legacy.{member.get('id')}",
                    "member_id": member.get("id"),
                    "text": normalize_text(member.get("text", "")),
                    "english": member.get("gloss", ""),
                    "invented": member.get("invented"),
                    "qa_state": member.get("qa_state"),
                    "path": relative(path, root),
                    "attested_in": member.get("attested_in", []),
                }
            )
    return rows


def v2_member_rows(root: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for path in sorted(root.glob(V2_FAMILIES_GLOB)):
        payload = json.loads(path.read_text(encoding="utf-8"))
        for member in payload.get("members", []):
            irish = member.get("irish") or {}
            english = member.get("english") or {}
            states = member.get("states") or {}
            rows.append(
                {
                    "id": f"v2.{member.get('id')}",
                    "member_id": member.get("id"),
                    "text": normalize_text(irish.get("text", "")),
                    "normalized_text": irish.get("normalized_text"),
                    "inventory_slug": irish.get("inventory_slug"),
                    "text_sha256": irish.get("text_sha256"),
                    "english": english.get("intent", ""),
                    "invented": (member.get("provenance") or {}).get("invented"),
                    "audio_qa": (states.get("audio_qa") or {}).get("status"),
                    "release": (states.get("learner_release") or {}).get("status"),
                    "risk_flags": member.get("risk_flags", []),
                    "path": relative(path, root),
                }
            )
    return rows


def batch_rows(root: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for path in sorted((root / BATCHES_PATH).glob("*.json")):
        payload = json.loads(path.read_text(encoding="utf-8"))
        for line in payload.get("lines", []):
            rows.append(
                {
                    "id": f"batch.{line.get('line_id')}",
                    "batch_id": payload.get("batch_id"),
                    "line_id": line.get("line_id"),
                    "text": normalize_text(line.get("normalized_text", "")),
                    "normalized_text": line.get("normalized_text"),
                    "member_ids": line.get("member_ids", []),
                    "inventory_slug": line.get("inventory_slug"),
                    "text_sha256": line.get("text_sha256"),
                    "request": line.get("request", {}),
                    "claim": line.get("claim", {}),
                    "provider_result": line.get("provider_result", {}),
                    "audio_qa": line.get("audio_qa", {}),
                    "execution": payload.get("execution", {}),
                    "voice_profile": payload.get("voice_profile", {}),
                    "path": relative(path, root),
                }
            )
    return rows


def source_rows(
    launch: list[dict[str, Any]],
    packs: list[dict[str, Any]],
    legacy: list[dict[str, Any]],
    v2: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    return [*launch, *packs, *legacy, *v2]


def audit_sources(root: Path = ROOT) -> dict[str, Any]:
    inventory_entries, inventory, findings = load_inventory(root)
    launch = launch_rows(root)
    packs = pack_audio_rows(root)
    legacy = legacy_member_rows(root)
    v2 = v2_member_rows(root)
    batches = batch_rows(root)

    for row in v2:
        findings.extend(
            identity_findings(
                finding_prefix=row["id"],
                record_id=row["id"],
                text=row["text"],
                declared_normalized_text=row.get("normalized_text"),
                declared_slug=row.get("inventory_slug"),
                declared_sha256=row.get("text_sha256"),
                source_label="v2 member",
                evidence=[row["path"], row.get("member_id") or row["id"]],
            )
        )

    for row in batches:
        findings.extend(
            identity_findings(
                finding_prefix=row["id"],
                record_id=row["id"],
                text=row["text"],
                declared_normalized_text=row.get("normalized_text"),
                declared_slug=row.get("inventory_slug"),
                declared_sha256=row.get("text_sha256"),
                source_label="generation-batch line",
                evidence=[row["path"], row.get("line_id") or row["id"]],
            )
        )

    for row in launch:
        entry = inventory.get(row["text"])
        if entry is None:
            findings.append(
                finding(
                    f"{row['id']}.missing-inventory",
                    "P0",
                    "bind_rule",
                    row["id"],
                    row["text"],
                    "Launch-bank line has no matching runtime inventory entry or clip record.",
                    [row["path"]],
                    "Hold: do not bind or capture until a complete v2 member and registered batch exist.",
                    gate=CAPTURE_BLOCKED,
                )
            )
        elif entry.get("qa_state") == "spot_flagged":
            findings.append(
                finding(
                    f"{row['id']}.spot-flagged",
                    "P1",
                    "audio_spot_listen",
                    row["id"],
                    row["text"],
                    "Launch-bank line points to an inventory clip already marked spot_flagged.",
                    [row["path"], f"inventory:{entry.get('slug')}"],
                    "Keep capture/release state pending; native-speaker audio QA remains required.",
                )
            )

        flags = text_risk_flags(row["text"])
        if flags:
            findings.append(
                finding(
                    f"{row['id']}.text-risk",
                    "P1",
                    "text_risk_prompt",
                    row["id"],
                    row["text"],
                    "Mechanical review prompts: " + ", ".join(flags) + ".",
                    [row["path"]],
                    "Route to the appropriate Irish-language/editorial reviewer; this audit makes no correction.",
                )
            )

    for row in packs:
        flags = text_risk_flags(row["text"])
        if flags:
            findings.append(
                finding(
                    f"{row['id']}.text-risk",
                    "P1",
                    "text_risk_prompt",
                    row["id"],
                    row["text"],
                    "Pack audio line has mechanical review prompts: " + ", ".join(flags) + ".",
                    [row["path"], row["page_id"]],
                    "Keep the pack review gate open; do not treat pack validation as Irish-language approval.",
                )
            )

    # Compare only exact spoken-text matches. Different English intents for one
    # spoken line are a concrete source inconsistency, not a grammar verdict.
    english_by_text: dict[str, list[tuple[str, str, str]]] = defaultdict(list)
    for row in source_rows(launch, packs, legacy, v2):
        english = row.get("english")
        if isinstance(english, str) and english.strip() and row.get("text"):
            english_by_text[row["text"]].append(
                (row["id"], english.strip(), row.get("path", ""))
            )
    for text, rows in sorted(english_by_text.items()):
        intents = {english for _, english, _ in rows}
        if len(intents) < 2 or not has_mechanical_intent_conflict(intents):
            continue
        ids = [record_id for record_id, _, _ in rows]
        findings.append(
            finding(
                f"semantic-conflict.{canonical_audio_slug(text)}",
                "P0",
                "semantic_ambiguity",
                ids[0],
                text,
                "Exact spoken text carries more than one English intent across repository records: "
                + " | ".join(sorted(intents)),
                ids,
                "Hold: reconcile the intended meaning and learner role; do not silently rewrite Irish or English.",
                gate=intent_conflict_gate(intents),
            )
        )

    pending_legacy = [
        row for row in legacy if row.get("qa_state") == "pending_generation"
    ]
    if pending_legacy:
        ids = [row["member_id"] for row in pending_legacy]
        findings.append(
            finding(
                "legacy.pending-generation-inputs",
                "P0",
                "legacy_generation_input",
                ids[0],
                "",
                "Legacy v1 members still say pending_generation; D31 retires this bank as a generation input.",
                [*ids, relative(root / LEGACY_FAMILIES_PATH, root)],
                "Migrate only through a complete v2 family/member, provenance, risk flags, capture request, and registered batch.",
                gate=CAPTURE_BLOCKED,
            )
        )

    legacy_spot_flagged = [
        row for row in legacy if row.get("qa_state") == "spot_flagged"
    ]
    if legacy_spot_flagged:
        findings.append(
            finding(
                "legacy.spot-flagged-members",
                "P1",
                "legacy_review_state",
                legacy_spot_flagged[0]["member_id"],
                legacy_spot_flagged[0]["text"],
                f"{len(legacy_spot_flagged)} legacy members remain spot_flagged and have no v2 review record.",
                [row["member_id"] for row in legacy_spot_flagged],
                "Keep the legacy state visible; import a v2 review record only when an actual review occurs.",
            )
        )

    for row in batches:
        voice = row.get("voice_profile", {})
        mismatches = [
            field
            for field, expected in LOCKED_VOICE.items()
            if voice.get(field) != expected
        ]
        if mismatches:
            findings.append(
                finding(
                    f"{row['id']}.voice-lock",
                    "P0",
                    "voice_lock",
                    row["id"],
                    row["text"],
                    "Batch voice snapshot differs from the user-locked Irish profile: "
                    + ", ".join(mismatches),
                    [row["path"]],
                    "Hold provider execution; do not substitute a voice or model.",
                    gate=CAPTURE_BLOCKED,
                )
            )

        request_status = (row.get("request") or {}).get("status")
        claim_status = (row.get("claim") or {}).get("status")
        provider_status = (row.get("provider_result") or {}).get("status")
        execution_state = (row.get("execution") or {}).get("state")
        if claim_status == "claimed" and provider_status == "not_started":
            findings.append(
                finding(
                    f"{row['id']}.claimed-not-started",
                    "P0",
                    "batch_state",
                    row["id"],
                    row["text"],
                    "Line has an active claim but its provider result is still not_started.",
                    [row["path"], row["line_id"], *row.get("member_ids", [])],
                    "Operational watch: do not duplicate or promote; resolve the existing lease/result first.",
                    gate=OPERATIONAL_WATCH,
                )
            )
        if request_status == "approved" and execution_state != "approved":
            findings.append(
                finding(
                    f"{row['id']}.request-execution-mismatch",
                    "P0",
                    "batch_state",
                    row["id"],
                    row["text"],
                    "Line request is approved while the enclosing batch is not approved for provider execution.",
                    [row["path"], row["line_id"]],
                    "Hold: reconcile batch state before any provider call.",
                    gate=CAPTURE_BLOCKED,
                )
            )

    spot_listen = root / SPOT_LISTEN_PATH
    summary = {
        "inventory_entries": len(inventory_entries),
        "launch_rows": len(launch),
        "pack_audio_rows": len(packs),
        "legacy_members": len(legacy),
        "v2_members": len(v2),
        "batch_lines": len(batches),
        "inventory_spot_flagged": sum(
            1 for entry in inventory_entries if entry.get("qa_state") == "spot_flagged"
        ),
        "launch_missing_inventory": sum(
            1 for row in launch if row["text"] not in inventory
        ),
        "legacy_pending_generation": len(pending_legacy),
        "v2_learner_release_eligible": sum(
            1 for row in v2 if row.get("release") == "eligible"
        ),
        "spot_listen_present": spot_listen.is_file(),
        "capture_blockers": sum(1 for item in findings if item.gate == CAPTURE_BLOCKED),
        "review_before_release": sum(
            1 for item in findings if item.gate == REVIEW_BEFORE_RELEASE
        ),
        "operational_watches": sum(
            1 for item in findings if item.gate == OPERATIONAL_WATCH
        ),
        # Keep the old key as a compatibility alias for consumers that only knew
        # about "hard" findings. The gate, not priority, now controls checkability.
        "hard_findings": sum(1 for item in findings if item.gate == CAPTURE_BLOCKED),
        "p0_findings": sum(1 for item in findings if item.priority == "P0"),
        "findings": len(findings),
    }
    findings.sort(key=lambda item: (item.priority, item.category, item.finding_id))
    return {
        "summary": summary,
        "findings": [asdict(item) for item in findings],
    }


def render_finding(item: dict[str, Any]) -> list[str]:
    return [
        f"### {item['priority']} · `{item['finding_id']}`",
        "",
        f"- Gate: `{item['gate']}`",
        f"- Record: `{item['record_id']}`",
        f"- Irish: `{item['text']}`" if item["text"] else "- Irish: *(aggregate finding)*",
        f"- Finding: {item['message']}",
        f"- Evidence: {', '.join(f'`{ref}`' for ref in item['evidence'])}",
        f"- Disposition: {item['disposition']}",
        "",
    ]


def render_report(audit: dict[str, Any], *, show_all: bool = False) -> str:
    summary = audit["summary"]
    findings = audit["findings"]
    lines = [
        "# D32 Irish high-risk review audit",
        "",
        "Mechanical source audit only: it does not judge pronunciation, Irish grammar,",
        "dialect, pedagogy, history, or audio quality, and it does not grant capture or",
        "learner release.",
        "",
        "## Counts",
        "",
        "| Measure | Count |",
        "| --- | ---: |",
    ]
    for key, value in summary.items():
        if key in {"spot_listen_present", "hard_findings", "p0_findings", "findings"}:
            continue
        lines.append(f"| `{key}` | {value} |")
    lines.extend(
        [
            "",
            f"Capture blockers: **{summary['capture_blockers']}**; review-before-release findings: **{summary['review_before_release']}**; operational watches: **{summary['operational_watches']}**; total findings: **{summary['findings']}**.",
            f"Canonical spot-listen record present: **{summary['spot_listen_present']}**.",
            "",
            "A `capture_blocked` finding withholds a line even from provisional capture. A",
            "`review_before_release` finding may remain a D32 capture candidate only when",
            "the v2 identity, provenance, risk, exercise, authorization, batch, claim, and",
            "result contracts are satisfied; it never grants learner release. An",
            "`operational_watch` is an existing claim/lease/result handoff and is not a new",
            "capture authorization.",
            "",
        ]
    )

    capture_blockers = [item for item in findings if item["gate"] == CAPTURE_BLOCKED]
    review_findings = [
        item for item in findings if item["gate"] == REVIEW_BEFORE_RELEASE
    ]
    operational_watches = [
        item for item in findings if item["gate"] == OPERATIONAL_WATCH
    ]

    lines.extend(["## Capture blockers — withhold even from provisional capture", ""])
    if capture_blockers:
        for item in capture_blockers:
            lines.extend(render_finding(item))
    else:
        lines.extend(["No mechanical capture blockers found.", ""])

    lines.extend(["## Review before learner release", ""])
    selected_review = review_findings if show_all else review_findings[:24]
    if selected_review:
        for item in selected_review:
            lines.extend(render_finding(item))
    else:
        lines.extend(["No review-only mechanical prompts found.", ""])

    lines.extend(["## Operational watches", ""])
    if operational_watches:
        for item in operational_watches:
            lines.extend(render_finding(item))
    else:
        lines.extend(["No active claim/lease/result watches found.", ""])

    if not show_all:
        lines.extend(
            [
                "The default report shows every capture blocker and operational watch plus a bounded review-only sample; use `--all` for every mechanical flag.",
                "",
            ]
        )
    return "\n".join(lines)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("report", "check"))
    parser.add_argument(
        "--all", action="store_true", help="Include every finding in report output."
    )
    parser.add_argument("--json", action="store_true", help="Emit the audit object as JSON.")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    audit = audit_sources()
    if args.json:
        print(json.dumps(audit, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print(render_report(audit, show_all=args.all))
    if args.command == "check" and audit["summary"]["capture_blockers"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
