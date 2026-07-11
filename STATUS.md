# STATUS

*Project: An Turas (working title) — iOS app teaching Irish through history, culture,
and visual narrative. English → Irish only. Updated 2026-07-11.*

## Where we are

**Phase 2 — story reset and living-atlas proof.** Phase 1 exit
criteria met (D5): playtest feedback strongly positive; testers return without streaks
and name **tá tú ar ais** and the **journey map** as pull mechanisms. Re-learners feel
respected, the grammar ladder reads as intentional, and the journey map answers
direction. D12 now makes that direction concrete: the learner journeys through all
**32 counties**, each rooted in a named person, myth, monument, community, or primary
record, and earns **20 useful words per county** from a significant reading or
encounter. The map's county colours are a product promise: current green, completed
gold, still-ahead white.

**The existing pipeline ran twice more and the app went multi-chapter.** Chapters 2
(*Oileán na Naomh*) and 3 (*Na Lochlannaigh*) are both authored through the three-stage
pipeline and wired into the app — each with its own artifact register (illuminated
initial; hack-silver arm-ring) and cross-chapter progress/visits persistence. Both
passed adversarial review as engineering and pipeline proofs. D13 now supersedes their
editorial centres before human sign-off, release audio, or final illustration.

**The immediate transformation is now explicit.** The next product is a living
historical atlas, not the inherited lesson path placed on a county map. Mayo opens
with Gráinne's 1593 petition; Offaly and Dublin centre real evidence from c. 900 and
c. 997; Breastagh becomes a labelled field note. The approved first design proof is a
restrained island → Rockfleet → Gráinne → 1593 letter → first Irish → island loop.
It validates the foundation, not the full story or broader atlas architecture. The
first product grilling has now fixed the county, episode, learner-action, 20-word,
evidence, collection, artifact, grammar, and post-county contracts. The next phase
stress-tests Gráinne's broader life against that contract before more tester rounds.

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

## Immediate next steps (Phase 2)

1. **Stress-test Gráinne as Mayo's complete flagship** — research and storyboard her
   broader life around the 1593 organising centre; test for sufficient sourced
   narrative depth and meaningful ground for the exact 20-word lifecycle. Add a side
   story only for a demonstrated gap (`docs/GRAINNE-PRODUCT-CONTRACT.md`).
2. **Build the full-story narrative spine** — create a source-backed storyboard of
   four to six movements, each mapping historical change, human stake, evidence,
   Irish earned, and learner action. D15 fixes 1593 as the organising centre of a
   broader life story.
3. **Design the language weave and evidence ladder** — place each Irish item at a
   dramatic need and later reuse; give each source a learner view, optional close
   reading, and editorial depth. Keep caveats, rights state, and taxonomies off the
   narrative surface.
4. **Low-fidelity product review before implementation** — storyboard pacing,
   interactions, episode exits, and return moments. Gate on emotional pull, clear
   understanding of Gráinne, meaningful Irish, and learner orientation before
   extending the approved prototype.
5. **Next tester round: the complete story arc** — test depth and continuity, not
   additional atlas breadth. Do not return to testers until the product questions,
   source spine, and internal gates above are resolved.
6. **Replacement source briefs for Mayo, Offaly, and Dublin** — build historian-ready
   packets for Gráinne's 1593 petition, the Cross of the Scriptures c. 900, and
   Sihtric's first penny c. 997. Each needs a claim ledger, rights plan, significant
   reading/object encounter, and 20-word language plan before new JSON is drafted.
7. **Clean-slate review of Meath / Trim** — test Hugh de Lacy and Trim against the
   same county claim, significance, narrative, evidence, language-yield, and afterlife
   criteria before confirming the fourth launch story.
8. **Content review CMS** — purpose-built review UI for the county-story schema (D9,
   D12). Stakeholders: writer, Irish-language pedagogue, historian, audio QA. Workflow:
   county/source brief → draft → linguist → historian → generate audio → native QA →
   sign-off → bundle.
9. **Editorial board** — recruit at minimum one qualified Irish-language pedagogue
   and one historian. Their immediate work shifts from clearing inherited composites
   to delimiting the replacement source briefs and deciding what can be reused.
10. **Legacy-content salvage map** — inventory interactions, exercises, artifacts,
   vocabulary, illustrations, and progress state from Chapters 1–3 as retain, adapt,
   field-note, or retire before replacement content changes story ids.
11. **Install Gemini 3.1 TTS clips only for cleared text** — set `bundle_winner: gemini-3-flash` per line in
   `tools/tts-bakeoff/winners.json`, run `python bakeoff.py install`, regenerate Xcode
   project. Do not spend release QA on narrative copy D13 has superseded.
12. **Illustration production recipe** — evolve Solas an Atlantaigh into one layer of
   the atlas beside maps, portraits, documentary sources, object drawings, and
   present-day landscapes. Do not commission final Chapter 1–3 scene sets until the
   new registers are prototyped.
13. **TestFlight build** — signed device build for wider playtest; needs Apple Developer
   account/team in `ios/project.yml`.
14. **Send ABAIR commercial enquiry** — optional long-term dialect upgrade; not a
   Phase 2 blocker (D7). Draft at `docs/ABAIR-enquiry.md`.
15. **Grant funding research** — map Foras na Gaeilge / Údarás schemes and strings
   before accepting (D10: grants on top of premium, not instead of).

## Long-term plan

- **Phase 1 — Vertical slice (complete):** Chapter 1 SwiftUI app with writing, audio,
  and illustrations. Playtest validated narrative pull without streaks; tá tú ar ais and
  the journey map named as return mechanisms. Exit criterion met (D5).
- **Phase 2 — Story contract + atlas proof (now):** approved Gráinne first-encounter
  foundation; resolve the full-story product questions; build the source-backed
  narrative spine, language weave, and evidence ladder; then extend the prototype and
  return to testers. Replacement source briefs, clean-slate Meath review, and legacy
  progress preservation continue behind that gate.
- **Phase 3 — Product build:** living historical atlas, county dossiers, documentary
  story registers, evidence collection, personal artifacts, FSRS dressed as revisiting,
  TEG-aligned progress, and **An Féilire** rituals. Target the first four replacement
  county stories at launch quality only after the prototype validates the vessel.
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
- **ABAIR upgrade path** — pursue if bundling rights granted; Gemini is production
  baseline (D7).

## Resolved (Phase 1 → 2)

| Unknown | Resolution |
|---|---|
| U1 Persona | D1 — re-learners + diaspora; NI north star |
| U2 Dialect | D2 — Connacht first |
| U3 Retention loop | D5/D6 — narrative pull (tá tú ar ais, journey map) + An Féilire rituals |
| U5 Audio strategy | D7 — Gemini all-generated with native-speaker QA |
| U6 Business model | D10 — premium + grants on top; Ch 1–4 launch; bespoke |
| U8 Pronunciation | D11 — listening-first permanent; echo ungraded |

## Risks watchlist

- **blas.** is shipping fast in the same waters (rigour angle); our differentiation
  is narrative/identity — window is now.
- Content accuracy: nothing ships publicly without native-speaker review.
- Bespoke content cost per chapter remains the business-model risk; four chapters at
  launch is depth-over-breadth by design (D10).
- The new interface could become an attractive historical browser that weakens the
  language journey. Every prototype must prove that real evidence makes the Irish
  more memorable and usable, not merely that the atlas is enjoyable to browse.
- Source access and rights now gate story shape earlier: petitions, coins, crosses,
  recordings, portraits, and maps need claim-level provenance before final UI and art.
- Legacy progress, artifacts, and review schedules must survive replacement story ids;
  editorial courage cannot become destructive migration.
