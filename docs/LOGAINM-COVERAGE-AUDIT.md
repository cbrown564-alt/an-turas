# Logainm all-island coverage and data-quality audit

*Snapshot fetched 2026-07-13T08:19:39+00:00; audit generated 2026-07-13T10:06:08+01:00.*

## Technical summary

**Automated projection gate: PASS.** The source contains 126,798 unique records and the shipped database contains all 126,712 records with a usable Irish or English form. All 32 counties are represented, SQLite integrity passes, aliases have no orphans, and required attribution is preserved.

The source is not uniformly complete. 7,655 records (6.04%) contain missing, sentinel, or out-of-bounds coordinates; the app now stores these as unavailable instead of presenting them as real points. Bilingual coverage is 78.08% overall, but only 23.25% across county-assigned Northern Ireland records versus 83.54% in the Republic. Presence across all counties therefore does **not** establish equivalent depth or independent all-island approval.

## Key findings

- **High, remediated — invalid source coordinates:** 7,655 source rows cannot safely support a map point. The projection now nulls them and the automated gate rejects any out-of-bounds coordinate that reaches the app.
- **High, open — jurisdictional completeness gap:** Northern Ireland bilingual coverage is 23.25% (2,632/11,321) compared with 83.54% (96,578/115,607) in the Republic. Specialist review must determine whether this reflects the authoritative source, category mix, or missing partner data.
- **Medium, documented — hierarchy exceptions:** 229 rows have no direct county parent and 312 resolve to more than one county. These remain searchable, but county-based coverage totals are not a strict partition of the source.
- **Low — source freshness metadata:** 98 source rows lack a modification date, so generated detail uses an explicit unavailable-date fallback.

## Automated release checks

| Check | Status | Observed | Expected |
|---|---:|---:|---:|
| source_primary_key | pass | 126798 | 126798 |
| all_32_counties_present | pass | 32 | 32 |
| projection_matches_eligible_records | pass | 126712 | 126712 |
| sqlite_integrity | pass | ok | ok |
| orphan_aliases | pass | 0 | 0 |
| invalid_coordinates_shipped | pass | 0 | 0 |
| attribution_preserved | pass | Irish-language placename data by Logainm © Government of Ireland and licensed under CC BY 4.0. | Irish-language placename data by Logainm © Government of Ireland and licensed under CC BY 4.0. |

## County evidence

The table measures records directly assigned to a county through Logainm's `includedIn` hierarchy. Multi-county records appear in each assigned county.

| County | Jurisdiction | Records | Bilingual | Bilingual rate |
|---|---|---:|---:|---:|
| Antrim | Northern Ireland | 2,150 | 714 | 33.2% |
| Armagh | Northern Ireland | 1,135 | 328 | 28.9% |
| Carlow | Republic of Ireland | 1,193 | 782 | 65.5% |
| Cavan | Republic of Ireland | 2,685 | 1,663 | 61.9% |
| Clare | Republic of Ireland | 3,750 | 2,894 | 77.2% |
| Cork | Republic of Ireland | 12,090 | 9,653 | 79.8% |
| Derry | Northern Ireland | 1,502 | 377 | 25.1% |
| Donegal | Republic of Ireland | 6,375 | 5,213 | 81.8% |
| Down | Northern Ireland | 1,701 | 528 | 31.0% |
| Dublin | Republic of Ireland | 17,509 | 17,220 | 98.3% |
| Fermanagh | Northern Ireland | 2,413 | 285 | 11.8% |
| Galway | Republic of Ireland | 8,992 | 8,268 | 92.0% |
| Kerry | Republic of Ireland | 6,666 | 5,787 | 86.8% |
| Kildare | Republic of Ireland | 3,081 | 1,737 | 56.4% |
| Kilkenny | Republic of Ireland | 2,935 | 2,880 | 98.1% |
| Laois | Republic of Ireland | 1,809 | 1,451 | 80.2% |
| Leitrim | Republic of Ireland | 1,879 | 1,833 | 97.5% |
| Limerick | Republic of Ireland | 5,409 | 4,300 | 79.5% |
| Longford | Republic of Ireland | 1,269 | 1,236 | 97.4% |
| Louth | Republic of Ireland | 2,037 | 1,700 | 83.5% |
| Mayo | Republic of Ireland | 5,642 | 5,053 | 89.6% |
| Meath | Republic of Ireland | 3,793 | 3,059 | 80.7% |
| Monaghan | Republic of Ireland | 2,250 | 2,224 | 98.8% |
| Offaly | Republic of Ireland | 1,789 | 1,720 | 96.1% |
| Roscommon | Republic of Ireland | 2,986 | 1,458 | 48.8% |
| Sligo | Republic of Ireland | 2,392 | 2,340 | 97.8% |
| Tipperary | Republic of Ireland | 5,578 | 4,630 | 83.0% |
| Tyrone | Northern Ireland | 2,420 | 400 | 16.5% |
| Waterford | Republic of Ireland | 4,766 | 3,497 | 73.4% |
| Westmeath | Republic of Ireland | 2,180 | 841 | 38.6% |
| Wexford | Republic of Ireland | 3,713 | 3,232 | 87.0% |
| Wicklow | Republic of Ireland | 2,839 | 1,907 | 67.2% |

## Scope and method

The unit of analysis is one Logainm API record from the production snapshot. A record is bilingual when at least one non-empty `ga` wording and one non-empty `en` wording are present. Coordinates are considered app-safe only within latitude 51–56 and longitude −11 to −5; this deliberately excludes `0,0` sentinels and points outside the island product scope. The audit reconciles eligible source IDs exactly against SQLite place IDs and checks database integrity, alias referential integrity, attribution, and coordinate validity.

## Limitations and next steps

This audit establishes technical coverage and measurable source completeness; it is not linguistic, onomastic, community, or political approval. Commission independent review of the six Northern Ireland counties, inspect the 229 countyless and 312 multi-county records, and agree whether entries without valid coordinates should remain searchable but mapless. Re-run this audit after every monthly ingest and block artifact promotion when `releaseGate` is `fail`.
