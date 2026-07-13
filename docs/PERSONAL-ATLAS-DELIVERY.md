# Personal atlas delivery and release audit

*Last audited 13 July 2026. This is the acceptance ledger for
`PERSONAL-HISTORIES-FEATURE-PLAN.md`; a feature is not complete merely because its
software path exists.*

## Current release decision

**Engineering-complete for the phased product surface; not approved for public
release.** The app, content graph, editorial controls, ingestion, signed delivery,
privacy boundaries, fallbacks, and Phase 4 interaction shells exist and pass automated
tests. The public payload intentionally contains zero subjects. Named specialist
review, licences, commissioned media, moderated user evidence, all-island partner work,
independent accessibility QA, production hosting, and release approval cannot be
manufactured in code and remain open.

Pilot copy is therefore bundled only as `pilot`, sharing does not present it as a
public authority, and the exporter fails closed.

## Phase-by-phase acceptance ledger

| Plan requirement | Delivered evidence | Status / release evidence still required |
|---|---|---|
| **0: three interaction grammars and hard cases** | Research protocol contains answer-first, evidence-first, and map/time-first prototypes, a 24-case matrix, session script, comprehension prompts, and 24-hour recall method. | **Prepared, not passed:** run 12–18 target-user sessions and obtain reviews from the named disciplines. Record the winning grammar and results in `docs/DECISIONS.md`. |
| **0: claim schema survives expert review** | Typed assertions, evidence references, certainty, competing claims, review history, rights, and durable assertion IDs are enforced for release. | **Open:** named onomastic, Irish-language, placename, archival, and community sign-off. |
| **1: 25 given, 25 surnames, 30 places** | The offline pilot pack contains 25/25/30 authored entries with source-linked assertions and honest pilot authority. | **Pilot only:** modern surname licensing, named review, and rights clearance are not complete. |
| **1: broad place foundation** | Monthly Logainm v1.1 ingestion, provenance snapshots, replacement handling, broad foundation-index builder, official forms/hierarchy/coordinates/permalink, safe fallback result, and monthly CI artifact workflow. First production ingest on 13 July 2026 fetched 126,798 records and built 126,712 entries spanning all 32 counties; 99,000 entries are bilingual and 119,141 have valid island-bounded coordinates. The projection converts 7,571 sentinel/out-of-scope points to unavailable. The app uses a 49 MB indexed SQLite resource with 305,638 aliases and lazy search/detail reads instead of decoding the former 160.7 MB JSON corpus into memory. | **Production ingest and app packaging complete:** attribution, API contract, database integrity, diacritic-insensitive lookup, generated detail, coordinate bounds, and source-to-database reconciliation are tested. [Automated coverage audit](LOGAINM-COVERAGE-AUDIT.md) passes its projection gates; independent all-island review remains required because Northern Ireland bilingual completeness is materially lower. |
| **1: complete native journey** | Pre-commitment atlas entry, normalized search, ambiguity paths, concise result, evidence sheets, native map plus list equivalent, local save/collection, Mayo story handoff, recent pages only after opt-in, and custom/web deep links. | **Implemented:** independent VoiceOver, Dynamic Type, contrast, and device QA remain release gates. |
| **1: signed/versioned offline delivery** | SHA-256 plus Ed25519 detail artifacts, pinned-key verification, authenticated cache, tamper eviction, last-good-cache behavior during network failure, manifest/index builder, and tests using real signatures. | **Implemented:** production key custody, rotation procedure, CDN base URL, and release ceremony remain operational work. |
| **1: scorecard** | Query ledger stores published subject ID, unresolved category, selected branch, time to answer, and continuation without raw input or exact coordinates. | **Open:** resolve ≥90% hard cases honestly; measure comprehension, next-day recall, care, engagement, and median answer time with real participants. |
| **2: assertion-level editorial engine** | Existing review CMS supports name/place preview, candidate progression, claim review, competing readings, rights, audio, accessibility, reviewer assignments, query demand, corrections, and public preview. Exporter requires durable mappings and named review. | **Implemented workflow; open content operations:** demonstrate an editor-led requested→released run and record throughput/cost. |
| **2: 100/100/100 reviewed catalogue** | Schema and batch tooling support the catalogue without app releases. | **Open:** commission, author, license, review, and accessibility-check 100 surnames, 100 given names, and 100 places. Pilot rows do not count. |
| **2: verified human pronunciation** | Only explicit bundled audio with speaker, dialect, recording date, permission, transcript, and translation can be presented as verified; synthetic personal-name speech is excluded. | **Open:** record, clear, review, and bundle native-speaker audio for the pilot. |
| **2: reproducible historic distribution** | Aggregate-only builder requires dataset/year/geography/source, suppression-safe rows, and cleared or link-only rights. UI explicitly says distribution is not family origin. | **Pipeline complete; data open:** agree source terms and publish reviewed CSO/archive aggregates. |
| **2: safe corrections and all-island audit** | Assertion/form feedback is a private lead with context and source field; it cannot mutate public data. Rights register and protocol identify NI terminology and source work. | **Open:** prove handling with real submissions; commission PRONI/GRONI/OSNI/NI Place-Name Project coverage and community review. |
| **3: public/search/share foundation** | Explicit coverage and method limits, static crawlable pages, canonical/meta/robots/sitemap, visible sources and reviewer/rights, web/app subject links, and public-only sourced sharing. | **Software complete; launch open:** production host, universal-link association, privacy/security review, analytics endpoint decision, SEO QA, and public approval. |
| **3: contextual nearby and graph connections** | Location is requested in context, rounded to coarse coordinates, used for local suggestions, and not retained; results connect to collection and genuine story handoffs. | **Implemented:** device permission and field testing remain. |
| **3: membership and public policy** | First answer remains free; membership follows the meaningful reveal. Methodology, correction route, credits, and “what a name cannot tell” are available in app and docs. | **Implemented:** product/legal approval of final subscription and policy language remains. |
| **4: time in the hand** | Present map/historic-image alignment, slider, reduced-motion behavior, feature-list equivalent, attribution, and rights gating exist. | **Shell complete:** license and bundle historic sheets and author feature alignments. |
| **4: voices and a name travelling** | Full voice metadata and permission gates exist. Travel moments require a sourced form/year/place and explicitly reject ancestry inference. | **Shell complete:** commission local voices and author reviewed travel moments. |
| **4: keepsake, field mode, family handoff** | Verified-form typographic keepsake; offline place pack, walking-scale map, audio and safety copy; private worksheet with official archive routes and no inferred relatives. | **Implemented:** moderated usefulness/safety testing and final archive-link review remain. |
| **4: community editions and seasons** | Community-edition metadata requires partner, editor, reviewer, agreed credit/consent, and correction URL before public release. | **Open:** execute partnership, revenue, credit, consent, and correction agreements; commission the first authored season. |

## Non-negotiable automated gates

The app validator and publisher jointly enforce:

- every material published claim is non-empty and has evidence, certainty, reviewer,
  review date, cleared rights, durable ID, and review history;
- the short answer and every etymology/derivation branch map to durable assertions;
- competing assertions resolve, variants have typed relationships, and all evidence
  references resolve;
- verified audio and historic-map/community assets carry their complete permission and
  attribution metadata;
- foundation results cannot impersonate authored stories;
- raw names and exact coordinates are absent from analytics;
- pilot content cannot be exported or shared as public content;
- a non-empty detail release requires a private Ed25519 key; tampered or unsigned
  details never enter cache.

## Reproducible verification

```bash
cd ios
xcodegen generate --spec project.yml
xcodebuild -project AnTuras.xcodeproj -scheme AnTuras \
  -destination 'platform=iOS Simulator,id=<SIMULATOR-UDID>' test

cd ..
python3 -m unittest discover -s tools/tests -v
python3 -m json.tool ios/AnTuras/Resources/personal-atlas-subjects.json >/dev/null
sqlite3 ios/AnTuras/Resources/personal-atlas-foundation.sqlite 'PRAGMA integrity_check;'
plutil -lint ios/AnTuras/Info.plist
```

Audited result on 13 July 2026: 13 Swift tests and 15 Python tests pass. JSON, SQLite,
and plist validation, CMS JavaScript syntax, GitHub workflow YAML parsing, empty static
preview generation, and empty signed-release generation also pass.

## Release operations

1. Export the CMS review log and build the deny-by-default public payload:

   ```bash
   python3 tools/publish_personal_atlas.py review-log.json \
     --output build/public-subjects.json
   ```

2. Generate crawlable pages and sitemap:

   ```bash
   python3 tools/build_personal_web_previews.py \
     build/public-subjects.json build/site/personal-atlas
   ```

3. Generate independently authenticated detail artifacts. Keep the private key out of
   the repository and CI logs:

   ```bash
   python3 tools/build_personal_atlas_release.py \
     build/public-subjects.json build/release \
     --private-key "$PERSONAL_ATLAS_SIGNING_KEY" \
     --public-key-id anturas-personal-atlas-v1
   ```

4. For the official place foundation, create a Gaois Developer Hub key and run the
   scheduled workflow or local ingest. The client follows the official HTTPS,
   `X-Api-Key`, paging, `ModifiedSince`, replacement, monthly-update, attribution, and
   rate-limit guidance from [Logainm open data](https://www.logainm.ie/en/about/open-data),
   the [API guide](https://docs.gaois.ie/ga/data/logainm/v1.1/api), and the
   [data dictionary](https://docs.gaois.ie/ga/data/logainm/v1.1/data).

## External completion checklist

The goal can be marked complete only when evidence—not assurances—is attached for:

- Phase 0 participant/expert sessions and 24-hour recall;
- Phase 1 scorecard and independent accessibility/device QA;
- named specialist review and rights clearance for every public claim and asset;
- production Logainm ingest and approved all-island coverage;
- commissioned 100/100/100 catalogue, voices, distributions, historic maps, and first
  community season;
- production hosting, key custody, universal links, privacy/security/legal/product
  approvals, and final release sign-off.

Until then, the correct public output is the current empty release—not pilot prose
presented with production authority.
