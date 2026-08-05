# STATUS

*Project: An Turas (working title) — an iOS app for learning Irish through the real
stories and places of Ireland. Updated 2026-08-05 (D32 harvest cycle 2 Track C
closed; Track D/E next; prior payload `d32.harvest.track-b.2026-08-03` remains
reconciled).*

## Current outcome

An Turas has a verified representative Mayo Story-and-Learning loop, shared learning
runtime, four in-app county review packs, a nationwide Personal Atlas foundation, and
a controlled Irish authoring/audio pipeline.

The immediate phase is the **D32 emergency Irish audio harvest**, which continues while
prepaid ElevenLabs credits remain (D32). Cycle 1 payload
`d32.harvest.track-b.2026-08-03` is closed and reconciled. Cycle 2 payload
`d32.harvest.track-b.2026-08-05` Track C is closed: **2,744 / 2,744** approved lines
succeeded across **391** manifests (A2 dialogue depth 14/14 all counties; partition
ids remapped to free `.part-0N` suffixes). Observed spend for the payload is about
**47,495** credits (baseline **138,576** → **186,071** used; **50,028** remaining),
under the authorized **90,000** limit. Next: Track D anomaly sampling and Track E
reconcile. Capture still does not imply linguistic approval or learner release.

The product is implemented as a substantial prototype. It has not been validated for
learning outcomes or promoted for public release.

## Current evidence

### Irish corpus and audio

- **714** phrase families, **4,316** authored members (**4,314** with
  `states.authoring.status = complete`), and **3,527** unique normalized texts across
  all **32** counties after the Track A bulk merge. About **2,820** of those unique
  texts are absent from the prior batch registry (**707** registered unique texts).
  The two incomplete members remain the deliberately retired Corca Dhuibhne lines.
- Registered batch scoreboard after Track C: **3,528** registered lines (**3,516**
  approved, **3,518** provider successes, **2** retired semantic quarantines, **11**
  cancelled, **0** failed / claimed). Store `batch_documents` remains the Track B
  harvest set plus prior batches.
- **3,880** bundled runtime MP3s / manifest lines. Checksums verify for all **3,880**
  runtime records and bundle files; there are no missing, mismatched, or orphan
  runtime files at the filesystem/manifest layer.
- Post-capture Track D technical anomaly audit inspected all **3,880** clips:
  **3,865** pass, **15** need targeted listening review (duration/level distribution
  outliers), and **0** require technical quarantine. Decoder was available. Two
  additional Corca Dhuibhne captures remain retained byte-for-byte for audit but are
  semantically retired, dynamically excluded, failed for learner QA, and unavailable
  through both text and named-asset runtime paths.
- Track E regenerated `ios/AnTuras.xcodeproj` from `ios/project.yml`; all **3,880**
  MP3s are in the Xcode Audio group. Read-only reconcile is **non-blocking** (**0**
  errors; **57** warnings for known chronology, archive/provenance drift, inventory
  legacy gaps, pedagogy drift, and the **15** technical review outliers).
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
- [`content/audio/authoring/d32-track-d-post-capture-report.json`](content/audio/authoring/d32-track-d-post-capture-report.json)
- [`content/audio/authoring/d32-track-e-reconcile-report.json`](content/audio/authoring/d32-track-e-reconcile-report.json)
- [`content/audio/README.md`](content/audio/README.md)

### Mechanistic review

- Deterministic disjoint sampling now selects **86** clips across **11** risk strata
  (**8** per stratum quota; `launch_lines` remains short at **6**). Prior
  2026-08-02 sample (**78**) is superseded for post-Track-C review planning.
- The offline ABAIR comparator records provenance and checksums and compares duration,
  level, spectral shape, zero-crossing rate, and coarse envelopes against locally
  supplied reference clips.
- No ABAIR reference corpus has been supplied or compared yet. The comparator does not
  scrape ABAIR, decide pronunciation correctness, or close a release gate.

Canonical records:

- [`content/audio/authoring/sampling/d32-risk-stratification-2026-08-04.json`](content/audio/authoring/sampling/d32-risk-stratification-2026-08-04.json)
- [`content/audio/authoring/sampling/d32-risk-stratification-2026-08-02.json`](content/audio/authoring/sampling/d32-risk-stratification-2026-08-02.json) (superseded sample)
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

- Track E (2026-08-04): `xcodegen generate` synced Audio resources; reconcile
  **blocking=false**; authoring `check` valid; scoreboard remaining resumable work
  **0**. Report:
  [`content/audio/authoring/d32-track-e-reconcile-report.json`](content/audio/authoring/d32-track-e-reconcile-report.json).
- Track D (2026-08-04): risk sample regenerated (**86** clips);
  `reconcile --json` inspected **3,880** clips (**3,865** pass / **15** review /
  **0** quarantine); review-queue audit still reports **17** capture blockers /
  **141** review-before-release / **0** learner-release-eligible. Report:
  [`content/audio/authoring/d32-track-d-post-capture-report.json`](content/audio/authoring/d32-track-d-post-capture-report.json).
- Track B `prepare-harvest` over all **32** county `authoring-v2` trees:
  **2,820** new draft lines / **557** batches / **705** skipped as already registered /
  **244** duplicate-text merges / **2** blocked (Corca Dhuibhne). Summary:
  [`content/audio/authoring/d32-track-b-prepare-harvest-summary.json`](content/audio/authoring/d32-track-b-prepare-harvest-summary.json).
- Estimated Track B spend **~75,087** credits vs **140,872** last-known remaining
  (headroom positive; size `payload_credit_limit` per drained payload, not the full
  band at once). Observed Track C/E ledger spend for this payload is **42,891** credits
  (baseline **95,461** → **138,352** used; **97,747** remaining).
- Track C capture for this payload is complete; manifests are no longer draft/provider-
  blocked for the drained lines.
- Prior: `structured_audio_authoring.py check` passed on the merged Track A store
  (**714** families).
- Runtime filesystem/manifest checksums: **3,880/3,880**. Xcode Audio group regenerated
  via `xcodegen`; `xcode_audio_resource_missing` cleared.
- Track E scoreboard: **0** remaining resumable work; authoring `check` valid;
  report [`d32-track-e-reconcile-report.json`](content/audio/authoring/d32-track-e-reconcile-report.json).
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

- Track E reconcile: regenerated Xcode Audio resources; reconcile **non-blocking**;
  checksums **3,880/3,880**; remaining resumable work **0**; credit ledger
  **95,461 → 138,352** used (**42,891** spend / **75,000** limit). Report:
  `d32-track-e-reconcile-report.json`.
- Track D post-capture: regenerated
  `sampling/d32-risk-stratification-2026-08-04.json` (**86** sample clips); ran full
  technical anomaly reconcile across **3,880** clips (**15** review-required
  duration/level outliers, **0** quarantine); re-ran mechanical review-queue audit.
  Report: `d32-track-d-post-capture-report.json`.
- Track C drained payload `d32.harvest.track-b.2026-08-03` (**2,818** successes).
- Track B `prepare-harvest` registered **557** draft manifests (**2,820** lines;
  **~75,087** estimated credits); remapped **6** partition collisions to `.part-02`.
  Reports: `d32-track-b-prepare-harvest-summary.json` /
  `d32-track-b-prepare-harvest-report.json`.
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

**Current priority: D32 harvest cycle 2 Track D → Track E** for closed Track C
payload `d32.harvest.track-b.2026-08-05` (**2,744** captured lines / **391**
batches / ~**47,495** credits / **90,000** limit). Approval:
[`d32-cycle2-track-c-approve-prepared-report.json`](content/audio/authoring/d32-cycle2-track-c-approve-prepared-report.json).
Prepare summary:
[`d32-cycle2-track-b-prepare-harvest-summary.json`](content/audio/authoring/d32-cycle2-track-b-prepare-harvest-summary.json).
Approval identity `user.d32.track-c.2026-08-05`; claim owner
`codex.track-c.d32-cycle2-drain`. Cycle 1 Track E report remains closed:
[`d32-track-e-reconcile-report.json`](content/audio/authoring/d32-track-e-reconcile-report.json).

**Resume / re-drain tooling (committed):** portable `pwsh` at
`~/.local/powershell/pwsh`. Detached launcher:

```powershell
~/.local/powershell/pwsh -NoProfile -File tools/start-track-c-drain-detached.ps1
```

Worker: [`tools/run-track-c-drain.ps1`](tools/run-track-c-drain.ps1). Python loop:
[`tools/run_track_c_batch_loop.py`](tools/run_track_c_batch_loop.py) (retries 429 /
connection resets; requires `ANTURAS_CANONICAL_ALLOW_NON_MAIN=1` on this branch).
Approval report:
[`d32-track-c-approve-prepared-report.json`](content/audio/authoring/d32-track-c-approve-prepared-report.json).
Runtime logs (ephemeral): `/tmp/track-c-drain/`.

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

**Track C gate:** closed for this payload — **2,818** lines captured.
**Track D gate:** closed for mechanical sampling/anomaly screen on this payload
(**3,880** inspected; **15** listening-review outliers; **0** technical quarantine).
**Track E gate:** closed — Xcode Audio regenerated, reconcile non-blocking, checksums
complete, resumable work zero, credit ledger recorded.

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
