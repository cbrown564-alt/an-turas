#!/usr/bin/env python3
"""Produce record-level review queues for Logainm county coverage.

The source API permits a place to have no direct county parent or several county
parents.  This tool does not silently force either shape into one county.  It
separates expected roots and cross-boundary features from records that need an
upstream correction, an external boundary join, or editorial review.
"""

from __future__ import annotations

import argparse
import csv
import json
from collections import Counter, defaultdict
from pathlib import Path


NORTHERN_IRELAND_COUNTIES = {"Antrim", "Armagh", "Derry", "Down", "Fermanagh", "Tyrone"}
PLAUSIBLE_CROSS_BOUNDARY_CATEGORIES = {
    "ABH", "ATH", "BA", "BEAR", "CAN", "CAOL", "CARN", "CN", "COS", "D", "DR",
    "GL", "GNE", "IN", "L", "MNG", "MUIR", "OIL", "POLL", "POR", "RIASC",
    "RINN", "SCEIR", "SL", "SRUTHAN", "UAIMH", "CUAN",
}
ADMINISTRATIVE_CATEGORIES = {"BAR", "B", "BF", "ID", "PAR", "TR"}


def wording(record: dict, language: str) -> str:
    values = [
        item.get("wording", "").strip()
        for item in record.get("placenames", [])
        if item.get("language", "").lower() == language and item.get("wording", "").strip()
    ]
    return " | ".join(values)


def form_state(record: dict) -> str:
    has_irish = bool(wording(record, "ga"))
    has_english = bool(wording(record, "en"))
    if has_irish and has_english:
        return "bilingual"
    if has_irish:
        return "irish_only"
    if has_english:
        return "english_only"
    return "no_usable_form"


def category(record: dict) -> tuple[str, str]:
    value = (record.get("categories") or [{}])[0]
    return value.get("id") or "?", value.get("nameEN") or value.get("nameGA") or "unknown"


def direct_counties(record: dict) -> set[str]:
    return {
        parent.get("nameEN") or parent.get("nameGA")
        for parent in record.get("includedIn", [])
        if parent.get("category", {}).get("id") == "CON"
        and (parent.get("nameEN") or parent.get("nameGA"))
    }


def coordinates(record: dict) -> tuple[float | None, float | None]:
    geography = record.get("geography") or {}
    if isinstance(geography, list):
        geography = geography[0] if geography else {}
    points = geography.get("coordinates") or []
    point = points[0] if points else {}
    return point.get("latitude"), point.get("longitude")


def infer_counties(place_id: int, records_by_id: dict[int, dict], seen: set[int] | None = None) -> set[str]:
    """Follow existing parents and clusters without inventing a spatial match."""
    seen = set() if seen is None else seen
    if place_id in seen or place_id not in records_by_id:
        return set()
    # Share one visited set across branches.  Cluster graphs are dense and cyclic;
    # copying the set per branch turns a simple reachability walk exponential.
    seen.add(place_id)
    record = records_by_id[place_id]
    result = direct_counties(record)
    for parent in record.get("includedIn", []):
        if isinstance(parent.get("id"), int):
            result |= infer_counties(parent["id"], records_by_id, seen)
    for member in (record.get("cluster") or {}).get("members", []):
        if isinstance(member.get("placeID"), int):
            result |= infer_counties(member["placeID"], records_by_id, seen)
    return result


def countyless_disposition(record: dict, records_by_id: dict[int, dict]) -> str:
    category_id, _ = category(record)
    if category_id == "CON":
        return "expected_county_root"
    if form_state(record) == "no_usable_form":
        return "exclude_no_usable_form"
    if infer_counties(record["id"], records_by_id):
        return "recover_from_existing_hierarchy"
    return "manual_or_spatial_review"


def multi_county_disposition(record: dict) -> str:
    category_id, _ = category(record)
    counties = direct_counties(record)
    if category_id in PLAUSIBLE_CROSS_BOUNDARY_CATEGORIES:
        return "plausible_cross_boundary_feature"
    if category_id == "SR" and counties == {"Kilkenny", "Waterford"}:
        return "waterford_city_hierarchy_review"
    if category_id == "SR":
        return "street_hierarchy_conflict_review"
    if category_id in ADMINISTRATIVE_CATEGORIES:
        return "administrative_boundary_review"
    return "manual_review"


def review_row(record: dict, records_by_id: dict[int, dict], disposition: str) -> dict:
    category_id, category_name = category(record)
    latitude, longitude = coordinates(record)
    parents = record.get("includedIn", [])
    return {
        "logainm_id": record["id"],
        "permalink": record.get("permalink") or f"https://www.logainm.ie/en/{record['id']}",
        "irish": wording(record, "ga"),
        "english": wording(record, "en"),
        "form_state": form_state(record),
        "category_id": category_id,
        "category": category_name,
        "direct_counties": " | ".join(sorted(direct_counties(record))),
        "inferred_counties": " | ".join(sorted(infer_counties(record["id"], records_by_id))),
        "parents": " | ".join(
            f"{parent.get('category', {}).get('id', '?')}:{parent.get('nameEN') or parent.get('nameGA') or parent.get('id')}"
            for parent in parents
        ),
        "latitude": latitude,
        "longitude": longitude,
        "coordinate_usable": isinstance(latitude, (int, float)) and isinstance(longitude, (int, float))
        and 51 <= latitude <= 56 and -11 <= longitude <= -5,
        "disposition": disposition,
    }


def county_profile(records: list[dict]) -> tuple[list[dict], dict]:
    rows = []
    category_rates: dict[tuple[str, str], list[int]] = defaultdict(lambda: [0, 0])
    for record in records:
        is_bilingual = form_state(record) == "bilingual"
        category_id, _ = category(record)
        for county in direct_counties(record):
            category_rates[(county, category_id)][0] += 1
            category_rates[(county, category_id)][1] += int(is_bilingual)

    for county in sorted(NORTHERN_IRELAND_COUNTIES):
        assigned = [record for record in records if county in direct_counties(record)]
        townlands = [record for record in assigned if category(record)[0] == "BF"]
        other = [record for record in assigned if category(record)[0] != "BF"]
        state_counts = Counter(form_state(record) for record in assigned)
        rows.append({
            "county": county,
            "records": len(assigned),
            "bilingual": state_counts["bilingual"],
            "bilingual_rate": round(state_counts["bilingual"] / len(assigned), 4),
            "english_only": state_counts["english_only"],
            "irish_only": state_counts["irish_only"],
            "townlands": len(townlands),
            "bilingual_townlands": sum(form_state(record) == "bilingual" for record in townlands),
            "townland_bilingual_rate": round(sum(form_state(record) == "bilingual" for record in townlands) / len(townlands), 4),
            "other_records": len(other),
            "bilingual_other_records": sum(form_state(record) == "bilingual" for record in other),
            "other_bilingual_rate": round(sum(form_state(record) == "bilingual" for record in other) / len(other), 4),
        })

    roi_rates: dict[str, list[int]] = defaultdict(lambda: [0, 0])
    ni_mix: Counter[str] = Counter()
    for (county, category_id), (total, bilingual) in category_rates.items():
        if county in NORTHERN_IRELAND_COUNTIES:
            ni_mix[category_id] += total
        else:
            roi_rates[category_id][0] += total
            roi_rates[category_id][1] += bilingual
    expected = sum(
        count * roi_rates[category_id][1] / roi_rates[category_id][0]
        for category_id, count in ni_mix.items() if roi_rates[category_id][0]
    )
    covered = sum(count for category_id, count in ni_mix.items() if roi_rates[category_id][0])
    ni_records = [record for record in records if direct_counties(record) & NORTHERN_IRELAND_COUNTIES]
    irish_statuses: Counter[str] = Counter()
    townland_assignments = bilingual_townland_assignments = 0
    other_assignments = bilingual_other_assignments = 0
    for record in ni_records:
        assignments = len(direct_counties(record) & NORTHERN_IRELAND_COUNTIES)
        category_id, _ = category(record)
        if category_id == "BF":
            townland_assignments += assignments
            bilingual_townland_assignments += assignments * (form_state(record) == "bilingual")
        else:
            other_assignments += assignments
            bilingual_other_assignments += assignments * (form_state(record) == "bilingual")
        irish = [
            name for name in record.get("placenames", [])
            if name.get("language", "").lower() == "ga" and name.get("wording", "").strip()
        ]
        main = next((name for name in irish if name.get("main")), irish[0] if irish else None)
        status = (
            (main.get("acceptability") or {}).get("textEN") or "unspecified"
            if main else "no Irish form"
        )
        irish_statuses[status] += assignments
    return rows, {
        "unique_records": len(ni_records),
        "record_assignments": sum(row["records"] for row in rows),
        "multi_county_records": sum(len(direct_counties(record)) > 1 for record in ni_records),
        "cross_jurisdiction_records": sum(
            bool(direct_counties(record) & NORTHERN_IRELAND_COUNTIES)
            and bool(direct_counties(record) - NORTHERN_IRELAND_COUNTIES)
            for record in ni_records
        ),
        "category_mix_expected_bilingual_rate_at_roi_rates": round(expected / covered, 4),
        "category_mix_comparable_assignments": covered,
        "townland_assignments": townland_assignments,
        "bilingual_townland_assignments": bilingual_townland_assignments,
        "townland_bilingual_rate": round(bilingual_townland_assignments / townland_assignments, 4),
        "other_assignments": other_assignments,
        "bilingual_other_assignments": bilingual_other_assignments,
        "other_bilingual_rate": round(bilingual_other_assignments / other_assignments, 4),
        "irish_form_status_assignments": dict(irish_statuses),
    }


def write_csv(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def build_review(snapshot: dict) -> tuple[dict, list[dict], list[dict]]:
    records = snapshot.get("records", [])
    records_by_id = {int(record["id"]): record for record in records}
    countyless_records = [record for record in records if not direct_counties(record)]
    multi_records = [record for record in records if len(direct_counties(record)) > 1]
    countyless_rows = [
        review_row(record, records_by_id, countyless_disposition(record, records_by_id))
        for record in countyless_records
    ]
    multi_rows = [
        review_row(record, records_by_id, multi_county_disposition(record))
        for record in multi_records
    ]
    county_rows, ni_summary = county_profile(records)
    report = {
        "snapshotFetchedAt": snapshot.get("fetchedAt"),
        "northernIreland": {"summary": ni_summary, "counties": county_rows},
        "countyless": {
            "records": len(countyless_rows),
            "dispositions": dict(Counter(row["disposition"] for row in countyless_rows)),
            "categories": dict(Counter(row["category"] for row in countyless_rows)),
        },
        "multiCounty": {
            "records": len(multi_rows),
            "dispositions": dict(Counter(row["disposition"] for row in multi_rows)),
            "categories": dict(Counter(row["category"] for row in multi_rows)),
        },
    }
    return report, countyless_rows, multi_rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("snapshot", type=Path)
    parser.add_argument("--json-output", type=Path, required=True)
    parser.add_argument("--countyless-csv", type=Path, required=True)
    parser.add_argument("--multi-county-csv", type=Path, required=True)
    args = parser.parse_args()
    report, countyless_rows, multi_rows = build_review(json.loads(args.snapshot.read_text(encoding="utf-8")))
    args.json_output.parent.mkdir(parents=True, exist_ok=True)
    args.json_output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    write_csv(args.countyless_csv, countyless_rows)
    write_csv(args.multi_county_csv, multi_rows)
    print(json.dumps({"countyless": len(countyless_rows), "multiCounty": len(multi_rows)}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
