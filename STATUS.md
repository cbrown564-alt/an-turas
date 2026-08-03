# STATUS

*Project: An Turas (working title) — an iOS app for learning Irish through the real
stories and places of Ireland. Updated 2026-08-03 (Track A bulk merge on
`track-a/bulk-integration`).*

## Current outcome

An Turas has a verified representative Mayo Story-and-Learning loop, shared learning
runtime, four in-app county review packs, a nationwide Personal Atlas foundation, and
a controlled Irish authoring/audio pipeline.

The immediate phase is the **D32 emergency Irish audio harvest**. Bulk Track A avenues
**A1–A8** are authored and merged on `track-a/bulk-integration`: about **2,820**
net-new unique normalized texts sit above the prior **707** batch-registered set
(authored corpus **3,527** unique / **4,316** members / **714** families). The
preflight gate (≥500 net-new unique) is cleared for Track B. Do not open a provider
payload until `prepare-harvest` writes resumable manifests sized to a credit
checkpoint. **140,872** ElevenLabs credits remained at the last observed provider
check. Capture does not imply linguistic approval or learner release.

The product is implemented as a substantial prototype. It has not been validated for
learning outcomes or promoted for public release.

## Current evidence

### Irish corpus and audio

- **714** phrase families, **4,316** authored members (**4,314** with
  `states.authoring.status = complete`), and **3,527** unique normalized texts across
  all **32** counties after the Track A bulk merge. About **2,820** of those unique
  texts are absent from the prior batch registry (**707** registered unique texts).
  The two incomplete members remain the deliberately retired Corca Dhuibhne lines.
- **708** registered audio lines: **698** approved, **700** provider successes, **2**
  retired semantic quarantines, **9** cancelled, **0** failed, and **0** actively
  claimed. Track B has not yet registered the Track A bulk slice.
- **1,062** bundled MP3s: **700** source-labelled v2 captures and **362** legacy/runtime
  clips.
- **1,062/1,062** checksums verify. There are no missing, mismatched, or orphan files.
- The technical anomaly audit inspected all **1,046** clips: **1,036** pass, **10** need
  targeted listening review, and **0** require technical quarantine. Two additional
  Corca Dhuibhne captures are retained byte-for-byte for audit but are semantically
  retired, dynamically excluded, failed for learner QA, and unavailable through both
  text and named-asset runtime paths.
- The learner Personal Atlas pack remains **80** subjects (**50** names / **30** places)
  with **160** captured clips. A1 adds **318** authoring-only bulk subjects (**636**
  unique texts) without promoting them into the Swift pilot pack.
- A8 expands `STORY_SLATE_SUBJECTS` **9 → 47** (**76** incremental unique texts), kept
  id-disjoint from A1 (`story.place.*` / `historical.name.*`).
- The extension tranche (pre-merge base) added historical name/place lines, story
  transitions, Sean/fada contrast lines, and pedagogy examples; **16** lines were
  registered, drained, and reconciled in payload `d32.harvest.extension.2026-08-03`.
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

- `python3 -B tools/structured_audio_authoring.py check` — passed on the merged Track A
  store (**714** family documents).
- Net-new unique-text preflight (authored NFC texts minus batch-registered texts):
  **≈2,820** (≥500 Track A → Track B gate).
- Focused Track A unit tests green after merge (personal-atlas generator, pedagogy
  corpus, contrast families, evidence-led tranche, source-packet expansion, story
  dialogue). Full `unittest discover` and `reconcile --scoreboard` not re-run on this
  host for the bulk merge; rerun before provider approval.
- Prior revision: `reconcile --scoreboard` passed with checksum-verified retired
  captures; `unittest discover` was **167/167** before the bulk merge.
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

- Merged parallel Track A branches onto `track-a/bulk-integration` (extension WIP base
  + A1–A8). Uses ledger kept at **32** stories / **4,305** exercises; store indexes
  **714** families. `structured_audio_authoring.py check` passed.
- **A1:** 318 bulk Personal Atlas subjects / **636** unique texts (pilot pack still 80).
- **A2:** **904** story-dialogue / exercise-role unique texts across 32 counties.
- **A3:** 74 contrast families / **148** unique listening texts.
- **A4:** pedagogy sidecar **21** lessons / **203** lines / **148** unique examples.
- **A5:** queue-02 evidence-led — **520** unique texts across 8 counties.
- **A6:** queue-03 source-packet — **560** unique texts across 14 counties (packets
  confirmed; Monaghan/Kilkenny bounded).
- **A7:** review-route register only; **0** new unique texts; volume blocked.
- **A8:** story-slate subjects **9 → 47** / **76** incremental unique texts.
- Authored and captured the D32 extension tranche before the bulk merge; drained **16**
  lines under payload `d32.harvest.extension.2026-08-03`.

## Active implementation sequence

**Next priority: Track B — normalize, dedupe, and build resumable manifests** for the
merged Track A slice. Do not call the provider until manifests pass credit preflight.
Estimated headroom toward the D32 **3,000–5,000** planning band: about **2,820**
net-new unique texts are authored and not yet batch-registered.

### 1. Bulk Track A — parallel authoring targets (merged)

Avenues A1–A8 landed on `track-a/bulk-integration`. Count remains **net-new unique
normalized text**. Merge rules applied: union by member/exercise id, keep deduped
story records, sorted store family index, one `check` on the merged slice.

| # | Avenue | Merged result (unique-text order of magnitude) | Branch |
| --- | --- | --- | --- |
| A1 | Personal Atlas names and places | **636** (318 bulk subjects × 2) | `bulk-a1-personal-atlas` |
| A2 | Story dialogue and exercise roles | **904** | `track-a/a2-story-dialogue` |
| A3 | Mutation, fada, and minimal-pair contrasts | **148** | `bulk-a3-mutation-fada-contrasts` |
| A4 | Pedagogy-bound Irish examples | **148** unique examples (21 lessons) | `track-a/a4-pedagogy-examples` |
| A5 | Evidence-led county expansion | **520** | `track-a/a5-evidence-led-next` |
| A6 | Source-packet county expansion | **560** | `track-a/a6-source-packet` |
| A7 | Sensitive county expansion | **0** (review route only) | `track-a/a7-sensitive-review-first` |
| A8 | Historical and story-slate proper names | **76** | `track-a/a8-story-slate-names` |

**Not bulk Track A (quick maintenance only):** re-approve **7** cancelled batch lines
(~300 estimated credits); retire or replace **2** Corca Dhuibhne quarantine members.

**Track A preflight gate:** cleared on unique-text inventory (**≈2,820** net-new vs
batch registry). Next: run `prepare-harvest` over the merged inputs, size
`payload_credit_limit` to that estimate, then Track C drain with checkpoints.

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
