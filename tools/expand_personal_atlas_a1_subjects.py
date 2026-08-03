#!/usr/bin/env python3
"""Build the A1 Personal Atlas authoring bulk subject list.

Writes content/personal-atlas/a1-bulk-subjects.json for offline family authoring.
Does not call a provider. Place rows are selected from the bundled Logainm
foundation snapshot; name rows are curated pedagogical shells with provisional
editorial notes only. This file is an authoring input, not a learner-release pack.
"""

from __future__ import annotations

import json
import re
import sqlite3
import unicodedata
from collections import defaultdict
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SUBJECTS_PATH = ROOT / "ios/AnTuras/Resources/personal-atlas-subjects.json"
FOUNDATION_PATH = ROOT / "ios/AnTuras/Resources/personal-atlas-foundation.sqlite"
OUTPUT_PATH = ROOT / "content/personal-atlas/a1-bulk-subjects.json"
GENERATOR_PATH = ROOT / "tools/generate_personal_atlas_name_place_families.py"

CONTENT_DATE = "2026-08-03"
PLACES_PER_COUNTY = 7
WANTED_PLACE_KINDS = (
    "town",
    "city",
    "population centre",
    "village",
    "island or archipelago",
    "castle",
    "ecclesiastical site",
    "monument",
)
PLACE_KIND_PRIORITY = {
    "city": 0,
    "town": 1,
    "population centre": 2,
    "village": 3,
    "island or archipelago": 4,
    "castle": 5,
    "ecclesiastical site": 6,
    "monument": 7,
}
PLACE_KIND_MAP = {
    "city": "city",
    "town": "town",
    "population centre": "town",
    "village": "village",
    "island or archipelago": "island",
    "castle": "castle",
    "ecclesiastical site": "ecclesiastical site",
    "monument": "historic site",
}
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

# Curated present-day pedagogical name shells. Not historical roleplay subjects;
# leave STORY_SLATE_SUBJECTS / A8 historical names alone.
GIVEN_NAMES: tuple[tuple[str, str, tuple[str, ...], str], ...] = (
    ("aodan", "Aodán", ("Aidan", "Aodhan"), "Irish given name used in present-day Personal Atlas practice."),
    ("caoimhe", "Caoimhe", ("Keeva", "Kwee-va"), "Irish given name used in present-day Personal Atlas practice."),
    ("clodagh", "Clodagh", ("Cloda",), "Irish given name used in present-day Personal Atlas practice."),
    ("conall", "Conall", ("Connell",), "Irish given name used in present-day Personal Atlas practice."),
    ("conchur", "Conchúr", ("Conor", "Connor"), "Irish given name used in present-day Personal Atlas practice."),
    ("daithi", "Dáithí", ("Dathi", "David"), "Irish given name used in present-day Personal Atlas practice."),
    ("eabha", "Eabha", ("Eva",), "Irish given name used in present-day Personal Atlas practice."),
    ("eilis", "Eilís", ("Eilis", "Elizabeth"), "Irish given name used in present-day Personal Atlas practice."),
    ("fiadh", "Fiadh", ("Fia",), "Irish given name used in present-day Personal Atlas practice."),
    ("fionn", "Fionn", ("Finn",), "Irish given name used in present-day Personal Atlas practice."),
    ("ide", "Íde", ("Ita",), "Irish given name used in present-day Personal Atlas practice."),
    ("laoise", "Laoise", ("Luíse",), "Irish given name used in present-day Personal Atlas practice."),
    ("lorcan", "Lorcán", ("Lorcan", "Laurence"), "Irish given name used in present-day Personal Atlas practice."),
    ("meabh", "Méabh", ("Maeve",), "Irish given name used in present-day Personal Atlas practice."),
    ("maghnus", "Maghnus", ("Manus", "Magnus"), "Irish given name used in present-day Personal Atlas practice."),
    ("muireann", "Muireann", ("Muirenn",), "Irish given name used in present-day Personal Atlas practice."),
    ("oisin", "Oisín", ("Oisin", "Ossian"), "Irish given name used in present-day Personal Atlas practice."),
    ("peadar", "Peadar", ("Peter",), "Irish given name used in present-day Personal Atlas practice."),
    ("sadhbh", "Sadhbh", ("Sive",), "Irish given name used in present-day Personal Atlas practice."),
    ("seamus", "Séamus", ("Seamus", "James"), "Irish given name used in present-day Personal Atlas practice."),
    ("seosamh", "Seosamh", ("Joseph", "Joe"), "Irish given name used in present-day Personal Atlas practice."),
    ("sorcha", "Sorcha", ("Sarah",), "Irish given name used in present-day Personal Atlas practice."),
    ("una", "Úna", ("Una", "Oona"), "Irish given name used in present-day Personal Atlas practice."),
    ("cathal", "Cathal", ("Cahal",), "Irish given name used in present-day Personal Atlas practice."),
    ("daire", "Dáire", ("Darragh", "Dara"), "Irish given name used in present-day Personal Atlas practice."),
    ("eoghan", "Eoghan", ("Owen",), "Irish given name used in present-day Personal Atlas practice."),
    ("fearghal", "Fearghal", ("Fergal",), "Irish given name used in present-day Personal Atlas practice."),
    ("neasa", "Neasa", ("Nessa",), "Irish given name used in present-day Personal Atlas practice."),
    ("riona", "Ríona", ("Riona",), "Irish given name used in present-day Personal Atlas practice."),
    ("tomas", "Tomás", ("Thomas", "Tomas"), "Irish given name used in present-day Personal Atlas practice."),
    ("proinsias", "Proinsias", ("Francis",), "Irish given name used in present-day Personal Atlas practice."),
    ("gearoid", "Gearóid", ("Gerald", "Garrett"), "Irish given name used in present-day Personal Atlas practice."),
    ("breandan", "Breandán", ("Brendan",), "Irish given name used in present-day Personal Atlas practice."),
    ("colm", "Colm", ("Colum",), "Irish given name used in present-day Personal Atlas practice."),
    ("diarmaid", "Diarmaid", ("Dermot", "Diarmuid"), "Irish given name used in present-day Personal Atlas practice."),
    ("eanna", "Éanna", ("Enda",), "Irish given name used in present-day Personal Atlas practice."),
    ("fiachra", "Fiachra", (), "Irish given name used in present-day Personal Atlas practice."),
    ("gobnait", "Gobnait", ("Deborah",), "Irish given name used in present-day Personal Atlas practice."),
    ("liadan", "Líadan", ("Liadin",), "Irish given name used in present-day Personal Atlas practice."),
    ("orlaith", "Órlaith", ("Orlaith",), "Irish given name used in present-day Personal Atlas practice."),
    ("ruairi", "Ruairí", ("Rory", "Ruairi"), "Irish given name used in present-day Personal Atlas practice."),
    ("toirdhealbhach", "Toirdhealbhach", ("Turlough",), "Irish given name used in present-day Personal Atlas practice."),
    ("blathnaid", "Bláthnaid", ("Blanid",), "Irish given name used in present-day Personal Atlas practice."),
    ("caoilfhionn", "Caoilfhionn", ("Keelin",), "Irish given name used in present-day Personal Atlas practice."),
    ("eithne", "Eithne", ("Edna", "Enya"), "Irish given name used in present-day Personal Atlas practice."),
    ("nuala", "Nuala", (), "Irish given name used in present-day Personal Atlas practice."),
    ("pilib", "Pilib", ("Philip",), "Irish given name used in present-day Personal Atlas practice."),
    ("raine", "Ráine", ("Raine",), "Irish given name used in present-day Personal Atlas practice."),
    ("sinead", "Sinéad", ("Sinead", "Jane"), "Irish given name used in present-day Personal Atlas practice."),
    ("tiarnan", "Tiarnán", ("Tiernan",), "Irish given name used in present-day Personal Atlas practice."),
    ("uainin", "Uainín", ("Uainin",), "Irish given name used in present-day Personal Atlas practice."),
    ("aoibheann", "Aoibheann", ("Eavan",), "Irish given name used in present-day Personal Atlas practice."),
    ("caitlin", "Caitlín", ("Kathleen", "Caitlin"), "Irish given name used in present-day Personal Atlas practice."),
    ("domhnall", "Domhnall", ("Donald",), "Irish given name used in present-day Personal Atlas practice."),
    ("fionntan", "Fionntán", ("Fintan",), "Irish given name used in present-day Personal Atlas practice."),
    ("mairead", "Máiréad", ("Margaret", "Mairead"), "Irish given name used in present-day Personal Atlas practice."),
    ("seafraid", "Séafraid", ("Jeffrey", "Geoffrey"), "Irish given name used in present-day Personal Atlas practice."),
    ("aine", "Áine", ("Anya",), "Irish given name used in present-day Personal Atlas practice."),
    ("donncha", "Donncha", ("Duncan", "Donagh"), "Irish given name used in present-day Personal Atlas practice."),
    ("lasairfhiona", "Lasairfhíona", ("Lassarina",), "Irish given name used in present-day Personal Atlas practice."),
    ("muirne", "Muirne", ("Morna",), "Irish given name used in present-day Personal Atlas practice."),
    ("oibhear", "Oibhear", ("Ivor",), "Irish given name used in present-day Personal Atlas practice."),
)

SURNAMES: tuple[tuple[str, str, tuple[str, ...], str | None, str], ...] = (
    ("oconnor", "Ó Conchúir", ("O'Connor", "O Connor"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("oneill", "Ó Néill", ("O'Neill", "O Neill"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("odonnell", "Ó Domhnaill", ("O'Donnell", "O Donnell"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("macdermott", "Mac Diarmada", ("MacDermott", "McDermott"), "mac", "Irish surname form used in present-day Personal Atlas practice."),
    ("oshea", "Ó Sé", ("O'Shea", "O Shea"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("ohughes", "Ó hAodha", ("Hughes", "Hayes"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("maher", "Ó Meachair", ("Maher", "Meagher"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("gilbride", "Mac Giolla Bhríde", ("Kilbride", "Gilbride"), "mac", "Irish surname form used in present-day Personal Atlas practice."),
    ("higgins", "Ó hUiginn", ("Higgins", "O'Higgins"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("kyne", "Ó Cadhain", ("Kyne", "Coyne"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("flynn", "Ó Floinn", ("Flynn", "O'Flynn"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("mahon", "Mac Mathúna", ("MacMahon", "McMahon"), "mac", "Irish surname form used in present-day Personal Atlas practice."),
    ("malone", "Ó Maoileoin", ("Malone",), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("hara", "Ó hEadhra", ("O'Hara", "Hara"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("mcgee", "Mac Aodha", ("McGee", "Magee"), "mac", "Irish surname form used in present-day Personal Atlas practice."),
    ("casey", "Ó Cathasaigh", ("Casey", "O'Casey"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("daly", "Ó Dálaigh", ("Daly", "O'Daly"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("ward", "Mac an Bhaird", ("Ward", "MacWard"), "mac", "Irish surname form used in present-day Personal Atlas practice."),
    ("dwyer", "Ó Duibhir", ("Dwyer", "O'Dwyer"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("hennessy", "Ó hAonghusa", ("Hennessy", "Hennessey"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("roche", "de Róiste", ("Roche",), "de", "Irish surname form used in present-day Personal Atlas practice."),
    ("hanlon", "Ó hAnluain", ("Hanlon", "O'Hanlon"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("mcsweeney", "Mac Suibhne", ("McSweeney", "Sweeney"), "mac", "Irish surname form used in present-day Personal Atlas practice."),
    ("toole", "Ó Tuathail", ("Toole", "O'Toole"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("brennan", "Ó Braonáin", ("Brennan", "O'Brennan"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("costello", "Mac Coisdealbha", ("Costello",), "mac", "Irish surname form used in present-day Personal Atlas practice."),
    ("heynes", "Ó hEidhin", ("Heynes", "Hynes"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("mulryan", "Ó Maoilriain", ("Mulryan",), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("geary", "Ó Gadhra", ("Geary", "O'Gara"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("cassidy", "Ó Caiside", ("Cassidy",), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("flaherty", "Ó Flaithbheartaigh", ("Flaherty", "O'Flaherty"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("mcgrath", "Mac Craith", ("McGrath", "Magraith"), "mac", "Irish surname form used in present-day Personal Atlas practice."),
    ("sheehan", "Ó Síocháin", ("Sheehan", "Sheahan"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("curran", "Ó Corráin", ("Curran",), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("duffy", "Ó Dubhthaigh", ("Duffy",), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("keane", "Ó Catháin", ("Keane", "O'Kane"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("mcloughlin", "Mac Lochlainn", ("McLoughlin", "MacLoughlin"), "mac", "Irish surname form used in present-day Personal Atlas practice."),
    ("oboyle", "Ó Baoill", ("O'Boyle", "Boyle"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
    ("redmond", "Mac Réamoinn", ("Redmond",), "mac", "Irish surname form used in present-day Personal Atlas practice."),
    ("scanlon", "Ó Scannláin", ("Scanlon", "Scanlan"), "ó", "Irish surname form used in present-day Personal Atlas practice."),
)


def nfc(value: str) -> str:
    return unicodedata.normalize("NFC", value)


def search_keys(*values: str) -> list[str]:
    keys: set[str] = set()
    for value in values:
        if not value:
            continue
        folded = unicodedata.normalize("NFKD", value)
        folded = "".join(char for char in folded if not unicodedata.combining(char))
        folded = re.sub(r"[^a-z0-9]+", " ", folded.casefold()).strip()
        if folded:
            keys.add(folded)
            keys.add(folded.replace(" ", ""))
    return sorted(keys)


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def reserved_displays() -> set[str]:
    reserved: set[str] = set()
    for subject in load_json(SUBJECTS_PATH).get("subjects", []):
        reserved.add(str(subject.get("canonicalDisplay", "")).casefold())
        for variant in subject.get("variants") or []:
            reserved.add(str(variant).casefold())
    text = GENERATOR_PATH.read_text(encoding="utf-8")
    for match in re.finditer(r'"canonicalDisplay":\s*"([^"]+)"', text):
        reserved.add(match.group(1).casefold())
    for match in re.finditer(r'"variants":\s*\[(.*?)\]', text, flags=re.S):
        for variant in re.findall(r'"([^"]+)"', match.group(1)):
            reserved.add(variant.casefold())
    return {item for item in reserved if item}


def reserved_ids() -> set[str]:
    ids = {subject["id"] for subject in load_json(SUBJECTS_PATH).get("subjects", [])}
    text = GENERATOR_PATH.read_text(encoding="utf-8")
    ids.update(re.findall(r'"id":\s*"(name\.[^"]+|place\.[^"]+|historical\.name\.[^"]+)"', text))
    return ids


def make_name_subject(
    *,
    subject_id: str,
    display: str,
    variants: tuple[str, ...],
    name_kind: str,
    grammar: str | None,
    summary: str,
    county: str,
) -> dict[str, Any]:
    display = nfc(display)
    variant_list = [nfc(item) for item in variants if nfc(item) != display]
    evidence_id = f"ev.{subject_id}.1"
    return {
        "id": subject_id,
        "kind": "name",
        "canonicalDisplay": display,
        "variants": variant_list,
        "languages": ["ga", "en"],
        "searchKeys": search_keys(display, *variant_list),
        "subtitle": "Given name" if name_kind == "given" else "Surname",
        "depth": "foundation",
        "county": county,
        "nameProfile": {
            "nameKind": name_kind,
            "grammar": grammar,
            "pronunciations": [
                {
                    "text": display,
                    "phonetic": None,
                    "dialect": "relevant",
                    "audioState": "unavailable",
                }
            ],
            "historicalForms": [
                {"display": display, "year": None, "note": "Modern Irish", "language": "ga"},
                *[
                    {"display": variant, "year": None, "note": "Common English or variant form", "language": "en"}
                    for variant in variant_list[:2]
                ],
            ],
            "etymologyBranches": [
                {
                    "label": "Provisional shell",
                    "certainty": "recorded",
                    "summary": summary,
                    "components": [],
                }
            ],
            "distributions": [],
            "peopleLinks": [],
        },
        "placeProfile": None,
        "editorial": {
            "shortAnswer": summary,
            "storyBeats": [],
            "languageMoment": None,
            "saveExcerpt": summary,
            "contentVersion": "1.0.0",
            "releaseState": "pilot",
            "storyHandoff": None,
            "deeperStoryMessage": "The deeper story is still being researched.",
            "familyHistoryNote": (
                None
                if name_kind == "given"
                else "A surname’s history is not a family tree."
            ),
        },
        "assertions": [
            {
                "statement": summary,
                "scope": "Ireland",
                "certainty": "recorded",
                "evidenceIds": [evidence_id],
                "competingAssertionIds": [],
                "reviewer": "pilot-editorial",
                "reviewedAt": CONTENT_DATE,
                "rightsState": "reviewed-for-pilot",
            }
        ],
        "evidence": [
            {
                "id": evidence_id,
                "sourceType": "editorial-synthesis",
                "citation": "A1 Personal Atlas authoring shell — provisional pedagogical name form pending specialist sign-off.",
                "stableURL": None,
                "dateBounds": None,
                "attribution": "An Turas A1 authoring",
                "transcription": None,
                "translation": None,
                "imageRights": None,
                "audioRights": None,
            }
        ],
        "authoring_source": {
            "path": "content/personal-atlas/a1-bulk-subjects.json",
            "record_id": subject_id,
            "supports": "pattern_only",
        },
    }


def make_place_subject(row: dict[str, Any]) -> dict[str, Any]:
    irish = nfc(str(row["irish"]))
    english = nfc(str(row["english"] or row["canonical"]))
    subject_id = f"place.logainm-{row['id']}"
    place_kind = PLACE_KIND_MAP[row["place_kind"]]
    hierarchy = str(row["hierarchy"])
    summary = (
        f"{irish} is a present-day Irish place-name form recorded in the bundled Logainm snapshot"
        f" ({english}; {place_kind})."
    )
    evidence_id = f"ev.{subject_id}.1"
    variants = [english]
    if english.casefold() != irish.casefold():
        variants.append(irish)
    coordinates = None
    if row["lat"] is not None and row["lon"] is not None:
        coordinates = {"lat": float(row["lat"]), "lon": float(row["lon"])}
    return {
        "id": subject_id,
        "kind": "place",
        "canonicalDisplay": irish,
        "variants": variants,
        "languages": ["ga", "en"],
        "searchKeys": search_keys(irish, english, *variants),
        "subtitle": f"{place_kind} · {hierarchy}",
        "depth": "foundation",
        "nameProfile": None,
        "placeProfile": {
            "logainmId": int(row["id"]),
            "placeKind": place_kind,
            "hierarchy": hierarchy,
            "coordinates": coordinates,
            "pronunciations": [
                {
                    "text": irish,
                    "phonetic": None,
                    "dialect": "relevant",
                    "audioState": "unavailable",
                },
                {
                    "text": english,
                    "phonetic": None,
                    "dialect": "en",
                    "audioState": "unavailable",
                },
            ],
            "historicalForms": [
                {"display": irish, "year": None, "note": "Irish", "language": "ga"},
                {"display": english, "year": None, "note": "English", "language": "en"},
            ],
            "derivationBranches": [
                {
                    "label": "Logainm-backed shell",
                    "certainty": "recorded",
                    "summary": summary,
                    "components": [],
                }
            ],
            "featureLinks": [],
            "storyLinks": [],
        },
        "editorial": {
            "shortAnswer": summary,
            "storyBeats": [],
            "languageMoment": None,
            "saveExcerpt": summary,
            "contentVersion": "1.0.0",
            "releaseState": "pilot",
            "storyHandoff": None,
            "deeperStoryMessage": "The deeper story is still being researched.",
            "familyHistoryNote": None,
        },
        "assertions": [
            {
                "statement": summary,
                "scope": hierarchy.rsplit("/", 1)[-1].strip() or "Ireland",
                "certainty": "recorded",
                "evidenceIds": [evidence_id],
                "competingAssertionIds": [],
                "reviewer": "pilot-editorial",
                "reviewedAt": CONTENT_DATE,
                "rightsState": "reviewed-for-pilot",
            }
        ],
        "evidence": [
            {
                "id": evidence_id,
                "sourceType": "logainm",
                "citation": "Bundled Logainm foundation snapshot used as a pattern source for Personal Atlas place forms.",
                "stableURL": row["permalink"] or "https://www.logainm.ie/en",
                "dateBounds": None,
                "attribution": "Irish-language placename data by Logainm © Government of Ireland and licensed under CC BY 4.0.",
                "transcription": None,
                "translation": None,
                "imageRights": None,
                "audioRights": None,
            }
        ],
        "authoring_source": {
            "path": "content/personal-atlas/a1-bulk-subjects.json",
            "record_id": subject_id,
            "supports": "pattern_only",
        },
    }


def ainm_counties() -> list[str]:
    counties: list[str] = []
    for path in sorted(ROOT.glob("content/*/phrase-families/authoring-v2/d32.*.v2.json")):
        family = load_json(path)
        if (family.get("target") or {}).get("citation_form") == "ainm":
            county = family.get("county")
            if isinstance(county, str):
                counties.append(county)
    for path in sorted(ROOT.glob("content/*/phrase-families/authoring-v2/ainm.name-noun.v2.json")):
        family = load_json(path)
        county = family.get("county")
        if isinstance(county, str) and county not in counties:
            counties.append(county)
    return counties or sorted(COUNTY_SLUGS.values())


def build_name_subjects(existing_ids: set[str], existing_displays: set[str]) -> list[dict[str, Any]]:
    subjects: list[dict[str, Any]] = []
    counties = ainm_counties()
    index = 0
    for slug, display, variants, summary in GIVEN_NAMES:
        subject_id = f"name.given.{slug}"
        forms = {display.casefold(), *(variant.casefold() for variant in variants)}
        if subject_id in existing_ids or forms & existing_displays:
            continue
        subject = make_name_subject(
            subject_id=subject_id,
            display=display,
            variants=variants,
            name_kind="given",
            grammar=None,
            summary=summary,
            county=counties[index % len(counties)],
        )
        subjects.append(subject)
        existing_ids.add(subject_id)
        existing_displays.update(forms)
        index += 1

    for slug, display, variants, grammar, summary in SURNAMES:
        subject_id = f"name.surname.{slug}"
        forms = {display.casefold(), *(variant.casefold() for variant in variants)}
        if subject_id in existing_ids or forms & existing_displays:
            continue
        subject = make_name_subject(
            subject_id=subject_id,
            display=display,
            variants=variants,
            name_kind="surname",
            grammar=grammar,
            summary=summary,
            county=counties[index % len(counties)],
        )
        subjects.append(subject)
        existing_ids.add(subject_id)
        existing_displays.update(forms)
        index += 1
    return subjects


def build_place_subjects(existing_ids: set[str], existing_displays: set[str]) -> list[dict[str, Any]]:
    connection = sqlite3.connect(FOUNDATION_PATH)
    try:
        rows = connection.execute(
            f"""
            SELECT id, canonical, irish, english, place_kind, hierarchy,
                   latitude, longitude, permalink
            FROM places
            WHERE irish IS NOT NULL AND trim(irish) != ''
              AND place_kind IN ({",".join("?" for _ in WANTED_PLACE_KINDS)})
            """,
            WANTED_PLACE_KINDS,
        ).fetchall()
    finally:
        connection.close()

    by_county: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        (
            place_id,
            canonical,
            irish,
            english,
            place_kind,
            hierarchy,
            latitude,
            longitude,
            permalink,
        ) = row
        english_county = str(hierarchy or "").rsplit("/", 1)[-1].strip()
        county = COUNTY_SLUGS.get(english_county)
        if county is None:
            continue
        forms = {
            str(irish).casefold(),
            str(canonical).casefold(),
        }
        if english:
            forms.add(str(english).casefold())
        if forms & existing_displays:
            continue
        # Prefer shorter, settlement-like Irish forms over long descriptive strings.
        if len(str(irish)) > 40:
            continue
        by_county[county].append(
            {
                "id": int(place_id),
                "canonical": canonical,
                "irish": irish,
                "english": english,
                "place_kind": place_kind,
                "hierarchy": hierarchy,
                "lat": latitude,
                "lon": longitude,
                "permalink": permalink,
                "county": county,
            }
        )

    selected: list[dict[str, Any]] = []
    for county in sorted(COUNTY_SLUGS.values()):
        candidates = sorted(
            by_county.get(county, []),
            key=lambda row: (
                PLACE_KIND_PRIORITY.get(row["place_kind"], 99),
                len(str(row["irish"])),
                str(row["irish"]).casefold(),
                int(row["id"]),
            ),
        )
        taken = 0
        seen_english: set[str] = set()
        for row in candidates:
            subject_id = f"place.logainm-{row['id']}"
            if subject_id in existing_ids:
                continue
            english_key = str(row["english"] or row["canonical"]).casefold()
            if english_key in seen_english:
                continue
            irish_key = str(row["irish"]).casefold()
            if irish_key in existing_displays or english_key in existing_displays:
                continue
            subject = make_place_subject(row)
            selected.append(subject)
            existing_ids.add(subject_id)
            existing_displays.add(irish_key)
            existing_displays.add(english_key)
            seen_english.add(english_key)
            taken += 1
            if taken >= PLACES_PER_COUNTY:
                break
    return selected


def main() -> int:
    existing_ids = reserved_ids()
    existing_displays = reserved_displays()
    names = build_name_subjects(existing_ids, existing_displays)
    places = build_place_subjects(existing_ids, existing_displays)
    subjects = [*names, *places]
    payload = {
        "schema_version": 1,
        "contract": "personal_atlas_a1_bulk_subjects",
        "contentDate": CONTENT_DATE,
        "attribution": (
            "Place forms draw on the bundled Logainm foundation snapshot (CC BY 4.0). "
            "Name shells are An Turas A1 authoring syntheses pending specialist review."
        ),
        "coverageNote": (
            "Authoring-only bulk subjects for Track A avenue A1. Not a learner-release "
            "showcase pack. Historical/story-slate names remain owned by A8 via "
            "STORY_SLATE_SUBJECTS."
        ),
        "counts": {
            "subjects": len(subjects),
            "names": len(names),
            "places": len(places),
            "given_names": sum(
                1
                for subject in names
                if (subject.get("nameProfile") or {}).get("nameKind") == "given"
            ),
            "surnames": sum(
                1
                for subject in names
                if (subject.get("nameProfile") or {}).get("nameKind") == "surname"
            ),
        },
        "subjects": subjects,
    }
    write_json(OUTPUT_PATH, payload)
    print(json.dumps({"status": "wrote", "path": str(OUTPUT_PATH.relative_to(ROOT)), **payload["counts"]}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
