# Scorecard — Shared state engine (rebuild plan step 3)

```text
Cluster: Shared state engine (rebuild plan step 3)
Scope: ios/AnTuras/CountyActivityStateEngine.swift,
       ios/AnTurasTests/CountyActivityStateEngineTests.swift,
       engine wiring in ios/AnTuras/CountyExerciseSystem.swift
Build / commit: uncommitted working tree (post D29 freeze ACCEPT + Grok coherence PASS)
Reviewer: Composer 2.5
Date: 2026-07-31
Unit tests: CountyActivityStateEngineTests + CountyFreezeRunTests — 49 tests, 0 failures (iPhone 17 Pro sim, parent-verified)
P0 checklist: clear
Verdict: ACCEPT
```

---

## Executive summary

Kimi delivered rebuild-plan **step 3** — a pure, SwiftUI-independent lifecycle engine with
comprehensive unit coverage — and wired it into the existing county shell without reopening
D26/D27/D29 freeze behavior. Required transitions, illegal rejection, D27 repair-window
semantics, exactly-once memory credit, revisit suppression, and bounded persistence are
implemented and tested. Shell wiring preserves struggle routing (`onStruggle`), escalated
diagnostic → incorrect panel mapping, matching brief diagnostics (`escalates: false`), and
Check/Continue primacy. Gaps against STATUS step 5 wording (full persistence, focus,
centralised announcements, `interrupt()` / `beginRecovery()` shell hooks) are **expected
deferred** to rebuild-plan steps 4–5, 7, and 11 — not REJECT-worthy for this pass.

---

## Contract gates

| ID | Gate | Result | Evidence |
|---|---|---|---|
| CG-1 | **Required transitions** | **Pass** | Engine implements unanswered→attempt, attempt→complete, attempt→diagnostic, unanswered→hint→attempt, diagnostic→retry→attempt, diagnostic→hint→retry→attempt, diagnostic→recovery→retry→attempt, and attempt→diagnostic→…→complete. Covered by `testUnansweredToAttempt`, `testAttemptToCompleteEmitsSuccessOnce`, `testDiagnosticToRetryToAttempt`, `testDiagnosticToHintToRetryToAttempt`, `testDiagnosticToRecoveryToRetryToAttempt`, `testAttemptToDiagnosticThroughRetryToComplete`. |
| CG-2 | **Illegal rejection** | **Pass** | `check` without formed response, `check` from diagnostic, `complete` without attempt, duplicate `complete`, `updateResponse` from diagnostic/recovery, `retry` from unanswered/attempt, stacked hints, `recovery` without diagnostic, `complete` from diagnostic/retry — all rejected with `accepted == false` and no spurious memory events. |
| CG-3 | **D27 repair window (selection vs check)** | **Pass** | `selectionTouch`: first wrong opens `repairWindowOpen`, no struggle (`testFirstWrongSelectionOpensTheRepairWindowWithoutStruggle`); second wrong closes window, signals struggle once (`testSecondWrongSelectionClosesTheWindowAndSignalsStruggleOnce`); self-correct closes without struggle (`testSelfCorrectingNextTouchClosesTheWindowWithoutStruggle`); `registerRepair` closes without struggle for unchecked progress (`testRegisterRepairClosesTheWindowForUncheckedProgress`). `explicitCheck`: struggle on first failure (`testExplicitCheckSignalsStruggleOnTheFirstFailure`), no repair window. |
| CG-4 | **Exactly-once memory** | **Pass** | `emit()` deduplicates via `emittedMemoryKinds`. Struggle never duplicates on third wrong (`testSecondWrongSelection…`). Completion after hint+recovery emits success/hint/recovery once (`testCompletionAfterHintAndRecoveryEmitsEachSignalOnce`). Revisit and in-session practice suppress credit and duplicate events (`testRevisitedCompletionAllowsPracticeWithoutCredit`, `testPracticeAfterCompletionInSessionEmitsNoDuplicateCredit`). Duplicate `complete` rejected with empty events. |
| CG-5 | **Attempt event fields** | **Pass (minor advisory)** | `CountyAttemptEvent` records exercise id, ordinal, outcome, diagnosticShown, hintUsed, recoveryUsed, completionEvidence, completionCredit, memoryCredit. **Advisory:** stable `targetIDs` live on `CountyMemoryEvent` and engine config, not duplicated on each attempt row — acceptable for step 3; add to attempt schema when persistence lands (step 6/11). |
| CG-6 | **Persistence bounds** | **Pass** | Engine stores phase flags, attempt metadata, and response **kind** only. `CountyActivityResponse.marker` is documented never stored. No verbatim free text, recordings, or option history in engine state. View keeps `panelMessage` for presentation copy only. |
| CG-7 | **Shell wiring preserves freeze behavior** | **Pass** | `CountyExerciseFeedbackState` removed; engine drives `locksResponse`, `presentationPhase` (`diagnosticEscalated` → `.incorrect` panel), `apply()` → `onStruggle` on struggle events only. Selection families: `noteSelectionWrong` uses `escalates` per family (choice `true`, matching/conversation `false`). `formEngineResponse()` auto-`retry()` from diagnostic/recovery. Explicit-check `markWrong` routes struggle through `apply()`. Speaking `recordCompare` retains own primary via `syncBarState` break. Freeze-run unit tests still pass (parent). |
| CG-8 | **Deferred to steps 4/7/11** | **Listed** | See table below. |

### Deferred (expected — not step-3 blockers)

| Item | Owner step | Notes |
|---|---|---|
| `interrupt()` shell wiring (back nav, background, permission) | Rebuild plan step 4 | Engine implemented + tested (`testInterruptWithAnOpenRepairWindowSignalsStruggle`); inline doc in engine acknowledges gap. **Severity: informational** — no freeze regression because pre-extraction shell also lacked lifecycle interrupt. |
| `beginRecovery()` shell wiring | Rebuild plan step 4 | Engine supports diagnostic→recovery→retry; freeze shell shows recovery **copy** via escalated incorrect panel without entering `.recovery` phase. `recoveryUsed` / recovery memory event fire only when shell calls `beginRecovery()` — parity with freeze, not a regression. |
| Persistence / resume of attempt ordinal + credit | Steps 6–7, 11 | Engine is in-memory; `CountyFreezeRunTests` still cover conversation resume separately. |
| Focus restoration, centralised a11y announcements | Step 4 shell | Per-option `AccessibilityNotification` on selection wrong remains in view; not centralised. |
| Success/hint/recovery memory handoff to scheduler | Step 11 | `apply()` forwards struggle only; comment documents step-11 landing. |
| Authored learning contract decode | Step 5–6 | `completionEvidence` mapping is shell static helper until contract adapter. |
| Full gallery / VoiceOver rotor / physical device | Foundation gate (step 7 / STATUS 7) | Unchanged from Grok coherence residuals. |

---

## P0 checklist (shell-observable behaviors affected by extraction)

| P0 | Result | Notes |
|---|---|---|
| Response stays repairable after wrong answer | **Clear** | `requiresRetry` + `formEngineResponse()` reopen path; matching `onRepair` → `registerRepair()`. |
| Exactly one ink primary per state | **Clear** | `syncBarState` unchanged for Check/Continue/speaking primacy. |
| Missing audio / mic denial never trap | **Clear** | No engine change to audio/mic surfaces. |
| No full-board lock on first wrong (matching) | **Clear** | `locksResponse` = `engine.isComplete` only; non-escalating families keep brief on-target note. |
| Struggle reaches contextual-review targeting | **Clear** | `apply()` → `onStruggle?()` on struggle memory events. |

---

## Observable shell dimensions (D1–D10, extraction-affected only)

Scored only where engine wiring touches learner-visible behavior. Pure invariants are in
contract gates above.

| Dim | Score | Evidence |
|---|---|---|
| D2 One primary | 5/5 | Check families keep Check slot; selection/speaking primacy unchanged; `recordCompare` still self-publishes bar. |
| D3 In-place repair | 5/5 | D27 window preserved; `formEngineResponse` auto-retries from diagnostic; `registerRepair` for matching/conversation unchecked repair; first wrong no struggle/panel on choice/matching. |
| D5 Feedback locality | 4/5 | `presentationPhase` maps engine `diagnosticEscalated` to shared incorrect panel; on-target diagnostics still family-local. Residual D5 ghost under Complete unchanged from freeze. |
| D8 Motion with meaning | 4/5 | `withAnimation(feedbackAnimation)` on panel transitions retained; no new blocking motion. |
| D9 Accessibility | 4/5 | Selection-wrong announcement still posted in `noteSelectionWrong`; not yet centralised in engine/shell (step 4). |

**Mean (scored dimensions): 4.4/5** — above 4.0 threshold; no dimension below 3.

Dimensions not materially touched by extraction (D1, D4, D6, D7, D10): not scored.

---

## Adversarial findings (defect-first)

### Cleared

1. **Required vs illegal transitions** — exhaustive unit coverage; rejected transitions leave `from == to` and emit nothing.
2. **D27 selection repair window** — first wrong records attempt + opens window without struggle; second wrong signals struggle exactly once; self-correct and `registerRepair` close without struggle; explicit Check struggles on first `check`.
3. **Revisit / practice credit** — `restoringCompletion` starts `.complete`; practice actions return `isPractice: true` with suppressed credit and no duplicate memory events.
4. **Bounded engine state** — no verbatim learner text, recordings, or option history in engine.
5. **Freeze regression risk** — wiring diff shows behavioral parity intent: struggle via `apply()` not raw `onStruggle()` on explicit check; matching/conversation `escalates: false`; contextual-review correct path now properly `check`+`complete` (fix, not regression).
6. **First-wrong attempt recording** — engine now creates an attempt event on first selection wrong (old shell only set `repairOpen`). Aligns with rebuild plan (“checking creates an immutable attempt event”); surfaces still show on-target diagnostic via family components.

### Non-blocking residuals

| ID | Finding | Severity |
|---|---|---|
| R-1 | `interrupt()` not called from shell | Informational — engine ready; step 4 |
| R-2 | `beginRecovery()` not called from shell | Informational — freeze used panel copy; step 4 |
| R-3 | `targetIDs` not on `CountyAttemptEvent` | Advisory — on memory events + engine config; persistence step |
| R-4 | Success/hint/recovery events not consumed beyond struggle | Expected — step 11 handoff |
| R-5 | `engine.phase == .recovery` never reached in live shell | Informational — step 4 placeholder/gallery |

No P0 defects. No contract gate failures.

---

## Test coverage map (step 3 acceptance)

| Area | Tests |
|---|---|
| Legal transitions | 9 tests |
| Illegal rejection | 10 tests |
| D27 repair window | 5 tests |
| Explicit Check | 2 tests |
| Support at completion | 2 tests |
| Interruption | 3 tests |
| Revisit / practice | 3 tests |
| Memory identity | 1 test |
| Freeze run (integration) | `CountyFreezeRunTests` (parent: all pass) |

---

## Rollup for Grok (quality owner)

**ACCEPT — foundation gate for step 3 is unblocked.**

Grok should **not** re-score freeze clusters. Next coherence pass:

1. **Confirm step-3 ACCEPT** and update STATUS step 5 wording to reflect step 3 done / step 4–5 remaining (persistence, focus, announcements, `interrupt` wiring).
2. **Plan step 4 shell extraction** — shared activity shell with placeholder component proving all lifecycle states including `.recovery` and `interrupt()` on page lifecycle.
3. **Foundation gate prep (steps 6–7)** — gallery matrix for C1/C3/C5, VoiceOver rotor, physical device, residual D5/D2 polish; re-walk freeze run after shell centralisation.
4. **Schema/memory (step 6/11)** — add `targetIDs` to persisted attempt records when handoff lands; wire success/hint/recovery consumers.

Grammar/Greenfield remain parked per D29/Grok coherence until foundation gate passes.

---

## Record

| Field | Value |
|---|---|
| Date | 2026-07-31 |
| Reviewer | Composer 2.5 (adversarial QA) |
| Input | Engine + tests + shell diff + rebuild plan § Shared runtime + D26/D27/D29 + STATUS steps 5–7 |
| Outcome | **ACCEPT** — pure state engine step 3 complete; shell wiring preserves freeze D27 behavior |
| P0 remaining | None |
