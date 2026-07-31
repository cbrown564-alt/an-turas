# Representative Mayo Learning-mode run — freeze

*Frozen 2026-07-30 by quality owner (Grok 4.5). Closes STATUS immediate step 1
and rebuild-plan staged step 1 (“Freeze D26 and the representative fixture”).
Does not reopen D26/D27 architecture.*

## Authority

| Document | Role |
|---|---|
| D26 / D27 | Architecture and activity layers — unchanged |
| This freeze | Exact Clew Bay sequence, retained study details, fixture boundary, cluster order |
| `ACTIVITY-QUALITY-SPEC.md` | Craft bar for cluster ACCEPT |
| Shell ACCEPT | `SCORECARD-shell-rescore-2026-07-30.md` at `e4c6a8b` — P0 shell cleared |

Shell craft for F1 / F5 / F7 is ACCEPT. Spectacular family/container passes and
the end-to-end Clew Bay run remain open.

---

## Frozen sequence (Learning mode only)

One fixture-level run. Fixed order. Same Irish, meanings, audio intent, and
accepted responses throughout. Launch may use an internal route; it must exercise
the **shared county activity shell**, not a parallel study runtime.

| Step | Family / container | Clew Bay material | Primary fixture id | Craft cluster |
|---|---|---|---|---|
| 1 | F1 Listen and choose | Hear *farraige*; choose “sea” | `mayo.clew-bay.listen-farraige` | Choice (shell already ACCEPT) |
| 2 | F5 Matching | *farraige* / *bá* / *áit* ↔ sea / bay / place (3 pairs) | `mayo.clew-bay.match-coast` | Matching (shell already ACCEPT) |
| 3 | F2 Sentence construction | Build *Is as Maigh Eo mé* from units | `mayo.clew-bay.build-origin` | Construction |
| 4 | F3 Free typed production | Type the same origin line; tiles gone | **new** `mayo.clew-bay.type-origin` | Typing |
| 5 | C1 Conversation | Present-day Clew Bay; ≥3 turns; opens *Cárb as tú?*; origin line is one acceptable answer; ≥1 branch changes a later partner line; interrupt/resume at current node | **new** `mayo.clew-bay.conversation-origin` | Conversation |
| 6 | F7 Record and compare | Speak the origin line beside the model; ungraded | **new** `mayo.clew-bay.speak-origin` | Speaking (shell already ACCEPT) |
| 7 | F6 Read or listen and respond | One short comprehension task on the Clew Bay setup | **new** `mayo.clew-bay.comprehend-coast` | Choice |
| 8 | C5 Completion | Capabilities: hear *farraige*, distinguish coast words, say the origin line; hand words to **fixture** collection only | **new** `mayo.clew-bay.completion` | Consolidation |
| 9 | C3 Contextual mistake review | Re-enter one struggled target from original sound / sentence after a deterministic test delay | **new** `mayo.clew-bay.review-struggle` | Consolidation |

### Lexeme set (unchanged from studies / draft Ch1)

- *farraige* — sea  
- *bá* — bay  
- *áit* — place  
- *Is as Maigh Eo mé.* — I am from Mayo  

Copy listen / match / build payloads from `content/mayo/grainne-1593.pack.draft.json`
revision in force; do not invent alternate Irish for this proof.

### Authored conversation constraints

- **Setting:** `present-day` only (Clew Bay 1593 must not cast the learner into
  undocumented history).
- Finite authored node graph; no runtime-generated Irish.
- Resume restores the current node after interruption.
- Distinct from step 4: step 4 is unsupported typing; step 5 is multi-turn use.

### Error / recovery scenarios every step must support

Cold open → deliberate wrong → next-touch (or Check) repair → complete; missing
audio inside the task; mic denial on step 6; largest Dynamic Type; Reduce Motion;
exact resume after backgrounding on step 5.

---

## Fixture vs production boundary

| In scope (fixture) | Out of scope |
|---|---|
| Internal Clew Bay Learning run and gallery states | Editing or promoting the nine-chapter Mayo production pack |
| Shared shell + response surfaces for steps 1–9 | Parallel study views / second activity app |
| Fixture collection handoff on completion | County gold, made objects, production review scheduling |
| Deterministic struggle → step 9 | Pedagogical validation or external tester build |
| Rockfleet screens as **craft** scorecard peers where cluster IDs overlap | Treating Rockfleet’s 12-exercise path as this freeze sequence |

Rockfleet Learning screens (`tmp/exercise-screenshots/01`–`12`) remain the
quality-spec craft fixtures for Choice / Construction / Typing / Speaking /
Grammar chrome. The **representative proof sequence** is the Clew Bay table
above, not the Rockfleet chapter order.

---

## Retained study details (synthesis closed)

D27 already kept the shared primitives. This freeze answers the four open
questions from `INTERACTION-STUDIES-REPORT.md` for the selected shell.

### 1. Correction pattern — when local repair overrides a panel

| Response kind | Rule |
|---|---|
| Single-choice (F1, F4, F6) | Grade on selection. Diagnostic on the affected row. Struggle chrome only after the D27 repair window fails. No board lock. |
| Matching (F5) | Wrong pair = brief on-target note + next-tap unlock. Never escalate to mastery-failure / incorrect-phase panel. |
| Multi-part (F2, F3, F10) | Explicit Check. Wrong units stay editable; correct work survives. Short verdict may sit in the shell feedback region; attach per-tile or field notes when the error is local. |
| Conversation (C1) | Wrong turn shows diagnostic on that turn; partner transcript stays; learner may pick another acceptable branch without clearing prior correct turns. |
| Speaking (F7) | No grade. Compare is voluntary; mic-denied escape never traps. |

**Override rule:** if the wrong object is still on screen and tappable, local
in-place repair wins. A generic feedback panel must not become the only recovery
path (Sound Match / Coast Placement lesson).

### 2. Stable shell vs working-model centre

Anatomy stays D26: quiet progress/exit → optional short context → one prompt →
**one dominant response slot** → one ink primary → same-screen feedback →
continue.

The response slot hosts the working model for that family (choice board, match
board, sentence track, text field, turn list, record controls). Familiar chrome
does not change per screen; only the slot contents do (Sentence Flow’s dark
track as a working area is allowed inside the slot; it is not a second shell).

### 3. Scaffold removal — within task vs across the run

| Kind | Where |
|---|---|
| Across the freeze run (required) | Step 3 tiles → step 4 unsupported type → step 5 conversational use → step 6 spoken compare. Same origin line loses support visibly across activities. |
| Within one activity (optional authorship) | Construction may offer a second unsupported rebuild of the same line inside step 3 only if authored; default for this freeze is one construction pass, then step 4. |
| Not for matching in this run | Do **not** replace step 2 with Coast Placement’s labelled→unlabelled map. Three word–meaning pairs are clearer as familiar matching. |

### 4. Quiet An Turas motion / sound / haptic vocabulary

Bind to state only; never delay the next task; no reward theatre.

| Event | Treatment |
|---|---|
| Select / deselect | Restrained highlight; optional light tick haptic |
| Wrong (local) | Rust/on-target note; existing error knock haptic |
| Correct settle | Moss confirm; existing soft chisel / completion haptic vocabulary |
| Pair lock (match) | Brief settle on both sides; unlock on wrong without board freeze |
| Tile place / return (construction) | Matched movement into track when Reduce Motion is off; instant snap when on |
| Continue / complete | Single flourish only on run completion (step 8), not after every item |

Reduce Motion: communicate state with layout and text; drop custom movement.
Do not import Duolingo/Brilliant identity, mascots, XP, hearts, streaks, or
confetti.

### Explicitly not retained

- Three study views as runtime  
- Bespoke coast map for distinctions matching already teaches  
- Study-local colour constants as global tokens  
- Recognition or tile rebuild as proof of free recall  
- Story exposition inside the activity screen  

### Spatial detail deferred (not discarded)

Coast Placement’s region-as-answer model is reserved for **F9 picture or map
selection** when geography *is* the distinction (migration / Greenfield cluster).
It is out of this nine-step freeze run.

---

## Cluster build order (for Design / IX — Kimi)

Shell is done. Implement against this freeze and
`docs/ACTIVITY-QUALITY-SPEC.md`. Cap two design–test rounds per cluster.

| Order | Cluster | Freeze steps | Notes |
|---|---|---|---|
| A | Choice | 1, 7 | Spectacular polish on F1; implement F6 listen-or-read path for step 7 |
| B | Construction | 3 | F2 + keep audioPrompted patterns available; Irish tiles when Irish is target |
| C | Matching | 2 | Spectacular polish only; contract already Pass at shell |
| D | Typing | 4 | F3; author `type-origin`; Two-Voice + fada bar |
| E | Speaking | 6 | Spectacular polish; author `speak-origin` |
| F | Conversation | 5 | **Hard gate for the run** — full turn graph, branch, resume |
| G | Consolidation | 8, 9 | C5 capability summary + C3 struggle return; fixture collection only |
| — | Grammar / Greenfield | — | **Parked** until the freeze run operates end-to-end (F8, F9, F10, C2, C4) |

Parallelism allowed among A–E after Shell ACCEPT; **F before claiming the run
complete**; G last. Do not open Grammar or Greenfield until steps 1–9 operate
with incorrect and recovery paths.

### Acceptance for “run frozen and operable”

1. All nine steps reachable in order on simulator via shared shell.  
2. Each in-scope cluster has a Composer scorecard ACCEPT (or Shell ACCEPT already
   covering F1/F5/F7 craft bar, with spectacular notes if improved).  
3. Conversation proves branch change + interrupt/resume.  
4. Completion and contextual review do not write production county gold or
   scheduler debt.  
5. `STATUS.md` inventory rows updated for contract-met families/containers.

---

## Common start / error / recovery / completion script

Use for UI tests and Composer adversarial scripts on the freeze run:

1. Open step 1 cold; answer without requiring play.  
2. Wrong once on steps 1 and 2; repair next touch.  
3. Build origin (3); type origin (4) with fada aids.  
4. Conversation (5): take a wrong turn, repair; take a branch that changes the
   next partner line; background and resume mid-graph.  
5. Speak (6) with mic denied once, then record/compare path.  
6. Comprehension (7); complete (8); force a struggle earlier and hit review (9).  

---

## Record

| Field | Value |
|---|---|
| Date | 2026-07-30 |
| Owner | Grok 4.5 (quality owner) |
| Architecture | D26 one-screen shell; D27 layers — not reopened |
| Shell gate | ACCEPT `e4c6a8b` |
| Next agents | Kimi — clusters A→G; Composer — scorecards; Grok — post-merge coherence |
