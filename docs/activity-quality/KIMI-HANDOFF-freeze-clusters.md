# Kimi handoff — D29 freeze-run clusters A–G

*Design/IX implementation record for the frozen representative Mayo run.
2026-07-30. For Composer (cluster scorecards) and Grok (coherence review).*

## Base and commits

- Working tree on top of `5174086` (uncommitted; the quality owner's D29 freeze
  record — `MAYO-REPRESENTATIVE-RUN-FREEZE.md`, D29 in `DECISIONS.md`, index —
  was already uncommitted in this tree and remains so).
- Nothing was committed by Design/IX; review the diff as one unit. No pushes.
- Fixture boundary held: `content/mayo/grainne-1593.pack.draft.json` and the
  bundled Rockfleet pack are byte-untouched; no InteractionStudies code returned.

## What landed, per cluster

| Cluster | Freeze step(s) | What changed | Dimensions / contracts |
|---|---|---|---|
| A Choice | 1, 7 | Step 1 prompt aligned with the ungated board ("you can answer whenever you are ready"). Step 7 authors F6 read-or-listen: new `CountyReadRespondSurface` — reading card (English note sans), Irish line serif via `sentenceTemplate`, authored listen variant with replay + visible text/meaning route; missing audio degrades to the notice, never traps | D1 D6 D7, F1 F6 |
| B Construction | 3 | Track tiles now carry per-tile VoiceOver labels ("as", hint "In your answer…") instead of every tile inheriting the container's "Your answer" label — found via UI test failure. Tiles serif (Irish target), editable until Check, correct work survives a failed Check | D3 D6 D9, F2 |
| C Matching | 2 | Polish only — surface unchanged from Shell ACCEPT; three-pair freeze board exercised in the run | D3 D4 D5, F5 |
| D Typing | 4 | New `mayo.clew-bay.type-origin` — unsupported production (no tiles, no model replay); native field serif, English translation sans, fada row + keyboard toolbar, one ink Check | D2 D3 D6, F3 |
| E Speaking | 6 | New `mayo.clew-bay.speak-origin` on the ACCEPT shell: Record/Stop owns ink, ghosts for model/playback, quiet escape; mic-denied escape becomes the primary | D2 D7, F7 |
| F Conversation | 5 | **Hard gate, landed.** `CountyConversationGraph` payload (finite nodes, `present-day` setting, fitting/misfit replies) + `CountyConversationEngine` (pure walk) + `CountyConversationGraphSurface` (living transcript; misfit shows diagnostic on that turn and never advances; fitting branch joins the transcript). Opens *Cárb as tú?*; origin line is the fitting answer; turn-2 branch (*Is mise …* vs *Cé thusa?*) changes the turn-3 partner line; every fitting reply persists `CountyConversationState` so relaunch resumes at the exact node with transcript intact. Graph validated in Swift and Python validators. Legacy thin MC conversations (Rockfleet, drafts) still render via the old surface | C1; D1 D3 D5 D9 |
| G Consolidation | 8, 9 | **C5** `CountyCompletionSurface`: three authored capabilities, fixture word handoff with explicit boundary note, single flourish, no points theatre; `recordFixtureCollection` keeps words in a fixture-scoped store (no gold, no scheduler). **C3** `CountyContextualReviewSurface`: the run's struggle record (D27 events — repair window closing or failed Check) deterministically selects an authored candidate; the learner re-enters from the original sound/sentence with the original response method (choice re-uses `CountyListenChoiceSurface`, typed re-uses `CountyTypingSurface`) | C3 C5; D3 D8 D10 |
| Run scaffolding | — | `--freeze-run` debug route (plus `--page`, `--fresh-county-pack`, `--completed-page`); fixture pack decoded from `Resources/Fixtures/` outside the production catalog and twenty-word gate; conversation pages land on the current turn when restored (bottom-scroll); completion family carries the run's one flourish | D26 anatomy intact |

## New fixture ids

Pack: `mayo.clew-bay-freeze` (`ios/AnTuras/Resources/Fixtures/mayo.clew-bay-freeze.json`,
scope `editorialPreview`, 4 headwords, `enforceLearningQuality: false`).
Steps: `mayo.clew-bay.listen-farraige` · `match-coast` · `build-origin` ·
`type-origin` · `conversation-origin` · `speak-origin` · `comprehend-coast` ·
`completion` · `review-struggle`.

**Launch the run:** simulator/debug launch args `--freeze-run`
(goes straight into Learning step 1). Add `--page <id>` to land mid-run,
`--fresh-county-pack` to reset fixture state, `--microphone-denied` for the
step-6 escape path, `--transient-test-state` to suppress persistence.

## Test results (iPhone 17 Pro simulator, iOS 26)

| Suite | Command | Result |
|---|---|---|
| Swift unit (56) | `xcodebuild test -scheme AnTuras -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:AnTurasTests` | **56/56 pass** — incl. 14 new `CountyFreezeRunTests` (fixture structure, C1 graph walk + branch + resume round-trip, C3 deterministic targeting, struggle record, C5 isolation, JSON persistence) |
| Swift UI (32) | same scheme, `-only-testing:AnTurasUITests` | **32/32 pass** — 5 new `FreezeRunUITests` (nine-step walk with wrong→repair→complete on steps 1–4, misfit repair + branch + double relaunch resume, mic-denied escape, record/compare, review default, AX5 conversation), 7 capture + 1 Reduce Motion capture tests, 19 pre-existing |
| Python (51) | `python3 -m unittest discover -s tools/tests` | **51/51 pass** — incl. 6 new `ContainerPayloadRules` (valid graph passes; dangling next, missing setting, bare exchange rejected; C5/C3 payload gates) |

Verification notes: the nine-step walk deliberately wrongs steps 1–4 and repairs
in place; the resume test relaunches twice and asserts transcript + current node;
fixture completion asserts no gold/artifact/scheduled reviews (unit) and the
boundary copy (UI). Largest Dynamic Type (AX5) exercised on conversation and
typing; dark appearance captured on listen/conversation/review; Reduce Motion
peer states captured on conversation and matching.

## Screenshots

`tmp/exercise-screenshots/freeze-run-2026-07-30/` — 39 PNGs (iPhone 17 Pro):
- `01-listen-{cold,cold-dark,wrong,struggle,complete}` — cold-open answerable board; on-row rationale; "Not quite" only after the repair window closes
- `02-match-{cold,word-selected,wrong-note,complete,pair-locked-reduce-motion}` — selected word (moss + dot, not tint-only); brief on-target note; unlock on next tap
- `03-build-{cold,filled,wrong,complete}` — serif tiles; stable bank placeholders; failed Check keeps the track
- `04-type-{cold,filled,wrong,complete,a11y}` — serif Irish input, sans translation, fada row; AX5 coherent
- `05-conversation-{cold,cold-dark,misfit,turn-two,branch,complete,a11y,turn-two-reduce-motion}` — transcript, on-turn diagnostic, branch's changed partner line
- `06-speak-{cold,recorded,complete,mic-denied}` — one ink Record; escape promoted to ink when denied
- `07-comprehend-{cold,wrong,complete}` — read card + listen variant
- `08-completion-{top,collection}` — capabilities + fixture collection handoff
- `09-review-{cold,cold-dark,complete}` — context card with original sound + replay, then the original task

## What Composer should focus on

- **F (C1) is the scorecard that matters.** Verify: turn graph vs "bare MC list";
  misfit diagnostic stays on the turn; branch changes a later partner line;
  resume after backgrounding (the UI test does two relaunches); present-day
  setting copy. Note *Cárb as tú?* has no bundled clip (text-only line, honest
  by D7 since conversation is production, not a listening family); every other
  Irish line in the graph has bundled audio.
- **C3 default-vs-struggled copy.** With no recorded struggle the review says
  "Nothing slipped on this run…" — check this reads as honesty, not theatre.
- **C5 flourish.** The completion container carries the run's single
  `Haptics.flourish`; steps 1–7 keep the soft chisel per item (freeze table).
- **Conversation bottom-scroll.** Restored mid-graph conversations now land on
  the current turn; in-session advances rely on normal scrolling. Watch for any
  over-scroll on very long transcripts (not reachable with this graph).
- **F1 prompt copy** ("you can answer whenever you are ready") — residual D1
  note from the shell rescore, addressed in the fixture only.
- D8/D9 residuals from the shell rescore were run here: Reduce Motion captured
  on conversation + matching; builder track tiles are now individually named
  for VoiceOver. Full VoiceOver rotor walk remains for the scorecard pass.

## Known gaps (not blockers)

- Grammar (F8), Greenfield (F9/F10), C2, C4 remain parked per the freeze.
- Production packs still author the legacy thin-MC conversation; migration to
  the graph is migration group 3 (the fixture is the acceptance proof).
- The fixture pack is intentionally outside the production validator's
  twenty-word county gate (4 headwords); its structural gate is the Swift unit
  test `CountyFreezeRunTests` plus the conversation-graph rules mirrored in both
  validators.
- `delayedRecall` in production packs is still plain later-page retrieval; C3
  wiring to scheduler-owned mistake review is group 4.
