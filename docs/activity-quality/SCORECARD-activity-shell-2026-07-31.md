# Scorecard — Shared activity shell (rebuild plan step 4)

```text
Cluster: Shared activity shell (rebuild plan step 4)
Scope: ios/AnTuras/CountyExerciseSystem.swift (shell wiring),
       ios/AnTuras/CountyActivityStateEngine.swift (doc),
       ios/AnTurasUITests/CountyActivityShellUITests.swift
Build / commit: uncommitted working tree (post step-3 ACCEPT at ae4fabf)
Reviewer: Composer 2.5
Date: 2026-07-31
Unit tests: CountyActivityStateEngineTests + CountyFreezeRunTests — pass (parent + re-run 2026-07-31)
Step-4 UI tests: CountyActivityShellUITests — 0/2 pass (parent + re-run 2026-07-31, iPhone 17 Pro sim)
P0 checklist: FAIL (D3 recovery typing repair; step-4 verification gate; D9 field unreachable after recovery)
Verdict: REJECT
```

---

## Executive summary

Kimi landed the intended step-4 **shape**: `onDisappear` / `scenePhase.background` → `interrupt()`,
escalated incorrect panel → `beginRecovery()`, shell-owned announcement/focus queue, and a dedicated
`.recovery` presentation phase. Engine unit coverage and the D29 freeze walk still pass — freeze
semantics are not regressed for the existing second-wrong struggle path.

Two new step-4 acceptance UI tests both fail. One exposes a **product defect**: after
`beginRecovery()` on free typing, `irish-answer-field` remains keyboard-focused but reports a
**zero accessibility frame** and cannot be scrolled into view — in-place repair is broken on the
explicit-Check recovery path (D3/D9 P0). The interrupt→C3 test never reaches its C3 assertion;
menu navigation likely needs list scrolling (harness), but the mandated verification gate still
fails and interrupt→struggle→C3 integration remains unproven in UI.

---

## Contract gates

| ID | Gate | Result | Evidence |
|---|---|---|---|
| CG-1 | **Interrupt wiring** (`onDisappear`, background) | **Partial** | `CountyExerciseView` calls `apply(engine.interrupt())` on `.onDisappear` and when `scenePhase == .background`. Engine unit tests cover open-window struggle (`testInterruptWithAnOpenRepairWindowSignalsStruggle`). Double-fire risk is low: `emit(.struggle)` dedupes; `recordStruggle` dedupes page ids. **Gap:** no passing UI proof that mid-window leave records struggle and selects C3 (`CountyActivityShellUITests` test 1 fails before C3 assertion). |
| CG-2 | **beginRecovery wiring** | **Fail** | Incorrect panel adds `QuietHintButton` → `engine.beginRecovery()` → `.recovery` phase. Engine legal path covered in unit tests. **Product fail:** after recovery, `irish-answer-field` has `{0,0}` AX frame while still keyboard-focused; XCUITest cannot tap/edit (log: `kAXErrorCannotComplete` scroll-to-visible). Learner cannot repair on next touch (D3 P0). |
| CG-3 | **Centralised announcements / focus** | **Pass** | All `AccessibilityNotification` posts removed from components; `noteSelectionWrong` → shell `announce()`. Panel transitions → `announceAndFocus()`; reopen → `restorePromptFocus()`. Matching/conversation on-target notes stay announcement-only (no erroneous focus steal). **Advisory:** focus move to feedback panel may contribute to typing-field layout bug after recovery. |
| CG-4 | **Freeze sequence preservation** | **Pass** | `CountyFreezeRunTests` + `FreezeRunUITests/testFreezeRunWalksAllNineStepsWithRepairsInPlace` pass after this diff (re-run 2026-07-31). D27 selection repair window, matching brief unlock, Check/Continue primacy, C1/C3/C5 containers unchanged on the walk path. |
| CG-5 | **Verification (new step-4 UI tests)** | **Fail** | `CountyActivityShellUITests`: **0/2**. (1) `testInterruptWithOpenRepairWindowFeedsTheContextualReview` — `Missing chapter row: Return to what slipped` (menu query finds no button; likely lazy-list scroll + unproven C3 copy). (2) `testRecoveryRestructuresAndRequiresAFreshResponse` — AX scroll-to-visible failure on `irish-answer-field` after recovery. ACTIVITY-QUALITY-SPEC verification gate requires passing UI coverage of wrong→repair→complete. |
| CG-6 | **Deferred (expected out of scope)** | **Listed** | Persistence/resume of attempt credit (steps 6–7/11); schema/`learningContract` adapter (step 5–6); success/hint/recovery scheduler handoff (step 11); full gallery/VoiceOver rotor/physical device (foundation gate). Correctly not scored as step-4 blockers except where wiring broke live repair. |

---

## P0 checklist

| P0 | Result | Notes |
|---|---|---|
| Response stays repairable after wrong answer | **FAIL** | Selection/matching freeze paths preserved. **Explicit-check typing recovery:** field unreachable after `beginRecovery()` — repair blocked (test 2, AX `{inf,inf},{0,0}`). |
| Exactly one ink primary per state | **Clear** | `syncBarState` unchanged; recovery affordance is `QuietHintButton` (ghost), not second ink bar. Check/Continue slot preserved on typing. |
| Missing audio / mic denial never trap | **Clear** | No change to audio/mic surfaces; freeze mic-denied walk still passes. |
| No full-board lock on first wrong | **Clear** | D27 window + `interrupt()` do not alter selection first-wrong behavior; freeze step 1 still shows on-row rationale without panel. |
| Step-4 verification UI tests pass | **FAIL** | 0/2 — mandatory for this cluster per spec and parent brief. |
| C3 struggle targeting via interrupt (when claimed) | **Unverified** | Engine + atlas wiring plausible; UI test never asserted `"Earlier, the sea word slipped…"`. |

---

## Adversarial findings

### Product defects (P0)

| ID | Finding | Severity |
|---|---|---|
| P0-1 | **Recovery breaks typing repair.** After wrong Check → `Show a steadier step`, `irish-answer-field` exists in AX tree with value intact and **Keyboard Focused**, but frame is zero and scroll-to-visible fails. Violates D3 (next touch must repair) and D9 (coherent scroll composition). | **P0** |
| P0-2 | **Step-4 acceptance UI tests fail.** Spec verification gate and STATUS step 4 require proof of interrupt and recovery shell paths. Both tests fail on simulator (Composer re-run 2026-07-31). | **P0** |

### Cleared

1. **Interrupt call sites** — `onDisappear` and background `scenePhase` are the correct shell hooks; components do not call `interrupt()` directly.
2. **Struggle deduplication** — engine `emit()` + atlas `recordStruggle` prevent double credit on repeated interrupt.
3. **Freeze regression** — nine-step freeze walk and 49 engine/freeze unit tests pass; no reopening of D27 second-wrong-only behavior on the walk path.
4. **Announcement centralisation** — single shell queue; matching/conversation brief notes preserved without panel escalation.
5. **Recovery never completes alone** — engine still requires `recovery → retry → attempt → complete`; UI offers re-Check (when field is reachable).
6. **One primary on incorrect/recovery** — ink bar stays Check for typing; recovery is secondary quiet control.

### Non-blocking / harness / advisory

| ID | Finding | Severity |
|---|---|---|
| A-1 | Interrupt UI test menu jump to step 9 may fail because SwiftUI `List` lazy cells below the fold are absent from AX until scrolled — test 1 never reaches C3 copy assertion. | Harness (but verification still fails) |
| A-2 | `beginRecovery()` does not call `syncBarState()` — bar state likely OK but worth syncing after phase change. | Advisory |
| A-3 | `announceAndFocus` on `.recovery` may compete with software keyboard focus — suspect contributor to P0-1. | Advisory |
| A-4 | Incorrect panel body already shows full `exercise.recovery` copy before tapping steadier step — same as pre-step-4 escalated panel; not a regression. | Informational |
| A-5 | R-1/R-2 from step-3 scorecard: wiring present; R-5 (`.recovery` never reached) **resolved** in code but broken for typing UX. | Closed / superseded by P0-1 |

---

## Observable shell dimensions (step-4-affected only)

| Dim | Score | Evidence |
|---|---|---|
| D2 One primary | 5/5 | Recovery is quiet secondary; Check retains ink slot on typing. |
| D3 In-place repair | **2/5** | Selection freeze paths intact; **typing recovery path blocked** after `beginRecovery()`. |
| D5 Feedback locality | 4/5 | Incorrect/recovery panels rise with authored copy; on-target selection notes still local. |
| D8 Motion with meaning | 4/5 | `feedbackAnimation` on panel transitions; no new blocking motion. |
| D9 Accessibility | **2/5** | Centralised announcements good; **recovery leaves typing field with zero frame while keyboard-focused** — VoiceOver/scroll coherence broken. |

**Mean (scored dimensions): 3.4/5** — below 4.0 threshold; D3 and D9 below 3 floor on affected path.

---

## Test evidence map

| Suite | Result | Relevance |
|---|---|---|
| `CountyActivityStateEngineTests` | Pass | Legal `interrupt()` / `beginRecovery()` transitions |
| `CountyFreezeRunTests` | Pass | C3 targeting rules; atlas struggle record |
| `FreezeRunUITests` (9-step walk) | Pass | Freeze sequence unchanged (struggle via second wrong, not interrupt) |
| `CountyActivityShellUITests` | **0/2 Fail** | Step-4 acceptance — interrupt→C3; recovery→fresh Check |

---

## Kimi punch list (IDs only)

**S4-1 S4-2 S4-3 D3 D9 CG-2 CG-5 C3**

| ID | Required fix |
|---|---|
| **S4-1** | After `beginRecovery()` on explicit-check typing, restore a hittable `irish-answer-field` in the scroll composition (keyboard + feedback panel + primary bar). |
| **S4-2** | Reconcile shell focus/announcement queue with software keyboard: dismiss or re-anchor field focus on recovery so AX frame is non-zero. |
| **S4-3** | Prove interrupt→`recordStruggle`→C3 `"Earlier, the sea word slipped…"` in a passing UI test (fix menu scroll or walk sequentially). |
| **D3** | Recovery path must allow next-touch repair without scroll/AX failure. |
| **D9** | Largest-type / VoiceOver coherence for typing recovery state. |
| **CG-2** | `beginRecovery` wiring must meet product contract, not only engine acceptance. |
| **CG-5** | Both `CountyActivityShellUITests` must pass on iPhone 17 Pro sim. |
| **C3** | Interrupt-emitted struggle must deterministically select the sea-word review candidate when authored. |

---

## Rollup for parent agent

**Verdict: REJECT.** Step-4 shell structure is present and freeze-safe, but the mandated step-4 UI
verification fails and typing recovery is product-broken after `beginRecovery()`. Do not mark
STATUS step 4 complete or proceed to schema/gallery work until S4 punch list clears and both shell
UI tests pass.

---

## Record

| Field | Value |
|---|---|
| Date | 2026-07-31 |
| Reviewer | Composer 2.5 (adversarial QA) |
| Input | Shell diff, UI tests, ACTIVITY-QUALITY-SPEC, rebuild plan step 4, step-3 scorecard R-1/R-2, STATUS step 5 wording, D27/C3, simulator re-runs |
| Outcome | **REJECT** |
| P0 remaining | Typing recovery repair (D3/D9); step-4 UI verification (0/2); interrupt→C3 integration unproven |
