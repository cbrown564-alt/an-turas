# Offaly source brief — Cross of the Scriptures, Flann Sinna, Clonmacnoise c. 900

*Historian-ready packet · started 12 July 2026 · status: **research draft, not
cleared**. Replaces the inherited Chapter 2 scriptorium composite (D13).*

## Phase 5 pre-clearance draft — 24 July 2026

`cross-of-the-scriptures.pack.draft.json` now applies the complete Mayo authoring
pattern and is bundled in the app as review-only content:

- six chapters and 68 stable pages, with variable chapter lengths;
- a 49.4-minute estimated Story path and a causally complete 67.2-minute Learning
  path projected from the same pages;
- 30 exercises across all 12 mechanic families;
- one introduction, heard use, active production and later reuse for each of the 20
  provisional headwords; and
- explicit evidence pages for the river-road site, settlement, Flann–Colmán
  patronage, panels, damaged inscription, and original/replica afterlife.

The draft passes `tools/validate_county_pack.py` with `scope: completeCounty` and
learning-quality enforcement enabled. `completeCounty` describes the authored data,
not its review state. The app labels the full pack **Review draft** and keeps county
gold, the made object and word scheduling locked until the historian, medieval
art/inscription, pedagogy, native-speaker audio and rights gates below close.

The six chapters are:

1. *River and road*
2. *A working settlement*
3. *King and abbot*
4. *The stone cross*
5. *Damaged letters*
6. *Original and replica*

The expanded draft uses the current [Heritage Ireland Clonmacnoise guide](https://heritageireland.ie/assets/uploads/2026/04/7565-OPW-Clonmacnoise-A5-visitor-guide_ENG_LR.pdf),
[site highlights](https://heritageireland.ie/visit/places-to-visit/clonmacnoise-monastic-site/highlights/),
and [High Crosses overview](https://heritageireland.ie/articles/high-crosses/) as
official starting sources. They support the tenth-century object, selected major
scenes, royal patronage, and the modern original/replica encounter. They do not close
the specialist dispute over the inscription expansion or approve the final panel
list.

## Phase 3 prototype binding — 14 July 2026

The earlier Phase 3 app contained a four-episode / twelve-beat editorial preview under
`offaly.cross-of-the-scriptures`. It proves the shared county-story format, evidence
inspection, recovery path, collection handoff, TEG can-do display and return
scheduling. It does **not** change this packet's research-draft status.

The prototype carries twenty provisional headwords: *abhainn, cloch, cros, rí,
mainistir, baile, obair, lá, anseo, anois, mór, beag, féach, seas, déan, foghlaim,
léigh, guí, bád,* and *bóthar*. A pedagogue must approve or replace the complete set,
pronunciation guides and lifecycle before release. The cross and inscription remain
rights-safe diagrams until the specialist reading and image route below are cleared.

## Identity

| Field | Value |
| --- | --- |
| County | Uíbh Fhailí / Offaly |
| Proposed story id | `offaly.cross-of-the-scriptures` |
| Named anchors | Flann Sinna (High King); Abbot Colmán; Cross of the Scriptures; Clonmacnoise |
| Organising centre | The cross inscription and sculpture c. 900 at Ireland's river–road crossroads |
| Significant encounter | Read/handle the inscription + selected panels; situate the settlement |
| Legacy bridge | `chapter2.json` interactions/progress migrate; editorial centre does not |
| Review state | Editorial research draft |

## Dramatic proposition

> A carved cross at the crossroads of Ireland asks for a prayer for a king. Who paid
> for it, who made it, and what kind of town had grown around it?

Ciarán's sixth-century foundation is opening context, not the dramatic present.

## Significant reading / object encounter

1. **Cross of the Scriptures** (original in visitor centre; replica on site) — figure
   panels + base/shaft inscription traditionally read as a prayer involving Colmán and
   King Flann.
2. **Settlement evidence** — high crosses, graveslabs, churches, Shannon/esker
   position; archaeology of craft, burial, and traffic.
3. **Annals mentions** of the cross / site (e.g. later AFM notices) as bounded
   context, not a second scavenger hunt.

## Claim ledger

| ID | Claim | Certainty | Support | Notes |
| --- | --- | --- | --- | --- |
| O01 | Clonmacnoise sits at a major Shannon / east–west route junction | story | Geography; Heritage Ireland; settlement studies | County claim is spatial |
| O02 | Founded in the sixth century in association with Ciarán | story/close | Hagiography + traditional foundation date | Label tradition vs archaeology carefully |
| O03 | By c. 900 it was a major ecclesiastical settlement with craft, burial, learning, and political ties | story | Archaeology; material culture; historical synthesis | Avoid inventing a named scribe's day |
| O04 | Cross of the Scriptures is an early-tenth-century scripture cross | story | Art-historical consensus | Exact year soft |
| O05 | Inscription links Abbot Colmán and King Flann (Flann Sinna) | story/close | Damaged inscription; conventional expansions vary | L1: prayer/patronage relationship; L2: letter-by-letter uncertainty |
| O06 | Flann Sinna (d. 916) was a powerful Uí Néill king associated with Clonmacnoise patronage | story | Annals; ODNB/synthesis | Keep political claim bounded |
| O07 | Sculpture includes crucifixion and other biblical / interpretive panels | story | Surviving carving | Panel IDs need art-historian check |
| O08 | Original moved indoors (1991); replica outdoors | story | OPW / site practice | Learner should know which object they “meet” |
| O09 | Invented gospel-book race / Pangur continuity as Chapter 2 headline | exclude | Editorial fiction | Release from flagship reality |
| O10 | Cross marks Flann's grave | close/exclude | Popular claim | Do not assert without board |

## Provisional 20-word field (pedagogue to lock)

Retain Chapter 2 language job where earned by settlement evidence: work, day, time,
colour, food, *tá*, liking, learning, river, stone, cross, king, pray, make, see,
stand, big, small, here, now — **exact list TBD** against weave rules; do not import
fictional-scriptorium-only words.

## Rights plan

| Asset | Action |
| --- | --- |
| OPW / Heritage Ireland site facts | Attribute; verify visitor-guide claims |
| Cross photographs | Clear OPW or commission drawing of panels + inscription zone |
| Inscription reading | Historian-approved conventional text with visible damage |
| Annals excerpts | Public-domain translations preferred; cite edition |

## Media evidence and rights audit — 10 August 2026

### Patronage without an invented meeting

- **Claims requiring evidence:** the Flann–Colmán relationship, the date and surviving
  cathedral fabric, and any material feature singled out. The evidence does not
  preserve a meeting, commission briefing, workforce, clothing, tools, scaffolding or
  construction sequence.
- The [OPW visitor guide](https://heritageireland.ie/assets/uploads/2026/04/7565-OPW-Clonmacnoise-A5-visitor-guide_ENG_LR.pdf)
  says the cathedral was built in 909 by Flann Sinna and Colmán and bounds the earliest
  surviving fabric mainly to the north wall: brown sandstone, deep antae and putlog
  holes. The [National Monuments Service record](https://www.archaeology.ie/collections-and-publications/multimedia-resources/monuments-from-the-air/clonmacnoise/)
  independently links the church to both men. Confidence: **high** for this bounded
  fabric claim; **none** for a staged encounter.
- **Rights:** commission the exact view through [OPW permission](https://heritageireland.ie/visit/venue-hire/filming-and-photography/),
  or check an individual file in the [Commons cathedral category](https://commons.wikimedia.org/wiki/Category:Clonmacnoise_Cathedral).
  The category is not a blanket licence.
- **Boundary:** replace the king–abbot meeting with authentic present-day north-wall
  fabric and live text. No people or 909 reconstruction. Brief ready; image rights open.

### Damaged inscription

- **Claims requiring evidence:** the exact face and zone, surviving strokes, damage,
  and the distinction between visible letters and conventional expansion. Never
  generate missing letters, a rubbing, or a clean inscription.
- The institutional [UCC Text and Image record](https://research.ucc.ie/doi/tandi/Clonmacnois19-N165.html)
  inventories the sandstone cross, records the plinth inscription, and names scholarly
  references and image credit. Confidence: **high** as an object record; a specialist
  must still approve the learner-facing reading.
- Crawford's 1926 [lower east-face plate](https://commons.wikimedia.org/wiki/File:Cross_of_the_Scriptures_detail_-_Crawford_plate_146.png)
  is public domain, but depicts a figure panel, not the inscription. It is cleared for
  panel context only.
- **Boundary:** use damage-aware live text with explicit gaps until a specialist picks
  the crop and its file-specific rights are cleared. Documentary promotion and visual
  generation remain blocked.

### Original and replica

- **Claims requiring evidence:** which object is the medieval original, which is the
  modern replica, and whether the view is indoor or outdoor.
- [Heritage Ireland highlights](https://heritageireland.ie/visit/places-to-visit/clonmacnoise-monastic-site/highlights/)
  confirms originals in the museum and replicas outside. Confidence: **high**.
- [*Clonmacnoise Cross of Scriptures replica Northwest face 01.png*](https://commons.wikimedia.org/wiki/File:Clonmacnoise_Cross_of_Scriptures_replica_Northwest_face_01.png)
  is explicitly a replica and CC0: ready for a correctly captioned replica view.
- A separately licensed indoor original is still needed. The [current site notice](https://heritageireland.ie/places-to-visit/clonmacnoise-monastic-site/)
  reports the visitor centre closed for essential works, so a new capture requires
  coordination.
- **Boundary:** replica-only may proceed. The comparison remains blocked until the
  original is cleared; never use the replica as documentary proof of the original's
  inscription surface.

## Board checklist

- [ ] Historian: lock inscription expansion for L1 vs L2
- [ ] Art historian / medievalist: panel reading list for learner encounter
- [ ] Pedagogue: 20-word weave from settlement, not scriptorium fiction
- [ ] Rights: cross imagery
- [ ] Product: illuminated-initial artifact retain/adapt decision
- [ ] Legacy: map Chapter 2 pages retain/adapt/retire

## Reading list

1. Heritage Ireland Clonmacnoise guide + high-cross articles
2. Scholarly inscription editions (Petrie / later revisions — board to name preferred)
3. Settlement / excavation summaries for Clonmacnoise
4. Flann Sinna biographical synthesis (annals-led)
5. Legacy `content/chapter2/` for salvage only
