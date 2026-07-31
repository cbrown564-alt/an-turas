# An Turas: Four-County Media & Imagery Audit

*Comprehensive audit of required audio, primary source evidence, and visual assets across all four initial launch-county story packs (Mayo, Dublin, Meath, Offaly).*

---

## Executive Summary & Media Classification Strategy

To deliver an evidence-grounded experience for learning Irish, *An Turas* enforces strict standards for visual media, video motion, and audio:
1. **Real Photographic & Documentary Evidence (Placeholders required)**: High-resolution scans of manuscripts, archival folios, physical coinage, high-cross panel rubbings, and architectural survey plans must **never** be AI generated. They represent authentic historical proof and must be populated with verified open-access / museum photographic placeholders until final rights are cleared.
2. **Tasteful, Meaningful AI Generated Imagery**: Visual narrative backgrounds, atmospheric landscapes, historical coastal environments, river crossings, and spatial scene-setters **should be AI generated**. These images capture atmosphere, geography, and scale without inventing fake historical details, adding decorative pseudo-Celtic motifs, or embedding text overlays.
3. **Cinematic Video & Ambient Motion (Gemini Omni via Google Flow)**: Video assets are used selectively for ambient environmental loops (3–6s) and spatial transitions. Generated with Gemini Omni and Google Flow, video brings living weather, tide shifts, mist, and macro lighting sweeps to life, cementing the connection between language and place without introducing fake historical reenactments.
4. **Studio & Pronunciation Audio**: Headwords and exercises require native Connacht speaker recordings.

---

## 1. Mayo (`mayo.grainne-1593`)
**Theme**: Gráinne Ní Mháille: Clew Bay, London, and return (9 Chapters, 100 Pages, 38 Exercises)

### A. Real Photographic & Documentary Evidence (Placeholders Required)
* **`evidence.sp63-170`**: TNA SP 63/170 Folio 201 (1593 Interrogatory & Gráinne's answers) — *Currently bundled (`SP63170F201`)*.
* **`source.sidney-memoir`**: Carew MS 601 / TNA SP 12/159 Folio 27d (Sir Henry Sidney's 1576/1583 memoir on meeting Gráinne).
* **`source.royal-draft`**: Queen Elizabeth I to Sir Richard Bingham draft letter (6 September 1593).
* **`evidence.rockfleet-elevation`**: Architectural measurement and stone survey plan of Rockfleet Castle (Carrigahowley).

### B. Tasteful AI Generated Imagery (Batch Generation Plan)
| Image ID / Filename | Description / Scene | Target Location / Usage |
| :--- | :--- | :--- |
| `mayo-clew-bay-coastal` | Wide panoramic vista of Clew Bay, autumn tide, drumlin islands, muted coastal lighting. | Ch 1: Clew Bay opening |
| `mayo-umhaill-territory` | 16th-century Mayo coastline, Umhaill chieftaincy landscape, sea meeting salt marsh. | Ch 1: Polity & sea reach |
| `mayo-galway-bay-trading` | Galleoglass/galley ships anchored in Galway Bay near stone quay, 16th-century maritime trade. | Ch 2: Trading & Galley fleet |
| `mayo-rockfleet-tide` | Rockfleet Castle tower house at high tide on the shoreline edge, stormy Atlantic skies. | Ch 3: Rockfleet stronghold |
| `mayo-tudor-pressure` | Tudor administrative outpost, stone precinct with military patrols, coastal Connacht. | Ch 4: Governor Bingham's pressure |
| `mayo-connacht-inland` | Inland Mayo bogs and oak scrubland under grey sky, kin retreat path. | Ch 5: Dislocation & loss |
| `mayo-sea-voyage-london` | 16th-century Irish galley navigating open choppy seas towards the English Channel. | Ch 6: Voyage to London |
| `mayo-greenwich-palace-outer` | Exterior courtyard of Greenwich Palace, Thames riverfront, 1590s Tudor stone architecture. | Ch 7: Greenwich petition |
| `mayo-royal-court-interior` | Muted Tudor presence chamber interior, tall stone windows, velvet and oak, formal audience atmosphere. | Ch 7: Petition presentation |
| `mayo-return-clew-bay` | Return journey by sea to Mayo, dramatic sunlight breaking through heavy clouds over Clew Bay. | Ch 8 & 9: Unfinished return |

### C. Gemini Omni / Google Flow Video Loops
| Video ID / Filename | Prompt & Motion Spec | Target Location / Usage |
| :--- | :--- | :--- |
| `video.mayo-clew-bay-tide-loop` | *Slow panoramic 4s loop*: Atlantic tide gently shifting across Clew Bay drumlins under low autumn sun, water ripple motion, mist lingering over shoreline. | Ch 1 Header / Arrival |
| `video.mayo-rockfleet-sea-surge` | *Cinematic 5s loop*: Heavy swell crashing softly against the stone base of Rockfleet Castle tower house, low grey storm clouds drifting right-to-left. | Ch 3 Stronghold Hero |
| `video.mayo-galley-sea-passage` | *Ambient 4s loop*: Wooden galley hull carving through dark swell in open Atlantic, spray rising, horizon staying steady. | Ch 6 Voyage Bridge |

### D. Audio Requirements
* **20 Headwords**: *farraige, bá, long, áit, as, caisleán, teaghlach, mac, bean, caill, deartháir, iarr, téigh, ainm, mise, tar, freagair, tabhair, arís, cósta* (draft pack; MEDIA-AUDIT stale variants superseded).
* **Phrase & conversation audio**: frozen in `content/audio/launch-phrases-conversations-v1.json` and generated into the bundled catalog (2026-07-31).

---

## 2. Dublin (`dublin.sihtric-penny`)
**Theme**: Sihtric's penny: a king and Dublin on silver (6 Chapters, 68 Pages, 30 Exercises)

### A. Real Photographic & Documentary Evidence (Placeholders Required)
* **`evidence.dublin-sihtric-penny-obverse`**: High-resolution macro photo scan of Sihtric Silkbeard penny obverse (King's profile & `SIHTRC REX DIFLI`).
* **`evidence.dublin-sihtric-penny-reverse`**: High-resolution macro photo scan of Sihtric Silkbeard penny reverse (Long cross & moneyer `FAENEMI MO DIFLI`).
* **`evidence.dublin-hiberno-norse-mint`**: Archaeological drawing/rubbing of coin die and Viking minting hammer found in Dublin excavations.
* **`source.dublin-annals-four-masters`**: Manuscript folio excerpt mentioning Dublin Viking trade and coinage (10th/11th century).

### B. Tasteful AI Generated Imagery (Batch Generation Plan)
| Image ID / Filename | Description / Scene | Target Location / Usage |
| :--- | :--- | :--- |
| `dublin-liffey-estuary` | 10th-century Liffey estuary confluence (*Dubhlinn* / Poddle), wooden Viking longships, muddy banks. | Ch 1: Dark Pool opening |
| `dublin-wood-quay-settlement` | Wattle-and-daub Viking town, earthwork defenses, smoke rising from timber hearths along river. | Ch 2: Wood Quay trade town |
| `dublin-viking-market` | Busy 11th-century Dublin market shore, merchants exchanging silver bullion, scales, imported cloth. | Ch 3: Market & silver economy |
| `dublin-minting-workshop` | Viking artisan anvil, glowing charcoal forge, silver ingots, hammer and coin die in low-lit workshop. | Ch 4: Royal minting process |
| `dublin-coin-distribution` | Merchant hands holding a freshly struck silver penny, trade route background (Irish Sea coast). | Ch 5: Circulation across Ireland |
| `dublin-modern-archaeology` | Modern Dublin riverfront excavation layer, dark peaty soil revealing timber foundations and artifacts. | Ch 6: Modern discovery & memory |

### C. Gemini Omni / Google Flow Video Loops
| Video ID / Filename | Prompt & Motion Spec | Target Location / Usage |
| :--- | :--- | :--- |
| `video.dublin-dark-pool-mist` | *Ambient 4s loop*: Dawn mist rising off the dark sluggish confluence of the Liffey and Poddle, reed sway, silent timber longship moored on mudbank. | Ch 1 Arrival |
| `video.dublin-coin-relief-light` | *Macro lighting sweep 5s*: Directional light grazing across the relief of the Sihtric Silkbeard silver penny, catching silver patina sheen and inscription grooves. | Ch 4 & 5 Evidence Canvas |

### D. Audio Requirements
* **20 Headwords**: draft pack lemmas (see `content/audio/atlas-headwords-v1.json` dublin).
* **Phrase & conversation audio**: frozen and generated 2026-07-31 into the bundled catalog.

---

## 3. Meath (`meath.trim-de-lacy`)
**Theme**: Trim: an old land, a grant and a castle at the ford (6 Chapters, 68 Pages, 30 Exercises)

### A. Real Photographic & Documentary Evidence (Placeholders Required)
* **`evidence.meath-delacy-grant-charter`**: Photo scan of King Henry II's 1172 charter granting Meath (*Mide*) to Hugh de Lacy.
* **`evidence.meath-trim-castle-plan`**: Archaeological survey plan showing the three construction phases of Trim Keep (1172 ringwork, 1174 wooden tower, 1200s stone keep).
* **`source.song-of-dermot`**: 12th-century Anglo-Norman manuscript excerpt (*Chanson de Dermot et du Roi Richard*) detailing the siege of Trim.

### B. Tasteful AI Generated Imagery (Batch Generation Plan)
| Image ID / Filename | Description / Scene | Target Location / Usage |
| :--- | :--- | :--- |
| `meath-boyne-ford` | River Boyne shallow ford at Trim before Norman arrival, fertile green meadows, ancient oak trees, misty morning. | Ch 1: The ancient Boyne ford |
| `meath-gaelic-settlement` | Early medieval Gaelic settlement (*talamh*), rath earthworks, cattle pasture, river bend. | Ch 2: Gaelic Meath landscape |
| `meath-norman-grant-arrival` | Anglo-Norman knights and surveyors on horseback overlooking the Boyne valley with wooden palisade stakes. | Ch 3: De Lacy grant & arrival |
| `meath-ringwork-fortress` | Early earth-and-timber ringwork fortification at Trim, motte timber palisade overlooking river crossing. | Ch 4: First timber fortification |
| `meath-stone-keep-rising` | Scaffolding around the towering stone curtain walls and curtain gatehouse of Trim Castle under construction. | Ch 5: Great stone keep construction |
| `meath-trim-castle-landscape` | Majestic Trim Castle curtain wall standing beside the flowing River Boyne in evening golden hour. | Ch 6: Landscape legacy & stone |

### C. Gemini Omni / Google Flow Video Loops
| Video ID / Filename | Prompt & Motion Spec | Target Location / Usage |
| :--- | :--- | :--- |
| `video.meath-boyne-flow-loop` | *Subtle 5s loop*: Water rippling gently over limestone pebbles at the Boyne river ford at Trim, morning mist dispersing in background meadows. | Ch 1 Arrival |
| `video.meath-trim-curtain-sunset` | *Cinematic 6s loop*: Golden sunset light slowly fading across the curtain walls of Trim Castle, river reflections shifting below. | Ch 6 Legacy Header |

### D. Audio Requirements
* **20 Headwords**: draft pack lemmas (see `content/audio/atlas-headwords-v1.json` meath).
* **Phrase & conversation audio**: frozen and generated 2026-07-31 into the bundled catalog.

---

## 4. Offaly (`offaly.cross-of-the-scriptures`)
**Theme**: The Cross of the Scriptures: river, king and carved prayer (6 Chapters, 68 Pages, 30 Exercises)

### A. Real Photographic & Documentary Evidence (Placeholders Required)
* **`evidence.offaly-cross-inscription-rubbing`**: High-contrast archaeological rubbing/photo of the damaged Gaelic inscription on the West face (*RÍ ÉIREANN / FLANN*).
* **`evidence.offaly-cross-panel-carvings`**: Photogrammetry/high-resolution scans of the sandstone carved panels (ecclesiastical & royal scenes).
* **`source.clonmacnoise-annals`**: Manuscript folio from the *Annals of Clonmacnoise* recording Abbot Colmán and King Flann Sinna (c. 909 AD).

### B. Tasteful AI Generated Imagery (Batch Generation Plan)
| Image ID / Filename | Description / Scene | Target Location / Usage |
| :--- | :--- | :--- |
| `offaly-shannon-callows` | River Shannon callows at Clonmacnoise, wide winding river, reeds, monastic round tower in soft morning mist. | Ch 1: Shannon river & monastic site |
| `offaly-clonmacnoise-monastery` | 10th-century monastic city, stone churches, thatched workshops, wooden jetties along the Shannon banks. | Ch 2: Monastic working settlement |
| `offaly-king-abbot-meeting` | 10th-century King Flann Sinna and Abbot Colmán standing near a sandstone quarry block, soft sunlight. | Ch 3: King & Abbot patronage |
| `offaly-carving-high-cross` | Master stone mason carving intricate biblical panels into a massive sandstone high cross with iron chisel. | Ch 4: Carving the stone cross |
| `offaly-cross-scriptures-sunset` | Sandstone High Cross standing outdoors at Clonmacnoise against a dramatic Irish sunset over the river. | Ch 5: Carved prayer & inscription |
| `offaly-clonmacnoise-visitor-center` | Modern indoor gallery exhibit displaying the original Cross of the Scriptures under protective lighting. | Ch 6: Original & replica preservation |

### C. Gemini Omni / Google Flow Video Loops
| Video ID / Filename | Prompt & Motion Spec | Target Location / Usage |
| :--- | :--- | :--- |
| `video.offaly-shannon-callows-mist` | *Ambient 5s loop*: Slow motion river breeze pushing tall reeds along the Shannon callows at Clonmacnoise, monastic round tower silhouetted in soft sunrise light. | Ch 1 Arrival |
| `video.offaly-cross-carving-relief` | *Macro lighting sweep 4s*: Warm low-angle sunlight panning across carved sandstone biblical relief panels, emphasizing depth of iron chisel work. | Ch 4 & 5 Evidence Header |

### D. Audio Requirements
* **20 Headwords**: draft pack lemmas (see `content/audio/atlas-headwords-v1.json` offaly).
* **Phrase & conversation audio**: frozen and generated 2026-07-31 into the bundled catalog.

---

## 5. Gemini Omni & Google Flow Video Integration Framework

**Policy owner:** D28. Operational detail lives here; do not invent a second density rule.

### A. What Video Adds to the Experience
1. **Living Atmosphere & Temporal Depth**: Static imagery establishes place, but ambient video loops capture the living pulse of Ireland's landscape—Atlantic tides at Clew Bay, river current on the Boyne, mist over the Shannon callows—strengthening the core principle that **language and place are inseparable**.
2. **Dynamic Evidence Illumination**: Rather than altering historical artifacts, video macro lighting sweeps across *generated interpretive relief* (or licensed 3D) to direct attention. Real archival scans stay still documentary evidence.
3. **Narrative Momentum in Transitions** *(deferred)*: Brief muted bridges between chapter arcs need a separate placement contract before Flow spend.
4. **Phonetic Articulation Guidance** *(deferred)*: Lip/mouth micro-videos need native-speaker audio sync and a Learning-shell home before generation.

### B. Natural Integration Points (active)
* **Chapter arrival heroes only (D28):** one 3–6s muted loop *or* atmospheric still on each chapter's first page / arrival beat.
* Still→motion: generate or select the still first; animate in Flow; ship the still as `fallbackResourceID`.

### C. Product Boundaries & Constraints
* **NO Invented Historical Reenactment**: Video must **never** feature AI actors performing fictionalized historical scenes (e.g. no fake video of Gráinne Ní Mháille meeting Elizabeth I). History remains anchored in authentic documentary evidence.
* **NO Burnt-In Copy**: All video assets must be purely visual. Text overlays, titles, and exercise controls remain live, accessible SwiftUI text layers.
* **Accessibility & Motion Compliance**: If `UIAccessibility.isReduceMotionEnabled` is active, video loops freeze to a static frame or fade smoothly without motion.
* **Battery & Performance Efficiency**: Loops are capped at 24 FPS, muted, H.264/H.265 encoded under **2MB per loop** after final encode, and strictly paused when off-screen. Current shipped MP4s exceed this and need a recompress pass before large-scale bundling.

### D. Wiring status (2026-07-30)

| County | Chapters | Opening hero now | Motion present | Still-only interim | Still missing → queue |
|---|---|---|---|---|---|
| Mayo (draft rev 7) | 9 | 8/9 (+ SP 63/170 documentary on Ch7) | Clew Bay, Rockfleet, galley/London road | Power at sea, Bingham, royal answer, return coast | Kin/alliances still; dedicated return loop |
| Mayo Rockfleet (bundled) | 1 | Rockfleet video | yes | — | — |
| Dublin | 6 | 6/6 | Dark pool, coin relief | Wood Quay, market, mint workshop, archaeology | Animate the four stills |
| Meath | 6 | 3/6 | Boyne flow, Trim sunset | Boyne ford (Ch1) | Grant, first fortification, town afterlife |
| Offaly | 6 | 2/6 | Shannon mist, cross relief | — | Settlement, king–abbot, inscription, original/replica |

### E. Flow / Gemini Omni generation queue (spend order)

Animate existing stills before inventing new scenes. Prompts stay text-free, muted, loopable, no people in invented historical action unless already accepted as distant atmospheric figures in the still.

**Batch A — animate wired stills (highest leverage)**

| Target video id | Source still | Chapter opening | Motion brief |
|---|---|---|---|
| `video.mayo-galway-bay-trading` | `mayo-galway-bay-trading` | Mayo Ch4 power-at-sea | Slow harbour water + light cloud drift, 4–5s loop |
| `video.mayo-tudor-pressure` | `mayo-tudor-pressure` | Mayo Ch5 Bingham | Low cloud scrape over coastal stone precinct, 5s |
| `video.mayo-royal-court-interior` | `mayo-royal-court-interior` | Mayo Ch8 royal answer | Soft window-light shift on stone/oak interior, 4s, empty of staged audience action |
| `video.mayo-clew-bay-return` | `mayo-clew-bay-coastal` (interim) then dedicated return still | Mayo Ch9 return | Distinct return light vs Ch1 tide loop—clearer horizon, calmer swell |
| `video.dublin-wood-quay-settlement` | `dublin-wood-quay-settlement` | Dublin Ch2 | Hearth smoke / reed sway at river edge, 4s |
| `video.dublin-viking-market` | `dublin-viking-market` | Dublin Ch3 | Soft crowd-distance blur only if already in still; prefer cloth/water micro-motion, 4s |
| `video.dublin-minting-workshop` | `dublin-minting-workshop` | Dublin Ch5 | Charcoal glow + slow light on die/anvil, no hammer strike theatrics, 4s |
| `video.dublin-modern-archaeology` | `dublin-modern-archaeology` | Dublin Ch6 | Mist/dust mote drift over excavation soil, 4s |
| `video.meath-boyne-ford` | `meath-boyne-ford` | Meath Ch1 | Morning mist lift over ford meadows, complementary to existing Boyne pebble loop |

**Batch B — missing stills, then motion**

| Still id | Chapter | Notes |
|---|---|---|
| `mayo-kin-alliances` (new) | Mayo Ch2 | Household/kin coast without costume drama; no invented faces as likeness |
| `mayo-return-clew-bay` | Mayo Ch9 | Dedicated return coast; replace interim coastal still |
| `meath-grant-claim` | Meath Ch2 | Document atmosphere only—not a fake charter facsimile |
| `meath-ringwork-fortress` | Meath Ch4 | Timber/earth ringwork at Trim ford |
| `meath-trim-town-afterlife` | Meath Ch6 | Living town beside curtain walls |
| `offaly-clonmacnoise-monastery` | Offaly Ch2 | Working settlement, Shannon bank |
| `offaly-king-abbot-meeting` | Offaly Ch3 | Distant figures only; no portrait claims |
| `offaly-inscription-attention` | Offaly Ch5 | Stone letters / damaged face as atmosphere, not fake rubbing |
| `offaly-original-and-replica` | Offaly Ch6 | Indoor gallery light vs outdoor replica—keep non-documentary |

**Batch C — deferred:** chapter-transition bridges; phoneme articulation clips; recompress all shipped loops to ≤2 MB.

### F. Encode recipe (before next large drop)
1. Export Flow loop muted, no titles.
2. Extract mid-loop still as keyframe JPEG matching composition.
3. Transcode ≤24 fps, 720–1080p edge-to-edge, H.264 or H.265, target ≤2 MB.
4. Register `video.*` + `image.*` fallback; set page `visualResourceID`; caption as generated interpretation.
5. Validate pack; Reduce Motion must show the keyframe.

---

## Summary of Media Production Targets

* **Density (D28):** one hero visual per chapter opening across launch counties (~27 openings), motion preferred after still lock.
* **Shipped Flow loops today:** **9** (Mayo 3, Dublin 2, Meath 2, Offaly 2); Mayo's Rockfleet + galley loops now page-wired.
* **AI atmospheric stills:** Dublin slate largely present; Mayo partial; Meath/Offaly gaps listed in Batch B.
* **Documentary evidence scans:** **14** authentic museum/archival photographic placeholders (TNA, Carew, Sihtric coins, De Lacy grant, High Cross panels)—not Flow targets.
* **Audio clips:** Irish teaching inventory frozen and generated 2026-07-31 —
  **289** unique strings in [`../content/audio/irish-inventory-v1.json`](../content/audio/irish-inventory-v1.json)
  (191 headwords for all 32 counties, 48 launch phrases, 50 launch conversation
  lines); **359** MP3s bundled including legacy chapter clips. Launch draft and
  CountyStories packs now mark those resources `bundled` and bind conversation
  `audioText` to inventory lines. Bind rule: launch `audioText` must come from the
  inventory (`audioNotInInventory` in the county validator). Native-speaker QA still
  open (D17). English narrative VO not generated in this pass.

