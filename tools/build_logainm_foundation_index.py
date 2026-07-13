#!/usr/bin/env python3
"""Convert the reviewed Logainm snapshot into the app's broad foundation index."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def first_text(value: dict, *keys: str) -> str | None:
    for key in keys:
        item = value.get(key)
        if isinstance(item, str) and item.strip():
            return item.strip()
    return None


def build_entry(place: dict, attribution: str) -> dict | None:
    placenames = place.get("Placenames") or []
    irish = [item for item in placenames if (item.get("Language") or "").lower() == "ga"]
    english = [item for item in placenames if (item.get("Language") or "").lower() == "en"]
    main_ga = next((item for item in irish if item.get("Main")), irish[0] if irish else None)
    main_en = next((item for item in english if item.get("Main")), english[0] if english else None)
    ga = first_text(main_ga or {}, "Wording")
    en = first_text(main_en or {}, "Wording")
    canonical = ga or en
    if not canonical:
        return None

    categories = place.get("Categories") or []
    category = categories[0] if categories else {}
    place_kind = first_text(category, "NameEN", "NameGA", "ID") or "place"
    hierarchy_parts = []
    for parent in place.get("IncludedIn") or []:
        name = first_text(parent, "NameGA", "NameEN")
        if name and name not in hierarchy_parts:
            hierarchy_parts.append(name)
    hierarchy = " / ".join(hierarchy_parts) or "Ireland"

    coordinates = None
    for geography in place.get("Geography") or []:
        points = geography.get("Coordinates") or []
        if points:
            point = points[0]
            if point.get("Latitude") is not None and point.get("Longitude") is not None:
                coordinates = {"lat": point["Latitude"], "lon": point["Longitude"]}
                break

    variants = []
    for item in placenames:
        wording = first_text(item, "Wording")
        if wording and wording != canonical and wording not in variants:
            variants.append(wording)
        genitive = first_text(item, "Genetive", "Genitive")
        if genitive and genitive != canonical and genitive not in variants:
            variants.append(genitive)

    place_id = int(place["ID"])
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
            "permalink": place.get("Permalink") or f"https://www.logainm.ie/en/{place_id}",
            "modifiedAt": place.get("DateModified"),
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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("snapshot", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    snapshot = json.loads(args.snapshot.read_text(encoding="utf-8"))
    index = build(snapshot)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Built {len(index['entries'])} Logainm foundation entries")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
