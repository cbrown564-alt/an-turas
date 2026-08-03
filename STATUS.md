# STATUS

*Project: An Turas (working title) — an iOS app for learning Irish through the real
stories and places of Ireland. Updated 2026-08-03 (bulk Track A priority).*

## Current outcome

An Turas has a verified representative Mayo Story-and-Learning loop, shared learning
runtime, four in-app county review packs, a nationwide Personal Atlas foundation, and
a controlled Irish authoring/audio pipeline.

The immediate phase is the **D32 emergency Irish audio harvest**. The first all-county
tranche, a story-linked Personal Atlas tranche, and an extension tranche (names/places,
story transitions, mutation/fada contrasts, pedagogy examples) are complete, but the
harvest is not: **140,872 ElevenLabs credits remained at the last observed provider
check**. The latest extension payload used **74** aggregate credits for **16**
successful captures. The provider does not expose a trustworthy per-batch credit
allocation, so the ledger records that delta only at the aggregate checkpoint.
Provisional generation may continue during the subscription window. Capture does not
imply linguistic approval or learner release.

The product is implemented as a substantial prototype. It has not been validated for
learning outcomes or promoted for public release.

## Current evidence

### Irish corpus and audio

- **641** phrase families, **1,484** authored members, **1,482** complete members, and
  **705** unique normalized texts across all **32** counties. The two incomplete members
  are the deliberately retired Corca Dhuibhne lines described below.
- **708** registered audio lines: **698** approved, **700** provider successes, **2**
  retired semantic quarantines, **9** cancelled, **0** failed, and **0** actively
  claimed. There is no remaining resumable or manual-recovery work.
- **1,062** bundled MP3s: **700** source-labelled v2 captures and **362** legacy/runtime
  clips.
- **1,062/1,062** checksums verify. There are no missing, mismatched, or orphan files.
- The technical anomaly audit inspected all **1,046** clips: **1,036** pass, **10** need
  targeted listening review, and **0** require technical quarantine. Two additional
  Corca Dhuibhne captures are retained byte-for-byte for audit but are semantically
  retired, dynamically excluded, failed for learner QA, and unavailable through both
  text and named-asset runtime paths.
- The Personal Atlas tranche contains **80** subjects—**50 names** and **30 places**—
  with two spoken forms each and **160** newly captured clips.
- The extension tranche adds **23** authored members across **641** families: **14**
  story-linked historical name/place lines, **7** shared story-transition recaps, **2**
  Sean/fada contrast lines, and **2** pedagogy-sidecar lessons. **16** lines were
  registered, drained, and reconciled in payload `d32.harvest.extension.2026-08-03`
  with **0** failures and **0** unresolved claims.
- The prior story-linked authoring tranche adds **9** name/place subjects and **18**
  lines across eight resumable manifests. Sixteen lines remain pending human QA; the two
  Corca Dhuibhne lines are the retired captures above.
- **20** pre-D31 worktree captures are checksum-verified in a quarantine archive;
  they are excluded from the runtime and v2 ledger pending explicit migration, and one
  conflicts with an existing canonical slug.
- All v2 captures remain `generated_unreviewed`. The high-risk audit reports **17**
  capture blockers, **141** review-before-release items, and **0** learner-release-
  eligible lines.

Canonical records:

- [`content/audio/authoring/phrase-family-store-v2.json`](content/audio/authoring/phrase-family-store-v2.json)
- [`ios/AnTuras/Resources/Audio/manifest.json`](ios/AnTuras/Resources/Audio/manifest.json)
- [`content/audio/README.md`](content/audio/README.md)

### Mechanistic review

- Deterministic disjoint sampling selects **78** clips across **11** risk strata,
  including names, places, mutations, fadas, launch lines, duplicates, source risk,
  and acoustic outliers.
- The offline ABAIR comparator records provenance and checksums and compares duration,
  level, spectral shape, zero-crossing rate, and coarse envelopes against locally
  supplied reference clips.
- No ABAIR reference corpus has been supplied or compared yet. The comparator does not
  scrape ABAIR, decide pronunciation correctness, or close a release gate.

Canonical records:

- [`content/audio/authoring/sampling/d32-risk-stratification-2026-08-02.json`](content/audio/authoring/sampling/d32-risk-stratification-2026-08-02.json)
- [`docs/ABAIR.md`](docs/ABAIR.md)
- [`tools/abair_reference_compare.py`](tools/abair_reference_compare.py)

### Pedagogy

- The authoring-only pedagogy sidecar contains **21** lessons and **203**
  English-framed lines around **148** unique exact repository Irish examples
  (A4 yield band 50–200).
- Source references, invented pedagogical framing, risk flags, and separate pedagogy,
  Irish-language, pronunciation, and learner-release states are recorded.
- All review gates remain open. The sidecar is implemented and mechanically verified,
  but not validated as teaching material and not connected to the learner runtime.

Canonical records:

- [`content/pedagogy/irish-explanations-v1.json`](content/pedagogy/irish-explanations-v1.json)
- [`content/pedagogy/README.md`](content/pedagogy/README.md)
- [`docs/DECISIONS.md`](docs/DECISIONS.md) D33

### Product runtime

- The representative Rockfleet chapter has complete Story and Learning paths on the
  shared county runtime.
- The shared activity shell, response state engine, recovery, memory handoff, review
  seeding, and phrase-family references are implemented.
- Mayo has a nine-chapter production draft. Offaly, Dublin, and Meath are bundled as
  review drafts and cannot award county completion while their gates remain open.
- The nationwide Personal Atlas foundation contains **126,712** place records;
  **100,738** have Irish forms. Only a small prioritized subset has authored teaching
  context and audio.

The latest full app and device verification predates the D32 content/audio additions.
Those additions now include runtime speech-catalog safeguards as well as resources.
The host currently reports no installed simulator runtime and CoreSimulator is
unavailable, so a fresh simulator and physical-device run is still required before
promotion.

### Verification at the current revision

- `python3 -B tools/structured_audio_authoring.py check` — passed.
- `python3 -B tools/structured_audio_authoring.py reconcile --scoreboard --json` —
  passed with **0 errors**, the counts above, and checksum-verified retired captures.
- `python3 -B -m unittest discover -s tools/tests` — **167/167 passed** on 2026-08-03.
- Swift parse checks passed for the speech runtime and catalog tests. The Xcode resource
  scan finds **1,062/1,062** expected MP3s with no missing, mismatched, or orphan
  resources.
- A generic-device Xcode build reached Swift compilation but could not complete asset
  catalog compilation because this host has no CoreSimulator runtime. iOS XCTest,
  playback, accessibility, appearance, and physical-device checks were therefore not
  rerun; this is an open verification gate, not a passing result.
- The complete nine-step Clew Bay UI walk and focused screenshot-capture test pass on
  an iPhone 17 Pro simulator after the recovered context/transition change. Direct
  inspection confirms the first task shows its *Farraige · sea* arrival cue without
  displacing its listening control or choices.
- Reconciliation of the original D32 worktrees is complete. Ten formerly dirty states
  are retained under `worktree-archive/*` tags; superseded, retired, and temporary
  material was not promoted into active source. Luna implementation tasks completed the
  pedagogy, name/place authoring, capture, anomaly-audit, ledger, runtime, and provenance
  work. A Sol review found no remaining actionable P1/P2 issue at revision `4ca6cca`.

### Completed in the latest coordinated cycle

- Authored and captured the D32 extension tranche: **14** historical name/place members,
  **7** story-transition recaps, **2** Sean/fada contrast lines, and **2** pedagogy
  lessons; drained **16** lines under payload `d32.harvest.extension.2026-08-03` with
  a **74**-credit aggregate checkpoint and full reconciliation.
- Deduplicated duplicate story records in `d32-county-harvest-uses.json` so emergency
  harvest registration resolves stable story identity.
- Added two narrative-pedagogy lessons and eight exact, repository-bound Irish examples.
- Authored nine story-linked Personal Atlas name/place subjects and captured 18 bounded
  payload lines with no failures or unresolved claims.
- Replaced the anomaly audit's slow per-file probing with batched inspection and metadata
  stratification; the cold run improved from about **37.4 s** to **10.0 s**, with cached
  runs near **0.01 s**.
- Repaired manifest membership, Xcode resources, aggregate credit accounting, exact
  source identity, retired-capture reconciliation, and runtime fail-closed speech lookup.
- Recorded nine post-hoc capture chronology warnings explicitly. Those manifests remain
  `chronology_unverified` and blocked from release until a human reviews the historical
  ledger sequence.

## Active implementation sequence

**Next priority: bulk Track A.** Tracks B–E stay ready, but do not open another provider
payload until Track A produces a large net-new unique-text slice. As of this revision,
**705/705** unique normalized texts are already registered and **700** are captured; a
full `prepare-harvest` dry-run over all families yields **0** new registrable lines.
Extension tranches that add county-bound variants of existing text will not scale credit
use. Target the D32 planning band of **3,000–5,000** utterances — roughly **2,300–4,300**
net-new unique lines remain — and run the avenues below **in parallel** where inputs are
independent.

### 1. Bulk Track A — parallel authoring targets (next session)

Each avenue must output complete v2 members (stable id, NFC Irish, English intent,
story/atlas binding, exercise consumer, provenance, risk flags). Count **net-new unique
normalized text**, not member count. Merge through the store, run `check`, then
`prepare-harvest` preflight before any emergency-harvest approval.

| # | Avenue | Primary inputs | Tool / owner | Counties / scope | Parallelism | Order-of-magnitude unique-text yield |
| --- | --- | --- | --- | --- | --- | --- |
| A1 | **Personal Atlas names and places** | `personal-atlas-subjects.json`, Logainm index, story slate anchors | [`tools/generate_personal_atlas_name_place_families.py`](tools/generate_personal_atlas_name_place_families.py) | All 32; expand beyond **80** pilot subjects | High — shard by county or subject batch | **400–1,600** (2 spoken forms per subject at 200–800 new subjects) |
| A2 | **Story dialogue and exercise roles** | County story packs, `d32-county-harvest-uses.json` | Manual family append + uses ledger; extend [`tools/generate_d32_county_families.py`](tools/generate_d32_county_families.py) role templates | All 32 stories | High — one stream per county | **300–1,000** (dialogue, listen-choose surrounds, story-specific lines beyond scaffold) |
| A3 | **Mutation, fada, and minimal-pair contrasts** | Atlas headwords, high-risk sampler strata | Pattern in [`tools/generate_d32_harvest_extension_tranche.py`](tools/generate_d32_harvest_extension_tranche.py); new contrast families per sense | Start Mayo + counties in risk sample; spread to all senses with mutation/fada exposure | High — shard by sense or contrast type | **100–400** |
| A4 | **Pedagogy-bound Irish examples** | [`content/pedagogy/irish-explanations-v1.json`](content/pedagogy/irish-explanations-v1.json) | [`tools/validate_pedagogy_corpus.py`](tools/validate_pedagogy_corpus.py); bind each example to an existing or new family member | Cross-county | High — shard by lesson | **50–200** (29 lines today; scale lessons with exact repository Irish) |
| A5 | **Evidence-led county expansion** | [`docs/COUNTY-STORY-SLATE.md`](docs/COUNTY-STORY-SLATE.md) | [`content/audio/authoring/d32-county-authoring-queue.md`](content/audio/authoring/d32-county-authoring-queue.md) queue **`queue-02-evidence-led-next`** | Cork, Galway, Kerry, Longford, Louth, Roscommon, Tipperary, Waterford | High — one county per stream | **200–600** |
| A6 | **Source-packet county expansion** | Story source packets, place forms, exercise shells | Same queue doc — **`queue-03-source-packet`** | Antrim, Armagh, Carlow, Cavan, Clare, Down, Fermanagh, Kildare, Kilkenny, Laois, Monaghan, Sligo, Westmeath, Wicklow | High — one county per stream after packet confirmed | **300–900** |
| A7 | **Sensitive county expansion** | Community/history review route | Same queue doc — **`queue-04-sensitive-review-first`** | Derry, Donegal, Leitrim, Limerick, Tyrone, Wexford | Limited — secure review route before volume | **TBD** (do not score-chase) |
| A8 | **Historical and story-slate proper names** | Story slate named figures and linked places | Extend `STORY_SLATE_SUBJECTS` in personal-atlas generator + ainm families | Per story anchor | Medium — overlaps A1; dedupe by normalized text | **50–150** incremental if not merged into A1 |

**Not bulk Track A (quick maintenance only):** re-approve **7** cancelled batch lines
(~300 estimated credits); retire or replace **2** Corca Dhuibhne quarantine members.

**Track A preflight gate (before Track B):** `prepare-harvest` over the merged slice
must report **≥500 net-new unique lines** (or **≥5,000** estimated credits) unless an
explicit smaller payload is delegated. Size `payload_credit_limit` to the preflight
estimate, not a nominal cap.

**Parallel merge rules:** register families in sorted store order; never fork competing
plans; one `check` + one reconcile per merged slice; deduplication is by normalized text
+ locked voice — prefer new sentences over county variants of captured text.

Canonical queue partition: [`content/audio/authoring/d32-county-authoring-queue.md`](content/audio/authoring/d32-county-authoring-queue.md).

### 2. Normalize, deduplicate, and build resumable manifests

Track B canonicalizes NFC text, detects exact reuse and intent conflicts, assigns
stable line identities, and partitions work by county, story, sense, and risk. Each
tranche must pass authoring validation and a credit preflight before provider calls.

### 3. Drain manifests continuously with explicit credit checkpoints

Track C uses the locked Irish Cultural Guide voice and model from D31. Run capture in
bounded payloads, checkpoint provider usage between payloads, preserve a regeneration
reserve, and stop at the agreed credit floor or subscription expiry. A successful
payload must end with registered results, bundle checksums, and zero unresolved claims.

The D31 **3,000–5,000 utterance** range remains a planning reference, not a D32 cap.
Available credits, metadata quality, and plausible future use determine the emergency
harvest ceiling.

### 4. Replace exhaustive listening with anomaly detection and quarantine

After each tranche, Track D regenerates the deterministic sample and runs technical
checks across the entire inventory. It should quarantine:

- missing, corrupt, clipped, unusually short/long, silent, or level-outlier audio;
- conflicting meanings for identical Irish text;
- names, places, mutations, fadas, and launch lines selected by the risk sampler;
- material that diverges materially from a lawfully supplied reference set.

Mechanical agreement is evidence for prioritization, not linguistic correctness.
Reference comparisons remain disabled until a lawful local ABAIR reference corpus and
its provenance are available.

### 5. Reconcile every tranche before starting the next

Track E updates inventory, checksums, batch state, recovery state, Atlas/pedagogy
coverage, and the credit ledger. Do not start a new provider payload while the previous
one has unresolved claims, missing checksums, or unregistered files.

### 6. Freeze the harvest, select, and prove one learner-facing slice

When the credit window closes, stop corpus expansion and rank the captured material by
story relevance, reuse, pedagogical purpose, risk, and mechanical audio quality. Then:

1. correct and gate the selected subset;
2. connect one production Mayo Learning slice to reviewed phrase-family and narrative
   pedagogy material;
3. verify Story and Learning modes, progress preservation, memory events, collection
   handoff, accessibility, audio playback, and offline behavior;
4. inspect the complete slice on simulator and physical device;
5. spread the pattern only if the representative slice passes without private
   family-specific exceptions.

## Open gates and unblock conditions

| Gate | Current state | Unblock condition |
| --- | --- | --- |
| Irish authoring | Provisional at scale | Selected records corrected and approved for their stated intent |
| Audio QA | Mechanically checked, human gate open | Qualified Irish speaker approves the selected learner-facing subset and recorded scope |
| Pedagogy | 21-lesson draft / 148 unique texts; review open | Pedagogue and Irish-language review the exact sidecar revision |
| ABAIR comparison | Adapter implemented, no references loaded | Lawful local references with permission, provenance, and checksums |
| Mayo production | Nine-chapter draft, representative runtime proof | History, pedagogy, language, audio, rights, accessibility, and device gates close |
| Offaly | Review draft | Medieval history and art/inscription review plus shared launch gates |
| Dublin | Review draft | Numismatic object/transcription review plus shared launch gates |
| Meath | Review draft | Grant source, castle phasing, and conquest-sensitivity review plus shared launch gates |
| External learner round | Blocked | All four counties pass the internal tester-readiness gate |
| Public release | Blocked | Product, specialist, rights, accessibility, device, operational, and commercial gates close |

## Known risks

- Generating faster than the corpus can be attributed, deduplicated, and assigned a
  plausible use would convert prepaid credits into unusable inventory.
- Acoustic similarity can catch anomalies but cannot establish grammatical,
  dialectal, semantic, or pedagogical correctness.
- Names and places are unusually sensitive to dialect, local convention, historical
  form, and anglicized/Irish-form ambiguity.
- Nine capture manifests have explicit post-hoc chronology warnings. Their bytes and
  checksums are auditable, but ledger sequence cannot be treated as contemporaneous
  provider evidence until reviewed.
- The Personal Atlas foundation is broad, but authored context and audio coverage are
  still shallow relative to its 126,712 place records.
- Bespoke reviewed story and pedagogy production—not TTS generation—is the long-term
  cost and scheduling constraint.

## Historical context

- **Phase 1:** built and tested the first Gráinne vertical slice; narrative pull was
  promising, but the evidence record is incomplete.
- **Phase 2:** established the story, evidence, Atlas, collection, offline, progress,
  and review foundations.
- **Phase 3:** replaced thin county previews with separate Story and Learning modes,
  rebuilt the shared activity system, proved the Rockfleet representative loop, and
  produced substantial review drafts for Mayo, Offaly, Dublin, and Meath.
- **D30–D31:** proved phrase-family learning patterns, added controlled authoring and
  resumable audio generation, and locked the initial Irish voice/model contract.
- **D32–D33:** expanded provisional authoring and audio across all 32 counties, added
  mechanistic risk sampling and offline reference comparison, began Personal Atlas
  name/place audio, and created the first reviewable narrative-pedagogy sidecar.

Durable product rules and decisions remain in [`PRODUCT.md`](PRODUCT.md) and
[`docs/DECISIONS.md`](docs/DECISIONS.md). Launch strategy and unresolved strategic
questions remain in [`docs/STRATEGY.md`](docs/STRATEGY.md).
