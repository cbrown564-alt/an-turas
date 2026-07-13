#!/usr/bin/env python3
"""Convert the reviewed Logainm snapshot into the app's broad foundation index."""

from __future__ import annotations

import argparse
import json
import sqlite3
import unicodedata
from pathlib import Path

IRELAND_LATITUDE_RANGE = (51.0, 56.0)
IRELAND_LONGITUDE_RANGE = (-11.0, -5.0)


def field(value: dict, *keys: str):
    for key in keys:
        if key in value:
            return value[key]
    return None


def first_text(value: dict, *keys: str) -> str | None:
    for key in keys:
        item = value.get(key)
        if isinstance(item, str) and item.strip():
            return item.strip()
    return None


def valid_irish_coordinates(latitude, longitude) -> bool:
    return (
        isinstance(latitude, (int, float))
        and not isinstance(latitude, bool)
        and isinstance(longitude, (int, float))
        and not isinstance(longitude, bool)
        and IRELAND_LATITUDE_RANGE[0] <= latitude <= IRELAND_LATITUDE_RANGE[1]
        and IRELAND_LONGITUDE_RANGE[0] <= longitude <= IRELAND_LONGITUDE_RANGE[1]
    )


def build_entry(place: dict, attribution: str) -> dict | None:
    placenames = field(place, "Placenames", "placenames") or []
    irish = [item for item in placenames if (field(item, "Language", "language") or "").lower() == "ga"]
    english = [item for item in placenames if (field(item, "Language", "language") or "").lower() == "en"]
    main_ga = next((item for item in irish if field(item, "Main", "main")), irish[0] if irish else None)
    main_en = next((item for item in english if field(item, "Main", "main")), english[0] if english else None)
    ga = first_text(main_ga or {}, "Wording", "wording")
    en = first_text(main_en or {}, "Wording", "wording")
    canonical = ga or en
    if not canonical:
        return None

    categories = field(place, "Categories", "categories") or []
    category = categories[0] if categories else {}
    place_kind = first_text(category, "NameEN", "nameEN", "NameGA", "nameGA", "ID", "id") or "place"
    hierarchy_parts = []
    for parent in field(place, "IncludedIn", "includedIn") or []:
        name = first_text(parent, "NameGA", "nameGA", "NameEN", "nameEN")
        if name and name not in hierarchy_parts:
            hierarchy_parts.append(name)
    hierarchy = " / ".join(hierarchy_parts) or "Ireland"

    coordinates = None
    geographies = field(place, "Geography", "geography") or []
    if isinstance(geographies, dict):
        geographies = [geographies]
    for geography in geographies:
        points = field(geography, "Coordinates", "coordinates") or []
        if points:
            point = points[0]
            latitude = field(point, "Latitude", "latitude")
            longitude = field(point, "Longitude", "longitude")
            if valid_irish_coordinates(latitude, longitude):
                coordinates = {"lat": latitude, "lon": longitude}
                break

    variants = []
    for item in placenames:
        wording = first_text(item, "Wording", "wording")
        if wording and wording != canonical and wording not in variants:
            variants.append(wording)
        genitive = first_text(item, "Genetive", "Genitive", "genetive", "genitive")
        if genitive and genitive != canonical and genitive not in variants:
            variants.append(genitive)

    place_id = int(field(place, "ID", "id"))
    return {
        "id": f"logainm.{place_id}",
        "kind": "place",
        "canonicalDisplay": canonical,
        "subtitle": f"{place_kind.lower()} · {hierarchy}",
        "variants": variants,
        "variantRelationships": [
            {"display": item, "relationship": "relatedForm", "note": "Recorded by Logainm"}
            for item in variants
        ],
        "searchKeys": [canonical, *variants],
        "depth": "foundation",
        "nameKind": None,
        "hierarchy": hierarchy,
        "placeKind": place_kind,
        "foundation": {
            "logainmId": place_id,
            "irishForm": ga,
            "englishForm": en,
            "placeKind": place_kind,
            "hierarchy": hierarchy,
            "coordinates": coordinates,
            "permalink": field(place, "Permalink", "permalink") or f"https://www.logainm.ie/en/{place_id}",
            "modifiedAt": field(place, "DateModified", "dateModified"),
            "attribution": attribution,
        },
    }


def build(snapshot: dict) -> dict:
    entries = [
        entry for place in snapshot.get("records", [])
        if (entry := build_entry(place, snapshot["attribution"])) is not None
    ]
    entries.sort(key=lambda item: (item["canonicalDisplay"].casefold(), item["id"]))
    return {
        "version": f"logainm-{snapshot['fetchedAt']}",
        "contentDate": snapshot["fetchedAt"][:10],
        "attribution": snapshot["attribution"],
        "entries": entries,
    }


def normalize(value: str) -> str:
    folded = unicodedata.normalize("NFKD", value.casefold())
    plain = "".join(character for character in folded if not unicodedata.combining(character))
    return " ".join("".join(character if character.isalnum() or character == " " else " " for character in plain).split())


def build_database(snapshot: dict, output: Path) -> int:
    """Build a compact, queryable offline index without decoding the corpus into RAM."""
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(output.suffix + ".tmp")
    temporary.unlink(missing_ok=True)
    connection = sqlite3.connect(temporary)
    try:
        connection.executescript("""
            PRAGMA journal_mode = OFF;
            PRAGMA synchronous = OFF;
            CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL);
            CREATE TABLE places (
                id INTEGER PRIMARY KEY, canonical TEXT NOT NULL, subtitle TEXT NOT NULL,
                variants TEXT NOT NULL, hierarchy TEXT NOT NULL, place_kind TEXT NOT NULL,
                irish TEXT, english TEXT, latitude REAL, longitude REAL,
                permalink TEXT NOT NULL, modified_at TEXT
            );
            CREATE TABLE aliases (
                place_id INTEGER NOT NULL, search_key TEXT NOT NULL,
                PRIMARY KEY (place_id, search_key)
            ) WITHOUT ROWID;
            CREATE INDEX aliases_search_key ON aliases(search_key, place_id);
        """)
        metadata = {
            "version": f"logainm-{snapshot['fetchedAt']}",
            "contentDate": snapshot["fetchedAt"][:10],
            "attribution": snapshot["attribution"],
        }
        connection.executemany("INSERT INTO metadata VALUES (?, ?)", metadata.items())
        count = 0
        for place in snapshot.get("records", []):
            entry = build_entry(place, snapshot["attribution"])
            if entry is None:
                continue
            foundation = entry["foundation"]
            coordinates = foundation["coordinates"] or {}
            connection.execute(
                "INSERT INTO places VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                (
                    foundation["logainmId"], entry["canonicalDisplay"], entry["subtitle"],
                    json.dumps(entry["variants"], ensure_ascii=False, separators=(",", ":")),
                    foundation["hierarchy"], foundation["placeKind"], foundation["irishForm"],
                    foundation["englishForm"], coordinates.get("lat"), coordinates.get("lon"),
                    foundation["permalink"], foundation["modifiedAt"],
                ),
            )
            keys = {normalize(value) for value in entry["searchKeys"] if normalize(value)}
            connection.executemany(
                "INSERT INTO aliases VALUES (?, ?)",
                ((foundation["logainmId"], key) for key in keys),
            )
            count += 1
        connection.commit()
        connection.execute("ANALYZE")
        connection.execute("VACUUM")
    finally:
        connection.close()
    temporary.replace(output)
    return count


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("snapshot", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    snapshot = json.loads(args.snapshot.read_text(encoding="utf-8"))
    if args.output.suffix == ".sqlite":
        count = build_database(snapshot, args.output)
    else:
        index = build(snapshot)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        count = len(index["entries"])
    print(f"Built {count} Logainm foundation entries")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
