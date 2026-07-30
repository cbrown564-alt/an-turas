# An Turas

An iOS app that teaches Irish through evidence-grounded county histories. This glossary
fixes the vocabulary shared by the content packs, the learning runtime, and the
authoring tools, so that the docs, the Swift code, and the Python validators can only
have one answer for each concept.

## Language

### Story and place

**County story**:
One authored historical account belonging to a single county, delivered as an ordered
sequence of pages.
_Avoid_: chapter set, lesson, unit

**Story page**:A page whose purpose is exposition. It may be editorial, atmospheric, and scrollable.
_Avoid_: narrative card, story card

**Activity page**:
A page whose purpose is a single learning task. It is focused and normally fits one
viewport at standard text sizes.
_Avoid_: exercise card, quiz, question

**Mode**:
The learner's chosen way through a county: story only, learning only, or both.
_Avoid_: track, path, difficulty

### Learning activities

**Activity anatomy**:
The fixed outer composition every activity page shares: exit and quiet progress,
optional short context, one prompt, one dominant response area, one primary action,
same-screen feedback, one continue action.
_Avoid_: layout, template, shell composition

**Response family**:
One reusable way for a learner to answer, defined by its working area rather than by
its subject matter, and satisfying the shared response contract. A family may take on
the imagery and evidence of the current story, but its response method stays stable
enough to become familiar.
_Avoid_: mechanic, exercise type, activity type, interaction pattern

**Container**:
A surface that hosts or terminates response families rather than being one. Conversation,
radio-style listening, contextual mistake review, Words you carry practice, and
completion are the five containers; each has its own contract and does not pretend to
satisfy the response contract.
_Avoid_: family, activity type

**Conversation**:
The single container for multi-turn authored exchange, owning turns, branching, resume,
and node-graph validation. Its **setting** is authored metadata, not a structural
difference.
_Avoid_: dialogue, roleplay, chat

**Setting**:
Which kind of exchange a conversation is: *historical-bounded*, where the learner stays
themselves and the evidence boundary holds, or *present-day*, where the learner converses
freely. Never a licence to invent participation in undocumented history.
_Avoid_: context, scenario, framing

**Response contract**:
The actions every response family exposes: update response, check, request hint, begin
recovery, retry, complete. A family that cannot satisfy it is a container.
_Avoid_: protocol, interface, API

**Authored use**:
A pedagogical purpose an author achieves by configuring an existing response family,
rather than by introducing a new family. Sequencing is an authored use of sentence
construction; delayed retrieval is an authored use of contextual mistake review and
Words you carry practice.
_Avoid_: variant, subtype, mode

**Grammar discovery**:
The response family that reveals worked cases in authored order and withholds the rule
until the learner has produced it. Distinct from every other family because its lifecycle
is a progressive reveal gated on a produce step.
_Avoid_: discover page, inductive exercise

**Support**:
Any scaffold that makes a task easier than the target capability requires — visible
tiles, labels, a hint, a text fallback for audio. Support is recorded on the attempt
because it changes what the attempt proves.
_Avoid_: hint (that is one kind of support), help, assist

**Target capability**:
What the learner should be able to hear, distinguish, understand, or say. Completion
copy may only claim a capability that completed target evidence supports.
_Avoid_: objective, skill, outcome

**Clean recall**:
Credit earned only when the learner retrieves or produces without the answer visible.
Recognition and supported construction diagnose and introduce; they never earn it.
_Avoid_: mastery, correct, passed

**Spine**:
The single corpus of language items — lexemes and patterns — that every learning surface
references. No surface owns a corpus of its own.
_Avoid_: content model, item bank

**Lexeme**:
The vocabulary atom on the spine, identified by a stable id that every surface references.
_Avoid_: word, gloss, term, vocab item

**Pattern**:
The grammar molecule on the spine: a frame plus the slots earned lexemes fill.
_Avoid_: rule, structure, template

**Earned**:
The state of a spine item that an authored page has referenced. Only earned items may be
scheduled or practised.
_Avoid_: unlocked, learned, seen

**Collection**:
The projection of the spine holding per-learner encounter metadata — first place, audio,
example, later uses.
_Avoid_: inventory, library

**Scheduler**:
The projection of the spine holding due state for later review. Distinct from collection;
both project off the same spine.
_Avoid_: SRS, queue, review engine

**Words you carry**:
The learner-facing surface over the collection projection. One of two surfaces on the
spine; scheduled review is the other.
_Avoid_: vocabulary list, deck, LexemeDeck, retrieval deck, drill surface, inventory

**Contextual mistake review**:
A return to the exact sound, sentence, place, or misconception that caused difficulty,
reconstructed from the original attempt event. It never presents overdue counts or
accumulated debt.
_Avoid_: review queue, practice due, mistakes list

### Content and evidence

**Story pack**:
The versioned, validated content file for one county story, decoded by the app and
checked by both the Swift and Python validators.
_Avoid_: content file, JSON, bundle

**Fixture**:
Realistic content used to prove the runtime, explicitly not production content and
never promoted into a bundled pack by being useful.
_Avoid_: sample, mock, test data

**Evidence boundary**:
The declared limit of what the historical record supports, distinguishing it from
inference and legend. Feedback must respect it.
_Avoid_: source note, disclaimer

**Reviewed**:
Authored language or historical content that has passed its required human review.
Nothing generated by a runtime model is ever reviewed.
_Avoid_: approved, checked, validated
