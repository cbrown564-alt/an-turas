# STATUS

*Project: An Turas (working title) — an iOS app for learning Irish through the real
stories and places of Ireland. Updated 2026-08-03 (bulk Track A avenue A3 authored).*

## Current outcome

An Turas has a verified representative Mayo Story-and-Learning loop, shared learning
runtime, four in-app county review packs, a nationwide Personal Atlas foundation, and
a controlled Irish authoring/audio pipeline.

The immediate phase is the **D32 emergency Irish audio harvest**. The first all-county
tranche and a story-linked Personal Atlas tranche are complete, but the harvest is not:
**140,946 ElevenLabs credits remained at the last observed provider check**. The latest
tranche used **254** aggregate credits for **18** successful captures. The provider does
not expose a trustworthy per-batch credit allocation, so the ledger records that delta
only at the aggregate checkpoint. Provisional generation may continue during the
subscription window. Capture does not imply linguistic approval or learner release.

The product is implemented as a substantial prototype. It has not been validated for
learning outcomes or promoted for public release.

## Current evidence

### Irish corpus and audio

- **714** phrase families, **1,609** authored members, **1,607** complete members, and
  **839** unique normalized texts across all **32** counties. The two incomplete members
  are the deliberately retired Corca Dhuibhne lines described below.
- Bulk Track A avenue **A3** (mutation / fada / minimal-pair contrasts) authored
  **74** contrast families and **148** net-new unique listening texts via
  [`tools/generate_d32_contrast_families.py`](tools/generate_d32_contrast_families.py)
  and [`content/audio/authoring/d32-contrast-catalog-a3.json`](content/audio/authoring/d32-contrast-catalog-a3.json).
  Mayo leads with **52** members; coverage then spreads across risk-sample counties.
  Contrast types in this pass: mutation **82**, fada **56**, fada minimal pair **6**,
  other minimal pair **4**. Authoring only — no provider capture.
- **692** registered audio lines: **682** approved, **684** provider successes, **2**
  retired semantic quarantines, **9** cancelled, **0** failed, and **0** actively
  claimed. There is no remaining resumable or manual-recovery work.
- **1,046** bundled MP3s: **684** source-labelled v2 captures and **362** legacy/runtime
  clips.
- **1,046/1,046** checksums verify. There are no missing, mismatched, or orphan files.
- The technical anomaly audit inspected all **1,046** clips: **1,036** pass, **10** need
  targeted listening review, and **0** require technical quarantine. Two additional
  Corca Dhuibhne captures are retained byte-for-byte for audit but are semantically
  retired, dynamically excluded, failed for learner QA, and unavailable through both
  text and named-asset runtime paths.
- The Personal Atlas tranche contains **80** subjects—**50 names** and **30 places**—
  with two spoken forms each and **160** newly captured clips.
- The latest story-linked authoring tranche adds **9** name/place subjects and **18**
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

- The authoring-only pedagogy sidecar contains **7** narrative lessons and **26**
  English-framed lines around exact repository Irish examples.
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
- `python3 -B -m unittest discover -s tools/tests` — **167/167 passed** on 2026-08-02.
- Swift parse checks passed for the speech runtime and catalog tests. The Xcode resource
  scan finds **1,046/1,046** expected MP3s with no missing, mismatched, or orphan
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

### 1. Expand high-value authoring banks while credits remain

Continue Track A in independently appendable tranches. Prioritize:

1. Irish personal names, surnames, historical names, and high-value place names already
   represented in the Personal Atlas or county stories;
2. story openings, recaps, transitions, and reusable dialogue roles;
3. phrase-family contrasts that exercise mutations, inflections, fadas, and likely
   pronunciation failures — A3 authored slice complete (**148** unique texts; see
   corpus evidence above);
4. narrative pedagogy examples with a named grammar or pronunciation purpose.

Every member must retain a stable ID, exact Irish text, English intent, source or
invented status, risk flags, and a plausible story/place/learning use. D32 permits
provisional capture; it does not permit untracked orphan text.

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
| Pedagogy | Seven-lesson draft only | Pedagogue and Irish-language review the exact sidecar revision |
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
