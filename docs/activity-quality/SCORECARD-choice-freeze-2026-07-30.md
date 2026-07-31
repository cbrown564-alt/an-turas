# Scorecard — Choice cluster (freeze steps 1 · 7)

```text
Cluster: Choice (F1 polish + F6)
Fixture files: mayo.clew-bay.listen-farraige (step 1/9), mayo.clew-bay.comprehend-coast (step 7/9)
  tmp/exercise-screenshots/freeze-run-2026-07-30/01-listen-{cold,wrong,complete}.png
  tmp/exercise-screenshots/freeze-run-2026-07-30/07-comprehend-{cold,wrong,complete}.png
Build / commit: uncommitted working tree (base 5174086); Shell ACCEPT at e4c6a8b for F1/F5/F7
Reviewer (Composer / human): Composer 2.5
Date: 2026-07-30

Scripts: 1P  2P  3P  4P  5~  6~  7~  8P  9P  10P
P0 checklist: clear

D1 Task clarity:        5/5  evidence: 01-listen-cold — full choice board at cold open;
  prompt now reads “you can answer whenever you are ready” (F1 polish). 07-comprehend-cold
  — read card + Irish line serif dominate the task.
D2 One primary:         5/5  evidence: content choices are the working primary on F1/F6;
  Continue occupies the single bottom slot after correct selection.
D3 In-place repair:     4/5  evidence: 01-listen-wrong / 07-comprehend-wrong — on-row
  rationale; next touch repairs without Retry; D27 repair window before struggle chrome.
D4 Finger choreography: 5/5  evidence: full-width stacked choice rows in thumb reach on
  both fixtures.
D5 Feedback locality:   4/5  evidence: per-row diagnostics (“That names the land…”;
  “That bends farraige into an origin…”); 01-listen-complete shows faint ghost of prior
  wrong rationale under Complete — cosmetic bleed only.
D6 Irish as subject:    5/5  evidence: 07-comprehend — Irish line in serif; English
  note and choices in sans; listen options serif on F1.
D7 Audio honesty:       5/5  evidence: 01 — Hear replay + answerable without play;
  07 — “Hear the line” replay + visible read card/meaning route; missing audio degrades
  to notice, never traps.
D8 Motion with meaning: 3/5  evidence: restrained selection highlights; Reduce Motion
  not re-captured on choice fixtures this pass.
D9 Accessibility:       4/5  evidence: wrong rows carry rust tint + rationale text
  (non-color); selected comprehend row uses moss border + checkmark; largest type not
  re-captured for steps 1/7 (script 5 ~).
D10 Distinction:        5/5  evidence: Clew Bay coast vocabulary and origin frame;
  shared limestone shell; no gamification.

Mean: 4.5/5
Contract gates: Pass (F1, F6)
Verdict: ACCEPT
Required fixes (dimension IDs only): —
```

---

## Scripts (evidence)

| # | Script | Result | Evidence |
|---|---|---|---|
| 1 | Cold open (Jordan) | **Pass** | 01-listen-cold: choices enabled; 07-comprehend-cold: read path + choices visible. |
| 2 | Deliberate wrong (Jordan) | **Pass** | 01-listen-wrong, 07-comprehend-wrong; FreezeRun UI test repairs steps 1 and 7. |
| 3 | Primary hunt (Casey) | **Pass** | One bottom slot; choices are the response surface. |
| 4 | Thumb reach (Casey) | **Pass** | Stacked rows above bar on both fixtures. |
| 5 | Largest type (Sam) | **~** | Shell rescore covered F1 pattern; not re-captured on freeze steps 1/7. |
| 6 | Reduce Motion (Sam) | **~** | Not re-captured on choice fixtures. |
| 7 | VoiceOver states (Sam) | **~** | Choice wrong `accessibilityValue` from shell; rotor not re-run. |
| 8 | Audio / mic escape (Jordan) | **Pass** | Replay + ungated response on F1; F6 read fallback. |
| 9 | Contract gate | **Pass** | F1, F6 (below). |
| 10 | Anti-reference scan | **Pass** | No reward theatre. |

## P0 checklist

- [x] Response stays repairable after a wrong answer (no full-board lock).
- [x] Exactly one ink primary per state; Check and Continue share one slot.
- [x] Disabled / secondary controls remain readable.
- [x] Missing audio and mic denial never trap progress.
- [x] No hearts, XP, streaks, leagues, confetti, or overdue-debt UI.
- [x] Drag is never the only way to answer.
- [x] Families satisfy D27 contract rows (F1, F6).

## Contract gates

| ID | Gate | Result | One-sentence evidence |
|---|---|---|---|
| F1 | Listen and choose | **Pass** | Response visible and tappable from cold open; repair window before struggle; in-place correction (`01-listen-cold`, `01-listen-wrong`). |
| F6 | Read or listen and respond | **Pass** | Read card works; listen variant with replay + visible Irish line and English note (`07-comprehend-cold`). |

## F1 polish (handoff focus)

- Prompt copy now aligns with ungated board: “you can answer whenever you are ready” (`01-listen-cold`). Residual tension with “Hear … and choose” is acceptable — response area is dominant.

## Residual notes (not blockers)

- D5: clear struggle diagnostic ghost under Complete on `01-listen-complete`.
- Matching (step 2) and Speaking (step 6) remain covered by Shell ACCEPT; no regressions observed in freeze-run gallery.

## Screenshot index

| File | State |
|---|---|
| `tmp/exercise-screenshots/freeze-run-2026-07-30/01-listen-cold.png` | F1 cold open |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/01-listen-wrong.png` | F1 wrong |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/01-listen-complete.png` | F1 complete |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/07-comprehend-cold.png` | F6 cold open |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/07-comprehend-wrong.png` | F6 wrong |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/07-comprehend-complete.png` | F6 complete |
