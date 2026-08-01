# Scorecard — D30 *farraige* B (surround-change construction)

```text
Cluster: Construction (phrase-family B proof)
Fixture files: mayo.farraige-family-b / mayo.farraige-family.build-sea-here
  tmp/exercise-screenshots/farraige-family-b-2026-08-01/01-build-{cold,filled,wrong,complete,cold-dark,cold-a11y}.png
Build / commit: uncommitted working tree
Reviewer (Composer / human): human (owner agent walk + screenshots)
Date: 2026-08-01

Scripts: 1P  2P  3P  4P  5~  6~  7~  8P  9P  10P
P0 checklist: clear

D1 Task clarity:        5/5  evidence: 01-build-cold — “Keep farraige” + English target
  “The sea is here.” + Listen object; bank and empty tray readable in one second.
D2 One primary:         5/5  evidence: disabled Check cold; ink Check filled/wrong;
  Continue-style “Complete this chapter path” on complete — one bottom slot.
D3 In-place repair:     5/5  evidence: 01-build-wrong keeps tiles editable; UI test
  repairs without Retry (`testSurroundChangeWalksWrongThenComplete`).
D4 Finger choreography: 4/5  evidence: Listen, tray, bank, bar stack above thumb zone;
  tiles ≥44 pt; no far-column scatter.
D5 Feedback locality:   4/5  evidence: 01-build-wrong — “Not quite” + recovery that names
  the heard ship surround vs location build; tiles stay in tray.
D6 Irish as subject:    5/5  evidence: Irish serif tiles (Tá / an / fharraige / anseo.);
  English target and chrome in sans.
D7 Audio honesty:       5/5  evidence: Check stays disabled until Listen plays
  (asserted in UI test); cold shows Éist; filled/wrong show Éist arís + Slow;
  ship audioText ≠ build answer.
D8 Motion with meaning: 3/5  evidence: shared builder settle; no Reduce Motion capture
  this pass (script 6 ~).
D9 Accessibility:       4/5  evidence: cold-a11y launched at XXXL content size; per-tile
  labels inherited from CountyBuilderSurface; full VoiceOver rotor not re-run (script 7 ~).
D10 Distinction:        5/5  evidence: Clew Bay farraige family; success copy “Same lexeme,
  new surround”; limestone shell; no reward theatre.

Mean: 4.5/5
Contract gates: Pass (F2 + D30 B surround-change)
Verdict: ACCEPT
Required fixes (dimension IDs only): —
```

---

## Scripts (evidence)

| # | Script | Result | Evidence |
|---|---|---|---|
| 1 | Cold open (Jordan) | **Pass** | 01-build-cold: Listen + empty tray + bank; Check disabled. |
| 2 | Deliberate wrong (Jordan) | **Pass** | 01-build-wrong: wrong order editable; recovery names ship vs location. |
| 3 | Primary hunt (Casey) | **Pass** | One ink Check; Complete replaces it after success. |
| 4 | Thumb reach (Casey) | **Pass** | Bank and bar in lower two-thirds. |
| 5 | Largest type (Sam) | **~** | 01-build-cold-a11y captured; not a full reflow audit. |
| 6 | Reduce Motion (Sam) | **~** | Shared builder; not visually captured for B. |
| 7 | VoiceOver states (Sam) | **~** | Per-tile labels in code; rotor walk not re-run. |
| 8 | Audio / mic escape (Jordan) | **Pass** | Audio-first gate; bundled ship clip; no mic path. |
| 9 | Contract gate | **Pass** | F2 + D30 B (below). |
| 10 | Anti-reference scan | **Pass** | No XP/hearts/confetti. |

## P0 checklist

- [x] Response stays repairable after a wrong answer (no full-board lock).
- [x] Exactly one ink primary per state; Check and Continue share one slot.
- [x] Disabled / secondary controls remain readable (tokenised sunk/stone).
- [x] Missing audio and mic denial never trap progress.
- [x] No hearts, XP, streaks, leagues, confetti, or overdue-debt UI.
- [x] Drag is never the only way to answer.
- [x] Family satisfies its D27 contract row (F2) and D30 B surround-change proof.

## Contract gates

| ID | Gate | Result | One-sentence evidence |
|---|---|---|---|
| F2 | Sentence construction | **Pass** | Multi-part Check; Irish serif tiles editable until Check; audio-first readiness; wrong→repair→complete UI test. |
| D30-B | Surround-change construction | **Pass** | Hear `Tá an long ar an bhfarraige.` then build distinct `Tá an fharraige anseo.`; success feedback states same lexeme / new surround. |

## Residual notes (not blockers)

- Authored `replay-ship-line` misconception cannot fire from construction tiles alone (bank is answer-only; no ship-line distractors). Wrong-order path uses recovery copy that still teaches the surround change. Defer distractor-bank work to foundation / densify if needed.
- Pedagogue + native audio QA remain open; this ACCEPT is craft/coherence only — no teaching claims, no production promotion.
- Pattern C (delayed reuse) stays parked until this ACCEPT is recorded.

## Screenshot index

| File | State |
|---|---|
| `tmp/exercise-screenshots/farraige-family-b-2026-08-01/01-build-cold.png` | Cold open |
| `tmp/exercise-screenshots/farraige-family-b-2026-08-01/01-build-filled.png` | Heard + filled, Check enabled |
| `tmp/exercise-screenshots/farraige-family-b-2026-08-01/01-build-wrong.png` | Failed Check, editable |
| `tmp/exercise-screenshots/farraige-family-b-2026-08-01/01-build-complete.png` | Complete |
| `tmp/exercise-screenshots/farraige-family-b-2026-08-01/01-build-cold-dark.png` | Cold, dark |
| `tmp/exercise-screenshots/farraige-family-b-2026-08-01/01-build-cold-a11y.png` | Cold, XXXL Dynamic Type |

## Verification

- Unit: `CountyFarraigeFamilyBFixtureTests` — 2/2 pass
- UI: `FarraigeFamilyBUITests` — 2/2 pass on iPhone 17 Pro
  (`testSurroundChangeWalksWrongThenComplete`, `testSurroundChangeColdDarkAndLargestType`)
