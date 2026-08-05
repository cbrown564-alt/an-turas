#!/usr/bin/env python3
"""Generate deterministic, provisional D32 phrase-family authoring tranches.

This is an offline Track A authoring tool. It creates no audio and never changes a
provider result. The generated Irish is explicitly invented pedagogical material,
bound to a county/story/atlas placement and to a repository exercise ledger so Track
B can prepare resumable manifests without mistaking the text for attestation.

Modes:
- scaffold (default): create uncovered atlas-placement families with opening + second role
- story-dialogue: append net-new dialogue, listen-choose surrounds, and story-exercise
  role members beyond the scaffold for all 32 story bindings (Bulk Track A avenue A2)
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import unicodedata
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
ATLAS_PATH = ROOT / "content/audio/atlas-headwords-v1.json"
STORE_PATH = ROOT / "content/audio/authoring/phrase-family-store-v2.json"
USES_PATH = ROOT / "content/audio/authoring/d32-county-harvest-uses.json"

A2_AUTHOR_REF = "track-a.a2-story-dialogue.cycle-2"
A2_COMPLETED_AT = "2026-08-05"

QUEUE_02_EVIDENCE_LED = (
    "cork",
    "galway",
    "kerry",
    "longford",
    "louth",
    "roscommon",
    "tipperary",
    "waterford",
)
DEEPEN_COUNTIES = ("mayo",) + QUEUE_02_EVIDENCE_LED


STORIES = {
    "antrim": ("fionn-mac-cumhaill", "Fionn mac Cumhaill and the Giant's Causeway", "Fionn mac Cumhaill · the Giant's Causeway"),
    "armagh": ("book-of-armagh", "St Patrick and the Book of Armagh", "St Patrick · the Book of Armagh"),
    "carlow": ("st-moling", "St Moling and St Mullins", "St Moling · St Mullins on the Barrow"),
    "cavan": ("oreillys-east-breifne", "Giolla Íosa Ruadh O'Reilly and East Bréifne", "Giolla Íosa Ruadh O'Reilly · the friary and East Bréifne"),
    "clare": ("brian-boru-kincora", "Brian Boru at Kincora", "Brian Boru · Kincora and Killaloe"),
    "cork": ("nano-nagle", "Nano Nagle and Cork schools", "Nano Nagle · education in eighteenth-century Cork"),
    "derry": ("city-walls-siege", "Derry's walls and the siege of 1688–89", "the city walls · the siege of 1688–89"),
    "donegal": ("flight-of-the-earls", "Aodh Ó Néill at Rathmullan", "Aodh Ó Néill · Rathmullan and the 1607 departure"),
    "down": ("patrick-saul", "St Patrick at Saul", "St Patrick · Saul and its later remembrance"),
    "dublin": ("sihtric-penny", "Sihtric and Dublin's first penny", "Sihtric Silkbeard · the first locally struck Dublin penny"),
    "fermanagh": ("enniskillen-castle", "The Maguires and Enniskillen Castle", "the Maguires · Enniskillen Castle"),
    "galway": ("joe-heaney-carna", "Joe Heaney and Carna sean-nós", "Joe Heaney · Carna and sean-nós transmission"),
    "kerry": ("piaras-feiritear", "Piaras Feiritéar", "Piaras Feiritéar · Corca Dhuibhne poetry"),
    "kildare": ("brigid-fire", "Brigid and Kildare's perpetual fire", "Brigid · Kildare and the perpetual fire tradition"),
    "kilkenny": ("alice-kyteler", "Alice Kyteler's trial", "Alice Kyteler · the 1324 trial"),
    "laois": ("rock-of-dunamase", "The Rock of Dunamase", "the Rock of Dunamase · the Marshal lordship"),
    "leitrim": ("brian-na-murtha", "Brian na Múrtha O'Rourke", "Brian na Múrtha O'Rourke · Breifne under Tudor pressure"),
    "limerick": ("treaty-of-limerick", "Patrick Sarsfield and the Treaty of Limerick", "Patrick Sarsfield · the Treaty of Limerick"),
    "longford": ("corlea-trackway", "The Corlea Trackway", "the Corlea Trackway · the Iron Age bog road"),
    "louth": ("cu-chulainn-cooley", "Cú Chulainn and the Cooley peninsula", "Cú Chulainn · the Cooley peninsula and the Táin"),
    "mayo": ("grainne-1593", "Gráinne Ní Mháille and the 1593 petition", "Gráinne Ní Mháille · Clew Bay and the 1593 petition"),
    "meath": ("trim-de-lacy", "Hugh de Lacy and Trim Castle", "Hugh de Lacy · Áth Troim and Trim Castle"),
    "monaghan": ("patrick-kavanagh", "Patrick Kavanagh at Iniskeen", "Patrick Kavanagh · Iniskeen and remembered place"),
    "offaly": ("cross-of-the-scriptures", "The Cross of the Scriptures", "Flann Sinna · Clonmacnoise and the Cross of the Scriptures"),
    "roscommon": ("medb-rathcroghan", "Medb and Rathcroghan", "Medb · Rathcroghan and the Táin"),
    "sligo": ("yeats-ben-bulben", "W. B. Yeats and Ben Bulben", "W. B. Yeats · Ben Bulben and Sligo"),
    "tipperary": ("cormac-chapel", "Cormac Mac Cárthaigh and Cormac's Chapel", "Cormac Mac Cárthaigh · the Rock of Cashel"),
    "tyrone": ("hugh-oneill-dungannon", "Hugh O'Neill at Dungannon", "Hugh O'Neill · Dungannon before the Flight"),
    "waterford": ("reginalds-tower", "Reginald and Waterford's Viking foundation", "Ragnall/Reginald · Waterford and the Suir"),
    "westmeath": ("st-fechin-fore", "St Féchín and Fore Abbey", "St Féchín · Fore Abbey and its monuments"),
    "wexford": ("bagenal-harvey-1798", "Bagenal Harvey and 1798", "Bagenal Harvey · Wexford in 1798"),
    "wicklow": ("st-kevin-glendalough", "St Kevin and Glendalough", "St Kevin · Glendalough's valley and monuments"),
}


POS_BY_GA = {
    "ainm": "noun", "áit": "noun", "abhainn": "noun", "baile": "noun", "bád": "noun",
    "balla": "noun", "bean": "noun", "bóthar": "noun", "caisleán": "noun", "carraig": "noun",
    "cathair": "noun", "cladach": "noun", "cloch": "noun", "colún": "noun", "cosán": "noun",
    "cros": "noun", "dídean": "noun", "dún": "noun", "eaglais": "noun", "fathach": "noun",
    "geata": "noun", "leabhar": "noun", "linn": "noun", "litir": "noun", "long": "noun",
    "mainistir": "noun", "margadh": "noun", "muileann": "noun", "oileán": "noun", "páiste": "noun",
    "páirc": "noun", "pingin": "noun", "scoil": "noun", "scéal": "noun", "teaghlach": "noun",
    "teach": "noun", "turas": "noun", "uisce": "noun", "focal": "noun", "fire": "noun",
    "rí": "noun", "cara": "noun", "clann": "noun", "cumhacht": "noun", "dóchas": "noun",
    "eagla": "noun", "ocras": "noun", "obair": "noun", "oilithreacht": "noun", "traidisiún": "noun",
    "airgead": "noun", "farraige": "noun", "bá": "noun", "cath": "noun", "fianaise": "noun",
    "abhainn": "noun", "mór": "adjective", "beag": "adjective", "dubh": "adjective", "fíor": "adjective",
    "bréag": "noun", "sean": "adjective", "nua": "adjective", "maith": "adjective", "álainn": "adjective",
    "dúnta": "adjective", "déan": "verb", "déanamh": "verb", "faigh": "verb", "fág": "verb",
    "féach": "verb", "fill": "verb", "foghlaim": "verb", "guí": "verb", "iarr": "verb",
    "léigh": "verb", "múin": "verb", "scríobh": "verb", "seas": "verb", "siúil": "verb",
    "tabhair": "verb", "tar": "verb", "téigh": "verb", "tóg": "verb", "ceannaigh": "verb",
    "caill": "verb", "cabhraigh": "verb", "creid": "verb", "díol": "verb", "tosnaigh": "verb",
    "tháinig": "verb", "chuaigh": "verb", "traidisiún": "noun", "cuimhnigh": "verb", "fan": "verb",
    "labhair": "verb", "éist": "verb", "roghnaigh": "verb", "cónaí": "noun", "agam": "pronoun",
    "agat": "pronoun", "mise": "pronoun", "as": "preposition", "anois": "adverb", "anseo": "adverb",
    "ansiúd": "adverb", "isteach": "adverb", "amuigh": "adverb", "trasna": "preposition", "arís": "adverb",
    "slán": "adjective", "brón": "noun", "solas": "noun", "oíche": "noun", "lá": "noun",
    "talamh": "noun", "loch": "noun", "cnoc": "noun", "dúnta": "adjective", "naomh": "noun",
}


def slug(value: str) -> str:
    folded = "".join(
        char for char in unicodedata.normalize("NFD", value.casefold())
        if unicodedata.category(char) != "Mn"
    )
    return re.sub(r"-+", "-", re.sub(r"[^a-z0-9]+", "-", folded)).strip("-") or "item"


def normalize(text: str) -> str:
    return " ".join(unicodedata.normalize("NFC", text).strip().split())


def text_hash(text: str) -> str:
    return hashlib.sha256(normalize(text).encode("utf-8")).hexdigest()


def audio_slug(text: str) -> str:
    fadas = {"á": "aa", "é": "ee", "í": "ii", "ó": "oo", "ú": "uu"}
    out: list[str] = []
    for char in normalize(text).lower():
        if char in fadas:
            out.append(fadas[char])
        elif char.isascii() and char.isalpha():
            out.append(char)
        else:
            out.append(" ")
    return "-".join("".join(out).split())


def story_record(county: str, atlas_record: dict, place_label: str) -> dict:
    story_slug, title, anchor = STORIES[county]
    return {
        "id": f"d32.{county}.{story_slug}",
        "county": county,
        "title": title,
        "anchor": anchor,
        "source_record": "docs/COUNTY-STORY-SLATE.md",
        "status": "development-slate-input",
        "place_label": place_label,
    }


def exercise_record(
    record_id: str,
    story_id: str,
    county: str,
    member_id: str,
    family: str,
    text: str,
    translation: str,
) -> dict:
    payload: dict = {
        "family": family,
        "prompt": "Listen and notice the county-bound line." if family == "listenChoose" else "Type the county-bound line.",
        "answer": translation,
        "translation": translation,
        "audioText": text if family == "listenChoose" else None,
        "modelText": text if family == "freeTyping" else None,
        "phraseFamilyMemberIDs": [member_id],
    }
    return {
        "id": record_id,
        "county": county,
        "story_ref": story_id,
        "kind": "exercise",
        "exercise": payload,
    }


# Bulk Track A avenue A2 role templates. Each frame must yield net-new unique
# normalized text relative to the scaffold openings/recaps already captured.
# Roles are restricted to structured_audio_authoring.MEMBER_ROLES.
STORY_DIALOGUE_ROLE_TEMPLATES: tuple[dict[str, Any], ...] = (
    {
        "suffix": "ask-what",
        "role": "dialogue_turn",
        "stage": "phrase_or_sentence_use",
        "response_family": "freeTyping",
        "tier": "lean",
        "text": lambda ga, gloss, place: f"Cad é an {ga}?",
        "fallback_text": lambda ga, gloss, place: f"Cad é an {ga} i {place}?",
        "english": lambda ga, gloss, place: f"What is the {gloss}?",
        "fallback_english": lambda ga, gloss, place: f"What is the {gloss} in {place}?",
        "purpose": lambda ga, gloss: f"Ask what the atlas-bound {gloss} is after the story opening.",
        "composition_note": "A2 dialogue question frame; invented pedagogical Irish, not attested speech.",
    },
    {
        "suffix": "ask-where",
        "role": "dialogue_turn",
        "stage": "phrase_or_sentence_use",
        "response_family": "freeTyping",
        "tier": "lean",
        "text": lambda ga, gloss, place: f"Cá bhfuil an {ga}?",
        "fallback_text": lambda ga, gloss, place: f"Cá bhfuil an {ga} i {place}?",
        "english": lambda ga, gloss, place: f"Where is the {gloss}?",
        "fallback_english": lambda ga, gloss, place: f"Where is the {gloss} in {place}?",
        "purpose": lambda ga, gloss: f"Locate the {gloss} in a short county-bound dialogue turn.",
        "composition_note": "A2 dialogue location question; invented pedagogical Irish, not attested speech.",
    },
    {
        "suffix": "listen-surround",
        "role": "listening_contrast",
        "stage": "phrase_or_sentence_use",
        "response_family": "listenChoose",
        "tier": "lean",
        "text": lambda ga, gloss, place: f"Éist leis an {ga}.",
        "fallback_text": lambda ga, gloss, place: f"Éist leis an {ga} i {place}.",
        "english": lambda ga, gloss, place: f"Listen to the {gloss}.",
        "fallback_english": lambda ga, gloss, place: f"Listen to the {gloss} in {place}.",
        "purpose": lambda ga, gloss: f"Surround a listen-choose beat with the county-bound {gloss}.",
        "composition_note": "A2 listen-choose surround frame; invented pedagogical Irish, not attested speech.",
    },
    {
        "suffix": "story-concerns",
        "role": "story_recap",
        "stage": "later_reuse",
        "response_family": "listenChoose",
        "tier": "lean",
        "text": lambda ga, gloss, place: f"Baineann an scéal leis an {ga}.",
        "fallback_text": lambda ga, gloss, place: f"Baineann scéal {place} leis an {ga}.",
        "english": lambda ga, gloss, place: f"The story concerns the {gloss}.",
        "fallback_english": lambda ga, gloss, place: f"The {place} story concerns the {gloss}.",
        "purpose": lambda ga, gloss: f"Bind the {gloss} into a story-specific exercise role line.",
        "composition_note": "A2 story-exercise role frame; invented pedagogical Irish, not attested speech.",
    },
    {
        "suffix": "see-here",
        "role": "dialogue_turn",
        "stage": "phrase_or_sentence_use",
        "response_family": "freeTyping",
        "tier": "deepen",
        "text": lambda ga, gloss, place: f"Feicim an {ga} anseo.",
        "fallback_text": lambda ga, gloss, place: f"Feicim an {ga} i {place}.",
        "english": lambda ga, gloss, place: f"I see the {gloss} here.",
        "fallback_english": lambda ga, gloss, place: f"I see the {gloss} in {place}.",
        "purpose": lambda ga, gloss: f"Produce a present-day noticing line for the story-bound {gloss}.",
        "composition_note": "A2 deepen dialogue noticing frame; invented pedagogical Irish, not attested speech.",
    },
    {
        "suffix": "choose-surround",
        "role": "listening_contrast",
        "stage": "phrase_or_sentence_use",
        "response_family": "listenChoose",
        "tier": "deepen",
        "text": lambda ga, gloss, place: f"Roghnaigh an {ga} ceart.",
        "fallback_text": lambda ga, gloss, place: f"Roghnaigh an {ga} ceart i {place}.",
        "english": lambda ga, gloss, place: f"Choose the correct {gloss}.",
        "fallback_english": lambda ga, gloss, place: f"Choose the correct {gloss} in {place}.",
        "purpose": lambda ga, gloss: f"Prompt a listen-choose selection around the {gloss}.",
        "composition_note": "A2 deepen listen-choose surround; invented pedagogical Irish, not attested speech.",
    },
    {
        "suffix": "speak-about",
        "role": "dialogue_turn",
        "stage": "phrase_or_sentence_use",
        "response_family": "freeTyping",
        "tier": "deepen",
        "text": lambda ga, gloss, place: f"Labhair faoin {ga}.",
        "fallback_text": lambda ga, gloss, place: f"Labhair faoin {ga} i {place}.",
        "english": lambda ga, gloss, place: f"Speak about the {gloss}.",
        "fallback_english": lambda ga, gloss, place: f"Speak about the {gloss} in {place}.",
        "purpose": lambda ga, gloss: f"Cue productive talk about the story-bound {gloss}.",
        "composition_note": "A2 deepen dialogue prompt; invented pedagogical Irish, not attested speech.",
    },
    {
        "suffix": "story-important",
        "role": "story_recap",
        "stage": "later_reuse",
        "response_family": "freeTyping",
        "tier": "deepen",
        "text": lambda ga, gloss, place: f"Tá an {ga} tábhachtach sa scéal.",
        "fallback_text": lambda ga, gloss, place: f"Tá an {ga} tábhachtach i scéal {place}.",
        "english": lambda ga, gloss, place: f"The {gloss} is important in the story.",
        "fallback_english": lambda ga, gloss, place: f"The {gloss} is important in the {place} story.",
        "purpose": lambda ga, gloss: f"Mark the {gloss} as a story-important exercise role line.",
        "composition_note": "A2 deepen story-exercise role; invented pedagogical Irish, not attested speech.",
    },
)


def irish_place_form(place_label: str) -> str:
    return place_label.split("/", 1)[0].strip()


def member(
    *,
    family_id: str,
    member_id: str,
    county: str,
    story_id: str,
    placement_id: str,
    place_label: str,
    ga: str,
    gloss: str,
    text: str,
    english_intent: str,
    role: str,
    stage: str,
    exercise_id: str,
    response_family: str,
    purpose: str,
    author_ref: str = "track-a.d32-scale-authoring",
    completed_at: str = "2026-08-02",
    composition_note: str | None = None,
    literal_note: str = "D32 invented pedagogical line; not an attested quotation.",
    family: dict | None = None,
) -> dict:
    text = normalize(text)
    risks = {"invented_text", "audio_pronunciation", "source_ambiguity"}
    if any(char in text for char in "áéíóúÁÉÍÓÚ"):
        risks.add("fada")
    if ga[:2] in {"bh", "ch", "dh", "fh", "gh", "mh", "ph", "sh", "th", "mb", "gc", "nd", "ng", "bp", "dt"}:
        risks.add("initial_mutation")
    if any(token in text.casefold() for token in ("éist", "baineann", "faoin")):
        risks.add("initial_mutation")
    if family is not None:
        family_target = family["target"]
        citation = str(family_target.get("citation_form") or ga)
        target = {
            "lexeme_id": family_target["lexeme_id"],
            "citation_form": citation,
            "sense_id": family_target["sense_id"],
            "part_of_speech": family_target.get("part_of_speech") or POS_BY_GA.get(ga, "lexical item"),
            "target_form": citation,
            "morphology": "atlas citation form; provisional surrounding frame",
        }
        if family_target.get("english_sense"):
            target["english_sense"] = family_target["english_sense"]
        family_story_ref = dict(family["story_ref"])
        binding_county = family.get("county") or county
        binding_place_label = place_label
    else:
        citation = ga
        target = {
            "lexeme_id": f"lex.{slug(ga)}",
            "citation_form": ga,
            "sense_id": f"{county}.{slug(ga)}.{slug(gloss)}",
            "part_of_speech": POS_BY_GA.get(ga, "lexical item"),
            "target_form": ga,
            "morphology": "atlas citation form; provisional surrounding frame",
        }
        family_story_ref = {
            "path": "content/audio/authoring/d32-county-harvest-uses.json",
            "record_id": story_id,
        }
        binding_county = county
        binding_place_label = place_label
    note = composition_note or (
        "Deterministically composed from the provisional atlas gloss and the county "
        "story-slate place binding for the D32 emergency harvest; not attested text."
    )
    return {
        "id": member_id,
        "family_id": family_id,
        "target": target,
        "irish": {
            "text": text,
            "normalized_text": text,
            "inventory_slug": audio_slug(text),
            "text_sha256": text_hash(text),
        },
        "english": {"intent": english_intent, "literal_note": literal_note},
        "binding": {
            "county": binding_county,
            "story_ref": family_story_ref,
            "atlas_placement_ids": [placement_id],
            "place": {"id": f"d32.{binding_county}.place", "label": binding_place_label},
            "setting": "present_day",
            "learner_role": "present_day_self",
        },
        "learning": {
            "stages": [stage],
            "roles": [role],
            "dialect": "standard Irish; provisional county context",
            "register": "neutral pedagogical frame",
            "purpose": purpose,
            "fixture_only": False,
        },
        "exercise_consumers": [{
            "path": "content/audio/authoring/d32-county-harvest-uses.json",
            "record_id": exercise_id,
            "response_family": response_family,
            "container": "none",
            "use": purpose,
        }],
        "provenance": {
            "origin": "invented_pedagogical",
            "invented": True,
            "composition_note": note,
            "source_refs": [{
                "path": "content/audio/authoring/d32-county-harvest-uses.json",
                "record_id": exercise_id,
                "supports": "exercise_context",
            }],
        },
        "states": {
            "authoring": {
                "status": "complete",
                "revision": 1,
                "author_ref": author_ref,
                "completed_at": completed_at,
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
            "learner_release": {
                "status": "blocked",
                "reasons": [
                    "invented_text",
                    "editorial_review_pending",
                    "pedagogy_review_pending",
                    "irish_language_review_pending",
                    "audio_not_generated",
                ],
            },
        },
        "risk_flags": sorted(risks),
    }


def dedupe_stories(stories: list[dict]) -> list[dict]:
    """Keep one story record per stable id; preserve kerry primary instance id."""
    by_id: dict[str, dict] = {}
    for record in stories:
        story_id = record.get("id")
        if not isinstance(story_id, str) or not story_id:
            continue
        prior = by_id.get(story_id)
        if prior is None:
            by_id[story_id] = record
            continue
        # Prefer the record that already carries a stable instance id.
        if prior.get("record_instance_id") or not record.get("record_instance_id"):
            continue
        by_id[story_id] = record
    return sorted(by_id.values(), key=lambda item: item["id"])


def load_existing_unique_texts(store: dict) -> set[str]:
    texts: set[str] = set()
    for family_ref in store.get("family_documents", []):
        family = json.loads((ROOT / family_ref["path"]).read_text(encoding="utf-8"))
        for item in family.get("members", []):
            irish = item.get("irish") or {}
            text = irish.get("normalized_text") or irish.get("text")
            if isinstance(text, str) and text.strip():
                texts.add(normalize(text))
    return texts


def family_index_by_placement(store: dict) -> dict[str, dict[str, str]]:
    """Map atlas placements to host families for A2 dialogue expansion.

    Prefer non-contrast families when a placement is shared. Contrast documents
    are listening-pair hosts and must not receive story-dialogue role members or
    steal exercise bindings from the primary county family.
    """
    index: dict[str, dict[str, str]] = {}
    for family_ref in store.get("family_documents", []):
        family = json.loads((ROOT / family_ref["path"]).read_text(encoding="utf-8"))
        family_id = family["id"]
        is_contrast = ".contrast." in family_id
        for placement in family.get("atlas_placements", []):
            placement_id = placement.get("id")
            if not isinstance(placement_id, str) or not placement_id:
                continue
            existing = index.get(placement_id)
            if existing is None:
                index[placement_id] = {
                    "family_id": family_id,
                    "path": family_ref["path"],
                }
            elif ".contrast." in existing["family_id"] and not is_contrast:
                index[placement_id] = {
                    "family_id": family_id,
                    "path": family_ref["path"],
                }
    return index


def story_level_members_for_county(
    *,
    county: str,
    place_label: str,
    family: dict,
    existing_member_ids: set[str],
    existing_texts: set[str],
) -> tuple[list[dict], list[dict]]:
    """Add a small county-unique story dialogue pair on the host family."""
    story_slug, _, _ = STORIES[county]
    story_id = f"d32.{county}.{story_slug}"
    placement_id = family["atlas_placements"][0]["id"]
    ga = family["target"]["citation_form"]
    gloss = family["target"].get("english_sense") or family["atlas_placements"][0].get("gloss") or ga
    irish_place = irish_place_form(place_label)
    specs = (
        {
            "suffix": "story-here",
            "role": "story_opening",
            "stage": "introduction",
            "response_family": "listenChoose",
            # Keep citation form in the line so target_form validation passes.
            "text": f"Seo scéal {irish_place}: {ga}.",
            "english": f"This is the story of {irish_place}: the {gloss}.",
            "purpose": f"Open the {county} story dialogue with its place-bound story line.",
        },
        {
            "suffix": "story-listen-place",
            "role": "listening_contrast",
            "stage": "phrase_or_sentence_use",
            "response_family": "listenChoose",
            "text": f"Éist leis an scéal i {irish_place}: {ga}.",
            "english": f"Listen to the story in {irish_place}: the {gloss}.",
            "purpose": f"Surround listen-choose with the {county} story place.",
        },
    )
    members: list[dict] = []
    exercises: list[dict] = []
    for spec in specs:
        member_id = f"{family['id']}.{spec['suffix']}"
        if member_id in existing_member_ids:
            continue
        text = normalize(spec["text"])
        if text in existing_texts:
            continue
        exercise_id = f"{story_id}.{spec['suffix']}"
        item = member(
            family_id=family["id"],
            member_id=member_id,
            county=county,
            story_id=story_id,
            placement_id=placement_id,
            place_label=place_label,
            ga=ga,
            gloss=gloss,
            text=text,
            english_intent=spec["english"],
            role=spec["role"],
            stage=spec["stage"],
            exercise_id=exercise_id,
            response_family=spec["response_family"],
            purpose=spec["purpose"],
            author_ref=A2_AUTHOR_REF,
            completed_at=A2_COMPLETED_AT,
            composition_note=(
                "A2 county-unique story dialogue line bound to the slate place label; "
                "invented pedagogical Irish, not attested speech."
            ),
            literal_note="A2 invented story dialogue; not an attested quotation.",
            family=family,
        )
        members.append(item)
        exercises.append(
            exercise_record(
                exercise_id,
                story_id,
                county,
                member_id,
                spec["response_family"],
                text,
                spec["english"],
            )
        )
        existing_texts.add(text)
        existing_member_ids.add(member_id)
    return members, exercises


def append_story_dialogue_tranche(
    *,
    lean_words: int,
    deepen_words: int,
    deepen_counties: tuple[str, ...],
) -> dict[str, Any]:
    atlas = json.loads(ATLAS_PATH.read_text(encoding="utf-8"))
    store = json.loads(STORE_PATH.read_text(encoding="utf-8"))
    uses = json.loads(USES_PATH.read_text(encoding="utf-8")) if USES_PATH.is_file() else {
        "schema_version": 1,
        "contract": "d32_county_harvest_uses",
        "created_at": f"{A2_COMPLETED_AT}T12:00:00Z",
        "status": "provisional_authoring_input_only",
        "stories": [],
        "exercises": [],
    }
    placement_index = family_index_by_placement(store)
    existing_texts = load_existing_unique_texts(store)
    existing_exercise_ids = {item.get("id") for item in uses.get("exercises", [])}
    existing_story_ids = {item.get("id") for item in uses.get("stories", [])}

    families_touched: set[str] = set()
    counties_touched: set[str] = set()
    new_members = 0
    new_unique_texts = 0
    new_exercises: list[dict] = []
    new_stories: list[dict] = []
    family_cache: dict[str, dict] = {}

    def get_family(path: str) -> dict:
        if path not in family_cache:
            family_cache[path] = json.loads((ROOT / path).read_text(encoding="utf-8"))
        return family_cache[path]

    def append_templates_for_word(
        *,
        county: str,
        place_label: str,
        position: int,
        word: dict,
        templates: list[dict[str, Any]],
    ) -> str | None:
        nonlocal new_members, new_unique_texts
        ga = word["ga"]
        gloss = word["en"]
        placement_id = f"atlas.{county}.{position:02d}.{slug(ga)}"
        family_ref = placement_index.get(placement_id)
        if family_ref is None:
            return None
        family = get_family(family_ref["path"])
        existing_member_ids = {item.get("id") for item in family.get("members", [])}
        story_slug, _, _ = STORIES[county]
        story_id = f"d32.{county}.{story_slug}"
        if story_id not in existing_story_ids:
            new_stories.append(story_record(county, word, place_label))
            existing_story_ids.add(story_id)
        irish_place = irish_place_form(place_label)
        for template in templates:
            member_id = f"{family['id']}.{template['suffix']}"
            if member_id in existing_member_ids:
                continue
            text = normalize(template["text"](ga, gloss, irish_place))
            english_intent = template["english"](ga, gloss, irish_place)
            if text in existing_texts:
                fallback_text = template.get("fallback_text")
                fallback_english = template.get("fallback_english")
                if fallback_text is None:
                    continue
                text = normalize(fallback_text(ga, gloss, irish_place))
                if text in existing_texts:
                    continue
                if fallback_english is not None:
                    english_intent = fallback_english(ga, gloss, irish_place)
            purpose = template["purpose"](ga, gloss)
            exercise_id = f"{story_id}.{template['suffix']}.{position:02d}"
            item = member(
                family_id=family["id"],
                member_id=member_id,
                county=county,
                story_id=story_id,
                placement_id=placement_id,
                place_label=place_label,
                ga=ga,
                gloss=gloss,
                text=text,
                english_intent=english_intent,
                role=template["role"],
                stage=template["stage"],
                exercise_id=exercise_id,
                response_family=template["response_family"],
                purpose=purpose,
                author_ref=A2_AUTHOR_REF,
                completed_at=A2_COMPLETED_AT,
                composition_note=template["composition_note"],
                literal_note=(
                    "A2 invented story dialogue / exercise-role line; "
                    "not an attested quotation."
                ),
                family=family,
            )
            family.setdefault("members", []).append(item)
            existing_member_ids.add(member_id)
            existing_texts.add(text)
            new_members += 1
            new_unique_texts += 1
            families_touched.add(family["id"])
            counties_touched.add(county)
            if exercise_id not in existing_exercise_ids:
                new_exercises.append(
                    exercise_record(
                        exercise_id,
                        story_id,
                        county,
                        member_id,
                        template["response_family"],
                        text,
                        english_intent,
                    )
                )
                existing_exercise_ids.add(exercise_id)
        return family_ref["path"]

    for county in sorted(STORIES):
        place_label = atlas["counties"][county]["display"]
        words = atlas["counties"][county]["words"]
        deepen = county in deepen_counties
        word_limit = deepen_words if deepen else lean_words
        templates = [
            template
            for template in STORY_DIALOGUE_ROLE_TEMPLATES
            if template["tier"] == "lean" or deepen
        ]
        host_family_path: str | None = None
        sceal_family_path: str | None = None
        for position, word in enumerate(words, start=1):
            if word["ga"] == "scéal":
                path = append_templates_for_word(
                    county=county,
                    place_label=place_label,
                    position=position,
                    word=word,
                    templates=templates,
                )
                if path is not None:
                    sceal_family_path = path
                continue
            if position > word_limit:
                continue
            path = append_templates_for_word(
                county=county,
                place_label=place_label,
                position=position,
                word=word,
                templates=templates,
            )
            if host_family_path is None and path is not None:
                host_family_path = path

        story_host_path = sceal_family_path or host_family_path
        if story_host_path is not None:
            host = get_family(story_host_path)
            existing_member_ids = {item.get("id") for item in host.get("members", [])}
            story_members, story_exercises = story_level_members_for_county(
                county=county,
                place_label=place_label,
                family=host,
                existing_member_ids=existing_member_ids,
                existing_texts=existing_texts,
            )
            if story_members:
                host.setdefault("members", []).extend(story_members)
                new_members += len(story_members)
                new_unique_texts += len(story_members)
                families_touched.add(host["id"])
                counties_touched.add(county)
                for record in story_exercises:
                    if record["id"] not in existing_exercise_ids:
                        new_exercises.append(record)
                        existing_exercise_ids.add(record["id"])

    for path, family in family_cache.items():
        if family["id"] in families_touched:
            (ROOT / path).write_text(
                json.dumps(family, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )

    uses["stories"] = dedupe_stories(list(uses.get("stories", [])) + new_stories)
    uses["exercises"] = sorted(
        list(uses.get("exercises", [])) + new_exercises,
        key=lambda item: item["id"],
    )
    USES_PATH.write_text(json.dumps(uses, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    return {
        "status": "generated",
        "mode": "story-dialogue",
        "counties": sorted(counties_touched),
        "county_count": len(counties_touched),
        "families_touched": len(families_touched),
        "new_members": new_members,
        "new_unique_texts": new_unique_texts,
        "new_exercises": len(new_exercises),
        "stories_after_dedupe": len(uses["stories"]),
        "lean_words": lean_words,
        "deepen_words": deepen_words,
        "deepen_counties": list(deepen_counties),
    }


def family_for(county: str, position: int, atlas_record: dict, place_label: str) -> tuple[dict, list[dict], list[dict]]:
    ga = atlas_record["ga"]
    gloss = atlas_record["en"]
    story_slug, _, _ = STORIES[county]
    story_id = f"d32.{county}.{story_slug}"
    family_id = f"d32.{county}.{position:02d}.{slug(ga)}.{slug(gloss)}"
    placement_id = f"atlas.{county}.{position:02d}.{slug(ga)}"
    opening_id = f"{family_id}.opening"
    second_kind = (position + len(county)) % 3
    if second_kind == 0:
        second_id = f"{family_id}.dialogue"
        second_text = f"An bhfuil {ga} anseo?"
        second_intent = f"Is the {gloss} here?"
        second_role = "dialogue_turn"
        second_stage = "phrase_or_sentence_use"
        second_family = "freeTyping"
        second_purpose = f"Reuse {ga} in a short county-bound question after the opening encounter."
    elif second_kind == 1:
        second_id = f"{family_id}.recap"
        second_text = f"Féach ar {ga}."
        second_intent = f"Look at the {gloss}."
        second_role = "story_recap"
        second_stage = "later_reuse"
        second_family = "freeTyping"
        second_purpose = f"Recap the {gloss} placement with a short present-day instruction."
    else:
        second_id = f"{family_id}.return"
        second_text = f"Tá {ga} sa scéal."
        second_intent = f"The {gloss} is in the story."
        second_role = "story_recap"
        second_stage = "later_reuse"
        second_family = "freeTyping"
        second_purpose = f"Carry {ga} from the place opening into a reusable story recap."
    opening_exercise_id = f"{story_id}.opening.{position:02d}"
    second_exercise_id = f"{story_id}.{second_id.rsplit('.', 1)[-1]}.{position:02d}"
    opening_text = f"Tá {ga} anseo."
    family = {
        "schema_version": 2,
        "contract": "irish_phrase_family",
        "id": family_id,
        "county": county,
        "story_ref": {"path": "content/audio/authoring/d32-county-harvest-uses.json", "record_id": story_id},
        "target": {
            "lexeme_id": f"lex.{slug(ga)}",
            "citation_form": ga,
            "sense_id": f"{county}.{slug(ga)}.{slug(gloss)}",
            "part_of_speech": POS_BY_GA.get(ga, "lexical item"),
            "english_sense": gloss,
        },
        "atlas_placements": [{"id": placement_id, "gloss": gloss}],
        "status": "draft",
        "claims": {"linguistic_approval": False, "historical_authenticity": False, "note": "D32 provisional family; text is invented pedagogical material and carries no attestation or release claim."},
        "members": [],
    }
    family["members"] = [
        member(
            family_id=family_id, member_id=opening_id, county=county, story_id=story_id,
            placement_id=placement_id, place_label=place_label, ga=ga, gloss=gloss,
            text=opening_text, english_intent=f"The {gloss} is here.", role="story_opening",
            stage="introduction", exercise_id=opening_exercise_id, response_family="listenChoose",
            purpose=f"Open the {county} story with the atlas-bound {gloss} at its named place.",
        ),
        member(
            family_id=family_id, member_id=second_id, county=county, story_id=story_id,
            placement_id=placement_id, place_label=place_label, ga=ga, gloss=gloss,
            text=second_text, english_intent=second_intent, role=second_role,
            stage=second_stage, exercise_id=second_exercise_id, response_family=second_family,
            purpose=second_purpose,
        ),
    ]
    exercises = [
        exercise_record(opening_exercise_id, story_id, county, opening_id, "listenChoose", opening_text, f"The {gloss} is here."),
        exercise_record(second_exercise_id, story_id, county, second_id, second_family, second_text, second_intent),
    ]
    return family, exercises, [story_record(county, atlas_record, place_label)]


def generate_scaffold(*, count_families: int, created_at: str) -> dict[str, Any]:
    atlas = json.loads(ATLAS_PATH.read_text(encoding="utf-8"))
    store = json.loads(STORE_PATH.read_text(encoding="utf-8"))
    uses = json.loads(USES_PATH.read_text(encoding="utf-8")) if USES_PATH.is_file() else {
        "schema_version": 1,
        "contract": "d32_county_harvest_uses",
        "created_at": created_at,
        "status": "provisional_authoring_input_only",
        "stories": [],
        "exercises": [],
    }
    covered = {
        placement.get("id")
        for family_ref in store.get("family_documents", [])
        for family in [json.loads((ROOT / family_ref["path"]).read_text(encoding="utf-8"))]
        for placement in family.get("atlas_placements", [])
    }
    candidates = []
    for county in sorted(atlas["counties"]):
        for position, word in enumerate(atlas["counties"][county]["words"], start=1):
            placement_id = f"atlas.{county}.{position:02d}.{slug(word['ga'])}"
            if placement_id not in covered:
                candidates.append((county, position, word))
    selected = candidates[:count_families]
    if not selected:
        return {"status": "complete", "remaining_uncovered_placements": 0}

    existing_family_refs = list(store.get("family_documents", []))
    existing_story_ids = {item.get("id") for item in uses.get("stories", [])}
    existing_exercise_ids = {item.get("id") for item in uses.get("exercises", [])}
    new_families = []
    new_exercises = []
    new_stories = []
    for county, position, word in selected:
        family, exercises, stories = family_for(
            county, position, word, atlas["counties"][county]["display"]
        )
        family_path = ROOT / f"content/{county}/phrase-families/authoring-v2/{family['id']}.v2.json"
        family_path.parent.mkdir(parents=True, exist_ok=True)
        family_path.write_text(json.dumps(family, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        new_families.append({"family_id": family["id"], "path": str(family_path.relative_to(ROOT))})
        for record in exercises:
            if record["id"] not in existing_exercise_ids:
                new_exercises.append(record)
                existing_exercise_ids.add(record["id"])
        for record in stories:
            if record["id"] not in existing_story_ids:
                new_stories.append(record)
                existing_story_ids.add(record["id"])

    store["family_documents"] = sorted(
        existing_family_refs + new_families, key=lambda item: item["family_id"]
    )
    STORE_PATH.write_text(json.dumps(store, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    uses["stories"] = dedupe_stories(list(uses.get("stories", [])) + new_stories)
    uses["exercises"] = sorted(
        list(uses.get("exercises", [])) + new_exercises,
        key=lambda item: item["id"],
    )
    USES_PATH.write_text(json.dumps(uses, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    counties = sorted({county for county, _, _ in selected})
    return {
        "status": "generated",
        "mode": "scaffold",
        "families": len(selected),
        "members": len(selected) * 2,
        "counties": counties,
        "first_family": new_families[0]["family_id"],
        "last_family": new_families[-1]["family_id"],
        "remaining_uncovered_placements": len(candidates) - len(selected),
        "stories_after_dedupe": len(uses["stories"]),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--mode",
        choices=("scaffold", "story-dialogue"),
        default="scaffold",
        help="scaffold creates uncovered families; story-dialogue appends A2 dialogue/role lines",
    )
    parser.add_argument("--count-families", type=int, default=128)
    parser.add_argument("--created-at", default="2026-08-02T12:00:00Z")
    parser.add_argument(
        "--lean-words",
        type=int,
        default=4,
        help="Atlas words per county for the lean all-32 dialogue pass",
    )
    parser.add_argument(
        "--deepen-words",
        type=int,
        default=6,
        help="Atlas words per deepen county (Mayo + queue-02 by default)",
    )
    parser.add_argument(
        "--deepen-counties",
        default=",".join(DEEPEN_COUNTIES),
        help="Comma-separated counties that receive deepen-tier role templates",
    )
    args = parser.parse_args()
    if args.count_families <= 0:
        raise SystemExit("--count-families must be positive")
    if args.lean_words <= 0 or args.deepen_words <= 0:
        raise SystemExit("--lean-words and --deepen-words must be positive")

    if args.mode == "story-dialogue":
        deepen = tuple(
            county.strip()
            for county in args.deepen_counties.split(",")
            if county.strip()
        )
        unknown = sorted(set(deepen) - set(STORIES))
        if unknown:
            raise SystemExit(f"unknown deepen counties: {', '.join(unknown)}")
        result = append_story_dialogue_tranche(
            lean_words=args.lean_words,
            deepen_words=args.deepen_words,
            deepen_counties=deepen,
        )
    else:
        result = generate_scaffold(
            count_families=args.count_families,
            created_at=args.created_at,
        )
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
