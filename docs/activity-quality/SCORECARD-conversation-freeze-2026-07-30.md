# Scorecard — Conversation cluster (freeze step 5) — C1 hard gate

```text
Cluster: Conversation
Fixture files: mayo.clew-bay.conversation-origin (step 5/9)
  tmp/exercise-screenshots/freeze-run-2026-07-30/05-conversation-{cold,cold-dark,misfit,
  turn-two,branch,complete,a11y,turn-two-reduce-motion}.png
Build / commit: uncommitted working tree (base 5174086)
Reviewer (Composer / human): Composer 2.5
Date: 2026-07-30

Scripts: 1P  2P  3P  4P  5P  6P  7~  8P  9P  10P
P0 checklist: clear

D1 Task clarity:        4/5  evidence: turn 1 cold (`05-conversation-cold`) reads as
  They say / Your reply — setting copy names present-day shore exchange; after first
  fitting turn the living transcript (`05-conversation-turn-two`) makes the graph legible.
D2 One primary:         5/5  evidence: reply choices are the response surface; Continue
  disabled until terminal fitting turn (`05-conversation-complete`).
D3 In-place repair:     5/5  evidence: 05-conversation-misfit — “Slán go fóill” shows
  on-turn diagnostic, graph does not advance; fitting reply repairs without clearing
  transcript (`CountyConversationEngine` + UI test double relaunch).
D4 Finger choreography: 4/5  evidence: reply cards stacked above bottom bar; speaker
  controls on partner lines with bundled audio are secondary ghosts.
D5 Feedback locality:   5/5  evidence: misfit diagnostic attaches to the selected reply
  (“That says goodbye, and the conversation has only begun…”).
D6 Irish as subject:    5/5  evidence: partner lines and replies in story serif; glosses
  and chrome in sans (`CountyConversationGraphSurface`).
D7 Audio honesty:       4/5  evidence: opening *Cárb as tú?* is text-only (no bundled
  clip) — honest for C1 production, not a listening family; later partner lines show
  replay when `audioText` is authored (`05-conversation-turn-two` speaker on
  *Cén t-ainm atá ort?*); text path always available.
D8 Motion with meaning: 4/5  evidence: 05-conversation-turn-two-reduce-motion — transcript
  and current turn communicate state without custom movement; settle uses nil animation
  under Reduce Motion.
D9 Accessibility:       4/5  evidence: 05-conversation-a11y — largest type coherent;
  learner rows expose “You said: …” in UI test resume path; full VoiceOver rotor not
  re-run (script 7 ~).
D10 Distinction:        5/5  evidence: present-day Clew Bay setting; origin line inside
  exchange; no MC chrome masquerading as the whole container once transcript builds.

Mean: 4.5/5
Contract gates: Pass (C1)
Verdict: ACCEPT
Required fixes (dimension IDs only): —
```

---

## Scripts (evidence)

| # | Script | Result | Evidence |
|---|---|---|---|
| 1 | Cold open (Jordan) | **Pass** | 05-conversation-cold: They say + three reply options within 3 s. |
| 2 | Deliberate wrong (Jordan) | **Pass** | 05-conversation-misfit: misfit does not advance; next fitting touch repairs. |
| 3 | Primary hunt (Casey) | **Pass** | Reply cards are the working surface; one bottom Continue slot. |
| 4 | Thumb reach (Casey) | **Pass** | Replies stacked above bar. |
| 5 | Largest type (Sam) | **Pass** | 05-conversation-a11y; `testFreezeRunConversationSurvivesLargestAccessibilityText`. |
| 6 | Reduce Motion (Sam) | **Pass** | 05-conversation-turn-two-reduce-motion. |
| 7 | VoiceOver states (Sam) | **~** | Transcript strings in UI test; full rotor not re-run. |
| 8 | Audio / mic escape (Jordan) | **Pass** | Text path for opening line; replay on authored lines; no trap. |
| 9 | Contract gate | **Pass** | C1 (below). |
| 10 | Anti-reference scan | **Pass** | No reward theatre. |

## P0 checklist

- [x] Response stays repairable after a wrong answer (no full-board lock).
- [x] Exactly one ink primary per state; Check and Continue share one slot.
- [x] Disabled / secondary controls remain readable.
- [x] Missing audio and mic denial never trap progress.
- [x] No hearts, XP, streaks, leagues, confetti, or overdue-debt UI.
- [x] Drag is never the only way to answer.
- [x] Container satisfies D27 contract row (C1).

## Contract gate C1 (hard gate — adversarial focus)

| Criterion | Result | Evidence |
|---|---|---|
| Authored turn graph (not bare MC list) | **Pass** | `CountyConversationGraph` + `CountyConversationGraphSurface`; living transcript after turn 1 (`05-conversation-turn-two`, `05-conversation-branch`, `05-conversation-complete`). Turn 1 alone resembles choice chrome — acceptable first-node presentation. |
| On-turn misfit diagnostic | **Pass** | `05-conversation-misfit`; engine `.misfit` never advances (`testConversationMisfitNeverAdvancesAndStateRoundTripsForResume`). |
| Branch changes later partner line | **Pass** | *Cé thusa?* branch yields partner *Is as Maigh Eo mé.* vs *Maith.* for name branch (`testConversationWalksThreeTurnsAndTheBranchChangesALaterPartnerLine`; `05-conversation-branch`). |
| Resume at current node + transcript | **Pass** | `testFreezeRunConversationBranchesAndResumesAtTheExactNode` — two relaunches; “You said: …” persists. |
| Setting metadata | **Pass** | `present-day` in graph; copy names shore / Clew Bay (`testConversationGraphMeetsTheC1Contract`). |
| *Cárb as tú?* without clip — honest D7 | **Pass** | Text-only opening line; conversation is production container, not F1/F6 listening; later nodes expose replay when authored. |

**Verdict on bare-MC challenge:** REJECTED as a fail — the surface is a finite turn graph with transcript, misfit handling, branching, and resume. It is not the legacy thin MC list scored in Rockfleet `06-conversation.png`.

## Residual notes (not blockers)

- Production packs still use legacy thin MC until migration group 3; freeze fixture is the acceptance proof.
- D1: turn-1 cold could gain a one-line “transcript will build here” hint — optional polish only.

## Screenshot index

| File | State |
|---|---|
| `tmp/exercise-screenshots/freeze-run-2026-07-30/05-conversation-cold.png` | Turn 1 cold |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/05-conversation-misfit.png` | Misfit diagnostic |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/05-conversation-turn-two.png` | Transcript + turn 2 |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/05-conversation-branch.png` | Branch partner line |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/05-conversation-complete.png` | Complete transcript |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/05-conversation-turn-two-reduce-motion.png` | Reduce Motion peer |
| `tmp/exercise-screenshots/freeze-run-2026-07-30/05-conversation-a11y.png` | Largest Dynamic Type |
