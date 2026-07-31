# Scorecard — Typing cluster (freeze step 4)

```text
Cluster: Typing
Fixture files: mayo.clew-bay.type-origin (step 4/9)
  tmp/exercise-screenshots/freeze-run-2026-07-30/04-type-{cold,filled,wrong,complete,a11y}.png
Build / commit: uncommitted working tree (base 5174086)
Reviewer (Composer / human): Composer 2.5
Date: 2026-07-30

Scripts: 1P  2P  3P  4P  5P  6~  7~  8P  9P  10P
P0 checklist: clear

D1 Task clarity:        5/5  evidence: 04-type-cold — “Type the origin line without tiles”,
  English gloss, and serif field dominate; unsupported production stated plainly.
D2 One primary:         5/5  evidence: one ink “Check the sentence”; keyboard toolbar
  Check is secondary chrome, not a second ink bar (`CountyTypingSurface`).
D3 In-place repair:     4/5  evidence: 04-type-wrong — field stays editable after wrong
  Check (me without fada); FreezeRun UI test wrongs and repairs step 4 in place.
D4 Finger choreography: 4/5  evidence: field and fada row above bottom bar; fada chips
  and Check reachable with keyboard up.
D5 Feedback locality:   4/5  evidence: wrong Check carries field-level verdict in shell
  feedback (fada/frame diagnostic); field text preserved.
D6 Irish as subject:    5/5  evidence: 04-type-filled/complete — Irish input in story
  serif; English translation in sans headline (`CountyTypingSurface`).
D7 Audio honesty:       4/5  evidence: no model replay by design (“no tiles, no model
  replay”); honest unsupported production — progress never gated on audio.
D8 Motion with meaning: 3/5  evidence: no decorative celebration; Reduce Motion not
  captured for typing (script 6 ~).
D9 Accessibility:       4/5  evidence: 04-type-a11y — largest Dynamic Type keeps task,
  field, fada row, and bar action coherent; `irish-answer-field` identifier; full
  VoiceOver rotor not re-run (script 7 ~).
D10 Distinction:        5/5  evidence: scaffold removal from step 3 tiles; Clew Bay
  origin line; no gamification.

Mean: 4.3/5
Contract gates: Pass (F3)
Verdict: ACCEPT
Required fixes (dimension IDs only): —
```

---

## Scripts (evidence)

| # | Script | Result | Evidence |
|---|---|---|---|
| 1 | Cold open (Jordan) | **Pass** | 04-type-cold: field and prompt visible immediately. |
| 2 | Deliberate wrong (Jordan) | **Pass** | FreezeRun UI test wrongs step 4 and repairs without Retry. |
| 3 | Primary hunt (Casey) | **Pass** | Single ink Check in bottom slot. |
| 4 | Thumb reach (Casey) | **Pass** | Field and fada row in lower half when keyboard dismissed. |
| 5 | Largest type (Sam) | **Pass** | 04-type-a11y capture. |
| 6 | Reduce Motion (Sam) | **~** | Not visually captured for typing. |
| 7 | VoiceOver states (Sam) | **~** | Field label in code; rotor walk not re-run. |
| 8 | Audio / mic escape (Jordan) | **Pass** | No audio trap. |
| 9 | Contract gate | **Pass** | F3 (below). |
| 10 | Anti-reference scan | **Pass** | No reward theatre. |

## P0 checklist

- [x] Response stays repairable after a wrong answer (no full-board lock).
- [x] Exactly one ink primary per state; Check and Continue share one slot.
- [x] Disabled / secondary controls remain readable.
- [x] Missing audio and mic denial never trap progress.
- [x] No hearts, XP, streaks, leagues, confetti, or overdue-debt UI.
- [x] Drag is never the only way to answer.
- [x] Family satisfies its D27 contract row (F3).

## Contract gates

| ID | Gate | Result | One-sentence evidence |
|---|---|---|---|
| F3 | Free typed production | **Pass** | Native serif field + fada row and keyboard toolbar; moss on interactive chrome only; one ink Check; unsupported recall after construction scaffold removal. |

## Residual notes (not blockers)

- D7: intentional absence of model replay is correct for this freeze step; do not add replay without revisiting scaffold-removal intent.
- D8/D9: full Reduce Motion and VoiceOver rotor walk remain open for a foundation gate.

## Screenshot index

| File | State |
|---|---|
| `tmp/exercise-screenshots/freeze-run-2026-07-30/04-type-cold.png` | Cold open |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/04-type-filled.png` | Filled |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/04-type-wrong.png` | Wrong (editable) |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/04-type-complete.png` | Complete |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/04-type-a11y.png` | Largest Dynamic Type |
