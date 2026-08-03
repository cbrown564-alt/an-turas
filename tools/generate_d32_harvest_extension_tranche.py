#!/usr/bin/env python3
"""Append the next D32 harvest extension tranche offline.

Adds, in one deterministic pass:
- county story-transition members (shared Irish, county-bound exercise records);
- mutation/fada contrast families with repository-bound pedagogy examples;
- store registration for new contrast families.

This tool never calls a speech provider.
"""

from __future__ import annotations

import copy
import json
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.structured_audio_authoring import (
    canonical_audio_slug,
    text_sha256,
)


ROOT = Path(__file__).resolve().parents[1]
STORE_PATH = ROOT / "content/audio/authoring/phrase-family-store-v2.json"
USES_PATH = ROOT / "content/audio/authoring/d32-county-harvest-uses.json"
PEDAGOGY_PATH = ROOT / "content/pedagogy/irish-explanations-v1.json"
CREATED_AT = "2026-08-03"

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

TRANSITION_TEXT = "Anois, fillimis ar an scéal."
TRANSITION_ENGLISH = "Now, let us return to the story."

CONTRAST_FAMILIES: tuple[dict[str, Any], ...] = (
    {
        "id": "d32.mayo.contrast.sean-fada",
        "county": "mayo",
        "story_id": "d32.mayo.grainne-1593",
        "citation_form": "ainm",
        "english_sense": "name",
        "placement_id": "atlas.mayo.14.ainm",
        "members": (
            {
                "suffix": "name-given",
                "text": "Is é Seán an t-ainm.",
                "english": "Seán is the name.",
                "target_form": "ainm",
                "morphology": "given name with fada in a name frame",
                "roles": ["morphology_contrast", "listening_contrast"],
                "risk_flags": ["invented_text", "audio_pronunciation", "fada", "named_entity"],
            },
            {
                "suffix": "adjective-old",
                "text": "Ní hainm é sin; tá an teach sean.",
                "english": "That is not the name; the house is old.",
                "target_form": "ainm",
                "morphology": "name frame contrasted with adjective sean without fada",
                "roles": ["morphology_contrast", "listening_contrast"],
                "risk_flags": ["invented_text", "audio_pronunciation", "fada", "initial_mutation"],
            },
        ),
    },
)


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict[str, Any]) -> None:
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
            "author_ref": "track-a.d32-harvest-extension",
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


def family_target_citation(family: dict[str, Any]) -> str:
    return str((family.get("target") or {}).get("citation_form") or "")


def transition_member(family: dict[str, Any], *, exercise_id: str) -> dict[str, Any]:
    normalized = TRANSITION_TEXT
    member_id = f"{family['id']}.story-transition"
    family_target = family["target"]
    target_form = str(family_target.get("citation_form") or "")
    target = copy.deepcopy(family_target)
    target["target_form"] = target_form
    return {
        "id": member_id,
        "family_id": family["id"],
        "target": target,
        "irish": {
            "text": normalized,
            "normalized_text": normalized,
            "inventory_slug": canonical_audio_slug(normalized),
            "text_sha256": text_sha256(normalized),
        },
        "english": {
            "intent": TRANSITION_ENGLISH,
            "literal_note": "Invented reusable county story transition; not attested dialogue.",
        },
        "binding": {
            "county": family["county"],
            "story_ref": copy.deepcopy(family["story_ref"]),
            "atlas_placement_ids": [family["atlas_placements"][0]["id"]],
            "place": {
                "id": f"d32.{family['county']}.place",
                "label": PLACE_LABELS[family["county"]],
            },
            "setting": "present_day",
            "learner_role": "present_day_self",
        },
        "learning": {
            "stages": ["later_reuse"],
            "roles": ["story_recap"],
            "dialect": "standard Irish; provisional county context",
            "register": "neutral pedagogical frame",
            "purpose": "Return from a place or name beat to the county story thread.",
            "fixture_only": False,
        },
        "exercise_consumers": [
            {
                "path": "content/audio/authoring/d32-county-harvest-uses.json",
                "record_id": exercise_id,
                "response_family": "listenChoose",
                "container": "none",
                "use": "Return from a place or name beat to the county story thread.",
            }
        ],
        "provenance": {
            "origin": "invented_pedagogical",
            "invented": True,
            "composition_note": "Deterministic reusable story-transition frame for the D32 harvest extension tranche; not attested text.",
            "source_refs": [
                {
                    "path": "content/audio/authoring/d32-county-harvest-uses.json",
                    "record_id": exercise_id,
                    "supports": "exercise_context",
                }
            ],
        },
        "states": member_state(["invented_text", "audio_pronunciation"]),
        "risk_flags": ["invented_text", "audio_pronunciation", "fada", "initial_mutation"],
    }


def transition_exercise(*, exercise_id: str, story_id: str, county: str, member_id: str) -> dict[str, Any]:
    return {
        "id": exercise_id,
        "county": county,
        "story_ref": story_id,
        "kind": "exercise",
        "exercise": {
            "family": "listenChoose",
            "prompt": "Listen for the return-to-story line.",
            "answer": TRANSITION_ENGLISH,
            "translation": TRANSITION_ENGLISH,
            "audioText": TRANSITION_TEXT,
            "modelText": None,
            "phraseFamilyMemberIDs": [member_id],
        },
    }


def contrast_family(spec: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    county = spec["county"]
    story_id = spec["story_id"]
    family_id = spec["id"]
    members: list[dict[str, Any]] = []
    exercises: list[dict[str, Any]] = []
    for entry in spec["members"]:
        member_id = f"{family_id}.{entry['suffix']}"
        exercise_id = f"{story_id}.contrast.{entry['suffix']}"
        normalized = entry["text"]
        member = {
            "id": member_id,
            "family_id": family_id,
            "target": {
                "lexeme_id": f"lex.{spec['citation_form'].casefold()}",
                "citation_form": spec["citation_form"],
                "sense_id": f"{county}.contrast.{entry['suffix']}",
                "part_of_speech": "noun",
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
                "story_ref": {
                    "path": "content/audio/authoring/d32-county-harvest-uses.json",
                    "record_id": story_id,
                },
                "atlas_placement_ids": [spec["placement_id"]],
                "place": {
                    "id": f"d32.{county}.place",
                    "label": PLACE_LABELS[county],
                },
                "setting": "present_day",
                "learner_role": "present_day_self",
            },
            "learning": {
                "stages": ["phrase_or_sentence_use"],
                "roles": list(entry["roles"]),
                "dialect": "standard-with-Connacht-context",
                "register": "neutral listening contrast",
                "purpose": f"Controlled fada/mutation contrast: {entry['english']}",
                "fixture_only": False,
            },
            "exercise_consumers": [
                {
                    "path": "content/audio/authoring/d32-county-harvest-uses.json",
                    "record_id": exercise_id,
                    "response_family": "listenChoose",
                    "container": "none",
                    "use": f"Controlled fada/mutation contrast: {entry['english']}",
                }
            ],
            "provenance": {
                "origin": "invented_pedagogical",
                "invented": True,
                "composition_note": "Deterministic mutation/fada contrast member for the D32 harvest extension tranche; not attested text.",
                "source_refs": [
                    {
                        "path": "content/audio/authoring/d32-county-harvest-uses.json",
                        "record_id": exercise_id,
                        "supports": "exercise_context",
                    }
                ],
            },
            "states": member_state(list(entry["risk_flags"])),
            "risk_flags": sorted(set(entry["risk_flags"])),
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
        "story_ref": {
            "path": "content/audio/authoring/d32-county-harvest-uses.json",
            "record_id": story_id,
        },
        "target": {
            "lexeme_id": f"lex.{spec['citation_form'].casefold()}",
            "citation_form": spec["citation_form"],
            "sense_id": f"{county}.contrast.{spec['citation_form'].casefold()}",
            "part_of_speech": "noun",
            "english_sense": spec["english_sense"],
        },
        "atlas_placements": [{"id": spec["placement_id"], "gloss": spec["english_sense"]}],
        "status": "draft",
        "claims": {
            "linguistic_approval": False,
            "historical_authenticity": False,
            "note": "D32 contrast family; invented pedagogical listening frames only.",
        },
        "members": members,
    }
    return family, exercises


def append_pedagogy_lessons(root: Path) -> int:
    payload = load_json(root / PEDAGOGY_PATH.relative_to(root))
    existing_ids = {lesson["id"] for lesson in payload["lessons"]}
    additions = [
        {
            "id": "pronunciation.sean-fada-contrast",
            "title": "Hear the fada on the name",
            "area": "pronunciation",
            "memory_hook": "Seán keeps the fada on the name; sean without it names oldness, not the person.",
            "scope": "Two exact Mayo contrast members; this is a listening cue, not a complete account of every use of sean or Seán.",
            "lines": [
                {
                    "id": "pronunciation.sean-fada-contrast.framing",
                    "kind": "framing",
                    "english": "Use two repository lines to separate a given name from an everyday adjective: Seán is the name; sean describes the house.",
                    "irish_examples": ["Is é Seán an t-ainm.", "Tá an teach sean."],
                    "source_refs": [
                        {
                            "path": "content/mayo/phrase-families/authoring-v2/d32.mayo.contrast.sean-fada.v2.json",
                            "record_id": "d32.mayo.contrast.sean-fada.name-given",
                            "field": "members[id=d32.mayo.contrast.sean-fada.name-given].irish.text",
                            "supports": "repository_text",
                        },
                        {
                            "path": "content/mayo/phrase-families/authoring-v2/d32.mayo.contrast.sean-fada.v2.json",
                            "record_id": "d32.mayo.contrast.sean-fada.adjective-old",
                            "field": "members[id=d32.mayo.contrast.sean-fada.adjective-old].irish.text",
                            "supports": "repository_text",
                        },
                    ],
                    "provenance": {
                        "origin": "invented_pedagogical",
                        "invented": True,
                        "composition_note": "English framing is provisional Track D composition; both Irish examples are copied exactly from the cited contrast members.",
                    },
                    "risk_flags": [
                        "scope_guard",
                        "invented_text",
                        "explanation_claim",
                        "fada",
                        "named_entity",
                        "audio_pronunciation",
                    ],
                    "reviews": {
                        "pedagogy": {"status": "pending", "record": None},
                        "irish_language": {"status": "pending", "record": None},
                        "audio_pronunciation": {"status": "pending", "record": None},
                    },
                    "learner_release": {
                        "status": "blocked",
                        "reasons": [
                            "pedagogy_review_pending",
                            "irish_language_review_pending",
                            "audio_pronunciation_review_pending",
                            "corpus_not_runtime_bound",
                        ],
                    },
                },
                {
                    "id": "pronunciation.sean-fada-contrast.boundary",
                    "kind": "boundary",
                    "english": "This note stays with the two contrast lines. It does not claim that every Irish word spelled sean is an adjective, or that every Seán is pronounced the same in every dialect.",
                    "irish_examples": ["Is é Seán an t-ainm.", "Tá an teach sean."],
                    "source_refs": [
                        {
                            "path": "content/mayo/phrase-families/authoring-v2/d32.mayo.contrast.sean-fada.v2.json",
                            "record_id": "d32.mayo.contrast.sean-fada.name-given",
                            "field": "members[id=d32.mayo.contrast.sean-fada.name-given].irish.text",
                            "supports": "repository_text",
                        }
                    ],
                    "provenance": {
                        "origin": "invented_pedagogical",
                        "invented": True,
                        "composition_note": "Boundary language prevents overgeneralisation; no new Irish wording is introduced.",
                    },
                    "risk_flags": [
                        "scope_guard",
                        "invented_text",
                        "explanation_claim",
                        "fada",
                        "named_entity",
                        "audio_pronunciation",
                    ],
                    "reviews": {
                        "pedagogy": {"status": "pending", "record": None},
                        "irish_language": {"status": "pending", "record": None},
                        "audio_pronunciation": {"status": "pending", "record": None},
                    },
                    "learner_release": {
                        "status": "blocked",
                        "reasons": [
                            "pedagogy_review_pending",
                            "irish_language_review_pending",
                            "audio_pronunciation_review_pending",
                            "corpus_not_runtime_bound",
                        ],
                    },
                },
            ],
        },
        {
            "id": "grammar.story-transition",
            "title": "Return to the story thread",
            "area": "grammar",
            "memory_hook": "Anois marks the turn; fillimis keeps the move shared; ar an scéal names what you are returning to.",
            "scope": "One reusable county transition line copied exactly from the harvest extension tranche; do not treat it as attested historical dialogue.",
            "lines": [
                {
                    "id": "grammar.story-transition.example",
                    "kind": "example",
                    "english": "After a place or name beat, this line can return the learner to the county story without inventing new historical speech.",
                    "irish_examples": [TRANSITION_TEXT],
                    "source_refs": [
                        {
                            "path": "content/antrim/phrase-families/authoring-v2/d32.antrim.08.sceal.story.v2.json",
                            "record_id": "d32.antrim.08.sceal.story.story-transition",
                            "field": "members[id=d32.antrim.08.sceal.story.story-transition].irish.text",
                            "supports": "repository_text",
                        }
                    ],
                    "provenance": {
                        "origin": "invented_pedagogical",
                        "invented": True,
                        "composition_note": "English framing is provisional; the Irish line is copied from one representative county transition member.",
                    },
                    "risk_flags": [
                        "scope_guard",
                        "invented_text",
                        "explanation_claim",
                        "fada",
                        "initial_mutation",
                    ],
                    "reviews": {
                        "pedagogy": {"status": "pending", "record": None},
                        "irish_language": {"status": "pending", "record": None},
                        "audio_pronunciation": {"status": "pending", "record": None},
                    },
                    "learner_release": {
                        "status": "blocked",
                        "reasons": [
                            "pedagogy_review_pending",
                            "irish_language_review_pending",
                            "audio_pronunciation_review_pending",
                            "corpus_not_runtime_bound",
                        ],
                    },
                }
            ],
        },
    ]
    added = 0
    for lesson in additions:
        if lesson["id"] in existing_ids:
            continue
        payload["lessons"].append(lesson)
        added += 1
    if added:
        write_json(root / PEDAGOGY_PATH.relative_to(root), payload)
    return added


def main() -> int:
    uses = load_json(USES_PATH)
    store = load_json(STORE_PATH)
    existing_member_ids = {
        member["id"]
        for ref in store.get("family_documents", [])
        for member in load_json(ROOT / ref["path"]).get("members", [])
        if isinstance(member, dict) and isinstance(member.get("id"), str)
    }
    existing_exercise_ids = {
        exercise["id"]
        for exercise in uses.get("exercises", [])
        if isinstance(exercise, dict) and isinstance(exercise.get("id"), str)
    }
    existing_family_ids = {ref["family_id"] for ref in store.get("family_documents", [])}

    transitions_added = 0
    exercises_added = 0
    families_changed = 0
    contrast_members = 0

    for county in sorted(STORIES):
        candidates = sorted(ROOT.glob(f"content/{county}/phrase-families/authoring-v2/*sceal.story*.v2.json"))
        if not candidates:
            continue
        chosen_path = candidates[0]
        chosen_family = load_json(chosen_path)
        if family_target_citation(chosen_family) != "scéal":
            continue
        member_id = f"{chosen_family['id']}.story-transition"
        exercise_id = f"{STORIES[county]}.transition.shared"
        if member_id in existing_member_ids:
            continue
        member = transition_member(chosen_family, exercise_id=exercise_id)
        chosen_family = copy.deepcopy(chosen_family)
        chosen_family["members"].append(member)
        chosen_family["members"] = sorted(chosen_family["members"], key=lambda row: row["id"])
        write_json(chosen_path, chosen_family)
        if exercise_id not in existing_exercise_ids:
            uses["exercises"].append(
                transition_exercise(
                    exercise_id=exercise_id,
                    story_id=STORIES[county],
                    county=county,
                    member_id=member_id,
                )
            )
            existing_exercise_ids.add(exercise_id)
            exercises_added += 1
        existing_member_ids.add(member_id)
        transitions_added += 1
        families_changed += 1

    new_family_refs: list[dict[str, str]] = []
    for spec in CONTRAST_FAMILIES:
        rel_path = f"content/{spec['county']}/phrase-families/authoring-v2/{spec['id']}.v2.json"
        path = ROOT / rel_path
        if spec["id"] in existing_family_ids and path.is_file():
            continue
        family, exercises = contrast_family(spec)
        path.parent.mkdir(parents=True, exist_ok=True)
        write_json(path, family)
        new_family_refs.append({"family_id": family["id"], "path": rel_path})
        for exercise in exercises:
            if exercise["id"] not in existing_exercise_ids:
                uses["exercises"].append(exercise)
                existing_exercise_ids.add(exercise["id"])
                exercises_added += 1
        contrast_members += len(family["members"])
        existing_family_ids.add(family["id"])

    if new_family_refs:
        store["family_documents"] = sorted(
            [*store.get("family_documents", []), *new_family_refs],
            key=lambda row: row["family_id"],
        )
        write_json(STORE_PATH, store)

    uses["exercises"] = sorted(uses["exercises"], key=lambda row: row.get("id", ""))
    write_json(USES_PATH, uses)

    pedagogy_added = append_pedagogy_lessons(ROOT)

    print(
        json.dumps(
            {
                "status": "generated",
                "story_transitions_added": transitions_added,
                "contrast_families_added": len(new_family_refs),
                "contrast_members_added": contrast_members,
                "exercises_added": exercises_added,
                "families_changed": families_changed,
                "pedagogy_lessons_added": pedagogy_added,
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
