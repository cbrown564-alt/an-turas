# Story and learning rebuild

*Confirmed 15 July 2026 and amended 30 July 2026 for D26's selected learning activity
system. This is the implementation plan for the Phase 3 rebuild.
`PRODUCT.md`, `DESIGN.md`, `STATUS.md`, `DECISIONS.md`, `COUNTY-ATLAS.md`, and
`CONTENT-PIPELINE.md` remain the canonical owners for their respective concerns.*

## Outcome

Rebuild the four-county road around one authored page sequence with two filtered
experiences:

- **Story mode** presents the complete narrative and only interactions needed to
  understand the story or evidence.
- **Learning mode** presents a shorter but coherent version of the same story and all
  language exercises in their authored positions.

Mayo is the representative implementation. Do not invite another external tester
round until Mayo, Offaly, Dublin, and Meath all pass the internal readiness gate in
this plan.

The active next work is the learning-mechanics foundation sprint below. Mayo now
serves only as realistic fixture content for that sprint. Do not improve one Mayo
chapter, author more chapter content, integrate another county, or spread the current
exercise implementation until the foundation gate passes.

## Why the current build does not pass

The working four-county product proves navigation, progress, evidence, collection,
review scheduling, and offline pack installation. It does not prove content depth or
learning quality.

- Mayo's six episodes and 18 beats are too short for the intended flagship story.
- Offaly, Dublin, and Meath began as four-episode, twelve-beat editorial previews.
  Their full review drafts are now bundled, but the review gates remain open.
- Each new county has only four required interactions for 20 provisional words.
- The new county flow mostly bypasses the stronger exercise mechanics already present
  in the legacy page system.
- Completing a preview currently schedules all 20 words even though most were not
  introduced, retrieved, produced, or reused.
- The pack validator rewards a fixed episode and beat count rather than narrative
  depth, exercise variety, or word lifecycle coverage.

## Target experience

### One sequence, two modes

Every county pack contains chapters and stable page ids. Each page is visible in
Story mode, Learning mode, or both.

**Story mode:**

- includes all core and extended narrative pages;
- includes maps, sources, evidence handling, and story-essential responses;
- contains no language-assessment gate;
- records that the county story was read and opens the next county;
- does not turn the county gold or claim that its 20 words were learned.

**Learning mode:**

- retains each chapter's setup, stakes, turn, consequence, and evidence limit;
- omits optional narrative depth;
- includes every required language exercise;
- turns the county gold only when the 20-word learning path is complete;
- moves those words into **Words you carry** and makes them eligible for later review.

The learner chooses a mode at the county opening and may change it from the chapter
menu. Shared pages keep one completion record. Switching mode moves to the next
incomplete visible page without restarting the county or granting unearned progress.

### Narrative scope

Mayo targets eight to ten chapters and 60–90 minutes in Story mode. D23 approves this
nine-chapter production shape:

1. **Clew Bay and Umhaill** — coast, islands, routes, and the political world in which
   maritime authority was possible.
2. **Marriage, kin, and alliances** — the family relationships and bases of power the
   surviving record can support.
3. **Rockfleet** — castle, harbour, household, children, followers, and boats as one
   connected system.
4. **Power at sea** — trade, tolling, raiding, coercion, wealth, and pragmatic
   alliances without romanticising them.
5. **Bingham closes in** — pressure on Gráinne's kin, livelihood, and authority, with
   competing accounts kept visible.
6. **The road to London** — why the crossing became necessary and what it demanded.
7. **Gráinne in the record** — the interrogatory, her name, family, lands, and voice
   shaped by state questions.
8. **The royal answer** — the order for relief and the limits of an answer on paper.
9. **Return and afterlife** — later petitions, Rockfleet and Clew Bay today, and the
   distinction between record and legend.

This sequence is subject to the source brief, claim ledger, historian review, and
storyboarding. No chapter exists primarily to accommodate vocabulary.

Other launch counties normally target six to eight chapters and 45–75 minutes in
Story mode. Evidence and dramatic shape determine the final chapter count; there is
no fixed three-beat template.

## Implementation sequence

### Phase 0 — Reset the product contract

1. Record the feedback as the active Phase 3 problem.
2. Pause external testing and additional county expansion.
3. Replace the fixed four-to-six episode and three-beat pack rule.
4. Lock mode visibility, completion, collection, and atlas behavior in the canonical
   documents.
5. Record the current baseline for narrative duration, exercise mix, 20-word
   lifecycle coverage, accessibility, and completion behavior.

**Exit:** canonical documents contain one consistent answer for modes, page
visibility, progress, county advancement, and gold.

### Phase 1 — Unify the county content model

Move the four stories into versioned content packs. Swift owns interaction mechanics;
the packs own story and exercise content.

Each pack must provide:

- chapters with variable page counts;
- stable chapter and page ids;
- `storyOnly`, `learningOnly`, or `both` visibility;
- story-required, learning-required, and optional completion status;
- lexeme, grammar-pattern, evidence, source, audio, and image references;
- exercise family, objective, answer, distractor rationale, feedback, hint, and
  recovery;
- estimated reading or interaction time;
- explicit Story-mode and Learning-mode completion requirements.

Remove county copy from `GrainneFullStory.swift` and `LaunchCountyStories.swift`.
Migrate existing beat-index progress to stable page ids without losing evidence,
artifacts, words, or scheduled review state.

**Exit:** one county pack renders both modes; switching preserves progress; old saves
migrate deterministically.

### Phase 2 — Build the full-screen exercise system

**Historical phase boundary:** this phase produced the first shared shell and twelve
mechanic families. D26 and the active foundation sprint below now own the selected
activity set and migration requirements; do not treat the numbered list here as the
current complete family inventory.

Create one shared full-screen exercise container with:

- chapter context and quiet progress;
- one clear task per page;
- standard unanswered, incorrect, hint, corrected, and complete states;
- immediate diagnostic feedback and an explicit retry;
- safe-area-aware primary actions;
- keyboard and fada support;
- bundled audio playback;
- local-only recording for speaking exercises;
- VoiceOver, Dynamic Type, Reduce Motion, Increased Contrast, and both appearances.

Reuse and improve the existing mechanics, adding missing sentence and comprehension
variants:

1. listen and identify a word or phrase;
2. listen and build a complete sentence;
3. build an Irish sentence from meaning or story context;
4. fill a sentence gap;
5. match related words, phrases, or audio;
6. type a phrase or sentence with fada-aware correction;
7. complete a dialogue turn;
8. sequence language, events, or evidence;
9. answer story and source-comprehension questions;
10. record and compare speech with the model, without grading;
11. discover a grammar pattern from examples;
12. retrieve material after a delay.

Add an internal exercise gallery covering correct, incorrect, retry, missing-audio,
denied-microphone, long-copy, and accessibility-size states.

**Exit:** every mechanic shares the same feedback model and passes direct
accessibility inspection.

### Phase 3 — Prove one Rockfleet chapter

Rebuild the chapter represented by the current *Caisleán. Teaghlach. Mac. Bean.*
screen before spreading the pattern.

The proof must contain:

- a materially richer Story-mode chapter;
- an abridged but causally complete Learning-mode version;
- at least five full-screen exercise mechanics;
- single-word listening, sentence construction, matching, fill-in-the-blank, and
  ungraded speaking;
- a realistic wrong-answer and recovery path;
- later reuse of language introduced in the chapter;
- seamless mode switching and exact-page resume.

Inspect the complete chapter on an iPhone simulator and physical iPhone in both
appearances and at accessibility text sizes.

**Exit:** the representative chapter passes every standard below. Revise the model or
mechanics before authoring the remaining chapters if it does not.

### Foundation sprint — Make the shared learning mechanics production-ready

**Active before Phases 4–6.** The Rockfleet proof established that the app can render
the required exercise families in one calm full-screen shell. It did not yet establish
one complete runtime contract for attempts, support, completion, learner memory, and
every accessibility and failure state. This sprint closes that gap before the pattern
is applied more widely.

**Direction selected:** D26 adopts a familiar one-screen, one-task activity system.
The interactive HTML field guide and user review close the earlier requirement to
choose between competing activity architectures. The app should not spend another
sprint making routine learning tasks more bespoke. Existing iOS interaction studies
remain removable research inputs; their useful response, support, or recovery details
may be retained without treating them as product directions awaiting selection.

Mayo is fixture content, not the editorial target. Use existing Mayo language,
exercise payloads, audio references, and story context to exercise realistic lengths,
fadas, sentence shapes, and evidence questions. A fixture may be copied into a
test-only gallery or adapter when isolation is required, but the sprint does not
rewrite Mayo prose, add exercises to a chapter, close a content review gate, or claim
that Mayo is more complete.

#### Scope

The sprint must produce:

- one representative Mayo Learning-mode run using the selected full-screen activity
  architecture and the same small fixture slice used by the interaction research;
- one shared exercise runtime and state model used by every response component;
- one authored learning contract for every exercise;
- common response components for the D26 activity set;
- deterministic learner-memory signals that scheduled review can consume;
- an internal mechanics gallery and QA harness with direct access to every important
  state and failure;
- a versioned content-pack path and validators for the authored contract;
- automated coverage plus direct simulator and physical-device verification;
- a recorded foundation-gate decision before any production pack is migrated or any
  chapter or county is authored against the revised system.

The sprint preserves the product's story-first order. An exercise may use only
language and evidence that the preceding Learning-mode pages have made meaningful.
The exercise shell remains quiet, native, and subordinate to the county account.

#### Non-goals

This sprint does not:

- improve Rockfleet or any other Mayo chapter as a story;
- author, translate, review, record, or illustrate new production content;
- add counties, integrate the nine-chapter Mayo draft, or promote any review draft;
- replace Story and Learning modes, the atlas, evidence views, or collection;
- grade pronunciation or introduce speech recognition;
- create a self-directed adaptive curriculum or silently change lesson order;
- clear historian, pedagogy, audio, rights, accessibility, or release gates for a
  county;
- add XP, hearts, streaks, leagues, confetti, cartoon rewards, artificial waits,
  overdue counts, or review debt.

#### Critical path: prove the selected slice, then consolidate

D26 closes the benchmark-and-selection stage. The first executable product outcome is
now a coherent Mayo Learning-mode run in which familiar full-screen activities replace
the current bespoke or mixed exercise compositions. Do not begin by migrating every
production pack, completing the scheduler, or generalising every component. Prove the
selected shell and its hardest representative response paths first, extract the shared
runtime from evidence, then spread it family by family.

The HTML activity field guide is the interaction reference. It is not a visual
specification and is not production content. The iOS implementation uses the An Turas
design system, native controls, safe areas, Dynamic Type, VoiceOver, both appearances,
Increased Contrast, and Reduce Motion.

Use public learning products only as interaction-quality references. Duolingo is a
useful reference for immediate task clarity, response speed, progressive practice,
and legible feedback. Brilliant is a useful reference for construction, guided
discovery, and visual manipulation that makes an idea graspable. Other products may
be added only when they contribute a named technique the team needs to test. Do not
copy branded visuals, sounds, characters, copy, content, proprietary sequencing, or
reward systems.

##### Reference adaptation matrix

| Stance | Techniques | An Turas requirement |
| --- | --- | --- |
| Emulate or adapt | Clear task framing; progressive difficulty; active recall and production; immediate explanatory feedback; construction and manipulation; visual reasoning when it makes the idea clearer; fast iteration | Match the underlying interaction clarity and responsiveness while using An Turas story context, Irish, evidence boundaries, visual system, and native iOS behavior. |
| Test cautiously | Guided scaffolding; momentum between related tasks; authored branching | Use only when the technique answers a named learning question. Keep support visible, let the learner pause, make every branch and sequencing rule deterministic and explainable, and reject any version that weakens the story or creates pressure. |
| Reject | XP; hearts; streaks; leagues; mascot-driven rewards; urgency or social pressure; artificial waiting; debt-like review queues | Do not prototype these as options. They conflict with the product rather than representing an unresolved direction. |

##### Representative Mayo implementation slice

The first implementation proof is explicitly a **Mayo learning slice**, not a
Rockfleet mechanics demo. Use the existing revision-6 Clew Bay fixtures
`mayo.clew-bay.listen-farraige`, `mayo.clew-bay.build-origin`, and
`mayo.clew-bay.match-coast`. Together they connect the sound and meaning of
*farraige*, the produced line *Is as Maigh Eo mé*, and the language of the Clew Bay
coast. Copy those payloads unchanged into the internal study fixture layer; this
does not bundle or promote the revision-6 county pack.

Every activity in the representative run uses the same Irish, translation, Mayo story
setup, audio, accepted responses, likely errors, and completion goals. If one fixture is technically
unusable, replace it with the smallest existing **Mayo** fixture set that covers the
same listening, production, meaning, error, and recovery loop, and record the ids
before coding.

Do not add new production prose or exercises to make an activity family work.
Prototype-only composition or support copy must be visibly identified in code and the
study record as disposable fixture material.

##### Superseded comparison record

The following criteria explain the comparison work that preceded D26. They are
retained as a research record, not active implementation instructions. Do not build
more directions or require another selection round before beginning the representative
slice.

The earlier comparison required two to four directions. Each direction had to change
at least
two of these:

- what the learner must recall or construct;
- when, and in what form, support appears;
- how the learner manipulates or produces Irish;
- how a misconception is diagnosed;
- how recovery changes the next attempt;
- how story context or evidence motivates the response.

A color, spacing, animation, typography, card, or button-layout variation does not
count as a direction. Each direction must also name the reusable primitives it would
contribute to later exercises; a one-off Mayo trick is not enough. Useful
starting hypotheses include:

- **Ear-first retrieval:** hear *farraige*, then produce *Is as Maigh Eo mé* from the
  Mayo story cue before seeing construction support.
- **Guided construction:** assemble the origin line from meaningful units, then
  remove support and retrieve it again after diagnostic feedback.
- **Contrast and discovery:** compare the existing Clew Bay coast terms, notice their
  distinct meanings, then apply the distinction before producing the origin line.
- **Visual place reasoning:** use the existing Clew Bay place relationships to connect
  sea and coast language, then produce the same Mayo origin line without the visual
  scaffold.

These were hypotheses, not product families. D26 selects the conventional full-screen
activity architecture and supersedes further comparison.

##### Superseded in-app comparison loop

The completed comparison used this intended loop:

1. State one learning question for the slice, such as whether Clew Bay can help the
   learner connect *farraige* to place and produce *Is as Maigh Eo mé* without reading
   the answer.
2. Freeze the Mayo fixture ids and a common start, error, recovery, and completion
   scenario.
3. Add one internal comparison entry in the running app. It lists the directions,
   launches each from the same initial state, preserves no cross-variant answer
   advantage, and returns to a concise comparison view.
4. Implement only the code needed to feel each direction honestly. Temporary
   duplication is preferable to an early shared abstraction that makes the variants
   artificially alike.
5. Verify each direction at standard and largest accessibility text sizes, in light
   and dark appearances, with VoiceOver reading order and actions, and with Reduce
   Motion. Exercise its incorrect and recovery path. Fix blocking access defects
   before comparison; the full gallery matrix remains a later consolidation gate.
6. Present the working variants with captures, the rubric below, material tradeoffs,
   and known shortcuts. The user operates the variants and selects one direction or
   asks for one bounded revision round.
7. Record the chosen direction, rejected alternatives, rationale, and unresolved
   risks as a durable decision in `docs/DECISIONS.md`. D26 is that decision.
8. Delete or isolate rejected variant code. Extract only the chosen interaction,
   feedback, and recovery primitives into the shared runtime, then continue the
   foundation stages.

##### Historical decision rubric

Score each direction from 1 (fails) to 4 (strong), with one observed reason for every
score. **Clarity of task** and **accessibility** are hard gates: a direction scoring
below 3 on either cannot be selected without revision. The user may choose against the
highest total when the recorded tradeoff better serves the product.

| Criterion | Question |
| --- | --- |
| Clarity of task | Can the learner tell what to attend to, do, and check without explanation? |
| Meaningful story connection | Does the Mayo and Clew Bay context make the Irish response necessary or memorable, rather than decorating a generic drill? |
| Active recall and production | How much of the target must the learner retrieve, construct, say, or manipulate instead of recognise? |
| Quality of recovery | Does an error produce a useful diagnosis and a changed next attempt without revealing the whole answer or shaming the learner? |
| Emotional tone | Does the direction feel calm, adult, exacting, and encouraging without reward theatre or pressure? |
| Native iOS usability | Are selection, input, audio, keyboard, navigation, focus, and response time familiar and dependable? |
| Accessibility | Do Dynamic Type, VoiceOver, both appearances, Reduce Motion, target size, non-audio meaning, and non-drag operation preserve the task? |

The selection closed the interaction-architecture question for consolidation. It did
not validate learning outcomes. Pedagogue review and learner evidence remain later
gates.

#### Selected activity architecture

##### Shared page anatomy

Every Learning-mode activity uses the same outer composition:

1. a native exit or back action and quiet chapter progress;
2. optional context, limited to what the learner needs for this task;
3. one task prompt;
4. one dominant response area;
5. one primary action above the safe area;
6. diagnostic or completion feedback on the same screen; and
7. one continue action into the next story or activity page.

At standard text sizes, the full task should fit in one viewport. At accessibility
sizes, the shell becomes one scrollable composition and keeps the prompt, formed
response, feedback, and primary action reachable. Story exposition does not accumulate
inside the shell. If context requires more than a short paragraph or one inspectable
source excerpt, it belongs on the preceding story page.

The shell uses native SwiftUI focus, keyboard, navigation, audio-session, permission,
and accessibility behavior. It does not reproduce the HTML prototype's phone frame,
layout, typography, or colors.

##### Core response families

These ten families satisfy the shared response contract. The five containers follow in
their own table; D27 owns the distinction.

| Family | First implementation requirement | Learning boundary |
| --- | --- | --- |
| Picture or map selection | One meaningful image, object, document detail, or map region per option; semantic selection group; authored rationale per distractor; checks on selection | Use only when the visual carries meaning. Generic illustration is not an acceptable substitute. |
| Sentence construction | Tap to add and remove; reorder without drag; preserve meaningful multiword units; VoiceOver move actions | Supported construction must later lead to recall or production without the visible answer. |
| Free typed production | Native text input; fada toolbar; declared normalization; precise fada and structure diagnostics; keyboard-safe action | Accept harmless declared variants. Do not silently strip meaningful orthographic distinctions. |
| Fill-in-the-blank | One consequential missing unit; editable choice or typed response; rationale for nearby alternatives; single-answer choice variants check on selection | Do not blank a random token merely to create a question. |
| Listen and choose | Bundled audio, replay, playback state, authored non-audio fallback, misconception-based options; checks on selection | Recognition is introduction or diagnosis, not complete word learning. |
| Listen and type | Bundled audio and replay plus native typing; distinguish listening from spelling errors in feedback | Do not fail comprehension solely because first-exposure spelling is incomplete. |
| Record and compare | Model replay, record, stop, learner playback, re-record, compare or continue; ephemeral local audio; denied-microphone continuation | No score, pronunciation verdict, retained recording, or gated progress. |
| Matching | Tap one item then its partner; non-drag and VoiceOver path; pair-level feedback and completion | Use briefly to establish a distinction. Matching alone does not earn clean-recall credit. |
| Read or listen and respond | Short reviewed passage; response increasingly stays in Irish; route back to relevant context | Questions test meaning, implication, or evidence—not whether the learner noticed the previous sentence. |
| Grammar discovery | Reveal worked cases in the authored order; withhold the rule until a produce step is answered; make the contrast explicit on completion | Recovery may expose one worked case but still requires a fresh application. |

##### Containers

A container hosts or ends activities rather than being a way to answer, so it does not
satisfy the response contract. Each declares its own.

| Container | First implementation requirement | Learning boundary |
| --- | --- | --- |
| Conversation | Finite reviewed node graph; clear preceding speaker and turn; learner choice or bounded input selects a branch; every acceptable response authored; pragmatic and grammatical feedback; deterministic resume and completion | No real-time generated Irish. A historical-bounded setting never invents participation in history; the learner remains themselves. |
| Radio-style listening | Audio-primary screen, segment replay, transcript or meaning route, sparse comprehension interruptions | Use reviewed narration, oral history, or clearly labelled performed archival material. |
| Contextual mistake review | Reconstruct the exact sound, sentence, place, or misconception that caused difficulty; bounded optional run | No accumulated debt, overdue count, broken-heart framing, or loss of county progress. |
| **Words you carry** practice | Review a word through its first place, audio, sentence, target capability, and later uses | Do not reduce carried words to a context-free vocabulary inventory. |
| Completion | State capabilities gained, carried words or evidence, next story choice, and any optional later review | No XP, accuracy theatre, confetti, mascot reaction, streak threat, or artificial delay. |

**Setting** is authored metadata on a conversation, not a structural difference:
*historical-bounded*, where the learner stays themselves and the evidence limit holds,
or *present-day*, where they converse freely. A conversation whose branches never change
a later partner line is a single-turn exercise and must be authored as one.

##### Representative slice flow

The first end-to-end Mayo proof uses the selected architecture in this order:

1. **Listen and choose:** hear *farraige* in Clew Bay context and identify its
   meaning.
2. **Matching:** distinguish *farraige*, *bá*, and *áit* once, with pair-level
   recovery.
3. **Sentence construction:** build *Is as Maigh Eo mé* from meaningful units.
4. **Free typed production:** retrieve the same line after the tiles and labels are
   removed.
5. **Conversation:** a present-day Clew Bay exchange of at least three turns that opens
   with *Cárb as tú?* and takes the origin line as the learner's answer. At least one
   branch must change a later partner line, and the run must survive interruption and
   resume at the current node.
6. **Record and compare:** say the origin line beside the reviewed model without a
   score.
7. **Read or listen and respond:** answer one short Irish comprehension task grounded
   in the Clew Bay setup.
8. **Completion:** state what the learner can now hear, distinguish, and say; return
   the words to the fixture collection without touching production county progress.
9. **Contextual review fixture:** re-enter one struggled target from its original
   sound, coast, or sentence after a deterministic test delay.

The conversation is deliberately the hardest container and sits inside the first proof
rather than after it. The shared runtime must meet multi-turn state, branching, and
resume before the abstraction is extracted; deriving it only from single-screen families
and fitting the containers afterwards would invalidate the group gates already passed.
Radio-style listening is the easier segment case and follows in group 3.

The Mayo fixture is Clew Bay in 1593, so its conversation cannot be historical-bounded:
a present-day setting is the only one that does not cast the learner into undocumented
history. It also keeps the conversation distinct from step 4 rather than repeating the
same single answer in a new frame.

This sequence is a fixture-level implementation proof. It does not add these pages to
the production Mayo pack or claim that the sequence has passed pedagogue or learner
validation.

##### Family grouping for migration

Implement and verify in bounded groups:

1. **Recognition:** picture or map selection, fill-in-the-blank, listen and choose,
   matching.
2. **Construction and production:** sentence construction, free typing, listen and
   type, record and compare.
3. **Contextual use:** read or listen and respond, grammar discovery, and radio-style
   listening. Conversation is already proven by the representative slice; this group
   extends it to the remaining authored settings.
4. **Consolidation:** contextual mistake review, **Words you carry** practice, and
   completion.

A group is complete only when every family and container in it uses the shared runtime,
authored contract, gallery, persistence rules, and accessibility behavior. Do not mark a
group complete because one happy path renders.

##### Implementation ownership

Keep each concern in one place:

| Concern | Current owner or target |
| --- | --- |
| Exercise families and content decoding | `ios/AnTuras/CountyStoryPack.swift`; extend `CountyExerciseFamily` and the versioned exercise payload without embedding runtime state in content. |
| Current county exercise rendering | `ios/AnTuras/CountyExerciseSystem.swift`; use as the migration boundary, then split the pure runtime, shared shell, and response views only when the representative slice proves the separation. |
| Story/activity page transition and exact resume | `ios/AnTuras/CountyStoryExperienceView.swift` and the existing stable page-progress model. |
| Later word practice | `ios/AnTuras/LexemeDeck.swift`; migrate its presentation onto the shared response components without letting the deck own a second grading model. |
| Persisted learner state and review handoff | existing progress and personal-foundation stores plus `docs/DRILL.md`; persist bounded attempt/support signals, never recordings or unnecessary answer text. |
| Swift validation | `CountyStoryPack` decoding and validation tests in `ios/AnTurasTests/`. |
| Offline authoring validation | `tools/validate_county_pack.py` and `tools/tests/test_validate_county_pack.py`; keep its accepted and rejected fixtures aligned with Swift. |
| Interaction and failure gallery | evolve the internal `CountyExerciseGalleryView` or replace it with one manifest-driven activity gallery. The disposable study gallery was removed with the study code once D27 recorded the retained primitives. |
| End-to-end UI verification | `ios/AnTurasUITests/`; cover the representative run, one state matrix per family group, exact resume, offline relaunch, keyboard, audio, microphone, and branching. |
| Xcode project membership | `ios/project.yml`; regenerate the project after adding, moving, or removing source, resource, target, or build-setting entries. |

Avoid a parallel “new activity app” beside the county runtime. The representative
fixture may launch from an internal route, but it must exercise the same runtime,
shell, and response components that production county pages will use.

#### Shared runtime and state model

Every exercise family must render through the same state engine. A component supplies
and reads a typed response; it does not own correctness, hint, retry, completion,
memory credit, or persistence rules.

The visible lifecycle is:

1. **Unanswered** — the task and response component are available, no answer has been
   judged, and no correctness language is shown.
2. **Attempt** — the learner has selected, arranged, typed, spoken, or otherwise
   formed a response. A selected-but-unchecked response remains editable. Checking the
   response creates an immutable attempt event.
3. **Diagnostic feedback** — an incorrect attempt is frozen long enough to show what
   did not fit and why. Feedback refers to the learner's response or a named likely
   misconception; “wrong” alone is not valid feedback.
4. **Hint or recovery** — a hint narrows attention without silently answering the
   task. Recovery reduces or restructures the same objective when another identical
   retry would not teach anything. Neither state completes the exercise by itself.
5. **Retry** — the response becomes editable again and the learner makes a new
   attempt. The relevant diagnostic or chosen support remains reachable. A retry is
   not a delayed replay of the first submission.
6. **Complete** — the learner has produced the exercise's declared completion
   evidence. The verdict states what they did, provides one clear continue action,
   and records the level of support used.

Required transitions:

```text
unanswered → attempt
attempt → complete
attempt → diagnostic feedback
unanswered → hint → attempt
diagnostic feedback → retry → attempt
diagnostic feedback → hint → retry → attempt
diagnostic feedback → recovery → retry → attempt
attempt → diagnostic feedback → … → complete
```

Back navigation, app backgrounding, interruption by audio or microphone permission,
and view recomposition must not invent a new attempt or lose a completed one. Reopening
a completed page may allow practice, but cannot remove completion or duplicate memory
credit. Illegal transitions must be rejected by the state engine and covered by unit
tests.

Each checked attempt records, at minimum:

- exercise id and stable target-language ids;
- attempt ordinal;
- outcome: correct or incorrect;
- whether diagnostic feedback was shown;
- whether a hint was used;
- whether recovery was used;
- the declared completion-evidence kind;
- completion and memory-credit status.

Do not persist microphone audio, a verbatim free-text response, or answer-option
history merely to support scheduling. Speaking recordings remain ephemeral and
on-device. Persist only the bounded state needed for resume, completion, support
signals, and review.

#### Shared shell and response components

The shell owns chapter context, quiet progress, task title, objective, response area,
feedback/support area, and one primary action above the safe area. Components own
only response capture and presentation. Correctness, diagnostic selection, retry,
completion, accessibility announcements, and memory events remain shared.

| Component | Required behavior |
| --- | --- |
| Listening and replay | Use bundled model audio, show a labelled Play/Replay control and playback state, prevent overlapping playback, and expose an authored non-audio route when playback is unavailable. A learner may replay without penalty. A text fallback marks the attempt as supported when it changes a listening objective. |
| Picture and map choices | Use real content or a semantically accurate map region, expose each option as one labelled selection, provide text alternatives for meaningful visual detail, and map every distractor to an authored rationale. The family is unavailable when no visual representation improves meaning. |
| Choices and fill gaps | Use one semantic selection group with 44-point rows. Single-choice families check on selection and carry Continue as the primary action; multi-part responses stay editable until an explicit Check. Every wrong option maps to an authored rationale or named misconception. Correctness is never exposed by color or option order alone. |
| Sentence tiles | Support tap-to-add, tap-to-remove, and deterministic reordering. VoiceOver offers equivalent add, remove, move earlier, and move later actions; dragging is optional. Multiword units remain atomic when the learning objective is syntax rather than spelling. |
| Irish typing | Use native text input and the existing fada toolbar. Precomposed and combining Unicode forms compare equally; case, surrounding whitespace, and declared punctuation variants follow authored rules. Fadas are not stripped from correctness: a missing or misplaced fada produces a specific diagnostic unless the contract explicitly makes it irrelevant. Keyboard appearance or dismissal must not hide the task, feedback, or primary action. |
| Matching | Support tap-one-then-tap-partner as the baseline. Any drag treatment has the same tap and VoiceOver alternative. A wrong pair remains identifiable for diagnostic feedback; completing one pair cannot accidentally complete or credit the whole set. |
| Comprehension | Test the story, source, or evidence limit already encountered. Feedback distinguishes what the evidence supports from inference or legend and offers a path back to the relevant page when useful. |
| Grammar discovery | Reveal examples in the authored order, withhold the rule until the learner has attended or responded, and make the inferred contrast explicit on completion. Recovery may expose one worked case but still requires a fresh application. |
| Conversation | Present the preceding turn and speaker clearly, allow every authored acceptable response, and explain pragmatic or grammatical fit. Decode a finite versioned node graph, preserve the current node across interruption, make every partner line and acceptable learner path reviewable before bundling, and route bounded free input only through authored intents. It never calls a runtime language model, and a historical-bounded setting never casts the learner as an undocumented historical participant. |
| Radio-style listening | Keep playback and segment replay primary, expose progress without speed pressure, preserve an authored transcript or meaning route, and insert only sparse tasks that improve listening attention or comprehension. |
| Record and compare speaking | Provide model play/replay, record, stop, learner playback, re-record, and compare/continue. There is no pronunciation score or pass/fail. Microphone denial explains the limitation and offers model-listen plus unrecorded self-comparison so progress is never trapped. Recordings are discarded when the exercise or app session ends unless the learner deliberately keeps listening within that exercise. |
| Contextual mistake review | Recreate the target and misconception from the original exercise event, choose a bounded authored review form deterministically, explain why the item returned, and allow exit without penalty. |
| **Words you carry** practice | Query by stable target id, preserve first encounter and later-use context, offer authored practice forms appropriate to the capability, and keep collection state distinct from scheduler state. |
| Completion | Summarise declared capabilities and carried material from completed target events, offer one next action and optional bounded review, and never derive reward copy from points, accuracy, speed, streak, or absence. |

Every component must expose a typed response value and the same actions:
`update response`, `check`, `request hint`, `begin recovery`, `retry`, and
`complete`. A family-specific view must not call county completion, schedule review,
or advance the page directly.

#### Authored learning contract

Every exercise, including an optional or test-fixture exercise, must declare:

- **Objective:** one observable ability, written as what the learner will understand,
  distinguish, recall, construct, interpret, or compare.
- **Target language:** stable lexeme and/or grammar-pattern ids plus whether each
  target is being recognised, recalled, produced, interpreted, or spoken for
  comparison.
- **Likely misconception or rationale:** the plausible confusion being tested.
  Choice distractors retain per-option rationales; constructed responses require
  named diagnostic cases and an authored fallback for an unclassified response.
- **Diagnostic feedback:** plain-language feedback for each named misconception and a
  success message that restates the achieved objective without praise inflation.
- **Hint:** the smallest useful cue that directs attention without revealing the
  complete response.
- **Recovery:** a supported version of the same objective, including the response the
  learner must still make after support.
- **Evidence of completion:** a typed rule such as correct selection, correct
  construction, corrected construction, reconstructed response, valid dialogue turn,
  ordered sequence, or completed record-and-compare cycle.

The runtime must not infer pedagogy from display copy. Prompts, answers, tokens,
pairs, audio, and options remain family-specific response data; the learning contract
states why that data exists and what completion means.

#### Learner memory and scheduled review

Inline Learning-mode exercises own the evidence emitted during the county path.
`docs/DRILL.md` remains the owner of later scheduled-review presentation and interval
policy. The handoff between them must use the same stable lexeme and pattern ids.

For every completed target, the runtime emits four independent signals:

- **success** — the declared completion evidence was produced;
- **struggle** — at least one checked attempt was incorrect;
- **hint use** — a hint was opened before completion;
- **recovery use** — the supported recovery path was used.

A clean success has `success = true` and the other three signals false. Completion
after any support remains a real completion and allows the learner to continue, but
it is not recorded as clean recall. A speaking comparison records completion and
support use, never inferred pronunciation quality.

The review model must satisfy these rules:

- the same authored exercise, event history, and scheduler version always produce
  the same memory update;
- struggle, hint use, and recovery use may bring an already-authored review
  opportunity forward or limit a stability increase, but may not insert an
  unauthored task, alter story order, or block county progress;
- recovery completion does not claim independent production; the next optional
  review begins from recall before offering support again;
- a plain-language reason is available for a review invitation, such as “You used a
  hint here, so this phrase is ready to revisit”;
- absence never accumulates penalties or an overdue count. A learner returning after
  a week sees a bounded optional invitation, not seven days of debt;
- review runs retain the existing bounded deck behavior and may be left without
  losing county completion, words, or future access;
- no random difficulty selection, engagement optimisation, or remote model changes
  the next task. Any future scheduler change is versioned, documented in
  `docs/DRILL.md`, and migration-tested.

Debug and test output must explain each memory update using its input signals and
rule version. Learner-facing UI does not need to expose interval arithmetic, but it
must never disguise a required task as an optional one or use guilt to drive return.

#### Interaction, accessibility, and reliability invariants

These are release requirements for every component and every state:

- one task, one dominant response area, and one primary action;
- 44 × 44 point minimum targets and a primary action clear of the safe area,
  software keyboard, and microphone controls;
- a scrollable composition at accessibility text sizes without clipping,
  truncation, hidden feedback, or loss of response context;
- a stable VoiceOver reading order: context, task, response, diagnostic/support,
  primary action; selection, correctness, playback, recording, and completion changes
  receive concise announcements;
- controls have specific accessible names and states; no instruction depends on
  position, gesture, color, animation, haptic feedback, or sound alone;
- equivalent non-drag controls for tiles, matching, and sequencing;
- light and dark appearances plus Increased Contrast preserve text, boundary, focus,
  selection, correction, and completion distinctions;
- Reduce Motion removes shake, spring, stagger, automatic page movement, and
  decorative video while preserving immediate state change and focus;
- missing or corrupt audio produces a stable authored fallback rather than a dead
  control, spinner, crash, or automatic correct answer;
- microphone denial, interruption, and revocation keep the speaking task usable and
  offer the non-recording continuation;
- Irish typing works with the software keyboard, hardware keyboard, paste, composed
  Unicode, and the fada toolbar; focus can be restored after feedback and retry;
- all required content, audio, grading, retry, completion, resume, and memory updates
  work offline. Network absence cannot change correctness or hide the recovery path;
- app backgrounding, termination, and relaunch preserve completed exercises and the
  minimum in-progress state declared by the runtime without duplicating memory credit.

#### Internal mechanics gallery and QA harness

Build one internal-only gallery driven by stable test fixtures and dependency
injection. It must not depend on editing a production pack, toggling a real permission
by hand, deleting a real audio file, or waiting for a scheduler date.

The gallery manifest enumerates every response component and exercise family. Each
entry has direct launch or deep-link access to:

- unanswered;
- selected or otherwise formed but not checked;
- incorrect with diagnostic feedback;
- hint;
- recovery;
- retry with prior support visible;
- correct before page advance;
- complete and revisited-complete;
- long prompt, feedback, Irish, and translation copy;
- missing audio for every audio-dependent component;
- denied microphone and interrupted recording for speaking;
- software-keyboard and fada-toolbar presentation for typing.

The harness must also render the shared state set at:

- standard text and the largest supported accessibility text size;
- VoiceOver with a documented expected reading order and announcements;
- light and dark appearances;
- Increased Contrast;
- Reduce Motion.

Coverage is manifest-driven: an automated test fails when a component, family, core
state, required failure, or environment named above has no fixture. Snapshot or image
comparison may supplement inspection, but it does not replace operating the controls
with VoiceOver, audio, microphone, and a real keyboard.

#### Content-pack and validation implications

Do not edit production content packs during this documentation task. During
implementation, introduce a versioned `learningContract` inside each exercise payload
with:

- `objective`;
- `targets` containing stable lexeme or pattern ids and the intended capability;
- `misconceptions` with stable ids, rationale, and diagnostic feedback;
- `successFeedback`;
- `hint`;
- `recovery`, including the response still required after support;
- `completionEvidence`.

Keep options, tokens, pairs, accepted answers, audio, and model text in the
family-specific payload. Existing flat fields may be adapted for the internal Mayo
fixtures while the runtime is built, but a production pack must not be migrated until
the new contract is decoded, rendered, and validated end to end. Increment the county
schema version when production serialization changes and supply deterministic
migration or an explicit rejection for older external packs.

Selected families add these payload requirements:

- picture or map selection references source-cleared visual assets or stable semantic
  regions plus accessible alternative text;
- listen-and-type distinguishes accepted auditory forms from orthographic diagnostic
  cases;
- radio-style listening declares ordered segment ids, audio, transcript or meaning
  fallback, and the sparse tasks attached to segment boundaries;
- conversation declares a versioned finite node graph, its setting, reviewed
  partner lines, accepted learner intents or responses, entry, terminal nodes, and
  deterministic resume behavior;
- contextual mistake review references the original exercise, target, and
  misconception event rather than duplicating decontextualized content;
- **Words you carry** practice references stable target ids and authored practice
  forms without copying county-completion state; and
- completion declares capability summaries and collection handoff from completed
  target evidence rather than storing reward totals.

For packs with `enforceLearningQuality`, the Swift and Python validators must fail
when:

- any exercise lacks a complete learning contract;
- a target id is unknown, appears before it is introduced, or is incompatible with
  the declared objective or completion evidence;
- a wrong option lacks a misconception/rationale mapping;
- a constructed-response exercise has no named diagnostic and no fallback
  diagnostic;
- a hint reveals the complete accepted answer without an authored reason;
- recovery changes the target or completes without a new learner response;
- completion evidence is unavailable to that response component;
- an audio-dependent task lacks bundled audio and its authored fallback;
- a speaking exercise declares pronunciation correctness or stores audio;
- a tile or matching task has no non-drag interaction;
- a picture or map choice lacks meaningful alternative text, a stable region or
  source-cleared asset, or a rationale for any incorrect option;
- a radio activity has an unreachable segment task, missing replay boundary, or no
  transcript or meaning route;
- a conversation contains an unreachable node, a non-terminal cycle
  without an authored exit, an unreviewed line, an invalid resume target, or any
  runtime-generated language path;
- a conversation declares no branch that changes a later partner line, which makes it a
  single-turn exercise authored in the wrong shape;
- a grammar-discovery activity reveals its rule before a produce step is answered, or
  has no produce step at all;
- a contextual-review activity cannot trace its target and misconception back to the
  original event;
- a carried-word practice item names a target absent from the collection or copies
  scheduler state into collection state;
- a completion summary claims a capability unsupported by completed target evidence;
- memory credit names a lexeme or pattern the exercise does not target.

The validator report must list contract coverage, target capabilities, diagnostic
coverage, recovery coverage, completion-evidence kinds, audio/fallback state, and
memory-signal destinations. Runtime and validator enums must be checked against one
shared documented list so a pack cannot pass offline and fail after decoding.

#### Staged implementation order

1. **Freeze D26 and the representative fixture.** Record the selected activity
   families, shared page anatomy, Clew Bay fixture ids, common error/recovery
   scenarios, and the boundary between fixture work and production Mayo. D26 and this
   plan complete the architecture choice; do not open another direction comparison.
2. **Freeze the broader baseline and fixture set.** Inventory all current exercise
   families, state transitions, completion paths, persistence, memory credit, and
   component-specific exceptions. Classify each current view as reuse, adapt, replace,
   or remove. Existing interaction-study code remains isolated until a specific
   primitive is intentionally adopted.
3. **Implement the pure state engine.** Define typed response,
   attempt, support, completion-evidence, and memory-event values independently of
   SwiftUI. Add unit tests for every legal transition, rejected illegal transition,
   interruption, revisit, and exactly-once completion/memory credit.
4. **Build the shared activity shell.** Implement the stable header/progress, optional
   context, prompt, response slot, keyboard-safe primary action, same-screen feedback,
   continue state, scrolling accessibility composition, focus restoration, and
   announcements. Prove unanswered, incorrect, hint, recovery, retry, complete, and
   revisited-complete states with a placeholder response component.
5. **Add the contract adapter and gallery shell.** Decode the new learning contract
   for test fixtures, adapt the current Mayo fixture fields where necessary, and
   render every lifecycle state through dependency-injected audio, microphone,
   keyboard, appearance, contrast, and motion conditions.
6. **Build the representative Mayo run.** Implement listen-and-choose, matching,
   sentence construction, free typing, a multi-turn conversation, record-and-compare,
   comprehension, completion, and one contextual-review return in the fixed sequence.
   Operate the complete run before extracting additional abstractions.
7. **Complete the recognition group.** Add picture or map selection and
   fill-in-the-blank to the proven listening, choice, and matching primitives. Pass
   gallery, VoiceOver, Dynamic Type, appearance, contrast, motion, missing-media, and
   incorrect/recovery states.
8. **Complete the construction and production group.** Harden sentence tiles and
   typing; add listen-and-type; finish record-and-compare permission, interruption,
   playback, privacy, and non-recording continuation. Pass software and hardware
   keyboard, Unicode, fada, audio, and microphone checks.
9. **Complete the contextual-use group.** Harden comprehension and grammar discovery;
   add radio-style listening and the remaining authored conversation settings.
   Verify reviewable branch coverage, interruption/resume, deterministic completion,
   transcript or meaning routes, and the prohibition on runtime-generated Irish.
10. **Complete the consolidation group.** Connect contextual mistake review,
    **Words you carry** practice, and capability-led completion to the same target ids
    and event history. Preserve the distinction between county completion,
    collection, optional review, and scheduler state.
11. **Connect learner memory.** Emit success, struggle, hint, and recovery signals once
   per completed target; update deterministic stability/difficulty behavior and
   persistence; add migration and debug-explanation tests. Update `docs/DRILL.md` only
   if implementation changes its owned interval or presentation policy.
12. **Harden schema and validators.** Make `learningContract` mandatory for the
   enforced-quality schema, mirror rules in Swift and Python, add failing fixtures for
   every rule, and prove older saved progress survives the runtime and schema change.
   Add image-choice, radio segment, authored branch graph, contextual-review, carried
   word, and completion-summary validation. Do not bulk-migrate production counties
   in this stage.
13. **Run the foundation gate.** Complete the automated suite, gallery matrix, direct
   simulator inspection, and physical-device walkthrough below. Record failures and
   fix the shared system or contract rather than patching a fixture.
14. **Migrate one production exercise slice.** After the foundation passes, migrate
    one representative production Mayo sequence and verify content decoding, progress
    preservation, memory events, collection handoff, optional review, and both modes.
    Stop and repair the shared system if production content requires a private
    exception.
15. **Decide whether to spread.** Record the gate result in `STATUS.md`. If a durable
   rule changed, add or amend a decision before migrating Mayo or another county. A
   pass authorises subsequent content migration and review; it does not itself
   validate pedagogy or clear a county for external testing.

#### Acceptance and verification

The sprint passes only when:

- D26 remains the recorded direction and the implemented activity shell matches its
  one-screen, one-task anatomy;
- the representative Mayo fixture run completes from listening through contextual
  review without touching production county progress;
- every D26 activity family uses the shared state engine and typed response interface;
- unit tests cover every required transition, support combination, interruption,
  revisit, and exactly-once completion/memory event;
- every exercise fixture has a complete authored learning contract and both
  validators accept and reject the same cases;
- every incorrect fixture produces diagnostic feedback tied to a misconception or
  response, every hint leaves something to do, and every recovery requires a fresh
  response;
- all four memory signals persist correctly, produce deterministic explainable
  updates, and never create a gate or overdue task count;
- the gallery manifest proves complete component, state, failure, and environment
  coverage;
- the conversation fixture proves every node and exit is reviewable,
  deterministic, resumable, and free of runtime-generated Irish;
- picture and map choices have meaningful visual content plus accessible text
  alternatives, and radio-style listening has segment replay plus an authored
  transcript or meaning route;
- mistake review, **Words you carry**, and completion use the same stable targets and
  event history without creating review debt or conflating collection with scheduling;
- UI automation exercises response formation, incorrect feedback, hint, recovery,
  retry, completion, resume, missing audio, denied microphone, and offline relaunch;
- no component requires dragging, sound, motion, color, or a microphone to complete;
- no Critical or High issue remains in mechanics, accessibility, persistence, privacy,
  or content-contract review.

Direct verification must include:

1. the complete representative Mayo fixture run on an iPhone 17 Pro-class simulator,
   including every activity's start, incorrect, recovery, and complete states plus its
   core accessibility check;
2. the complete D26 family gallery on an iPhone 17 Pro-class simulator in light and dark
   appearances;
3. every component at the largest accessibility text size, with Increased Contrast
   and Reduce Motion checked independently;
4. VoiceOver operation of each component through unanswered, incorrect, support,
   retry, and complete states, including focus after state changes;
5. a physical-iPhone walkthrough of bundled audio, replay, interruption, software
   keyboard, fada entry, hardware-keyboard input when available, microphone
   allow/deny/revoke, speaking playback, background/resume, termination/relaunch, and
   offline completion;
6. a representative existing Mayo fixture sequence from story context into exercise,
   recovery, completion, memory credit, and optional review invitation. This verifies
   integration only; it is not a Mayo chapter review.

Compilation, snapshots, or one successful path do not satisfy this gate.

#### Decisions required before spreading

Do not migrate or author production county exercises against the revised system until
all of these decisions have an evidence-backed pass:

1. **Direction:** D26 remains the active decision; the implementation proves its
   one-screen, one-task architecture and selected activity families without reopening
   bespoke candidate directions.
2. **Runtime:** one state engine owns attempts, support, completion, persistence, and
   exactly-once events; no family keeps a private alternative.
3. **Completion:** clean, corrected, hinted, and recovered completion semantics are
   agreed and do not trap the learner or make a false clean-recall claim.
4. **Memory:** success, struggle, hint, and recovery signals produce deterministic,
   explainable, debt-free review behavior under the versioned scheduler.
5. **Authoring:** the learning contract is sufficient for every family and validators
   prevent generic feedback, answer-revealing hints, target-changing recovery, and
   unsupported completion evidence.
6. **Access and failure:** the gallery and direct checks pass for VoiceOver, Dynamic
   Type, both appearances, Increased Contrast, Reduce Motion, missing audio, denied
   microphone, keyboard/fada input, interruption, and offline use.
7. **Spread:** the foundation is recorded as **implemented** and **verified** in
   `STATUS.md`. It remains unvalidated until pedagogue review and representative
   learner evidence support the intended learning outcome.

### Phase 4 — Rebuild Mayo

1. Expand the source packet for the broader nine-chapter hypothesis.
2. Approve a complete storyboard before final prose.
3. Map all 20 words across dramatic need, first use, production, and delayed reuse.
4. Author the complete Story-mode narrative.
5. Derive the shorter Learning-mode narrative through page visibility, not a second
   story draft.
6. Author 30–45 learning exercises across the county.
7. Complete historian and Irish-language pedagogue review.
8. Generate and run native-speaker QA on every Irish teaching clip.
9. Add only source-cleared or clearly interpretive imagery.
10. Complete the voyage chart, collection handoff, and both progress states.

**Current progress (24 July):** steps 1–6 are complete in the non-bundled revision-6
review draft, including the nine chapters, 38 exercises, 20 lifecycles, and an
86.2-minute estimated Story path. Steps 7–10 remain open; `STATUS.md` and
`content/mayo/DRAFT-STATUS.md` own the current gate state.

**Exit:** Mayo is complete in both modes, takes the intended time, and passes the
content, learning, engineering, audio, and accessibility gates.

### Phase 5 — Reauthor Offaly, Dublin, and Meath

Research may run in parallel, but integration follows the Mayo proof.

- **Offaly:** settle the Cross of the Scriptures inscription and panel readings with a
  medieval historian and art historian.
- **Dublin:** have a numismatist select the learner-facing penny and legend before the
  exercise sequence is authored.
- **Meath:** complete grant-copy research, castle phasing, and conquest-sensitivity
  review before final storyboarding.

Each county needs a substantial causal story, a complete 20-word lifecycle, and a
county-specific exercise composition. Each passes independently; three previews
completed together do not constitute a quality gate.

**Current progress (24 July):** structurally complete pre-clearance drafts now exist
for all three counties and are bundled for in-app review. Each contains six
variable-length chapters, 68 pages, a 49.4-minute estimated Story path, 30 exercises
across all 12 families, and complete ordered lifecycles for 20 provisional headwords.
All three pass the strict county-pack validator. The app labels them **Review draft**;
page progress is saved, but gold, made objects and word scheduling remain locked by
the open gates. This enables review without completing the Phase 5 exit: the named
historian, object specialist, pedagogy, native-speaker audio, rights, full
accessibility and device gates remain open.

**Exit:** all three counties pass the same internal gates as Mayo, with their own
specialist and rights requirements closed.

### Phase 6 — Four-county verification

Run:

- county-pack schema and word-lifecycle validation;
- unit tests for every exercise and recovery state;
- UI tests for both modes, switching, resume, completion, and migration;
- complete light, dark, Increased Contrast, and Dynamic Type coverage;
- VoiceOver reading-order and control-label inspection;
- Reduce Motion verification;
- offline and missing-resource tests;
- physical-device audio, microphone, keyboard, and performance checks;
- timed internal walkthroughs of all four county stories.

**Exit:** the tester-readiness gate below passes in full. Only then schedule the next
moderated learner round.

## Good-enough standards

### Narrative

- Mayo contains eight to ten chapters and takes 60–90 minutes in Story mode.
- Other launch counties normally contain at least six chapters and take at least 45
  minutes in Story mode.
- Timing comes from complete in-app walkthroughs, not estimated word count.
- Every chapter has a local question, meaningful change, consequence, and authored
  exit.
- No chapter exists merely to teach words, repeat the previous page, or satisfy a
  structural quota.

### Mode integrity

- Story mode contains the complete narrative and no language gate.
- Learning mode retains the full causal chain and all required exercises.
- No exercise appears before the story has made its language meaningful.
- Switching modes never duplicates, skips, or resets shared progress.
- Story completion opens the route without granting gold or the 20-word claim.
- Learning completion turns the county gold and activates its 20 words for review.

### Word lifecycle and learning depth

- Every one of the 20 words is heard in meaningful context, retrieved later, used in
  a phrase or sentence, and reused in a later chapter.
- A machine-checked lifecycle table proves all four stages.
- At least half of exercises operate on phrases or full sentences.
- At least 40% require construction, typing, speaking, ordering, or another form of
  active production.
- Full-sentence work begins no later than the second chapter.

### Exercise variety and quality

- Each county uses at least seven mechanic families.
- No family exceeds 25% of exercises and the same family never appears consecutively.
- Recognition multiple choice is no more than 25% of a county.
- Single-word listen-and-pick is an introduction mechanic and no more than 10%.
- Distractors represent plausible learner errors or meaningful contrasts. Random
  unrelated answers fail review.
- Feedback explains the error and supports another attempt.
- Every required exercise has a usable wrong-answer and recovery path.
- Exercises are full-screen, calm, and free of XP, hearts, streaks, confetti, cartoon
  rewards, or artificial delays.

### Irish, audio, and speaking

- A qualified pedagogue approves Irish copy, grammar, dialect, answers, distractors,
  feedback, and pronunciation guides.
- Every required Irish teaching line has bundled audio cleared by a native speaker.
- Missing or unreviewed teaching audio blocks tester readiness.
- Speaking exercises record and compare with the model but do not grade
  pronunciation.
- Microphone denial never traps progress; recordings stay on-device and are not kept
  by default.

### History and evidence

- Every material claim maps to a claim ledger.
- Evidence, inference, dispute, tradition, and afterlife remain distinguishable.
- Comprehension may test what evidence supports but never invent learner participation
  in history.
- Each county closes its named historian, specialist, sensitivity, and rights gates.

### Accessibility and reliability

- Every mechanic passes Dynamic Type through accessibility sizes, VoiceOver, 44-point
  targets, both appearances, Increased Contrast, Reduce Motion, and non-audio
  alternatives.
- Dragging is never the only available interaction.
- Exact-page resume, mode switching, county completion, audio, keyboard input, and
  save migration work offline.
- No content or progress is lost during an upgrade.
- Zero Critical or High issues remain in editorial, pedagogy, history, accessibility,
  or engineering review.

## Automated enforcement

The county-pack validator fails when:

- ids are missing or duplicated;
- a mode produces an empty or causally broken chapter;
- an exercise refers to language not previously introduced;
- any target word lacks a complete lifecycle;
- exercise variety or recognition limits are violated;
- required audio or evidence references are missing;
- a correct answer is duplicated among distractors;
- a required page is unreachable;
- completion can be awarded without all pages required by that mode;
- a pack still depends on the old three-beat structure.

The validator produces a readable report for each county: narrative timing, word
coverage, exercise distribution, audio state, evidence state, and outstanding review
gates.

## Tester-readiness gate

Do not issue the next external build until:

- all four stories are complete in both modes;
- Mayo internally times at 60–90 minutes in Story mode;
- every other county internally times at 45 minutes or more;
- all 80 words pass their lifecycle checks;
- every county meets the exercise-distribution standards;
- all Irish teaching audio has native-speaker QA;
- all specialist source, sensitivity, and rights gates are complete;
- no Critical or High issue remains;
- the full automated suite passes;
- both modes have been exercised end to end on a physical iPhone;
- direct accessibility inspection is complete.

The moderated round then validates the implementation. Initial pass thresholds are:

- at least 80% of Story-mode participants can recount the central problem, three
  meaningful turns, and one evidence limit;
- at least 80% describe the county story as substantial and complete;
- exercise mechanics require no moderator explanation after their first appearance;
- after 48–72 hours, the Learning-mode group has median recognition of at least 14 of
  20 words and can produce at least 8 of 20 in a supported phrase or sentence;
- no P0 or P1 usability, accessibility, historical, or language issue appears.

These are initial validation thresholds. A pedagogue may tighten them before the
round; do not relax them after seeing the results.

## Indicative scope

Allow 16–24 weeks with one iOS engineer, one editor, and timely specialist access.
External review and rights waits are additional. Editorial research for the three
later counties may run beside Mayo engineering, but implementation remains
representative-slice first.
