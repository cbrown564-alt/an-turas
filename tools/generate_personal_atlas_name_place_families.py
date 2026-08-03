#!/usr/bin/env python3
"""Add provisional Personal Atlas name/place contexts to canonical v2 families.

This is an offline authoring tool. It never calls a provider and never changes
audio result state. Personal Atlas and Logainm records are used as provenance
patterns; every surrounding sentence remains invented pedagogical material.
"""

from __future__ import annotations

import copy
import json
import sqlite3
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.structured_audio_authoring import (
    canonical_audio_slug,
    identifier_slug,
    normalize_spoken_text,
    text_sha256,
)


ROOT = Path(__file__).resolve().parents[1]
SUBJECTS_PATH = ROOT / "ios/AnTuras/Resources/personal-atlas-subjects.json"
A1_BULK_SUBJECTS_PATH = ROOT / "content/personal-atlas/a1-bulk-subjects.json"
FOUNDATION_PATH = ROOT / "ios/AnTuras/Resources/personal-atlas-foundation.sqlite"
USES_PATH = ROOT / "content/audio/authoring/d32-county-harvest-uses.json"
LOGAINM_SOURCE_INDEX_PATH = ROOT / "content/personal-atlas/logainm-v2-source-index.json"
FAMILY_GLOB = "content/*/phrase-families/authoring-v2/d32.*.v2.json"
LEGACY_NAME_FAMILY_GLOB = "content/{county}/phrase-families/authoring-v2/ainm.name-noun.v2.json"
CREATED_AT = "2026-08-03"


# A small, appendable extension for high-value names and places already present
# in the D32 story slate. These are authoring inputs, not a learner-facing atlas
# pack: their story records establish why the subject belongs in this tranche,
# while the generated sentence remains invented and review-pending.
STORY_SLATE_SUBJECTS: tuple[dict[str, Any], ...] = (
    {
        "id": "historical.name.grainne-ni-mhaille",
        "kind": "name",
        "canonicalDisplay": "Gráinne Ní Mháille",
        "authoring_kind": "historical_name",
        "county": "mayo",
        "authoring_source": {
            "path": "content/audio/authoring/d32-county-harvest-uses.json",
            "record_id": "d32.mayo.grainne-1593",
            "supports": "pattern_only",
        },
    },
    {
        "id": "historical.name.sihtric",
        "kind": "name",
        "canonicalDisplay": "Sihtric",
        "authoring_kind": "historical_name",
        "county": "dublin",
        "authoring_source": {
            "path": "content/audio/authoring/d32-county-harvest-uses.json",
            "record_id": "d32.dublin.sihtric-penny",
            "supports": "pattern_only",
        },
    },
    {
        "id": "historical.name.flann-sinna",
        "kind": "name",
        "canonicalDisplay": "Flann Sinna",
        "authoring_kind": "historical_name",
        "county": "offaly",
        "authoring_source": {
            "path": "content/audio/authoring/d32-county-harvest-uses.json",
            "record_id": "d32.offaly.cross-of-the-scriptures",
            "supports": "pattern_only",
        },
    },
    {
        "id": "historical.name.aodh-o-neill",
        "kind": "name",
        "canonicalDisplay": "Aodh Ó Néill",
        "authoring_kind": "historical_name",
        "county": "donegal",
        "authoring_source": {
            "path": "content/audio/authoring/d32-county-harvest-uses.json",
            "record_id": "d32.donegal.flight-of-the-earls",
            "supports": "pattern_only",
        },
    },
    {
        "id": "historical.name.piaras-feiritear",
        "kind": "name",
        "canonicalDisplay": "Piaras Feiritéar",
        "authoring_kind": "historical_name",
        "county": "kerry",
        "authoring_source": {
            "path": "content/audio/authoring/d32-county-harvest-uses.json",
            "record_id": "d32.kerry.piaras-feiritear",
            "supports": "pattern_only",
        },
    },
    {
        "id": "place.rath-maolain",
        "kind": "place",
        "canonicalDisplay": "Ráth Maoláin",
        "variants": ["Rathmullan"],
        "placeProfile": {
            "placeKind": "town",
            "hierarchy": "Dún na nGall / Cill Mhic Réanáin / Cill Gharbháin / Donegal",
        },
        "authoring_source": {
            "path": "content/audio/authoring/d32-county-harvest-uses.json",
            "record_id": "d32.donegal.flight-of-the-earls",
            "supports": "pattern_only",
        },
    },
    {
        "id": "place.corca-dhuibhne",
        "kind": "place",
        "canonicalDisplay": "Corca Dhuibhne",
        "variants": ["Corkaguiny"],
        "placeProfile": {"placeKind": "barony", "hierarchy": "Ciarraí / Kerry"},
        "authoring_source": {
            "path": "content/audio/authoring/d32-county-harvest-uses.json",
            "record_id": "d32.kerry.piaras-feiritear",
            "supports": "pattern_only",
        },
    },
    {
        "id": "place.cuan-mo",
        "kind": "place",
        "canonicalDisplay": "Cuan Mó",
        "variants": ["Clew Bay"],
        "placeProfile": {
            "placeKind": "bay",
            "hierarchy": "Maigh Eo / Buiríos Umhaill / Muraisc / Mayo",
        },
        "authoring_source": {
            "path": "content/audio/authoring/d32-county-harvest-uses.json",
            "record_id": "d32.mayo.grainne-1593",
            "supports": "pattern_only",
        },
    },
    {
        "id": "place.carna",
        "kind": "place",
        "canonicalDisplay": "Carna",
        "variants": ["Carna"],
        "placeProfile": {
            "placeKind": "village",
            "hierarchy": "Gaillimh / Galway",
        },
        "authoring_source": {
            "path": "content/audio/authoring/d32-county-harvest-uses.json",
            "record_id": "d32.galway.joe-heaney-carna",
            "supports": "pattern_only",
        },
    },
)


COUNTY_SLUGS = {
    "Antrim": "antrim",
    "Armagh": "armagh",
    "Carlow": "carlow",
    "Cavan": "cavan",
    "Clare": "clare",
    "Cork": "cork",
    "Derry": "derry",
    "Donegal": "donegal",
    "Down": "down",
    "Dublin": "dublin",
    "Fermanagh": "fermanagh",
    "Galway": "galway",
    "Kerry": "kerry",
    "Kildare": "kildare",
    "Kilkenny": "kilkenny",
    "Laois": "laois",
    "Leitrim": "leitrim",
    "Limerick": "limerick",
    "Longford": "longford",
    "Louth": "louth",
    "Mayo": "mayo",
    "Meath": "meath",
    "Monaghan": "monaghan",
    "Offaly": "offaly",
    "Roscommon": "roscommon",
    "Sligo": "sligo",
    "Tipperary": "tipperary",
    "Tyrone": "tyrone",
    "Waterford": "waterford",
    "Westmeath": "westmeath",
    "Wexford": "wexford",
    "Wicklow": "wicklow",
}


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def load_a1_bulk_subjects() -> list[dict[str, Any]]:
    """Load Track A A1 authoring-only subjects; empty when the bulk file is absent."""
    if not A1_BULK_SUBJECTS_PATH.exists():
        return []
    payload = load_json(A1_BULK_SUBJECTS_PATH)
    subjects = payload.get("subjects")
    if not isinstance(subjects, list):
        return []
    return [subject for subject in subjects if isinstance(subject, dict) and subject.get("id")]


def authoring_subject_list() -> list[dict[str, Any]]:
    """Pilot pack + story-slate anchors + A1 bulk subjects, deduped by id."""
    merged: list[dict[str, Any]] = []
    seen: set[str] = set()
    for subject in [
        *load_json(SUBJECTS_PATH).get("subjects", []),
        *STORY_SLATE_SUBJECTS,
        *load_a1_bulk_subjects(),
    ]:
        subject_id = subject.get("id")
        if not isinstance(subject_id, str) or subject_id in seen:
            continue
        seen.add(subject_id)
        merged.append(subject)
    return merged


def expected_county(subject: dict[str, Any]) -> str | None:
    explicit_county = subject.get("county")
    if isinstance(explicit_county, str) and explicit_county in COUNTY_SLUGS.values():
        return explicit_county
    hierarchy = (subject.get("placeProfile") or {}).get("hierarchy") or ""
    english_county = hierarchy.rsplit("/", 1)[-1].strip()
    return COUNTY_SLUGS.get(english_county)


def logainm_match(subject: dict[str, Any], connection: sqlite3.Connection) -> dict[str, Any] | None:
    """Find a current foundation row by exact subject form and expected county."""
    place_profile = subject.get("placeProfile") or {}
    county = expected_county(subject)
    terms = [subject.get("canonicalDisplay", ""), *(subject.get("variants") or [])]
    terms = [term for term in terms if isinstance(term, str) and term.strip()]
    if not terms or county is None:
        return None
    marks = ",".join("?" for _ in terms)
    rows = connection.execute(
        f"""
        SELECT id, canonical, irish, english, place_kind, hierarchy, permalink
        FROM places
        WHERE canonical IN ({marks}) OR irish IN ({marks}) OR english IN ({marks})
        """,
        terms * 3,
    ).fetchall()
    if not rows:
        return None

    wanted_kind = str(place_profile.get("placeKind") or "").casefold()

    def score(row: tuple[Any, ...]) -> tuple[int, int, int]:
        _, canonical, irish, english, place_kind, hierarchy, _ = row
        exact_form = 0 if any(value in terms for value in (canonical, irish)) else 1
        kind_score = 0 if wanted_kind and wanted_kind in str(place_kind).casefold() else 1
        county_score = 0 if county.casefold() in str(hierarchy).casefold() else 1
        return county_score, kind_score + exact_form, int(row[0])

    county_rows = [row for row in rows if county.casefold() in str(row[5]).casefold()]
    chosen = sorted(county_rows or rows, key=score)[0]
    return {
        "id": int(chosen[0]),
        "canonical": chosen[1],
        "irish": chosen[2],
        "english": chosen[3],
        "place_kind": chosen[4],
        "hierarchy": chosen[5],
        "permalink": chosen[6],
    }


def family_index() -> dict[tuple[str, str], tuple[Path, dict[str, Any]]]:
    indexed: dict[tuple[str, str], tuple[Path, dict[str, Any]]] = {}
    for path in sorted(ROOT.glob(FAMILY_GLOB)):
        family = load_json(path)
        target = family.get("target") or {}
        indexed[(family.get("county", ""), target.get("citation_form", ""))] = (path, family)
    return indexed


def story_ref(family: dict[str, Any]) -> dict[str, str]:
    return copy.deepcopy(family["story_ref"])


def place_label(family: dict[str, Any]) -> str:
    return f"{family['county'].title()} / present-day Personal Atlas context"


def subject_family(
    indexed: dict[tuple[str, str], tuple[Path, dict[str, Any]]],
    subject: dict[str, Any],
) -> dict[str, Any] | None:
    """Resolve an authoring subject to an existing family in its county."""
    county = expected_county(subject)
    if county is None:
        return None
    if subject.get("kind") == "name":
        family = indexed.get((county, "ainm"), (None, None))[1]
        if family is None and subject.get("authoring_kind") == "historical_name":
            legacy_paths = sorted(ROOT.glob(LEGACY_NAME_FAMILY_GLOB.format(county=county)))
            if legacy_paths:
                family = load_json(legacy_paths[-1])
        if family is None and subject.get("authoring_kind") == "historical_name":
            family = indexed.get((county, "rí"), (None, None))[1]
        return family
    return place_family(indexed, subject)


def family_path(
    indexed: dict[tuple[str, str], tuple[Path, dict[str, Any]]],
    family: dict[str, Any],
) -> Path:
    for path, candidate in indexed.values():
        if candidate.get("id") == family.get("id"):
            return path
    county = family.get("county")
    for path in sorted(ROOT.glob(f"content/{county}/phrase-families/authoring-v2/*.v2.json")):
        if load_json(path).get("id") == family.get("id"):
            return path
    raise ValueError(f"family is not a canonical repository document: {family.get('id')!r}")


def place_family(indexed: dict[tuple[str, str], tuple[Path, dict[str, Any]]], subject: dict[str, Any]) -> dict[str, Any] | None:
    county = expected_county(subject)
    if county is None:
        return None
    place_kind = str((subject.get("placeProfile") or {}).get("placeKind") or "").casefold()
    if "city" in place_kind:
        preferred = ["cathair", "baile", "ainm", "áit"]
    elif "castle" in place_kind:
        preferred = ["caisleán", "áit", "ainm"]
    elif "island" in place_kind:
        preferred = ["oileán", "áit", "ainm"]
    elif any(token in place_kind for token in ("monastery", "abbey", "ecclesiastical")):
        preferred = ["mainistir", "áit", "ainm"]
    elif any(token in place_kind for token in ("town", "village", "settlement")):
        preferred = ["baile", "áit", "ainm"]
    else:
        preferred = ["áit", "baile", "ainm"]
    for citation in preferred:
        if (county, citation) in indexed:
            return indexed[(county, citation)][1]
    return None


def member_state(risk_flags: list[str]) -> dict[str, Any]:
    reasons = [
        "invented_text",
        "editorial_review_pending",
        "pedagogy_review_pending",
        "irish_language_review_pending",
        "audio_not_generated",
    ]
    if "source_ambiguity" in risk_flags:
        reasons.append("source_ambiguity")
    return {
        "authoring": {
            "status": "complete",
            "revision": 1,
            "author_ref": "track-a.personal-atlas-name-place-authoring",
            "completed_at": CREATED_AT,
        },
        "reviews": {
            "editorial": {"status": "pending", "record": None},
            "pedagogy": {"status": "pending", "record": None},
            "irish_language": {"status": "pending", "record": None},
        },
        "capture_request": {
            "status": "planned",
            "requested_by": None,
            "requested_at": None,
            "authorization": None,
            "batch_line_ids": [],
        },
        "audio_qa": {"status": "not_generated", "record": None, "batch_line_id": None},
        "learner_release": {"status": "blocked", "reasons": reasons},
    }


def make_member(
    family: dict[str, Any],
    subject: dict[str, Any],
    *,
    mode: str,
    text: str,
    english: str,
    exercise_id: str,
    use: str,
    logainm: dict[str, Any] | None,
) -> tuple[dict[str, Any], dict[str, Any]]:
    normalized = normalize_spoken_text(text)
    subject_id = subject["id"]
    family_id = family["id"]
    member_id = f"{family_id}.personal-atlas.{identifier_slug(subject_id)}.{mode}"
    response_family = "listenChoose" if mode == "context" else "freeTyping"
    role = "context_introduction" if mode == "context" else "dialogue_turn"
    stage = "introduction" if mode == "context" else "retrieval"
    subject_source = subject.get("authoring_source")
    source_refs: list[dict[str, str]] = [
        copy.deepcopy(subject_source)
        if isinstance(subject_source, dict)
        else {
            "path": "ios/AnTuras/Resources/personal-atlas-subjects.json",
            "record_id": subject_id,
            "supports": "pattern_only",
        }
    ]
    risk_flags = ["invented_text", "audio_pronunciation", "source_ambiguity"]
    if subject.get("authoring_kind") == "historical_name":
        risk_flags.append("historical_roleplay")
    if any(char in normalized for char in "áéíóúÁÉÍÓÚ"):
        risk_flags.append("fada")
    if logainm is not None:
        source_refs.append(
            {
                "path": "content/personal-atlas/logainm-v2-source-index.json",
                "record_id": f"logainm.{logainm['id']}",
                "supports": "pattern_only",
            }
        )
    source_refs.append(
        {
            "path": "content/audio/authoring/d32-county-harvest-uses.json",
            "record_id": exercise_id,
            "supports": "exercise_context",
        }
    )
    placement_ids = [placement["id"] for placement in family["atlas_placements"]]
    family_target = family["target"]
    member = {
        "id": member_id,
        "family_id": family_id,
        "target": {
            "lexeme_id": family_target["lexeme_id"],
            "citation_form": family_target["citation_form"],
            "sense_id": family_target["sense_id"],
            "part_of_speech": family_target["part_of_speech"],
            "target_form": family_target["citation_form"],
            "morphology": "atlas citation form; Personal Atlas context; provisional surrounding frame",
        },
        "irish": {
            "text": normalized,
            "normalized_text": normalized,
            "inventory_slug": canonical_audio_slug(normalized),
            "text_sha256": text_sha256(normalized),
        },
        "english": {
            "intent": english,
            "literal_note": "Invented pedagogical frame around a Personal Atlas subject; not an attested quotation or historical claim.",
        },
        "binding": {
            "county": family["county"],
            "story_ref": story_ref(family),
            "atlas_placement_ids": placement_ids,
            "place": {"id": f"personal-atlas.{family['county']}", "label": place_label(family)},
            "setting": (
                "historical_bounded"
                if subject.get("authoring_kind") == "historical_name"
                else "present_day"
            ),
            "learner_role": (
                "self_observer"
                if subject.get("authoring_kind") == "historical_name"
                else "present_day_self"
            ),
        },
        "learning": {
            "stages": [stage],
            "roles": [role],
            "dialect": (
                "standard Irish; provisional historical-name context"
                if subject.get("authoring_kind") == "historical_name"
                else "standard Irish; provisional name/place context"
            ),
            "register": (
                "neutral historical-bounded frame"
                if subject.get("authoring_kind") == "historical_name"
                else "neutral pedagogical frame"
            ),
            "purpose": use,
            "fixture_only": False,
        },
        "exercise_consumers": [
            {
                "path": "content/audio/authoring/d32-county-harvest-uses.json",
                "record_id": exercise_id,
                "response_family": response_family,
                "container": "none",
                "use": use,
            }
        ],
        "provenance": {
            "origin": "invented_pedagogical",
            "invented": True,
            "composition_note": (
                "Deterministically composed around a county/story subject and the current bundled Logainm foundation snapshot where a matching row exists; the sentence is not attested and makes no historical claim."
                if subject.get("authoring_source")
                else "Deterministically composed around a Personal Atlas subject and the current bundled Logainm foundation snapshot where a matching row exists; the sentence is not attested and makes no historical claim."
            ),
            "source_refs": source_refs,
        },
        "states": member_state(risk_flags),
        "risk_flags": sorted(set(risk_flags)),
    }
    exercise = {
        "id": exercise_id,
        "county": family["county"],
        "story_ref": family["story_ref"]["record_id"],
        "kind": "exercise",
        "exercise": {
            "family": response_family,
            "prompt": "Listen for the Personal Atlas name or place-name context.",
            "answer": english,
            "translation": english,
            "audioText": None,
            "modelText": normalized,
            "phraseFamilyMemberIDs": [member_id],
        },
    }
    return member, exercise


def main() -> int:
    subjects = load_json(SUBJECTS_PATH)["subjects"]
    a1_bulk_subjects = load_a1_bulk_subjects()
    authoring_subjects = authoring_subject_list()
    uses = load_json(USES_PATH)
    indexed = family_index()
    name_families = sorted(
        (family for (county, citation), (_, family) in indexed.items() if citation == "ainm"),
        key=lambda family: family["county"],
    )
    if not name_families:
        raise SystemExit("no existing ainm families found")

    connection = sqlite3.connect(FOUNDATION_PATH)
    logainm_by_subject = {
        subject["id"]: logainm_match(subject, connection)
        for subject in authoring_subjects
        if subject.get("kind") == "place"
    }
    metadata = dict(connection.execute("SELECT key, value FROM metadata").fetchall())
    logainm_source_index = {
        "schema_version": 1,
        "contract": "personal_atlas_logainm_v2_source_index",
        "snapshot": metadata.get("version"),
        "content_date": metadata.get("contentDate"),
        "attribution": metadata.get("attribution"),
        "records": [
            {
                **row,
                "id": f"logainm.{row['id']}",
            }
            for row in sorted(
                (row for row in logainm_by_subject.values() if row is not None),
                key=lambda row: row["id"],
            )
        ],
    }
    changed: dict[Path, dict[str, Any]] = {}
    desired_place_families = {
        subject["id"]: (place_family(indexed, subject) or {}).get("id")
        for subject in authoring_subjects
        if subject.get("kind") == "place"
    }
    place_slugs = {
        subject_id: identifier_slug(subject_id)
        for subject_id in desired_place_families
    }
    removed_member_ids: set[str] = set()
    for path, family in indexed.values():
        retained_members = []
        for member in family.get("members", []):
            member_id = member.get("id", "") if isinstance(member, dict) else ""
            moved_subject = next(
                (
                    subject_id
                    for subject_id, desired_family_id in desired_place_families.items()
                    if desired_family_id
                    and desired_family_id != family["id"]
                    and f".personal-atlas.{place_slugs[subject_id]}." in member_id
                ),
                None,
            )
            if moved_subject is not None:
                removed_member_ids.add(member_id)
            else:
                retained_members.append(member)
        if len(retained_members) != len(family.get("members", [])):
            changed[path] = copy.deepcopy(family)
            changed[path]["members"] = retained_members
    if removed_member_ids:
        uses["exercises"] = [
            exercise
            for exercise in uses.get("exercises", [])
            if not removed_member_ids.intersection(
                set((exercise.get("exercise") or {}).get("phraseFamilyMemberIDs", []))
            )
        ]
    families_after_cleanup = [
        changed.get(path, family) for path, family in indexed.values()
    ]
    existing_member_ids = {
        member["id"]
        for family in families_after_cleanup
        for member in family.get("members", [])
        if isinstance(member, dict) and isinstance(member.get("id"), str)
    }
    # Legacy ainm.name-noun.v2.json families are outside FAMILY_GLOB but already hold
    # story-slate Personal Atlas members; include them so regeneration stays idempotent.
    for legacy_path in sorted(ROOT.glob("content/*/phrase-families/authoring-v2/*.v2.json")):
        legacy_family = changed.get(legacy_path) or load_json(legacy_path)
        for member in legacy_family.get("members", []):
            if isinstance(member, dict) and isinstance(member.get("id"), str):
                existing_member_ids.add(member["id"])
    existing_exercise_ids = {
        exercise["id"]
        for exercise in uses.get("exercises", [])
        if isinstance(exercise, dict) and isinstance(exercise.get("id"), str)
    }
    covered_subjects: list[str] = []
    skipped_subjects: list[dict[str, str]] = []
    added_members = 0
    added_exercises = 0
    changed_family_ids: set[str] = set()
    changed_family_ids.update(family["id"] for family in changed.values())
    name_index = 0

    try:
        for subject in authoring_subjects:
            kind = subject.get("kind")
            county = expected_county(subject) if kind == "place" else None
            if kind == "name":
                family = subject_family(indexed, subject)
                if family is None and subject.get("authoring_kind") != "historical_name":
                    family = name_families[name_index % len(name_families)]
                    name_index += 1
            elif kind == "place":
                family = place_family(indexed, subject)
                if family is None:
                    skipped_subjects.append(
                        {"subject_id": subject["id"], "reason": "no compatible county place family in the v2 atlas contract"}
                    )
                    continue
            else:
                continue

            path = family_path(indexed, family)
            target_name = subject["canonicalDisplay"]
            logainm = logainm_by_subject.get(subject["id"]) if kind == "place" else None
            is_given = (subject.get("nameProfile") or {}).get("nameKind") == "given"
            if subject.get("authoring_kind") == "historical_name":
                if family["target"]["citation_form"] == "rí":
                    context_text = f"Is rí é {target_name}."
                    context_english = f"{target_name} is a king."
                    dialogue_text = f"An rí é {target_name}?"
                    dialogue_english = f"Is {target_name} a king?"
                else:
                    context_text = f"Is ainm stairiúil é {target_name}."
                    context_english = f"{target_name} is a historical name."
                    dialogue_text = f"An é {target_name} an t-ainm stairiúil?"
                    dialogue_english = f"Is {target_name} the historical name?"
            elif kind == "name" and is_given:
                context_text = f"Is é {target_name} an t-ainm."
                context_english = f"{target_name} is the name."
                dialogue_text = f"An é {target_name} d’ainm?"
                dialogue_english = f"Is {target_name} your name?"
            elif kind == "name":
                context_text = f"Is é {target_name} an t-ainm teaghlaigh."
                context_english = f"{target_name} is the family name."
                dialogue_text = f"An é {target_name} d’ainm teaghlaigh?"
                dialogue_english = f"Is {target_name} your family name?"
            else:
                citation = family["target"]["citation_form"]
                if citation == "cathair":
                    context_text = f"Is cathair í {target_name}."
                    context_english = f"{target_name} is a city."
                    dialogue_text = f"An cathair í {target_name}?"
                    dialogue_english = f"Is {target_name} a city?"
                elif citation == "baile":
                    context_text = f"Is baile é {target_name}."
                    context_english = f"{target_name} is a town or settlement."
                    dialogue_text = f"An baile é {target_name}?"
                    dialogue_english = f"Is {target_name} a town or settlement?"
                elif citation == "caisleán":
                    context_text = f"Is caisleán é {target_name}."
                    context_english = f"{target_name} is a castle."
                    dialogue_text = f"An caisleán é {target_name}?"
                    dialogue_english = f"Is {target_name} a castle?"
                elif citation == "oileán":
                    context_text = f"Is oileán é {target_name}."
                    context_english = f"{target_name} is an island."
                    dialogue_text = f"An t-oileán é {target_name}?"
                    dialogue_english = f"Is {target_name} the island?"
                elif citation == "mainistir":
                    context_text = f"Is mainistir é {target_name}."
                    context_english = f"{target_name} is a monastery."
                    dialogue_text = f"An mainistir é {target_name}?"
                    dialogue_english = f"Is {target_name} a monastery?"
                elif citation == "ainm":
                    context_text = f"Is ainm áite é {target_name}."
                    context_english = f"{target_name} is a place-name."
                    dialogue_text = f"An ainm áite é {target_name}?"
                    dialogue_english = f"Is {target_name} a place-name?"
                else:
                    context_text = f"Is áit í {target_name}."
                    context_english = f"{target_name} is a place."
                    dialogue_text = f"An áit í {target_name}?"
                    dialogue_english = f"Is {target_name} a place?"

            subject_slug = identifier_slug(subject["id"])
            county_tag = family["county"]
            for mode, text, english in (
                ("context", context_text, context_english),
                ("dialogue", dialogue_text, dialogue_english),
            ):
                exercise_id = f"personal-atlas.{identifier_slug(family['id'])}.{subject_slug}.{mode}"
                use = (
                    f"Introduce the Personal Atlas {'given or family name' if kind == 'name' else 'place-name'} {target_name} in a present-day county context."
                    if mode == "context"
                    else f"Retrieve the Personal Atlas {'given or family name' if kind == 'name' else 'place-name'} {target_name} in a short dialogue."
                )
                member, exercise = make_member(
                    family,
                    subject,
                    mode=mode,
                    text=text,
                    english=english,
                    exercise_id=exercise_id,
                    use=use,
                    logainm=logainm,
                )
                if member["id"] in existing_member_ids or exercise_id in existing_exercise_ids:
                    continue
                changed.setdefault(path, copy.deepcopy(family))["members"].append(member)
                uses["exercises"].append(exercise)
                existing_member_ids.add(member["id"])
                existing_exercise_ids.add(exercise_id)
                added_members += 1
                added_exercises += 1
                changed_family_ids.add(family["id"])
            covered_subjects.append(subject["id"])

        for path, family in changed.items():
            family["members"] = sorted(family["members"], key=lambda member: member["id"])
            write_json(path, family)
        uses["exercises"] = sorted(uses["exercises"], key=lambda exercise: exercise.get("id", ""))
        write_json(USES_PATH, uses)
    finally:
        connection.close()

    subject_by_slug = {
        identifier_slug(subject["id"]): subject
        for subject in authoring_subjects
        if subject.get("kind") == "place"
    }
    for path, family in indexed.values():
        candidate = changed.get(path)
        for member in (candidate or family).get("members", []):
            member_id = member.get("id", "") if isinstance(member, dict) else ""
            if ".personal-atlas.place-" not in member_id:
                continue
            suffix = member_id.split(".personal-atlas.", 1)[1]
            subject_slug = suffix.rsplit(".", 1)[0]
            subject = subject_by_slug.get(subject_slug)
            if subject is None:
                continue
            current_match = logainm_by_subject.get(subject["id"])
            provenance = member.get("provenance") or {}
            refs = [
                ref
                for ref in provenance.get("source_refs", [])
                if ref.get("path") != "ios/AnTuras/Resources/personal-atlas-foundation.sqlite"
            ]
            if current_match is not None:
                source_ref = {
                    "path": "content/personal-atlas/logainm-v2-source-index.json",
                    "record_id": f"logainm.{current_match['id']}",
                    "supports": "pattern_only",
                }
                if source_ref not in refs:
                    refs.insert(1, source_ref)
            if refs != provenance.get("source_refs"):
                if path not in changed:
                    changed[path] = copy.deepcopy(family)
                    changed_family_ids.add(changed[path]["id"])
                for changed_member in changed[path]["members"]:
                    if changed_member.get("id") == member_id:
                        changed_member.setdefault("provenance", {})["source_refs"] = refs
                        break

    for path, family in changed.items():
        family["members"] = sorted(family["members"], key=lambda member: member["id"])
        write_json(path, family)
    write_json(LOGAINM_SOURCE_INDEX_PATH, logainm_source_index)

    print(
        json.dumps(
            {
                "status": "generated",
                "families_changed": len(changed_family_ids),
                "members_added": added_members,
                "exercises_added": added_exercises,
                "subjects_covered": len(covered_subjects),
                "names_covered": sum(
                    subject.get("kind") == "name"
                    for subject in authoring_subjects
                    if subject["id"] in covered_subjects
                ),
                "places_covered": sum(
                    subject.get("kind") == "place"
                    for subject in authoring_subjects
                    if subject["id"] in covered_subjects
                ),
                "story_slate_subjects": len(STORY_SLATE_SUBJECTS),
                "a1_bulk_subjects": len(a1_bulk_subjects),
                "authoring_subjects_total": len(authoring_subjects),
                "pilot_subjects": len(subjects),
                "skipped_subjects": skipped_subjects,
                "logainm_source_snapshot": "ios/AnTuras/Resources/personal-atlas-foundation.sqlite",
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
