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

## Immediate next steps

1. **TestFlight build** — the SwiftUI prototype runs on simulator; next is a signed
   device build + TestFlight distribution so playtesters hold the real thing.
   (Needs an Apple Developer account/team set in `ios/project.yml`.)
2. **Native-speaker review** of all Chapter 1 Irish (forms currently conservative
   Connacht-leaning drafts; specific open calls flagged, e.g. *Cé thusa?* vs *Cé
   tusa?*). Blocker for testing beyond friendly audiences.
3. **ABAIR technical evaluation** — run the Chapter 1 script through their Conamara
   voices (free, no permission needed), then send the one-page commercial enquiry
   (`docs/ABAIR.md` steps 1–2).
4. **Recruit 10–20 playtesters** from target personas (r/gaeilge, Irish-language
   Discords, a Conradh na Gaeilge branch, diaspora groups). The one question:
   *did anything pull you back for session two?*

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
  answer this.
- Audio: ABAIR terms unknown until they respond; hybrid human/TTS assumed.
- Frame device carrying the learner between eras (SPINE.md, open creative question).
- Business model timing: freemium subscription assumed; grant-funding strings to be
  understood before accepting (U6).

## Risks watchlist

- **blas.** is shipping fast in the same waters (rigour angle); our differentiation
  is narrative/identity — window is now.
- Content accuracy: nothing ships publicly without native-speaker review.
- ABAIR dependency: if bundling rights stall, Phase 2 audio falls back to
  human-recorded narrative + Azure `ga-IE` for exercises (docs/ABAIR.md).
