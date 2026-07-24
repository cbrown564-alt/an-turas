# Story and learning rebuild

*Confirmed 15 July 2026. This is the implementation plan for the Phase 3 rebuild.
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

## Why the current build does not pass

The working four-county product proves navigation, progress, evidence, collection,
review scheduling, and offline pack installation. It does not prove content depth or
learning quality.

- Mayo's six episodes and 18 beats are too short for the intended flagship story.
- Offaly, Dublin, and Meath are four-episode, twelve-beat editorial previews. They are
  outlines with interactions, not substantial stories.
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

**Current progress (24 July):** steps 1–6 are complete in the non-bundled revision-5
review draft, including the nine chapters, 38 exercises, 20 lifecycles, and an
84.8-minute estimated Story path. Steps 7–10 remain open; `STATUS.md` and
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
