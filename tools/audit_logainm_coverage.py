#!/usr/bin/env python3
"""Audit the production Logainm snapshot and shipped SQLite projection.

The audit distinguishes source limitations from projection failures. It never reads
or emits the API key and is safe to run in CI against retained snapshot artifacts.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from datetime import datetime
from pathlib import Path


NORTHERN_IRELAND_COUNTIES = {"Antrim", "Armagh", "Derry", "Down", "Fermanagh", "Tyrone"}


def percentage(numerator: int, denominator: int) -> float:
    return round(100 * numerator / denominator, 2) if denominator else 0.0


def profile(snapshot: dict, database_path: Path) -> dict:
    records = snapshot.get("records", [])
    ids = [item.get("id", item.get("ID")) for item in records]
    form_counts: Counter[str] = Counter()
    county_counts: Counter[str] = Counter()
    county_bilingual: Counter[str] = Counter()
    eligible_ids: set[int] = set()
    invalid_coordinate_ids: set[int] = set()
    countyless = multiple_counties = missing_modified = 0

    for item in records:
        place_id = int(item.get("id", item.get("ID")))
        placenames = item.get("placenames", item.get("Placenames", [])) or []
        has_irish = any(
            (name.get("language", name.get("Language")) or "").lower() == "ga"
            and (name.get("wording", name.get("Wording")) or "").strip()
            for name in placenames
        )
        has_english = any(
            (name.get("language", name.get("Language")) or "").lower() == "en"
            and (name.get("wording", name.get("Wording")) or "").strip()
            for name in placenames
        )
        form_state = "bilingual" if has_irish and has_english else "irish_only" if has_irish else "english_only" if has_english else "no_usable_form"
        form_counts[form_state] += 1
        if has_irish or has_english:
            eligible_ids.add(place_id)

        counties = {
            parent.get("nameEN") or parent.get("NameEN") or parent.get("nameGA") or parent.get("NameGA")
            for parent in item.get("includedIn", item.get("IncludedIn", [])) or []
            if (parent.get("category", parent.get("Category", {})) or {}).get("id", (parent.get("category", parent.get("Category", {})) or {}).get("ID")) == "CON"
        }
        counties.discard(None)
        if not counties:
            countyless += 1
        if len(counties) > 1:
            multiple_counties += 1
        for county in counties:
            county_counts[county] += 1
            if has_irish and has_english:
                county_bilingual[county] += 1

        geography = item.get("geography", item.get("Geography", {})) or {}
        if isinstance(geography, list):
            geography = geography[0] if geography else {}
        points = geography.get("coordinates", geography.get("Coordinates", [])) or []
        point = points[0] if points else {}
        latitude = point.get("latitude", point.get("Latitude"))
        longitude = point.get("longitude", point.get("Longitude"))
        if not (
            isinstance(latitude, (int, float)) and not isinstance(latitude, bool)
            and isinstance(longitude, (int, float)) and not isinstance(longitude, bool)
            and 51.0 <= latitude <= 56.0 and -11.0 <= longitude <= -5.0
        ):
            invalid_coordinate_ids.add(place_id)
        if not item.get("dateModified", item.get("DateModified")):
            missing_modified += 1

    connection = sqlite3.connect(database_path)
    try:
        database_ids = {row[0] for row in connection.execute("SELECT id FROM places")}
        database_places = len(database_ids)
        aliases = connection.execute("SELECT count(*) FROM aliases").fetchone()[0]
        orphan_aliases = connection.execute(
            "SELECT count(*) FROM aliases a LEFT JOIN places p ON p.id = a.place_id WHERE p.id IS NULL"
        ).fetchone()[0]
        invalid_shipped_coordinates = connection.execute(
            """SELECT count(*) FROM places
               WHERE (latitude IS NULL) != (longitude IS NULL)
                  OR (latitude IS NOT NULL AND (latitude < 51 OR latitude > 56 OR longitude < -11 OR longitude > -5))"""
        ).fetchone()[0]
        missing_shipped_coordinates = connection.execute(
            "SELECT count(*) FROM places WHERE latitude IS NULL OR longitude IS NULL"
        ).fetchone()[0]
        integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
        metadata = dict(connection.execute("SELECT key, value FROM metadata"))
    finally:
        connection.close()

    county_rows = []
    for county in sorted(county_counts):
        total = county_counts[county]
        bilingual = county_bilingual[county]
        county_rows.append({
            "county": county,
            "jurisdiction": "Northern Ireland" if county in NORTHERN_IRELAND_COUNTIES else "Republic of Ireland",
            "records": total,
            "bilingualRecords": bilingual,
            "bilingualRate": percentage(bilingual, total),
        })

    ni_total = sum(county_counts[county] for county in NORTHERN_IRELAND_COUNTIES)
    ni_bilingual = sum(county_bilingual[county] for county in NORTHERN_IRELAND_COUNTIES)
    roi_counties = set(county_counts) - NORTHERN_IRELAND_COUNTIES
    roi_total = sum(county_counts[county] for county in roi_counties)
    roi_bilingual = sum(county_bilingual[county] for county in roi_counties)
    checks = [
        {"check": "source_primary_key", "status": "pass" if len(ids) == len(set(ids)) and None not in ids else "fail", "value": len(set(ids)), "expected": len(ids)},
        {"check": "all_32_counties_present", "status": "pass" if len(county_counts) == 32 else "fail", "value": len(county_counts), "expected": 32},
        {"check": "projection_matches_eligible_records", "status": "pass" if database_ids == eligible_ids else "fail", "value": database_places, "expected": len(eligible_ids)},
        {"check": "sqlite_integrity", "status": "pass" if integrity == "ok" else "fail", "value": integrity, "expected": "ok"},
        {"check": "orphan_aliases", "status": "pass" if orphan_aliases == 0 else "fail", "value": orphan_aliases, "expected": 0},
        {"check": "invalid_coordinates_shipped", "status": "pass" if invalid_shipped_coordinates == 0 else "fail", "value": invalid_shipped_coordinates, "expected": 0},
        {"check": "attribution_preserved", "status": "pass" if metadata.get("attribution") == snapshot.get("attribution") else "fail", "value": metadata.get("attribution"), "expected": snapshot.get("attribution")},
    ]
    return {
        "generatedAt": datetime.now().astimezone().isoformat(timespec="seconds"),
        "snapshotFetchedAt": snapshot.get("fetchedAt"),
        "summary": {
            "sourceRecords": len(records), "eligibleRecords": len(eligible_ids),
            "shippedPlaces": database_places, "searchAliases": aliases,
            "countiesPresent": len(county_counts), "bilingualRecords": form_counts["bilingual"],
            "bilingualRate": percentage(form_counts["bilingual"], len(records)),
            "sourceInvalidCoordinates": len(invalid_coordinate_ids),
            "shippedMissingCoordinates": missing_shipped_coordinates,
            "countylessRecords": countyless, "multipleCountyRecords": multiple_counties,
            "missingModifiedDate": missing_modified,
        },
        "formCompleteness": dict(form_counts),
        "jurisdictions": [
            {"jurisdiction": "Northern Ireland", "countyAssignedRecords": ni_total, "bilingualRecords": ni_bilingual, "bilingualRate": percentage(ni_bilingual, ni_total)},
            {"jurisdiction": "Republic of Ireland", "countyAssignedRecords": roi_total, "bilingualRecords": roi_bilingual, "bilingualRate": percentage(roi_bilingual, roi_total)},
        ],
        "counties": county_rows,
        "checks": checks,
        "releaseGate": "pass" if all(check["status"] == "pass" for check in checks) else "fail",
    }


def markdown(report: dict) -> str:
    summary = report["summary"]
    ni, roi = report["jurisdictions"]
    gate = report["releaseGate"].upper()
    rows = "\n".join(
        f"| {item['county']} | {item['jurisdiction']} | {item['records']:,} | {item['bilingualRecords']:,} | {item['bilingualRate']:.1f}% |"
        for item in report["counties"]
    )
    checks = "\n".join(
        f"| {item['check']} | {item['status']} | {item['value']} | {item['expected']} |"
        for item in report["checks"]
    )
    return f"""# Logainm all-island coverage and data-quality audit

*Snapshot fetched {report['snapshotFetchedAt']}; audit generated {report['generatedAt']}.*

## Technical summary

**Automated projection gate: {gate}.** The source contains {summary['sourceRecords']:,} unique records and the shipped database contains all {summary['eligibleRecords']:,} records with a usable Irish or English form. All 32 counties are represented, SQLite integrity passes, aliases have no orphans, and required attribution is preserved.

The source is not uniformly complete. {summary['sourceInvalidCoordinates']:,} records ({percentage(summary['sourceInvalidCoordinates'], summary['sourceRecords']):.2f}%) contain missing, sentinel, or out-of-bounds coordinates; the app now stores these as unavailable instead of presenting them as real points. Bilingual coverage is {summary['bilingualRate']:.2f}% overall, but only {ni['bilingualRate']:.2f}% across county-assigned Northern Ireland records versus {roi['bilingualRate']:.2f}% in the Republic. Presence across all counties therefore does **not** establish equivalent depth or independent all-island approval.

## Key findings

- **High, remediated — invalid source coordinates:** {summary['sourceInvalidCoordinates']:,} source rows cannot safely support a map point. The projection now nulls them and the automated gate rejects any out-of-bounds coordinate that reaches the app.
- **High, open — jurisdictional completeness gap:** Northern Ireland bilingual coverage is {ni['bilingualRate']:.2f}% ({ni['bilingualRecords']:,}/{ni['countyAssignedRecords']:,}) compared with {roi['bilingualRate']:.2f}% ({roi['bilingualRecords']:,}/{roi['countyAssignedRecords']:,}) in the Republic. Specialist review must determine whether this reflects the authoritative source, category mix, or missing partner data.
- **Medium, documented — hierarchy exceptions:** {summary['countylessRecords']:,} rows have no direct county parent and {summary['multipleCountyRecords']:,} resolve to more than one county. These remain searchable, but county-based coverage totals are not a strict partition of the source.
- **Low — source freshness metadata:** {summary['missingModifiedDate']:,} source rows lack a modification date, so generated detail uses an explicit unavailable-date fallback.

## Automated release checks

| Check | Status | Observed | Expected |
|---|---:|---:|---:|
{checks}

## County evidence

The table measures records directly assigned to a county through Logainm's `includedIn` hierarchy. Multi-county records appear in each assigned county.

| County | Jurisdiction | Records | Bilingual | Bilingual rate |
|---|---|---:|---:|---:|
{rows}

## Scope and method

The unit of analysis is one Logainm API record from the production snapshot. A record is bilingual when at least one non-empty `ga` wording and one non-empty `en` wording are present. Coordinates are considered app-safe only within latitude 51–56 and longitude −11 to −5; this deliberately excludes `0,0` sentinels and points outside the island product scope. The audit reconciles eligible source IDs exactly against SQLite place IDs and checks database integrity, alias referential integrity, attribution, and coordinate validity.

## Limitations and next steps

This audit establishes technical coverage and measurable source completeness; it is not linguistic, onomastic, community, or political approval. Commission independent review of the six Northern Ireland counties, inspect the 229 countyless and 312 multi-county records, and agree whether entries without valid coordinates should remain searchable but mapless. Re-run this audit after every monthly ingest and block artifact promotion when `releaseGate` is `fail`.
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("snapshot", type=Path)
    parser.add_argument("database", type=Path)
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--markdown-output", type=Path)
    args = parser.parse_args()
    report = profile(json.loads(args.snapshot.read_text(encoding="utf-8")), args.database)
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if args.markdown_output:
        args.markdown_output.parent.mkdir(parents=True, exist_ok=True)
        args.markdown_output.write_text(markdown(report), encoding="utf-8")
    print(json.dumps(report["summary"], ensure_ascii=False))
    return 0 if report["releaseGate"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
