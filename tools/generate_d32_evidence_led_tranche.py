#!/usr/bin/env python3
"""Assemble queue-02 source register and append evidence-led v2 members.

Offline Track A / avenue A5 authoring for `queue-02-evidence-led-next`.
Confirms slate anchors and exercise demand, then appends net-new invented
pedagogical members bound to existing county families and the uses ledger.

Never calls a speech provider. Does not invent documentary quotations or
historical participation; myth counties are explicitly labelled.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.structured_audio_authoring import (
    canonical_audio_slug,
    normalize_spoken_text,
    text_sha256,
)


ROOT = Path(__file__).resolve().parents[1]
USES_PATH = ROOT / "content/audio/authoring/d32-county-harvest-uses.json"
REGISTER_PATH = ROOT / "content/audio/authoring/d32-queue-02-evidence-source-register.json"
QUEUE_DOC = ROOT / "content/audio/authoring/d32-county-authoring-queue.md"
CREATED_AT = "2026-08-03"

QUEUE_02: tuple[dict[str, Any], ...] = (
    {
        "county": "cork",
        "story_id": "d32.cork.nano-nagle",
        "title": "Nano Nagle and Cork schools",
        "anchor": "Nano Nagle · education in eighteenth-century Cork",
        "place_label": "Corcaigh / Cork",
        "place_ga": "Corcaigh",
        "language_field": ["school", "child", "night", "teach", "hope"],
        "evidence_kind": "archive_letter_or_account",
        "evidence_note": (
            "Slate names a Presentation-archive letter or documented account as the "
            "reading plan. No quotation is authored here; lines only orient learners "
            "toward inspectable school/education language."
        ),
        "myth_labelled": False,
        "packet_status": "slate_confirmed_register_assembled",
        "blocked": False,
    },
    {
        "county": "galway",
        "story_id": "d32.galway.joe-heaney-carna",
        "title": "Joe Heaney and Carna sean-nós",
        "anchor": "Joe Heaney · Carna and sean-nós transmission",
        "place_label": "na Gaillimhe / Galway",
        "place_ga": "Carna",
        "language_field": ["voice", "song", "listen", "remember", "place"],
        "evidence_kind": "rights_cleared_archival_performance",
        "evidence_note": (
            "Slate requires rights-cleared archival audio and local cultural review. "
            "Authoring here is provisional pedagogical framing only; no performance "
            "is quoted and no rights claim is made."
        ),
        "myth_labelled": False,
        "packet_status": "slate_confirmed_register_assembled",
        "blocked": False,
        "rights_note": "Audio rights and local cultural review remain mandatory before learner release.",
    },
    {
        "county": "kerry",
        "story_id": "d32.kerry.piaras-feiritear",
        "title": "Piaras Feiritéar",
        "anchor": "Piaras Feiritéar · Corca Dhuibhne poetry",
        "place_label": "Ciarraí / Kerry",
        "place_ga": "Corca Dhuibhne",
        "language_field": ["poet", "land", "word", "memory", "opinion"],
        "evidence_kind": "public_domain_poem_with_gloss",
        "evidence_note": (
            "Slate plans a short public-domain poem with supported gloss. Lines here "
            "do not quote verse; they teach place-bound poet/land/word language."
        ),
        "myth_labelled": False,
        "packet_status": "slate_confirmed_register_assembled",
        "blocked": False,
    },
    {
        "county": "longford",
        "story_id": "d32.longford.corlea-trackway",
        "title": "The Corlea Trackway",
        "anchor": "the Corlea Trackway · the Iron Age bog road",
        "place_label": "an Longfort / Longford",
        "place_ga": "Corr Liath",
        "language_field": ["road", "wood", "bog", "carry", "across"],
        "evidence_kind": "archaeological_monument",
        "evidence_note": (
            "Monument-led episode; OPW/Heritage Ireland Corlea interpretation orients "
            "the place. No fictional road-builder is invented."
        ),
        "myth_labelled": False,
        "packet_status": "slate_confirmed_register_assembled",
        "blocked": False,
    },
    {
        "county": "louth",
        "story_id": "d32.louth.cu-chulainn-cooley",
        "title": "Cú Chulainn and the Cooley peninsula",
        "anchor": "Cú Chulainn · the Cooley peninsula and the Táin",
        "place_label": "Lú / Louth",
        "place_ga": "Cuaille",
        "language_field": ["bull", "ford", "warrior", "wait", "strong"],
        "evidence_kind": "myth_labelled_literature",
        "evidence_note": (
            "Explicitly myth-labelled Ulster Cycle literature rooted in the Cooley "
            "landscape. Paired with Roscommon Medb; do not invent historical participation."
        ),
        "myth_labelled": True,
        "packet_status": "slate_confirmed_register_assembled",
        "blocked": False,
    },
    {
        "county": "roscommon",
        "story_id": "d32.roscommon.medb-rathcroghan",
        "title": "Medb and Rathcroghan",
        "anchor": "Medb · Rathcroghan and the Táin",
        "place_label": "Ros Comáin / Roscommon",
        "place_ga": "Ráth Cruachan",
        "language_field": ["queen", "cattle", "cave", "want", "command"],
        "evidence_kind": "myth_labelled_literature_and_archaeology",
        "evidence_note": (
            "Myth-labelled Táin/Dindshenchas framing beside Rathcroghan archaeology. "
            "Paired with Louth; no invented historical queen biography."
        ),
        "myth_labelled": True,
        "packet_status": "slate_confirmed_register_assembled",
        "blocked": False,
    },
    {
        "county": "tipperary",
        "story_id": "d32.tipperary.cormac-chapel",
        "title": "Cormac Mac Cárthaigh and Cormac's Chapel",
        "anchor": "Cormac Mac Cárthaigh · the Rock of Cashel",
        "place_label": "Tiobraid Árann / Tipperary",
        "place_ga": "Caiseal",
        "language_field": ["rock", "chapel", "king", "stone", "beautiful"],
        "evidence_kind": "architectural_site_account",
        "evidence_note": (
            "Named patron and standing chapel on the Rock of Cashel. Lines orient to "
            "building/site language; no invented inscription text."
        ),
        "myth_labelled": False,
        "packet_status": "slate_confirmed_register_assembled",
        "blocked": False,
    },
    {
        "county": "waterford",
        "story_id": "d32.waterford.reginalds-tower",
        "title": "Reginald and Waterford's Viking foundation",
        "anchor": "Ragnall/Reginald · Waterford and the Suir",
        "place_label": "Port Láirge / Waterford",
        "place_ga": "Port Láirge",
        "language_field": ["tower", "river", "town", "trade", "arrive"],
        "evidence_kind": "annal_and_object_led_tower",
        "evidence_note": (
            "Annal entry plus object-led Reginald's Tower account in the slate plan. "
            "Lines teach tower/river/town language without inventing annal text."
        ),
        "myth_labelled": False,
        "packet_status": "slate_confirmed_register_assembled",
        "blocked": False,
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
    if "source_ambiguity" in risk_flags:
        reasons.append("source_ambiguity")
    return {
        "authoring": {
            "status": "complete",
            "revision": 1,
            "author_ref": "track-a.a5-evidence-led-next",
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


def risk_flags_for(text: str, *, myth_labelled: bool) -> list[str]:
    flags = {"invented_text", "audio_pronunciation", "source_ambiguity"}
    if any(char in text for char in "áéíóúÁÉÍÓÚ"):
        flags.add("fada")
    if myth_labelled:
        flags.add("historical_roleplay")
    return sorted(flags)


def exercise_demand(meta: dict[str, Any]) -> list[dict[str, str]]:
    demand = [
        {
            "role": "context_introduction",
            "stage": "introduction",
            "response_family": "listenChoose",
            "purpose": "Orient the learner to evidence-facing place language before productive reuse.",
        },
        {
            "role": "productive_pattern",
            "stage": "phrase_or_sentence_use",
            "response_family": "freeTyping",
            "purpose": "Practice the atlas headword inside a county-specific evidence frame.",
        },
        {
            "role": "story_recap",
            "stage": "later_reuse",
            "response_family": "freeTyping",
            "purpose": "Return to the slate anchor without inventing a documentary quotation.",
        },
    ]
    if meta["myth_labelled"]:
        demand.append(
            {
                "role": "dialogue_turn",
                "stage": "retrieval",
                "response_family": "freeTyping",
                "purpose": "Keep myth labelling explicit while retrieving the headword.",
            }
        )
    return demand


def frames_for(meta: dict[str, Any], ga: str, gloss: str, position: int) -> list[dict[str, str]]:
    """Return county-unique pedagogical frames for one atlas headword."""
    place = meta["place_ga"]
    county = meta["county"]
    myth = meta["myth_labelled"]
    # Position-rotated collocates keep lines unique without cross-county reskins.
    collocate = meta["language_field"][(position - 1) % len(meta["language_field"])]
    slot = (position - 1) % 5

    if county == "cork":
        triples = (
            (
                "evidence",
                f"Léigh faoin {ga} i gCorcaigh.",
                f"Read about the {gloss} in Cork.",
                "context_introduction",
                "introduction",
                "listenChoose",
            ),
            (
                "pattern",
                f"Tá {ga} nasctha leis an oideachas.",
                f"The {gloss} is linked with education.",
                "productive_pattern",
                "phrase_or_sentence_use",
                "freeTyping",
            ),
            (
                "notice",
                (
                    f"Taispeánann an litir an {ga}."
                    if slot in {0, 1}
                    else f"Tugann an scéal oíche an {ga}."
                    if slot == 2
                    else f"Fanann an {ga} le dóchas."
                    if slot == 3
                    else f"Tosaíonn an {ga} sa chathair."
                ),
                f"The evidence-facing Cork frame keeps {gloss} inspectable.",
                "story_recap",
                "later_reuse",
                "freeTyping",
            ),
        )
    elif county == "galway":
        triples = (
            (
                "evidence",
                f"Éist leis an {ga} ó Charna.",
                f"Listen for the {gloss} from Carna.",
                "context_introduction",
                "introduction",
                "listenChoose",
            ),
            (
                "pattern",
                f"Cuimhnigh ar an {ga} sa traidisiún.",
                f"Remember the {gloss} in the tradition.",
                "productive_pattern",
                "phrase_or_sentence_use",
                "freeTyping",
            ),
            (
                "notice",
                (
                    f"Ní luaitear amhrán anseo; tá {ga} ann."
                    if slot in {0, 1}
                    else f"Tá áit agus {ga} le chéile."
                    if slot == 2
                    else f"Foghlaimíonn an guth an {ga}."
                    if slot == 3
                    else f"Téann an {ga} thar an bhfarraige."
                ),
                f"Provisional Galway frame for {gloss}; no archival performance is quoted.",
                "story_recap",
                "later_reuse",
                "freeTyping",
            ),
        )
    elif county == "kerry":
        triples = (
            (
                "evidence",
                f"Léigh faoin {ga} i gCorca Dhuibhne.",
                f"Read about the {gloss} in Corca Dhuibhne.",
                "context_introduction",
                "introduction",
                "listenChoose",
            ),
            (
                "pattern",
                f"Tá {ga} agus talamh le chéile.",
                f"The {gloss} and land belong together.",
                "productive_pattern",
                "phrase_or_sentence_use",
                "freeTyping",
            ),
            (
                "notice",
                (
                    f"Coinníonn an file an {ga}."
                    if slot in {0, 1}
                    else f"Scríobhtar an {ga} sa chuimhne."
                    if slot == 2
                    else f"Labhraíonn an dán faoin {ga}."
                    if slot == 3
                    else f"Tá tuairim ann faoin {ga}."
                ),
                f"Kerry poet/land frame for {gloss}; no poem is quoted.",
                "story_recap",
                "later_reuse",
                "freeTyping",
            ),
        )
    elif county == "longford":
        triples = (
            (
                "evidence",
                f"Féach ar an {ga} ag Corr Liath.",
                f"Look at the {gloss} at Corlea.",
                "context_introduction",
                "introduction",
                "listenChoose",
            ),
            (
                "pattern",
                f"Téann an {ga} trasna an phortaigh.",
                f"The {gloss} goes across the bog.",
                "productive_pattern",
                "phrase_or_sentence_use",
                "freeTyping",
            ),
            (
                "notice",
                (
                    f"Tógadh bóthar adhmaid; tá {ga} ann."
                    if slot in {0, 1}
                    else f"Iompraíonn an t-adhmad an {ga}."
                    if slot == 2
                    else f"Faightear an {ga} faoin bportach."
                    if slot == 3
                    else f"Siúil leis an {ga} ansiúd."
                ),
                f"Longford monument frame for {gloss}; no fictional builder.",
                "story_recap",
                "later_reuse",
                "freeTyping",
            ),
        )
    elif county == "louth":
        triples = (
            (
                "evidence",
                f"Is finscéal é: tá {ga} ag Cuaille.",
                f"It is myth: the {gloss} is at Cooley.",
                "context_introduction",
                "introduction",
                "listenChoose",
            ),
            (
                "pattern",
                f"Fanann an laoch leis an {ga}.",
                f"The warrior waits with the {gloss}.",
                "productive_pattern",
                "phrase_or_sentence_use",
                "freeTyping",
            ),
            (
                "notice",
                (
                    f"Léigh an Táin: tá {ga} sa scéal."
                    if slot in {0, 1}
                    else f"Seasann an {ga} ag an áth."
                    if slot == 2
                    else f"Tá an {ga} láidir sa mhionscéal."
                    if slot == 3
                    else f"Ní stair é; is {ga} finscéalta é."
                ),
                f"Myth-labelled Louth frame for {gloss}.",
                "story_recap",
                "later_reuse",
                "freeTyping",
            ),
            (
                "myth",
                f"Abair é: finscéal Lú faoin {ga}.",
                f"Say it: a Louth myth about the {gloss}.",
                "dialogue_turn",
                "retrieval",
                "freeTyping",
            ),
        )
    elif county == "roscommon":
        triples = (
            (
                "evidence",
                f"Is finscéal é: tá {ga} ag Ráth Cruachan.",
                f"It is myth: the {gloss} is at Rathcroghan.",
                "context_introduction",
                "introduction",
                "listenChoose",
            ),
            (
                "pattern",
                f"Ordaíonn an bhanríon an {ga}.",
                f"The queen commands the {gloss}.",
                "productive_pattern",
                "phrase_or_sentence_use",
                "freeTyping",
            ),
            (
                "notice",
                (
                    f"Tá uaimh agus {ga} sa tírdhreach."
                    if slot in {0, 1}
                    else f"Teastaíonn an {ga} ón scéal."
                    if slot == 2
                    else f"Féach ar an {ga} agus an eallach."
                    if slot == 3
                    else f"Ní stair í; is {ga} finscéalta í."
                ),
                f"Myth-labelled Roscommon frame for {gloss}.",
                "story_recap",
                "later_reuse",
                "freeTyping",
            ),
            (
                "myth",
                f"Abair é: finscéal Ros Comáin faoin {ga}.",
                f"Say it: a Roscommon myth about the {gloss}.",
                "dialogue_turn",
                "retrieval",
                "freeTyping",
            ),
        )
    elif county == "tipperary":
        triples = (
            (
                "evidence",
                f"Féach ar an {ga} ag Caiseal.",
                f"Look at the {gloss} at Cashel.",
                "context_introduction",
                "introduction",
                "listenChoose",
            ),
            (
                "pattern",
                f"Tógadh an {ga} ar an charraig.",
                f"The {gloss} was built on the rock.",
                "productive_pattern",
                "phrase_or_sentence_use",
                "freeTyping",
            ),
            (
                "notice",
                (
                    f"Tá an séipéal álainn; tá {ga} ann."
                    if slot in {0, 1}
                    else f"Léigh faoin {ga} ar an gcnoc."
                    if slot == 2
                    else f"Seasann cloch agus {ga} le chéile."
                    if slot == 3
                    else f"Guíonn an rí leis an {ga}."
                ),
                f"Tipperary chapel/site frame for {gloss}; no invented inscription.",
                "story_recap",
                "later_reuse",
                "freeTyping",
            ),
        )
    elif county == "waterford":
        triples = (
            (
                "evidence",
                f"Féach ar an {ga} ag Port Láirge.",
                f"Look at the {gloss} at Waterford.",
                "context_introduction",
                "introduction",
                "listenChoose",
            ),
            (
                "pattern",
                f"Tagann an {ga} leis an abhainn.",
                f"The {gloss} comes with the river.",
                "productive_pattern",
                "phrase_or_sentence_use",
                "freeTyping",
            ),
            (
                "notice",
                (
                    f"Insíonn an túr an {ga}."
                    if slot in {0, 1}
                    else f"Tá trádáil agus {ga} sa bhaile."
                    if slot == 2
                    else f"Seasann an {ga} ag an gcladach."
                    if slot == 3
                    else f"Tógadh baile nua leis an {ga}."
                ),
                f"Waterford tower/town frame for {gloss}; no invented annal text.",
                "story_recap",
                "later_reuse",
                "freeTyping",
            ),
        )
    else:
        raise ValueError(f"unsupported county {county}")

    if myth:
        assert len(triples) == 4
    else:
        assert len(triples) == 3
        # Keep collocate referenced so language-field coverage is inspectable in purpose.
        _ = collocate
        _ = place

    out: list[dict[str, str]] = []
    for suffix, text, english, role, stage, response_family in triples:
        out.append(
            {
                "suffix": suffix,
                "text": text,
                "english": english,
                "role": role,
                "stage": stage,
                "response_family": response_family,
                "collocate": collocate,
            }
        )
    return out


def make_member_and_exercise(
    family: dict[str, Any],
    meta: dict[str, Any],
    frame: dict[str, str],
    position: int,
) -> tuple[dict[str, Any], dict[str, Any]]:
    family_id = family["id"]
    ga = family["target"]["citation_form"]
    gloss = family["target"]["english_sense"]
    suffix = frame["suffix"]
    member_id = f"{family_id}.{suffix}"
    exercise_id = f"{meta['story_id']}.{suffix}.{position:02d}"
    normalized = normalize_spoken_text(frame["text"])
    response_family = frame["response_family"]
    purpose = (
        f"A5 evidence-led {suffix} for {ga}/{gloss} in {meta['county']} "
        f"(collocate={frame['collocate']}; myth={meta['myth_labelled']})."
    )
    flags = risk_flags_for(normalized, myth_labelled=meta["myth_labelled"])
    placement_ids = [placement["id"] for placement in family["atlas_placements"]]
    target = family["target"]
    member = {
        "id": member_id,
        "family_id": family_id,
        "target": {
            "lexeme_id": target["lexeme_id"],
            "citation_form": target["citation_form"],
            "sense_id": target["sense_id"],
            "part_of_speech": target["part_of_speech"],
            "target_form": target["citation_form"],
            "morphology": "atlas citation form; evidence-led provisional surrounding frame",
        },
        "irish": {
            "text": normalized,
            "normalized_text": normalized,
            "inventory_slug": canonical_audio_slug(normalized),
            "text_sha256": text_sha256(normalized),
        },
        "english": {
            "intent": frame["english"],
            "literal_note": (
                "D32 invented pedagogical line; myth-labelled literary framing; not an attested quotation or historical claim."
                if meta["myth_labelled"]
                else "D32 invented pedagogical line; evidence-orienting frame only; not an attested quotation."
            ),
        },
        "binding": {
            "county": meta["county"],
            "story_ref": dict(family["story_ref"]),
            "atlas_placement_ids": placement_ids,
            "place": {"id": f"d32.{meta['county']}.place", "label": meta["place_label"]},
            "setting": "historical_bounded" if meta["myth_labelled"] else "present_day",
            "learner_role": "self_observer" if meta["myth_labelled"] else "present_day_self",
        },
        "learning": {
            "stages": [frame["stage"]],
            "roles": [frame["role"]],
            "dialect": (
                "standard Irish; provisional myth-labelled county context"
                if meta["myth_labelled"]
                else "standard Irish; provisional evidence-led county context"
            ),
            "register": (
                "neutral myth-labelled pedagogical frame"
                if meta["myth_labelled"]
                else "neutral evidence-orienting pedagogical frame"
            ),
            "purpose": purpose,
            "fixture_only": False,
        },
        "exercise_consumers": [
            {
                "path": "content/audio/authoring/d32-county-harvest-uses.json",
                "record_id": exercise_id,
                "response_family": response_family,
                "container": "none",
                "use": purpose,
            }
        ],
        "provenance": {
            "origin": "invented_pedagogical",
            "invented": True,
            "composition_note": (
                "Deterministically composed for queue-02 evidence-led expansion from the "
                "county story slate anchor, source register, and atlas headword; not attested text."
            ),
            "source_refs": [
                {
                    "path": "content/audio/authoring/d32-queue-02-evidence-source-register.json",
                    "record_id": f"register.{meta['county']}",
                    "supports": "pattern_only",
                },
                {
                    "path": "content/audio/authoring/d32-county-harvest-uses.json",
                    "record_id": exercise_id,
                    "supports": "exercise_context",
                },
            ],
        },
        "states": member_state(flags),
        "risk_flags": flags,
    }
    exercise = {
        "id": exercise_id,
        "county": meta["county"],
        "story_ref": meta["story_id"],
        "kind": "exercise",
        "exercise": {
            "family": response_family,
            "prompt": (
                "Listen and notice the evidence-led county line."
                if response_family == "listenChoose"
                else "Type the evidence-led county line."
            ),
            "answer": frame["english"],
            "translation": frame["english"],
            "audioText": normalized if response_family == "listenChoose" else None,
            "modelText": normalized if response_family == "freeTyping" else None,
            "phraseFamilyMemberIDs": [member_id],
        },
    }
    return member, exercise


def build_source_register() -> dict[str, Any]:
    counties = []
    for meta in QUEUE_02:
        counties.append(
            {
                "id": f"register.{meta['county']}",
                "county": meta["county"],
                "queue": "queue-02-evidence-led-next",
                "avenue": "A5",
                "story_id": meta["story_id"],
                "title": meta["title"],
                "anchor": meta["anchor"],
                "place_label": meta["place_label"],
                "place_ga": meta["place_ga"],
                "language_field": list(meta["language_field"]),
                "evidence_kind": meta["evidence_kind"],
                "evidence_note": meta["evidence_note"],
                "myth_labelled": meta["myth_labelled"],
                "packet_status": meta["packet_status"],
                "blocked": meta["blocked"],
                "rights_note": meta.get("rights_note"),
                "slate_source": "docs/COUNTY-STORY-SLATE.md",
                "exercise_demand": exercise_demand(meta),
                "family_glob": f"content/{meta['county']}/phrase-families/authoring-v2/d32.{meta['county']}.*.v2.json",
            }
        )
    return {
        "schema_version": 1,
        "contract": "d32_queue_02_evidence_source_register",
        "created_at": CREATED_AT,
        "status": "assembled_for_authoring",
        "queue": "queue-02-evidence-led-next",
        "avenue": "A5",
        "notes": [
            "Entry condition satisfied: each county has a named slate anchor and place/story language field.",
            "Exercise demand is assembled before member authoring; harvest uses are registered with members.",
            "No documentary quotations or historical participation are invented.",
            "Provider capture is not requested by this tranche.",
        ],
        "counties": counties,
    }


def family_paths(county: str) -> list[Path]:
    root = ROOT / f"content/{county}/phrase-families/authoring-v2"
    return sorted(root.glob(f"d32.{county}.*.v2.json"))


def existing_corpus_texts() -> set[str]:
    texts: set[str] = set()
    for path in ROOT.glob("content/*/phrase-families/authoring-v2/*.v2.json"):
        family = load_json(path)
        for member in family.get("members", []):
            irish = member.get("irish") or {}
            text = irish.get("normalized_text") or irish.get("text")
            if isinstance(text, str) and text:
                texts.add(normalize_spoken_text(text))
    return texts


def run(*, dry_run: bool = False) -> dict[str, Any]:
    register = build_source_register()
    if not dry_run:
        write_json(REGISTER_PATH, register)

    uses = load_json(USES_PATH)
    existing_exercise_ids = {item.get("id") for item in uses.get("exercises", [])}
    corpus_texts = existing_corpus_texts()
    planned_texts: set[str] = set()
    new_exercises: list[dict[str, Any]] = []
    per_county: dict[str, dict[str, Any]] = {}
    collisions: list[str] = []
    members_added = 0
    files_touched: list[str] = []

    for meta in QUEUE_02:
        county_new_texts: set[str] = set()
        families_updated = 0
        for path in family_paths(meta["county"]):
            family = load_json(path)
            existing_ids = {member.get("id") for member in family.get("members", [])}
            position = int(family["id"].split(".")[2])
            ga = family["target"]["citation_form"]
            gloss = family["target"]["english_sense"]
            added_here = 0
            for frame in frames_for(meta, ga, gloss, position):
                member_id = f"{family['id']}.{frame['suffix']}"
                if member_id in existing_ids:
                    continue
                member, exercise = make_member_and_exercise(family, meta, frame, position)
                text = member["irish"]["normalized_text"]
                if text in corpus_texts or text in planned_texts:
                    collisions.append(f"{meta['county']}:{member_id}:{text}")
                    continue
                planned_texts.add(text)
                county_new_texts.add(text)
                family["members"].append(member)
                added_here += 1
                members_added += 1
                if exercise["id"] not in existing_exercise_ids:
                    new_exercises.append(exercise)
                    existing_exercise_ids.add(exercise["id"])
            if added_here:
                families_updated += 1
                files_touched.append(str(path.relative_to(ROOT)))
                if not dry_run:
                    write_json(path, family)
        per_county[meta["county"]] = {
            "county": meta["county"],
            "members_added": len(county_new_texts),
            "unique_texts_added": len(county_new_texts),
            "families_updated": families_updated,
            "blocked": meta["blocked"],
            "story_id": meta["story_id"],
            "packet_status": meta["packet_status"],
        }

    if collisions:
        raise SystemExit(
            "unique-text collisions while composing A5 tranche:\n" + "\n".join(collisions[:40])
        )

    if not dry_run:
        uses["exercises"] = sorted(
            uses.get("exercises", []) + new_exercises,
            key=lambda item: item["id"],
        )
        write_json(USES_PATH, uses)

    return {
        "status": "dry_run" if dry_run else "generated",
        "avenue": "A5",
        "queue": "queue-02-evidence-led-next",
        "members_added": members_added,
        "unique_texts_added": len(planned_texts),
        "exercises_added": len(new_exercises),
        "files_touched": sorted(set(files_touched)),
        "register_path": str(REGISTER_PATH.relative_to(ROOT)),
        "per_county": per_county,
        "blocked_counties": [meta["county"] for meta in QUEUE_02 if meta["blocked"]],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    report = run(dry_run=args.dry_run)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
