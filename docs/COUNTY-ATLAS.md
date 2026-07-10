# The 32-county atlas

## Product promise

*An Turas* takes the learner around all 32 counties of Ireland. A county is the
visible unit of progress; a story is the unit of learning. At each stop the
learner should be able to say:

> I learned 20 useful Irish words by reading a significant story from this
> county, rooted in a real person, myth, monument, community, or primary record.

The map always shows all 32 counties. Gold means every shipped story in that
county is complete; green means the story now in hand; white means the county
is still ahead. White is an honest promise, never a disguised lock.

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
4. `vocabularyTarget: 20` and `vocabularyPlan` — four visible five-word groups
   (story people/things; place/movement; actions/descriptions; reusable conversation)
   showing where every word is earned and later revisited.
5. `spineRefs` — the era/grammar/artifact rails the story uses. These are sequencing
   metadata, not the county's learner-facing identity.
6. `reviewState`, historian source notes, a rights record, and Irish-language
   pedagogue sign-off before public release.

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

The current playable content is Mayo, Offaly, and Dublin; Meath is the planned fourth
launch-quality stop. The map deliberately includes the other counties now, but their
cards state that research and review are still in progress. This prevents the map from
making a false claim that 32 complete courses already exist while giving the product
its intended long-term shape.

When a county receives a second era, it gets a second story rather than being
silently overwritten. County completion then means the learner has completed
all shipped stories there.

## Exercise affordances

When a response needs a fada, show the `á é í ó ú` keys directly beneath the
field with the plain reminder that the mark can change a word. Type-in feedback
must distinguish “letters right, fada missing” from a wrong answer. Instructions
should name the next action before asking the learner to perform it.
