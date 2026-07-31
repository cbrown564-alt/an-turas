# Scorecard — Construction cluster (freeze step 3)

```text
Cluster: Construction
Fixture files: mayo.clew-bay.build-origin (step 3/9)
  tmp/exercise-screenshots/freeze-run-2026-07-30/03-build-{cold,filled,wrong,complete}.png
Build / commit: uncommitted working tree (base 5174086)
Reviewer (Composer / human): Composer 2.5
Date: 2026-07-30

Scripts: 1P  2P  3P  4P  5~  6~  7~  8P  9P  10P
P0 checklist: clear

D1 Task clarity:        5/5  evidence: 03-build-cold — prompt, as…mé frame, empty track
  and bank dominate within one second; no taxonomy chrome.
D2 One primary:         4/5  evidence: one ink Check in filled/wrong; Continue replaces
  Check on complete — 03-build-complete shows a brief label ghost (“Check the order” under
  “Continue”) but only one bottom slot, not dual ink bars.
D3 In-place repair:     5/5  evidence: 03-build-wrong — failed Check keeps tiles in the
  track and bank placeholders; next tap can reorder without Retry
  (`testFreezeRunWalksAllNineStepsWithRepairsInPlace`).
D4 Finger choreography: 4/5  evidence: tile bank and track sit above the bottom bar;
  tiles ≥44 pt; no far-column scatter.
D5 Feedback locality:   4/5  evidence: 03-build-wrong — “Not quite” names order
  (“Is · as · the place · mé”) in the shell feedback region; track stays editable.
D6 Irish as subject:    5/5  evidence: Irish tokens (Is, as, Maigh Eo, mé.) in story
  serif; English prompt/support in sans (`CountyBuilderSurface.tokenFont`).
D7 Audio honesty:       4/5  evidence: freeze step 3 is text-first build (no audio gate);
  `startsWithAudio` path in builder still offers replay / MissingAudioNotice when authored.
D8 Motion with meaning: 3/5  evidence: tile place/return uses `Motion.settle` when Reduce
  Motion off; no construction Reduce Motion capture this pass (script 6 ~).
D9 Accessibility:       4/5  evidence: per-tile `accessibilityLabel` + “In your answer”
  hint (`CountyBuilderSurface`); container label “Your answer: …”; largest type not
  re-captured for step 3 (script 5 ~); full rotor walk not re-run (script 7 ~).
D10 Distinction:        5/5  evidence: Clew Bay origin frame; limestone shell; no reward
  theatre.

Mean: 4.3/5
Contract gates: Pass (F2)
Verdict: ACCEPT
Required fixes (dimension IDs only): —
```

---

## Scripts (evidence)

| # | Script | Result | Evidence |
|---|---|---|---|
| 1 | Cold open (Jordan) | **Pass** | 03-build-cold: track + bank visible; Check disabled until filled. |
| 2 | Deliberate wrong (Jordan) | **Pass** | 03-build-wrong: tiles editable after failed Check; FreezeRun UI test repairs step 3. |
| 3 | Primary hunt (Casey) | **Pass** | One ink “Check the order”; Continue only after complete. |
| 4 | Thumb reach (Casey) | **Pass** | Bank and bar in lower two-thirds. |
| 5 | Largest type (Sam) | **~** | Not captured for step 3; shell rescore pattern applies. |
| 6 | Reduce Motion (Sam) | **~** | Code nils animation; not visually captured for construction. |
| 7 | VoiceOver states (Sam) | **~** | Per-tile labels in code; rotor walk not re-run. |
| 8 | Audio / mic escape (Jordan) | **Pass** | No audio trap on this fixture step. |
| 9 | Contract gate | **Pass** | F2 (below). |
| 10 | Anti-reference scan | **Pass** | No XP/hearts/confetti. |

## P0 checklist

- [x] Response stays repairable after a wrong answer (no full-board lock).
- [x] Exactly one ink primary per state; Check and Continue share one slot.
- [x] Disabled / secondary controls remain readable (tokenised sunk/stone).
- [x] Missing audio and mic denial never trap progress.
- [x] No hearts, XP, streaks, leagues, confetti, or overdue-debt UI.
- [x] Drag is never the only way to answer.
- [x] Family satisfies its D27 contract row (F2).

## Contract gates

| ID | Gate | Result | One-sentence evidence |
|---|---|---|---|
| F2 | Sentence construction | **Pass** | Multi-part Check; Irish serif tiles editable until Check; bank placeholders preserve layout; correct work survives a failed Check (`03-build-wrong`). |

## Residual notes (not blockers)

- D2/D9: bar label ghost on Continue transition in `03-build-complete` — polish only.
- D8: capture Reduce Motion tile snap for construction in a later pass.

## Screenshot index

| File | State |
|---|---|
| `tmp/exercise-screenshots/freeze-run-2026-07-30/03-build-cold.png` | Cold open |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/03-build-filled.png` | Filled, Check enabled |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/03-build-wrong.png` | Failed Check, editable |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/03-build-complete.png` | Complete |
