#!/usr/bin/env python3
"""Rank frozen-corpus candidates for the first reviewable learner-facing slice.

This is an offline review-planning tool for `STATUS.md` §6 step 1 under D35. It
reads the v2 authoring store, the county pack, the runtime manifest, the latest
risk stratification, the Track D technical audit, and the mechanical review
queue, and it emits a deterministic ranking plus a bounded slice selection.

It does not judge Irish grammar, dialect, pronunciation, pedagogy, or history;
it does not approve anything; and it never changes capture, claim, lease,
checksum, QA, or learner-release state. A high score means "review this first",
never "this is correct".

Two rankings exist (docs/SLICE-SELECTION.md §1). This tool builds ranking A,
slice selection, in which risk is a penalty. Ranking B, review order within the
slice, reuses the existing risk stratification, in which risk is a boost.
"""

from __future__ import annotations

import argparse
import json
import statistics
import sys
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

SCHEMA_VERSION = 1
CONTRACT = "irish_slice_selection_ranking"
LOCKED_VOICE_ID = "NPWroowF4phQhaPWjXPj"

DEFAULT_COUNTY = "mayo"
DEFAULT_PACK = "content/mayo/grainne-1593.pack.draft.json"
DEFAULT_FAMILY_DIR = "content/mayo/phrase-families/authoring-v2"
DEFAULT_SLICE_SIZE = 60
DEFAULT_SEED = "d35.slice-selection.v1"

MANIFEST_PATH = "ios/AnTuras/Resources/Audio/manifest.json"
PEDAGOGY_PATH = "content/pedagogy/irish-explanations-v1.json"
TRACK_D_PATH = "content/audio/authoring/d32-cycle2-track-d-post-capture-report.json"
STRATIFICATION_GLOB = "content/audio/authoring/sampling/d32-risk-stratification-*.json"

# Story ids that count as the Mayo Gráinne story. The store carries two
# spellings for the same story; both are in scope, other counties' stories are
# not (docs/SLICE-SELECTION.md §3, §7.4).
IN_SCOPE_STORY_IDS = frozenset({"d32.mayo.grainne-1593", "mayo.grainne-1593"})

CRITERION_WEIGHTS = {
    "story_relevance": 5,
    "reuse": 4,
    "pedagogical_purpose": 4,
    "risk": -3,
    "audio_quality": 3,
}

# Flags carried by so much of the pool that they cannot discriminate between
# candidates. Recorded on every row for audit, excluded from scoring, exactly as
# `priority` is (docs/SLICE-SELECTION.md §3).
NON_DISCRIMINATING_FLAGS = frozenset({"invented_text", "audio_pronunciation"})

RISK_FLAG_PENALTIES = {
    "source_ambiguity": 2,
    "sense_ambiguity": 3,
    "pronoun_reference": 1,
    "historical_roleplay": 2,
    "initial_mutation": 1,
}
RISK_CATEGORY_PENALTIES = {
    "names": 2,
    "places": 1,
}

# D30's two consuming patterns. Matched against the free-text `use` field and
# the structured `response_family`.
SURROUND_CHANGE_MARKERS = ("surround change", "surround-change")
DELAYED_REUSE_MARKERS = ("delayed reuse", "delayed retrieval", "delayed")
D30_RESPONSE_FAMILIES = frozenset({"sentenceConstruction"})

# D30's designated first proof; included regardless of rank (§5).
ANCHOR_FAMILY_SUBSTRINGS = ("farraige",)


def normalize_text(text: Any) -> str:
    if not isinstance(text, str):
        return ""
    return unicodedata.normalize("NFC", text).strip()


def load_json(path: Path) -> Any:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def latest_stratification(root: Path) -> Path:
    paths = sorted(root.glob(STRATIFICATION_GLOB))
    if not paths:
        raise SystemExit(f"no risk stratification found under {STRATIFICATION_GLOB}")
    return paths[-1]


def percentile(values: list[float], fraction: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    if len(ordered) == 1:
        return ordered[0]
    position = fraction * (len(ordered) - 1)
    low = int(position)
    high = min(low + 1, len(ordered) - 1)
    weight = position - low
    return ordered[low] * (1 - weight) + ordered[high] * weight


def chapter_index(pack: dict[str, Any]) -> dict[str, str]:
    """Map every pack page id to the chapter that owns it."""
    index: dict[str, str] = {}
    for chapter in pack.get("chapters", []):
        chapter_id = chapter.get("id")
        if not isinstance(chapter_id, str):
            continue
        for page in chapter.get("pages", []):
            page_id = page.get("id")
            if isinstance(page_id, str):
                index[page_id] = chapter_id
    return index


def load_members(family_dir: Path) -> list[dict[str, Any]]:
    """Load every v2 member in the county family directory, with its family."""
    members: list[dict[str, Any]] = []
    for path in sorted(family_dir.glob("*.json")):
        family = load_json(path)
        family_id = family.get("id")
        story_ref = family.get("story_ref") or {}
        for member in family.get("members", []):
            members.append(
                {
                    "member": member,
                    "family_id": family_id,
                    "family_path": str(path.relative_to(ROOT)),
                    "family_story_record": story_ref.get("record_id"),
                }
            )
    return members


def stratification_index(payload: dict[str, Any]) -> tuple[
    dict[str, dict[str, Any]], dict[str, dict[str, Any]], dict[str, list[dict[str, Any]]]
]:
    """Index risk items by member id, by normalized text, and by duplicate key."""
    by_member: dict[str, dict[str, Any]] = {}
    by_text: dict[str, dict[str, Any]] = {}
    by_text_all: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for item in payload.get("risk_items", []):
        text = normalize_text(item.get("normalized_text"))
        if text:
            by_text.setdefault(text, item)
            by_text_all[text].append(item)
        for member_id in item.get("member_ids", []):
            if isinstance(member_id, str):
                by_member.setdefault(member_id, item)
    return by_member, by_text, by_text_all


def capture_blocker_keys(audit: dict[str, Any]) -> tuple[set[str], set[str]]:
    """Record ids and texts that the mechanical audit blocks from capture."""
    record_ids: set[str] = set()
    texts: set[str] = set()
    for item in audit.get("findings", []):
        if item.get("gate") != "capture_blocked":
            continue
        record_id = item.get("record_id")
        if isinstance(record_id, str):
            record_ids.add(record_id)
            # v2 member findings are recorded with a `v2.` prefix.
            if record_id.startswith("v2."):
                record_ids.add(record_id[3:])
        text = normalize_text(item.get("text"))
        if text:
            texts.add(text)
    return record_ids, texts


def pedagogy_examples(path: Path) -> set[str]:
    """Every exact Irish example text carried by the pedagogy sidecar."""
    if not path.is_file():
        return set()
    payload = load_json(path)
    texts: set[str] = set()

    def walk(node: Any) -> None:
        if isinstance(node, dict):
            for key, value in node.items():
                if key in {"irish", "irish_text", "example", "example_text"}:
                    if isinstance(value, str):
                        text = normalize_text(value)
                        if text:
                            texts.add(text)
                    elif isinstance(value, dict):
                        for inner in ("text", "normalized_text"):
                            text = normalize_text(value.get(inner))
                            if text:
                                texts.add(text)
                walk(value)
        elif isinstance(node, list):
            for entry in node:
                walk(entry)

    walk(payload)
    return texts


def consumer_patterns(member: dict[str, Any]) -> dict[str, bool]:
    """Detect D30's two consuming patterns on a member's exercise consumers."""
    surround = False
    delayed = False
    for consumer in member.get("exercise_consumers", []):
        use = str(consumer.get("use") or "").lower()
        family = consumer.get("response_family")
        if any(marker in use for marker in SURROUND_CHANGE_MARKERS):
            surround = True
        if any(marker in use for marker in DELAYED_REUSE_MARKERS):
            delayed = True
        if family in D30_RESPONSE_FAMILIES:
            surround = True
    return {"surround_change": surround, "delayed_reuse": delayed}


def score_story_relevance(
    member: dict[str, Any],
    *,
    chapters: dict[str, str],
    story_ids: set[str],
) -> tuple[int, list[str], list[str]]:
    """C1 — does a chapter of the production draft actually need this line?"""
    bound_chapters: list[str] = []
    for consumer in member.get("exercise_consumers", []):
        record_id = consumer.get("record_id")
        if isinstance(record_id, str) and record_id in chapters:
            bound_chapters.append(chapters[record_id])
    bound_chapters = sorted(set(bound_chapters))
    in_story = bool(story_ids & IN_SCOPE_STORY_IDS)
    has_consumer = bool(member.get("exercise_consumers"))

    if bound_chapters and in_story:
        return 5, bound_chapters, ["chapter_bound", "in_scope_story"]
    if in_story and has_consumer:
        return 3, bound_chapters, ["in_scope_story", "consumer_not_chapter_bound"]
    if has_consumer:
        return 1, bound_chapters, ["out_of_scope_story"]
    return 0, bound_chapters, ["no_exercise_consumer"]


def score_reuse(
    member: dict[str, Any],
    *,
    risk_item: dict[str, Any] | None,
    duplicate_group: list[dict[str, Any]],
    intent_conflict: bool,
) -> tuple[int, list[str]]:
    """C2 — how much does one approval buy? Reuse is not duplication (§4)."""
    if intent_conflict:
        return 0, ["conflicting_intent_duplicate"]

    reasons: list[str] = []
    consumers = len(member.get("exercise_consumers", []))
    if consumers >= 3:
        score = 3
    elif consumers == 2:
        score = 2
    else:
        score = 1
    reasons.append(f"exercise_consumers:{consumers}")

    placements = len((risk_item or {}).get("placement_ids", []) or [])
    if placements:
        score += 1
        reasons.append(f"atlas_placements:{placements}")

    counties = {
        county
        for item in duplicate_group
        for county in item.get("counties", [])
        if isinstance(county, str)
    }
    if len(counties) > 1:
        score += 1
        reasons.append(f"consistent_intent_across_counties:{len(counties)}")

    return min(score, 5), reasons


def score_pedagogy(
    member: dict[str, Any],
    *,
    patterns: dict[str, bool],
    in_sidecar: bool,
) -> tuple[int, list[str]]:
    """C3 — is there a named teaching job for this line?"""
    reasons: list[str] = []
    d30 = patterns["surround_change"] or patterns["delayed_reuse"]
    if d30:
        reasons.extend(name for name, hit in patterns.items() if hit)
    if in_sidecar:
        reasons.append("pedagogy_sidecar_example")

    if d30 and in_sidecar:
        return 5, reasons
    if d30:
        return 3, reasons

    morphology = str((member.get("target") or {}).get("morphology") or "").strip()
    flags = set(member.get("risk_flags") or [])
    if morphology or "initial_mutation" in flags:
        reasons.append("target_morphology")
        return 2, reasons
    if member.get("exercise_consumers"):
        reasons.append("exercise_bound_only")
        return 1, reasons
    return 0, reasons or ["no_teaching_role"]


def score_risk(
    member: dict[str, Any],
    *,
    risk_item: dict[str, Any] | None,
    intent_conflict: bool,
    risk_score_bounds: tuple[float, float],
) -> tuple[float, list[str], list[str]]:
    """C4 — raw penalty. Risky lines are expensive, failure-prone first proofs.

    Returns an uncapped raw penalty. Capping here saturates: most of the pool
    carries mutation, name, and place risk at once, so a hard 0–5 clamp would
    make the criterion constant. The raw value is calibrated against the pool in
    :func:`calibrate_risk` so it discriminates within the material actually
    under consideration.
    """
    reasons: list[str] = []
    penalty = 0.0

    low, high = risk_score_bounds
    raw = (risk_item or {}).get("risk_score")
    if isinstance(raw, (int, float)) and high > low:
        scaled = (float(raw) - low) / (high - low)
        penalty += 3.0 * max(0.0, min(1.0, scaled))
        reasons.append(f"risk_score:{raw}")

    flags = [flag for flag in member.get("risk_flags") or [] if isinstance(flag, str)]
    scored_flags = [flag for flag in flags if flag not in NON_DISCRIMINATING_FLAGS]
    for flag in scored_flags:
        weight = RISK_FLAG_PENALTIES.get(flag)
        if weight:
            penalty += weight
            reasons.append(f"flag:{flag}")

    categories = set((risk_item or {}).get("categories", []) or [])
    for category, weight in RISK_CATEGORY_PENALTIES.items():
        if category in categories:
            penalty += weight
            reasons.append(f"category:{category}")

    if intent_conflict:
        penalty += 5
        reasons.append("conflicting_intent_duplicate")

    ignored = sorted(set(flags) & NON_DISCRIMINATING_FLAGS)
    return penalty, reasons, ignored


def calibrate_risk(raw_values: list[float]) -> list[int]:
    """Map raw risk penalties onto 0–5 by position within the pool."""
    if not raw_values:
        return []
    bounds = [percentile(raw_values, fraction) for fraction in (0.2, 0.4, 0.6, 0.8)]
    calibrated: list[int] = []
    for value in raw_values:
        score = 0
        for bound in bounds:
            if value > bound:
                score += 1
        calibrated.append(score)
    return calibrated


def criterion_discrimination(rows: list[dict[str, Any]]) -> dict[str, Any]:
    """Report how much work each criterion actually did.

    A criterion whose value is near-constant across the pool cannot rank
    anything, however sensible it looks on paper. Naming those explicitly keeps
    the ranking honest rather than letting a dead criterion imply it contributed.
    """
    report: dict[str, Any] = {}
    total = len(rows)
    for name in CRITERION_WEIGHTS:
        counts = Counter(row["subscores"][name] for row in rows)
        modal_value, modal_count = (
            counts.most_common(1)[0] if counts else (None, 0)
        )
        share = (modal_count / total) if total else 0.0
        report[name] = {
            "distribution": {str(key): value for key, value in sorted(counts.items())},
            "modal_value": modal_value,
            "modal_share": round(share, 4),
            "effectively_constant": share >= 0.9,
        }
    return report


def score_audio(
    slug: str,
    *,
    manifest_row: dict[str, Any] | None,
    review_slugs: set[str],
    duration_band: tuple[float, float],
) -> tuple[int, list[str]]:
    """C5 — mechanical only. Never evidence that the Irish is good."""
    if slug in review_slugs:
        return 0, ["track_d_listening_review_outlier"]
    if manifest_row is None:
        return 0, ["no_manifest_row"]
    duration = manifest_row.get("duration_seconds")
    if not isinstance(duration, (int, float)):
        return 2, ["duration_unknown"]
    low, high = duration_band
    if low <= duration <= high:
        return 5, [f"duration_near_centre:{duration}"]
    return 2, [f"duration_at_edge:{duration}"]


def build_candidates(
    *,
    root: Path,
    county: str,
    pack_path: Path,
    family_dir: Path,
    slice_size: int,
) -> dict[str, Any]:
    pack = load_json(pack_path)["pack"]
    chapters = chapter_index(pack)
    manifest = load_json(root / MANIFEST_PATH)
    manifest_rows = {
        row.get("slug"): row for row in manifest.get("lines", []) if row.get("slug")
    }
    excluded_slugs = {
        row.get("slug")
        for row in manifest.get("dynamic_exclusions", [])
        if row.get("slug")
    }

    track_d = load_json(root / TRACK_D_PATH)
    technical = track_d.get("technical_audio", {})
    review_slugs = set(technical.get("review_slugs", []) or [])
    quarantine_slugs = set(technical.get("quarantine_slugs", []) or [])

    stratification_path = latest_stratification(root)
    stratification = load_json(stratification_path)
    by_member, by_text, by_text_all = stratification_index(stratification)

    from audit_irish_review_queue import audit_sources

    audit = audit_sources(root)
    blocked_ids, blocked_texts = capture_blocker_keys(audit)

    sidecar = pedagogy_examples(root / PEDAGOGY_PATH)
    records = load_members(family_dir)

    # Risk-score bounds are taken from the county pool so the penalty
    # discriminates within the pool rather than against the whole corpus.
    pool_risk_scores = [
        float(by_member[entry["member"]["id"]]["risk_score"])
        for entry in records
        if entry["member"].get("id") in by_member
        and isinstance(by_member[entry["member"]["id"]].get("risk_score"), (int, float))
    ]
    risk_bounds = (
        (min(pool_risk_scores), max(pool_risk_scores))
        if pool_risk_scores
        else (0.0, 1.0)
    )

    pool_durations = [
        manifest_rows[slug]["duration_seconds"]
        for slug in (
            normalize_text((entry["member"].get("irish") or {}).get("inventory_slug"))
            for entry in records
        )
        if slug in manifest_rows
        and isinstance(manifest_rows[slug].get("duration_seconds"), (int, float))
    ]
    duration_band = (
        (percentile(pool_durations, 0.25), percentile(pool_durations, 0.75))
        if pool_durations
        else (0.0, 0.0)
    )

    candidates: list[dict[str, Any]] = []
    gated: list[dict[str, Any]] = []

    for entry in records:
        member = entry["member"]
        member_id = member.get("id")
        irish = member.get("irish") or {}
        text = normalize_text(irish.get("text") or irish.get("normalized_text"))
        slug = irish.get("inventory_slug")
        risk_item = by_member.get(member_id) or by_text.get(text)
        manifest_row = manifest_rows.get(slug)

        story_ids = set((risk_item or {}).get("story_ids", []) or [])
        if entry["family_story_record"]:
            story_ids.add(entry["family_story_record"])

        gates: list[str] = []
        notes: list[str] = []
        states = (risk_item or {}).get("batch_states", []) or []
        captured = any("succeeded" in str(state) for state in states)
        if manifest_row is None:
            gates.append("no_runtime_clip")
        elif not manifest_row.get("sha256"):
            gates.append("no_checksum")
        elif not captured:
            # A bundled, checksummed clip satisfies the gate's purpose — there
            # is real audio to review. Some D30-era lines carry their clip from
            # the pre-v2 inventory path and have no succeeded v2 batch state.
            notes.append("legacy_inventory_provenance_not_v2_batch")
        if slug in excluded_slugs:
            gates.append("dynamically_excluded")
        if slug in quarantine_slugs:
            gates.append("technical_quarantine")
        if member_id in blocked_ids or text in blocked_texts:
            gates.append("capture_blocker")
        if not (story_ids & IN_SCOPE_STORY_IDS):
            gates.append("out_of_scope_story")

        duplicate_group = [
            item for item in by_text_all.get(text, []) if item is not risk_item
        ]
        intents = {
            normalize_text((member.get("english") or {}).get("intent"))
        }
        for other in by_text_all.get(text, []):
            for path in other.get("source_paths", []) or []:
                candidate_path = root / path
                if not candidate_path.is_file():
                    continue
                other_family = load_json(candidate_path)
                for other_member in other_family.get("members", []):
                    other_irish = other_member.get("irish") or {}
                    if normalize_text(other_irish.get("text")) != text:
                        continue
                    intents.add(
                        normalize_text((other_member.get("english") or {}).get("intent"))
                    )
        intents.discard("")
        intent_conflict = len(intents) > 1

        row: dict[str, Any] = {
            "member_id": member_id,
            "family_id": entry["family_id"],
            "family_path": entry["family_path"],
            "irish_text": text,
            "english_intent": normalize_text(
                (member.get("english") or {}).get("intent")
            ),
            "slug": slug,
            "text_sha256": irish.get("text_sha256"),
            "story_ids": sorted(story_ids),
            "gates": gates,
            "notes": notes,
        }

        if gates:
            gated.append(row)
            continue

        patterns = consumer_patterns(member)
        c1, bound_chapters, c1_reasons = score_story_relevance(
            member, chapters=chapters, story_ids=story_ids
        )
        c2, c2_reasons = score_reuse(
            member,
            risk_item=risk_item,
            duplicate_group=duplicate_group,
            intent_conflict=intent_conflict,
        )
        c3, c3_reasons = score_pedagogy(
            member, patterns=patterns, in_sidecar=text in sidecar
        )
        raw_risk, c4_reasons, ignored_flags = score_risk(
            member,
            risk_item=risk_item,
            intent_conflict=intent_conflict,
            risk_score_bounds=risk_bounds,
        )
        c5, c5_reasons = score_audio(
            slug,
            manifest_row=manifest_row,
            review_slugs=review_slugs,
            duration_band=duration_band,
        )

        subscores = {
            "story_relevance": c1,
            "reuse": c2,
            "pedagogical_purpose": c3,
            "risk": 0,  # calibrated against the pool after the loop
            "audio_quality": c5,
        }

        reviews = ((member.get("states") or {}).get("reviews") or {})
        already_approved = bool(reviews) and all(
            (record or {}).get("status") == "approved" for record in reviews.values()
        )

        row.update(
            {
                "subscores": subscores,
                "raw_risk_penalty": round(raw_risk, 3),
                "reasons": {
                    "story_relevance": c1_reasons,
                    "reuse": c2_reasons,
                    "pedagogical_purpose": c3_reasons,
                    "risk": c4_reasons,
                    "audio_quality": c5_reasons,
                },
                "chapters": bound_chapters,
                "d30_patterns": sorted(name for name, hit in patterns.items() if hit),
                "duplicate_texts": len(duplicate_group),
                "intent_conflict": intent_conflict,
                "risk_flags_ignored_as_non_discriminating": ignored_flags,
                "already_approved": already_approved,
                "duration_seconds": (manifest_row or {}).get("duration_seconds"),
                "qa_state": (manifest_row or {}).get("qa_state"),
            }
        )
        candidates.append(row)

    for row, calibrated in zip(
        candidates, calibrate_risk([row["raw_risk_penalty"] for row in candidates])
    ):
        row["subscores"]["risk"] = calibrated
        row["weighted_total"] = sum(
            row["subscores"][name] * weight
            for name, weight in CRITERION_WEIGHTS.items()
        )

    candidates.sort(
        key=lambda row: (-row["weighted_total"], str(row.get("text_sha256") or ""))
    )
    discrimination = criterion_discrimination(candidates)
    selection = select_slice(candidates, slice_size=slice_size)

    return {
        "schema_version": SCHEMA_VERSION,
        "contract": CONTRACT,
        "scope": (
            "slice selection ranking for review planning only; not approval, "
            "not learner release, and no state is changed"
        ),
        "read_only": True,
        "county": county,
        "in_scope_story_ids": sorted(IN_SCOPE_STORY_IDS),
        "sources": {
            "pack": str(pack_path.relative_to(ROOT)),
            "family_dir": str(family_dir.relative_to(ROOT)),
            "manifest": MANIFEST_PATH,
            "stratification": str(stratification_path.relative_to(ROOT)),
            "track_d_report": TRACK_D_PATH,
            "pedagogy_sidecar": PEDAGOGY_PATH,
            "review_queue_audit": "tools/audit_irish_review_queue.py::audit_sources",
        },
        "method": {
            "weights": CRITERION_WEIGHTS,
            "risk_direction": "penalty",
            "risk_score_bounds_in_pool": list(risk_bounds),
            "duration_centre_band_seconds": list(duration_band),
            "non_discriminating_flags_excluded": sorted(NON_DISCRIMINATING_FLAGS),
            "note": (
                "Risk penalizes slice selection (ranking A). Review order within "
                "the slice (ranking B) is the existing risk stratification, where "
                "risk boosts."
            ),
        },
        "summary": {
            "members_examined": len(records),
            "gated_out": len(gated),
            "candidates": len(candidates),
            "selected": len(selection["slice"]),
            "gate_counts": dict(
                Counter(gate for row in gated for gate in row["gates"]).most_common()
            ),
            "note_counts": dict(
                Counter(
                    note for row in candidates for note in row.get("notes", [])
                ).most_common()
            ),
            "chapter_bound_candidates": sum(
                1 for row in candidates if row.get("chapters")
            ),
            "d30_pattern_candidates": sum(
                1 for row in candidates if row.get("d30_patterns")
            ),
        },
        "criterion_discrimination": discrimination,
        "selection": selection,
        "candidates": candidates,
        "gated": gated,
    }


def select_slice(
    candidates: list[dict[str, Any]], *, slice_size: int
) -> dict[str, Any]:
    """Greedy coverage-constrained selection (docs/SLICE-SELECTION.md §5)."""
    family_cap = max(1, round(slice_size * 0.15))
    per_family: Counter[str] = Counter()
    per_chapter: Counter[str] = Counter()
    chosen: list[dict[str, Any]] = []
    chosen_ids: set[str] = set()
    constraints: list[str] = []

    def take(row: dict[str, Any], reason: str) -> None:
        chosen.append({**row, "selected_because": reason})
        chosen_ids.add(str(row["member_id"]))
        per_family[str(row["family_id"])] += 1
        for chapter in row["chapters"] or ["unbound"]:
            per_chapter[chapter] += 1

    # 1. Anchors: D30's designated first proof stays in the slice by name.
    for row in candidates:
        if len(chosen) >= slice_size:
            break
        family_id = str(row["family_id"] or "")
        if any(marker in family_id for marker in ANCHOR_FAMILY_SUBSTRINGS):
            if str(row["member_id"]) not in chosen_ids:
                take(row, "anchor_family")
    if chosen:
        constraints.append(f"anchor_family_members:{len(chosen)}")

    # 2. Cover both D30 consuming patterns before general filling.
    for pattern in ("surround_change", "delayed_reuse"):
        if any(pattern in row.get("d30_patterns", []) for row in chosen):
            continue
        for row in candidates:
            if str(row["member_id"]) in chosen_ids:
                continue
            if pattern in row.get("d30_patterns", []):
                take(row, f"pattern_coverage:{pattern}")
                constraints.append(f"pattern_coverage:{pattern}")
                break

    # 3. Fill by rank under the per-family cap, then relax the cap if the
    #    pool is too narrow to fill the slice without it.
    for row in candidates:
        if len(chosen) >= slice_size:
            break
        if str(row["member_id"]) in chosen_ids:
            continue
        if per_family[str(row["family_id"])] >= family_cap:
            continue
        take(row, "rank")

    if len(chosen) < slice_size:
        constraints.append("family_cap_relaxed_to_fill_slice")
        for row in candidates:
            if len(chosen) >= slice_size:
                break
            if str(row["member_id"]) in chosen_ids:
                continue
            take(row, "rank_after_cap_relaxed")

    return {
        "slice_size_requested": slice_size,
        "family_cap": family_cap,
        "constraints_applied": constraints,
        "coverage": {
            "families": dict(per_family.most_common()),
            "chapters": dict(per_chapter.most_common()),
            "d30_patterns": dict(
                Counter(
                    pattern for row in chosen for pattern in row.get("d30_patterns", [])
                ).most_common()
            ),
            "already_approved": sum(1 for row in chosen if row.get("already_approved")),
        },
        "slice": chosen,
    }


def render_packet(report: dict[str, Any]) -> str:
    """Human-readable review packet, grouped by chapter then family."""
    selection = report["selection"]
    lines: list[str] = []
    lines.append("# Review packet — first learner-facing slice candidate")
    lines.append("")
    lines.append(
        f"*Generated by `tools/rank_slice_candidates.py` for county "
        f"`{report['county']}`. Review planning only: nothing here is approved, "
        f"and selection is not evidence that the Irish is correct.*"
    )
    lines.append("")
    summary = report["summary"]
    lines.append(
        f"**{summary['selected']}** lines selected from **{summary['candidates']}** "
        f"eligible candidates (**{summary['gated_out']}** gated out of "
        f"**{summary['members_examined']}** members examined)."
    )
    lines.append("")
    lines.append("## What the reviewer is being asked")
    lines.append("")
    lines.append(
        "For each line: is the Irish correct and idiomatic for its stated English "
        "intent, appropriate in dialect and register, and safe to teach? A line may "
        "be approved, corrected, or rejected. Approving a line does not release it."
    )
    lines.append("")

    grouped: dict[str, dict[str, list[dict[str, Any]]]] = defaultdict(
        lambda: defaultdict(list)
    )
    for row in selection["slice"]:
        chapter = (row.get("chapters") or ["· unbound to a chapter"])[0]
        grouped[chapter][str(row.get("family_id"))].append(row)

    for chapter in sorted(grouped):
        lines.append(f"## {chapter}")
        lines.append("")
        for family_id in sorted(grouped[chapter]):
            lines.append(f"### {family_id}")
            lines.append("")
            for row in grouped[chapter][family_id]:
                flags = row["reasons"]["risk"]
                lines.append(f"- **{row['irish_text']}**")
                lines.append(f"  - intent: {row['english_intent']}")
                lines.append(f"  - member: `{row['member_id']}`")
                lines.append(f"  - clip: `{row['slug']}.mp3` ({row['duration_seconds']}s)")
                if row.get("d30_patterns"):
                    lines.append(f"  - pattern: {', '.join(row['d30_patterns'])}")
                if flags:
                    lines.append(f"  - risk: {', '.join(flags)}")
                if row.get("already_approved"):
                    lines.append("  - **already approved** — no review time needed")
                lines.append(
                    f"  - score: {row['weighted_total']} "
                    f"({row['selected_because']})"
                )
            lines.append("")
    return "\n".join(lines)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("command", choices=("report", "packet", "check"))
    parser.add_argument("--county", default=DEFAULT_COUNTY)
    parser.add_argument("--pack", default=DEFAULT_PACK)
    parser.add_argument("--family-dir", default=DEFAULT_FAMILY_DIR)
    parser.add_argument("--slice-size", type=int, default=DEFAULT_SLICE_SIZE)
    parser.add_argument("--seed", default=DEFAULT_SEED)
    parser.add_argument("--out", help="Write the report or packet to this path.")
    parser.add_argument("--json", action="store_true", help="Emit JSON to stdout.")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])
    report = build_candidates(
        root=ROOT,
        county=args.county,
        pack_path=ROOT / args.pack,
        family_dir=ROOT / args.family_dir,
        slice_size=args.slice_size,
    )
    report["seed"] = args.seed

    if args.command == "check":
        summary = report["summary"]
        ok = summary["candidates"] > 0 and summary["selected"] > 0
        print(
            f"candidates={summary['candidates']} selected={summary['selected']} "
            f"gated={summary['gated_out']} {'ok' if ok else 'EMPTY'}"
        )
        return 0 if ok else 1

    if args.command == "packet":
        text = render_packet(report)
        if args.out:
            Path(args.out).write_text(text, encoding="utf-8")
            print(f"wrote {args.out}")
        else:
            print(text)
        return 0

    payload = json.dumps(report, ensure_ascii=False, indent=1, sort_keys=False)
    if args.out:
        Path(args.out).write_text(payload + "\n", encoding="utf-8")
        print(f"wrote {args.out}")
    elif args.json:
        print(payload)
    else:
        summary = report["summary"]
        print(json.dumps(summary, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
