# Scorecard — Shell cluster (fixtures 01 · 02 · 10)

```text
Cluster: Shell
Fixture files: 01-listen-choose.png · 02-matching.png · 10-record-compare.png
  (paths under tmp/exercise-screenshots/; PNGs not in-repo — graded from
  STATUS fixture map, 2026-07-30 impeccable critique, and committed shell at
  CountyExerciseSystem.swift / CountyStoryExperienceView.swift)
Build / commit: 237d74f
Reviewer (Composer / human): Composer
Date: 2026-07-30

Scripts: 1F  2P  3F  4F  5~  6~  7~  8P  9F  10P
P0 checklist: FAIL — D2 speaking primary inverted; D1/F1 listen-choose gate;
  F7 no Record primary. Board-lock Retry P0 cleared at 237d74f (script 2 Pass).

D1 Task clarity:        2/5  evidence: 01 cold open still dims and disables the
  choice board until Hear (`interactionEnabled: heard`, opacity 0.72). Prompt is
  clear; response area is not dominant or answerable in the first second.
D2 One primary:         1/5  evidence: 10 cold open enables ink "Continue without
  recording" while Record and Play are equal moss bordered controls. Escape owns
  the primary slot; Record is secondary. 01 leaves Continue dead until complete
  (acceptable for check-on-selection) but offers no ink primary while answering.
D3 In-place repair:     3/5  evidence: Board-lock + Retry wall gone; UI test
  `testRockfleetWrongAnswerStaysRepairableInPlace` proves 01 wrong→correct.
  Residual friction: matching wrong still escalates through shell `markWrong` into
  full "Not quite" incorrect phase (mastery-failure chrome on a brief distinction
  task); wrong choice rows stay permanently rust-marked; repair window before
  struggle *memory* is not modelled (misses++ on first wrong).
D4 Finger choreography: 3/5  evidence: Targets ≥48 pt. Matching remains a
  two-column board with meanings in the far thumb zone (Casey script 4).
D5 Feedback locality:   3/5  evidence: Choice rationales attach via option text +
  rust row. Matching wrong uses global recovery banner only; flash on the right
  target is color/timing without a lasting on-target rationale.
D6 Irish as subject:    4/5  evidence: Irish match left + listen options use story
  serif; English meanings SF Pro. No systematic Two-Voice inversion on these three.
D7 Audio honesty:       4/5  evidence: Replay labels present; MissingAudioNotice
  and mic-denied escape exist; 01 still withholds interaction until play (F1/D1),
  but progress is not trapped when audio/mic missing (script 8 Pass).
D8 Motion with meaning: 3/5  evidence: Reduce Motion respected on feedback
  animation; no confetti. Matching flash is short; no physical lock/repair motion
  language beyond tint.
D9 Accessibility:       3/5  evidence: Selected match uses mossTint + filled dot +
  isSelected trait (not tint-only). Wrong flash has no VoiceOver wrong value.
  Largest-type / Reduce Motion / both appearances not re-inspected this pass
  (no iOS simulator in this environment) — scored from gallery intent + prior suite.
D10 Distinction:        4/5  evidence: Shared limestone shell; no XP/hearts/
  streaks. Residual taxonomy pressure is out of scope for these three fixtures.

Mean: 3.0/5
Contract gates: Fail (F1, F5, F7)
Verdict: REJECT
Required fixes (dimension IDs only): D1 D2 D3 D4 D5 F1 F5 F7
```

---

## Scripts (evidence)

| # | Script | Result | Evidence |
|---|---|---|---|
| 1 | Cold open (Jordan) | **Fail** | 01: choices disabled until Hear; copy “Listen once, then choose a meaning.” |
| 2 | Deliberate wrong (Jordan) | **Pass** | 01: wrong→correct without Retry (`AtlasFlowUITests`). 02: wrong pair does not set `responseLocked`. |
| 3 | Primary hunt (Casey) | **Fail** | 10: single ink control is “Continue without recording”, not Record. |
| 4 | Thumb reach (Casey) | **Fail** | 02: right-column meanings remain far-thumb two-column matching. |
| 5 | Largest type (Sam) | **~** | Not re-run here; prior gallery/UI coverage exists — do not treat as Pass. |
| 6 | Reduce Motion (Sam) | **~** | `feedbackAnimation` nil under Reduce Motion; not visually re-verified. |
| 7 | VoiceOver states (Sam) | **~** | Selected/complete traits present; wrong flash unnamed. |
| 8 | Audio / mic escape (Jordan) | **Pass** | Missing audio notice; `--microphone-denied` continue path + UI test. |
| 9 | Contract gate | **Fail** | F1 Fail · F5 Fail · F7 Fail (below). |
| 10 | Anti-reference scan | **Pass** | No XP, hearts, streaks, confetti, shamrock theatre on these surfaces. |

## P0 checklist

- [x] Response stays repairable after a wrong answer (no full-board lock). — cleared at 237d74f
- [ ] Exactly one ink primary per state; Check and Continue share one slot. — **FAIL** on 10
- [x] Disabled / secondary controls remain readable (tokenised sunk/stone). — PrimaryButton disabled uses sunk + stone
- [x] Missing audio and mic denial never trap progress.
- [x] No hearts, XP, streaks, leagues, confetti, or overdue-debt UI.
- [x] Drag is never the only way to answer.
- [ ] Family or container still satisfies its D27 contract row below. — **FAIL** F1/F5/F7

## Contract gates (fixtures under test)

| ID | Gate | Result | One-sentence evidence |
|---|---|---|---|
| F1 | Listen and choose | **Fail** | Response interactive only after play; instant “Not quite” struggle chrome on first wrong; Continue dead until complete. |
| F5 | Matching | **Fail** | Wrong pair escalates to full incorrect phase (not brief unlock); far-column board; Mayo draft still authors a 5-pair board (`mayo.in-the-record.match-record`) against ≤4. Rockfleet fixture itself is 4 pairs and unlocks. |
| F7 | Record and compare | **Fail** | Cold open: ink Continue-without-recording + two equal moss Play/Record ghosts; Record is never the sole primary before compare. |

## Partial progress since critique (do not treat as ACCEPT)

Commit `237d74f` cleared the matching board-lock / Retry P0, moved Check into the bottom bar for builders/typing, added non-tint selection marks on match, and retokenised disabled primary. That is necessary shell groundwork — not a Shell-cluster pass. Mean 3.0 < 4.0; D2 = 1; F1/F5/F7 red.

## Kimi punch list (Shell cluster — dimension IDs)

Implement **only** the Shell cluster until ACCEPT. Cite these IDs in notes; do not open Choice / Matching / Speaking spectacular passes yet.

1. **D2 / F7** — One ink primary per speaking state: Record (or Stop) owns ink until compare; Play model / Play back / Record again are moss ghost; Continue (or “I compared both”) replaces the slot after compare; mic-denied escape stays available without stealing primacy on cold open.
2. **D1 / F1** — Listen-choose response area answerable before or with first play (no interaction gate that hides the task behind Hear).
3. **D3 / F1 / F5** — Keep in-place repair; matching wrong stays a brief unlock (next tap) without mastery-failure incorrect-phase escalation; struggle *memory* only after failed repair window (D27); choice diagnostic on target without permanent board freeze.
4. **D4 / F5** — Matching board thumb-native (≤4 pairs enforced in authorship + validator); no far-column-only layout.
5. **D5** — Wrong match rationale on the affected target, not only the global banner.

Out of scope until Shell ACCEPT: family chrome invention, grammar progressive reveal, conversation graph, greenfield F9/F10, Consolidation containers.
