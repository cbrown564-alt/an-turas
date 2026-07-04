# Illustration exploration — finding the visual voice

*Started 2026-07-05. STRATEGY.md Phase 1 names this directly: "real illustration
style tests — this app lives or dies on visual identity." This document frames the
exploration: foundational principles first, then a deliberately wide fan of
directions over the next couple of days, then a narrowing to one canonical view.
When a direction wins, the final section of this file becomes the style bible and
the decision is logged as D4 in DECISIONS.md.*

## 1. What the exploration must answer

The playtest question is *does the visual identity carry the narrative* — do the
scene pages feel like a world you re-enter, or text with pictures? We are not
choosing Chapter 1 art. We are choosing the visual voice of a 13-chapter course
that runs from an ogham stone in 480 AD to a Belfast gable wall today, tested on
Chapter 1 because that's the slice we have.

**Exit criterion:** one direction survives the funnel, looks right *inside the app*
in both light and dark mode, demonstrably stretches to at least two other eras, and
has a production recipe we believe at pipeline scale (Phase 2's proof is Chapter 2
produced through the pipeline).

## 2. Foundational principles (the trunk)

Every branch below must satisfy these. Kill a direction for violating a principle,
not for rough craft — craft improves with iteration; a wrong register doesn't.

1. **The art is the world, not decoration.** Scenes are the register where the
   learner lives in another century. Illustration exists to make the next page
   pulled-toward, not to break up text.
2. **One material language.** The app already speaks in physical stuff: the carved
   groove, chalk guide-marks, lichen wash, smoothed dust, stone against chalk.
   Whatever the illustrations are made of must feel drawn from that same world —
   an image that would look at home in any other app is disqualified by definition.
3. **A system, not a picture.** The style must hold across 13 chapters and 1,500
   years — stone yard, scriptorium, longphort, hedge school, famine ship, Belfast
   street. If it can only paint the Iron Age, it fails no matter how beautiful.
4. **Both modes are canonical.** Light and dark are equal citizens everywhere else
   in the app. The art either survives both or defines its own ground on the page.
5. **Warm, never kitsch.** No plastic shamrock, no Celtic-clipart knotwork
   wallpaper, no fantasy-Ireland mist (STRATEGY.md §4.5 — legitimacy is the moat).
   The bar: would someone *from Killala* hang it up?
6. **Repeatable at pipeline scale.** A style only one lucky prompt or one
   irreplaceable hand can produce is a dead end. Cost-per-scene matters
   (STRATEGY.md §4.1 — content cost is the business-model risk).
7. **Reference traditions, not working illustrators.** For generated exploration
   we draw on visual traditions and long-dead masters (insular manuscripts, Paul
   Henry, Robert Gibbings, Jack B. Yeats, the CIÉ poster school) — never the
   recognisable style of a living illustrator. Partly ethics, partly practical:
   Phase 2 may well *hire* the living ones, and this exploration doubles as their
   brief.

## 3. Where the art lives (the surfaces)

Inventory from the current slice (`ios/AnTuras/Resources/chapter1.json`):

| Surface | Count in Ch. 1 | Notes |
|---|---|---|
| Scene pages | 16 scene pages across 6 settings | The main canvas. Likely one hero image per **slugline** (setting change: the field above the Atlantic, the strand, the carver's yard ×2, dawn carving day, Breastagh today) — ~6–7 images, with later pages in the same setting inheriting atmosphere or getting small vignettes |
| Chapter cover | 1 | First impression; currently typographic |
| Grammar notes | 8 | Already have a look (lichen-washed manual pages). Probably spot diagrams/marginalia at most, or nothing — to be decided by seeing it |
| Artifact + share card | 1 | The learner's stone is a Canvas render; the style should inform, maybe not replace |
| Map / journey | 1 | Currently the ogham stemline — carved UI language. Open question whether it adopts the illustration style or stays UI |
| Feature pages (lens, listen, turn…) | ~8 | Currently typographic/diagrammatic; likely stay that way |

Coverage economy is itself an open question the exploration answers: a few images
placed where the story crests may beat art on every page. The registers already
carry visual identity; illustration should land like the spoken-Irish groove does —
as the hero moment, not wallpaper.

## 4. The axes (what actually varies)

Underneath any named style, three questions cut across all of them. Every test
image should be taggable on these axes so we learn about the axes, not just the
styles:

- **Figuration — how much person do we show?** Full faces (maximum warmth, hardest
  consistency, locks in "casting" of Dáire and Bríd) · bodies-not-faces (hands,
  backs, figures at distance — resonates with "the hand" theme: the learner already
  carves with their own finger) · unpeopled (pure place; the people live in the
  prose).
- **Colour economy.** Near-monochrome + one accent (stone + chalk white) · a
  period pigment palette (ochre, iron oxide, woad blue, lichen corcra — colours
  that were *available* in the era, shifting palette per chapter) · full colour.
- **Ground.** Vignettes whose edges dissolve into the page (the app killed the
  grey exercise card; a hard-framed rectangle may feel like putting cards back) ·
  full-bleed scenes the text sits within · framed plates.

## 5. The branches (the wide fan)

Six directions, each a hypothesis. All get tested in Day 1's wide pass; expect to
kill at least three fast.

### B1 · Gearrtha — the incised line
Images built the way the app is built: grooves, relief, chisel-width lines in
stone; monochrome plus chalk. The ogham groove extended until it can draw a
coastline, a face, a tide.
**Hypothesis:** the app's material language *is* the style — deepest possible unity.
**Risk:** sombre and monotone across 13 chapters; how does incision draw a
scriptorium candle-flame or a Belfast mural?

### B2 · Cailc is deannach — chalk and dust
Charcoal/chalk drawing on toned grounds — the medium Dáire himself teaches with
(he draws in smoothed dust before letting you carve). Loose, gestural, hand-warm.
Dark mode is native (chalk on slate); light mode is charcoal on limewash.
**Hypothesis:** "chalk before carve" scales from UI metaphor to full scenes; the
sketch quality reads as intimacy.
**Risk:** reads unfinished rather than intimate; low colour ceiling.

### B3 · Cló-ghearrtha — the printmaker's Ireland
Linocut/wood-engraving: bold carved line, flat ink, two or three colours per
chapter. Cutting an image out of a block is literally what Chapter 1 is about.
Tradition: Robert Gibbings' west-of-Ireland engravings, the Cuala Press.
**Hypothesis:** keeps the carved-line honesty *and* gains colour and era-range —
printmaking has depicted every century.
**Risk:** woodcut is the stock "historical app" look; must be ours, not pastiche.

### B4 · Solas an Atlantaigh — Atlantic light
Gouache/watercolour atmospherics: weather as the subject, big sky, grey-green sea,
figures as small dark shapes in a large landscape. Tradition: Paul Henry's west,
Jack B. Yeats' figures.
**Hypothesis:** emotional atmosphere is the narrative pull; the landscape *is* the
identity hook for diaspora and re-learners alike.
**Risk:** soft edges argue with the crisp carved UI; washes are the hardest style
to keep consistent through a pipeline, and the hardest to invert for dark mode.

### B5 · Scáthchruthach — flat graphic
Hard-edged flat shapes, limited palette, screen-print grain. Tradition: mid-century
Irish travel posters (CIÉ, Aer Lingus), modern editorial flat.
**Hypothesis:** the most reproducible, cheapest per scene, crispest in both modes,
stretches across eras trivially.
**Risk:** the very "could be any app" genericism we exist against. This branch is
the control group as much as a candidate.

### B6 · Lámhscríbhinn — the manuscript line
Calligraphic contour, flat mineral-pigment fills, insular drawing conventions
(profile figures, flat fields, inhabited initials) — the *drawing* language of the
manuscripts, explicitly not knotwork wallpaper.
**Hypothesis:** the one style literally native to Irish visual history; borrows
the prestige of Kells; sets up Chapter 2's scriptorium perfectly.
**Risk:** anachronistic for Chapter 1 (ogham predates the manuscripts by
centuries); the shortest slide of all six into kitsch.

## 6. The constants (fixed test brief)

Every branch renders the same subjects, so comparison is fair. All from the actual
chapter text:

- **T1 — the establishing shot.** Dáire kneeling at the long pillar, salt wind, a
  field above the grey Atlantic (S1 opening). Tests: landscape + figure + stone +
  mood in one image; this is the first image any player sees.
- **T2 — the human close-up.** Bríd running her thumb along the blank edge of the
  pillar where her father's name will go (S3). Tests: intimacy, hands, character,
  grief held quietly. The hardest test and the most important.
- **T3 — place without people.** The strand at low tide, oystercatchers over the
  flats, morning (S2). Tests: light, weather, whether the world breathes with
  nobody in frame.
- **T4 — fifteen centuries later.** The Breastagh ogham stone standing in a fenced
  Mayo field today, rain coming (S5 present-day beat). Tests: the same style
  holding the modern world — the era-stretch inside Chapter 1 itself.

**Survivors only (Day 2):**

- **T5 — the stretch pair.** One Chapter 2 image (scriptorium at dawn, Pangur Bán
  by candlelight) and one Chapter 12 image (an Irish-language mural on a Belfast
  gable). If the style can't hold both, it can't hold the course.
- **T6 — the continuity run.** Dáire in three different scenes, recognisably the
  same man. A style that can't keep a character is a style without a story.

Render at scene-page aspect (portrait, phone). Day 1 judges a contact sheet;
Day 2 judges **in the app**, on the simulator, light and dark, with a note page
and an exercise page adjacent — the question is never "is this a good image" but
"is this the same app."

## 7. The scorecard

Score each surviving image set 1–5. Weighted toward the things that can't be fixed
later.

| Criterion | What it asks |
|---|---|
| **Pull** | Does it make you want the next page? (The playtest metric, previewed) |
| **Belonging** | Does a scene page still read as sibling to the notes and exercises? |
| **Both modes** | Genuinely at home in light *and* dark, not merely legible |
| **Era-stretch** | T4/T5: does 2026 (and 800, and 1970) still look like the same course? |
| **Continuity** | T6: is Dáire Dáire? |
| **Repeatability** | Could we produce 7 of these per chapter, 13 chapters, on a budget? |
| **Register** | Warmth without kitsch — the Killala wall test |

Plus one veto question per reviewer, answered before seeing scores: *which of these
worlds do you want to go back into tomorrow?* That answer outranks the arithmetic.

## 8. The funnel (next couple of days)

**Day 1 — wide.** All six branches × T1 + T2 (the establishing shot and the
close-up — the two hardest constants). Multiple variants per branch are fine;
vary along the §4 axes deliberately (e.g. B3 with faces vs hands-only, B2
monochrome vs pigment accent). Judge on a contact sheet. **Cut to 2–3 branches.**
Kill on principles (§2), not on polish.

**Day 2 — deep.** Survivors render the full brief T1–T6, then the strongest images
go into the app behind a debug flag — real scene pages, simulator, light and dark,
swiped in sequence with notes and exercises. **Cut to 1** (or 1 + a named runner-up
if it's genuinely close).

**Then — canonical.** The winner gets written up in §10 of this file as the style
bible: palette, line quality, grounds, figuration rules, per-surface treatment
(scene hero art / note marginalia / cover / artifact / map), and the production
recipe (prompts + post-process, or the brief for a human illustrator — the honest
outcome may be "generation found the direction; a hired hand owns it in Phase 2").
Log as **D4** in DECISIONS.md. Then produce full Chapter 1 coverage per the §3
inventory, install, and the slice is playtest-ready on the visual front.

## 9. Mechanics

Mirrors the TTS bake-off pattern (`tools/tts-bakeoff/`):

- Files: `art/exploration/<branch>/<test>-<variant>.png` (e.g.
  `art/exploration/b3-print/t2-hands-2col.png`).
- A `CONTACT.md` per day in `art/exploration/` — the contact sheet with scores and
  kill decisions, so the reasoning survives the images.
- Generation settings/prompts recorded next to each image (`.txt` sidecar) —
  repeatability is a scored criterion, so the recipe is part of the artifact.
- In-app viewing via a debug arg (pattern exists: `--session N --reveal N`);
  simplest form is dropping candidates into the bundle behind a `--art <branch>`
  flag.

## 10. Canonical view

*Empty until the funnel closes. The winning direction's style bible lands here.*

## Open questions carried into the exploration

- **Faces or hands?** The single biggest fork. The prose currently does the faces;
  T2 exists to test whether images should too.
- **Coverage economy** — hero image per slugline vs per scene page; do notes get
  marginalia or stay pure (§3).
- **Does the UI chrome follow?** If B3/B4 wins, do the map, cover, and artifact
  stone adopt the style, or does the carved UI language stay a separate, deliberate
  layer? (Current instinct: UI stays carved; illustration is the *window*, UI is
  the *stone it's set in*. Test will tell.)
- **Motion later** — the winning style should not preclude subtle life (weather
  drift, candle flicker) added in Phase 3, always behind Reduce Motion.
- **Who makes Chapter 2+** — generation pipeline, human illustrator, or hybrid;
  cost per chapter becomes a Phase 2 budget line either way.
