# The Drill Surface — one spine, two surfaces

*Drafted 2026-07-08. How the app teaches vocabulary at volume, grammar across
contexts, and rules by discovery — without rebuilding the extrinsic-reward
machinery the whole product exists to reject. Companion to [SPINE.md](SPINE.md).
The shared item spine and two of the three drill projections — `discover` and
grammar-at-volume (generated substitution drills) — have landed; chapter 1 is
tagged, its `caol le caol` discovery page is playable, and its two copula
patterns run at volume from the hub.*

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

Deliberately **not** built in the schema-only pass: the scheduler, the deck
assembly, and the two *retrieval* projections (the due-lexeme deck and generated
substitution drills). The point was to tag chapter 1's items against real shapes
and feel whether the spine holds before a line of it is wired up. It held — and
both authored projections have since been wired: `discover`, then grammar-at-
volume (the substitution drills, run unscheduled). Only the *vocabulary* deck and
the shared scheduler under it remain (see the two build logs below).

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
  journey hub ("Na Patrúin"), beside Ar Ais and the museum — optional-but-invited,
  never a gate. The invitation rides the hub rather than the session hook for now
  (the hook wiring waits for the vocab deck).
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
patterns have one); and **scheduling stays out** — this runs unscheduled, folded
into the SRS-under-review work when it comes, exactly as the doc reserved.

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
