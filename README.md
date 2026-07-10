# An Turas (working title)

An iOS app for learning Irish (Gaeilge) that treats language, culture, and history as
one inseparable thing — because for Irish, they are.

## The idea

Existing apps teach Irish as if it were Spanish with stranger spelling. Duolingo keeps
people coming back with streaks and leagues; the language itself is interchangeable.
We invert that: **the thing that pulls you back is a growing sense of connection to
Ireland** — a journey through all 32 counties, where language is woven into the story
of a real place.

Every county stop is anchored in a named person, myth, monument, community, or primary
record — never a generic historical stand-in. The learner spends most of the time with
a significant reading or encounter, then practises the Irish that reading has earned.
The concrete promise is **20 useful Irish words per county**, with progress visible on
the island map: green for the current journey, gold for completed counties, white for
places still ahead. You learn the words *because this county's story needs them*.

Because we do exactly one language pair — English → Irish — we can go deep on what
actually makes Irish hard for English speakers (VSO word order, initial mutations,
the two "to be" verbs, broad/slender consonants) instead of pretending those
differences don't exist.

## The two problems we're solving

1. **Difficulty** — Irish is genuinely hard for anglophones, and most tools either
   ignore the hard parts or drill them without explanation. We explain, then drill.
2. **Motivation** — gamification manufactures a reason to return. We want the reason
   to be real: identity, heritage, story, and visible progress toward being able to
   *say something that matters in Irish*.

## Repo map

- `STATUS.md` — where we are, work log, Phase 2 next steps.
- `docs/DECISIONS.md` — decision log (D1–D11); everything downstream flows from here.
- `docs/STRATEGY.md` — the strategic map: path to launch, unknowns, biggest
  challenges, resource landscape, competitive landscape.
- `docs/COUNTY-ATLAS.md` — the county-led product contract and map/progress rules.
- `docs/COUNTY-STORY-SLATE.md` — researched first-story leads for all 32 counties;
  a development slate, not publishable history.
- `docs/SPINE.md` — the historical and language sequencing rail behind county stories.
- `docs/COMPETITIVE-RESEARCH.md` — competitive research: pedagogy, features,
  positioning, failed experiments.

## Status

**Phase 2 — county-led content pipeline.** Phase 1 complete: Chapter 1 vertical slice
playtested in SwiftUI; narrative pull validated. The next product transformation is to
make the 32-county journey the primary learning structure, while retaining the
historical spine as the language-sequencing rail. See `STATUS.md` for current work and
`docs/DECISIONS.md` for the decision log.
