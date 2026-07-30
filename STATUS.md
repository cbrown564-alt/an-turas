# STATUS

*Project: An Turas (working title) — iOS app teaching Irish through history, culture,
and visual narrative. English → Irish only. Updated 2026-07-30 (Shell cluster
ACCEPT at e4c6a8b; freeze representative Mayo run next).*

## Where we are

**Phase 3 — Story and Learning rebuild.** The four-county road is implemented and was
simulator-verified on 14 July, but it is not ready for another external tester round.
Feedback reported on 15 July found Mayo worthwhile but too short and found Offaly,
Dublin, and Meath too light to count as substantial stories. The learning path had
also regressed toward repetitive listen-and-pick exercises. Repository inspection
supports that diagnosis: each new county is a twelve-beat editorial preview with four
required interactions for 20 provisional words, and completion schedules words whose
full learning lifecycle was never authored.

**Current implemented evidence:** the island route, dossiers, evidence views,
collection, learner-made objects, review scheduling, TEG summary, An Féilire, offline
pack installation, durable progress across four counties, and the rebuilt Rockfleet
representative chapter. The complete 24 July iPhone 17 Pro Max simulator suite passes
36 unit and 16 UI tests, and all 36 Python content/tooling tests pass. Those checks
verify the working implementation; they do not validate the broader Mayo narrative,
learning outcomes, specialist review, audio, or rights after the 15 July product
reset.

**Current product decision:** D21 defines one county page sequence filtered into Story
and Learning modes. D26 now defines a familiar one-screen activity system for the
Learning path: stable task anatomy and response lifecycle, with story, Irish, place,
evidence, audio, feedback, and the visual system carrying the product's distinction.
Story mode carries the complete account and opens the next county; only Learning mode
turns the county gold and schedules its words. Speaking remains ungraded
record-and-compare.

**Current target:** rebuild-plan phases 0–3 are complete. D25 makes the shared
learning-mechanics foundation the active sprint before more chapter authoring, county
expansion, or production-pack migration. Two complementary 30 July inputs now exist:
the expanded 48-activity reference review that led to D26, and three working iOS
interaction studies—Sound Match, Sentence Flow, and Coast Placement—using the same
narrow Clew Bay fixture. The studies are implemented and pass their focused 3-unit /
5-UI simulator suite, including complete repair loops, audio fallback, both
appearances, largest Dynamic Type, and reduced motion. They remain disposable and
isolated from the shared county runtime.

The next proof is one representative Mayo Learning-mode run through D26's selected
one-screen shell. Before extracting the shared runtime, that proof must explicitly
decide which response, correction, scaffold-removal, motion, and spatial details from
the iOS studies improve the selected activity families. This combines the two bodies
of work without reopening three candidate architectures. The Phase 4 Mayo and Phase 5
launch-county review drafts remain at their recorded gate states.

**24 July rebuild update:** Phase 0's product contract is complete. The Phase
1 version-two page-pack model, deterministic beat-to-page migration, dual-mode
projection and separate completion state are implemented and verified for the
representative Rockfleet slice. Phase 2's shared exercise shell covers all twelve
mechanic families, including explicit correction, fada-aware typing, bundled audio,
ephemeral speaking, denied-microphone recovery and the internal failure-state
gallery. The Phase 3 Rockfleet proof now contains ten Story pages with ten authored
compositions—landscape, tide, route, language, relationships, system, archive,
evidence boundary, pressure and consequence—plus an eighteen-page Learning path.
The complete iPhone 17 Pro Max simulator scheme passes **52 tests**, and all **36 Python
content/tooling tests** pass. Direct simulator inspection covers light and dark
appearances, accessibility text reflow, Increased Contrast and Reduce Motion. Both
full paths now have end-to-end UI coverage, including the keyboard fada toolbar and
delayed retrieval. County routes use version-two packs; the duplicate legacy Gráinne
renderer and embedded launch-county copy have been removed.

The latest signed app builds, installs and launches on the physical iPhone 15 Pro Max.
Three on-device UI checks pass with no failures: the complete ten-page Story path in
dark appearance, the complete eighteen-page Learning path in light appearance, and
the mode opening at the largest accessibility text size. The Learning walkthrough
exercises bundled audio, matching, sentence construction, the keyboard fada toolbar,
denied-microphone recovery, delayed retrieval, and completion. Direct device
screenshots also verify the coastal opening and following tide diagram. No
device-specific defect was found.

This closes the rebuild plan's Phase 3 representative exit criterion. It verifies the
implemented Rockfleet pattern; it does not validate learning outcomes or clear the
broader Mayo and four-county work in phases 4–6 for another external tester round.

**24 July Phase 4 authoring update:** the nine-chapter production storyboard is
approved under D23, with every open choice D-A–D-F resolved as recommended. The
offline county-pack validator now mirrors the Swift runtime rules and adds complete
20-word lifecycle and lexeme-contract checks. The non-bundled revision-6 pre-clearance
draft now contains all nine chapters and 100 pages, including 38 exercises across all
12 families. Its estimated Story path is 86.2 minutes; all 20 words have one
introduction and a complete ordered lifecycle. Rockfleet introduces only *caisleán*
and carries eight exercises. The July historical review's reversible fixes are
applied: C02 now surfaces, C04 has a candidate Carew/SP 12 trail but stays Story-only,
and mismatched evidence statuses and stale prototype copy are corrected. The draft
passes the validator with `completeCounty` scope and learning-quality enforcement
enabled; all **36 Python content/tooling tests** pass. Twenty referenced audio
resources are accurately marked unbundled. Historian re-clearance for Chapters 2 and
4 and C04, pedagogue review, native-speaker audio QA, and Rockfleet imagery rights
remain open external gates, so the draft has not replaced the bundled representative
chapter. D24 allows a newly named historian to close `history.expanded`; the review
must identify its revision and scope. C04 confirmation may be supplied separately by
an archival specialist, but both dispositions are required to close the gate. D24
uses evidence-based reviewer qualification: relevant work and source competence
rather than academic title or institutional affiliation. Paid review is allowed with
internal disclosure, but a contributor cannot solely approve material they authored;
overlap requires a second qualified independent disposition. With consent, public
provenance may show reviewer name, scope, and completion date; private operational and
conflict records remain internal. A reviewer who declines public naming may still
close the gate when the internal record is complete; public provenance then shows
qualified role, scope, and date. Meaning-bearing historical edits after approval
reopen only the affected disposition; non-semantic production changes do not.
Historical approval has no calendar expiry, but material new evidence, scholarship,
or a credible challenge reopens the affected scope.
Qualified-reviewer disagreement keeps the affected disposition open until conservative
shared wording or a third qualified disposition resolves it; the owner cannot promote
an unresolved dispute as settled fact.

**24 July Phase 5 authoring update:** the working Mayo pattern has been applied to
Offaly, Dublin, and Meath as three in-app pre-clearance review packs. Each has six
variable-length chapters, 68 pages, a 49.4-minute estimated Story path, a causally
complete Learning projection, 30 exercises across all 12 families, and one complete
ordered lifecycle for each of its 20 provisional headwords. The exercise compositions
follow their objects: cross and inscription attention in Offaly, coin handling and
legend reading in Dublin, and possession, grant, site sequence and fabric inspection
in Meath. All three pass the strict county validator and their generator output is
covered by regression tests; all **38 Python content/tooling tests** pass. A temporary
iPhone 17 Pro substitution build first decoded and rendered every draft. The promoted
bundle now passes all **36 Swift unit tests** and the **16 UI tests**: the initial full
run exposed only two stale Rockfleet completion-copy expectations, and both complete
Rockfleet walkers passed after its approved wording was restored. Offaly's review
opening and retry/correct/recovery path pass directly; all three review openings were
then inspected on the simulator at accessibility text size. Their source briefs name
the expanded chapter maps, official starting sources and open gates.

This is implemented authoring structure promoted for in-app review, not specialist
validation or public release.
Offaly still needs medieval history and art/inscription review; Dublin needs a
numismatist to select and transcribe the learner-facing penny; Meath needs the grant
copy pinned, castle phasing reviewed, and conquest-sensitivity review. All three also
need pedagogy, native-speaker audio QA, rights, full accessibility and device checks.
The app labels all three **Review draft** and prevents them from awarding county gold,
made objects or scheduled words while any review gate remains open.

**25 July media correction:** Offaly, Dublin and Meath now each connect two
representative county pages to their bundled muted video loop and explicit still
keyframe. The shared renderer loops only while the app is active and shows the still
for Reduce Motion or unavailable playback. Swift and Python validators now accept the
same image/video visual contract and require every video to name an image fallback.
Direct iPhone 17 Pro simulator inspection confirmed the Offaly opening composition,
advancing video frames and identical still frames with Reduce Motion enabled. All
**37 Swift unit tests**, **17 UI tests** and **40 Python content/tooling tests** pass.

**Tester gate:** no external learner build until all four counties pass the narrative,
20-word lifecycle, exercise-distribution, specialist review, native-speaker audio,
rights, accessibility, physical-device, migration, offline, and automated checks in
`docs/STORY-LEARNING-REBUILD-PLAN.md`. The prior Mayo test remains owner-reported
evidence with no session record in the repository; it does not validate the expanded
story or new Learning mode.

## Learning activity inventory (D27)

Canonical taxonomy: one **activity anatomy**, ten **response families**, five
**containers**, and three **authored uses** (`ordering`, `audioPrompted`,
`delayedRecall`). Owners: `PRODUCT.md`, `docs/DECISIONS.md` D27, `CONTEXT.md`,
`docs/STORY-LEARNING-REBUILD-PLAN.md`. Legacy Chapter 1–3 inline formats and
`DRILL.md` scheduled-review projections remain parallel until migrated onto the shared
county runtime.

### Response families — implementation checklist

| # | D27 family | `CountyExerciseFamily` | Surface | Authored (4 packs) | Contract met? |
|---|---|---|---|---|---|
| 1 | Listen and choose | `listenChoose` | ✓ | ✓ | **Yes** — Shell ACCEPT (F1); response answerable from cold open; D27 repair window before struggle chrome |
| 2 | Sentence construction | `sentenceConstruction` | ✓ | ✓ | Partial — Check in bottom bar (nil-action regression fixed); stable tile bank; not Shell-scored this pass |
| 3 | Free typed production | `freeTyping` | ✓ | ✓ | Partial — two-voice/fada polish deferred until family cluster passes |
| 4 | Fill-in-the-blank | `fillGap` | ✓ | ✓ | Partial — shares choice surface with read-respond |
| 5 | Matching | `matching` | ✓ | ✓ | **Yes** — Shell ACCEPT (F5); wrong pair = on-target note + next-tap unlock; thumb-native board; ≤4 pairs enforced |
| 6 | Read or listen and respond | `readRespond` | ✓ | ✓ (read only) | Partial — no listen variant yet |
| 7 | Record and compare | `recordCompare` | ✓ | ✓ | **Yes** — Shell ACCEPT (F7); Record/Stop owns ink until compare; quiet escape unless mic denied |
| 8 | Grammar discovery | `grammarDiscovery` | ✓ | ✓ | **No** — one MC step, not progressive reveal → produce → rule |
| 9 | Picture or map selection | — | ✗ | ✗ | Not started (migration group 1) |
| 10 | Listen and type | — | ✗ | ✗ | Not started (migration group 2); `audioPrompted` construction is partial overlap only |

### Containers — implementation checklist

| # | D27 container | In enum / surface | Authored | Contract met? |
|---|---|---|---|---|
| 1 | Conversation | `conversation` / thin MC list | ✓ | **No** — no turn graph, branching, or resume |
| 2 | Radio-style listening | — | ✗ | Not started (migration group 3) |
| 3 | Contextual mistake review | — | ✗ | Not started (migration group 4); `delayedRecall` is a typing use only |
| 4 | **Words you carry** practice | legacy `VocabDeckView` | chapter 1 | **No** — not on shared county shell |
| 5 | Completion | `CountyStoryExperienceView` | ✓ | Partial — no capability summary or collection handoff per D27 |

### Authored uses (configuration, not families)

| Use | Parent family | In packs | Runtime |
|---|---|---|---|
| `ordering` | `sentenceConstruction` | ✓ all four | ✓ tile order with `\|` separator |
| `audioPrompted` | `sentenceConstruction` | ✓ all four | ✓ bundled audio before build |
| `delayedRecall` | `freeTyping` | ✓ all four | ✓ later-page retrieval; not yet wired to mistake-review container |

### Legacy parallel systems (not yet on county runtime)

| System | Formats / entry | Status |
|---|---|---|
| Chapter 1–3 inline exercises | `choice`, `assemble`, `typein`, `match`, `listen`, `echo`, `turn`, `recarve`, `discover` in `Models.swift` | Retained; `ExerciseViews.swift` still diverges from county shell |
| Grammar discovery (`discover`) | `DiscoverView` | Wired for chapter 1; progressive reveal works here |
| Grammar at volume | `PatternDrillView` / `assemble` | Wired; session-gated |
| Vocabulary at volume | `VocabDeckView` / `LexemeDeck` | Wired; scheduler over lexeme ids |

### Content coverage (county packs)

| Pack | Exercises | Enum cases present | Notes |
|---|---|---|---|
| Rockfleet representative (`mayo.grainne-1593.json`, bundled) | 12 | all 9 | Current Phase 3 proof |
| Mayo full draft | 38 | all 9 | Not bundled; pre-clearance |
| Offaly / Dublin / Meath (bundled review) | 30 each | all 9 | Review draft; no gold until gates close |

Pre-D27 **twelve mechanic families** are fully re-authored as the nine enum cases plus
three authored uses. References to "12 families" elsewhere in this file describe the
24 July rebuild before D27 collapsed the taxonomy.

### Screenshot map (`tmp/exercise-screenshots/`)

Twelve Rockfleet Learning-path screens captured 2026-07-30. Critique:
`.impeccable/critique/2026-07-30T15-34-03Z__tmp-exercise-screenshots.md`.

| File | D27 layer | Family / container | Authored use | Implementation gap |
|---|---|---|---|---|
| `01-listen-choose.png` | Response family | Listen and choose | — | **Shell ACCEPT** — choices answerable from cold open; D27 repair window; on-row rationale |
| `02-matching.png` | Response family | Matching | — | **Shell ACCEPT** — thumb-native board; brief wrong-pair unlock; ≤4 pairs |
| `03-sentence-audio.png` | Response family | Sentence construction | `audioPrompted` | Bar-driven Check works (nil-action regression fixed); bank tiles leave placeholders so targets never slide; Irish tiles sans while story voice is serif remains |
| `04-sentence-build.png` | Response family | Sentence construction | — | Same bar fix and stable bank; tile chips no longer scatter on pick |
| `05-free-typing.png` | Response family | Free typed production | — | English translation in serif, Irish input in sans; fada row uses atlas green not moss; stacked ink primaries |
| `06-conversation.png` | Container | Conversation | — | **Container contract unmet** — bare choice list, no turn transcript, branching, or resume |
| `07-sentence-sequence.png` | Response family | Sentence construction | `ordering` | English clause tiles, not Irish; same Check/Continue and recovery model as other builders |
| `08-read-respond.png` | Response family | Read or listen and respond | — | Read-only MC; Irish template serif but options sans; shares hollow radio row with fill-gap and grammar |
| `09-grammar-discovery.png` | Response family | Grammar discovery | — | **Family contract unmet** — one worked case + single MC, not reveal → reveal → produce → rule |
| `10-record-compare.png` | Response family | Record and compare | — | **Shell ACCEPT** — Record owns ink; ghosts for Play/Record again; quiet escape unless mic denied |
| `11-fill-gap.png` | Response family | Fill-in-the-blank | — | Choice-backed gap only; identical radio-row chrome as 06/08/09 |
| `12-delayed-typing.png` | Response family | Free typed production | `delayedRecall` | Delay works as later-page retrieval; not yet contextual mistake review; typography issues as 05 |

**Not pictured (intended but absent):** picture or map selection, listen and type,
radio-style listening, contextual mistake review, **Words you carry** practice, and the
D27 completion container.

### Migration groups (remaining build order)

1. **Recognition** — add picture or map selection (only missing family in group).
2. **Construction and production** — add listen and type.
3. **Contextual use** — radio; extend conversation to full node graph (representative Clew
   Bay fixture is the acceptance test).
4. **Consolidation** — contextual mistake review, **Words you carry** on shared runtime,
   capability-led completion; migrate `LexemeDeck` / `DiscoverView` grading onto county
   shell.

### Activity quality bar

Operational scorecard for cluster craft and agent loops:
[`docs/ACTIVITY-QUALITY-SPEC.md`](docs/ACTIVITY-QUALITY-SPEC.md). Shared dimensions,
D27 contract gates, Rockfleet fixtures, and adversarial scripts. Shell P0s (repair,
primary slot, disabled styles) before parallel family polish. Does not replace
`PRODUCT.md` / `DESIGN.md` / D27.

**First Composer pass (2026-07-30) — Shell vs fixtures 01/02/10:**
[`docs/activity-quality/SCORECARD-shell-2026-07-30.md`](docs/activity-quality/SCORECARD-shell-2026-07-30.md).
**REJECT** (mean 3.0/5; D2 = 1). Board-lock Retry P0 cleared at `237d74f`; not an
ACCEPT. **Kimi punch list (IDs only):** D1 D2 D3 D4 D5 F1 F5 F7. No spectacular
family pass until Shell ACCEPT.

**Composer re-score (2026-07-30) — Shell ACCEPT at `e4c6a8b`:**
[`docs/activity-quality/SCORECARD-shell-rescore-2026-07-30.md`](docs/activity-quality/SCORECARD-shell-rescore-2026-07-30.md).
Mean **4.1/5**; F1/F5/F7 pass; P0 clear. First pass REJECT at `237d74f` is
superseded for fixtures 01/02/10. Choice / Matching / Speaking spectacular
passes may proceed in cluster order; next gate is freezing the representative
Mayo run.

## Work completed

| Date | Work | Where |
|---|---|---|
| 2026-07-30 | **Composer Shell re-score — ACCEPT.** Fixtures 01/02/10 at `e4c6a8b`. Mean 4.1/5; D2 5, D7 5; F1/F5/F7 pass; P0 clear. Four targeted UI tests pass (repair window, matching unlock, record primacy, mic escape); largest Dynamic Type on all three fixtures; cold-open and mic-denied screenshots in `tmp/exercise-screenshots/rescore-2026-07-30/`. Residual: D8/D9 Reduce Motion and full VoiceOver not re-run. Unblocks freeze-the-representative-Mayo-run. | `docs/activity-quality/SCORECARD-shell-rescore-2026-07-30.md`, `STATUS.md` |
| 2026-07-30 | **Shell scorecard punch list implemented; two 237d74f bar regressions found and fixed.** All five Kimi items landed in the county shell: Record/Stop owns the ink slot until compare with a quiet no-recording escape (D2/F7); listen-choose answers from cold open (D1/F1); selection families follow the D27 repair window — first wrong carries the rationale on the affected row and struggle fires only when the next touch fails to self-correct, matching never leaves its brief on-target note (D3/D5/F1/F5); matching is a single-column thumb board and the Mayo draft's 5-pair board is re-authored to four with ≤4 pairs enforced in both validators (D4/F5). Verification also exposed two regressions from `237d74f`: the bottom-bar Check published its action then had it overwritten nil by a state sync (builders advanced without grading), and the terminal exercise page lost "Complete this chapter path". Builder banks now keep placeholders so tiles never slide mid-task. Full simulator suite passes on iPhone 17 Pro (42 unit, 19 UI, incl. new repair-window, matching-unlock and record-primacy tests); 45 Python tests pass; changed screens inspected light, dark, and at largest Dynamic Type. Awaiting Composer re-score; not an ACCEPT. | `ios/AnTuras/CountyExerciseSystem.swift`, `CountyStoryExperienceView.swift`, `CountyStoryPack.swift`, `content/mayo/grainne-1593.pack.draft.json`, `tools/validate_county_pack.py`, `tools/tests/`, `ios/AnTurasUITests/AtlasFlowUITests.swift` |
| 2026-07-30 | **D28 chapter-opening Flow density; existing loops and stills wired.** One muted ambient hero per chapter opening; still→motion pipeline; evidence scans stay still. Wired unused Mayo Rockfleet + galley videos, Mayo draft openings to existing atmosphere stills (rev 7), Dublin's four remaining openings to catalog stills, Meath Ch1 to Boyne ford still, and the bundled Rockfleet proof to `video.mayo-rockfleet-sea-surge`. MEDIA-AUDIT now carries Batches A–C for Flow spend. Does not clear rights or generate new Flow clips in-repo. | `docs/DECISIONS.md` D28, `docs/MEDIA-AUDIT.md`, `content/mayo/`, `tools/build_phase5_county_drafts.py`, `ios/AnTuras/Resources/CountyStories/` |
| 2026-07-30 | **First Composer Shell scorecard — REJECT.** Fixtures 01 listen-choose, 02 matching, 10 record-compare against commit `237d74f`. Mean 3.0/5; fails D2 (speaking primary inverted), residual D3 friction, F1/F5/F7 contracts. Board-lock Retry P0 already cleared; listen-choose gate and Record primacy remain. Kimi punch list: D1 D2 D3 D4 D5 F1 F5 F7. No family spectacular pass until Shell ACCEPT. | `docs/activity-quality/SCORECARD-shell-2026-07-30.md`, `STATUS.md`, `docs/README.md` |
| 2026-07-30 | **Activity Quality Spec drafted for Learning-mode craft loops.** Operational scorecard: ten shared dimensions, P0 checklist, D27 family/container contract gates, Rockfleet fixture map, adversarial scripts, and agent-loop roles. Linked from docs index and inventory; shell P0s before parallel polish. Does not change product or design authority. | `docs/ACTIVITY-QUALITY-SPEC.md`, `docs/README.md`, `STATUS.md` |
| 2026-07-30 | **Three disposable iOS learning-interaction studies implemented and focused verification passed.** Sound Match tests immediate audio/meaning choice and in-place repair; Sentence Flow keeps correct sentence work while role cues visibly disappear; Coast Placement attaches *farraige*, *bá*, and *áit* to a spatial coast before removing its labels. The studies use one narrow Clew Bay fixture, no story exposition, separate local state, direct audio fallback, and no county progress, review, or shared-runtime side effects. XcodeGen was regenerated; 3 focused unit and 5 focused UI tests pass, including complete wrong-to-correct loops, both appearances, largest Dynamic Type, and reduced motion. Initial states were directly inspected on an iPhone 17 Pro Max simulator. This is implemented and verified research evidence, not validated pedagogy or a selected architecture. | `ios/AnTuras/Prototypes/InteractionStudies/`, `ios/AnTurasTests/InteractionStudyTests.swift`, `ios/AnTurasUITests/InteractionStudyUITests.swift`, `docs/INTERACTION-STUDIES-REPORT.md` |
| 2026-07-30 | **D26 grilled; D27 records three activity layers and the migration lands.** The flat fifteen-family set became one activity anatomy, ten response families, and five containers, because five of the fifteen could not satisfy the response contract D26 also mandates. Sequencing and delayed retrieval became authored uses; grammar discovery stayed a family and reconciled with `DRILL.md`'s `discover` projection; dialogue and branching roleplay merged into one conversation container with setting as authored metadata; single-choice families now check on selection with a repair window before any struggle signal; **Words you carry** and scheduled review became two surfaces over one spine. `CountyExerciseFamily` went from twelve cases to nine with a deterministic migration from the legacy vocabulary, and 32 authored exercises across eight packs were re-expressed. A new `authoredUse` field keeps the anti-monotony cap measuring what the learner actually does after the merge. The 5,259 lines of prototype and interaction-study code were deleted once D27 recorded the retained primitives. XcodeGen regenerated; 42 unit, 17 UI, and 43 Python tests pass, and all eight packs validate. This changes the taxonomy and implementation order; it validates no learning outcome. | `CONTEXT.md`, `docs/DECISIONS.md` D27, `PRODUCT.md`, `DESIGN.md`, `docs/DRILL.md`, `docs/STORY-LEARNING-REBUILD-PLAN.md`, `ios/AnTuras/CountyStoryPack.swift`, `CountyExerciseSystem.swift`, `tools/` |
| 2026-07-30 | **Expanded activity reference review completed and D26 recorded.** A separate 48-activity HTML field guide supported selection of a familiar one-screen activity system. The next Mayo proof will combine that stable shell with only the response and recovery details from the iOS studies that improve clarity and repeatability. | `web/learning-activity-reference/`, `PRODUCT.md`, `DESIGN.md`, `docs/DECISIONS.md` D26 |
| 2026-07-04 | Repo founded; vision + full strategy map (unknowns, challenges, resources, competition) | `README.md`, `docs/STRATEGY.md` |
| 2026-07-04 | Persona decided: school-Irish re-learners + diaspora primary, NI as cultural north star | `docs/DECISIONS.md` D1 |
| 2026-07-04 | Dialect decided: Connacht first; Ulster required before NI launch | `docs/DECISIONS.md` D2 |
| 2026-07-04 | Historical spine drafted: 13 chapters, Ogham → Belfast revival, grammar ladder A1→B1 mapped to TEG | `docs/SPINE.md` |
| 2026-07-04 | ABAIR licensing mapped: commercial use needs written TCD consent; bundling rights are the key ask; contact info@abair.ie; fallbacks ranked | `docs/ABAIR.md` |
| 2026-07-04 | Chapter 1 vertical slice built and published as playable HTML prototype: 5 sessions, carve-progress mechanic, ogham name-carver artifact | `prototype/index.html` |
| 2026-07-04 | HTML slice reviewed: **mechanics, design taste, and flow approved** → platform decision D3, port to SwiftUI | `docs/DECISIONS.md` D3 |
| 2026-07-04 | SwiftUI prototype built and verified on iPhone 17 Pro simulator (iOS 26): all 5 sessions, content as bundled JSON, ogham Canvas renderer, carve-progress bar, gloss sheets, fada keys; debug deep-links (`--map`, `--session N`, `--reveal N`) for screenshots | `ios/` (xcodegen project) |
| 2026-07-04 | Native-feel overhaul ("the chisel"): NavigationStack with back-swipe + iOS 18 zoom transition; CoreHaptics vocabulary (chisel strike per correct answer, stroke ticks, completion flourish, error knock); ogham stones carve themselves stroke-by-stroke; map redesigned as an ogham stemline path with session numbers as strokes; story beats rise on springs, past beats dim; assemble tiles fly via matchedGeometryEffect; shake on wrong answers; Reduce Motion respected throughout; verified light + dark on simulator | `ios/AnTuras/` (`Haptics.swift` new) |
| 2026-07-04 | Sessions re-architected as swiped pages ("chalk before carve"): horizontal scene-paging replaces the vertical click-to-reveal flow; consecutive narrative blocks share a page, exercises gate the turn (pages beyond an unsolved exercise don't exist — swipe rubber-bands with a dull knock, iOS 18+); solving auto-turns the page after the verdict lands; next page trailed as breathing chalk guide-marks naming what's coming; synthetic completion page per session (flourish on arrival); DEBUG toolbar toggle between scene-pages and block-pages groupings; `--reveal N` now jumps to page N with earlier exercises pre-solved | `ios/AnTuras/` (SessionView, Models) |
| 2026-07-04 | Page redesign ("three registers") after review found pages monotonous and top-pinned. Block-pages toggle removed — scene pages won. Pages are now **authored in content, not derived**: chapter1.json restructured so each session is a list of typed pages; scene paras became beats, with spoken Irish as *data* (speaker, meaning, rough sound) rather than inline links; exercises carry an optional in-world context line. Spoken Irish is the hero primitive: display serif against a carved groove, pronunciation beneath, tap for meaning. Sluglines (place · time, small caps + short rule) mark scene changes. Notes are full-bleed lichen-washed manual pages with specimen pairs on a hanging rule. Exercises lost the grey card — register mark (three chalk strokes · CLEACHTADH), italic story beat, serif prompt, elements raised directly on the page. Register-specific composition: scenes/features sit at the optical centre, notes/exercises anchor at chapter-start depth. All registers verified light + dark on simulator | `ios/AnTuras/` (chapter1.json, Models, SessionView, ExerciseViews, ArtifactView) |
| 2026-07-04 | **Six new primitives** (second experimental wave). (1) *Sound*: bundled-clip audio pipeline — clips first (`Resources/Audio/<slug>`, manifest for the provider bake-off), system ga-IE voice second (Apple ships none as of iOS 26 — confirmed), graceful per-line silence last; ears on speech beats, glosses, seanfhocal. New `listen` page (ear-before-eye minimal pairs: féar/fear, Seán/sean in S4) and `echo` page (record yourself beside the model, ungraded — U8 punt; mic permission; skip hatch). (2) *Turns*: `turn` page — the scene pauses on your line; two chalk-dashed replies, both acceptable Irish, no fail state; choosing carves it as TUSA and the scene answers each differently; {name} interpolation (S3: meeting Bríd). (3) *Weathering*: `recarve` pages open S2–5 — earlier phrases weathered (vowels erode to middots), re-typed fadas-and-all to restore the groove; doubles as return acknowledgment (tá tú ar ais), which also now greets returns on map + cover; sessions carry an authored `hook` shown under AMÁRACH on the completion page. (4) *Lens*: `lens` feature page — Killala peels to Cill Ala, morphemes step out (S2). (5) *The hand*: artifact stone is now carved by the learner's own finger, base→top past chalk guides, tick per stroke; finished stone exports via ShareLink as an image card ("my name in ogham"). (6) Exercise polish: all non-note registers at optical centre; match = stone (serif + groove, raised) vs chalk (flat sans) with a thread drawn across the gutter per locked pair. Debug seeding args `--name`, `--done`. All verified light + dark on simulator | `ios/AnTuras/` (Speech, Beats, EchoView, TurnView, RecarveView, LensView new; Models, SessionView, ExerciseViews, Ogham, ArtifactView, MapView, CoverView, AppState, chapter1.json, project.yml) |

| 2026-07-04 | **TTS bake-off (round 2):** Gemini 3.1 Flash TTS (`gemini-3.1-flash-tts-preview`) regenerated 21/21; auto-jury removed — manual review via `tools/tts-bakeoff/review.html`; `winners.json` template for per-line picks; Irish TTS landscape researched (`docs/TTS-research.md`) | `tools/tts-bakeoff/`, `docs/TTS-research.md` |

| 2026-07-05 | **TTS decision:** Gemini 3.1 Flash TTS selected for playtest clips (quite good); ElevenLabs + Gemini 2.5 rejected on pronunciation; Azure `ga-IE` scheduled as follow-up bake-off | `docs/TTS-research.md` |

| 2026-07-05 | **Competitive atlas built ("The Seventh Way"):** interactive HTML companion to `COMPETITIVE-RESEARCH.md` — working reconstructions of all six competitor families' core loops (Duolingo lesson, blas. mastery grid, SSi audio round, Bitesize daily letter, Gaeilgeoir chat, Drops match, DCU MOOC), the structure×culture territory map, wrecks-on-the-shore lessons, live mockups of the slice's registers + primitives (recarve/turn/lens/ogham carver), seven imagined-future prototypes (Músaem, Ar Ais, Do Logainm, Féilire, dialect atlas, Dhá Litir, An Doras, in-world Comhrá), a pull×yield feature map, and six trade-off stances with move-conditions. Light+dark, page-language in Solas an Atlantaigh | `docs/seventh-way.html` |

| 2026-07-05 | **Illustration exploration framed:** principles → six style branches (incised, chalk, print, Atlantic wash, flat graphic, manuscript) → fixed test brief → two-day wide/deep funnel → canonical style bible (will log as D4); surfaces inventoried from chapter1.json | `docs/ILLUSTRATIONS.md` |
| 2026-07-05 | **The big picture built** — three surfaces from the Seventh Way futures shelf, answering playtester feedback ("intrigued by ch. 1 but where is this going?"). (1) *An Turas, the journey map*: the island of Ireland drawn in the carved-limestone language (Natural Earth 50m coastline → 241-point Swift shape, whole island per D1), the 13 spine chapters as numbered waypoints through place *and* time — Cill Ala c. 480 → Béal Feirste inniu; chalk-before-carve extended to the course (road behind carved in moss, one clear chalk leg ahead, faintest thread beyond); *tá tú anseo* pulse; every waypoint opens an era card (hook, payload, artifact) from new `journey.json`; ch. 1's card opens the chonair. Cover → journey → chonair → session is the new spine of the app. (2) *An Músaem*: 13 niches, one line-drawn glyph per artifact, ch. 1's ogham stone unlocks on completion (opens the existing share flow); locked niches are chalk-dashed with era cards; a rust dot means an artifact's people are asking. (3) *Ar Ais*: authored visits in chapter1.json (Dáire, Bríd, an bhaintreach, an chloch féin — 7 across the 5 sessions), FSRS-lite scheduler faoin gcraiceann (due +1 day on session end, ×2.5 on clean recall, reset on struggle, persisted; migration schedules visits for sessions done before the feature existed), queue dressed as people asking (*Tá beirt ag fiafraí fút*, N lá ó shin), answered with the recarve mechanic incl. ismise/isas pattern checks; never a card count. Returning learners land on the journey when someone is asking, else on the chonair. Debug args: `--journey --museum --arais --due N --card N`. All verified light + dark on iPhone 17 Pro sim. **The 13-waypoint navigation described here is superseded by D12's 32-county map; its chapter progress and mechanics remain migration inputs.** | `ios/AnTuras/` (JourneyView, MuseumView, ArAisView, IrelandShape, ChapterCard new; AppState, Models, AnTurasApp, MapView; Resources/journey.json; chapter1.json visits) |
| 2026-07-05 | **Journey map review pass:** thread visibility, label placement, and copy quick wins, then two follow-ups. (1) Chapter 9's place name carried a stray year ("Baile Átha Cliath, 1893") no other chapter has — dropped, era range already covers it. (2) Waypoint tap targets were sized off the label's 170pt frame rather than the marker, scaled 3.2×, giving each waypoint a ~500pt-wide invisible hit region that could steal taps meant for a neighbour; replaced per-marker tap gestures with one nearest-waypoint gesture over the whole map, so density (Dubhlinn and an lá inniu render ~14pt apart) can no longer mis-resolve a tap. (3) Added a time axis strip below the map — the route is chaotic in space but linear in time, and the map alone couldn't carry that; 13 evenly-spaced ticks (not calendar-proportional — chapters 8–13 would crowd the last tenth of a real timeline) in the same moss/chalk depths as the road, endpoints and current era captioned, each tap-through to its chapter card | `ios/AnTuras/JourneyView.swift`, `Resources/journey.json` |

| 2026-07-05 | **Phase 1 playtest decisions logged; Phase 2 entered.** Retention: tá tú ar ais + journey map validated; An Féilire chosen as gentle ritual layer (D6). Audio: Gemini all-generated + native-speaker QA (D7). Illustration: scene pages only (D8). CMS review layer scoped (D9). Business: premium + grants on top, Ch 1–4 launch, bespoke (D10). Pedagogy: listening-first permanent (D11). Phase 1 exit (D5). | `docs/DECISIONS.md` D5–D11, `docs/STRATEGY.md`, `docs/TTS-research.md` |

| 2026-07-05 | **Chapter 2 content pipeline run + process doc.** Three-stage pass (generator → adversarial reviewer → overall editor) produced `chapter2.json` (*Oileán na Naomh*, 5 sessions, 58 pages); repeatable workflow and good-enough gates written up | `content/chapter2/`, `ios/AnTuras/Resources/chapter2.json`, `docs/CONTENT-PIPELINE.md` |

| 2026-07-06 | **Chapter 3 through the pipeline (*Na Lochlannaigh*, Vikings).** Second repeat of the three-stage pass produced `chapter3.json` (past tense + irregulars, directions, market/Norse-loanword payload, Dubhlinn lens); adversarial review returned **PASS WITH REVISIONS**, editor fixes logged. Human board sign-off, audio, and scene illustration still required | `content/chapter3/`, `ios/AnTuras/Resources/chapter3.json` |

| 2026-07-07 | **App went multi-chapter.** `ContentLoader` now serves chapters 1–3; `AppState` gained multi-chapter selection with **per-chapter progress persistence**; visits loader **merges Ar Ais across chapters** (was chapter-1 only). Per-chapter artifact registers built: **illuminated initial** (ch. 2) and **hack-silver arm-ring** with `{name}` notch (ch. 3, `ArmRingView.swift`) | `ios/AnTuras/` (Models, AppState, ArtifactView, IlluminatedInitialView, ArmRingView) |

| 2026-07-08 | **Build fixes.** Swift build errors in `AppState` init and share-card rendering resolved; tree building clean on simulator | `ios/AnTuras/` (AppState, ArtifactView) |
| 2026-07-10 | **County-led product architecture adopted (D12).** All 32 counties now have researched first-story leads, each requiring a named real anchor, substantial reading/encounter, 20-word plan, source/rights register, and expert review. The county map is the learner-facing structure; the historical spine remains the sequencing rail. Core documentation and the content-pipeline gates were updated; app/schema migration remains future work. | `docs/DECISIONS.md` D12, `docs/COUNTY-ATLAS.md`, `docs/COUNTY-STORY-SLATE.md`, `docs/SPINE.md`, `docs/CONTENT-PIPELINE.md` |
| 2026-07-10 | **First full county-story arc implemented — Mayo / Breastagh.** Chapter 1 is now a story-first Mayo pack (`mayo.breastagh-stones`) with explicit anchor, inscription encounter, 20-word groups, source/rights/review metadata, and story-keyed progress migrated losslessly from Chapter 1 saves. The path and county card show the story contract; the lesson distinguishes the fictional practice inscription from the damaged Breastagh reading. It remains an editorial draft, blocked from public release pending historian, pedagogue, rights, and audio QA. | `ios/AnTuras/Resources/journey.json`, `chapter1.json`, `Models.swift`, `AppState.swift`, `JourneyView.swift`, `MapView.swift`, `content/mayo/source-register.md` |
| 2026-07-11 | **First-story reset and expansive interface vision.** Clean-slate review replaced Breastagh as Mayo's flagship with Gráinne Ní Mháille's 1593 petition; retained Clonmacnoise but recentered Offaly on Flann Sinna and the Cross of the Scriptures c. 900; retained Sihtric but recentered Dublin on the first Irish penny c. 997. Breastagh becomes the prototype for short, labelled reconstruction field notes. A living-historical-atlas direction now expands the app around the island, people, evidence, time, county dossiers, source certainty, and a collection separating real evidence from learner-made artifacts. This row records the design direction; the implementation and test result follow below. | `docs/STORY-RESET.md`, `docs/EXPANSIVE-INTERFACE-VISION.md`, `docs/DECISIONS.md` D13 |
| 2026-07-11 | **Gráinne first encounter iterated and tester-approved.** The first atlas build exposed too much product and editorial architecture; a first simplification became trustworthy but dry. The approved revision restores narrative craft through Rockfleet, Gráinne's losses and agency, a dedicated person beat, an interactive 1593 family-letter reveal, and Irish earned through her name before the learner's. Later storytelling is surfaced affirmatively rather than as a warning. Approval applies to this simple foundation; the next milestone is resolving the full-story product contract before wider testing. | `ios/AnTuras/AtlasPrototype.swift`, `IslandAtlasView.swift`, `MayoStoryPrototype.swift`, `AtlasCollectionViews.swift`, `docs/GRAINNE-PROTOTYPE-REPORT.md` |
| 2026-07-11 | **Gráinne / Mayo product contract resolved for storyboarding.** One county at a time; four to six bingeable 8–12 minute episodes; flagship-first stress test with side stories only for demonstrated gaps; broader Gráinne life organised around 1593; binding discovery + Irish action per episode; exactly 20 lexical headwords with need/use/later-reuse lifecycle; three-level evidence ladder; quiet county record + usable language + one completion artifact; Mayo voyage chart; authored next county rather than a picker; just-in-time optional grammar. Remaining research and design questions are explicitly carried. | `docs/GRAINNE-PRODUCT-CONTRACT.md`, `docs/DECISIONS.md` D14–D15, `docs/PRODUCT-GLOSSARY.md` |
| 2026-07-12 | **Gráinne flagship stress-test + storyboard + weave + lo-fi review; Mayo source brief started.** Provisional pass: she can carry Mayo alone for narrative depth and the 20-word lifecycle; no side story yet. Five-episode spine organised around 1593; language weave and three-level evidence ladder drafted; lo-fi review passes with revisions (tighten Ep3, watch Ep5 overload) and blocks implementation/tester round until paper walkthrough. Historian-ready Mayo 1593 packet begun with claim ledger and rights plan; Breastagh register retargeted as field-note only. | `docs/GRAINNE-SOURCE-STRESS-TEST.md`, `docs/GRAINNE-STORYBOARD.md`, `docs/GRAINNE-LANGUAGE-WEAVE.md`, `docs/GRAINNE-LOFI-REVIEW.md`, `content/mayo/grainne-1593-source-brief.md` |
| 2026-07-12 | **Walkthrough revisions + parallel launch packets.** Storyboard revised to six episodes; Mayo brief advanced with L1 paraphrases and transcription-first rights default. Offaly Cross, Dublin penny, and Meath/Trim briefs (plus Meath clean-slate confirm) opened. Content-review HTML CMS foundation + manifest; editorial board recruitment pack; Chapters 1–3 legacy salvage map. | `docs/GRAINNE-STORYBOARD.md`, `content/mayo/grainne-1593-source-brief.md`, `content/offaly/`, `content/dublin/`, `content/meath/`, `tools/content-review/`, `docs/CONTENT-REVIEW-CMS.md`, `docs/editorial/BOARD-RECRUITMENT.md`, `docs/LEGACY-SALVAGE-MAP.md` |
| 2026-07-12 | **Personal atlas Phase 1 pilot shipped in-app.** Behind-a-name / behind-a-place search and result shell on the living atlas: 25 given + 25 surname + 30 place packs, certainty labels, historical-form travel, local saves under “What matters to you,” Mayo story handoffs, first-encounter hooks. Bundled JSON; no genealogy matching; foundation vs authored depth. Specialist review and licensed surname authority still required before public hardening. | `docs/PERSONAL-HISTORIES-FEATURE-PLAN.md`, `ios/AnTuras/PersonalAtlas*.swift`, `Resources/personal-atlas-subjects.json`, `content/personal-atlas/` |
| 2026-07-13 | **Personal atlas Phase 0–4 engineering delivered behind evidence gates.** Added the hard-case research protocol; assertion-level CMS and deny-by-default public exporter; signed/versioned detail cache and deep links; production Logainm ingestion and a lazy 51 MB SQLite foundation containing 126,712 places and 305,638 aliases; automated all-island quality audit and safe nulling of 7,571 invalid source coordinates; applied 22 existing-link hierarchy recoveries plus four reviewed Northern repairs with provenance; private corrections and privacy-safe query ledger; aggregate distribution pipeline; coarse opt-in nearby places; source-visible static previews; map/time, voices, keepsake, field mode, family worksheet, and community-edition gates. Simulator build and 22 Swift unit plus 5 UI and 22 Python tests pass. No pilot subject was promoted: specialist, rights, audio, accessibility, community, hosting, and user-validation work remains external release work. | `docs/PERSONAL-ATLAS-*.md`, `ios/AnTuras/PersonalAtlas*.swift`, `tools/content-review/`, `tools/*personal*`, `.github/workflows/logainm-monthly.yml`, `web/personal-atlas/` |
| 2026-07-13 | **House story voice selected.** ElevenLabs generated voice *Irish Cultural Guide* (`NPWroowF4phQhaPWjXPj`) is the default voice for Gráinne / Mayo narrative audio and the next story-audio tests. Browser review accepted the character despite generation variability; two of three samples were good enough. Irish headwords and phrases remain subject to focused language QA before bundling. | `docs/DECISIONS.md` D16, `docs/TTS-research.md` |
| 2026-07-13 | **Initial-launch voice locked.** Irish Cultural Guide is now the default voice for all initial-launch narrative and Irish teaching audio. It is not perfect, but is mostly accurate and good enough to carry launch; the Gaeilge-first alternatives tested worse. Trinity College Dublin, ABAIR, and other established Irish-language speech/data partnerships are post-launch upgrade paths. | `docs/DECISIONS.md` D17, `docs/TTS-research.md` |
| 2026-07-13 | **Gráinne historian/pedagogue gate passed; full six-episode prototype implemented.** Historian and Irish-language pedagogue approval of the Mayo claims and 20-word weave was reported, with very positive tester feedback on the direction. The app now carries the complete Clew Bay → Rockfleet → squeeze → crossing/record → partial answer → return arc as 18 resumable beats, one dramatic/language action per episode, the full 20-word lifecycle, a progressive voyage chart, versioned migration from the approved four-step encounter, and a cinematic palette/illustration progression. Generated interpretive portraiture replaces the former abstract mark; the person page now uses the same full-width editorial composition and evidence rhythm. The final simulator run passes 22 Swift unit and 5 UI tests, including XXXL accessibility text, person-page evidence reachability, and route persistence; all 22 Python content/tooling tests also pass. Public release still requires final native-speaker audio QA, rights clearance for production imagery, accessibility/device QA, and a moderated complete-arc tester round. | `ios/AnTuras/GrainneFullStory.swift`, `ios/AnTuras/MayoStoryPrototype.swift`, `docs/GRAINNE-ART-DIRECTION.md`, `docs/GRAINNE-STORYBOARD.md`, `docs/GRAINNE-LANGUAGE-WEAVE.md` |
| 2026-07-13 | **Editorial composition system documented and rolled across the app.** `PRODUCT.md` and `DESIGN.md` now make image-led and text-led surfaces equal expressions of one system: one anchor, live accessible copy, intentional negative space, accessibility recomposition, story-led cinematic pressure, and containers that earn their boundary. Shared semantic SwiftUI headers now carry that grammar through the living atlas, personal atlas, legacy journey/map, review, practice, lesson, and artifact surfaces. The Mayo dossier is a full-width landscape hero; the obsolete portrait-sticker treatment is gone from active surfaces. Chapter 1 scene art is full-width and four text-bearing generated assets have clean, text-free v2 replacements. Normal and accessibility-size simulator compositions were inspected on iPhone 17 Pro. | `PRODUCT.md`, `DESIGN.md`, `.impeccable/design.json`, `ios/AnTuras/Theme.swift`, `ios/AnTuras/MayoStoryPrototype.swift`, `ios/AnTuras/SessionView.swift`, `ios/AnTuras/Resources/art/*-v2.png` |
| 2026-07-14 | **Signed-off Gráinne copy implemented.** The warmer, concrete replacement voice now carries all 18 beats; route-turn chart labels, authored episode exits, dossier promise, person-page separation, listening-first prompts and `Say it like` labels match the review. Episode 4 handles the July `SP 63/170` interrogatory under D18/D19, Episode 5 now tests the unsupported conclusion instead of revealing it, and the collection reports all 20 approved Mayo headwords. XcodeGen regeneration and the complete iPhone 17 Pro simulator suite pass: 23 unit tests and 10 UI tests, including XXXL Dynamic Type, evidence reachability, audio-first recall, completed-beat replay, source identity and the new Episode 5 recovery path. The affected Episode 5 screen was also directly inspected in the simulator. | `docs/GRAINNE-COPY-REVIEW.md`, `ios/AnTuras/GrainneFullStory.swift`, `ios/AnTuras/MayoStoryPrototype.swift`, `ios/AnTuras/AtlasCollectionViews.swift`, `ios/AnTurasTests/AtlasProgressTests.swift`, `ios/AnTurasUITests/AtlasFlowUITests.swift` |
| 2026-07-14 | **Phase 3 four-county working product implemented and simulator-verified.** D20 records the owner-reported Phase 2 pass. A reusable county-story engine now carries Offaly's Cross of the Scriptures, Sihtric's Dublin penny and Trim's grant/castle as visibly provisional four-episode loops; map progression, evidence and made-object shelves, 80-word accumulation, TEG can-do context, stability/difficulty review scheduling, daily calendar ritual and atomic offline pack validation share one durable state model. After XcodeGen regeneration, the complete iPhone 17 Pro simulator suite passes **28 unit and 14 UI tests**; all **22 Python content/tooling tests** pass. UI coverage includes the Offaly dossier at XXXL Dynamic Type and the shared recovery interaction; direct simulator inspection covers the Offaly dossier/listen beat, Dublin in dark appearance and Meath evidence in light appearance. | `ios/AnTuras/LaunchCountyStories.swift`, `AtlasCalendarView.swift`, `AtlasPrototype.swift`, `IslandAtlasView.swift`, `AtlasCollectionViews.swift`, `AppState.swift`, `ios/AnTurasTests/AtlasProgressTests.swift`, `ios/AnTurasUITests/AtlasFlowUITests.swift`, `content/{offaly,dublin,meath}/` |
| 2026-07-15 | **Story and Learning rebuild confirmed.** New feedback rejects the four-county previews as the next tester build. D21–D22 lock one page sequence with two modes, separate story-read and language-complete progress, an eight-to-ten chapter / 60–90 minute Mayo target, varied full-screen exercises, and a four-county internal gate before external testing. This is a confirmed plan and product decision, not an implemented app change. | `docs/STORY-LEARNING-REBUILD-PLAN.md`, `docs/DECISIONS.md` D21–D22, canonical product/status documents |
| 2026-07-24 | **Story/Learning rebuild phases 0–3 complete; Rockfleet proof passes on simulator and physical iPhone.** Versioned page packs, stable ids, dual mode projections, separate progress/completion, deterministic legacy migration, a shared twelve-family full-screen exercise system, and the representative Rockfleet chapter are working. The first uniform narrative renderer was rejected as visually monotonous; Rockfleet now changes composition with the account and varies its forward action labels while preserving native navigation. The legacy Gráinne renderer and hardcoded launch-county copy are removed in favour of pack-backed routes. XcodeGen regeneration and the complete iPhone 17 Pro Max simulator scheme pass 52 tests; 22 Python content/tooling tests pass. Light, dark, accessibility-size, Increased Contrast and Reduce Motion states were directly inspected. On the physical iPhone 15 Pro Max, the complete dark Story path, complete light Learning path, and largest accessibility-text opening pass with no failures. | `ios/AnTuras/CountyStoryPack.swift`, `CountyStoryExperienceView.swift`, `CountyNarrativePacing.swift`, `CountyExerciseSystem.swift`, `StoryEvidenceComponents.swift`, `Resources/CountyStories/`, `ios/AnTurasTests/AtlasProgressTests.swift`, `ios/AnTurasUITests/AtlasFlowUITests.swift` |
| 2026-07-24 | **Mayo Phase 4 production plan approved; authoring pipeline proved.** D23 records the approved nine-chapter storyboard and recommended D-A–D-F choices. The offline validator prints per-county timing, exercise, lifecycle, audio, evidence, and gate state while matching the runtime rules and adding complete-lifecycle and lexeme-contract enforcement. Chapter 1, *Clew Bay and Umhaill*, is authored in a non-bundled county draft so the proven Rockfleet pack stays intact during assembly. All 35 Python content/tooling tests pass. Expanded history, pedagogy, audio, and image-rights gates remain open. | `docs/GRAINNE-STORYBOARD-V2.md`, `docs/DECISIONS.md` D23, `tools/validate_county_pack.py`, `tools/tests/test_validate_county_pack.py`, `content/mayo/` |
| 2026-07-24 | **Nine-chapter Mayo review draft completed and machine-checked.** Chapters 2 and 4–9 are authored; Rockfleet now introduces only *caisleán* and is trimmed to eight exercises. The non-bundled revision-5 draft contains 99 pages, an 84.8-minute estimated Story path, 38 exercises across all 12 families, and complete ordered lifecycles for all 20 headwords. Strict county-pack validation and all 36 Python tests pass. The structurally complete draft remains outside the app because expanded specialist review, 20 teaching-audio resources, Rockfleet image rights, integration, and device/accessibility checks are still open. | `content/mayo/grainne-1593.pack.draft.json`, `content/mayo/DRAFT-STATUS.md`, `docs/GRAINNE-STORYBOARD-V2.md` |
| 2026-07-24 | **Mayo revision-6 historian candidate prepared.** The accepted pre-clearance workflow applies the July historical review's reversible fixes before external review: C04 now carries a candidate Carew MS 601 / SP 12/159 trail but remains Story-only and behind `history.expanded`; C02's archive bias appears in Story mode; Chapter 2/4 wording, C06/C10/C14/C15 evidence statuses, names, and stale prototype copy are corrected. The non-bundled pack now contains 100 pages with an 86.2-minute Story path and 104.1-minute Learning path. Strict validation and all 36 Python tests pass. No external gate is closed and the bundled app remains unchanged. | `content/mayo/grainne-1593.pack.draft.json`, `content/mayo/grainne-1593-source-brief.md`, `content/mayo/DRAFT-STATUS.md`, `docs/mayo-historical-review/` |
| 2026-07-24 | **Expanded-history reviewer continuity requirement removed.** D24 records that a newly named historian may close the revision-6 `history.expanded` gate. The new review must identify revision, scope, date, requested changes and final disposition, and must explicitly confirm the candidate C04 folio and diplomatic wording. No gate is closed by this governance decision. | `docs/DECISIONS.md` D24, `content/mayo/grainne-1593-source-brief.md`, `content/mayo/DRAFT-STATUS.md` |
| 2026-07-24 | **Split historical review permitted.** D24 now permits a narrative historian to own the Chapter 2/4 disposition and an archival specialist to own C04 folio and diplomatic-wording confirmation. One qualified person may perform both, but `history.expanded` requires both recorded dispositions. | `docs/DECISIONS.md` D24, `content/mayo/grainne-1593-source-brief.md`, `content/mayo/DRAFT-STATUS.md` |
| 2026-07-24 | **Offaly, Dublin, and Meath full Story/Learning drafts assembled and simulator-smoke-tested.** The Mayo pattern now produces three non-bundled, six-chapter pre-clearance packs with variable page counts, estimated 49.4-minute Story paths, 30 exercises across all 12 mechanic families, complete 20-word lifecycles, object-specific evidence boundaries, and explicit open review gates. A repeatable builder and regression tests keep the generated drafts current; strict validation and all 38 Python tests pass. A temporary iPhone 17 Pro substitution build rendered representative Story and Learning pages for all three, the visible missing-audio recovery state, largest accessibility text, and a dark-appearance sample. The shipping bundle remains unchanged and passes 36 unit plus the two preview UI tests affected by substitution. This smoke test does not close specialist, full accessibility, device, or promotion gates. | `tools/build_phase5_county_drafts.py`, `tools/tests/test_validate_county_pack.py`, `content/{offaly,dublin,meath}/` |
| 2026-07-24 | **Offaly, Dublin, and Meath promoted to in-app review drafts.** The full generated packs replace the five-page previews in the app bundle and are labelled **Review draft** wherever release state appears. Reviewers can traverse both complete modes and retain stable page progress. A new runtime guard requires `completeCounty` scope **and** zero open review gates before gold, made objects or scheduled words can be awarded; completing a review draft therefore has no release effects. Mode-opening and completion copy now derives from each pack's real chapter, page, timing, exercise and gate state instead of Rockfleet constants. All 38 Python tests, 36 Swift unit tests and 16 UI tests pass; the three review openings were directly inspected on an iPhone 17 Pro simulator at accessibility text size. | `ios/AnTuras/Resources/CountyStories/`, `CountyStoryPack.swift`, `CountyStoryExperienceView.swift`, `LaunchCountyStories.swift`, `AtlasPrototype.swift` |

## Immediate next steps (learning-mechanics foundation, then rebuild Phases 4–6)

1. **Freeze the representative Mayo run** — use the selected D26 shell with the Clew
   Bay fixtures and record the exact listening, matching, construction, typing,
   conversation, speaking, comprehension, completion, and contextual-review sequence.
   Decide which local response, correction, scaffold-removal, motion, and spatial
   details from the iOS studies are retained; do not reopen the architecture choice.
   Grade craft against [`docs/ACTIVITY-QUALITY-SPEC.md`](docs/ACTIVITY-QUALITY-SPEC.md).
2. **Implement the shared state engine and activity shell** — centralise attempt,
   diagnostic, hint/recovery, retry, completion, persistence, focus, accessibility
   announcements, and exactly-once memory events before migrating production packs.
3. **Operate the complete representative run** — prove the selected shell end to end
   with incorrect and recovery paths, audio fallback, keyboard/fadas, microphone
   denial, interruption/resume, and fixture-only completion.
4. **Migrate the activity families in bounded groups** — recognition; construction
   and production; contextual use, including grammar discovery and radio; then
   contextual mistake review, **Words you carry**, and capability-led completion.
   Each group must pass its gallery and accessibility matrix before the next spreads.
5. **Harden the authored contract, schema, memory handoff, and validators** — mirror
   Swift and Python rules, prove deterministic debt-free review behavior, preserve
   old progress, and add failing fixtures for every family and contract invariant.
6. **Run the foundation gate** — complete automated transition, schema, persistence,
   UI, branching, offline, and failure checks plus direct simulator, VoiceOver,
   appearance, contrast, motion, audio, microphone, keyboard/fada, and physical-device
   verification. Record the result before spreading the system.
7. **Migrate one production Mayo slice, then decide whether to spread** — verify both
   modes, progress preservation, memory events, collection handoff, and optional
   review. Resume broader county integration only after this slice and the foundation
   pass without private family-specific exceptions.
8. **Resume county review and integration only after the foundation passes** — clear
   Mayo's history, pedagogy, audio, and rights gates; review Offaly, Dublin, and Meath
   independently; then run the four-county tester-readiness gate.
9. **Preserve the Phase 2 test record** — add participant count and moderated-session
   notes if they exist; D20 deliberately does not invent them.

### Lower priority (unchanged)

1. **Personal atlas external release gates** — run the 12–18 person hard-case protocol;
   establish the specialist-reviewed showcase, licensed surname source and community/
   voice agreements before public promotion.
2. **Generate Irish Cultural Guide clips only for cleared text** — do not QA superseded
   D13 copy; native-speaker review remains required for Irish teaching audio. Treat
   Trinity/ABAIR partnership work as a post-launch upgrade.
3. **Flow / Gemini Omni Batch A** — animate the D28 queue in `docs/MEDIA-AUDIT.md`
   (wired stills first), then Batch B missing stills; recompress shipped loops to ≤2 MB.
4. **Illustration production recipe** — atlas registers before Chapter 1–3 scene sets.
5. **TestFlight build** — needs Apple Developer team in `ios/project.yml`.
6. **Send ABAIR commercial enquiry** — optional; draft at `docs/ABAIR-enquiry.md`.
7. **Grant funding research** — Foras na Gaeilge / Údarás strings before accepting (D10).

## Long-term plan

- **Phase 1 — Vertical slice (complete):** Chapter 1 SwiftUI app with writing, audio,
  and illustrations. Playtest validated narrative pull without streaks; tá tú ar ais and
  the journey map named as return mechanisms. Exit criterion met (D5).
- **Phase 2 — Story contract + atlas proof (complete by owner report):** Gráinne claims,
  weave and copy are approved; the six-episode prototype was delivered and its complete
  moderated arc was reported passed on 14 July (D20). Session details are not in-repo.
- **Phase 3 — Story and Learning rebuild (now):** preserve the implemented atlas,
  evidence, collection, review, calendar, offline, and progress foundations while
  replacing the preview-shaped county content and repetitive learning path. Mayo proves
  one authored sequence with two modes before Offaly, Dublin, and Meath are rebuilt.
  The phase exits only when all four counties pass the internal tester-readiness gate.
- **Phase 4 — Launch:** premium subscription to diaspora + re-learners; calendar-aligned
  moments (Seachtain na Gaeilge, St Patrick's Day); grant funding layered on top.
- **Phase 5 — NI expansion:** gated on Ulster dialect audio (D2) and community
  relationships (Turas, Glór na Móna); chapters 10–12 carry the editorial weight.

## Open questions being carried

- **An Féilire implementation** — direction chosen (D6); product design and content
  tagging for calendar-tied material is Phase 3/4 work.
- **Contested history editorial principles** (STRATEGY.md U7) — write before Chapter 10
  production; advisory board scope TBD.
- **Frame device carrying the learner between county stops and eras** (SPINE.md, open
  creative question). D12 fixes the map structure; it does not yet select the recurring
  narrative device.
- **Grant-funding strings** — understand before accepting public money (D10).
- **Irish-language audio upgrade path** — pursue Trinity/ABAIR/established speech-data
  partnerships after launch; Irish Cultural Guide is the initial-launch baseline (D17).

## Resolved (Phase 1 → 2)

| Unknown | Resolution |
|---|---|
| U1 Persona | D1 — re-learners + diaspora; NI north star |
| U2 Dialect | D2 — Connacht first |
| U3 Retention loop | D5/D6 — narrative pull (tá tú ar ais, journey map) + An Féilire rituals |
| U4 Story and language relationship | D21 — one page sequence, Story mode without language gates, Learning mode with the shorter causal story and required exercises |
| U5 Audio strategy | D17 — Irish Cultural Guide for all initial-launch audio, all-generated with native-speaker QA; D7 is the historical Chapter 1 baseline |
| U6 Business model | D10 — premium + grants on top; Ch 1–4 launch; bespoke |
| U8 Pronunciation | D11 — listening-first permanent; echo ungraded |

## Risks watchlist

- **blas.** is shipping fast in the same waters (rigour angle); our differentiation
  is narrative/identity — window is now.
- Content accuracy: nothing ships publicly without native-speaker review.
- Bespoke content cost per chapter remains the business-model risk; four chapters at
  launch is depth-over-breadth by design (D10).
- Fixed schemas can create the appearance of a complete county while rewarding short
  outlines and repeated mechanics. D22 requires representative-slice proof and
  outcome-based validators before the pattern spreads again.
- The new interface could become an attractive historical browser that weakens the
  language journey. Every prototype must prove that real evidence makes the Irish
  more memorable and usable, not merely that the atlas is enjoyable to browse.
- Source access and rights now gate story shape earlier: petitions, coins, crosses,
  recordings, portraits, and maps need claim-level provenance before final UI and art.
- Legacy progress, artifacts, and review schedules must survive replacement story ids;
  editorial courage cannot become destructive migration.
