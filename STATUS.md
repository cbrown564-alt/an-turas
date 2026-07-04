# STATUS

*Project: An Turas (working title) — iOS app teaching Irish through history, culture,
and visual narrative. English → Irish only. Updated 2026-07-04.*

## Where we are

**Phase 1 — vertical slice.** Strategy is set, first content chapter is written, the
HTML prototype validated the core ideas, and the SwiftUI port is running on the iOS
simulator. Next: playtesters.

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

## Immediate next steps

1. **TestFlight build** — the SwiftUI prototype runs on simulator; next is a signed
   device build + TestFlight distribution so playtesters hold the real thing.
   (Needs an Apple Developer account/team set in `ios/project.yml`.)
2. **Native-speaker review** of all Chapter 1 Irish (forms currently conservative
   Connacht-leaning drafts; specific open calls flagged, e.g. *Cé thusa?* vs *Cé
   tusa?*). Blocker for testing beyond friendly audiences.
3. **TTS bake-off** — generate Chapter 1's 21 lines (manifest at
   `ios/AnTuras/Resources/Audio/manifest.json`) with ABAIR Conamara voices (web
   demo — evaluation only, output must not be bundled before written consent),
   ElevenLabs (`.env` key present; Irish-accent voices + eleven_v3), and
   gemini-3-flash (often beat ElevenLabs in CB's standard tests). Pick per-line
   winners, drop clips into `Resources/Audio/` — every ear in the app opens
   automatically. Note: **iOS has no ga-IE system voice**, so bundled clips are
   the only real path. Then send the ABAIR commercial enquiry (`docs/ABAIR.md`).
4. **Recruit 10–20 playtesters** from target personas (r/gaeilge, Irish-language
   Discords, a Conradh na Gaeilge branch, diaspora groups). The one question:
   *did anything pull you back for session two?* (The slice now has three
   return mechanics to measure: recarve pages, amárach hooks, tá-tú-ar-ais.)

## Long-term plan

- **Phase 1 — Vertical slice (now):** SwiftUI Chapter 1, playtest, measure narrative
  pull vs. drop-off. Exit criterion: testers return without streaks and can say why.
- **Phase 2 — Content pipeline:** authoring format + editorial board (Irish-language
  pedagogue + historian per chapter); audio strategy settled (ABAIR agreement or
  hybrid human/TTS); illustration style locked; Chapter 2 (monastic scriptorium)
  produced through the pipeline as its proof.
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
- Audio: provider bake-off pending (ABAIR vs ElevenLabs vs gemini-3-flash) for
  scratch clips; ABAIR terms unknown until they respond; hybrid human/TTS assumed
  long-term. No iOS system voice exists for Irish — bundled clips are the path.
- Frame device carrying the learner between eras (SPINE.md, open creative question).
- Business model timing: freemium subscription assumed; grant-funding strings to be
  understood before accepting (U6).

## Risks watchlist

- **blas.** is shipping fast in the same waters (rigour angle); our differentiation
  is narrative/identity — window is now.
- Content accuracy: nothing ships publicly without native-speaker review.
- ABAIR dependency: if bundling rights stall, Phase 2 audio falls back to
  human-recorded narrative + Azure `ga-IE` for exercises (docs/ABAIR.md).
