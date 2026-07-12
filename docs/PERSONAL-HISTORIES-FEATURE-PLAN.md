# The history behind a name and a place

*Feature strategy and multi-phase implementation plan — 12 July 2026.*

This plan should be read with `PRODUCT.md` and `DESIGN.md`. Their product and design
contracts govern implementation; this document defines the feature-specific
experience, evidence model, rollout, and learning loops.

## The decision

Build these as two doors into one first-class product surface: **the personal atlas**.

- **Behind a name** begins with a given name or surname and reveals its forms,
  pronunciation, linguistic roots, historical changes, distribution in surviving
  records, and selected people or sources that illuminate it.
- **Behind a place** begins with a current location, searched place, or map point and
  reveals the Irish and English forms, pronunciation, recorded historical forms,
  proposed derivation, the landscape inside the name, and stories or evidence rooted
  there.

They must work as stand-alone invitations for a new user and as deeper layers inside
the county journey. They are not side panels full of trivia. Each should give the
feeling of placing something familiar under a different light and watching time
appear inside it.

The shared promise is:

> Give us a name or a place that matters to you. We will take you as far back as the
> evidence allows, show you what changed along the way, and leave you with something
> worth carrying forward.

## What the product may and may not claim

This boundary is foundational.

| Input | The app can responsibly explain | It must not imply |
| --- | --- | --- |
| A given name | language of origin, component meanings, older forms, pronunciation, Irish use, popularity through time | that the meaning predicts the bearer's character or that every modern bearer shares one origin |
| A surname | documented forms, likely etymology or multiple origins, naming grammar, historical distribution, notable source appearances | that everyone with the surname belongs to one clan, has a crest, descends from a famous figure, or comes from one county |
| A user's family | research routes and records that may help a person investigate | a family tree, relationship, migration path, or genetic ancestry not established by user-supplied evidence |
| A place-name | official forms, recorded variants, scholarly derivation, language components, landscape context, and local traditions | that a neat modern translation is necessarily the historical origin, or that folklore is documentary fact |

The content graph retains the evidence states **recorded**, **supported
interpretation**, **possible**, **local tradition**, **disputed**, and **unknown**.
The result page does not repeat that taxonomy as badges. A quiet, tappable evidence
mark sits beside a material claim and opens its status, sources, competing readings,
and review history. Persistent text labels are reserved for disputed, traditional,
reconstructed, unknown, or otherwise consequential boundaries. Folk etymology can be
delightful content when it is clearly introduced as folk etymology.

## The experience

### Entry points

The two hooks should be visible before a user has committed to a course.

1. **First encounter:** after the island appears, a quiet invitation offers “A name
   you carry” and “A place you know.” No account, notification, dialect, or payment
   prompt comes first.
2. **The Island:** search accepts a name, place, townland, address, or map point. The
   result becomes a layer of the atlas rather than a detached utility.
3. **Inside a story:** a person's name or a place-name can be opened in context. The
   deeper page remembers where the learner came from and returns them to the same
   story beat.
4. **The Collection:** saved names and places sit together under “What matters to
   you,” separate from historical evidence and learner-made objects.
5. **A share link:** a carefully framed excerpt can open on the web or in the app. It
   should carry a source path and accessible evidence state, not just a decorative
   quote card.

### Behind a name: the ideal sequence

1. **Ask lightly.** “Which name shall we look at?” Accept a single name; do not ask
   for a full legal name. Offer recent searches only when the person has opted to
   save them.
2. **Resolve with respect.** Preserve fadas, apostrophes, spaces, `Mac/Mc`, `Ó/O'`,
   `Ní/Nic`, and historic spellings. If several origins are possible, ask a useful
   disambiguating question or show the branches honestly.
3. **Give the short answer.** Pronounce the name and offer a two- or three-sentence
   account of what can safely be said. The first screen must be satisfying on its own.
4. **Let the form travel.** A restrained horizontal sequence shows the earliest
   relevant attestation, later Irish forms, anglicised or translated forms, and
   modern spellings. The transitions should reveal change, not imply one inevitable
   line.
5. **Put it on the island.** Where records permit, show historical distribution by
   period and source. Label the dataset and year prominently. “Common in this record”
   is not “your family came from here.”
6. **Meet a bearer, not a celebrity list.** One or two sourced lives can illuminate
   how a form was used in a particular time and place. The person earns their place
   through the story, not fame.
7. **Carry a little Irish away.** Teach the relevant naming form—`Is mise…`, `Ó`,
   `Ní`, `Mac`, `Nic`, or a pronunciation contrast—only when it belongs to this name.
8. **Save or continue.** Save the page, make a restrained personal name mark, or open
   the county/person/story connection. Sharing is optional and never the final demand.

### Behind a place: the ideal sequence

1. **Find the right place.** Search by official or local form, use current location
   with permission, or drop a point. Duplicate names show county, townland class, and
   map context before selection.
2. **Let it be heard.** Show Irish and English forms without treating one as a
   subtitle. Offer pronunciation in the relevant dialect where verified audio exists.
3. **Reveal the name beneath the name.** A concise account explains the leading
   derivation once, with word components that can be heard and opened. Literal gloss
   and historical derivation remain separate in the content graph, but the interface
   must not repeat identical prose to demonstrate that distinction.
4. **Show its older shapes.** Historical spellings appear against dated source marks.
   The learner sees scribal, administrative, and anglicising change without a lecture.
5. **Return the words to the ground.** A local map or landscape view makes the river,
   ford, ridge, church, wood, settlement, person, or other referent visible when the
   interpretation supports it.
6. **Open the human layer.** One relevant story, record, object, photograph, or
   tradition shows that the place-name was carried by people. Tradition is visibly a
   different register from documented history.
7. **Stand in the present.** End with the place now—a current landscape, local voice,
   or small invitation to notice the feature in person. Offer a county story or route
   only when the connection is real.

### Visual and interaction direction

This surface is an especially literal expression of `DESIGN.md`'s **Living Field
Journal**: a familiar name or place sits close enough to examine, while the wider
island remains just beyond it. It should expand the system through real cartography,
source images, typographic forms, voices, and time layers—not parchment, clan heraldry,
knotwork decoration, or generic “Celtic” illustration.

Apply the named design rules directly:

- **Two voices:** New York/system serif carries names, place forms, story, quotation,
  and evidence; SF Pro carries search, navigation, controls, metadata, filters, and
  source actions. Both use semantic Dynamic Type styles rather than fixed geometry.
- **Evidence marks:** one small, familiar SF Symbol gives a material claim a quiet
  path to its evidence detail. The visual mark has a 44-point hit target and complete
  VoiceOver label; the opened detail carries status text, sources, competing readings,
  and review history. Moss/lichen/rust may reinforce meaning but never replace the
  symbol or accessible text. Repeated certainty pills and production labels are not
  part of the public interface. The exact symbol mapping remains provisional until
  usability and expert review lock it in `DESIGN.md`.
- **Flat field:** prefer full-width editorial sections, source-led layouts, tonal
  limestone/raised/sunk layers, and separators. Do not turn etymology branches,
  historical forms, people, and sources into an identical card grid.
- **Native shell:** use `NavigationStack`, native search and text fields, standard
  sheets for focused choices, edge-swipe back, safe areas, and 44-point targets. The
  content can feel singular without inventing new iOS controls.
- **Sparse labels:** use a contextual label only when it conveys a real date, place,
  evidence class, language register, or uncertainty state. Do not add an uppercase
  eyebrow to every reveal.

The physical scene is a person sitting with an iPhone in quiet evening light, perhaps
at home or on a train toward the place, giving full attention to something personally
familiar. Light and dark mode follow the device; the mood is intimate rather than
cinematic.

Motion has three feature-specific jobs:

- settle a modern spelling into earlier recorded forms;
- align a historic map or landscape feature with the present map;
- return a saved name or place to the island.

Use the existing `settle` token for state and form changes and reserve `rise` for a
genuine story turn; `pop` does not belong on routine search or evidence disclosure.
Every transformation has a Reduce Motion crossfade or immediate state change and a
static VoiceOver reading order. Haptics confirm a consequential selection or save,
never passive discovery. A list conveys every fact available on a map.

## Source and rights strategy

### Production foundation

| Source | Best use | Rights / integration posture |
| --- | --- | --- |
| [Logainm — Placenames Database of Ireland](https://www.logainm.ie/en) | official Irish/English place forms, type, hierarchy, coordinates, records, some explanatory material | Primary place index. API data is CC BY 4.0 with attribution; create a Gaois Developer Hub account, respect rate limits, and ingest monthly updates as Logainm recommends. |
| Oxford *Dictionary of Family Names in Britain and Ireland* | modern scholarly surname etymologies, variants, multiple-origin analysis, distribution context | Preferred surname authority if a commercial licence can be agreed. Do not copy entries before licensing. |
| Patrick Woulfe, *Sloinnte Gaedheal is Gall* (1923) | historic Irish name forms and an editorial starting point | Public-domain-age source, but dated scholarship. Never let it stand alone where modern work revises it. Store page-level citations. |
| Teanglann, Foclóir.ie, eDIL, and language specialists | component-word meanings, grammar, historic Irish forms, modern standard and dialect checks | Reference and review tools, not assumed bulk-content licences. Confirm reuse terms; commission final user-facing explanations and audio. |
| [CSO Irish Babies' Names](https://www.cso.ie/en/statistics/birthsdeathsandmarriages/irishbabiesnames/) | given-name and surname popularity through time and by area where disclosure thresholds permit | Use published/PxStat data with dataset, year, geography, and suppression rules visible. Popularity is context, not origin evidence. |

### Historical distribution and personal research routes

- The [National Archives census collections](https://nationalarchives.ie/collections/search-the-census/)
  provide 1901, 1911, and now 1926 household records. The 1926 initial release includes
  names, surnames, streets, and townlands and continues to receive accuracy updates.
  Use aggregate or precomputed distributions only under agreed terms; otherwise deep
  link to an official search. Never expose a living person's inferred family link.
- [IrishGenealogy.ie](https://www.irishgenealogy.ie/) provides official civil indexes
  and selected church records, with privacy cut-offs. Initially treat it as a guided
  research handoff, not a dataset to scrape or silently query on a user's behalf.
- The [National Library's Catholic parish registers](https://registers.nli.ie/) cover
  digitised microfilm for parishes across the island, generally to 1880. Images may be
  reproduced non-commercially; commercial publication requires permission. They are
  a “continue your own research” path until rights and indexing make deeper integration
  responsible.
- Northern Ireland requires equivalent coverage through the Public Record Office of
  Northern Ireland, GRONI, OSNI, and the Northern Ireland Place-Name Project. Rights,
  API availability, terminology, and community review must be resolved before claiming
  all-island parity.

### Story enrichment

- [Ainm.ie](https://www.ainm.ie/) is a strong source for Irish-language lives linked
  to places and variant names. Its content is research-use by default; obtain explicit
  permission before republishing or adapting biographies.
- [Dúchas.ie](https://www.duchas.ie/) can supply extraordinary local traditions,
  Schools' Collection material, photographs, and recordings. Its API data is CC
  BY-NC 4.0 and therefore incompatible with straightforward use in a premium product.
  Pursue a partnership or commercial permission; until then, use reviewed links and
  independently commissioned summaries from sources with suitable rights.
- Tailte Éireann historic six-inch and 25-inch mapping can make the “same ground,
  another time” interaction exceptional. The available historic products and MapGenie
  services are commercial inputs; budget and test them rather than assuming open use.
- Local historical societies, placename scholars, heritage officers, libraries, and
  community archives should be commissioning and review partners, especially where
  published databases are silent or local usage differs from official forms.

### Source hierarchy per assertion

Each user-facing assertion stores:

1. the exact claim in neutral editorial language;
2. subject and time/geographic scope;
3. source citation and, where possible, source excerpt location;
4. evidence class and certainty label;
5. reviewer, review date, and competing interpretation;
6. asset/content rights and required attribution;
7. the short user-facing explanation and optional closer look.

No result is publishable because “the page has sources.” Every material sentence must
be traceable. A source packet and claim ledger are required just as they are for county
stories.

## Content and technical model

Create one content graph with typed subjects rather than two bespoke page formats.

```text
OriginSubject
  id, kind(name | place), canonicalDisplay, variants[], languages[]

NameProfile
  nameKind(given | surname), grammar, pronunciations[], historicalForms[],
  etymologyBranches[], distributions[], peopleLinks[]

PlaceProfile
  logainmId, placeKind, hierarchy, coordinates, pronunciations[],
  historicalForms[], derivationBranches[], featureLinks[], storyLinks[]

Assertion
  statement, scope, certainty, evidenceRefs[], competingAssertionIds[],
  reviewer, reviewedAt, rightsState

Evidence
  sourceType, citation, stableURL, dateBounds, image/audio rights,
  attribution, transcription, translation

EditorialLayer
  shortAnswer, storyBeats[], languageMoment, save/share excerpt,
  contentVersion, releaseState
```

Implementation principles:

- Bundle a small reviewed index and the user's saved results for offline use; fetch
  versioned detail packs on demand and cache them.
- Normalize search without destroying the entered form. Diacritic-insensitive matching
  helps find `Grainne`; the result still teaches and displays `Gráinne`.
- Use typed variant relationships. `O'Brien`, `Ó Briain`, and `Ní Bhriain` are related
  forms, not interchangeable strings.
- Keep assertions and evidence addressable so corrections can update a claim without
  rewriting an entire page.
- Extend the existing content review tool with name/place previews, claim review,
  rights gates, audio state, and accessibility checks rather than creating a second CMS.
- Keep personal queries local or pseudonymous by default. Do not log raw full names,
  exact home coordinates, or genealogy searches. Analytics records subject IDs only
  for published entries and coarse failure categories for unresolved input.
- Treat user submissions as leads, never as facts. They enter a moderation queue and
  cannot change public content without source and expert review.

## Fallbacks are part of the feature

The experience must fail with the same care as it succeeds. Never fill a content gap
with generated prose that sounds plausible.

| Situation | User experience | Product response |
| --- | --- | --- |
| Fully authored match | Complete short answer and journey | Show all reviewed layers and connected stories. |
| Foundation-data match, no authored story | A useful, modest result | Show verified forms, type/location or name relationships, pronunciation state, source, and “The deeper story is still being researched.” Let the user request it. |
| Several plausible matches or origins | A respectful fork | Show the distinguishing evidence—county, place type, spelling, period, or origin—without selecting for the user. |
| Unknown or disputed derivation | The uncertainty becomes the subject | Show recorded forms, the leading readings, what would decide between them, and why no neat answer is offered. |
| Name is not specifically Irish | A real answer, not rejection | Explain its documented life or use in Ireland where evidence exists; do not manufacture an Irish derivation. Offer wider-origin coverage only when a reliable licensed source supports it. |
| User asks about their own family line | Clear boundary plus a path forward | Explain the difference between surname and family history, then offer a private research worksheet and official archive links. |
| Place is outside the island | Honest scope | At launch, say the place atlas currently covers Ireland. Save demand for later diaspora/place-name routes without retaining an exact private address. |
| No image, map licence, or audio | Typography and evidence still carry the page | Use no decorative substitute. Show a clear audio state, an accessible modern map if licensed, and the source record. |
| Network or upstream API unavailable | Cached value with freshness | Serve the last reviewed pack offline, display its content date, and defer live source updates. Never let an upstream outage erase a saved result. |
| Community correction conflicts with the published account | Acknowledged but not instantly public | Preserve the submission and context, route it to editorial review, and show competing readings only after evidence review. |

Because source coverage is asymmetric, rollout should be asymmetric too. Place search
can become broad early on top of Logainm while authored place stories remain visibly
curated. Name results should stay deliberately narrower until a modern surname source
is licensed and the editorial team can treat multiple origins properly. Artificial
feature parity would create confident-looking weak name pages.

## The phased build

### Phase 0 — Find the emotional and evidentiary form (3–5 weeks)

**Goal:** learn what makes the experience feel personal, trustworthy, and memorable
before committing to a universal template.

Build throwaway, high-fidelity prototypes for three name and three place structures:

- answer first, then evidence;
- evidence/object first, then interpretation;
- map/time first, then language.

Use a deliberately difficult 24-subject test set:

- given names with clear, multiple, imported, uncertain, historic, and recently
  revived origins;
- surnames with `Ó`, `Mac`, `Ní/Nic`, spelling drift, several unrelated origins,
  planter/immigrant histories, and no specifically Irish origin;
- places with dual names, repeated names, a townland, a street, a vanished feature,
  uncertain derivation, strong folklore, Northern Ireland terminology, and a
  politically contested public name.

Test with 12–18 target users, two Irish-language specialists, an onomastician or
placename scholar, a genealogist/archivist, and two local-history/community reviewers.
Ask for a 24-hour retelling, not only an immediate preference. Watch where users confuse
surname history with family history or literal translation with etymology.

**Exit gate:** one interaction grammar wins on trust, comprehension, emotional pull,
and next-day recall; the claim schema survives expert review; source and rights owners
for the first pilot set are known. No production architecture is built before this.

### Phase 1 — Minimum lovable pilot (6–8 weeks)

**Goal:** ship a narrow but complete experience to invited testers inside the iOS app.

Scope:

- 25 given names and 25 surnames, chosen from tester demand and the hard-case matrix;
- Logainm-backed search across the island, with 30 fully authored place experiences;
- a safe factual shell for other well-resolved Logainm entries: official forms,
  pronunciation state, type, hierarchy, map, source link, and an honest “deeper story
  still in research” message;
- save, return, source view, accessible map/list, and one real handoff into a county
  story;
- no genealogy matching, family tree, AI-generated etymology, heraldry, or open public
  submissions.

The result must be useful without an account. Saved results are device-local in the
pilot. Build the content as signed/versioned JSON packs so editorial work and app
releases are separable.

**Exit gate:** see the “good enough to continue” scorecard below. Failure leads back
to Phase 0 interaction/content work, not to adding more names.

### Phase 2 — Closed beta and editorial engine (8–12 weeks)

**Goal:** prove that quality can scale without flattening the experience.

- Extend the review CMS with assertion-level citations, competing readings, rights,
  reviewer assignments, query demand, and result previews.
- Add 100 surnames, 100 given names, and 100 authored place experiences in themed
  batches, each with a named editor and reviewer.
- Add verified human/native-speaker pronunciation for the pilot set; never ship an
  unreviewed synthetic reading of a personal name as authoritative.
- Add historic distribution only for sources with an agreed reproducible pipeline.
- Add claim-level feedback: “I know another local form” and “This does not match the
  place I meant.” Require a source or context, acknowledge the contribution, and keep
  it private until reviewed.
- Run an all-island coverage audit and commission the missing Northern Ireland source
  and terminology work.
- Test two entry points: pre-onboarding hook and in-journey drill-down. Measure whether
  the hook brings people into Irish/story work rather than becoming an isolated toy.

**Exit gate:** an editor can take a subject from requested to reviewed and released
without engineering; correction handling is demonstrably safe; breadth does not lower
the trust, recall, or emotional scores achieved by the pilot.

### Phase 3 — Public foundation (one release cycle)

**Goal:** make both hooks dependable enough to carry acquisition and onboarding.

- Launch searchable name and place histories with explicit coverage language.
- Add a privacy-preserving web preview for share links and search discovery.
- Add “near me” only after location permission is requested in context; use coarse
  location for suggestions and do not retain it.
- Connect relevant results to county dossiers, people, stories, words, and the
  collection graph.
- Add subscription framing after the free personal reveal. The first meaningful answer
  must not be held hostage to a paywall; deeper stories and the wider journey can show
  the value of membership.
- Establish a published corrections policy, editorial methodology, source credits,
  and “what we cannot tell from a name” explainer.
- Release only after content, accessibility, performance, offline, and rights gates pass.

### Phase 4 — Make it wonderful (continuous, themed releases)

This phase is not “more database rows.” It deepens the forms that testers prove matter.

- **Time in the hand:** align a place's present map with a licensed historic sheet;
  let a finger reveal recorded forms and vanished landscape features by date.
- **Voices of the place:** commission short local pronunciations and memories, with
  speaker, dialect, date, permission, transcript, and translation attached.
- **A name travelling:** show a carefully sourced form moving through a document,
  census period, county, or migration context without turning aggregate patterns into
  a user's ancestry story.
- **Personal keepsakes:** create a typographic name lineage or place time-strip made
  only from verified forms the learner encountered. It is a record of learning, not a
  crest or faux historical document.
- **Field mode:** when visiting, offer an offline place pack, walking-scale map, audio,
  and prompts to notice landscape evidence. Never require looking at a phone in an
  unsafe location.
- **Family research handoff:** a guided worksheet helps users record what they already
  know and opens the right official archives. It remains user-controlled research;
  the app does not infer relatives.
- **Community editions:** local partners review and narrate a cluster of place-names;
  revenue, credit, consent, and correction terms are agreed before production.

Every release is a small authored season—river names, names of women, townlands around
a county story, Irish names in the 1926 census—not an endless undifferentiated dump.

## Feedback loops that resist “just good enough”

### The query ledger

Record published subject IDs, unresolved reason, selected ambiguity branch, time to
first satisfying answer, and whether the user continued. Never record raw private
names or coordinates. Review the top unresolved and most-abandoned patterns every two
weeks. Editorial demand should come from real searches, but popularity never bypasses
the source/review gates.

### Three kinds of feedback

1. **Comprehension:** ask a tester to explain what the app knows, suspects, and cannot
   know. Misunderstanding is a design failure even when the text is technically correct.
2. **Resonance:** ask “Did this change how you hear or see the name/place?” and collect
   a short reason. A star rating alone cannot diagnose wonder.
3. **Correction:** attach feedback to a particular assertion or form, allow local
   knowledge, and preserve an editorial audit trail. Never crowdsource truth by vote.

### The fortnightly quality loop

1. Choose one observed failure or one unexplored opportunity.
2. Predeclare the hypothesis and the signal that would change the design.
3. Prototype two materially different solutions; do not compare palette variants.
4. Test with 5–7 relevant people, including one expert when evidence language changes.
5. Inspect next-day recall and downstream journey behaviour.
6. Keep, revise, or remove. Record why in `docs/DECISIONS.md`.

### Purposeful explorations

The first six explorations should be:

1. which reveal order creates the strongest combination of wonder and accurate recall;
2. how much evidence is visible before it feels academic, and how little creates false
   confidence;
3. how to describe competing origins without turning the result into a disclaimer wall;
4. whether a personal keepsake increases meaning or cheapens the encounter;
5. which handoff—county story, person, word, or nearby place—best converts curiosity
   into the main journey;
6. which real media role (map, document, landscape, voice, typography) deserves the
   visual centre for each subject type.

Do not A/B-test factual wording to maximize confidence, optimize for sharing without
source visibility, or reward editors for query coverage alone.

## What “good enough to continue” means

Phase 1 is allowed to advance only when all release gates and most experience targets
hold across the deliberately hard test set.

### Non-negotiable release gates

- 100% of material claims have assertion-level sources, certainty, reviewer, and
  rights state.
- Zero known severe factual errors, fabricated family links, unlabelled folklore, or
  unsupported single-origin claims.
- Every published subject has a graceful no-audio/no-image/no-deep-story state.
- Every map, audio clip, animation, color state, and manipulated object has an
  accessible equivalent.
- Search round-trips fadas, apostrophes, prefixes, gendered forms, and entered casing
  without corruption.
- Raw personal-name queries and exact locations do not enter product analytics.

### Pilot experience targets

- At least 90% of the curated hard-case queries resolve to the correct subject or an
  honest ambiguity/no-result path; there are no confident wrong matches.
- At least 80% of testers can distinguish a surname's history from their own family's
  history after one use.
- At least 70% can accurately retell one meaningful idea the next day, including the
  uncertainty when it mattered.
- At least 75% answer yes to “This felt made with care for the thing I entered,” with
  qualitative reasons that point to evidence, writing, sound, or visual treatment.
- At least 30% voluntarily save, share, inspect a source, or continue into a connected
  story. This is a directional engagement target, not a reason to add coercive CTAs.
- Median time to a satisfying short answer is under 20 seconds on a warm connection;
  the full experience remains inviting for several minutes.

Set final public-launch targets after the pilot establishes honest baselines. Do not
move goalposts merely because a weak design missed them.

## What “wonderful” looks like

The feature is wonderful when:

- the first answer is concise enough to remember and deep enough to feel discovered;
- a user can see exactly why the app believes it without leaving the emotional flow;
- uncertain or non-Irish origins feel respected rather than like failed searches;
- the sound and spelling of Irish are central, preserved, and pleasurable to explore;
- a map or recorded form produces a genuine sense of the present opening onto another
  time, without historical theatre or false intimacy;
- users spontaneously send a result to family or save it for a journey because it
  says something accurate they could not have found in a generic name site;
- local experts recognize care, ordinary users understand the story, and neither group
  feels the other was the real audience;
- curiosity naturally enters the county journey and language practice, while the
  personal result remains complete enough to stand alone;
- the editorial system can say “we do not know” beautifully.

## Workstreams and ownership

| Workstream | Required owner | First deliverable |
| --- | --- | --- |
| Product/design research | product designer/researcher | Phase 0 hard-case matrix, prototypes, test script, and 24-hour recall method |
| Onomastics and Irish language | named specialist editor + native-speaker reviewers | editorial style guide for forms, grammar, pronunciation, multiple origins, and certainty |
| Placenames/history | placename scholar/local-history editor | first 30 place packets with claim ledgers and community review plan |
| Archives/genealogy | archivist or accredited genealogist | safe-claim policy, research handoffs, privacy and record-coverage guide |
| Rights/partnerships | producer/legal owner | source-by-source licence register and outreach to Logainm/Gaois, OUP, Dúchas/UCD, Tailte Éireann, PRONI/OSNI, and Ainm.ie |
| Content operations | managing editor | CMS schema, review gates, correction policy, and throughput/cost baseline |
| iOS engineering | SwiftUI lead | normalized search, versioned content packs, accessible result shell, cache, and subject deep links |
| Data/backend | data engineer | ingestion provenance, subject/variant graph, signed releases, monthly Logainm update job, and private analytics taxonomy |
| Accessibility QA | independent tester plus engineering owner | VoiceOver/Dynamic Type/Reduce Motion/increased-contrast test matrix across all result states |

## Immediate next actions

**Phase 1 app shell (12 July 2026):** search, result views, bundled pilot packs
(25/25/30), local saves, collection shelf, and Mayo handoffs are in the iOS atlas.
Treat name packs as pilot syntheses until specialist review and licensing land.

**Phase 1b hardening (active after adversarial review):** the shell is implemented but
the feature has not passed its exit gate. Keep the wider pack as a transparent
foundation index and promote only a small, named-review showcase. Remove public
production labels, replace repeated certainty badges with inspectable evidence marks,
deduplicate the leading account, suppress unsupported audio surfaces, complete native
accessibility, and record the hard-case comprehension/recall results before Phase 2.

1. Appoint an onomastics/placenames editorial adviser before hardening production copy.
2. Open rights and API conversations with Logainm/Gaois, OUP, Dúchas/UCD, Ainm.ie,
   Tailte Éireann, and the Northern Ireland source owners.
3. Run the Phase 0 hard-case matrix against the shipped interaction grammar; revise
   reveal order only if comprehension/resonance/recall fail.
4. Replace pilot surname syntheses once a modern authority is licensed; enrich
   Logainm ids via monthly ingest.
5. Extend the content-review CMS with assertion-level claim review for personal atlas
   subjects and a distinct `showcase candidate → specialist reviewed → showcase`
   progression. Internal `authored` depth is not public evidence authority.
6. Gate public launch on the Phase 1 scorecard in this document — not on pack count
   alone.

This order deliberately buys learning before scale. The point of the pilot is not to
prove that the team can render an etymology page. It is to discover the form in which
evidence, language, design, and personal significance become one experience.
