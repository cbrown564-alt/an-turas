#!/usr/bin/env python3
"""Author D32 mutation / fada / minimal-pair contrast families offline.

Bulk Track A avenue A3. Creates complete v2 contrast families with exercise
consumers, provenance, and risk flags. Never calls a speech provider.

Catalog: content/audio/authoring/d32-contrast-catalog-a3.json
Priority inputs: Mayo atlas headwords, then risk-sample strata
(mutations / fadas / names / places / high_risk).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.structured_audio_authoring import (
    atlas_placements,
    canonical_audio_slug,
    identifier_slug,
    normalize_spoken_text,
    text_sha256,
)


ROOT = Path(__file__).resolve().parents[1]
STORE_REL = Path("content/audio/authoring/phrase-family-store-v2.json")
USES_REL = Path("content/audio/authoring/d32-county-harvest-uses.json")
ATLAS_REL = Path("content/audio/atlas-headwords-v1.json")
CATALOG_REL = Path("content/audio/authoring/d32-contrast-catalog-a3.json")
RISK_SAMPLE_REL = Path(
    "content/audio/authoring/sampling/d32-risk-stratification-2026-08-02.json"
)
STORE_PATH = ROOT / STORE_REL
USES_PATH = ROOT / USES_REL
ATLAS_PATH = ROOT / ATLAS_REL
CATALOG_PATH = ROOT / CATALOG_REL
RISK_SAMPLE_PATH = ROOT / RISK_SAMPLE_REL
CREATED_AT = "2026-08-03"
AUTHOR_REF = "track-a.a3-mutation-fada-contrasts"
PRIORITY_STRATA = ("mutations", "fadas", "names", "places", "high_risk")

STORIES = {
    "antrim": "d32.antrim.fionn-mac-cumhaill",
    "armagh": "d32.armagh.book-of-armagh",
    "carlow": "d32.carlow.st-moling",
    "cavan": "d32.cavan.oreillys-east-breifne",
    "clare": "d32.clare.brian-boru-kincora",
    "cork": "d32.cork.nano-nagle",
    "derry": "d32.derry.city-walls-siege",
    "donegal": "d32.donegal.flight-of-the-earls",
    "down": "d32.down.patrick-saul",
    "dublin": "d32.dublin.sihtric-penny",
    "fermanagh": "d32.fermanagh.enniskillen-castle",
    "galway": "d32.galway.joe-heaney-carna",
    "kerry": "d32.kerry.piaras-feiritear",
    "kildare": "d32.kildare.brigid-fire",
    "kilkenny": "d32.kilkenny.alice-kyteler",
    "laois": "d32.laois.rock-of-dunamase",
    "leitrim": "d32.leitrim.brian-na-murtha",
    "limerick": "d32.limerick.treaty-of-limerick",
    "longford": "d32.longford.corlea-trackway",
    "louth": "d32.louth.cu-chulainn-cooley",
    "mayo": "d32.mayo.grainne-1593",
    "meath": "d32.meath.trim-de-lacy",
    "monaghan": "d32.monaghan.patrick-kavanagh",
    "offaly": "d32.offaly.cross-of-the-scriptures",
    "roscommon": "d32.roscommon.medb-rathcroghan",
    "sligo": "d32.sligo.yeats-ben-bulben",
    "tipperary": "d32.tipperary.cormac-chapel",
    "tyrone": "d32.tyrone.hugh-oneill-dungannon",
    "waterford": "d32.waterford.reginalds-tower",
    "westmeath": "d32.westmeath.st-fechin-fore",
    "wexford": "d32.wexford.bagenal-harvey-1798",
    "wicklow": "d32.wicklow.st-kevin-glendalough",
}

PLACE_LABELS = {
    "antrim": "Aontroim / Antrim",
    "armagh": "Ard Mhacha / Armagh",
    "carlow": "Ceatharlach / Carlow",
    "cavan": "an Cabhán / Cavan",
    "clare": "an Clár / Clare",
    "cork": "Corcaigh / Cork",
    "derry": "Doire / Derry",
    "donegal": "Dún na nGall / Donegal",
    "down": "an Dún / Down",
    "dublin": "Baile Átha Cliath / Dublin",
    "fermanagh": "Fear Manach / Fermanagh",
    "galway": "na Gaillimhe / Galway",
    "kerry": "Ciarraí / Kerry",
    "kildare": "Cill Dara / Kildare",
    "kilkenny": "Cill Chainnigh / Kilkenny",
    "laois": "Laois",
    "leitrim": "Liatroim / Leitrim",
    "limerick": "Luimneach / Limerick",
    "longford": "an Longfort / Longford",
    "louth": "Lú / Louth",
    "mayo": "Maigh Eo / Mayo",
    "meath": "an Mhí / Meath",
    "monaghan": "Muineachán / Monaghan",
    "offaly": "Uíbh Fhailí / Offaly",
    "roscommon": "Ros Comáin / Roscommon",
    "sligo": "Sligeach / Sligo",
    "tipperary": "Tiobraid Árann / Tipperary",
    "tyrone": "Tír Eoghain / Tyrone",
    "waterford": "Port Láirge / Waterford",
    "westmeath": "an Iarmhí / Westmeath",
    "wexford": "Loch Garman / Wexford",
    "wicklow": "Cill Mhantáin / Wicklow",
}


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict[str, Any] | list[Any]) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def member_state(risk_flags: list[str]) -> dict[str, Any]:
    reasons = [
        "invented_text",
        "editorial_review_pending",
        "pedagogy_review_pending",
        "irish_language_review_pending",
        "audio_not_generated",
    ]
    return {
        "authoring": {
            "status": "complete",
            "revision": 1,
            "author_ref": AUTHOR_REF,
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


def existing_normalized_texts(root: Path) -> set[str]:
    texts: set[str] = set()
    for path in root.glob("content/*/phrase-families/authoring-v2/*.v2.json"):
        family = load_json(path)
        for member in family.get("members", []):
            if not isinstance(member, dict):
                continue
            irish = member.get("irish") or {}
            normalized = irish.get("normalized_text")
            if isinstance(normalized, str) and normalized.strip():
                texts.add(normalize_spoken_text(normalized))
    return texts


def risk_sample_counties(root: Path) -> set[str]:
    payload = load_json(root / RISK_SAMPLE_REL)
    samples = {row["sample_id"]: row for row in payload.get("samples", [])}
    counties: set[str] = set()
    for stratum in PRIORITY_STRATA:
        for sample_id in payload.get("strata", {}).get(stratum, {}).get(
            "selected_sample_ids", []
        ):
            sample = samples.get(sample_id) or {}
            for county in sample.get("counties") or []:
                if isinstance(county, str):
                    counties.add(county)
    return counties


def dialect_for(county: str) -> str:
    if county in {"mayo", "galway", "roscommon", "leitrim", "sligo"}:
        return "standard-with-Connacht-context"
    return "standard Irish; provisional county context"


def resolve_placement(
    placements: dict[str, dict[str, Any]], county: str, citation_form: str
) -> dict[str, Any]:
    for placement in placements.values():
        if placement["county"] == county and placement["citation_form"] == citation_form:
            return placement
    raise KeyError(f"No atlas placement for {county!r} / {citation_form!r}")


def risk_flags_for(entry: dict[str, Any]) -> list[str]:
    flags = {"invented_text", "audio_pronunciation"}
    for flag in entry.get("extra_risk") or entry.get("risk_flags") or []:
        if isinstance(flag, str):
            flags.add(flag)
    return sorted(flags)


def contrast_family(
    spec: dict[str, Any], placement: dict[str, Any]
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    county = spec["county"]
    story_id = STORIES[county]
    family_id = spec["id"]
    citation = spec["citation_form"]
    sense_id = f"{county}.{identifier_slug(citation)}.contrast"
    story_ref = {
        "path": "content/audio/authoring/d32-county-harvest-uses.json",
        "record_id": story_id,
    }
    family_target = {
        "lexeme_id": f"lex.{identifier_slug(citation)}",
        "citation_form": citation,
        "sense_id": sense_id,
        "part_of_speech": spec["part_of_speech"],
        "english_sense": spec["english_sense"],
    }
    members: list[dict[str, Any]] = []
    exercises: list[dict[str, Any]] = []
    for entry in spec["members"]:
        member_id = f"{family_id}.{entry['suffix']}"
        exercise_id = f"{story_id}.contrast.{family_id.rsplit('.', 1)[-1]}.{entry['suffix']}"
        normalized = normalize_spoken_text(entry["text"])
        roles = ["morphology_contrast", "listening_contrast"]
        purpose = (
            f"Controlled {spec['contrast_type']} contrast: {entry['english']}"
        )
        flags = risk_flags_for(entry)
        member = {
            "id": member_id,
            "family_id": family_id,
            "target": {
                **family_target,
                "target_form": entry["target_form"],
                "morphology": entry["morphology"],
            },
            "irish": {
                "text": normalized,
                "normalized_text": normalized,
                "inventory_slug": canonical_audio_slug(normalized),
                "text_sha256": text_sha256(normalized),
            },
            "english": {
                "intent": entry["english"],
                "literal_note": "Invented listening contrast frame; not attested text.",
            },
            "binding": {
                "county": county,
                "story_ref": dict(story_ref),
                "atlas_placement_ids": [placement["id"]],
                "place": {
                    "id": f"d32.{county}.place",
                    "label": PLACE_LABELS[county],
                },
                "setting": "present_day",
                "learner_role": "present_day_self",
            },
            "learning": {
                "stages": ["phrase_or_sentence_use"],
                "roles": roles,
                "dialect": dialect_for(county),
                "register": "neutral listening contrast",
                "purpose": purpose,
                "fixture_only": False,
            },
            "exercise_consumers": [
                {
                    "path": "content/audio/authoring/d32-county-harvest-uses.json",
                    "record_id": exercise_id,
                    "response_family": "listenChoose",
                    "container": "none",
                    "use": purpose,
                }
            ],
            "provenance": {
                "origin": "invented_pedagogical",
                "invented": True,
                "composition_note": (
                    "Deterministic mutation/fada/minimal-pair contrast member for "
                    "bulk Track A avenue A3; not attested text."
                ),
                "source_refs": [
                    {
                        "path": "content/audio/authoring/d32-county-harvest-uses.json",
                        "record_id": exercise_id,
                        "supports": "exercise_context",
                    }
                ],
            },
            "states": member_state(flags),
            "risk_flags": flags,
        }
        members.append(member)
        exercises.append(
            {
                "id": exercise_id,
                "county": county,
                "story_ref": story_id,
                "kind": "exercise",
                "exercise": {
                    "family": "listenChoose",
                    "prompt": "Listen for the contrast line.",
                    "answer": entry["english"],
                    "translation": entry["english"],
                    "audioText": normalized,
                    "modelText": None,
                    "phraseFamilyMemberIDs": [member_id],
                },
            }
        )
    family = {
        "schema_version": 2,
        "contract": "irish_phrase_family",
        "id": family_id,
        "county": county,
        "story_ref": story_ref,
        "target": family_target,
        "atlas_placements": [
            {
                "id": placement["id"],
                "gloss": placement.get("gloss") or spec["english_sense"],
            }
        ],
        "status": "draft",
        "claims": {
            "linguistic_approval": False,
            "historical_authenticity": False,
            "note": "D32 contrast family; invented pedagogical listening frames only.",
        },
        "members": members,
    }
    return family, exercises


def generate(root: Path = ROOT, *, dry_run: bool = False) -> dict[str, Any]:
    catalog = load_json(root / CATALOG_REL)
    store = load_json(root / STORE_REL)
    uses = load_json(root / USES_REL)
    placements = atlas_placements(load_json(root / ATLAS_REL))
    existing_family_ids = {ref["family_id"] for ref in store.get("family_documents", [])}
    existing_exercise_ids = {
        exercise["id"]
        for exercise in uses.get("exercises", [])
        if isinstance(exercise, dict) and isinstance(exercise.get("id"), str)
    }
    known_texts = existing_normalized_texts(root)
    priority_counties = risk_sample_counties(root) | {"mayo"}

    families_added = 0
    members_added = 0
    exercises_added = 0
    skipped_existing = 0
    skipped_duplicate_text = 0
    new_family_refs: list[dict[str, str]] = []
    contrast_type_counts: dict[str, int] = {}
    county_counts: dict[str, int] = {}
    unique_texts: set[str] = set()

    specs = list(catalog.get("families") or [])
    # Mayo first, then risk-sample counties, then remaining.
    def sort_key(spec: dict[str, Any]) -> tuple[int, str]:
        county = spec["county"]
        if county == "mayo":
            return (0, spec["id"])
        if county in priority_counties:
            return (1, spec["id"])
        return (2, spec["id"])

    for spec in sorted(specs, key=sort_key):
        family_id = spec["id"]
        rel_path = (
            f"content/{spec['county']}/phrase-families/authoring-v2/{family_id}.v2.json"
        )
        path = root / rel_path
        if family_id in existing_family_ids and path.is_file():
            skipped_existing += 1
            continue
        placement = resolve_placement(
            placements, spec["county"], spec["citation_form"]
        )
        family, exercises = contrast_family(spec, placement)
        member_texts = [
            normalize_spoken_text(member["irish"]["normalized_text"])
            for member in family["members"]
        ]
        if any(text in known_texts for text in member_texts):
            skipped_duplicate_text += 1
            continue
        if not dry_run:
            path.parent.mkdir(parents=True, exist_ok=True)
            write_json(path, family)
        new_family_refs.append({"family_id": family_id, "path": rel_path})
        families_added += 1
        members_added += len(family["members"])
        county_counts[spec["county"]] = county_counts.get(spec["county"], 0) + len(
            family["members"]
        )
        contrast_type_counts[spec["contrast_type"]] = contrast_type_counts.get(
            spec["contrast_type"], 0
        ) + len(family["members"])
        for text in member_texts:
            known_texts.add(text)
            unique_texts.add(text)
        for exercise in exercises:
            if exercise["id"] in existing_exercise_ids:
                continue
            if not dry_run:
                uses["exercises"].append(exercise)
            existing_exercise_ids.add(exercise["id"])
            exercises_added += 1
        existing_family_ids.add(family_id)

    if new_family_refs and not dry_run:
        store["family_documents"] = sorted(
            [*store.get("family_documents", []), *new_family_refs],
            key=lambda row: row["family_id"],
        )
        write_json(root / STORE_REL, store)
        uses["exercises"] = sorted(
            uses["exercises"], key=lambda row: row.get("id", "")
        )
        write_json(root / USES_REL, uses)

    return {
        "status": "dry_run" if dry_run else "generated",
        "contrast_families_added": families_added,
        "contrast_members_added": members_added,
        "unique_texts_added": len(unique_texts),
        "exercises_added": exercises_added,
        "skipped_existing_families": skipped_existing,
        "skipped_duplicate_text_families": skipped_duplicate_text,
        "contrast_type_counts": dict(sorted(contrast_type_counts.items())),
        "county_counts": dict(sorted(county_counts.items())),
        "priority_counties": sorted(priority_counties),
        "family_paths": [ref["path"] for ref in new_family_refs],
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report what would be authored without writing files.",
    )
    args = parser.parse_args(argv)
    result = generate(ROOT, dry_run=args.dry_run)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
