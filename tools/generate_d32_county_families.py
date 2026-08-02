#!/usr/bin/env python3
"""Generate deterministic, provisional D32 phrase-family authoring tranches.

This is an offline Track A authoring tool. It creates no audio and never changes a
provider result. The generated Irish is explicitly invented pedagogical material,
bound to a county/story/atlas placement and to a repository exercise ledger so Track
B can prepare resumable manifests without mistaking the text for attestation.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import unicodedata
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ATLAS_PATH = ROOT / "content/audio/atlas-headwords-v1.json"
STORE_PATH = ROOT / "content/audio/authoring/phrase-family-store-v2.json"
USES_PATH = ROOT / "content/audio/authoring/d32-county-harvest-uses.json"


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
) -> dict:
    text = normalize(text)
    risks = {"invented_text", "audio_pronunciation", "source_ambiguity"}
    if any(char in text for char in "áéíóú"): risks.add("fada")
    if ga[:2] in {"bh", "ch", "dh", "fh", "gh", "mh", "ph", "sh", "th", "mb", "gc", "nd", "ng", "bp", "dt"}:
        risks.add("initial_mutation")
    family_story_ref = {"path": "content/audio/authoring/d32-county-harvest-uses.json", "record_id": story_id}
    return {
        "id": member_id,
        "family_id": family_id,
        "target": {
            "lexeme_id": f"lex.{slug(ga)}",
            "citation_form": ga,
            "sense_id": f"{county}.{slug(ga)}.{slug(gloss)}",
            "part_of_speech": POS_BY_GA.get(ga, "lexical item"),
            "target_form": ga,
            "morphology": "atlas citation form; provisional surrounding frame",
        },
        "irish": {
            "text": text,
            "normalized_text": text,
            "inventory_slug": audio_slug(text),
            "text_sha256": text_hash(text),
        },
        "english": {"intent": english_intent, "literal_note": "D32 invented pedagogical line; not an attested quotation."},
        "binding": {
            "county": county,
            "story_ref": family_story_ref,
            "atlas_placement_ids": [placement_id],
            "place": {"id": f"d32.{county}.place", "label": place_label},
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
            "composition_note": "Deterministically composed from the provisional atlas gloss and the county story-slate place binding for the D32 emergency harvest; not attested text.",
            "source_refs": [{
                "path": "content/audio/authoring/d32-county-harvest-uses.json",
                "record_id": exercise_id,
                "supports": "exercise_context",
            }],
        },
        "states": {
            "authoring": {"status": "complete", "revision": 1, "author_ref": "track-a.d32-scale-authoring", "completed_at": "2026-08-02"},
            "reviews": {
                "editorial": {"status": "pending", "record": None},
                "pedagogy": {"status": "pending", "record": None},
                "irish_language": {"status": "pending", "record": None},
            },
            "capture_request": {"status": "planned", "requested_by": None, "requested_at": None, "authorization": None, "batch_line_ids": []},
            "audio_qa": {"status": "not_generated", "record": None, "batch_line_id": None},
            "learner_release": {"status": "blocked", "reasons": ["invented_text", "editorial_review_pending", "pedagogy_review_pending", "irish_language_review_pending", "audio_not_generated"]},
        },
        "risk_flags": sorted(risks),
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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--count-families", type=int, default=128)
    parser.add_argument("--created-at", default="2026-08-02T12:00:00Z")
    args = parser.parse_args()
    if args.count_families <= 0:
        raise SystemExit("--count-families must be positive")

    atlas = json.loads(ATLAS_PATH.read_text(encoding="utf-8"))
    store = json.loads(STORE_PATH.read_text(encoding="utf-8"))
    uses = json.loads(USES_PATH.read_text(encoding="utf-8")) if USES_PATH.is_file() else {
        "schema_version": 1,
        "contract": "d32_county_harvest_uses",
        "created_at": args.created_at,
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
    selected = candidates[:args.count_families]
    if not selected:
        print(json.dumps({"status": "complete", "remaining_uncovered_placements": 0}, indent=2))
        return 0

    existing_family_refs = list(store.get("family_documents", []))
    existing_story_ids = {item.get("id") for item in uses.get("stories", [])}
    existing_exercise_ids = {item.get("id") for item in uses.get("exercises", [])}
    new_families = []
    new_exercises = []
    new_stories = []
    for county, position, word in selected:
        family, exercises, stories = family_for(county, position, word, atlas["counties"][county]["display"])
        family_path = ROOT / f"content/{county}/phrase-families/authoring-v2/{family['id']}.v2.json"
        family_path.parent.mkdir(parents=True, exist_ok=True)
        family_path.write_text(json.dumps(family, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        new_families.append({"family_id": family["id"], "path": str(family_path.relative_to(ROOT))})
        for record in exercises:
            if record["id"] not in existing_exercise_ids:
                new_exercises.append(record)
        for record in stories:
            if record["id"] not in existing_story_ids:
                new_stories.append(record)

    store["family_documents"] = sorted(existing_family_refs + new_families, key=lambda item: item["family_id"])
    STORE_PATH.write_text(json.dumps(store, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    uses["stories"] = sorted(uses.get("stories", []) + new_stories, key=lambda item: item["id"])
    uses["exercises"] = sorted(uses.get("exercises", []) + new_exercises, key=lambda item: item["id"])
    USES_PATH.write_text(json.dumps(uses, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    counties = sorted({county for county, _, _ in selected})
    print(json.dumps({
        "status": "generated",
        "families": len(selected),
        "members": len(selected) * 2,
        "counties": counties,
        "first_family": new_families[0]["family_id"],
        "last_family": new_families[-1]["family_id"],
        "remaining_uncovered_placements": len(candidates) - len(selected),
    }, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
