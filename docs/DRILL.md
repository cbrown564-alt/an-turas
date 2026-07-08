# The Drill Surface — one spine, two surfaces

*Drafted 2026-07-08. How the app teaches vocabulary at volume, grammar across
contexts, and rules by discovery — without rebuilding the extrinsic-reward
machinery the whole product exists to reject. Companion to [SPINE.md](SPINE.md).
The shared item spine and the first drill projection — `discover` — have landed;
chapter 1 is tagged and its `caol le caol` discovery page is playable.*

## The principle

Story mode and drill mode are **not two content sets**. They are two surfaces on
one spine. The spine is a shared *item layer*: a **lexicon** of vocabulary atoms
and a **bank** of grammar patterns. Story pages *earn* items; the drill surface
only ever *schedules* items already earned. Neither surface owns content the
other cannot see.

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
together as the same item. The lexicon fixes exactly that.

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

Decided 2026-07-08: drills never gate the narrative. The invitation rides the
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

Deliberately **not** built yet: the scheduler, the deck assembly, and the two
*retrieval* projections (the due-lexeme deck and generated substitution drills).
The point of the schema-only pass was to tag chapter 1's items against real
shapes and feel whether the spine holds before a line of it is wired up. It held
— and the first projection is now wired (see below).

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

## Open questions

- **`discover` → note link.** `DiscoverBlock` has no `note` field yet;
  `note.two-flavours` already exists to be pointed at once it does, so the learner
  can read the nóta *after* the aha. Small and non-breaking.
- **Scheduling policy.** Deck size, spacing, interleaving — folded into the
  existing SRS-under-review work, not invented here.
- **Coverage definition.** Production vs recognition threshold for what counts as
  "you can use this" on the museum signal.
- **Lexeme authoring ergonomics.** Chapter-local JSON keeps items beside their
  scene; revisit if cross-chapter reuse makes a global file cleaner.
