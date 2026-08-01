# Scorecard — D30 *farraige* C (delayed reuse typing)

```text
Cluster: Typing (phrase-family C proof)
Fixture files: mayo.farraige-family-c
  encounter → bay delay → delayed-where-sea
  tmp/exercise-screenshots/farraige-family-c-2026-08-01/
Build / commit: uncommitted working tree
Reviewer (Composer / human): human (owner agent walk + screenshots)
Date: 2026-08-01

Scripts: 1P  2P  3P  4P  5~  6~  7~  8P  9P  10P
P0 checklist: clear

D1 Task clarity:        5/5  evidence: 03-type-cold — “Type the question” + “Where is
  the sea?”; empty Irish field and fada row; Check disabled.
D2 One primary:         5/5  evidence: Check on attempt; “Complete this chapter path”
  on success — one bottom slot.
D3 In-place repair:     5/5  evidence: 03-type-wrong keeps typed text; recovery yields
  keyboard; UI test repairs without board lock.
D4 Finger choreography: 4/5  evidence: field, fada row, Check in thumb reach; no
  competing primaries.
D5 Feedback locality:   5/5  evidence: 03-type-wrong recovery names the earlier location
  line vs the question surround — delayed reuse pedagogy on-target.
D6 Irish as subject:    5/5  evidence: Irish serif in the field; English target/chrome
  in sans; fada row present.
D7 Audio honesty:       5/5  evidence: delayed step has no audioText (unsupported
  recall); no silent trap.
D8 Motion with meaning: 3/5  evidence: shared typing settle; no Reduce Motion capture
  this pass.
D9 Accessibility:       4/5  evidence: irish-answer-field + fada Insert labels;
  XXXL / rotor not re-run (scripts 5/7 ~).
D10 Distinction:        5/5  evidence: success “Same lexeme, later surround”; Clew Bay
  delay page; limestone shell; no reward theatre.

Mean: 4.6/5
Contract gates: Pass (F3 + delayedRecall authored use + D30 C)
Verdict: ACCEPT
Required fixes (dimension IDs only): —
```

---

## Scripts (evidence)

| # | Script | Result | Evidence |
|---|---|---|---|
| 1 | Cold open (Jordan) | **Pass** | 03-type-cold: field + fada row; Check disabled. |
| 2 | Deliberate wrong (Jordan) | **Pass** | Replay location line → Not quite + surround-aware recovery; repair in place. |
| 3 | Primary hunt (Casey) | **Pass** | One ink Check / Complete. |
| 4 | Thumb reach (Casey) | **Pass** | Field and bar in lower half. |
| 5 | Largest type (Sam) | **~** | Not captured for C typing. |
| 6 | Reduce Motion (Sam) | **~** | Shared shell; not captured. |
| 7 | VoiceOver states (Sam) | **~** | Labels in code; rotor not re-run. |
| 8 | Audio / mic escape (Jordan) | **Pass** | No audio gate on delayed step. |
| 9 | Contract gate | **Pass** | F3 + D30 C (below). |
| 10 | Anti-reference scan | **Pass** | No XP/hearts/confetti. |

## P0 checklist

- [x] Response stays repairable after a wrong answer (no full-board lock).
- [x] Exactly one ink primary per state; Check and Continue share one slot.
- [x] Disabled / secondary controls remain readable.
- [x] Missing audio and mic denial never trap progress.
- [x] No hearts, XP, streaks, leagues, confetti, or overdue-debt UI.
- [x] Drag is never the only way to answer.
- [x] Family satisfies F3; authored use `delayedRecall`; D30 C reuses a different member after delay.

## Contract gates

| ID | Gate | Result | One-sentence evidence |
|---|---|---|---|
| F3 | Free typed production | **Pass** | Unsupported field; fada row; wrong→repair→complete UI test. |
| D27-use | `delayedRecall` | **Pass** | Authored on delayed page; learning path orders encounter → narrative delay → type. |
| D30-C | Delayed reuse of another member | **Pass** | Encounter builds `Tá an fharraige anseo.`; delay has no production; type `Cá bhfuil an fharraige?`. |

## Shape decision (resolves STATUS open question)

Pattern C uses **freeTyping + `delayedRecall`** — the existing county-shell authored use.
Contextual review (struggle remap) and Words you carry (not on shared shell) stay out of
this fixture.

## Residual notes (not blockers)

- Pedagogue + native audio QA remain open; no teaching claims or Mayo densify yet.
- Encounter construction reuses B’s sea-here member without the ship-audio surround change; C’s proof is the delay + different member, not a second B.

## Screenshot index

| File | State |
|---|---|
| `01-encounter-cold.png` | Build sea-here cold |
| `02-bay-delay.png` | Intervening narrative |
| `03-type-cold.png` | Delayed typing cold |
| `03-type-filled-wrong.png` | Location line replay typed |
| `03-type-wrong.png` | Failed Check + recovery |
| `03-type-complete.png` | Question accepted |
| `03-type-cold-dark.png` | Delayed cold, dark |

## Verification

- Unit: `CountyFarraigeFamilyCFixtureTests` — 3/3 pass
- UI: `FarraigeFamilyCUITests` — 2/2 pass on iPhone 17 Pro
