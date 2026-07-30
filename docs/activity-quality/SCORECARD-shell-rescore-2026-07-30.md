# Scorecard — Shell cluster re-score (fixtures 01 · 02 · 10)

```text
Cluster: Shell
Fixture files: 01-listen-choose · 02-matching · 10-record-compare
  (paths under tmp/exercise-screenshots/rescore-2026-07-30/; cold-open,
  mic-denied, and largest Dynamic Type captures on iPhone 17 Pro simulator)
Build / commit: e4c6a8b
Reviewer (Composer / human): Composer
Date: 2026-07-30

Scripts: 1P  2P  3P  4P  5P  6~  7~  8P  9P  10P
P0 checklist: clear

D1 Task clarity:        4/5  evidence: 01 cold open shows the full choice board
  enabled at full opacity — no Hear-first interaction gate (`CountyListenChoiceSurface`
  no longer binds `interactionEnabled` to `heard`). Prompt still reads “Listen, then
  choose,” which is slightly at odds with an answerable cold open but the response
  area is dominant and tappable in the first second.
D2 One primary:         5/5  evidence: 10 cold open — ink “Record your voice”;
  “Play the model” is a moss bordered ghost; “Continue without recording” is a quiet
  text link (`QuietHintButton`), not a second ink bar. Mic-denied path correctly
  promotes the escape to ink. 01 uses content choices as the primary while Continue
  stays disabled until correct (check-on-selection anatomy).
D3 In-place repair:     4/5  evidence: `noteSelectionWrong` opens a D27 repair
  window — first wrong carries on-row rationale without struggle chrome; second wrong
  without self-correct fires “Not quite” for choice families only. Matching never
  escalates to incorrect phase (`testRockfleetMatchingWrongPairStaysBriefAndRepairable`).
  Wrong choice rows keep rust tint until repaired (intentional on-target diagnostic).
D4 Finger choreography: 4/5  evidence: matching is a 2×2 Irish word grid plus
  full-width meaning rows stacked above the bottom bar (`CountyMatchingSurface`);
  no far-column-only layout. 01 choices are full-width stacked rows in thumb reach.
D5 Feedback locality:   4/5  evidence: matching wrong attaches a plain-language note
  on the attempted meaning row (“son” does not belong with “caisleán”…); choice wrong
  shows rationale under the affected row. No global-only banner on matching wrong.
D6 Irish as subject:    4/5  evidence: Irish match chips and listen options use story
  serif; English meanings SF Pro. No Two-Voice inversion on these three fixtures.
D7 Audio honesty:       5/5  evidence: replay labels present; 01 answers without
  play; missing-audio notice and mic-denied escape never trap progress
  (`testRockfleetDeniedMicrophoneNeverTrapsProgress` + mic-denied screenshot).
D8 Motion with meaning: 3/5  evidence: `feedbackAnimation` nil under Reduce Motion in
  code; matching flash is brief. Reduce Motion not visually re-verified this pass
  (script 6 ~).
D9 Accessibility:       4/5  evidence: choice wrong exposes `accessibilityValue`
  “Not correct”; selected match uses moss tint + filled dot + `isSelected` trait.
  All three fixtures survive largest Dynamic Type without clipping task, response,
  or bar action (script 5 Pass). Full VoiceOver wrong-state walk not re-run (script 7 ~).
D10 Distinction:        4/5  evidence: shared limestone shell; no XP/hearts/streaks/
  confetti on these surfaces.

Mean: 4.1/5
Contract gates: Pass (F1, F5, F7)
Verdict: ACCEPT
Required fixes (dimension IDs only): —
```

---

## Scripts (evidence)

| # | Script | Result | Evidence |
|---|---|---|---|
| 1 | Cold open (Jordan) | **Pass** | 01: castle/ship/coast choices enabled at cold open; `testRockfleetWrongAnswerStaysRepairableInPlace` taps ship before Hear. |
| 2 | Deliberate wrong (Jordan) | **Pass** | 01: wrong→correct without Retry; repair window then struggle on second wrong. 02: wrong pair stays brief, next tap unlocks; no “Not quite”. |
| 3 | Primary hunt (Casey) | **Pass** | 10: single ink “Record your voice”; Play model and quiet escape are not ink. |
| 4 | Thumb reach (Casey) | **Pass** | 02: word grid + stacked meaning rows; no two-column far-thumb board. |
| 5 | Largest type (Sam) | **Pass** | `UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge` on 01/02/10 — task, response, hint, and bar action visible without clipping. |
| 6 | Reduce Motion (Sam) | **~** | Code path nils animation; not visually re-verified this pass. |
| 7 | VoiceOver states (Sam) | **~** | Choice wrong value in code; matching wrong note is visible text; full rotor walk not re-run. |
| 8 | Audio / mic escape (Jordan) | **Pass** | Mic-denied screenshot + `testRockfleetDeniedMicrophoneNeverTrapsProgress`. |
| 9 | Contract gate | **Pass** | F1 · F5 · F7 (below). |
| 10 | Anti-reference scan | **Pass** | No XP, hearts, streaks, confetti, or shamrock theatre. |

## P0 checklist

- [x] Response stays repairable after a wrong answer (no full-board lock).
- [x] Exactly one ink primary per state; Check and Continue share one slot.
- [x] Disabled / secondary controls remain readable (tokenised sunk/stone).
- [x] Missing audio and mic denial never trap progress.
- [x] No hearts, XP, streaks, leagues, confetti, or overdue-debt UI.
- [x] Drag is never the only way to answer.
- [x] Family or container satisfies its D27 contract row for fixtures under test.

## Contract gates (fixtures under test)

| ID | Gate | Result | One-sentence evidence |
|---|---|---|---|
| F1 | Listen and choose | **Pass** | Response interactive from cold open; D27 repair window before struggle chrome; Continue enables after correct pick. |
| F5 | Matching | **Pass** | Wrong pair = on-target note + next-tap unlock, no incorrect phase; thumb-native single-column board; Rockfleet fixture and Mayo draft ≤4 pairs with validator enforcement. |
| F7 | Record and compare | **Pass** | Cold open: Record owns ink; Play model / Play back / Record again are moss ghosts; “I compared both” after playback; quiet escape unless mic denied. |

## Delta from first pass (`SCORECARD-shell-2026-07-30.md` at `237d74f`)

| Dimension | First pass | Re-score | Δ |
|---|---|---|---|
| D1 | 2 | 4 | +2 |
| D2 | 1 | 5 | +4 |
| D3 | 3 | 4 | +1 |
| D4 | 3 | 4 | +1 |
| D5 | 3 | 4 | +1 |
| D7 | 4 | 5 | +1 |
| Mean | 3.0 | 4.1 | +1.1 |
| Verdict | REJECT | ACCEPT | — |

## Residual notes (not blockers)

- D8/D9: run Reduce Motion and full VoiceOver scripts on the next cluster pass or foundation gate.
- D1 copy could align wording with ungated response (“You can listen or choose”).
- Choice / Matching / Speaking spectacular passes remain gated on cluster ACCEPT — Shell is now clear to proceed to **freeze the representative Mayo run** (STATUS step 2).

## Screenshot index

| File | State |
|---|---|
| `tmp/exercise-screenshots/rescore-2026-07-30/01-listen-choose-cold.png` | 01 cold open |
| `tmp/exercise-screenshots/rescore-2026-07-30/02-matching-cold.png` | 02 cold open |
| `tmp/exercise-screenshots/rescore-2026-07-30/10-record-compare-cold.png` | 10 cold open |
| `tmp/exercise-screenshots/rescore-2026-07-30/10-record-compare-mic-denied.png` | 10 mic denied |
| `tmp/exercise-screenshots/rescore-2026-07-30/01-listen-choose-a11y.png` | 01 largest type |
| `tmp/exercise-screenshots/rescore-2026-07-30/02-matching-a11y.png` | 02 largest type |
| `tmp/exercise-screenshots/rescore-2026-07-30/10-record-compare-a11y.png` | 10 largest type |
