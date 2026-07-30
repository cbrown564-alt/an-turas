---
target: tmp/exercise-screenshots (12 exercise screens)
total_score: 29
p0_count: 0
p1_count: 3
timestamp: 2026-07-30T15-34-03Z
slug: tmp-exercise-screenshots
---
# Critique: tmp/exercise-screenshots (12 exercise screens)

Method: dual-agent (A: fdda375a-b5f0-49ea-b8d5-b30771bdfc09 · B: 8b59e078-5e1a-44de-9151-4360825be39f)

## Design Health Score — 29/40 (Good)

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Match selection is tint-only; wrong tap freezes everything with no explanation of why |
| 2 | Match System / Real World | 3 | "Corrected", "Keep this answer", "release-ready" are system-speak, not learner language |
| 3 | User Control and Freedom | 2 | Wrong answers lock the response and force Retry restart; single-choice commits on first touch, no undo |
| 4 | Consistency and Standards | 2 | Hollow radio circles that never fill; Irish serif/sans flip-flop; two stacked ink primaries on some families, none on 10 |
| 5 | Error Prevention | 3 | Check disabled until complete, normalization, fada aids; but instant grading + full-board match lock punish slips |
| 6 | Recognition Rather Than Recall | 4 | Hints on demand, visible templates/translations, replay everywhere |
| 7 | Flexibility and Efficiency | 3 | Fada keyboard toolbar excellent; Retry round-trips and "Keep this answer" add recovery friction |
| 8 | Aesthetic and Minimalist Design | 3 | Calm and restrained; taxed by four-line header stack, ever-present hint at control weight, dead disabled Checks |
| 9 | Error Recovery | 3 | Per-option rationale is genuinely good; recovery is restart-based, matching freezes the board |
| 10 | Help and Documentation | 3 | Hints on every screen; nothing explains mechanics (circles, covered meanings, locking) |
| **Total** | | **29/40** | **Good — solid foundation, weak recovery model** |

## Anti-Patterns Verdict

Not AI slop overall: limestone palette (pixel-exact tokens), ink primary, quiet progress, flat fields, zero gamification are clearly authored. But scaffolding tells creep in at the chrome layer: tracked family-taxonomy eyebrow above all 12 headings ("LISTEN AND IDENTIFY"…); identical radio-row card stack reused across 06/08/09/11; three-deep equal-weight ghost-button stack on 10; state-machine copy leaking into UI ("Corrected", "Keep this answer").

Deterministic scan: web detector not applicable to SwiftUI (exit 0, empty result). Mechanical evidence instead: current county system (CountyExerciseSystem.swift) is disciplined (semantic type, zero shadows, icon+text feedback); legacy ExerciseViews.swift carries the debt (15 fixed font sizes, 3 shadows, 3 border+shadow ghost cards, ≈39–43pt check buttons/tiles below 44pt). Screenshots render palette exactly (bg #ECEDE7, ink #23281F, moss #4C6647) but include gray button fills (#91948D, #CFD5CA) and chrome (5-dot pager, nav mic icon, "Cuardaigh" back label) that exist nowhere in the repo — the renders depict an external iteration, not the committed code.

## What's Working

1. Chrome discipline: one skeleton across all 12 — native nav, quiet progress, identical header rhythm, one safe-area continue.
2. Flat-field compliance: no shadows, no pills, radius discipline, tonal limestone layering, exact token colors.
3. Honest edge states + typing scaffolds: missing-audio/mic-denied never trap progress; fada entry inline and in keyboard toolbar; verdicts pair icon + plain-language text.

## Priority Issues

1. [P1] Restart-based error recovery locks the response (all 12, worst on 02 matching). markWrong freezes the entire board behind a full-width ink Retry wall; one mis-tap locks 12 targets. Violates DESIGN.md "stays repairable: the next touch changes the answer in place." Fix: unlock on diagnostic; rust card inline; next touch repairs in place; Retry as explicit secondary reset only.
2. [P1] No stable primary-action hierarchy. 10 record-compare: three equal moss ghost buttons + hint + dead continue bar (five controls, no primary; completion path is a ghost). 03/04/05/07/12: ink Check stacked directly above ink Continue — two identical-weight black bars, mis-tap invitation. Fix: one ink primary per state; Check replaces Continue in the same slot; ghost for Play/Record; hint demoted to quiet text button.
3. [P1] Disabled/secondary buttons fail readability. Off-palette gray fills (#91948D with white text ≈3:1) on "Show a hint"/"Next"; disabled ink at 0.45 opacity = limestone-on-mud. The most important button is least readable exactly when disabled. Fix: real disabled style (stone text on sunk fill, full opacity); route all grays through tokens.
4. [P2] Chrome & tint discipline. Tracked mechanism-taxonomy eyebrow on all 12 violates Sparse Label Rule and spends moss's rarity; fada row on 05/12 wears atlas green ("SÍNEADH FADA · TAP TO INSERT", caption2) while the progress bar is moss — tints literally swapped vs Flag-without-a-Flag. Dot pager + unexplained mic icon on every screen. Fix: delete eyebrow (chrome already carries mode · chapter · x/y); fada label ink-soft sentence case, raised/ink keys; moss reserved for interactive elements.
5. [P2] Two-Voice inversion. English translation gets display serif on 05/12 while learner's Irish is sans; Irish is serif 28pt on 08/09/11 templates but sans 17pt on 01/02/06 options and 03/04/07 tiles. Fix: Irish working text serif everywhere; instructions/glosses SF Pro.

## Persona Red Flags

- Jordan (first-timer): four-line header stack before anything actionable; hollow circles that commit on first touch; covered response area on 01; full-board freeze on first wrong match; "Keep this answer" tax after success.
- Sam (accessibility): 0.45-opacity disabled labels; selected match = pale mossTint background only (color-only state, CES:440); trailing circle glyphs in inkFaint with no VoiceOver value; green caption2 fada label — smallest text on screen.
- Casey (one-handed, distracted): matching right column in far-thumb zone; small scattered tile chips mid-screen; stacked ink Check/Continue mis-tap risk; one-tap grading punishes thumb slips with lock-and-Retry.

## Minor Observations

- "Show a hint" at bordered control weight on every screen — should be quiet text button.
- Dead 45% Check remains visible next to "Complete" state.
- "Corrected" headline is state-machine vocabulary.
- Missing-audio notice says "release-ready" — production jargon in learner copy.
- 01 hides the entire response area behind gate copy; no dominant response area in initial state.
- Conversation (06) is a bare choice list — no turns/transcript; grammar discovery (09) is one worked case + MC — container contracts unmet.
- Matching board presents 12 simultaneous targets (6 pairs) — above the ≤4 chunking guidance; DESIGN.md wants matching brief.
- Legacy ExerciseViews.swift (serif prompts, tile shadows, shakes, ≈39pt check buttons) still coexists with the county system — two anatomies in one codebase.
- "‹ Cuardaigh" back label: Irish-only wayfinding with no learner support.
- Theme.swift token values drift from DESIGN.md frontmatter (inkFaint, stone, lichen, atlas green/gold) with WCAG rationale comments — fix the doc, not the values.

## Questions to Consider

1. If the serif is the story's voice, why does the English translation receive it while the learner's Irish is typed in sans? Which language is the editorial subject?
2. What would be lost if the family eyebrow were deleted from all twelve screens tomorrow?
3. What is the app protecting the learner from when one wrong tap freezes the matching board — at the exact moment they're ready to fix it?
4. The atlas trio is reserved for progress, yet the progress bar is moss and the fada keys are atlas green — applied by rule or by habit?
5. When five equal-weight controls ask the learner to choose on the speaking screen, who is doing the prioritizing?
