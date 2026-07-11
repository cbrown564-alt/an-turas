# The 32-county atlas

## Product promise

*An Turas* takes the learner around all 32 counties of Ireland, one county at a time.
A county is the visible unit of progress; encounters are the units completed along
its core story arc. At each stop the
learner should eventually be able to say:

> I learned 20 useful Irish words through significant stories and encounters from
> this county, rooted in real people, myths, monuments, communities, or primary
> records.

The map always shows all 32 counties. Gold means every designated core encounter in
that county's arc is complete; green means the county now in hand; white means the
county is still ahead. Completing the core arc advances the learner to the next
county selected by the historical and language spine. White is an honest promise,
never a disguised lock. The island shows the whole journey without becoming a county
picker.

## County, story, and encounter

A **county arc** is the designated sequence of core encounters through which the
learner completes that county and earns its 20-word language promise. A constituent
**story** supplies a coherent narrative within the arc. An **encounter** is a
completable movement within a story; it may introduce or reuse part of the county's
language payload. No constituent story or encounter is obliged to carry all 20 words
by itself.

The default hypothesis is that one flagship story, divided into episodes, carries the
entire county arc. Before production, that hypothesis must be stress-tested for:

1. enough sourced historical and human change to sustain a satisfying episodic arc;
2. enough authentic dramatic situations for the learner to earn and reuse all 20
   useful words without padding or vocabulary detours.

If the flagship fails either test, side stories may supply the missing narrative or
language ground. They are a remedy for a demonstrated gap, not a default content
quota. Gráinne is currently Mayo's flagship hypothesis, not yet a finding that her
story can carry the complete Mayo arc.

The learner completes one county at a time. A county turns gold when every designated
core encounter in its arc is complete.

## Story contract

Every playable county story must carry these fields in `journey.json` before it
can be presented as ready:

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
   teaching vehicle, not additional quota units. Every headword must be introduced at
   a dramatic or practical need, used meaningfully by the learner, and reused in a
   later encounter or episode. Mere exposure does not fulfil the promise.
5. `spineRefs` — the era/grammar/artifact rails the story uses. These are sequencing
   metadata, not the county's learner-facing identity.
6. `reviewState`, historian source notes, a rights record, and Irish-language
   pedagogue sign-off before public release.
7. Evidence metadata — `evidenceKind`, `certainty`, dated bounds, source object or
   record, and `reconstructionState` — so the interface can distinguish what survives,
   what is inferred, what is traditional, and what has been imagined.

A short **field note** may revisit a county without becoming a county-completion
story. Field notes are explicitly labelled reconstructions, traditions, or evidence
encounters; they cannot carry assessed facts that exist only in invented dialogue.
See `STORY-RESET.md` and D13.

Fictional guide characters may help the learner act inside a scene, but they
cannot replace the real anchor. Most of each session's time belongs to the
significant reading, its spoken Irish, and meaning-making; exercises practise
language the reading has already earned.

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
4. show research-state counties honestly rather than creating empty playable shells.

`COUNTY-STORY-SLATE.md` is the development starting point for the first story in each
county. It is deliberately not a source of publishable copy; its rows graduate only
through the review and rights gates above.

## Production sequencing

The current playable packs are legacy Mayo, Offaly, and Dublin prototypes; D13
supersedes their editorial centres without discarding their engineering, interaction,
or progress work. Gráinne's Mayo, the Cross of the Scriptures in Offaly, and Sihtric's
penny in Dublin require replacement source briefs before new story production. Meath
is the candidate fourth stop but must pass the same clean-slate test. The map includes
the other counties honestly as researched or still-ahead territory.

When a county receives another constituent story, it must be placed explicitly inside
or outside the designated core arc rather than silently changing completion semantics.

## Exercise affordances

When a response needs a fada, show the `á é í ó ú` keys directly beneath the
field with the plain reminder that the mark can change a word. Type-in feedback
must distinguish “letters right, fada missing” from a wrong answer. Instructions
should name the next action before asking the learner to perform it.
