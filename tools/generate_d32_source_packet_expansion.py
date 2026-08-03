#!/usr/bin/env python3
"""A6 / queue-03: confirm source packets, then expand county phrase families.

Entry order is mandatory:
1. write or confirm a minimal honest source-packet register + place forms;
2. confirm a consuming exercise shell already exists in the uses ledger;
3. only then append net-new complete v2 members bound to new exercise records.

Never calls a speech provider. Invented pedagogical Irish only; no fabricated
historical sources beyond named public starting points and explicit pending gates.
"""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
ATLAS_PATH = ROOT / "content/audio/atlas-headwords-v1.json"
USES_PATH = ROOT / "content/audio/authoring/d32-county-harvest-uses.json"
PACKET_REGISTER_PATH = ROOT / "content/audio/authoring/d32-queue-03-source-packets.json"
LOGAINM_INDEX_PATH = ROOT / "content/personal-atlas/logainm-v2-source-index.json"
CREATED_AT = "2026-08-03"

QUEUE_03_COUNTIES = (
    "antrim",
    "armagh",
    "carlow",
    "cavan",
    "clare",
    "down",
    "fermanagh",
    "kildare",
    "kilkenny",
    "laois",
    "monaghan",
    "sligo",
    "westmeath",
    "wicklow",
)

# Story bindings and honest packet stubs. Irish site forms are asserted only when
# confirmed in the Logainm index or the atlas county display label.
PACKETS: dict[str, dict[str, Any]] = {
    "antrim": {
        "story_slug": "fionn-mac-cumhaill",
        "title": "Fionn mac Cumhaill and the Giant's Causeway",
        "anchor": "Fionn mac Cumhaill · the Giant's Causeway",
        "proposition": (
            "A credited retelling of the Fionn/Benandonner tradition sits beside an "
            "evidence-led explanation of the basalt columns."
        ),
        "language_field": ["coast", "stone", "sea", "giant", "challenge", "myth-versus-geology"],
        "public_starting_sources": [
            {
                "label": "County story slate row",
                "ref": "docs/COUNTY-STORY-SLATE.md",
                "supports": "story identity and language field only",
            },
            {
                "label": "Logainm — Clochán an Aifir / Giant's Causeway",
                "ref": "content/personal-atlas/logainm-v2-source-index.json",
                "supports": "confirmed Irish/English site form",
            },
        ],
        "sites": [
            {
                "id": "clochán-an-aifir",
                "ga": "Clochán an Aifir",
                "en": "Giant's Causeway",
                "status": "logainm_index_confirmed",
            }
        ],
        "gates": [
            "Historian framing of myth versus geology remains open",
            "Irish-language and pedagogy review pending for all invented lines",
        ],
        "authoring_support": "full_provisional",
        "blockers": [],
    },
    "armagh": {
        "story_slug": "book-of-armagh",
        "title": "St Patrick and the Book of Armagh",
        "anchor": "St Patrick · the Book of Armagh",
        "proposition": (
            "A carefully introduced Book of Armagh passage and the two cathedrals "
            "frame learning and belief without treating later tradition as biography."
        ),
        "language_field": ["church", "book", "writing", "town", "belief"],
        "public_starting_sources": [
            {
                "label": "County story slate row",
                "ref": "docs/COUNTY-STORY-SLATE.md",
                "supports": "story identity and language field only",
            }
        ],
        "sites": [],
        "gates": [
            "Manuscript excerpt selection and translation route not yet locked",
            "Distinguish later tradition from secure biography in learner copy",
        ],
        "authoring_support": "full_provisional",
        "blockers": [],
    },
    "carlow": {
        "story_slug": "st-moling",
        "title": "St Moling and St Mullins",
        "anchor": "St Moling · St Mullins on the Barrow",
        "proposition": (
            "Moling's monastery on the Barrow is introduced as tradition-labelled "
            "hagiography, not modern biography."
        ),
        "language_field": ["river", "mill", "monastery", "work", "welcome"],
        "public_starting_sources": [
            {
                "label": "County story slate row",
                "ref": "docs/COUNTY-STORY-SLATE.md",
                "supports": "story identity and language field only",
            }
        ],
        "sites": [],
        "gates": [
            "Best manuscript/translation for Moling's Life needs medievalist check",
            "Irish form for St Mullins not asserted until Logainm-confirmed",
        ],
        "authoring_support": "full_provisional",
        "blockers": [],
    },
    "cavan": {
        "story_slug": "oreillys-east-breifne",
        "title": "Giolla Íosa Ruadh O'Reilly and East Bréifne",
        "anchor": "Giolla Íosa Ruadh O'Reilly · the friary and East Bréifne",
        "proposition": (
            "A named founder and the friary/Tullymongan landscape support local-power "
            "language without inventing private scenes."
        ),
        "language_field": ["lake", "hill", "clan", "market", "build"],
        "public_starting_sources": [
            {
                "label": "County story slate row",
                "ref": "docs/COUNTY-STORY-SLATE.md",
                "supports": "story identity and language field only",
            }
        ],
        "sites": [],
        "gates": [
            "Friary and Tullymongan site Irish forms pending Logainm confirmation",
            "Local-history lead still needs named annal/site extracts",
        ],
        "authoring_support": "full_provisional",
        "blockers": [],
    },
    "clare": {
        "story_slug": "brian-boru-kincora",
        "title": "Brian Boru at Kincora",
        "anchor": "Brian Boru · Kincora and Killaloe",
        "proposition": (
            "Partisan Cogad framing and annal context teach source bias rather than "
            "epic-as-reportage."
        ),
        "language_field": ["king", "river", "fort", "ally", "journey"],
        "public_starting_sources": [
            {
                "label": "County story slate row",
                "ref": "docs/COUNTY-STORY-SLATE.md",
                "supports": "story identity and language field only",
            }
        ],
        "sites": [],
        "gates": [
            "Kincora/Killaloe Irish forms pending Logainm confirmation before site-bound lines",
            "Cogad excerpt must remain labelled partisan",
        ],
        "authoring_support": "full_provisional",
        "blockers": [],
    },
    "down": {
        "story_slug": "patrick-saul",
        "title": "St Patrick at Saul",
        "anchor": "St Patrick · Saul and its later remembrance",
        "proposition": (
            "A labelled medieval Patrick Life excerpt is contrasted with what the "
            "place-name and early church can securely support."
        ),
        "language_field": ["field", "church", "give", "arrive", "return"],
        "public_starting_sources": [
            {
                "label": "County story slate row",
                "ref": "docs/COUNTY-STORY-SLATE.md",
                "supports": "story identity and language field only",
            }
        ],
        "sites": [],
        "gates": [
            "Saul Irish form pending Logainm confirmation",
            "Avoid certainty the sources cannot provide",
        ],
        "authoring_support": "full_provisional",
        "blockers": [],
    },
    "fermanagh": {
        "story_slug": "enniskillen-castle",
        "title": "The Maguires and Enniskillen Castle",
        "anchor": "the Maguires · Enniskillen Castle",
        "proposition": (
            "A documented castle timeline keeps both Gaelic and later settler histories "
            "visible at the river stronghold."
        ),
        "language_field": ["castle", "island", "river", "guard", "rule"],
        "public_starting_sources": [
            {
                "label": "County story slate row",
                "ref": "docs/COUNTY-STORY-SLATE.md",
                "supports": "story identity and language field only",
            }
        ],
        "sites": [],
        "gates": [
            "Enniskillen Irish form pending Logainm confirmation for site-bound lines",
            "Retain both Maguire and garrison histories in future narrative copy",
        ],
        "authoring_support": "full_provisional",
        "blockers": [],
    },
    "kildare": {
        "story_slug": "brigid-fire",
        "title": "Brigid and Kildare's perpetual fire",
        "anchor": "Brigid · Kildare and the perpetual fire tradition",
        "proposition": (
            "A labelled Life extract plus modern fire commemoration keep saintly "
            "tradition distinct from recoverable history."
        ),
        "language_field": ["fire", "food", "home", "share", "kind"],
        "public_starting_sources": [
            {
                "label": "County story slate row",
                "ref": "docs/COUNTY-STORY-SLATE.md",
                "supports": "story identity and language field only",
            },
            {
                "label": "Logainm — Cill Dara / Kildare",
                "ref": "content/personal-atlas/logainm-v2-source-index.json",
                "supports": "confirmed county/site Irish form",
            },
        ],
        "sites": [
            {
                "id": "cill-dara",
                "ga": "Cill Dara",
                "en": "Kildare",
                "status": "logainm_index_confirmed",
            }
        ],
        "gates": [
            "Life-of-Brigid excerpt selection still open",
            "Modern fire commemoration must not be presented as early-medieval fact",
        ],
        "authoring_support": "full_provisional",
        "blockers": [],
    },
    "kilkenny": {
        "story_slug": "alice-kyteler",
        "title": "Alice Kyteler's trial",
        "anchor": "Alice Kyteler · the 1324 trial",
        "proposition": (
            "Age-appropriate court-record language may describe accusation and witness "
            "without turning persecution into a puzzle or game."
        ),
        "language_field": ["court", "accusation", "house", "witness", "say"],
        "public_starting_sources": [
            {
                "label": "County story slate row",
                "ref": "docs/COUNTY-STORY-SLATE.md",
                "supports": "story identity, sensitivity note, language field",
            },
            {
                "label": "Logainm — Cill Chainnigh / Kilkenny",
                "ref": "content/personal-atlas/logainm-v2-source-index.json",
                "supports": "confirmed county Irish form",
            },
        ],
        "sites": [
            {
                "id": "cill-chainnigh",
                "ga": "Cill Chainnigh",
                "en": "Kilkenny",
                "status": "logainm_index_confirmed",
            }
        ],
        "gates": [
            "Sensitive: never author persecution-as-game mechanics",
            "Court-record excerpt selection and age-appropriateness review open",
        ],
        "authoring_support": "bounded_sensitive",
        "blockers": [],
        "authoring_note": (
            "Expand only descriptive present-day story frames; do not add accusation "
            "scoring, guilt puzzles, or playful trial mechanics."
        ),
    },
    "laois": {
        "story_slug": "rock-of-dunamase",
        "title": "The Rock of Dunamase",
        "anchor": "the Rock of Dunamase · the Marshal lordship",
        "proposition": (
            "The fortress monument anchors the midlands lordship story; no invented "
            "resident voice."
        ),
        "language_field": ["rock", "castle", "land", "give", "defend"],
        "public_starting_sources": [
            {
                "label": "County story slate row",
                "ref": "docs/COUNTY-STORY-SLATE.md",
                "supports": "story identity and language field only",
            }
        ],
        "sites": [],
        "gates": [
            "Dunamase Irish form pending local/Logainm verification",
            "Named lord centred only after local verification",
        ],
        "authoring_support": "full_provisional",
        "blockers": [],
    },
    "monaghan": {
        "story_slug": "patrick-kavanagh",
        "title": "Patrick Kavanagh at Iniskeen",
        "anchor": "Patrick Kavanagh · Iniskeen and remembered place",
        "proposition": (
            "Place and memory language may be authored; Kavanagh verse quotation stays "
            "blocked until rights are cleared."
        ),
        "language_field": ["road", "field", "neighbour", "remember", "compare"],
        "public_starting_sources": [
            {
                "label": "County story slate row",
                "ref": "docs/COUNTY-STORY-SLATE.md",
                "supports": "story identity, rights warning, language field",
            }
        ],
        "sites": [],
        "gates": [
            "Kavanagh is not public domain — no verse quotation or close adaptation",
            "Iniskeen Irish form pending Logainm confirmation",
        ],
        "authoring_support": "rights_bounded",
        "blockers": [
            "Literary quotation / commissioned Irish adaptation blocked pending rights"
        ],
        "authoring_note": (
            "Author only invented place/memory pedagogical frames; never quote or "
            "paraphrase Kavanagh poems."
        ),
    },
    "sligo": {
        "story_slug": "yeats-ben-bulben",
        "title": "W. B. Yeats and Ben Bulben",
        "anchor": "W. B. Yeats · Ben Bulben and Sligo",
        "proposition": (
            "Landscape and remembrance language is supported; Yeats must not be made to "
            "speak for all of Sligo, and poem lines need an explicit public-domain route."
        ),
        "language_field": ["mountain", "grave", "dream", "see", "describe"],
        "public_starting_sources": [
            {
                "label": "County story slate row",
                "ref": "docs/COUNTY-STORY-SLATE.md",
                "supports": "story identity and language field only",
            }
        ],
        "sites": [],
        "gates": [
            "Ben Bulben Irish form pending Logainm confirmation",
            "Any Yeats poem/prose line needs an explicit public-domain citation before use",
        ],
        "authoring_support": "full_provisional",
        "blockers": [],
        "authoring_note": "No Yeats quotation in this tranche; landscape frames only.",
    },
    "westmeath": {
        "story_slug": "st-fechin-fore",
        "title": "St Féchín and Fore Abbey",
        "anchor": "St Féchín · Fore Abbey and its monuments",
        "proposition": (
            "A labelled Life extract and an evidence-led site guide; the monument "
            "cluster carries factual learning, not miracle claims."
        ),
        "language_field": ["abbey", "well", "path", "welcome", "old"],
        "public_starting_sources": [
            {
                "label": "County story slate row",
                "ref": "docs/COUNTY-STORY-SLATE.md",
                "supports": "story identity and language field only",
            }
        ],
        "sites": [],
        "gates": [
            "Fore Irish form pending Logainm confirmation",
            "Miracle claims excluded from factual learning frames",
        ],
        "authoring_support": "full_provisional",
        "blockers": [],
    },
    "wicklow": {
        "story_slug": "st-kevin-glendalough",
        "title": "St Kevin and Glendalough",
        "anchor": "St Kevin · Glendalough's valley and monuments",
        "proposition": (
            "A labelled Kevin Life excerpt sits beside material evidence; legends stay "
            "distinct from archaeology."
        ),
        "language_field": ["valley", "lake", "cell", "bird", "quiet"],
        "public_starting_sources": [
            {
                "label": "County story slate row",
                "ref": "docs/COUNTY-STORY-SLATE.md",
                "supports": "story identity and language field only",
            }
        ],
        "sites": [],
        "gates": [
            "Glendalough Irish form pending Logainm confirmation for site-bound lines",
            "Keep legends delightful but never present them as archaeology",
        ],
        "authoring_support": "full_provisional",
        "blockers": [],
    },
}


def normalize(text: str) -> str:
    return " ".join(unicodedata.normalize("NFC", text).strip().split())


def text_hash(text: str) -> str:
    import hashlib

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


def county_ga_en(display: str) -> tuple[str, str]:
    if " / " in display:
        ga, en = display.split(" / ", 1)
        return ga.strip(), en.strip()
    return display.strip(), display.strip()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def confirmed_logainm_irish() -> set[str]:
    if not LOGAINM_INDEX_PATH.is_file():
        return set()
    payload = load_json(LOGAINM_INDEX_PATH)
    return {
        normalize(str(record.get("irish") or ""))
        for record in payload.get("records", [])
        if isinstance(record, dict) and record.get("irish")
    }


def story_id_for(county: str) -> str:
    return f"d32.{county}.{PACKETS[county]['story_slug']}"


def brief_path_for(county: str) -> Path:
    return ROOT / f"content/{county}/{PACKETS[county]['story_slug']}-source-brief.md"


def render_source_brief(county: str, display: str) -> str:
    packet = PACKETS[county]
    county_ga, county_en = county_ga_en(display)
    sites = packet["sites"]
    site_lines = []
    if sites:
        for site in sites:
            site_lines.append(
                f"- `{site['ga']}` / {site['en']} — status: **{site['status']}**"
            )
    else:
        site_lines.append(
            "- No story-site Irish form asserted yet; county bilingual label only "
            f"(`{county_ga}` / {county_en})."
        )
    source_lines = [
        f"- {item['label']} (`{item['ref']}`) — {item['supports']}"
        for item in packet["public_starting_sources"]
    ]
    gate_lines = [f"- {gate}" for gate in packet["gates"]]
    blocker_lines = (
        [f"- {item}" for item in packet["blockers"]]
        if packet["blockers"]
        else ["- None for provisional place-bound pedagogical frames in this stub."]
    )
    note = packet.get("authoring_note")
    note_block = f"\n## Authoring note\n\n{note}\n" if note else ""
    return f"""# {county_en} source packet stub — {packet['title']}

*Queue `queue-03-source-packet` · A6 minimal honest register stub · status:
**research stub, not cleared**. Created {CREATED_AT}. Does not fabricate manuscript
readings, translations, or rights clearances.*

## Identity

| Field | Value |
| --- | --- |
| County | {display} |
| Story id | `{story_id_for(county)}` |
| Anchor | {packet['anchor']} |
| Authoring support | `{packet['authoring_support']}` |
| Review state | Editorial research stub |

## Dramatic proposition

> {packet['proposition']}

## Place forms confirmed in this stub

{chr(10).join(site_lines)}

County label from atlas headwords: **{display}**.

## Public starting sources (honest, not exhaustive)

{chr(10).join(source_lines)}

## Language field the stub supports

{', '.join(packet['language_field'])}

Provisional family expansion may use atlas headwords already bound to this story and
the county place label. It may not quote unlicensed literary text or invent primary-source
wording.

## Open gates

{chr(10).join(gate_lines)}

## Blockers

{chr(10).join(blocker_lines)}
{note_block}
## Board checklist

- [ ] Historian / specialist source register beyond this stub
- [ ] Irish-language pedagogue review of invented lines
- [ ] Rights route for any literary quotation
- [ ] Native-speaker audio QA before learner release
"""


def write_source_brief(county: str, display: str) -> Path:
    path = brief_path_for(county)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(render_source_brief(county, display), encoding="utf-8")
    return path


def build_packet_register(atlas: dict[str, Any], *, write_briefs: bool = True) -> dict[str, Any]:
    confirmed = confirmed_logainm_irish()
    records: list[dict[str, Any]] = []
    counties_out: list[dict[str, Any]] = []
    for county in QUEUE_03_COUNTIES:
        packet = PACKETS[county]
        display = atlas["counties"][county]["display"]
        county_ga, county_en = county_ga_en(display)
        brief = write_source_brief(county, display) if write_briefs else brief_path_for(county)
        county_record = {
            "id": f"d32.packet.{county}.county-form",
            "kind": "county_form",
            "county": county,
            "ga": county_ga,
            "en": county_en,
            "label": display,
            "status": "atlas_confirmed",
            "story_id": story_id_for(county),
            "source_brief": str(brief.relative_to(ROOT)),
        }
        records.append(county_record)
        site_records = []
        for site in packet["sites"]:
            ga = normalize(site["ga"])
            if ga not in confirmed and site["status"] == "logainm_index_confirmed":
                raise SystemExit(
                    f"{county}: site {ga!r} marked logainm_index_confirmed but missing "
                    f"from {LOGAINM_INDEX_PATH.relative_to(ROOT)}"
                )
            site_record = {
                "id": f"d32.packet.{county}.place.{site['id']}",
                "kind": "place_form",
                "county": county,
                "ga": site["ga"],
                "en": site["en"],
                "status": site["status"],
                "story_id": story_id_for(county),
                "source_brief": str(brief.relative_to(ROOT)),
            }
            records.append(site_record)
            site_records.append(site_record)
        counties_out.append(
            {
                "county": county,
                "story_id": story_id_for(county),
                "title": packet["title"],
                "source_brief": str(brief.relative_to(ROOT)),
                "authoring_support": packet["authoring_support"],
                "blockers": list(packet["blockers"]),
                "packet_status": "stub_confirmed",
                "county_form_record_id": county_record["id"],
                "place_form_record_ids": [item["id"] for item in site_records],
                "exercise_shell_status": "confirm_at_runtime",
            }
        )
    return {
        "schema_version": 1,
        "contract": "d32_queue_03_source_packets",
        "created_at": f"{CREATED_AT}T12:00:00Z",
        "status": "provisional_authoring_input_only",
        "queue": "queue-03-source-packet",
        "avenue": "A6",
        "counties": counties_out,
        "records": records,
    }


def member_states() -> dict[str, Any]:
    return {
        "authoring": {
            "status": "complete",
            "revision": 1,
            "author_ref": "track-a.a6-source-packet",
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
    }


def risk_flags_for(text: str) -> list[str]:
    risks = {"invented_text", "audio_pronunciation", "source_ambiguity"}
    if any(char in text for char in "áéíóúÁÉÍÓÚ"):
        risks.add("fada")
    folded = unicodedata.normalize("NFD", text.casefold())
    if re.search(r"\b(?:bh|ch|dh|fh|gh|mh|ph|sh|th|mb|gc|nd|ng|bp|dt)", folded):
        risks.add("initial_mutation")
    return sorted(risks)


def templates_for(county: str, county_ga: str, county_en: str) -> list[dict[str, Any]]:
    """Return member templates supported by the packet."""
    packet = PACKETS[county]
    templates = [
        {
            "suffix": "packet-place",
            "text": f"Tá {{ga}} i {county_ga}.",
            "english": f"There is {{gloss}} in {county_en}.",
            "role": "story_recap",
            "stage": "later_reuse",
            "response_family": "listenChoose",
            "purpose": (
                f"Reuse the atlas headword inside the {county} source-packet county place frame."
            ),
        },
        {
            "suffix": "packet-ask",
            "text": f"An bhfuil {{ga}} i {county_ga}?",
            "english": f"Is there {{gloss}} in {county_en}?",
            "role": "dialogue_turn",
            "stage": "phrase_or_sentence_use",
            "response_family": "freeTyping",
            "purpose": (
                f"Ask a short county-bound question supported by the {county} source-packet stub."
            ),
        },
    ]
    if packet["authoring_support"] == "bounded_sensitive":
        # Keep Kilkenny descriptive; avoid accusation/game framing beyond place reuse.
        templates = [
            {
                "suffix": "packet-place",
                "text": f"Tá {{ga}} i {county_ga}.",
                "english": f"There is {{gloss}} in {county_en}.",
                "role": "story_recap",
                "stage": "later_reuse",
                "response_family": "listenChoose",
                "purpose": (
                    "Descriptive county place frame for the Kilkenny packet; not a trial mechanic."
                ),
            },
            {
                "suffix": "packet-mark",
                "text": f"Cuimhnigh ar {{ga}} i {county_ga}.",
                "english": f"Remember {{gloss}} in {county_en}.",
                "role": "later_reuse",
                "stage": "later_reuse",
                "response_family": "freeTyping",
                "purpose": (
                    "Memory/reuse frame bounded by the Kilkenny sensitivity note in the packet stub."
                ),
            },
        ]
    if packet["authoring_support"] == "rights_bounded":
        templates = [
            {
                "suffix": "packet-place",
                "text": f"Tá {{ga}} i {county_ga}.",
                "english": f"There is {{gloss}} in {county_en}.",
                "role": "story_recap",
                "stage": "later_reuse",
                "response_family": "listenChoose",
                "purpose": (
                    "Place-bound frame for Monaghan; no literary quotation from the packet-blocked corpus."
                ),
            },
            {
                "suffix": "packet-remember",
                "text": f"Cuimhnigh: {{ga}} i {county_ga}.",
                "english": f"Remember: {{gloss}} in {county_en}.",
                "role": "later_reuse",
                "stage": "later_reuse",
                "response_family": "freeTyping",
                "purpose": (
                    "Memory vocabulary supported by the Monaghan stub without quoting Kavanagh."
                ),
            },
        ]
    return templates


def exercise_record(
    *,
    exercise_id: str,
    story_id: str,
    county: str,
    member_id: str,
    family: str,
    text: str,
    translation: str,
) -> dict[str, Any]:
    return {
        "id": exercise_id,
        "county": county,
        "story_ref": story_id,
        "kind": "exercise",
        "exercise": {
            "family": family,
            "prompt": (
                "Listen and notice the county-bound line."
                if family == "listenChoose"
                else "Type the county-bound line."
            ),
            "answer": translation,
            "translation": translation,
            "audioText": text if family == "listenChoose" else None,
            "modelText": text if family == "freeTyping" else None,
            "phraseFamilyMemberIDs": [member_id],
        },
    }


def build_member(
    *,
    family: dict[str, Any],
    suffix: str,
    text: str,
    english: str,
    role: str,
    stage: str,
    response_family: str,
    purpose: str,
    exercise_id: str,
    place_label: str,
    packet_record_id: str,
) -> dict[str, Any]:
    text = normalize(text)
    member_id = f"{family['id']}.{suffix}"
    family_target = family["target"]
    return {
        "id": member_id,
        "family_id": family["id"],
        "target": {
            "lexeme_id": family_target["lexeme_id"],
            "citation_form": family_target["citation_form"],
            "sense_id": family_target["sense_id"],
            "part_of_speech": family_target["part_of_speech"],
            "target_form": family_target["citation_form"],
            "morphology": "atlas citation form; source-packet county place frame",
        },
        "irish": {
            "text": text,
            "normalized_text": text,
            "inventory_slug": audio_slug(text),
            "text_sha256": text_hash(text),
        },
        "english": {
            "intent": english,
            "literal_note": (
                "A6 invented pedagogical line from a queue-03 source-packet stub; "
                "not an attested quotation."
            ),
        },
        "binding": {
            "county": family["county"],
            "story_ref": dict(family["story_ref"]),
            "atlas_placement_ids": [family["atlas_placements"][0]["id"]],
            "place": {"id": f"d32.{family['county']}.place", "label": place_label},
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
                "Deterministic A6 source-packet expansion from the queue-03 stub, "
                "atlas headword, and county place form; not attested text."
            ),
            "source_refs": [
                {
                    "path": "content/audio/authoring/d32-county-harvest-uses.json",
                    "record_id": exercise_id,
                    "supports": "exercise_context",
                },
                {
                    "path": "content/audio/authoring/d32-queue-03-source-packets.json",
                    "record_id": packet_record_id,
                    "supports": "pattern_only",
                },
            ],
        },
        "states": member_states(),
        "risk_flags": risk_flags_for(text),
    }


def existing_normalized_texts() -> set[str]:
    texts: set[str] = set()
    for path in ROOT.glob("content/*/phrase-families/authoring-v2/*.json"):
        family = load_json(path)
        for member in family.get("members", []):
            irish = member.get("irish") or {}
            value = irish.get("normalized_text") or irish.get("text")
            if isinstance(value, str) and value.strip():
                texts.add(normalize(value))
    return texts


def confirm_exercise_shell(uses: dict[str, Any], county: str) -> int:
    return sum(1 for item in uses.get("exercises", []) if item.get("county") == county)


def dedupe_stories(stories: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Keep first story per id, preferring records that carry record_instance_id."""
    by_id: dict[str, dict[str, Any]] = {}
    order: list[str] = []
    for story in stories:
        story_id = story["id"]
        if story_id not in by_id:
            by_id[story_id] = story
            order.append(story_id)
            continue
        current = by_id[story_id]
        if not current.get("record_instance_id") and story.get("record_instance_id"):
            by_id[story_id] = story
    return [by_id[story_id] for story_id in order]


def expand_county(
    *,
    county: str,
    atlas: dict[str, Any],
    uses: dict[str, Any],
    packet_register: dict[str, Any],
    known_texts: set[str],
    dry_run: bool,
) -> dict[str, Any]:
    packet = PACKETS[county]
    if packet["authoring_support"] == "blocked":
        return {
            "county": county,
            "packet_status": "blocked",
            "authored_members": 0,
            "unique_new_texts": 0,
            "blockers": packet["blockers"],
        }

    display = atlas["counties"][county]["display"]
    county_ga, county_en = county_ga_en(display)
    story_id = story_id_for(county)
    shell_count = confirm_exercise_shell(uses, county)
    if shell_count <= 0:
        return {
            "county": county,
            "packet_status": "blocked",
            "authored_members": 0,
            "unique_new_texts": 0,
            "blockers": ["No consuming exercise shell in d32-county-harvest-uses.json"],
        }

    county_meta = next(
        item for item in packet_register["counties"] if item["county"] == county
    )
    county_meta["exercise_shell_status"] = f"confirmed:{shell_count}"
    packet_record_id = county_meta["county_form_record_id"]

    family_paths = sorted(
        (ROOT / f"content/{county}/phrase-families/authoring-v2").glob("d32.*.v2.json")
    )
    templates = templates_for(county, county_ga, county_en)
    existing_exercise_ids = {item.get("id") for item in uses.get("exercises", [])}
    new_exercises: list[dict[str, Any]] = []
    authored = 0
    unique_new = 0
    skipped_collision = 0

    for family_path in family_paths:
        family = load_json(family_path)
        existing_ids = {member.get("id") for member in family.get("members", [])}
        changed = False
        for template in templates:
            ga = family["target"]["citation_form"]
            gloss = family["target"]["english_sense"]
            text = normalize(template["text"].format(ga=ga, gloss=gloss))
            english = template["english"].format(ga=ga, gloss=gloss)
            member_id = f"{family['id']}.{template['suffix']}"
            if member_id in existing_ids:
                continue
            if text in known_texts:
                skipped_collision += 1
                continue
            family_key = family["id"].removeprefix(f"d32.{county}.")
            exercise_id = f"{story_id}.{template['suffix']}.{family_key}"
            if exercise_id in existing_exercise_ids:
                continue
            member = build_member(
                family=family,
                suffix=template["suffix"],
                text=text,
                english=english,
                role=template["role"],
                stage=template["stage"],
                response_family=template["response_family"],
                purpose=template["purpose"],
                exercise_id=exercise_id,
                place_label=display,
                packet_record_id=packet_record_id,
            )
            family.setdefault("members", []).append(member)
            existing_ids.add(member_id)
            known_texts.add(text)
            exercise = exercise_record(
                exercise_id=exercise_id,
                story_id=story_id,
                county=county,
                member_id=member_id,
                family=template["response_family"],
                text=text,
                translation=english,
            )
            new_exercises.append(exercise)
            existing_exercise_ids.add(exercise_id)
            authored += 1
            unique_new += 1
            changed = True
        if changed and not dry_run:
            write_json(family_path, family)

    if new_exercises and not dry_run:
        uses["exercises"] = sorted(
            list(uses.get("exercises", [])) + new_exercises,
            key=lambda item: item["id"],
        )

    return {
        "county": county,
        "packet_status": "stub_confirmed",
        "authoring_support": packet["authoring_support"],
        "exercise_shell": shell_count,
        "authored_members": authored,
        "unique_new_texts": unique_new,
        "skipped_text_collisions": skipped_collision,
        "source_brief": county_meta["source_brief"],
        "blockers": list(packet["blockers"]),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--counties",
        nargs="*",
        default=list(QUEUE_03_COUNTIES),
        help="Subset of queue-03 counties to expand",
    )
    args = parser.parse_args()
    selected = []
    for county in args.counties:
        key = county.strip().lower()
        if key not in PACKETS:
            raise SystemExit(f"unsupported county for A6/queue-03: {county}")
        selected.append(key)

    atlas = load_json(ATLAS_PATH)
    uses = load_json(USES_PATH)
    packet_register = build_packet_register(atlas, write_briefs=not args.dry_run)
    known_texts = existing_normalized_texts()
    baseline_unique = len(known_texts)

    # Hygiene: collapse identical duplicate story rows so packet confirmation has one story shell.
    before_stories = len(uses.get("stories", []))
    uses["stories"] = dedupe_stories(list(uses.get("stories", [])))
    after_stories = len(uses["stories"])

    reports = []
    for county in selected:
        reports.append(
            expand_county(
                county=county,
                atlas=atlas,
                uses=uses,
                packet_register=packet_register,
                known_texts=known_texts,
                dry_run=args.dry_run,
            )
        )

    if not args.dry_run:
        write_json(PACKET_REGISTER_PATH, packet_register)
        write_json(USES_PATH, uses)

    summary = {
        "status": "dry_run" if args.dry_run else "generated",
        "avenue": "A6",
        "queue": "queue-03-source-packet",
        "story_dedupe": {"before": before_stories, "after": after_stories},
        "baseline_unique_texts_repo": baseline_unique,
        "unique_texts_after": len(known_texts),
        "net_new_unique_texts": len(known_texts) - baseline_unique,
        "authored_members": sum(item["authored_members"] for item in reports),
        "counties": reports,
        "packet_register": str(PACKET_REGISTER_PATH.relative_to(ROOT)),
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
