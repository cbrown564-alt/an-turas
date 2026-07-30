# Scheduled review — one language item layer

*Drafted 2026-07-08; scope clarified after D21 on 15 July 2026; reconciled with D26–D27
on 30 July 2026. This document owns scheduled vocabulary and grammar review after
language has been earned. Inline Learning-mode exercises and Story-mode filtering are
owned by `PRODUCT.md`, `COUNTY-ATLAS.md`, and `STORY-LEARNING-REBUILD-PLAN.md`. All three
scheduled-review projections have landed for legacy Chapter 1: `discover`,
grammar-at-volume (generated substitution drills), and vocabulary-at-volume (the
scheduled retrieval deck).*

**D27 reconciliation.** The spine described here and D26's **Words you carry** are one
model, not two. The lexicon and pattern bank remain the only corpus. Two projections sit
on it:

- **collection** — per-learner encounter metadata: a word's first place, audio, example,
  and later uses;
- **scheduler** — due state for later review.

**Words you carry** is the learner-facing surface over collection; scheduled review is
the surface over scheduler. This is what D26 means by keeping collection state distinct
from scheduler state, and it does not weaken the guarantee below: neither surface owns a
corpus, and both may only touch earned ids. Retire *retrieval deck*, *drill surface*, and
`LexemeDeck` as learner-facing names; they describe implementation, not places the
learner goes.

The `discover` projection below is promoted by D27 to a response family, **grammar
discovery**, and moves onto the shared activity runtime. It is still authored the same
way and still owned here.

## The principle

D21 adds Story and Learning modes as two projections of one county page sequence.
Scheduled review is a later projection of the same language item layer: a **lexicon**
of vocabulary atoms and a **bank** of grammar patterns. Story context earns items;
Learning-mode exercises complete their authored lifecycle; scheduled review may only
schedule items whose learning path is complete. No surface owns a disconnected corpus.

This is what keeps drill honest. The anti-Duolingo thesis fails the moment drill
becomes a context-free grind of decontextualised words. Here that is
*structurally impossible*: the drill surface has no corpus of its own — it can
only touch ids the story has already made the learner care about, and every
drill card carries a backlink to the place that gave it meaning ("from Dáire's
yard"). The thesis is enforced by the schema, not by discipline.

## What already exists

Most of "drill mode" is already built — inline. `Models.swift` defines eight
retrieval formats (`choice`, `assemble`, `typein`, `match`, `listen`, `echo`,
`turn`, `recarve`), and `recarve` + `Visit` are a spaced-review layer already
dressed in narrative clothes (SPINE rule 6). What was missing is not drill
*mechanics* but a shared *item identity*: "Dia dhuit" appears in a scene, a
`choice`, a `match`, and a `Visit`, and nothing tied those four appearances
together as the same item. The lexicon and shared scheduler fix exactly that.

## The spine

### Lexeme — the vocabulary atom

Authored per chapter, beside the scene that earns it, and merged into one bank at
load (mirrors how `visits` are chapter-local and merged via `visits(throughChapter:)`).

```json
{ "id": "lex.dia-dhuit", "ga": "Dia dhuit", "en": "hello (God to you)",
  "ph": "JEE-a GWIT", "kind": "phrase", "tags": ["greeting"],
  "dialect": "connacht", "lemma": "dia-dhuit",
  "earnedAt": { "chapter": 1, "session": 0 } }
```

- `id` is the stable handle every surface references. Existing `Gloss`
  (`t`/`g`/`s`) and `SpeechBeat` become *views* of a lexeme via an optional `ref`.
- `dialect` + `lemma`: dialect variants are siblings sharing a `lemma`. Connacht
  ships first (SPINE rule 5 / STRATEGY D2); the lexicon is where that policy lives.
- `earnedAt` is the backlink a drill card shows and the invariant that keeps
  drill downstream of story.

### Pattern — the grammar molecule

A rule with a fillable frame, linked to the *An Nóta Gramadaí* page that already
explains it in prose (SPINE rule 2: explain, then drill).

```json
{ "id": "pat.copula-identity", "note": "note.two-to-bes",
  "teach": "identity → is, not tá",
  "frame": "Is mise {x}",
  "slots": { "x": { "fromTag": "name" } },
  "contrast": "Tá mé {state}",
  "earnedAt": { "chapter": 1, "session": 0 } }
```

- `frame` + `slots` generate substitution drills. A slot fills from an explicit
  list *or* from every lexeme carrying a tag (`fromTag`), so grammar practice
  stays in sync with the lexicon and reinforces vocabulary for free.
- `contrast` is the minimal pair that makes a rule click (`Is mise` vs `Tá mé`).
- `note` is a **forward reference**: notes don't carry ids yet (see Open
  questions). Patterns can link once they do; the field is optional until then.

### The earn / reference link

Story text already links glosses with `[mac](turas://g/0)`. The scheme
generalises: `turas://lex/dia-dhuit`, `turas://pat/copula-identity`. A scene
*earns* items by referencing them; the drill surface may only schedule earned
ids. That single rule is the whole guarantee.

## The three projections off the spine

1. **Vocabulary at volume → a retrieval deck.** No new formats: a deck assembles
   the due lexemes and runs each through `match`/`listen`/`typein`, recall-first.
   The scheduler (already present under `recarve`/`Visit`) now operates over
   unified lexeme ids instead of per-block strings.

2. **Grammar across contexts → substitution drills, generated.** The pattern's
   `frame` × its slot fills produce them. `Is mise Áine / Is mise Seán / Is mise
   Bríd` is one pattern × many earned lexemes — one core idea, slight variations.

3. **Rules by discovery → a new authored `discover` page** (the Brilliant model,
   and the most on-brand of the three). Reveal, reveal, then withhold — the
   learner produces the rule before it is stated; the reward is their own "aha".

   ```json
   { "type": "discover", "pattern": "pat.lenition-mo",
     "teach": "after mo, the first consonant softens",
     "steps": [
       { "show": "cat → mo chat" },
       { "show": "bord → mo bhord" },
       { "prompt": "garraí → mo ___", "answer": "mo gharraí" } ] }
   ```

   A step with `prompt` is a *produce* step; otherwise it *shows* a worked case.
   `teach` is revealed only after the produce step. Irish mutations are made for
   this.

## Optional-but-invited

Decided 2026-07-08 and preserved by D21: scheduled reviews never gate Story mode or
county advancement. Required inline exercises do gate Learning-mode completion. The
later review invitation rides the
session-completion `hook` already authored on each session ("3 phrases from the
yard are ready to revisit" → opens the deck) — an offer framed as returning to
people, never a gate, never a nag (SPINE rule 6). The museum/map becomes the
honest anti-streak signal: **how much of a chapter's lexicon the learner can
produce** — coverage, not points.

## This first pass (schema-only)

Landed in `Models.swift`, non-breaking:

- `Lexeme`, `Pattern`, `PatternSlot`, `ContentRef` structs + chapter-local and
  merged loaders (`lexicon(forChapter:)` / `lexicon(throughChapter:)`, same for
  `patterns`). Absent JSON keys decode to empty, so no authored chapter changes.
- `DiscoverBlock` + `discover` wired into the `Page` enum (register `.exercise`).
- Optional `ref` on `Gloss` and `SpeechBeat`, threaded through — backward
  compatible.

Deliberately **not** built in the schema-only pass: the scheduler, the deck
assembly, and the two *retrieval* projections (the due-lexeme deck and generated
substitution drills). The point was to tag chapter 1's items against real shapes
and feel whether the spine holds before a line of it is wired up. It held — and
all three projections have since been wired: `discover`, grammar-at-volume (the
substitution drills, run unscheduled), and vocabulary-at-volume (the scheduled
retrieval deck over unified lexeme ids).

## What tagging chapter 1 found

`chapter1.json` now carries 32 lexemes, two patterns, and 14 beat `ref`s
(validated: the whole chapter still decodes, every ref resolves, and
`pat.copula-origin`'s `fromTag: "county"` resolves to five real placename fills).
The spine held — with one instructive push-back:

- **The copula tagged cleanly** as two *production* patterns (`Is mise {x}`,
  `Is as {x} mé`) — `frame` + `slots` fit it exactly.
- **Broad/slender and surname gender did not.** They are *classification* rules
  ("is this consonant broad or slender?", "Mac or Nic?") — the varied contexts
  are the drill, but `frame` + `slots` has nowhere to hold the per-item answer
  key. Forcing them into `Pattern` would corrupt the clean substitution model.
  They belong to `discover` (guided induction), which is also their more
  on-brand home. So `Pattern` is for *production* grammar only; classification
  and phonics rules are `discover`. Recorded here rather than papered over —
  this is exactly what the tagging pass was for.

Consequence for the schema: no change needed to `Pattern`. `discover` gains
importance as the second grammar projection (not just the Brilliant flourish),
and note ids remain the one small addition still owed (for `Pattern.note` and a
future `discover`→note link).

## What building the discover surface landed

*2026-07-08.* The first of the three projections is wired end-to-end. `discover`
was the right one to make real first: it is fully *authored*, so it leans on none
of the deferred scheduler work, and the tagging pass had already promoted it from
Brilliant-flourish to the home for classification rules `Pattern` can't hold.

- **`DiscoverView`** (`ios/AnTuras/DiscoverView.swift`) renders a sequence as
  *reveal → reveal → withhold*: worked cases land one at a time as the learner
  taps through, the final `prompt` step makes them produce the next case, and
  only then does `teach` — the rule — carve in, framed as *an riail a d'aimsigh
  tú* (the rule you found). It replaces the old stub that rendered `teach`
  immediately — the exact anti-pattern the surface exists to reject.
- **Chapter 1's *caol le caol, leathan le leathan*** is the first real `discover`
  page (session 3): inducted from names the learner already knows (Dáire, Áine,
  Rónán) and applied to a fresh one (Ciara). It is the capstone of the
  broad/slender arc the single-consonant `choice` pages set up — the positional
  agreement rule none of them named.
- **Note ids landed.** `NoteBlock` gained an optional `id`; both chapter-1
  patterns' `note` references now resolve (`note.two-to-bes`,
  `note.every-placename-poem`), and the broad/slender note carries
  `note.two-flavours` for the discover→note link when it comes.

Two small policy choices, recorded: produce grading is **case- and
fada-insensitive** (grasping the rule counts even if a length mark slips), and
produce steps stay **text entry** — honouring the schema's free production rather
than collapsing to a tap-choice. Verified: chapter 1 still decodes, the app
launches past its fail-loud content guard, and the grader accepts *Ciara* /
*ciara* / *CIARA* while rejecting *Ciare* / *Ciar*.

## What building grammar-at-volume landed

*2026-07-08.* The second projection — grammar across contexts as *generated*
substitution drills — is wired end-to-end. Unlike `discover` (authored), this
one is produced from the spine: one earned `Pattern` × its slot fills becomes
many items, "one core idea, slight variations," with nothing authored per item.

- **`PatternDrill.items(for:in:)`** (`ios/AnTuras/PatternDrill.swift`) is the
  generator — the pure heart of the projection. It splits the `frame`, rotates
  the first slot's fills (explicit `options`, or every lexeme carrying the slot's
  `fromTag`), and emits a `SubstitutionItem` per fill. The **fill is one atomic
  tile**, so a multi-word placename ("Baile Átha Cliath") never turns ordering
  into a spelling puzzle — the *frame order* is the retrieval, which is exactly
  the grammar of the copula (`Is mise X`; `Is as X mé`, with *mé* trailing).
- **No new format.** Each item is run through the existing `assemble` view
  (DRILL.md said the retrieval projections reuse formats — taken literally). A
  new `PatternDrillView` wraps it: a persistent **rule strip** on top (the
  `teach` + the frame + the `contrast` struck through — the known groove kept in
  sight, honouring SPINE rule 2's "explain, then drill"), a carve-bar of
  progress, the current generated item, and a **coverage close** — every sentence
  you produced, shown as chips. Coverage, not points (the anti-streak signal).
- **`PatternsView`** lists the earned patterns as a peer surface reached from the
  journey hub ("Na Patrúin"), beside Ar Ais, Na Focail, and the museum —
  optional-but-invited, never a gate.
- **The spine's guarantee, enforced twice.** A new `AppState.hasEarned(_:)` gates
  the surface on the *session* that earns each pattern (not just the chapter), so
  a fresh chapter-1 learner sees nothing until they've walked to it. And every
  fill is an earned lexeme or an authored option — the drill can only ever
  schedule what the story has earned.

One schema addition: `Pattern.cue` — the English *intent* a produced item shows
("Say you're from {x}"), so the learner retrieves the frame rather than reading
it back. Optional and non-breaking; both chapter-1 patterns carry one. Verified
in-simulator end-to-end: the list is session-gated (Is mise · 4 focal, Is as ·
5 focal), the runner renders rule strip + contrast + generated tiles with the
cue substituted, and the close shows all four produced `Is mise …` sentences.

Recorded, to revisit: the drill is **assemble-only** for now (a type-in variation
is a natural second format); generation rotates a **single slot** (all shipped
patterns have one). Scheduling now runs over composite keys — see shared scheduler.

## What building vocabulary-at-volume landed

*2026-07-08.* The third projection — vocabulary at volume as a scheduled retrieval
deck — is wired end-to-end. Due earned lexemes assemble into cards; each runs
through an existing format (`typein`, `listen`, or batched `match`), recall-first,
with a backlink to the session that earned it.

- **`LexemeDeck.items(due:in:)`** (`ios/AnTuras/LexemeDeck.swift`) is the
  generator — the pure heart of the projection. Minimal-pair lemmas and fada-tagged
  items prefer `listen`; tag groups of three or more batch into one `match`; everything
  else is English→Irish `typein`. The deck caps at eight cards per run.
- **`VocabDeckView`** (`ios/AnTuras/VocabDeckView.swift`) runs the queue: carve-bar
  progress, existing exercise views unchanged, and a **coverage close** — every
  phrase produced, plus how many of the chapter lexicon have been produced at least
  once. Coverage, not points.
- **Shared scheduler** (see below): lexeme ids carry scheduling state; the deck
  draws from `dueLexemes()` and calls `completeLexeme` on each card.
- **Hub invitation**: "Na Focail" row on the journey map when phrases are due —
  optional-but-invited, never a gate, beside Ar Ais and Na Patrúin.
- **Session hook**: completion page offers deck when ≥2 fresh phrases from the session
  are ready ("frása ón seisiún seo atá réidh le athbhreithniú") — the invitation
  DRILL.md described, now wired.

Verified: chapter 1 still decodes; `--vocab` and `--due N` debug flags reach the
deck; earned lexemes only appear once their session is behind the learner.

## What building the shared scheduler landed

*2026-07-08.* The problem the spine was written to fix: "Dia dhuit" could appear
in a scene beat, a `choice`, a `match`, a session `recarve`, and an Ar Ais
`Visit` — four unrelated strings, no shared memory. Unified lexeme ids (`lex.dia-dhuit`)
are the handle; the scheduler is the boring interval math underneath, now operating
over those ids for the vocab deck the way it already did for visits.

### One progress struct, two keyed stores

`AppState.VisitProgress` holds `{ due, interval, reps }` for each schedulable item.
`LexemeProgress` is a **typealias** — not a second algorithm. `PatternItemProgress`
is too. Three parallel dictionaries in `Saved`:

| Store | Key | Surface | Clothing |
|---|---|---|---|
| `visitProgress` | `Visit.id` | Ar Ais | people asking at the stone |
| `lexemeProgress` | `Lexeme.id` | Na Focail | phrases from the path |
| `patternProgress` | `pat.*:lex.*` composite | Na Patrúin | grooves to run at volume |

The learner never sees `interval` or `reps`. SPINE rule 6 holds: the schedule is
solved technology; only the framing changes.

### Interval math (FSRS-lite, first pass)

Same rules in `completeVisit` and `completeLexeme`:

- **Session earns an item** (`markDone`): visits schedule **due tomorrow** (+1 day);
  lexemes schedule **due now** — available for the optional first-pass deck offer,
  never a gate.
- **Clean recall** (`struggled: false`): `interval = max(interval × 2.5, 2.5)`;
  `due = now + interval days`.
- **Struggled recall** (`struggled: true`): `interval` resets to 1; `due = tomorrow`.
- **`reps`** increments on every completion — powers `producedLexemes(inChapter:)`
  (coverage: "produced at least once") and the session hook (`reps == 0` = fresh).

Ar Ais passes `struggled` from the recarve bench (any miss before the clean strike).
The vocab deck always passes `struggled: false` for now — every format solves on
first success without a miss counter. Revisit when listen/typein gain retry paths.

### Due queues and deck assembly

- `dueLexemes()` / `dueVisits()` filter to earned items with `due ≤ now`, sorted
  oldest-first.
- `hasEarned(_:)` gates both: nothing schedules until its earning session is carved.
- `LexemeDeck.items(due:in:)` takes the due list, caps at **eight cards** per run
  (`deckCap`), batches tag groups into one `match`, and emits `typein`/`listen` for
  the rest. A match card calls `completeLexeme` for **every** lexeme in the batch.
- Both `VocabDeckView` and `ArAisView` **freeze the queue on arrival** so cards
  don't vanish mid-run as the scheduler pushes items into the future.

### Persistence and migration

`lexemeProgress` persists in `turas_progress` beside `visitProgress` (non-breaking:
absent `lexemes` key decodes to `{}`). On init, a migration walks every carved
session across chapters walked so far and back-fills any lexeme whose
`earnedAt.session` matches but has no progress row yet — due now, same as visits
owed before Ar Ais existed. Debug: `--due N` seeds both stores.

### What unified ids buy — and what they don't yet

**Today:** `Gloss.ref` and `SpeechBeat.ref` point at lexeme ids; inline exercises
with `ref`/`refs` credit `lexemeProgress` on success via `SessionView`. Pattern
items schedule under composite keys and credit their source lexeme when present.
Classification drills (broad/slender, surname logic) stay untagged — no lexeme
to credit.

**Still deferred:**

- **FSRS proper** — STRATEGY.md Phase 3; the ×2.5 ladder is prototype-grade.
- **Interleaving** — visits and lexemes stay in separate surfaces; one mixed queue
  is a product choice, not a schema one.

**Landed 2026-07-08** (first three deferred items):

- **Struggle in the deck** — `ChoiceView`, `AssembleView`, `TypeInView`,
  `MatchView`, and `ListenView` now pass `struggled` (any miss before the clean
  strike) through `onSolved(Bool)`; `VocabDeckView` and `PatternDrillView` forward
  it to `completeLexeme` / `completePatternItem`. Ar Ais already did this.
- **Cross-surface recall credit** — optional `ref` on `choice`/`assemble`/`typein`/
  `listen` blocks, `refs` on `match`; `SessionView.creditScheduling` calls
  `completeLexeme` on inline success. Chapter 1 exercises tagged where the
  retrieval is a single earned lexeme (production drills, not classification).
- **Pattern scheduling** — `patternProgress` keyed by composite id
  (`pat.copula-origin:lex.gaillimh`; literal fills use `fill.Áine`). Session
  completion seeds due items; `PatternDrillView` runs the due queue (cap 8);
  completing an item also credits its source lexeme when present.

Recorded as first-pass policy, not final: eight cards per run; same spacing as Ar
Ais; lexemes due immediately on earn (visits due tomorrow); coverage = `reps > 0`.

Verified: `VisitProgress` and `LexemeProgress` share one encode path; chapter 1
lexemes schedule on session carve and space out after a deck run; migration fills
gaps for saves carved before the deck existed.

## Open questions

- **`discover` → note link.** `DiscoverBlock` has no `note` field yet;
  `note.two-flavours` already exists to be pointed at once it does, so the learner
  can read the nóta *after* the aha. Small and non-breaking.
- **FSRS upgrade.** First-pass interval math is landed (see shared scheduler above);
  Phase 3 swaps in FSRS proper without changing the clothing.
- **Interleaving.** Visits, lexemes, and pattern items stay in separate surfaces.
- **Coverage definition.** Production vs recognition threshold for what counts as
  "you can use this" on the museum signal.
- **Lexeme authoring ergonomics.** Chapter-local JSON keeps items beside their
  scene; revisit if cross-chapter reuse makes a global file cleaner.
