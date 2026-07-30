# Activity Quality Spec

*Operational scorecard for Learning-mode exercise craft. Drafted 2026-07-30.*

This document does **not** own product rules or visual tokens. Those stay in
`PRODUCT.md`, `DESIGN.md`, and `docs/DECISIONS.md` (D26, D27). Use this file to
grade experiments, agent loops, and cluster merges against a fixed bar.

**Ambition:** interaction quality comparable to the strongest language apps on
clarity, finger choreography, feedback, and recovery — without borrowing their
reward economies, identity, or branded motion. An Turas distinction remains
story, Irish, place, evidence, audio, and the limestone visual system.

**Baseline evidence:** Rockfleet Learning screens in `tmp/exercise-screenshots/`
and the 2026-07-30 impeccable critique
(`.impeccable/critique/2026-07-30T15-34-03Z__tmp-exercise-screenshots.md`).
Baseline design-health score: **29/40**. New work must beat that on the shared
dimensions below and clear every D27 contract gate for the cluster under test.

---

## How to use

1. Freeze the **fixture** (screenshot file + pack exercise id) before redesign.
2. Implement against one **work cluster** (see Parallel clusters).
3. Capture four states: unanswered · wrong · repaired · complete.
4. A Composer (or human) tester fills the scorecard below — no freeform taste
   notes without dimension IDs.
5. Any **P0** fail or unmet **contract gate** rejects the pass, even if polish
   is high.
6. Cap **two** design–test rounds per cluster, then a Grok coherence review
   before merge.
7. Update `STATUS.md` inventory rows when a family or container moves from
   Partial / No to contract-met.

### Pass thresholds

| Gate | Requirement |
|---|---|
| Shared dimensions | Mean ≥ **4.0** / 5 across D1–D10; **no score below 3** |
| P0 checklist | All clear |
| D27 contract gates | Every row for the cluster under test is Pass |
| Verification | Simulator screenshots of four states + one UI test covering wrong→repair→complete |
| Accessibility spot | Largest Dynamic Type still one coherent task; Reduce Motion peer path present |

Reject polish that raises aesthetic score while leaving repair, primary hierarchy,
or contract rows red.

---

## Shared dimensions (score 1–5)

Score the **shell and working area together**. Family-specific chrome that breaks
a dimension fails the cluster, not just the family.

### D1 — Task clarity

Within about one second at standard text size, the learner can answer: what to
attend to, how to respond, and which control advances.

| Score | Meaning |
|---|---|
| 5 | Prompt and response area dominate; no taxonomy eyebrow or dead chrome |
| 3 | Task is findable after scanning a crowded header |
| 1 | Response area gated, hidden, or competing with equal-weight controls |

**P0:** Initial state has no dominant response area (e.g. listen-choose gated
empty behind “play first” copy with nowhere to answer).

### D2 — One primary action

Exactly one ink primary per state. Check and Continue share one bottom slot;
Check *replaces* Continue when checking is required. Ghost/moss for Play,
Record, Replay, Hint.

| Score | Meaning |
|---|---|
| 5 | One ink primary; secondaries clearly quieter |
| 3 | Two competing actions but one is slightly stronger |
| 1 | Stacked equal ink bars, or no primary (all ghosts) |

**P0:** Two stacked ink primaries, or speaking/completion path that finishes via
a ghost while the ink bar stays dead.

### D3 — In-place repair

Wrong answers stay editable. The next meaningful touch changes the answer.
Retry is an explicit secondary reset, never the only recovery.

| Score | Meaning |
|---|---|
| 5 | Diagnostic on target; next touch repairs; correct work survives |
| 3 | Repair possible but frictiony (extra confirm, partial lock) |
| 1 | Board or response locks; full restart required |

**P0:** First wrong tap freezes the response behind Retry only (matching board
lock is the reference failure).

### D4 — Finger choreography

Primary response targets sit in comfortable thumb reach on iPhone; all
interactive targets ≥ 44 × 44 pt; drag always has a tap alternative.

| Score | Meaning |
|---|---|
| 5 | Dense, thumb-native board; tiles/choices near the action bar |
| 3 | Usable but mid-screen scatter or far-column matching |
| 1 | Tiny chips, <44 pt, or drag-only |

### D5 — Feedback locality

Diagnostics name what did not fit in plain learner language and attach to the
affected target when possible. Never color, shake, sound, or haptics alone.

| Score | Meaning |
|---|---|
| 5 | Per-target rationale + restrained verdict |
| 3 | Global banner only, still plain language |
| 1 | State-machine copy (“Corrected”, “Keep this answer”) or silent lock |

### D6 — Irish as subject (Two-Voice)

Working Irish uses the story serif. Instructions, glosses, progress, buttons,
and English support use SF Pro. Do not give English the display serif while
Irish answers sit in sans.

| Score | Meaning |
|---|---|
| 5 | Irish serif everywhere it is the working object |
| 3 | Mostly correct with one inversion |
| 1 | Systematic serif/sans flip-flop across families |

### D7 — Audio honesty

Replay (or visible text path) is always available for listening tasks. Missing
audio never traps progress. Response area is not withheld solely to force play.

| Score | Meaning |
|---|---|
| 5 | Audio primary where appropriate; replay + fallback clear |
| 3 | Audio works but secondary controls compete |
| 1 | No replay, silent fail, or empty gated response |

**P0:** Microphone denial or missing clip leaves no continuation path.

### D8 — Motion with meaning

Motion marks lock, repair, and continue — never delays the task. Reduce Motion
gets immediate changes or short crossfades. Correctness stays restrained (no
confetti, XP, hearts, mascots).

| Score | Meaning |
|---|---|
| 5 | Physical, short, Reduce Motion peer |
| 3 | Harmless but generic or slightly late |
| 1 | Blocks input, decorative only, or gamified celebration |

### D9 — Accessibility parity

Selected/disabled/correct states are not color-only. VoiceOver names state.
Largest Dynamic Type keeps task, response, verdict, and action in one coherent
scroll. Contrast meets WCAG for body and controls; disabled labels stay readable
at full opacity via sunk/stone treatment, not 0.45-opacity ink.

| Score | Meaning |
|---|---|
| 5 | Passes VoiceOver + largest type + both appearances on first try |
| 3 | Minor reflow or naming gaps |
| 1 | Color-only selection, unreadable disabled, or clipped task |

**P0:** Selected match or choice conveyed by tint alone with no non-color cue.

### D10 — An Turas distinction without novelty chrome

Product identity comes from Mayo story context, reviewed Irish, place/evidence,
and limestone craft — not a new control grammar per family, tracked mechanism
eyebrows, or Duolingo-like reward theatre.

| Score | Meaning |
|---|---|
| 5 | Familiar shell; story/Irish carry the feeling |
| 3 | Calm but generic; little place or language presence |
| 1 | Per-family chrome invention or gamification leak |

---

## P0 checklist (any fail = reject)

- [ ] Response stays repairable after a wrong answer (no full-board lock).
- [ ] Exactly one ink primary per state; Check and Continue share one slot.
- [ ] Disabled / secondary controls remain readable (tokenised, not off-palette grey).
- [ ] Missing audio and mic denial never trap progress.
- [ ] No hearts, XP, streaks, leagues, confetti, or overdue-debt UI.
- [ ] Drag is never the only way to answer.
- [ ] Family or container still satisfies its D27 contract row below.

---

## D27 contract gates

Score shared dimensions only after these pass for the cluster under test.
`—` means not in scope for that cluster.

### Response families

| ID | Family | Contract gate (Pass / Fail) |
|---|---|---|
| F1 | Listen and choose | Grades on selection; repair window before struggle signal; response visible before/with play; in-place correction |
| F2 | Sentence construction | Multi-part Check; tiles editable until Check; one primary slot; Irish tiles when Irish is the target |
| F3 | Free typed production | Native field + fada aids; Irish input serif; moss reserved for interactive chrome, not atlas-green fada labels |
| F4 | Fill-in-the-blank | Gap is the working object; choice or type per authorship; not a clone of read-respond chrome unless same response method |
| F5 | Matching | ≤4 pairs on one board; wrong pair unlocks for next tap; selection not tint-only; brief distinction task, not mastery |
| F6 | Read or listen and respond | Read path works; listen variant has replay + visible text/meaning route when authored |
| F7 | Record and compare | One primary Record (or Continue after compare); Play model / Play back as secondary; ungraded; mic-denied escape |
| F8 | Grammar discovery | Progressive reveal of worked cases → produce step → rule withheld until produce; not a single MC on one example |
| F9 | Picture or map selection | Meaningful image/map region; live accessible labels; no clip-art slots |
| F10 | Listen and type | Hear then type; replay available; fada-aware; not only `audioPrompted` construction |

### Containers

| ID | Container | Contract gate |
|---|---|---|
| C1 | Conversation | Authored turn graph; branching; resume; setting metadata; not a bare MC list |
| C2 | Radio-style listening | Audio primary; segment replay; transcript or meaning route; interrupt only for a response that improves attention |
| C3 | Contextual mistake review | Returns to original story/sound/sentence/misconception; not bare delayed typing |
| C4 | Words you carry | Shared county shell; preserves first place, audio, example, later uses; no overdue debt |
| C5 | Completion | States capabilities and what returns to atlas/collection; no points theatre |

### Authored uses (configuration checks)

| Use | Parent | Gate |
|---|---|---|
| `ordering` | F2 | Order objective clear; separator/`|` authorship honored |
| `audioPrompted` | F2 | Bundled audio before build; replay available |
| `delayedRecall` | F3 (interim) | Later-page retrieval works; promote into C3 when mistake-review container lands |

---

## Fixtures (Rockfleet Learning path)

Grade against these screens unless a cluster explicitly substitutes the Clew Bay
conversation fixture. Paths under `tmp/exercise-screenshots/`.

| File | Layer | Cluster | Known baseline fails (must clear) |
|---|---|---|---|
| `01-listen-choose.png` | F1 | Choice | Gated response; hollow radios; instant grade without repair feel |
| `02-matching.png` | F5 | Matching | Board lock; 6 pairs; tint-only selection |
| `03-sentence-audio.png` | F2 + audioPrompted | Construction | Dual ink Check/Continue; tile voice |
| `04-sentence-build.png` | F2 | Construction | Dual ink; scattered chips |
| `05-free-typing.png` | F3 | Typing | Two-Voice inversion; fada tint; dual ink |
| `06-conversation.png` | C1 | Conversation | No turn graph / transcript / resume |
| `07-sentence-sequence.png` | F2 + ordering | Construction | Same Check model; English tiles if Irish is target |
| `08-read-respond.png` | F6 | Choice | Read-only; shared hollow radio chrome |
| `09-grammar-discovery.png` | F8 | Grammar | Single MC, not reveal→produce→rule |
| `10-record-compare.png` | F7 | Speaking | Three equal ghosts; no primary |
| `11-fill-gap.png` | F4 | Choice | Identical radio row to 06/08/09 |
| `12-delayed-typing.png` | F3 + delayedRecall | Typing | Same as 05; not yet C3 |

**Not pictured (greenfield):** F9, F10, C2, C3, C4, C5 as specified. Do not score
them as polish passes until fixtures exist in the gallery.

---

## Parallel clusters

Run spectacular craft **after** the shared shell clears P0 items for D2, D3, and
disabled styles. Then parallelize by shared chrome, not by ten independent
families.

| Cluster | Scope | Order |
|---|---|---|
| **Shell** | Anatomy, lifecycle, primary slot, repair, disabled styles, Two-Voice, hint weight | First — serial |
| **Choice** | F1, F4, F6 (+ F6 listen variant) | After Shell |
| **Construction** | F2 + ordering + audioPrompted | After Shell; parallel with Choice / Matching |
| **Matching** | F5 | After Shell; alone |
| **Typing** | F3 + delayedRecall; later F10 | After Choice/Construction patterns exist |
| **Speaking** | F7 | After Shell |
| **Grammar** | F8 (port progressive behavior from legacy discover) | After Shell |
| **Conversation** | C1 Clew Bay acceptance | Runtime + craft; parallel with Speaking/Grammar only |
| **Greenfield** | F9, then F10 | After Choice / Typing |
| **Consolidation** | C2, C3, C4, C5 | After representative run; migration groups 3–4 |

---

## Adversarial test scripts

Every Composer (or human) pass runs these with the same personas. Record
Pass/Fail per script, then fill D1–D10.

### Personas

- **Jordan** — first Learning-mode session; hesitant; will tap wrong once.
- **Sam** — VoiceOver or largest Dynamic Type; needs non-color state.
- **Casey** — one-handed, distracted; thumb zone only.

### Scripts

1. **Cold open (Jordan):** Without reading any family taxonomy label, start the
   task within 3 seconds. Fail if the response area is missing or unexplained.
2. **Deliberate wrong (Jordan):** Give a wrong answer. Repair on the next touch.
   Fail if Retry is required to unlock.
3. **Primary hunt (Casey):** Name the single primary control in the current
   state. Fail if two ink bars or only ghosts.
4. **Thumb reach (Casey):** Complete the task using only the lower two-thirds of
   the screen where possible. Note any far-column or mid-scatter pain.
5. **Largest type (Sam):** Enable the largest accessibility text size. Confirm
   task, response, verdict, and action remain available without clipping meaning.
6. **Reduce Motion (Sam):** Confirm lock/repair/continue still communicate state.
7. **VoiceOver states (Sam):** Selected, disabled, correct, and wrong targets
   expose state in the accessibility value or label.
8. **Audio / mic escape (Jordan):** If the family uses audio or recording,
   trigger missing-audio or deny mic; confirm continuation.
9. **Contract gate:** Mark the cluster’s F/C rows Pass or Fail with one sentence
   of evidence.
10. **Anti-reference scan:** Fail immediately on XP, hearts, streaks, confetti,
    plastic-shamrock decoration, or a new page composition that abandons the
    shared anatomy.

---

## Scorecard template

Copy per cluster review. Attach screenshot paths for the four states.

```text
Cluster:
Fixture files:
Build / commit:
Reviewer (Composer / human):
Date:

Scripts: 1__ 2__ 3__ 4__ 5__ 6__ 7__ 8__ 9__ 10__
P0 checklist: clear / FAIL (list)

D1 Task clarity:        _/5  evidence:
D2 One primary:         _/5  evidence:
D3 In-place repair:     _/5  evidence:
D4 Finger choreography: _/5  evidence:
D5 Feedback locality:   _/5  evidence:
D6 Irish as subject:    _/5  evidence:
D7 Audio honesty:       _/5  evidence:
D8 Motion with meaning: _/5  evidence:
D9 Accessibility:       _/5  evidence:
D10 Distinction:        _/5  evidence:

Mean: _/5
Contract gates: Pass / Fail (IDs)
Verdict: ACCEPT / REJECT
Required fixes (dimension IDs only):
```

---

## Agent loop contract

| Role | Model (suggested) | Duty |
|---|---|---|
| Quality owner | Grok 4.5 | Keep this spec coherent with PRODUCT/DESIGN/D27; periodic cross-cluster review |
| Design / IX | Kimi | Implement one cluster against this spec; cite dimension IDs in notes |
| Adversarial QA | Composer 2.5 | Fill scorecard; reject on P0 or contract fail; no vibe-only approve |

Rules:

- Kimi does not open a second cluster until the open one is ACCEPT or explicitly
  parked after two rounds.
- Composer must use this template; freeform praise without scores is incomplete.
- Grok reviews after every two to three ACCEPT merges: shell drift, duplicate
  anatomies (`ExerciseViews.swift` vs county shell), token forks, gallery matrix
  coverage.
- Reference apps may inform timing and hierarchy only. Do not copy identity,
  mascots, reward UX, or branded motion.

---

## Authority

| If this conflicts with… | Prefer |
|---|---|
| `PRODUCT.md` learning activity system | PRODUCT.md |
| `DESIGN.md` full-screen exercises / buttons / type | DESIGN.md |
| D26 / D27 | `docs/DECISIONS.md` |
| Inventory rows / next steps | `STATUS.md` |
| This scorecard’s thresholds or scripts | Update this file |

When a durable visual or product rule changes, update the owner first, then
adjust dimensions or contract gates here so agents do not enforce a stale bar.
