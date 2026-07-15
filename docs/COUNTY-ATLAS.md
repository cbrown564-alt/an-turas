# The 32-county atlas

## Product promise

*An Turas* takes the learner around all 32 counties of Ireland, one county at a time.
A county is the visible unit of progress; encounters are the units completed along
its core story arc. Story mode should let the learner say:

> I followed a substantial, evidence-grounded story from this county and understand
> why it matters.

Completing the Learning-mode path should let the learner say:

> I learned 20 useful Irish words through significant stories and encounters from
> this county, rooted in real people, myths, monuments, communities, or primary
> records.

The map always shows all 32 counties. White means still ahead and green means the
county now in hand. Story-mode completion adds a quiet read state and opens the next
county without claiming language completion. Gold is reserved for Learning-mode
completion: the learner has completed every authored opportunity required by the
20-word path. White is an honest promise, never a disguised lock. The island shows the
whole journey without becoming a county picker.

## County, story, and encounter

A **county arc** is the designated sequence of core encounters through which the
learner completes that county and earns its 20-word language promise. A constituent
**story** supplies a coherent narrative within the arc. An **encounter** is a
completable movement within a story; it may introduce or reuse part of the county's
language payload. No constituent story or encounter is obliged to carry all 20 words
by itself.

The default hypothesis is that one flagship story, divided into chapters, carries the
entire county arc. Before production, that hypothesis must be stress-tested for:

1. enough sourced historical and human change to sustain a satisfying episodic arc;
2. enough authentic dramatic situations for the learner to earn and reuse all 20
   useful words without padding or vocabulary detours.

If the flagship fails either test, side stories may supply the missing narrative or
language ground. They are a remedy for a demonstrated gap, not a default content
quota. Gráinne remains Mayo's flagship, but the six-episode implementation does not
meet the required depth; D22 requires an eight-to-ten chapter rebuild before the next
tester round.

The learner moves through one county at a time in either mode. Story-mode completion
records the account as read and advances the route. A county turns gold only when all
Learning-mode encounters required by its 20-word path are complete.

## One sequence, two modes

A county is authored once as chapters containing stable pages. Every page declares
whether it belongs to Story mode, Learning mode, or both.

- **Story mode** contains the complete narrative, evidence, and story-essential
  interaction. It never gates progress on a correct Irish answer.
- **Learning mode** keeps the setup, stakes, turn, consequence, and evidence limit of
  every chapter, omits optional narrative depth, and includes every required language
  exercise where the story has made that language meaningful.

Shared pages have one completion record. Changing mode continues at the next
incomplete visible page. Story completion and language completion remain separate so
the atlas and collection never make a false learning claim.

## Story contract

Every playable county story must carry these fields in its versioned county pack
before it can be presented as ready:

1. `storyId`, `countyGa`, and `countyEn` — the learner knows exactly where they are,
   and the story can be tracked independently of a legacy chapter number.
2. `anchorName` and `anchorKind` — a named person, myth, monument, community,
   or historical record; no generic stand-in character is the headline hook.
3. `readingPromise`, `readingKind`, and `readingSource` — what significant thing the
   learner will read or encounter, whether it is a primary record, a literary/mythic
   text, an inscription, or evidence-led monument interpretation, and where its
   verified source packet lives.
4. A reference to the county language plan, plus the subset of words this story
   earns and reuses. The county plan owns `vocabularyTarget: 20` and shows where all
   20 words are first needed and later revisited across its encounters. These are 20
   distinct lexical headwords: tokens, phrases, constructions, and inflected or
   emphatic variants do not create extra countable words. Useful phrases are the
   teaching vehicle, not additional quota units. Every headword must be heard at a
   dramatic or practical need, retrieved later, produced in a phrase or sentence, and
   reused in a later chapter. Mere exposure does not fulfil the promise.
5. `spineRefs` — the era/grammar/artifact rails the story uses. These are sequencing
   metadata, not the county's learner-facing identity.
6. `reviewState`, historian source notes, a rights record, and Irish-language
   pedagogue sign-off before public release.
7. Evidence metadata — `evidenceKind`, `certainty`, dated bounds, source object or
   record, and `reconstructionState` — so the interface can distinguish what survives,
   what is inferred, what is traditional, and what has been imagined.
8. Chapters and stable page ids, with page-level mode visibility and separate
   Story-mode, Learning-mode, and optional completion requirements.
9. Exercise metadata: mechanic family, learning objective, answer, distractor
   rationale, diagnostic feedback, recovery, and required audio or input resources.
10. Estimated page time and a generated quality report covering narrative duration,
    word lifecycle, exercise distribution, audio, evidence, and review state.

A short **field note** may revisit a county without becoming a county-completion
story. Field notes are explicitly labelled reconstructions, traditions, or evidence
encounters; they cannot carry assessed facts that exist only in invented dialogue.
See `STORY-RESET.md` and D13.

Fictional guide characters may help the learner act inside a scene, but they cannot
replace the real anchor. Story mode gives most of its time to the significant reading,
its sources, and meaning-making. Learning mode uses shorter narrative connective
pages and full-screen exercises to practise language the story has already earned.

## Information architecture and migration

Counties are the primary navigation and progress layer. Stories are the unit of
learning and ship/review independently. The historical spine is the curriculum and
production layer behind them; it tells us what language a story should introduce next.

The current app is still backed by `chapterN.json` and a chapter-shaped `journey.json`.
That is retained as migration data, not the end state. The county-story migration must:

1. preserve existing Chapter 1–3 progress, artifacts, and Ar Ais visits;
2. represent Mayo, Offaly, Dublin, and Meath as county stories without duplicating
   their content;
3. allow a county to add a later story without overwriting its earlier completion;
4. show research-state counties honestly rather than creating empty playable shells;
5. migrate beat-index progress to stable page ids;
6. preserve separate story-read and language-complete states;
7. prevent Story-mode completion from scheduling words that were not learned.

`COUNTY-STORY-SLATE.md` is the development starting point for the first story in each
county. It is deliberately not a source of publishable copy; its rows graduate only
through the review and rights gates above.

## Production sequencing

The current four-county loop is an engineering proof, not the content pattern for the
next tester build. Mayo's six-episode implementation is too short; Offaly, Dublin, and
Meath are twelve-beat editorial previews with insufficient story and learning depth.
Preserve their atlas, evidence, collection, scheduling, offline, and migration work,
but rebuild their authored county packs under D21–D22.

Mayo proves the new model first: one complete Rockfleet chapter, then the full
eight-to-ten chapter arc. Offaly, Dublin, and Meath may progress source and specialist
work in parallel, but no later county is promoted before the representative Mayo
chapter passes. The map includes other counties honestly as researched or still-ahead
territory.

When a county receives another constituent story, it must be placed explicitly inside
or outside the designated core arc rather than silently changing completion semantics.

## Exercise affordances

Exercises are full-screen pages interspersed with narrative pages in Learning mode.
Each page has one task, one dominant response area, diagnostic feedback, and a usable
retry. When a response needs a fada, show the `á é í ó ú` keys directly beneath the
field with the plain reminder that the mark can change a word. Type-in feedback must
distinguish “letters right, fada missing” from a wrong answer. Instructions name the
next action before asking the learner to perform it.

Every county must meet these minimums:

- all 20 words are heard in meaningful context, retrieved, used in a phrase or
  sentence, and reused in a later chapter;
- at least seven mechanic families;
- no mechanic family exceeds 25% and none repeats consecutively;
- at least half of exercises operate on phrases or complete sentences;
- at least 40% require construction, typing, speaking, ordering, or other active
  production;
- recognition multiple choice is at most 25%; single-word listen-and-pick is at most
  10%;
- speaking is ungraded record-and-compare, with a non-recording continuation when
  microphone permission is unavailable;
- dragging is never the only way to answer.

The validator and release gates are defined in `CONTENT-PIPELINE.md` and
`STORY-LEARNING-REBUILD-PLAN.md`.
