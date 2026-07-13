# Personal atlas — pilot content note

*Phase 1 minimum lovable pilot for `docs/PERSONAL-HISTORIES-FEATURE-PLAN.md`.*

## Bundled pack

- App resource: `ios/AnTuras/Resources/personal-atlas-subjects.json`
- Counts: 25 given names, 25 surnames, 30 places
- Depths: `authored` (full short answer + forms + branches) and `foundation` (honest shell + “deeper story still being researched”)
- Content date and attribution ship inside the pack
- The 80-subject pack is a **foundation index**, not 80 showcase experiences. See
  `SHOWCASE-CANDIDATES.md` for the deliberately small Phase 1b promotion queue.

## Editorial posture

Pilot name packs are **editorial syntheses** pending specialist review and a licensed modern surname authority. They must not be treated as final scholarship. Place forms lean on Logainm (CC BY 4.0) where an id is present; other place notes are pilot shells awaiting monthly ingest.

## Regeneration

The corpus was generated for the pilot. Its repeated `storyBeats` are scaffolding and
must not appear in the public result flow or qualify an entry as showcase-authored.
Prefer editing the JSON for small fixes; regenerate only when expanding the subject
set in bulk.

## CMS

`tools/content-review/manifest.json` lists the personal-atlas pack as a review surface
alongside county stories. The UI now reviews each assertion, its named reviewer,
rights, audio state, accessibility, competing readings, query demand, and the gated
`candidate → specialist reviewed → showcase` progression. Public preview export is
deny-by-default through `tools/publish_personal_atlas.py`.

## Phase-spanning engineering

See `docs/PERSONAL-ATLAS-DELIVERY.md`. Native surfaces include coarse opt-in nearby
suggestions, private corrections, a privacy-safe query ledger, sourced sharing,
method/limits, a learning keepsake, offline field mode, and a user-controlled family
research worksheet. These capabilities do not promote the pilot corpus.
