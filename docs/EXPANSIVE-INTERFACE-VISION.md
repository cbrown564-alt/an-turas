# The living historical atlas

*Interface vision — 11 July 2026. Direction for exploration, not an implementation
specification. It describes what the product should become when real history, real
people, evidence, and all 32 counties are the primary material.*

## The leap

The existing app is beautifully constructed around a narrow dramatic idea: enter an
imagined historical world, learn enough Irish to take part, and leave with a crafted
artifact. Its intimacy, typography, haptics, spoken-Irish treatment, and refusal of
cheap gamification are assets.

The county reset asks for a larger vessel.

The future app is a **living historical atlas of Ireland that teaches Irish**. The
learner moves across a real island, meets consequential people and communities,
examines the evidence that survives, hears the language of each place, and gradually
becomes able to speak about what they have seen. Lessons remain, but they are no
longer the primary visual metaphor.

The emotional promise changes from:

> Step into this imagined scene.

to:

> Look at this island. Every place has something to tell you, and Irish lets you get
> closer to it.

## Product principles

### 1. Ireland is the home screen

The full island is not a course-selection illustration. It is the persistent spatial
index of people, stories, language, sources, and progress. Every major surface can
return to it. The map should reward looking around before it asks for completion.

### 2. Real people have faces, names, places, and consequences

A person is not a decorative portrait above a lesson title. Their county dossier
shows where they lived or acted, when they entered the story, what survives from
them, whom they affected, and where their story continues elsewhere on the map.

### 3. Evidence is a product primitive

A petition, penny, cross, letter, poem, recording, photograph, place-name, and ruined
wall each require a different way of looking. The interface should let the learner
zoom, turn, trace, compare, hear, and annotate evidence. Sources are not relegated to
an academic footnote screen.

### 4. Certainty is visible

The app distinguishes **documented**, **material evidence**, **later account**,
**tradition**, **disputed**, **reconstruction**, and **unknown** through plain labels
and consistent visual treatment. This is part of the storytelling, not legal copy.

### 5. Language is carried out of the story

Twenty words per county remain a clear promise, but they appear as a growing personal
vocabulary tied to people, objects, actions, and places. The learner can always see
where a word first mattered and where it has travelled since.

### 6. History is layered, not flattened into a march

The opening road is authored and cumulative. Beyond it, learners can browse regional
and thematic routes. A time control reveals that several Irelands occupy the same
ground. The map supports chronology without pretending history is one straight line.

### 7. Restraint survives the expansion

More expansive does not mean denser, louder, or more game-like. One strong historical
question per screen is preferable to a dashboard of counters. Detail appears through
progressive disclosure. The current app's quiet confidence remains the standard.

## The new information architecture

Four durable destinations are enough:

1. **An tOileán / The Island** — map, time, counties, people, and routes.
2. **An Scéal / The Story** — the current documentary journey and its language work.
3. **An Cnuasach / The Collection** — evidence encountered, personal artifacts, and
   words carried forward.
4. **Ar Ais / Return** — people, places, phrases, and sources asking to be revisited.

These may become tabs, map modes, or another native navigation pattern after
prototyping. The conceptual separation matters more than the control.

The current *Músaem* does not disappear; it expands into *An Cnuasach*. A hack-silver
ring made by the learner can sit beside the real Sihtric penny that inspired it. The
product distinguishes **what survived** from **what you made**.

## An tOileán — the island as an explorable surface

### Default map

The first view shows the whole island, county boundaries, the active road, completed
encounters, and researched stories still ahead. It should also show a small number of
meaningful story signals: a face, object, date, or question—not 32 undifferentiated
pins.

The learner can:

- tap a county to open its dossier;
- follow the fixed opening road;
- inspect white counties without being sold an empty lock;
- see stories that cross county lines;
- return to the present location of an object or monument;
- switch between journey, time, and theme views;
- use an accessible county list carrying exactly the same information.

### Time view

A horizontal time control changes the map's visible people, routes, settlements,
documents, and borders. It is not a precise GIS reconstruction at launch. It is an
editorial layer that answers: *what else was happening on this island then?*

The fixed opening road can make its unusual start explicit:

> Mayo, 1593 — the invitation

then:

> Rewind to Offaly, c. 900 — the long road begins

After that, time advances through Dublin, Meath, Donegal, Kerry, and later stops.

### Theme view

Themes reveal relationships that county borders conceal: sea routes, writing,
women's lives, power, belief, land, migration, work, music, revival, and the changing
language itself. These are editorial routes through completed and future stories,
not collectible categories.

### Geographic scale

Zooming should reveal story geography where it matters: Clew Bay and Gráinne's Mayo
sites; the river and esker crossing at Clonmacnoise; Sihtric's Dublin and the penny's
findspot; routes of departure, trade, pilgrimage, or correspondence. County cards
remain useful, but a story is allowed to occupy several points and lines.

## The county dossier

A county no longer opens to a small launch card. It opens to an editorial front page:

- county name in Irish and English, province, and pronunciation;
- one commanding landscape or cartographic view;
- the headline person, community, object, or event;
- a one-sentence historical question;
- time and evidence type;
- **What survives:** the document, object, place, recording, or tradition;
- **What you will be able to say:** the useful language outcome;
- story route on the local map;
- later stories in the same county, when they exist;
- source and review state expressed without production jargon.

For Mayo, the dossier might open on Clew Bay, place Clare Island, Kildavnet, and
Rockfleet, then set a document from 1593 beside the popular “pirate queen” image. The
question is visible before the Start button: *What did Gráinne actually ask for?*

## An Scéal — documentary storytelling with language inside it

The current sequence of full-screen pages is still valuable. The page vocabulary
needs to grow beyond scene, note, and exercise.

### New story registers

| Register | Purpose | Typical interaction |
| --- | --- | --- |
| **Cold open** | establish stakes with a true event or object | cinematic map/portrait/object reveal |
| **Person** | introduce a named actor without reducing them to a bio card | portrait, name forms, relationships, source voice |
| **Place** | make geography causally important | pan/zoom route, layered place-name |
| **Evidence** | inspect what survives | zoom, rotate, trace, transcribe, listen |
| **Source reading** | work through a short primary passage | line focus, context, translation, uncertainty |
| **Timeline** | connect events without expository dumping | scrub a bounded sequence |
| **Language lens** | explain the Irish the story has earned | spoken line, pattern, comparison |
| **Practice** | retrieve and recombine useful Irish | current clean exercise registers |
| **Reconstruction** | offer a bounded imaginative bridge | visibly labelled, optional, never the factual source |
| **Afterlife** | connect history to the present | contemporary place, institution, word, song, debate |

The story alternates attention rather than adding prose: person → map → object → a
line of Irish → source → learner response. Historical significance and beginner
language can coexist because the interface changes register instead of making a
fictional guide explain everything.

### True account before reconstruction

Every story establishes, in order:

1. the question;
2. the secure account;
3. the surviving evidence;
4. what historians infer;
5. what remains unknown;
6. only then, if useful, one possible reconstruction.

A reconstruction gets its own entry and exit treatment. The learner should never
need a disclaimer to realise that the register has changed.

### The learner's role

The learner does not become Gráinne's assistant, Sihtric's merchant, or a witness to
an unrecorded conversation merely to justify an exercise. They remain themselves: a
person examining the past and learning enough Irish to name, describe, ask, answer,
and remember it.

Moments of participation remain possible—tracing a route, reading a name, choosing
how to describe an object, carving a reconstruction—but the app does not pretend the
learner caused history.

## People as a connected layer

The app should gradually build a cast of real people rather than a succession of
disposable fictional guides.

A person's page can show:

- Irish and English name forms, pronunciation, and contemporary spellings;
- dates expressed honestly as exact, approximate, or disputed;
- county places and journeys;
- family, allies, opponents, patrons, makers, and later interpreters;
- surviving words or records, with source context;
- appearances in other county stories;
- claims the app deliberately does not make.

Relationships should appear only when they clarify three or more stories. This is not
a genealogy database or a social-network gimmick. It lets a learner notice that the
same people, institutions, roads, and consequences recur across the island.

## An Cnuasach — from trophy room to evidence collection

The collection has three clearly separated shelves.

### What survives

Real evidence encountered: petition, coin, cross, inscription, letter, poem,
recording, photograph, building, or landscape. Each object remembers its provenance,
rights, source, certainty, county, date, and the part of the story it answered.

### What you made

Personal artifacts: name in Ogham, illuminated initial, arm-ring, letter, map,
recording, or later free composition. These keep the tactile joy of the current
museum without masquerading as historical objects.

### Words you carry

The useful Irish learned across counties. A word can be opened to show pronunciation,
first encounter, later uses, dialect notes, and due review. This makes “20 words per
county” visible without turning it into a spreadsheet-like inventory.

## Ar Ais — return to meaning, not task debt

The existing principle survives: no overdue-card count. Return prompts now draw from
real anchors and evidence:

- a phrase from Gráinne's Mayo story is used in a new introduction;
- Sihtric's penny has lost part of its legend and asks to be read again;
- the road into Clonmacnoise needs directions;
- a place-name encountered in one county reappears in another;
- a source once marked uncertain is compared with a later account.

Review copy must not imply that a dead historical person is literally waiting for the
learner or speaking unattested Irish. The emotional language can remain warm without
crossing the evidence boundary.

## Visual direction

### Keep

- editorial typography and generous space;
- carved, chalked, inked, and weathered materiality;
- restrained Atlantic colour;
- native-feeling motion and haptics;
- spoken Irish as the visual hero;
- artifacts that respond to the learner's hand;
- light and dark modes designed as atmospheres, not inversions.

### Expand

- cartography as a primary visual language;
- portraits and named people;
- documentary photography and scans where rights permit;
- commissioned line drawings of objects when source imagery cannot be licensed;
- diagrams, routes, timelines, and comparative views;
- era-specific materials—stone, metal, vellum, print, paper, tape—inside one coherent
  system;
- present-day landscapes so history is visibly continuous with the island now.

### Release

- Ogham/chisel language as the universal skin for every era;
- generic cinematic characters as the main visual anchor;
- the assumption that every story needs the learner inside a simulated room;
- small cards trying to summarise an entire county;
- one linear path drawn across the island as the only mental model.

The Solas an Atlantaigh illustration style can remain one voice in the system. It
should serve reconstruction and atmosphere while primary evidence keeps its own
documentary authority.

## First-run vision

The first five minutes must demonstrate the whole proposition:

1. The island appears without a course menu.
2. The camera settles on Mayo and Clew Bay.
3. Gráinne Ní Mháille is named immediately.
4. A 1593 document or licensed explanatory facsimile appears: the first encounter
   with evidence.
5. One sharp question lands: *What did she ask for?*
6. The learner hears and uses their first Irish to identify themselves: *Is mise…*
7. The Mayo dossier and the wider island open, showing that this is one beginning
   among many.

The historical hook arrives before onboarding exhausts it. Account setup, goals,
notifications, dialect explanation, and subscription framing can wait until the user
has felt the product's difference.

## What the 32-county structure should become

The first 10–12 stories form a fixed opening road because language is cumulative.
After that, the island opens through regional and thematic routes. A learner can
choose what pulls them while the language layer recommends stories appropriate to
their current reach.

Possible route families include:

- **North and borders:** Derry, Tyrone, Fermanagh, Cavan, Monaghan, Down, and Louth;
- **roads through the middle:** Longford, Westmeath, Laois, Kildare, Carlow, Kilkenny,
  and Tipperary;
- **Atlantic lives:** Sligo, Leitrim, Clare, Limerick, Kerry, Cork, and Waterford;
- **stories, saints, and remembered landscapes:** Wicklow, Kildare, Louth, Roscommon,
  and other counties whose first anchor is literary or traditional.

These overlap deliberately. Counties remain the visible completion unit; routes are
ways of seeing relationships, not new progress currencies.

## Product and content model implications

The vision eventually requires:

- multiple stories per county;
- people, places, objects, sources, and claims as addressable entities;
- story routes containing points and lines, not one latitude/longitude;
- evidence and certainty types;
- precise source/rights attribution per asset and claim;
- field notes distinct from county-completion stories;
- an authored opening-road order plus later prerequisite recommendations;
- completion stored by story, with county completion derived;
- legacy chapter progress mapped without loss;
- downloadable media-rich story packs that remain useful offline;
- accessible alternatives for maps, object manipulation, audio, and motion.

This does **not** require building a general-purpose historical database. Author only
the entities and connections a shipped story needs.

## Approved prototype; story before platform

The first high-fidelity flow has now been built and iterated:

1. **Island → Rockfleet and the stakes**
2. **Rockfleet → Gráinne as a person and leader**
3. **Gráinne → find her name and family in the 1593 letter**
4. **Her Irish name → the learner's first Irish introduction**
5. **Story exit → the wider island**

Testing rejected both an architecture-heavy atlas introduction and an over-corrected,
document-led simplification. The approved foundation is story-led, source-grounded,
progressively disclosed, and emotionally inviting. See
`GRAINNE-PROTOTYPE-REPORT.md`.

The next design phase is not more atlas surface. It is resolving the full Gráinne
story contract and storyboarding four to six source-backed movements before further
SwiftUI expansion or external testing. The full-story prototype should test whether
learners can answer:

- Who did you meet, and why did they matter?
- What real thing did you examine?
- What did the surviving record reveal, and how did it change the story?
- Which Irish can you now use outside the story?
- Where do you want to go next on the map?

Success is not merely “beautiful” or “engaging.” The new interface succeeds if it
makes the history more memorable, the evidence more trustworthy, the language more
usable, and the island feel larger after every encounter.

## Decisions deliberately left open

- whether the four destinations are tabs or contextual navigation;
- exact map technology, projection, zoom depth, and offline tile strategy;
- portrait style and the boundary between documentary assets and illustration;
- whether the time control is always present or a dedicated mode;
- how much of the opening road is available before subscription;
- whether field notes are scheduled, discovered geographically, or editorially
  placed;
- how regional choice and language prerequisites negotiate when they conflict;
- the final Irish names for interface destinations and certainty labels;
- how source citations appear at learner depth versus reviewer depth.

These should be answered through deliberate product work and targeted prototypes, not
by extending the current navigation one card at a time.
