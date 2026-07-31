#!/usr/bin/env python3
"""Assemble content/audio/irish-inventory-v1.json from drafts, atlas, and banks.

Also writes atlas-headwords-v1.md for human review. Provisional atlas lemmas are
invented from COUNTY-STORY-SLATE field notes; launch counties reuse draft packs.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / "content"
AUDIO_DIR = CONTENT / "audio"
DRAFT_PACKS = {
    "mayo": CONTENT / "mayo/grainne-1593.pack.draft.json",
    "dublin": CONTENT / "dublin/sihtric-penny.pack.draft.json",
    "meath": CONTENT / "meath/trim-de-lacy.pack.draft.json",
    "offaly": CONTENT / "offaly/cross-of-the-scriptures.pack.draft.json",
}
FREEZE = ROOT / "ios/AnTuras/Resources/Fixtures/mayo.clew-bay-freeze.json"
MANIFEST = ROOT / "ios/AnTuras/Resources/Audio/manifest.json"


def slug(text: str) -> str:
    fadas = {"á": "aa", "é": "ee", "í": "ii", "ó": "oo", "ú": "uu"}
    flat: list[str] = []
    for char in text.lower():
        if char in fadas:
            flat.append(fadas[char])
        elif char.isascii() and char.isalpha():
            flat.append(char)
        else:
            flat.append(" ")
    return "-".join("".join(flat).split())


# Provisional 20-word banks. Launch four match draft packs. Others invent from
# slate English fields (people/things, place/movement, actions, conversation).
ATLAS_HEADWORDS: dict[str, list[tuple[str, str]]] = {
    "antrim": [
        ("cladach", "shore"),
        ("carraig", "rock"),
        ("farraige", "sea"),
        ("fathach", "giant"),
        ("dúshlán", "challenge"),
        ("cosán", "path"),
        ("colún", "column"),
        ("scéal", "story"),
        ("fíor", "true"),
        ("bréag", "false / lie"),
        ("trasna", "across"),
        ("tóg", "build / raise"),
        ("féach", "look"),
        ("seas", "stand"),
        ("mór", "big"),
        ("beag", "small"),
        ("tháinig", "came"),
        ("chuaigh", "went"),
        ("ainm", "name"),
        ("áit", "place"),
    ],
    "armagh": [
        ("eaglais", "church"),
        ("leabhar", "book"),
        ("scríobh", "write"),
        ("baile", "town"),
        ("creideamh", "belief"),
        ("catagóir", "cathedral"),  # prefer ardeaglais
        ("ardeaglais", "cathedral"),
        ("foghlaim", "learn"),
        ("léigh", "read"),
        ("naomh", "saint"),
        ("teach", "house"),
        ("bóthar", "road"),
        ("anseo", "here"),
        ("ansiúd", "there"),
        ("déan", "make / do"),
        ("féach", "look"),
        ("tabhair", "give"),
        ("faigh", "get"),
        ("ainm", "name"),
        ("lá", "day"),
    ],
    "carlow": [
        ("abhainn", "river"),
        ("muileann", "mill"),
        ("mainistir", "monastery"),
        ("obair", "work"),
        ("fáilte", "welcome"),
        ("oilithreacht", "pilgrimage"),
        ("baile", "settlement"),
        ("bóthar", "road"),
        ("teach", "house"),
        ("uisce", "water"),
        ("tar", "come"),
        ("téigh", "go"),
        ("fan", "stay"),
        ("déan", "make / do"),
        ("foghlaim", "learn"),
        ("guí", "pray"),
        ("anseo", "here"),
        ("anois", "now"),
        ("maith", "good"),
        ("ainm", "name"),
    ],
    "cavan": [
        ("loch", "lake"),
        ("cnoc", "hill"),
        ("clann", "clan / family"),
        ("margadh", "market"),
        ("tóg", "build"),
        ("mainistir", "friary / monastery"),
        ("dúnta", "fort"),
        ("talamh", "land"),
        ("baile", "town"),
        ("uisce", "water"),
        ("rí", "king / lord"),
        ("cumhacht", "power"),
        ("déan", "make"),
        ("tabhair", "give"),
        ("caill", "lose"),
        ("féach", "look"),
        ("anseo", "here"),
        ("mór", "big"),
        ("sean", "old"),
        ("ainm", "name"),
    ],
    "clare": [
        ("rí", "king"),
        ("abhainn", "river"),
        ("dún", "fort"),
        ("cara", "friend / ally"),
        ("turas", "journey"),
        ("oileán", "island"),
        ("cumhacht", "power"),
        ("cath", "battle"),
        ("scéal", "story"),
        ("fianaise", "evidence"),
        ("téigh", "go"),
        ("tar", "come"),
        ("iarr", "ask"),
        ("freagair", "answer"),
        ("léigh", "read"),
        ("creid", "believe"),
        ("anseo", "here"),
        ("ansiúd", "there"),
        ("mór", "big"),
        ("ainm", "name"),
    ],
    "cork": [
        ("scoil", "school"),
        ("páiste", "child"),
        ("oíche", "night"),
        ("múin", "teach"),
        ("dóchas", "hope"),
        ("solas", "light"),
        ("cathair", "city"),
        ("bóthar", "road"),
        ("teach", "house"),
        ("leabhar", "book"),
        ("foghlaim", "learn"),
        ("léigh", "read"),
        ("tabhair", "give"),
        ("cabhraigh", "help"),
        ("tosnaigh", "begin"),
        ("fan", "stay"),
        ("maith", "good"),
        ("anseo", "here"),
        ("anois", "now"),
        ("ainm", "name"),
    ],
    "derry": [
        ("balla", "wall"),
        ("geata", "gate"),
        ("baile", "town"),
        ("ocras", "hunger"),
        ("dídean", "shelter"),
        ("cathair", "city"),
        ("dún", "close / fort"),
        ("taobh", "side"),
        ("isteach", "inside"),
        ("amuigh", "outside"),
        ("fan", "stay"),
        ("téigh", "go"),
        ("tar", "come"),
        ("féach", "look"),
        ("éist", "listen"),
        ("labhair", "speak"),
        ("eagla", "fear"),
        ("dóchas", "hope"),
        ("cuimhnigh", "remember"),
        ("ainm", "name"),
    ],
    "donegal": [
        ("long", "ship"),
        ("cladach", "shore"),
        ("fág", "leave"),
        ("brón", "grief"),
        ("litir", "letter"),
        ("farraige", "sea"),
        ("calafort", "harbour"),
        ("tiarna", "lord"),
        ("teaghlach", "family"),
        ("turas", "journey"),
        ("téigh", "go"),
        ("tar", "come"),
        ("fan", "stay"),
        ("caill", "lose"),
        ("scríobh", "write"),
        ("léigh", "read"),
        ("cuimhnigh", "remember"),
        ("slán", "safe / goodbye"),
        ("arís", "again"),
        ("ainm", "name"),
    ],
    "down": [
        ("páirc", "field"),
        ("eaglais", "church"),
        ("tabhair", "give"),
        ("tar", "come / arrive"),
        ("fill", "return"),
        ("áit", "place"),
        ("ainm", "name"),
        ("scéal", "story"),
        ("traidisiún", "tradition"),
        ("fianaise", "evidence"),
        ("féach", "look"),
        ("éist", "listen"),
        ("creid", "believe"),
        ("foghlaim", "learn"),
        ("seas", "stand"),
        ("siúil", "walk"),
        ("anseo", "here"),
        ("ansiúd", "there"),
        ("sean", "old"),
        ("nua", "new"),
    ],
    "dublin": [],  # filled from draft
    "fermanagh": [
        ("caisleán", "castle"),
        ("oileán", "island"),
        ("abhainn", "river"),
        ("cosain", "guard"),
        ("riail", "rule"),
        ("loch", "lake"),
        ("geata", "gate"),
        ("balla", "wall"),
        ("cumhacht", "power"),
        ("talamh", "land"),
        ("tóg", "build"),
        ("caill", "lose"),
        ("faigh", "get"),
        ("tabhair", "give"),
        ("féach", "look"),
        ("seas", "stand"),
        ("anseo", "here"),
        ("mór", "big"),
        ("sean", "old"),
        ("ainm", "name"),
    ],
    "galway": [
        ("guth", "voice"),
        ("amhrán", "song"),
        ("éist", "listen"),
        ("cuimhnigh", "remember"),
        ("áit", "place"),
        ("ceol", "music"),
        ("focal", "word"),
        ("teanga", "language"),
        ("baile", "home / town"),
        ("farraige", "sea"),
        ("can", "sing"),
        ("foghlaim", "learn"),
        ("múin", "teach"),
        ("scéal", "story"),
        ("tar", "come"),
        ("téigh", "go"),
        ("anseo", "here"),
        ("anois", "now"),
        ("maith", "good"),
        ("ainm", "name"),
    ],
    "kerry": [
        ("file", "poet"),
        ("talamh", "land"),
        ("focal", "word"),
        ("cuimhne", "memory"),
        ("tuairim", "opinion"),
        ("sléibhte", "mountains"),
        ("farraige", "sea"),
        ("baile", "home"),
        ("teanga", "language"),
        ("dán", "poem"),
        ("léigh", "read"),
        ("scríobh", "write"),
        ("labhair", "speak"),
        ("éist", "listen"),
        ("cuimhnigh", "remember"),
        ("iarr", "ask"),
        ("freagair", "answer"),
        ("maith", "good"),
        ("anseo", "here"),
        ("ainm", "name"),
    ],
    "kildare": [
        ("tine", "fire"),
        ("bia", "food"),
        ("baile", "home"),
        ("roinn", "share"),
        ("cineálta", "kind"),
        ("fáilte", "welcome"),
        ("teach", "house"),
        ("eaglais", "church"),
        ("solas", "light"),
        ("lá", "day"),
        ("tabhair", "give"),
        ("faigh", "get"),
        ("fan", "stay"),
        ("tar", "come"),
        ("déan", "make"),
        ("cabhraigh", "help"),
        ("maith", "good"),
        ("anseo", "here"),
        ("anois", "now"),
        ("ainm", "name"),
    ],
    "kilkenny": [
        ("cúirt", "court"),
        ("cúiseamh", "accusation"),
        ("teach", "house"),
        ("finné", "witness"),
        ("abair", "say"),
        ("breitheamh", "judge"),
        ("baile", "town"),
        ("bean", "woman"),
        ("cumhacht", "power"),
        ("scéal", "story"),
        ("éist", "listen"),
        ("labhair", "speak"),
        ("creid", "believe"),
        ("léigh", "read"),
        ("scríobh", "write"),
        ("féach", "look"),
        ("eagla", "fear"),
        ("fírinne", "truth"),
        ("anseo", "here"),
        ("ainm", "name"),
    ],
    "laois": [
        ("carraig", "rock"),
        ("caisleán", "castle"),
        ("talamh", "land"),
        ("tabhair", "give"),
        ("cosain", "defend"),
        ("dún", "fort"),
        ("cnoc", "hill"),
        ("balla", "wall"),
        ("geata", "gate"),
        ("tiarna", "lord"),
        ("tóg", "build"),
        ("caill", "lose"),
        ("faigh", "get"),
        ("féach", "look"),
        ("seas", "stand"),
        ("téigh", "go"),
        ("anseo", "here"),
        ("mór", "big"),
        ("sean", "old"),
        ("ainm", "name"),
    ],
    "leitrim": [
        ("taoiseach", "chief"),
        ("loch", "lake"),
        ("dlí", "law"),
        ("taistil", "travel"),
        ("caill", "lose"),
        ("talamh", "land"),
        ("cumhacht", "power"),
        ("cúirt", "court"),
        ("turas", "journey"),
        ("baile", "home"),
        ("téigh", "go"),
        ("tar", "come"),
        ("fan", "stay"),
        ("iarr", "ask"),
        ("freagair", "answer"),
        ("labhair", "speak"),
        ("eagla", "fear"),
        ("dóchas", "hope"),
        ("anseo", "here"),
        ("ainm", "name"),
    ],
    "limerick": [
        ("conradh", "treaty"),
        ("cathair", "city"),
        ("gealltanas", "promise"),
        ("saighdiúir", "soldier"),
        ("síocháin", "peace"),
        ("balla", "wall"),
        ("geata", "gate"),
        ("abhainn", "river"),
        ("cogadh", "war"),
        ("cuimhne", "memory"),
        ("aontaigh", "agree"),
        ("diúltaigh", "refuse"),
        ("téigh", "go"),
        ("fan", "stay"),
        ("caill", "lose"),
        ("cuimhnigh", "remember"),
        ("labhair", "speak"),
        ("éist", "listen"),
        ("anseo", "here"),
        ("ainm", "name"),
    ],
    "longford": [
        ("bóthar", "road"),
        ("adhmad", "wood"),
        ("portach", "bog"),
        ("iompair", "carry"),
        ("trasna", "across"),
        ("cosán", "path"),
        ("talamh", "land"),
        ("uisce", "water"),
        ("sean", "old"),
        ("nua", "new"),
        ("tóg", "build"),
        ("caill", "lose"),
        ("faigh", "find"),
        ("féach", "look"),
        ("siúil", "walk"),
        ("téigh", "go"),
        ("anseo", "here"),
        ("ansiúd", "there"),
        ("mór", "big"),
        ("ainm", "name"),
    ],
    "louth": [
        ("tarbh", "bull"),
        ("áth", "ford"),
        ("laoch", "warrior"),
        ("fan", "wait"),
        ("láidir", "strong"),
        ("cath", "battle"),
        ("abhainn", "river"),
        ("talamh", "land"),
        ("scéal", "story"),
        ("rí", "king"),
        ("seas", "stand"),
        ("rith", "run"),
        ("cosain", "defend"),
        ("iarr", "ask"),
        ("tabhair", "give"),
        ("féach", "look"),
        ("éist", "listen"),
        ("anseo", "here"),
        ("mór", "big"),
        ("ainm", "name"),
    ],
    "mayo": [],
    "meath": [],
    "monaghan": [
        ("bóthar", "road"),
        ("páirc", "field"),
        ("comharsa", "neighbour"),
        ("cuimhnigh", "remember"),
        ("comparáid", "compare"),
        ("baile", "village / home"),
        ("dán", "poem"),
        ("focal", "word"),
        ("óige", "youth"),
        ("talamh", "land"),
        ("léigh", "read"),
        ("scríobh", "write"),
        ("féach", "look"),
        ("éist", "listen"),
        ("labhair", "speak"),
        ("siúil", "walk"),
        ("anseo", "here"),
        ("ansiúd", "there"),
        ("sean", "old"),
        ("ainm", "name"),
    ],
    "offaly": [],
    "roscommon": [
        ("banríon", "queen"),
        ("eallach", "cattle"),
        ("uaimh", "cave"),
        ("teastaigh", "want"),
        ("ordaigh", "command"),
        ("tarbh", "bull"),
        ("talamh", "land"),
        ("rí", "king"),
        ("cumhacht", "power"),
        ("scéal", "story"),
        ("iarr", "ask"),
        ("tabhair", "give"),
        ("téigh", "go"),
        ("tar", "come"),
        ("féach", "look"),
        ("éist", "listen"),
        ("anseo", "here"),
        ("mór", "big"),
        ("láidir", "strong"),
        ("ainm", "name"),
    ],
    "sligo": [
        ("sliabh", "mountain"),
        ("uaigh", "grave"),
        ("aisling", "dream"),
        ("féach", "see / look"),
        ("cur síos", "describe"),
        ("dán", "poem"),
        ("file", "poet"),
        ("loch", "lake"),
        ("baile", "town"),
        ("áit", "place"),
        ("léigh", "read"),
        ("scríobh", "write"),
        ("cuimhnigh", "remember"),
        ("labhair", "speak"),
        ("éist", "listen"),
        ("siúil", "walk"),
        ("anseo", "here"),
        ("ansiúd", "there"),
        ("álainn", "beautiful"),
        ("ainm", "name"),
    ],
    "tipperary": [
        ("carraig", "rock"),
        ("séipéal", "chapel"),
        ("rí", "king"),
        ("cloch", "stone"),
        ("álainn", "beautiful"),
        ("eaglais", "church"),
        ("cnoc", "hill"),
        ("doras", "door"),
        ("balla", "wall"),
        ("solas", "light"),
        ("tóg", "build"),
        ("féach", "look"),
        ("seas", "stand"),
        ("léigh", "read"),
        ("guí", "pray"),
        ("déan", "make"),
        ("anseo", "here"),
        ("mór", "big"),
        ("sean", "old"),
        ("ainm", "name"),
    ],
    "tyrone": [
        ("cnoc", "hill"),
        ("tiarna", "lord"),
        ("arm", "army"),
        ("labhair", "speak"),
        ("cinneadh", "decide"),
        ("cumhacht", "power"),
        ("caisleán", "castle"),
        ("talamh", "land"),
        ("cath", "battle"),
        ("teaghlach", "family"),
        ("téigh", "go"),
        ("tar", "come"),
        ("fan", "stay"),
        ("iarr", "ask"),
        ("freagair", "answer"),
        ("éist", "listen"),
        ("caill", "lose"),
        ("anseo", "here"),
        ("mór", "big"),
        ("ainm", "name"),
    ],
    "waterford": [
        ("túr", "tower"),
        ("abhainn", "river"),
        ("baile", "town"),
        ("trádáil", "trade"),
        ("tar", "arrive / come"),
        ("calafort", "harbour"),
        ("long", "ship"),
        ("margadh", "market"),
        ("cathair", "city"),
        ("cladach", "shore"),
        ("ceannaigh", "buy"),
        ("díol", "sell"),
        ("téigh", "go"),
        ("tóg", "take / build"),
        ("féach", "look"),
        ("seas", "stand"),
        ("anseo", "here"),
        ("sean", "old"),
        ("nua", "new"),
        ("ainm", "name"),
    ],
    "westmeath": [
        ("mainistir", "abbey"),
        ("tobar", "well"),
        ("cosán", "path"),
        ("fáilte", "welcome"),
        ("sean", "old"),
        ("eaglais", "church"),
        ("loch", "lake"),
        ("cnoc", "hill"),
        ("baile", "settlement"),
        ("uisce", "water"),
        ("tar", "come"),
        ("téigh", "go"),
        ("fan", "stay"),
        ("guí", "pray"),
        ("féach", "look"),
        ("siúil", "walk"),
        ("anseo", "here"),
        ("ansiúd", "there"),
        ("ciúin", "quiet"),
        ("ainm", "name"),
    ],
    "wexford": [
        ("cruinniú", "meeting"),
        ("baile", "town"),
        ("eagla", "fear"),
        ("roghnaigh", "choose"),
        ("cuimhnigh", "remember"),
        ("cogadh", "war"),
        ("síocháin", "peace"),
        ("pobal", "community"),
        ("bóthar", "road"),
        ("teach", "house"),
        ("labhair", "speak"),
        ("éist", "listen"),
        ("téigh", "go"),
        ("fan", "stay"),
        ("cabhraigh", "help"),
        ("caill", "lose"),
        ("dóchas", "hope"),
        ("anseo", "here"),
        ("anois", "now"),
        ("ainm", "name"),
    ],
    "wicklow": [
        ("gleann", "valley"),
        ("loch", "lake"),
        ("cill", "cell / church"),
        ("éan", "bird"),
        ("ciúin", "quiet"),
        ("mainistir", "monastery"),
        ("sliabh", "mountain"),
        ("cosán", "path"),
        ("uisce", "water"),
        ("áit", "place"),
        ("tar", "come"),
        ("fan", "stay"),
        ("féach", "look"),
        ("éist", "listen"),
        ("guí", "pray"),
        ("siúil", "walk"),
        ("anseo", "here"),
        ("ansiúd", "there"),
        ("álainn", "beautiful"),
        ("ainm", "name"),
    ],
}

# Fix armagh: remove bad "catagóir" entry — rewrite cleanly
ATLAS_HEADWORDS["armagh"] = [
    ("eaglais", "church"),
    ("leabhar", "book"),
    ("scríobh", "write"),
    ("baile", "town"),
    ("creideamh", "belief"),
    ("ardeaglais", "cathedral"),
    ("foghlaim", "learn"),
    ("léigh", "read"),
    ("naomh", "saint"),
    ("teach", "house"),
    ("bóthar", "road"),
    ("anseo", "here"),
    ("ansiúd", "there"),
    ("déan", "make / do"),
    ("féach", "look"),
    ("tabhair", "give"),
    ("faigh", "get"),
    ("ainm", "name"),
    ("lá", "day"),
    ("focal", "word"),
]

# Sligo "cur síos" is two words — use single lemma "cur" or better "insint"
ATLAS_HEADWORDS["sligo"] = [
    ("sliabh", "mountain"),
    ("uaigh", "grave"),
    ("aisling", "dream"),
    ("féach", "see / look"),
    ("insint", "telling / describe"),
    ("dán", "poem"),
    ("file", "poet"),
    ("loch", "lake"),
    ("baile", "town"),
    ("áit", "place"),
    ("léigh", "read"),
    ("scríobh", "write"),
    ("cuimhnigh", "remember"),
    ("labhair", "speak"),
    ("éist", "listen"),
    ("siúil", "walk"),
    ("anseo", "here"),
    ("ansiúd", "there"),
    ("álainn", "beautiful"),
    ("ainm", "name"),
]

# Monaghan "comparáid" as noun — use verb "déan comparáid" vehicle; headword "cosúil"
ATLAS_HEADWORDS["monaghan"] = [
    ("bóthar", "road"),
    ("páirc", "field"),
    ("comharsa", "neighbour"),
    ("cuimhnigh", "remember"),
    ("cosúil", "like / similar"),
    ("baile", "village / home"),
    ("dán", "poem"),
    ("focal", "word"),
    ("óige", "youth"),
    ("talamh", "land"),
    ("léigh", "read"),
    ("scríobh", "write"),
    ("féach", "look"),
    ("éist", "listen"),
    ("labhair", "speak"),
    ("siúil", "walk"),
    ("anseo", "here"),
    ("ansiúd", "there"),
    ("sean", "old"),
    ("ainm", "name"),
]

COUNTY_DISPLAY = {
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

LAUNCH_PHRASE_CONVERSATION: dict[str, dict[str, list[dict[str, str]]]] = {
    "mayo": {
        "phrases": [
            {"text": "Is as Maigh Eo mé.", "gloss": "I am from Mayo."},
            {"text": "Tá an long sa bhá.", "gloss": "The ship is in the bay."},
            {"text": "Ná caill an long.", "gloss": "Do not lose the ship."},
            {"text": "Téigh go Londain agus iarr freagra.", "gloss": "Go to London and ask for an answer."},
            {"text": "Is mise Gráinne.", "gloss": "I am Gráinne."},
            {"text": "Tá an caisleán ar an gcósta.", "gloss": "The castle is on the coast."},
            {"text": "Tá muid go léir.", "gloss": "We are all here."},
            {"text": "Tá an fharraige mór.", "gloss": "The sea is big."},
            {"text": "Tar ar ais chuig an mbá.", "gloss": "Come back to the bay."},
            {"text": "Tabhair freagra dom.", "gloss": "Give me an answer."},
            {"text": "Cad is ainm duit?", "gloss": "What is your name?"},
            {"text": "Tá áit agam anseo.", "gloss": "I have a place here."},
        ],
        "conversation": [
            {"text": "Cárb as tú?", "gloss": "Where are you from?"},
            {"text": "Cén t-ainm atá ort?", "gloss": "What is your name?"},
            {"text": "Maith.", "gloss": "Good."},
            {"text": "Slán go fóill.", "gloss": "Goodbye for now."},
            {"text": "Cé thusa?", "gloss": "Who are you?"},
            {"text": "Is mise…", "gloss": "I am…"},
            {"text": "An bhfuil an long anseo?", "gloss": "Is the ship here?"},
            {"text": "Tá an fharraige ciúin.", "gloss": "The sea is quiet."},
            {"text": "Cá bhfuil an caisleán?", "gloss": "Where is the castle?"},
            {"text": "Tá sé ar an gcósta.", "gloss": "It is on the coast."},
            {"text": "Cad atá uait?", "gloss": "What do you want?"},
            {"text": "Iarr freagra.", "gloss": "Ask for an answer."},
            {"text": "Tar isteach.", "gloss": "Come in."},
            {"text": "Téigh ar ais.", "gloss": "Go back."},
        ],
    },
    "dublin": {
        "phrases": [
            {"text": "Tá cathair agus baile ag an linn dubh; tá long ar an abhainn.", "gloss": "There is a city and town at the dark pool; a ship is on the river."},
            {"text": "Tá ainm an rí ar airgead an mhargaidh agus na trádála.", "gloss": "The king's name is on the market's silver and the trade."},
            {"text": "Ceannaigh agus díol; tabhair an t-airgead dom agus tóg é.", "gloss": "Buy and sell; give me the money and take it."},
            {"text": "Tháinig an dearadh; chuaigh an phingin ón mionta.", "gloss": "The design came; the penny went from the mint."},
            {"text": "Téigh go dtí an aghaidh; tar ar ais chuig an inscríbhinn.", "gloss": "Go to the face; come back to the inscription."},
            {"text": "Chuaigh an phingin ón gcathair go Gleann Dá Loch.", "gloss": "The penny went from the city to Glendalough."},
            {"text": "Tá pingin airgid agam.", "gloss": "I have a silver penny."},
            {"text": "Cén t-ainm atá ar an rí?", "gloss": "What is the king's name?"},
            {"text": "Tá an margadh ar an abhainn.", "gloss": "The market is on the river."},
            {"text": "Tabhair an phingin dom.", "gloss": "Give me the penny."},
            {"text": "Téigh go dtí an mhargadh.", "gloss": "Go to the market."},
            {"text": "Tháinig an long isteach.", "gloss": "The ship came in."},
        ],
        "conversation": [
            {"text": "Cad atá á cheannach agat?", "gloss": "What are you buying?"},
            {"text": "Tá airgead agam.", "gloss": "I have money."},
            {"text": "An bhfuil pingin agat?", "gloss": "Do you have a penny?"},
            {"text": "Cá bhfuil an margadh?", "gloss": "Where is the market?"},
            {"text": "Tá sé ag an linn.", "gloss": "It is at the pool."},
            {"text": "Cé hé an rí?", "gloss": "Who is the king?"},
            {"text": "Tabhair dom é.", "gloss": "Give it to me."},
            {"text": "Tóg an phingin.", "gloss": "Take the penny."},
            {"text": "An ndíolann tú é?", "gloss": "Do you sell it?"},
            {"text": "Ceannaím é.", "gloss": "I buy it."},
            {"text": "Tar go dtí an long.", "gloss": "Come to the ship."},
            {"text": "Téigh ar ais go dtí an chathair.", "gloss": "Go back to the city."},
            {"text": "Cad is ainm duit?", "gloss": "What is your name?"},
            {"text": "Slán.", "gloss": "Goodbye."},
        ],
    },
    "meath": {
        "phrases": [
            {"text": "Tá ainm ar an talamh sean agus tá baile ann.", "gloss": "There is a name on the old land and there is a town there."},
            {"text": "Tá taifead nua agam; cad atá agat? Tóg é.", "gloss": "I have a new record; what do you have? Take it."},
            {"text": "Tá an t-áth anseo ar an abhainn; tá an baile ansiúd.", "gloss": "The ford is here on the river; the town is over there."},
            {"text": "Tá cónaí sa teach; seas sa chaisleán.", "gloss": "There is living in the house; stand in the castle."},
            {"text": "Féach ar an mballa mór cloiche.", "gloss": "Look at the big stone wall."},
            {"text": "Féach ar an sean-chaisleán agus ar an mbaile nua.", "gloss": "Look at the old castle and the new town."},
            {"text": "Tá talamh agam anseo.", "gloss": "I have land here."},
            {"text": "Cad atá agat?", "gloss": "What do you have?"},
            {"text": "Tóg an caisleán.", "gloss": "Build / raise the castle."},
            {"text": "Seas ag an áth.", "gloss": "Stand at the ford."},
            {"text": "Tá an teach mór.", "gloss": "The house is big."},
            {"text": "Féach ansiúd.", "gloss": "Look over there."},
        ],
        "conversation": [
            {"text": "Cad atá agat?", "gloss": "What do you have?"},
            {"text": "Tá talamh agam.", "gloss": "I have land."},
            {"text": "Cá bhfuil an t-áth?", "gloss": "Where is the ford?"},
            {"text": "Tá sé anseo.", "gloss": "It is here."},
            {"text": "An bhfuil cónaí ort anseo?", "gloss": "Do you live here?"},
            {"text": "Tá cónaí orm sa bhaile.", "gloss": "I live in the town."},
            {"text": "Féach ar an gcaisleán.", "gloss": "Look at the castle."},
            {"text": "Seas anseo.", "gloss": "Stand here."},
            {"text": "An bhfuil sé nua?", "gloss": "Is it new?"},
            {"text": "Níl, tá sé sean.", "gloss": "No, it is old."},
            {"text": "Cén t-ainm atá ar an áit?", "gloss": "What is the name of the place?"},
            {"text": "Tar go dtí an teach.", "gloss": "Come to the house."},
            {"text": "Téigh go dtí an mballa.", "gloss": "Go to the wall."},
            {"text": "Maith thú.", "gloss": "Well done."},
        ],
    },
    "offaly": {
        "phrases": [
            {"text": "Tá abhainn, bád agus bóthar anseo.", "gloss": "There is a river, a boat and a road here."},
            {"text": "Tá obair sa mhainistir agus tá mé ag foghlaim sa bhaile gach lá.", "gloss": "There is work in the monastery and I am learning in the town every day."},
            {"text": "Déan cros mhór don rí le sonraí beaga.", "gloss": "Make a big cross for the king with small details."},
            {"text": "Seas anseo agus féach ar an gcros chloiche.", "gloss": "Stand here and look at the stone cross."},
            {"text": "Léigh an t-inscríbhinn anois agus guí.", "gloss": "Read the inscription now and pray."},
            {"text": "Tá an chloch agus an chros anseo anois.", "gloss": "The stone and the cross are here now."},
            {"text": "Tá an mhainistir mór.", "gloss": "The monastery is big."},
            {"text": "Féach ar an gcros.", "gloss": "Look at the cross."},
            {"text": "Léigh an t-ainm.", "gloss": "Read the name."},
            {"text": "Déan an obair anois.", "gloss": "Do the work now."},
            {"text": "Tá bád ar an abhainn.", "gloss": "There is a boat on the river."},
            {"text": "Téigh ar an mbóthar.", "gloss": "Go on the road."},
        ],
        "conversation": [
            {"text": "Cá bhfuil an chros?", "gloss": "Where is the cross?"},
            {"text": "Tá sí anseo.", "gloss": "It is here."},
            {"text": "An bhfuil tú ag foghlaim?", "gloss": "Are you learning?"},
            {"text": "Tá, gach lá.", "gloss": "Yes, every day."},
            {"text": "Féach ar an gcloch.", "gloss": "Look at the stone."},
            {"text": "Léigh é anois.", "gloss": "Read it now."},
            {"text": "Cé hé an rí?", "gloss": "Who is the king?"},
            {"text": "Déan cros bheag.", "gloss": "Make a small cross."},
            {"text": "An bhfuil obair agat?", "gloss": "Do you have work?"},
            {"text": "Tá obair sa mhainistir.", "gloss": "There is work in the monastery."},
            {"text": "Tar go dtí an abhainn.", "gloss": "Come to the river."},
            {"text": "Seas ag an gcros.", "gloss": "Stand at the cross."},
            {"text": "Guí linn.", "gloss": "Pray with us."},
            {"text": "Slán go fóill.", "gloss": "Goodbye for now."},
        ],
    },
}


def load_pack(path: Path) -> dict:
    root = json.loads(path.read_text())
    return root.get("pack", root)


def draft_target_words() -> dict[str, list[tuple[str, str]]]:
    out: dict[str, list[tuple[str, str]]] = {}
    for county, path in DRAFT_PACKS.items():
        pack = load_pack(path)
        out[county] = [(w["ga"], w.get("en", "")) for w in pack.get("targetWords", [])]
    return out


def draft_audio_strings() -> dict[str, list[tuple[str, str, str]]]:
    """Return (text, resource_id, kind_guess) per county from pack resources."""
    out: dict[str, list[tuple[str, str, str]]] = {}
    for county, path in DRAFT_PACKS.items():
        pack = load_pack(path)
        rows: list[tuple[str, str, str]] = []
        for resource in pack.get("resources", []):
            if resource.get("kind") != "audio":
                continue
            value = resource.get("value")
            if not isinstance(value, str) or not value.strip():
                continue
            rid = resource.get("id", "")
            kind = "phrase" if " " in value.strip() or "." in value or "?" in value else "headword"
            if "exercise" in rid:
                kind = "phrase"
            rows.append((value.strip(), rid, kind))
        out[county] = rows
    return out


def walk_audio_texts(obj: object, found: set[str]) -> None:
    if isinstance(obj, dict):
        value = obj.get("audioText")
        if isinstance(value, str) and value.strip():
            found.add(value.strip())
        for child in obj.values():
            walk_audio_texts(child, found)
    elif isinstance(obj, list):
        for child in obj:
            walk_audio_texts(child, found)


def add_entry(
    by_slug: dict[str, dict],
    text: str,
    kind: str,
    county: str | None,
    gloss: str,
    source: str,
) -> None:
    text = text.strip()
    if not text or "{name}" in text:
        return
    key = slug(text)
    if not key:
        return
    entry = by_slug.get(key)
    if entry is None:
        by_slug[key] = {
            "text": text,
            "slug": key,
            "kind": kind,
            "counties": [county] if county else [],
            "gloss": gloss,
            "source": source,
            "qa_state": "pending_generation",
        }
        return
    if county and county not in entry["counties"]:
        entry["counties"].append(county)
    # Prefer headword kind when the same lemma appears as both
    if entry["kind"] != "headword" and kind == "headword":
        entry["kind"] = "headword"
    if not entry.get("gloss") and gloss:
        entry["gloss"] = gloss
    # Prefer draft-pack over invented for source label when upgrading
    if source == "draft-pack" and entry["source"] != "draft-pack":
        entry["source"] = "draft-pack"
        entry["text"] = text


def main() -> int:
    AUDIO_DIR.mkdir(parents=True, exist_ok=True)
    by_slug: dict[str, dict] = {}

    drafts = draft_target_words()
    for county, words in drafts.items():
        ATLAS_HEADWORDS[county] = words

    # Validate atlas banks
    for county, words in ATLAS_HEADWORDS.items():
        if len(words) != 20:
            raise SystemExit(f"{county} has {len(words)} headwords, need 20")
        lemmas = [w[0] for w in words]
        if len(set(lemmas)) != 20:
            raise SystemExit(f"{county} has duplicate headwords: {lemmas}")

    # Atlas + launch headwords
    for county, words in ATLAS_HEADWORDS.items():
        source = "draft-pack" if county in DRAFT_PACKS else "weave"
        for ga, en in words:
            add_entry(by_slug, ga, "headword", county, en, source)

    # Draft pack audio resources (phrases + any headwords)
    for county, rows in draft_audio_strings().items():
        for text, _rid, kind in rows:
            add_entry(by_slug, text, kind, county, "", "draft-pack")

    # Invented launch phrase + conversation banks
    for county, banks in LAUNCH_PHRASE_CONVERSATION.items():
        for row in banks["phrases"]:
            add_entry(
                by_slug,
                row["text"],
                "phrase",
                county,
                row.get("gloss", ""),
                "invented" if " " in row["text"] else "draft-pack",
            )
        for row in banks["conversation"]:
            add_entry(
                by_slug,
                row["text"],
                "conversation",
                county,
                row.get("gloss", ""),
                "invented",
            )

    # Freeze fixture conversation / audio texts
    if FREEZE.exists():
        found: set[str] = set()
        walk_audio_texts(json.loads(FREEZE.read_text()), found)
        for text in found:
            kind = "conversation" if ("?" in text or text[0].isupper()) and " " in text else (
                "phrase" if " " in text else "headword"
            )
            add_entry(by_slug, text, kind, "mayo", "", "freeze-fixture")

    # Mark already-bundled clips
    if MANIFEST.exists():
        manifest = json.loads(MANIFEST.read_text())
        present = {line["slug"] for line in manifest.get("lines", [])}
        for key, entry in by_slug.items():
            if key in present:
                entry["qa_state"] = "generated_unreviewed"

    entries = sorted(by_slug.values(), key=lambda e: (e["kind"], e["slug"]))
    for entry in entries:
        entry["counties"] = sorted(entry["counties"])

    inventory = {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "bind_rule": (
            "Launch exercises may only set audioText to strings present in this "
            "inventory. New Irish without a clip stays silent until a post-"
            "ElevenLabs provider can regenerate."
        ),
        "voice": {"name": "Irish Cultural Guide", "id": "NPWroowF4phQhaPWjXPj"},
        "counts": {
            "total": len(entries),
            "headword": sum(1 for e in entries if e["kind"] == "headword"),
            "phrase": sum(1 for e in entries if e["kind"] == "phrase"),
            "conversation": sum(1 for e in entries if e["kind"] == "conversation"),
            "already_generated": sum(
                1 for e in entries if e["qa_state"] == "generated_unreviewed"
            ),
            "pending_generation": sum(
                1 for e in entries if e["qa_state"] == "pending_generation"
            ),
        },
        "entries": entries,
    }

    inv_path = AUDIO_DIR / "irish-inventory-v1.json"
    inv_path.write_text(json.dumps(inventory, ensure_ascii=False, indent=2) + "\n")

    # Atlas JSON + markdown
    atlas = {
        "schema_version": 1,
        "status": "provisional_until_pedagogue",
        "generated_at": inventory["generated_at"],
        "counties": {
            county: {
                "display": COUNTY_DISPLAY[county],
                "source": "draft-pack" if county in DRAFT_PACKS else "weave",
                "words": [{"ga": ga, "en": en} for ga, en in words],
            }
            for county, words in sorted(ATLAS_HEADWORDS.items())
        },
    }
    (AUDIO_DIR / "atlas-headwords-v1.json").write_text(
        json.dumps(atlas, ensure_ascii=False, indent=2) + "\n"
    )

    md_lines = [
        "# Atlas headwords v1 (provisional)",
        "",
        "*Invented from county slate field notes for ElevenLabs pre-generation. "
        "Launch counties reuse draft packs. Pedagogue approval required before "
        "any county is taught from this bank.*",
        "",
    ]
    for county, words in sorted(ATLAS_HEADWORDS.items()):
        md_lines.append(f"## {COUNTY_DISPLAY[county]}")
        md_lines.append("")
        source = "draft pack" if county in DRAFT_PACKS else "provisional weave"
        md_lines.append(f"Source: {source}")
        md_lines.append("")
        for index, (ga, en) in enumerate(words, start=1):
            md_lines.append(f"{index}. *{ga}* — {en}")
        md_lines.append("")
    (AUDIO_DIR / "atlas-headwords-v1.md").write_text("\n".join(md_lines))

    banks_path = AUDIO_DIR / "launch-phrases-conversations-v1.json"
    banks_path.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "generated_at": inventory["generated_at"],
                "counties": LAUNCH_PHRASE_CONVERSATION,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n"
    )

    counts = inventory["counts"]
    print(
        f"Wrote {inv_path} — {counts['total']} entries "
        f"({counts['headword']} headwords, {counts['phrase']} phrases, "
        f"{counts['conversation']} conversation; "
        f"{counts['already_generated']} present, {counts['pending_generation']} pending)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
