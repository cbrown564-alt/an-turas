# Independent review of Logainm coverage in Northern Ireland

*Reviewed 13 July 2026 against the production Logainm snapshot fetched at 08:19:39 UTC. “Derry” follows the Logainm county label; external sources may use “Derry/Londonderry” or “Londonderry”.*

## Executive summary

- **The shortfall is a townland-research gap, not a general Northern place-name gap.** Across the six counties, only 1,215 of 9,757 townland assignments are bilingual (12.5%), while 1,417 of 1,564 non-townland assignments are bilingual (90.6%). Townlands account for 8,542 of the 8,689 non-bilingual assignments (98.3%).
- **County mix does not explain the result.** Reweighting Republic-of-Ireland within-category bilingual rates to the Northern category mix produces an indicative expected rate of 89.8%, versus 23.3% observed. This is not a causal estimate, but it rejects “Northern counties merely contain harder place types” as a sufficient explanation.
- **No reviewed source is safe for an automatic bulk fill today.** The Northern Ireland Place-Name Project is the strongest scholarly source, but its public layer contains almost no fill-ready townland `Irish_Form` values and does not state a reuse licence. Townlands.ie/OpenStreetMap supplies 2,654 promising Logainm-linked candidates, but they are unreviewed, sometimes malformed or historical, and governed by ODbL rather than the Logainm CC BY 4.0 contract.
- **The hierarchy exceptions are much smaller than their raw counts suggest.** Of 229 countyless records, 32 are expected county roots, 82 have no usable form and do not ship, and 22 can recover a county from existing Logainm links. Of 312 multi-county records, 237 are plausible cross-boundary physical features. The work should focus on the remaining targeted queues, not flatten every record to one county.

## Six-county evidence

The table uses direct Logainm county assignments, so a genuinely multi-county record appears once in each applicable county. There are 11,295 unique Northern records and 11,321 county assignments; 54 records are multi-county and 32 cross the jurisdictional boundary.

| County | All records | Bilingual | Townlands | Bilingual townlands | Other records | Bilingual other |
|---|---:|---:|---:|---:|---:|---:|
| Antrim | 2,150 | 714 (33.2%) | 1,756 | 357 (20.3%) | 394 | 357 (90.6%) |
| Armagh | 1,135 | 328 (28.9%) | 959 | 167 (17.4%) | 176 | 161 (91.5%) |
| Derry | 1,502 | 377 (25.1%) | 1,272 | 170 (13.4%) | 230 | 207 (90.0%) |
| Down | 1,701 | 528 (31.0%) | 1,336 | 194 (14.5%) | 365 | 334 (91.5%) |
| Fermanagh | 2,413 | 285 (11.8%) | 2,260 | 151 (6.7%) | 153 | 134 (87.6%) |
| Tyrone | 2,420 | 400 (16.5%) | 2,174 | 176 (8.1%) | 246 | 224 (91.1%) |
| **Six-county assignments** | **11,321** | **2,632 (23.3%)** | **9,757** | **1,215 (12.5%)** | **1,564** | **1,417 (90.6%)** |

The issue is not just presence or absence. Of the 2,637 assignments with any Irish form, the main form is explicitly marked `validated name` in only 751 (28.5%); 962 are `non-validated`, 913 have no acceptability value, and 11 are historical/local. The product should retain this source status instead of describing every available Irish form as equally established.

## Review of the 229 countyless records

| Disposition | Records | Finding |
|---|---:|---|
| Expected county roots | 32 | County records correctly have no county parent. Exclude them from the “countyless defect” metric. |
| No usable form | 82 | These are already ineligible for the foundation index. Track as source tombstones/incomplete rows, not county repair work. |
| Recover from existing hierarchy | 22 | Existing parent or cluster links already resolve a county. The audit/projection can derive these without an external source, while retaining `county_assignment_method = inferred_hierarchy`. |
| Manual or spatial review | 93 | This includes 40 streets, 19 historical names, 7 categoryless named rows, 4 provinces, 4 islands, 3 townlands, 3 electoral divisions, one civil parish, and smaller offshore/global categories. Only 47 are ordinary street or administrative records likely to need a county. |

Four Northern cases are immediately actionable:

- Logainm `56408` Clankilvoragh, `56409` Derrylisnahavil, and `56410` Donagreagh all sit within County Armagh in the LPS county geometry and in the historical townland lists. Add Armagh as a source correction or a separately provenance-marked inferred county.
- Logainm `2737` Magheralin is a civil parish spanning Armagh and Down. It should be multi-county, not forced into one county. The three records above are specifically the Armagh portion. The [1851 census table for County Armagh](https://www.cso.ie/en/media/csoie/statistics/archive/census1851/THE_CENSUS_OF_IRELAND_1851_-_Armagh.pdf) identifies Magheralin as partly in Armagh with the remainder in Down; [Townlands.ie’s Armagh parish view](https://www.townlands.ie/armagh/magheralin/) lists the same three townlands.

These four reviewed assignments and the 22 existing-link recoveries are now applied
to the generated foundation through `logainm-hierarchy-repairs.json`. The source
snapshot remains untouched. Each generated record carries its assignment method and
supporting source identifiers; future source changes therefore remain distinguishable
from local reviewed repairs.

## Review of the 312 multi-county records

| Disposition | Records | Recommendation |
|---|---:|---|
| Plausible cross-boundary feature | 237 | Retain multiple counties. This group is dominated by 103 rivers, 36 mountains/ranges, 31 lakes, 12 bridges, 7 estuaries and other linear/areal features. |
| Administrative boundary review | 23 | Check eight townlands, three civil parishes, three towns, seven population centres, one barony and one electoral division against official boundaries. Do not assume they are errors; places such as Newry and Portglenone legitimately cross historic county boundaries. |
| Waterford-city hierarchy review | 35 | These are a systematic Kilkenny/Waterford group of street or address-like records. Validate the shared city hierarchy once, then apply one documented rule to the cohort. |
| Street hierarchy conflict review | 9 | Inspect individually. Several rows contain parent chains from different settlements/counties and look more like hierarchy joins than cross-boundary streets. |
| Manual review | 8 | Review the remaining historical, road, waterfall, man-made and categoryless cases individually. |

County totals must continue to be described as **assignments**, not a partition of unique records. The projection should retain all source counties and optionally add one `primary_county` only for navigation, with an explicit derivation method.

## Candidate source assessment

### 1. Northern Ireland Place-Name Project — best authority, not fill-ready

The [Queen’s University description](https://www.qub.ac.uk/schools/ael/Research/ResearchinLanguages/imdorus/DigitalProjectsfortheGaelicWorld/) says the corpus contains about 9,600 townlands and at least 20,000 non-administrative names. The [Irish Collections Network catalogue](https://irishcollectionsnetwork.qub.ac.uk/s/ICN/item-set/1131) confirms coverage of all six counties plus historical spellings, source references and local-pronunciation fieldwork. Logainm already lists the Project as a [resource-exchange partner](https://www.logainm.ie/en/about/partnership-links).

The current [PlacenamesNI ArcGIS application](https://experience.arcgis.com/experience/9b31e0501b744154b4584b1dce1f859b) exposes 42,357 gazetteer rows. Its exact-townland cohort contains 9,529 rows, but only 14 currently have a non-empty `Irish_Form` field (2 Antrim, 12 Armagh; none in the other four counties), and none has `IrishFormLocal`. The richer historical-reference and explanatory fields may support research, but they are not canonical Irish display forms. The application also states that Down was the first completed/checked phase, while the other counties’ historical data should not be treated as fully verified.

There are two blockers:

- the Project’s current application says its funding period has ended and the team is winding down and cannot respond to new enquiries;
- the [ArcGIS item metadata](https://www.arcgis.com/sharing/rest/content/items/9b31e0501b744154b4584b1dce1f859b?f=pjson) declares neither `licenseInfo` nor `termsOfUse` for database reuse.

Use it as the preferred scholarly partner/source once reuse terms and a data handoff are agreed. Do not scrape explanatory prose into a canonical-name field.

### 2. Townlands.ie / OpenStreetMap — useful candidate generator, not authority

The [Townlands.ie download](https://www.townlands.ie/en/page/download/) is explicitly incomplete and ODbL-licensed. Its April 2022 no-geometry export contains 9,687 rows across the six counties, 5,676 with `NAME_GA`. Exact numeric `logainm:ref` matching finds 2,654 unique townlands where Townlands.ie has `NAME_GA` and the current Logainm record has no Irish form:

| County label in Townlands.ie | Candidate rows | Upper-bound townland coverage if every candidate passed review |
|---|---:|---:|
| Antrim | 527 | 50.3% |
| Armagh | 214 | 39.7% |
| Londonderry | 702 unique IDs (707 rows) | 68.6% |
| Down | 591 | 58.8% |
| Fermanagh | 78 | 10.1% |
| Tyrone | 542 unique IDs (543 rows) | 33.0% |

That is a worthwhile review queue, but not a production import. The export contains mojibake, forms identical to English, historical spellings, uncertain reconstructions and no validation status. If every candidate were approved, overall Northern townland coverage would rise only from 12.5% to about 39.7%, and Fermanagh would remain critically incomplete. Before combining any ODbL-derived forms with the CC BY foundation database, obtain licensing advice and define database attribution/share-alike obligations.

### 3. OSNI/LPS and PRONI — hierarchy and geometry, not bilingual forms

The [OSNI 50K townland boundaries](https://www.data.gov.uk/dataset/123adcd5-aa6e-4ebe-a47f-377ec2c0e6ff/osni-open-data-50k-boundaries-townlands6) are official, downloadable under the Open Government Licence, and suitable for county membership, geometry and point-in-polygon repair. The [OSNI place-name gazetteer](https://www.data.gov.uk/dataset/25ac7a78-af01-4727-b8b7-265ba8ee96b4/osni-open-data-gazetteer-place-names) covers only 336 towns and villages, so it cannot close the townland gap. [PRONI’s county townland lists](https://www.proni.gov.uk/publications/townlands-county) are a useful independent membership check. These sources can fix hierarchy and coordinates but do not supply a reviewed Irish form.

## Recommended solution

1. **Hierarchy repair applied; continue the bounded review.** The foundation now recovers the 22 existing-link cases, assigns the three Magheralin townlands to Armagh, and represents Magheralin parish as Armagh + Down. Source and repaired assignments remain distinguishable. The 75 targeted multi-county rows remain an editorial/boundary-review queue and have not been guessed or flattened.
2. **Ask Logainm/DCU for an upstream route.** Send the record queues and ask whether the existing NIPNP/OpenStreetMap partnerships can be used to publish reviewed Irish townland forms through Logainm. This keeps one canonical identifier, one CC BY provenance chain, and future monthly updates. Logainm’s project contact is published on its [project page](https://www.logainm.ie/en/about/about-project).
3. **Pilot a licensed specialist workflow in County Down.** NIPNP describes Down as its checked first phase. Request a structured export containing English form, recommended Irish form, form type (`established`, `postulated`, `historical`, `local`), confidence/review state, stable source ID, citations and reuse terms. Match by Logainm ID where available, otherwise by townland + parish + county + geometry. Measure acceptance and disagreement before scaling.
4. **Keep external suggestions in a separate candidate layer.** Minimum fields: `logainm_id`, `source`, `source_record_id`, `language`, `wording`, `form_type`, `confidence`, `match_method`, `rights`, `review_status`, `reviewer`, `reviewed_at`, and citations. Only `approved` rows may affect public display; never machine-translate a missing townland name.
5. **Be honest in the product meanwhile.** Continue to show the English source form where no Irish form exists and say “Irish form not yet established in the available source.” Preserve Logainm’s `validated`, `non-validated`, historical/local and unspecified distinctions in generated detail.

## Decision

Do not bulk-fill the six counties from a secondary dataset in the current release. The defensible hierarchy repairs are now applied; pursue an upstream Logainm/NIPNP handoff as the preferred enrichment path and use Townlands.ie only to prioritise specialist review. Treat Fermanagh as a separate research workstream because neither current Logainm nor the available candidate sources provide material coverage there.

## Reproducibility

- Aggregate audit: `content/personal-atlas/logainm-ni-review.json`
- Countyless queue: `content/personal-atlas/logainm-countyless-review.csv`
- Multi-county queue: `content/personal-atlas/logainm-multi-county-review.csv`
- Generator: `tools/review_logainm_hierarchy.py`
- Applied repair overlay: `content/personal-atlas/logainm-hierarchy-repairs.json`

The source snapshot is intentionally git-ignored. Regenerate the three retained outputs after each monthly ingest.
