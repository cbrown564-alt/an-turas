# Learning interaction studies

*Research and implementation report · 30 July 2026*

## Status and purpose

This report records the iOS interaction study carried out after the first three
learning-mechanics prototypes passed their technical checks but failed the experience
bar.

The earlier prototypes—Ear-first Retrieval, Guided Construction, and Coastline
Reasoning—proved complete learning loops, recovery, audio fallback, accessibility
behavior, and isolated state. They did not prove a compelling exercise experience.
They were visually dense and document-like; instructions and context competed with
the task; most responses were ordinary forms and buttons; feedback was informative
but detached from the learner's action; and the three approaches felt too similar
moment to moment because they shared one editorial scaffold.

The follow-up work deliberately removed story and historical exposition. It held the
language material constant and asked a narrower question:

> Can a small Irish task feel immediately understandable, responsive, satisfying to
> correct, and worth repeating?

Three disposable iOS studies were implemented:

1. **Sound Match** — hear or reveal one Irish word and choose its meaning.
2. **Sentence Flow** — build one Irish sentence from substantial word units, first
   with role cues and then without them.
3. **Coast Placement** — attach three Irish words to a simplified spatial model of
   open water, sheltered bay, and named land, then repeat without labels.

They remain research evidence. They do not constitute a selected learning
architecture, a shared exercise runtime, a validated teaching method, or production
county content. D26 separately selects a familiar one-screen activity system after
the expanded 48-activity review. The useful task now is to bring the strongest local
response, correction, scaffold-removal, motion, and spatial details from these studies
into that selected system without importing three competing shells.

## Fixed material

Every study uses the same narrow projection of the frozen Clew Bay fixture:

- *farraige* — sea;
- *bá* — bay;
- *áit* — place; and
- *Is as Maigh Eo mé.* — I am from Mayo.

The study fixture intentionally exposes only words, meanings, the sentence, sentence
units, and the minimum audio text needed to run the interactions. It does not expose
story context, place exposition, historical explanation, county progress, review
scheduling, carried words, or completion rewards.

Holding the material constant makes the response mechanics easier to compare. It
also prevents a stronger story passage from disguising a weaker exercise.

## Public benchmark observations

The research used publicly observable product behavior and first-party descriptions
from Duolingo and Brilliant. It did not copy their branded visual identity, content,
characters, reward economy, sound signatures, or proprietary implementation.

### Action comes before explanation

Duolingo describes learners beginning with simple exercises and using hints or short
explanations as needed. Brilliant describes starting with the simplest form of a
problem and building understanding through small steps. The transferable pattern is
that the first screen presents an action, not a lecture.

Sources: [Duolingo Method](https://blog.duolingo.com/duolingo-teaching-method/),
[Brilliant's method](https://brilliant.org/about/), and
[Brilliant on solving equations](https://blog.brilliant.org/solving-equations/).

### The response is the visual centre

Public Duolingo examples give most of the screen to replayable audio, substantial
choices, word units, speaking controls, or tracing. Brilliant often makes the
manipulable model the problem itself rather than placing an illustration beside
instructions. The learner should not have to search a document-like screen for the
thing they can touch.

Sources: [Duolingo 101](https://blog.duolingo.com/duolingo-101-how-to-learn-a-language-on-duolingo/)
and [Brilliant's tactile-learning process](https://blog.brilliant.org/hand-crafted-machine-made/).

### Feedback stays beside the action

Both products publicly emphasise immediate feedback. Duolingo's deeper explanation is
an optional layer after a compact verdict. Brilliant describes hints and correction
inside the current problem. The transferable pattern is a short
action–feedback–repair loop: identify the affected object, preserve correct work,
and make the next useful touch obvious.

Sources: [Duolingo's Explain My Answer](https://blog.duolingo.com/explain-my-answer-now-free/)
and [Brilliant's in-context support](https://brilliant.org/help/why-brilliant/is-brilliant-good-for-learners-with-dyscalculia/).

### Support recedes through the same task

Duolingo's public writing and listening descriptions move from visible support to
less-supported production. Brilliant describes increasing complexity and removing
visual aids. The important detail is continuity: the learner can see that the same
object or task has lost a support, rather than reading a paragraph that says the next
screen is harder.

Sources: [Duolingo's listening progression](https://blog.duolingo.com/covering-all-the-bases-duolingos-approach-to-listening-skills/),
[Duolingo's writing progression](https://blog.duolingo.com/covering-all-the-bases-duolingos-approach-to-writing-skills/),
and [Brilliant's method](https://brilliant.org/about/).

### Motion, sound, and haptics communicate state

The useful effects are attached to selection, placement, return, correctness, and
progress. They do not delay the next task or serve as a reward performance. An Turas
can use restrained movement and haptics to make cause and effect clear while retaining
its own quiet tone and respecting Reduce Motion.

Sources: [Duolingo lesson settings](https://blog.duolingo.com/learning-with-hearing-aids/),
[Duolingo responsive animation](https://blog.duolingo.com/world-character-visemes/),
and [Brilliant's method](https://brilliant.org/about/).

### Repeatability comes from rhythm and nearby variation

Short tasks become repeatable when the motor rhythm is predictable but the demand
changes: another word, another order, less support, or a nearby contrast. This does
not require points, hearts, streaks, leagues, mascots, or confetti.

Sources: [Duolingo product progression](https://blog.duolingo.com/product-highlights/)
and [Brilliant's learning-game process](https://blog.brilliant.org/hand-crafted-machine-made/).

## Study 1: Sound Match

### Question

Can an ear-first recognition task become clear and satisfying when audio, three large
targets, and immediate local correction are the whole screen?

### Loop

1. The learner hears one of the three Irish words.
2. If bundled or synthesised speech is unavailable, the written Irish word appears in
   the same focal position; the task remains usable.
3. The learner taps one of three large English meaning targets.
4. A wrong target changes in place, gains a clear incorrect mark, and gives one short
   distinction. The other targets remain active, so repair is the next touch.
5. A correct target settles into a clear correct state and opens one bottom action.
6. The next sound uses a different answer order.
7. After three words, the learner can replay each Irish–English pair or begin again.

### Designed states

- waiting;
- audio playing;
- written fallback visible;
- selected;
- incorrect and directly repairable;
- correct;
- advancing; and
- complete/restart.

Correct and incorrect states use icon, text, surface, and accessibility value rather
than colour alone. Correct selection locks the answer only after the verdict; an
incorrect selection does not force a separate Retry button.

### What it tests

Sound Match is the control study for ruthless clarity. It asks whether execution
quality—scale, spacing, response immediacy, audio replay, and a short repair loop—is
enough to improve an otherwise conventional listen-and-choose task.

### Current observation

The initial simulator composition is substantially clearer than the earlier
Ear-first Retrieval prototype. The prompt, audio focus, and three targets fit one
coherent first viewport. The interaction still proves recognition only. Its value is
as an entry or diagnostic format; it cannot stand in for later retrieval and
production.

## Study 2: Sentence Flow

### Question

Can Irish sentence structure feel physical and progressive without relying on a text
field, a separate Check action, or a long grammar explanation?

### Loop

1. The learner sees the English meaning and one sentence track.
2. Four substantial Irish units—*Is*, *as*, *Maigh Eo*, and *mé.*—sit in a word bank.
3. On the first pass, each empty position carries a short structural role:
   statement, from, place, and speaker.
4. Tapping the correct next unit moves it into the track and preserves it.
5. Tapping a unit out of sequence returns attention to that unit and names the role
   or word that comes next. Correct work is not cleared.
6. When the line is complete, the same sentence is spoken when audio is available.
7. The learner removes the role cues and rebuilds the same line from a different word
   order.
8. Completion offers an immediate restart.

### Designed states

- guided pass;
- current empty position;
- available unit;
- incorrect unit and local return cue;
- placed unit;
- sentence complete;
- cues removed;
- unsupported rebuild; and
- complete/restart.

The sentence track, not explanatory copy, communicates progress. The same language
object survives from supported construction into the unsupported pass, so the
withdrawal of help is visible.

### What it tests

Sentence Flow tests whether synchronized movement, sound, haptics, and persistent
correct work can make construction feel more like assembling a line than filling in a
form. It also tests a narrower meaning of direct manipulation: the learner taps large
units and sees them move into place; dragging is not required.

### Current observation

The dark sentence field gives this study a distinct working space and makes the
scaffold legible. The structural roles are useful in the first pass and disappear
cleanly in the second. The study intentionally does not claim free production:
removing role labels while keeping the same word units is a reduction in support, not
the final learning outcome.

## Study 3: Coast Placement

### Question

Can place relationships do real teaching work when the learner attaches Irish words
directly to a simplified coast rather than reading a labelled list?

### Loop

1. A simplified coast shows open Atlantic water, a sheltered inlet, and named land.
2. One Irish word appears above the coast and is spoken when audio is available.
3. The learner taps the region where the word belongs.
4. A wrong placement marks that region and gives one spatial distinction, such as
   open water versus water gathered inside the coast.
5. A correct placement remains attached to the region.
6. After *farraige*, *bá*, and *áit* are placed, the region labels disappear.
7. The learner places the same three words again using the coast's shape rather than
   written region names.
8. Completion offers an immediate restart.

At accessibility Dynamic Type sizes, the map becomes a semantic vertical region
stack. The learner answers the same conceptual question with large native buttons;
the custom canvas is not the only operable path.

### Designed states

- labelled coast;
- current word/audio;
- selected region;
- incorrect region with local contrast;
- correct anchored word;
- labelled pass complete;
- labels removed;
- unlabelled pass; and
- complete/restart.

### What it tests

Coast Placement is the only study in which a spatial relationship is the working
model. It tests whether place can support comprehension without importing story
exposition, and whether the disappearance of labels creates a meaningful nearby
variation.

### Current observation

The coast gives this study a different moment-to-moment character from the other two.
It is the strongest demonstration that geography can be part of the answer method,
not decoration. It is also the most bespoke and therefore the easiest to overuse.
The production rule should remain: use a map or object response only when the real
visual communicates the distinction precisely.

## Shared implementation boundary

The studies lived under `ios/AnTuras/Prototypes/InteractionStudies/`, removed once D27
recorded the retained primitives; git history preserves them. They had their own
catalogue, fixture projection, gallery, destination switch, state, feedback, motion,
and completion. Temporary duplication is intentional.

They do not add cases to the original `LearningPrototypeDirection`, whose tests freeze
the three earlier prototypes. They do not read or write:

- `AppState`;
- county completion;
- review scheduling;
- carried words;
- learner-made objects;
- county pack content;
- `CountyExerciseSystem`; or
- production exercise contracts.

The old comparison gallery remains available and now links to the new internal
interaction lab. Debug launch routes are:

```text
--interaction-studies
--interaction-study sound-match
--interaction-study sentence-flow
--interaction-study coast-placement
```

The studies also support forced audio fallback and reduced-motion test paths:

```text
--interaction-study-missing-audio
--interaction-study-reduce-motion
```

This isolation prevents a promising visual detail from silently becoming production
architecture before the comparison and synthesis are complete.

## Accessibility and recovery

The studies preserve the strongest safeguards from the earlier prototypes:

- semantic VoiceOver labels, values, and hints on response targets;
- 44 pt or larger touch targets;
- Dynamic Type reflow through the largest accessibility category;
- both light and dark appearances;
- Reduce Motion paths that remove custom movement rather than delaying state;
- visible audio fallback;
- correctness communicated with text and symbols as well as colour;
- no drag-only answer;
- no microphone dependency;
- no timed response; and
- no county-progress or review side effect.

One useful implementation lesson came from UI automation: a broad SwiftUI
`accessibilityIdentifier` applied outside a safe-area inset can replace the more
specific identifier of a bottom action in the accessibility hierarchy. The final
implementation scopes task identifiers to scroll content and contains the bottom
feedback group, preserving the learner-facing label and the specific control
identifier.

## Verification completed

The Xcode project was regenerated from `ios/project.yml`. The app was built, installed,
launched, and directly inspected on an iPhone 17 Pro Max simulator running iOS 26.5.
Representative initial compositions were directly inspected across the two
appearances: Sound Match in light, Sentence Flow in dark, and Coast Placement in
light. The automated matrix covers both appearances for every study.

The focused automated suite passes:

- **3 unit tests** covering the isolated catalogue, fixed fixture projection, and
  distinct coast regions; and
- **5 UI tests** covering the gallery; a complete Sound Match loop; a complete
  Sentence Flow wrong-answer, cue-removal, and unsupported-rebuild loop; a complete
  Coast Placement wrong-region, label-removal, and unlabelled loop; audio fallback;
  restart states; and first-response reachability for every study in light and dark
  appearance at the largest Dynamic Type size with reduced motion.

Passing UI tests capture all three completion states. This verifies the implemented
loops and accessibility reachability covered by those tests. It does not validate
learning efficacy, enjoyment over repeated real use, Irish pedagogy, production
audio, or a product direction. The complete pre-existing app regression suite and
physical-device pass were not rerun for this disposable lab checkpoint.

## What should transfer into the selected activity system

The studies suggest response-level details worth carrying into the D26 implementation:

- make the response the visual centre;
- keep a wrong response editable and make repair the next touch;
- attach the diagnostic cue to the affected target or working model;
- preserve correct work during repair;
- let the same language object lose support visibly;
- use substantial response targets and stable bottom actions;
- bind restrained motion, sound, and haptics to state change;
- use geography, objects, or documents as response models only when they communicate
  the distinction;
- keep audio fallback inside the task rather than routing to an error page; and
- make restart fast enough that repetition can be judged honestly.

These are candidates for synthesis, not permanent rules merely because they exist in
working code. D27 records which were adopted.

Two of the study's suggestions were decided rather than carried forward. Grading a
simple choice on selection is now the rule for single-choice families, with a repair
window before any struggle signal is recorded, so a mis-tap does not enter contextual
mistake review as a misconception. Multi-part responses keep an explicit Check.

## What should not transfer

- Do not consolidate the three study views into a new shared runtime.
- Do not treat recognition or tile reconstruction as proof of free recall.
- Do not use a bespoke map when a familiar choice communicates the same thing.
- Do not add story exposition back into the activity screen.
- Do not import Duolingo's or Brilliant's identity, branded feedback, characters,
  sounds, or reward economy.
- Do not generalise study-local visual constants into global theme tokens.
- Do not claim the studies are validated because automated and simulator checks pass.

## Questions for the combined review

The separate expanded exercise review and this iOS interaction study now need one
explicit synthesis pass. That pass should answer:

1. What is the common correction pattern, and where should local in-place repair
   override a generic feedback panel?
2. How can the stable one-screen shell preserve familiarity while letting a sentence
   track, map, document, or audio control become the visual centre?
3. Which supports should visibly recede within the same task, and which should recede
   across later authored activities?
4. Which actions warrant sound or haptics, and what is the quiet An Turas vocabulary
   for them?

Three questions listed here earlier are closed. Grading on selection is settled above.
The recognition-to-production progression is already enforced, not open: the four-stage
lifecycle in `tools/validate_county_pack.py` requires every target word to move
`introduced <= heard < produced < reused` in page order, with at least forty percent of
activities in production families. Learner measurement is a real question but not one
this report can answer; the four-county tester-readiness gate owns it, and D26 records
that it remains the first contact with a learner other than the owner.

The next build should answer these questions in one representative Mayo Learning-mode
run through the selected shell. It should extract only the response details that make
that run clearer and more satisfying, then test the important exceptions before the
pattern spreads.
