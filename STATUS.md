# STATUS

*Project: An Turas (working title) — iOS app teaching Irish through history, culture,
and visual narrative. English → Irish only. Updated 2026-07-24.*

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
and Learning modes. Story mode carries the complete account, opens the next county,
and does not claim the 20 words. Learning mode keeps a shorter causal account, inserts
varied full-screen exercises, and is the only path that turns the county gold and
schedules its words. Speaking remains ungraded record-and-compare.

**Current target:** rebuild-plan phases 0–3 are complete. The representative
Rockfleet chapter has proved the page model, both mode projections, full-screen
exercise system, recovery, accessibility, progress migration, and varied narrative
composition. Phase 4 now follows the approved nine-chapter Mayo storyboard. The
non-bundled review draft now contains all nine chapters, the revised Rockfleet
sequence, 38 exercises, and all 20 lifecycles. Its strict structural and learning
checks pass. Targeted history and pedagogy review, audio, image rights, app integration,
and device/accessibility verification remain. Offaly, Dublin, and Meath then require
substantial reauthoring, not clearance of their present preview copy.

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

**Tester gate:** no external learner build until all four counties pass the narrative,
20-word lifecycle, exercise-distribution, specialist review, native-speaker audio,
rights, accessibility, physical-device, migration, offline, and automated checks in
`docs/STORY-LEARNING-REBUILD-PLAN.md`. The prior Mayo test remains owner-reported
evidence with no session record in the repository; it does not validate the expanded
story or new Learning mode.

## Work completed

| Date | Work | Where |
|---|---|---|
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

## Immediate next steps (rebuild-plan Phase 4)

1. **Review and integrate Mayo** — clear the targeted history and pedagogy passes,
   bundle and QA the 20 outstanding audio resources, clear or replace Rockfleet
   imagery, then update the complete-county app copy, integrate the reviewed pack, and
   close accessibility, device, migration, offline, and automated gates.
2. **Reauthor Offaly, Dublin, and Meath** — progress their specialist research in
   parallel, but do not promote or integrate another preview-shaped story before the
   Mayo pattern passes.
3. **Run the four-county internal gate** — automated validators, full tests, timed
   walkthroughs, physical-device and accessibility checks. Schedule external testing
   only after every item passes.
4. **Preserve the Phase 2 test record** — add participant count and moderated-session
   notes if they exist; D20 deliberately does not invent them.

### Lower priority (unchanged)

5. **Personal atlas external release gates** — run the 12–18 person hard-case protocol;
   establish the specialist-reviewed showcase, licensed surname source and community/
   voice agreements before public promotion.
6. **Generate Irish Cultural Guide clips only for cleared text** — do not QA superseded
   D13 copy; native-speaker review remains required for Irish teaching audio. Treat
   Trinity/ABAIR partnership work as a post-launch upgrade.
7. **Illustration production recipe** — atlas registers before Chapter 1–3 scene sets.
8. **TestFlight build** — needs Apple Developer team in `ios/project.yml`.
9. **Send ABAIR commercial enquiry** — optional; draft at `docs/ABAIR-enquiry.md`.
10. **Grant funding research** — Foras na Gaeilge / Údarás strings before accepting (D10).

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
