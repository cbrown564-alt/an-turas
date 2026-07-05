# STATUS

*Project: An Turas (working title) — iOS app teaching Irish through history, culture,
and visual narrative. English → Irish only. Updated 2026-07-05.*

## Where we are

**Phase 1 — vertical slice.** Strategy is set, first content chapter is written, the
HTML prototype validated the core ideas, and the SwiftUI port is running on the iOS
simulator. Audio and writing are in active experiment; **illustrations join the same
wave for Chapter 1** — the slice needs the full visual + audio + text view before
playtesters see it. Next: illustration exploration, then playtesters.

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
| 2026-07-05 | **The big picture built** — three surfaces from the Seventh Way futures shelf, answering playtester feedback ("intrigued by ch. 1 but where is this going?"). (1) *An Turas, the journey map*: the island of Ireland drawn in the carved-limestone language (Natural Earth 50m coastline → 241-point Swift shape, whole island per D1), the 13 spine chapters as numbered waypoints through place *and* time — Cill Ala c. 480 → Béal Feirste inniu; chalk-before-carve extended to the course (road behind carved in moss, one clear chalk leg ahead, faintest thread beyond); *tá tú anseo* pulse; every waypoint opens an era card (hook, payload, artifact) from new `journey.json`; ch. 1's card opens the chonair. Cover → journey → chonair → session is the new spine of the app. (2) *An Músaem*: 13 niches, one line-drawn glyph per artifact, ch. 1's ogham stone unlocks on completion (opens the existing share flow); locked niches are chalk-dashed with era cards; a rust dot means an artifact's people are asking. (3) *Ar Ais*: authored visits in chapter1.json (Dáire, Bríd, an bhaintreach, an chloch féin — 7 across the 5 sessions), FSRS-lite scheduler faoin gcraiceann (due +1 day on session end, ×2.5 on clean recall, reset on struggle, persisted; migration schedules visits for sessions done before the feature existed), queue dressed as people asking (*Tá beirt ag fiafraí fút*, N lá ó shin), answered with the recarve mechanic incl. ismise/isas pattern checks; never a card count. Returning learners land on the journey when someone is asking, else on the chonair. Debug args: `--journey --museum --arais --due N --card N`. All verified light + dark on iPhone 17 Pro sim | `ios/AnTuras/` (JourneyView, MuseumView, ArAisView, IrelandShape, ChapterCard new; AppState, Models, AnTurasApp, MapView; Resources/journey.json; chapter1.json visits) |
| 2026-07-05 | **Journey map review pass:** thread visibility, label placement, and copy quick wins, then two follow-ups. (1) Chapter 9's place name carried a stray year ("Baile Átha Cliath, 1893") no other chapter has — dropped, era range already covers it. (2) Waypoint tap targets were sized off the label's 170pt frame rather than the marker, scaled 3.2×, giving each waypoint a ~500pt-wide invisible hit region that could steal taps meant for a neighbour; replaced per-marker tap gestures with one nearest-waypoint gesture over the whole map, so density (Dubhlinn and an lá inniu render ~14pt apart) can no longer mis-resolve a tap. (3) Added a time axis strip below the map — the route is chaotic in space but linear in time, and the map alone couldn't carry that; 13 evenly-spaced ticks (not calendar-proportional — chapters 8–13 would crowd the last tenth of a real timeline) in the same moss/chalk depths as the road, endpoints and current era captioned, each tap-through to its chapter card | `ios/AnTuras/JourneyView.swift`, `Resources/journey.json` |

## Immediate next steps

1. **Install Gemini 3.1 TTS clips** — set `bundle_winner: gemini-3-flash` per line in
   `tools/tts-bakeoff/winners.json`, run `python bakeoff.py install`, regenerate Xcode
   project. Ears open across Chapter 1.
2. **Illustration exploration (Chapter 1)** — run style tests in parallel with audio
   and writing so the vertical slice shows the full experience: scene pages, beats,
   and the ogham world with real art, not placeholders. Goal: enough coverage to judge
   whether the visual identity carries the narrative (STRATEGY.md Phase 1 criterion).
   Lock a direction here; Phase 2 scales it through the pipeline. Plan of record:
   `docs/ILLUSTRATIONS.md` (wide fan Day 1, deep pass Day 2, then canonical → D4).
3. **TestFlight build** — signed device build + TestFlight once audio is installed and
   Chapter 1 illustration direction is far enough along to represent the product.
   Needs Apple Developer account/team in `ios/project.yml`.
4. **Azure `ga-IE` bake-off (follow-up)** — add Orla/Colm to the pipeline; compare
   against Gemini 3.1 on fada pairs and full chapter (`docs/TTS-research.md`).
5. **Native-speaker review** of Chapter 1 Irish text and TTS clips — blocker for
   testing beyond friendly audiences.
6. **Send ABAIR commercial enquiry** — draft at `docs/ABAIR-enquiry.md`.
7. **Recruit 10–20 playtesters** from target personas (r/gaeilge, Irish-language
   Discords, a Conradh na Gaeilge branch, diaspora groups). The one question:
   *did anything pull you back for session two?* (The slice now has four
   return mechanics to measure: recarve pages, amárach hooks, tá-tú-ar-ais,
   and Ar Ais visits — plus the journey map for the "where is this going?"
   question earlier viewers kept asking.)

## Long-term plan

- **Phase 1 — Vertical slice (now):** SwiftUI Chapter 1 with **writing, audio, and
  illustrations explored together** — the app lives or dies on visual identity, so the
  playtest must see the full picture, not text + ears alone. Playtest, measure narrative
  pull vs. drop-off. Exit criterion: testers return without streaks and can say why.
- **Phase 2 — Content pipeline:** authoring format + editorial board (Irish-language
  pedagogue + historian per chapter); audio strategy settled (ABAIR agreement or
  hybrid human/TTS); illustration style locked from Phase 1 experiments; Chapter 2
  (monastic scriptorium) produced through the pipeline as its proof.
- **Phase 3 — Product build:** full iOS app (offline-first chapter packs, FSRS
  spaced repetition dressed as revisiting, músaem/artifact collection, TEG-aligned
  progress). Chapters 1–4 at launch quality.
- **Phase 4 — Launch:** soft-launch to diaspora + re-learners; align moments with
  the real Irish calendar (Seachtain na Gaeilge, St Patrick's Day). Grant funding
  conversations (Foras na Gaeilge / Údarás) run in parallel from Phase 2.
- **Phase 5 — NI expansion:** gated on Ulster dialect audio (D2) and community
  relationships (Turas, Glór na Móna); chapters 10–12 carry the editorial weight.

## Open questions being carried

- Retention mechanic beyond narrative pull (STRATEGY.md U3) — the playtest exists to
  answer this; recarve/hooks/return-greeting are now in the slice to be measured.
- Audio: **Gemini 3.1 Flash TTS** for playtest clips; **Azure `ga-IE`** follow-up
  bake-off; **ABAIR** licensing for long-term dialect fidelity. ElevenLabs and
  Gemini 2.5 rejected on pronunciation (`docs/TTS-research.md`).
- Illustration: style and coverage for Chapter 1 scenes — in active exploration this
  phase; must be far enough along for playtesters to judge narrative pull, not just
  mechanics (`docs/STRATEGY.md` Phase 1; exploration framed in `docs/ILLUSTRATIONS.md`).
- Frame device carrying the learner between eras (SPINE.md, open creative question).
- Business model timing: freemium subscription assumed; grant-funding strings to be
  understood before accepting (U6).

## Risks watchlist

- **blas.** is shipping fast in the same waters (rigour angle); our differentiation
  is narrative/identity — window is now.
- Content accuracy: nothing ships publicly without native-speaker review.
- ABAIR dependency: if bundling rights stall, Phase 2 audio falls back to
  human-recorded narrative + Azure `ga-IE` for exercises (docs/ABAIR.md).
