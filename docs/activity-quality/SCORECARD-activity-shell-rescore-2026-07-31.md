# Scorecard — Shared activity shell (rebuild plan step 4) — re-score

```text
Cluster: Shared activity shell (rebuild plan step 4) — re-score
Reviewer: Composer 2.5
Date: 2026-07-31
Prior: REJECT (SCORECARD-activity-shell-2026-07-31.md)
Verdict: ACCEPT
P0 checklist: clear
```

---

## Executive summary

Kimi cleared every punch-list ID from the prior REJECT. The typing recovery
defect (zero AX frame while keyboard-focused after `beginRecovery()`) is fixed by
passing `recoveryPresented` into `CountyTypingSurface` / contextual-review typing
and resigning field focus when recovery rises. All three `CountyActivityShellUITests`
pass on iPhone 17 Pro sim, including interrupt→C3 targeting and AX5 Dynamic Type
field reachability. Engine and freeze unit suites remain green (49 tests). Step-4
shell wiring meets ACTIVITY-QUALITY-SPEC pass thresholds for this cluster.

---

## Punch-list clearance

| ID | Prior fail | Re-score | Evidence |
|---|---|---|---|
| **S4-1** | Field unreachable after recovery | **Clear** | `recoveryPresented` → `focused = false`; `testRecoveryRestructuresAndRequiresAFreshResponse` edits and completes |
| **S4-2** | Keyboard vs shell focus conflict | **Clear** | Focus resign on recovery; re-tap re-raises keyboard for repair (test 2 lines 84–91) |
| **S4-3** | Menu jump / C3 unproven | **Clear** | `jumpToPage` scrolls lazy `collectionViews`; test 1 asserts `"Earlier, the sea word slipped…"` |
| **D3** | In-place repair blocked on typing recovery | **Clear** | Wrong → recovery → edit → Check → complete in UI test 2 |
| **D9** | Zero frame / scroll coherence | **Clear** | `testRecoveryKeepsTheAnswerFieldReachableAtLargestText` (AX5) — field `isHittable` after recovery |
| **CG-2** | beginRecovery product fail | **Pass** | Recovery panel + restructured response path proven in UI |
| **CG-5** | 0/2 shell UI tests | **Pass** | **3/3** `CountyActivityShellUITests` pass (~88s Composer re-run 2026-07-31) |
| **C3** | Interrupt struggle → sea word unverified | **Clear** | UI test 1 completes step 9 with struggled sea-word copy |

---

## Contract gates

| ID | Gate | Result | Evidence |
|---|---|---|---|
| CG-1 | **Interrupt wiring** (`onDisappear`, background) | **Pass** | `CountyExerciseView` hooks unchanged; UI test 1 proves mid-window leave → struggle → C3 sea-word review |
| CG-2 | **beginRecovery wiring** | **Pass** | Incorrect panel → recovery phase; typing field reachable and editable after recovery (tests 2–3) |
| CG-3 | **Centralised announcements / focus** | **Pass** | Shell queue unchanged; focus resign on recovery avoids keyboard/AX frame clash |
| CG-4 | **Freeze sequence preservation** | **Pass** | `CountyFreezeRunTests` 14/14; no drift on nine-step semantics |
| CG-5 | **Verification (step-4 UI tests)** | **Pass** | `CountyActivityShellUITests` 3/3 on iPhone 17 Pro sim |
| CG-6 | **Deferred (out of scope)** | **Listed** | Persistence resume, schema adapter, scheduler handoff, full gallery/rotor — unchanged |

---

## P0 checklist

| P0 | Result | Notes |
|---|---|---|
| Response stays repairable after wrong answer | **Clear** | Typing recovery path restored; selection/matching freeze paths unchanged |
| Exactly one ink primary per state | **Clear** | Check retains ink slot; recovery is `QuietHintButton` ghost |
| Missing audio / mic denial never trap | **Clear** | No change; freeze mic-denied walk not regressed |
| No full-board lock on first wrong | **Clear** | D27 first-wrong window unchanged |
| Step-4 verification UI tests pass | **Clear** | 3/3 shell UI tests pass |
| C3 struggle targeting via interrupt | **Clear** | `"Earlier, the sea word slipped. Meet it again from the original sound."` asserted |

---

## Adversarial findings

### Cleared (prior P0)

1. **P0-1 typing recovery AX frame** — `onChange(of: recoveryPresented)` resigns focus; field keeps valid frame and scroll composition.
2. **P0-2 verification gate** — all mandated shell UI tests pass, including new AX5 coverage.

### Residual (non-blocking)

| ID | Finding | Severity |
|---|---|---|
| A-1 | `announceAndFocus` on `.recovery` still moves VoiceOver to feedback panel while keyboard yields — acceptable trade; learner re-taps field for repair | Advisory |
| A-2 | `beginRecovery()` still does not call `syncBarState()` — bar state correct on observed paths | Advisory |
| A-3 | AX5 test proves reachability (`isHittable`) but not full edit→Check at largest type — default-size test covers repair flow | Advisory |
| A-4 | Double `interrupt()` on background + dismantle is safe: `repairWindowOpen` closes once; `emit(.struggle)` dedupes | Informational |

No new P0 defects found on double-interrupt, focus thrash, primary hierarchy, or freeze drift.

---

## Observable shell dimensions (step-4-affected only)

| Dim | Score | Evidence |
|---|---|---|
| D2 One primary | 5/5 | Recovery quiet secondary; Check retains ink on typing |
| D3 In-place repair | **5/5** | Recovery → re-tap → edit → Check → complete (UI test 2) |
| D5 Feedback locality | 4/5 | Incorrect/recovery panels with authored copy; selection notes local |
| D8 Motion with meaning | 4/5 | `feedbackAnimation` on panel transitions; no blocking motion |
| D9 Accessibility | **4/5** | Centralised announcements; focus resign fixes scroll/AX; AX5 reachability test passes |

**Mean (scored dimensions): 4.4/5** — above 4.0 threshold; no dimension below 3.

---

## Test evidence map

| Suite | Result | Relevance |
|---|---|---|
| `CountyActivityStateEngineTests` | **35/35 Pass** | `interrupt()`, `beginRecovery()`, struggle dedupe |
| `CountyFreezeRunTests` | **14/14 Pass** | C3 targeting; atlas struggle record |
| `CountyActivityShellUITests` | **3/3 Pass** | Interrupt→C3; recovery→fresh Check; AX5 field reachability |
| `FreezeRunUITests` (9-step walk) | Not re-run | Parent green before punch list; engine/freeze unit suites unchanged |

Composer re-run 2026-07-31, iPhone 17 Pro sim. Parent xcresult (12:58): 3/3 shell tests. Composer xcresult (13:01): 3/3 shell + 49 unit tests.

---

## Grok coherence — next confirmation

With step 4 ACCEPT, Grok should confirm:

1. **STATUS step 4** can mark shared activity shell complete (interrupt, recovery, announcements, focus).
2. **Step 5 / schema foundation** is the next serial gate: `learningContract` adapter, authored completion evidence vocabulary alignment, gallery baseline for deferred containers — without reopening shell lifecycle or freeze sequence.
3. **No STATUS step 5 wording** that implies shell or freeze work remains open for this cluster.

---

## Rollup for parent agent

**Verdict: ACCEPT.** All prior punch-list IDs cleared. Mean scored dimensions 4.4/5;
P0 checklist clear; in-scope contract gates Pass; verification UI tests 3/3. Safe to
advance STATUS step 4 and hand schema/foundation prep to Grok.

---

## Record

| Field | Value |
|---|---|
| Date | 2026-07-31 |
| Reviewer | Composer 2.5 (adversarial QA re-score) |
| Input | Kimi fixes, shell UI tests, engine/freeze unit tests, prior REJECT scorecard, ACTIVITY-QUALITY-SPEC |
| Outcome | **ACCEPT** |
| P0 remaining | None |
