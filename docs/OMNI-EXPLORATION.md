# Omni video exploration — what a 10-second clip is for

*Started 2026-08-05. Mirrors the funnel pattern of `ILLUSTRATIONS.md` §9 and
`tools/tts-bakeoff/`: a deliberately wide day-one pass, prompt sidecars next to every
output, a contact sheet that records the reasoning, and a narrowing to the uses that
earn a place. Read with `PRODUCT.md`, `DESIGN.md`, `GRAINNE-ART-DIRECTION.md`, and
`STRATEGY.md`.*

Gemini Omni Flash generates ten videos per day at no cost. This document decides what
that capacity is *for* — and, more importantly, which of our open questions it can
close for free.

## 1. What the model is

| Property | Value | Consequence for us |
| --- | --- | --- |
| Clip length | ~10 seconds | The unit of work is a proverb, an etymology, a mutation, an ambient loop — not a scene |
| Aspect | 16:9 or 9:16 only | 9:16 is the social/Féilire channel we do not currently have; 3:4 scene-page aspect is unavailable |
| Audio | Native, synchronised, in the same pass | Lip-synced dialogue without a separate TTS step |
| Tasks | `text_to_video`, `image_to_video`, `reference_to_video`, `edit` | `image_to_video` runs on our existing gouache stills |
| Editing | Multi-turn via `previous_interaction_id` | Tonal consistency across a multi-clip reel |
| Known strengths | Text-synced-to-action, character consistency from references, real-world physics | Maps onto mutations, Gráinne continuity, and the Atlantic crossing respectively |
| Unsupported | System instructions, temperature, negative prompts, voice/dialogue editing | Fold exclusions into the prompt body; a bad take is regenerated, not corrected |

### Constraints that bite this project

- **"English is fully supported, but other languages have not been evaluated."** Irish
  dialogue is unproven. This is the reason V1 exists and why it takes two of the ten.
- **Editing uploaded video is unavailable in the EEA, Switzerland, and the UK.** Model-
  generated edits are permitted. Plan around `image_to_video` and `reference_to_video`;
  do not build a workflow on uploading footage.
- **Video references are limited to ~3 seconds**, cannot be multi-video, and the model
  cannot extend or interpolate. There is no path from ten seconds to twenty.
- **SynthID watermarks every output.** This is an asset, not a cost. Design Principle 2
  requires that reconstruction never be mistaken for evidence; generated video here is
  permanently and provably marked as generated, and the evidence sheet should say so.

## 2. Rules this exploration does not get to break

1. **Text-free assets** (Design Principle 7). Generated art carries no names, captions,
   labels, or interface copy; the app owns that content. V2 and V3 deliberately
   generate onscreen type and are therefore **exploration and marketing artifacts, not
   in-app assets**. If kinetic mutation teaching ever ships, the type must be live,
   accessible app text composed over generated video — never burned in.
2. **Interpretation, not likeness** (`GRAINNE-ART-DIRECTION.md`). Gráinne is authored
   interpretive portraiture with no claim of likeness, and the disclosure lives in the
   accessibility description and opened evidence context — never stamped on the frame.
3. **No generated documents as archival objects.** SP 63/170 and every other surviving
   record must be a licensed facsimile when a learner is asked to inspect its wording,
   however good the model's text rendering becomes.
4. **No costume drama.** No romantic pirate-queen poses, fantasy armour, green gowns on
   cliffs, Tudor pageant, shamrocks, Celtic knotwork, flags, or tourist emerald.
   V10 exists to generate exactly this, once, on purpose.
5. **Contested history is out of scope until U7 closes.** Famine, plantation, partition,
   and the Troubles are not prompt material until the contested-history editorial
   principles exist. The model has no judgement about what it depicts, and
   `STRATEGY.md` §3 says we need those principles *before* we need them.
6. **Capture does not imply approval.** As with the audio harvest: a generated clip is
   inventory, not a release-eligible asset. Every output starts `generated_unreviewed`.

## 3. The day-one slate

Ten clips. Two spent on the question worth most.

| # | Slug | Task | Aspect | Closes / tests |
| --- | --- | --- | --- | --- |
| V1a | `v01a-irish-dialogue-tatuarais` | `text_to_video` | 9:16 | Can Omni speak Irish at all? |
| V1b | `v01b-irish-dialogue-seimhiu` | `text_to_video` | 9:16 | Irish phonology under mutation and fada |
| V2 | `v02-seimhiu-kinetic` | `text_to_video` | 9:16 | Mutation teaching via text-synced-to-action |
| V3 | `v03-placename-bealfeirste` | `text_to_video` | 9:16 | The Logainm engine |
| V4 | `v04-gouache-motion` | `image_to_video` | 16:9 | `ILLUSTRATIONS.md` §Open: "motion later" |
| V5a | `v05a-grainne-limestone` | `reference_to_video` | 16:9 | T6 continuity, Ep 1 register |
| V5b | `v05b-grainne-atlantic` | `reference_to_video` | 16:9 | T6 continuity, Ep 5 register |
| V6 | `v06-the-crossing` | `text_to_video` | 16:9 | Physics as historical argument |
| V9 | `v09-pangur-ban` | `text_to_video` | 16:9 | Era-stretch (T5) + a real marketing asset |
| V10 | `v10-anti-reference` | `text_to_video` | 9:16 | Makes the anti-reference enforceable |

V7 (grant reel) and V8 (seanfhocal series) are deliberately held for day two — both are
production runs that should only start once V1–V6 have told us what the model is
actually good at here.

### V1 — Can it speak Irish?

The highest-value clip on the list. `docs/TTS-research.md` records that no iOS Irish
voice exists; D17 locked an all-generated ElevenLabs voice with native-speaker QA per
release. A video model with native synchronised Irish dialogue would be a category
nobody in this space occupies. If it fails, it fails informatively — capture the failure
mode (does it anglicise the orthography? does it flatten the fada? does it read the
séimhiú as a consonant cluster?) and file the finding beside the bake-off.

**V1a** uses *tá tú ar ais* — the greeting D5 validated as an actual retention hook.
**V1b** goes straight at the hard case: broad/slender contrast, a séimhiú, and a fada
in one short line.

Judge: intelligibility to an Irish speaker, lip-sync accuracy, and whether the vowel
quality is Irish or English-with-Irish-spelling. Do not judge dialect authenticity from
one take; that is a reviewer's call, not ours.

### V2 — Séimhiú as physics

`STRATEGY.md` §4.2 names initial mutations as one of the three things that make Irish
genuinely hard for anglophones, and our stated promise is that we *explain* the hard
parts beautifully where others drill or ignore them. Text-synced-to-action is Omni's
documented showcase capability. This is the one place where the model's signature
strength and our core product claim are the same thing.

Burned-in type disqualifies this as an app asset (§2.1). It is a pedagogy probe and a
marketing artifact. What it proves is whether the *idea* reads in ten seconds.

### V3 — Your townland means something

`STRATEGY.md` §5 calls placenames "the single best culture↔language bridge (every
learner's town name *means something* in Irish)." The Personal Atlas foundation holds
126,712 place records, 100,738 with Irish forms. Ten free clips a day against a hundred
thousand etymologies is a content engine with a multi-century backlog.

*Béal Feirste* — mouth of the sandbank ford — is the right first test because it is the
NI cultural north star (D1), it is genuinely surprising to an English speaker who has
said "Belfast" their whole life, and the referent is a real physical feature the camera
can actually fly over.

### V4 — Living illustration

`ILLUSTRATIONS.md` closes with an open question: *"the winning style should not preclude
subtle life (weather drift, candle flicker) added in Phase 3, always behind Reduce
Motion."* This answers it for free. Feed an existing Solas an Atlantaigh still as
`image_to_video` and ask for weather drift and nothing else.

The question is not whether it is a good video. It is whether granulating pigment, wet
paper texture, and dry-brush edges survive motion or turn to plastic. If they survive,
scene pages gain ambient life behind Reduce Motion. If not, we have killed an expensive
Phase 3 assumption in ten seconds.

### V5 — Is Gráinne Gráinne?

`ILLUSTRATIONS.md` §6 defines T6: *"Dáire in three different scenes, recognisably the
same man. A style that can't keep a character is a style without a story."* Run it in
motion, with our approved interpretive portraiture as reference, across two ends of the
locked palette progression: limestone/moss (Ep 1) and Atlantic blue-black (Ep 5).

Character consistency from references is Omni's headline claim. This tests it against
our actual art direction rather than a generic face.

### V6 — The crossing

Episode 4. Omni's documented strengths include intuitive physics — gravity, kinetic
energy, fluid dynamics. A still cannot make the *difficulty* of the 1593 Atlantic
crossing legible, and that difficulty is the dramatic argument of the episode. No
figures, no vessel heroics, no costume. Ten seconds of genuinely hostile water.

### V9 — Pangur Bán

The ninth-century scriptorium and the white cat. It is real, documented, the most
charming object in the Irish literary record, and it doubles as the T5 era-stretch test
from `ILLUSTRATIONS.md` §6. It is also the clip most likely to travel on its own.

### V10 — Generate the anti-reference

`PRODUCT.md` lists "plastic shamrock Irishness" as anti-reference #2, and
`ILLUSTRATIONS.md` §2.5 sets the bar as *"would someone from Killala hang it up?"* Right
now those are words in a document. One clip of the exact thing we are against, placed
beside V5 in the editorial board pack, makes the standard enforceable by people who were
not in the room when it was written.

File it clearly as a calibration artifact. It must never enter the asset pipeline.

## 4. Scorecard

Score each clip 1–5. The criteria are inherited from `ILLUSTRATIONS.md` §7 with three
added for motion and audio.

| Criterion | What it asks |
| --- | --- |
| **Pull** | Does it make you want the next thing? |
| **Belonging** | Would this sit beside a scene page without breaking the register? |
| **Register** | Warmth without kitsch — the Killala wall test |
| **Continuity** | Is the character/place the same one across takes? |
| **Repeatability** | Could we produce this reliably, ten a day, for months? |
| **Irish** | Is the Irish intelligible and plausibly native? (audio clips only) |
| **Motion honesty** | Does movement clarify something a still could not, or is it decoration? |
| **Material survival** | Do the gouache/paper qualities hold under motion? (V4 only) |

Plus the veto question, asked before the arithmetic: *does this make Irish feel more
worth learning, or does it make us look like every other app with a video budget?*

## 5. Mechanics

- Outputs: `art/video/<slug>.mp4`, prompt sidecar `art/video/<slug>.txt`.
- The sidecar in `art/video/` is canonical for **what was actually sent** and records
  task, aspect, references, take number, and any multi-turn interaction id. The prompts
  in §6 below are the day-one starting point; expect drift as takes iterate, and let the
  sidecar carry the truth.
- `art/video/CONTACT.md` is the contact sheet: scores, findings, kill decisions — so the
  reasoning survives the clips, exactly as `art/exploration/CONTACT.md` does.
- Every clip starts `generated_unreviewed`. Nothing here is a release-eligible asset.

## 6. Day-one prompts

Negative prompts are unsupported, so exclusions are written into the prompt body. Each
of these is duplicated into its sidecar at `art/video/<slug>.txt`.

### V1a · `v01a-irish-dialogue-tatuarais` — 9:16, text_to_video

```
A woman in her sixties, close on her face, sitting by a window in a plain
whitewashed room on the west coast of Ireland. Soft grey daylight. She looks
directly at the camera, warm and unhurried, and says in the Irish language,
in a Connacht accent: "Tá tú ar ais."

She pauses, and smiles slightly.

The audio is her voice only — no music, no background score, no narration.
Her mouth movements match the Irish sounds precisely. Documentary framing,
shallow depth of field, no camera movement. Plain room, no decoration.
```

### V1b · `v01b-irish-dialogue-seimhiu` — 9:16, text_to_video

```
The same woman, same room, same soft grey daylight, same framing. She is
teaching. She speaks slowly and clearly in the Irish language, in a Connacht
accent, leaving a beat between each phrase:

"Bean. An bhean. Mo bhean."

Then she says: "Sláinte mhaith."

Her lips and tongue form the Irish sounds precisely — the softened bh, the
long á. The audio is her voice only, no music, no narration, no translation.
Static camera, documentary framing.
```

*Judging note: the point of V1b is the `bh` and the fada. If the model renders these as
English "b" and short "a", we have our answer.*

### V2 · `v02-seimhiu-kinetic` — 9:16, text_to_video

```
Extreme close-up of a smooth wet grey limestone surface filling the frame,
west of Ireland daylight, water beading on the stone.

The word "cat" is cut into the stone, sharp and clean.

A single letter "h" descends slowly and presses itself into the stone
between the c and the a. The stone yields. The word becomes "chat".

As the h lands, a woman's voice says the two words in the Irish language,
one after the other, matching the moment of change exactly: "cat", then
"chat" — the second noticeably softer than the first.

The type is a classical serif, deeply incised, no colour. No other text
appears. No music. No decoration, no Celtic ornament, no knotwork. Static
camera, one continuous shot.
```

*This clip deliberately burns in type and is therefore not an app asset (§2.1).*

### V3 · `v03-placename-bealfeirste` — 9:16, text_to_video

```
Aerial shot descending slowly over a wide tidal river mouth at low tide in
Ireland — grey water, exposed sandbanks, wet mud catching a flat overcast
light, hills rising behind. Real northern Irish geography, unglamorous,
documentary. The sandbank is the subject: a low pale ridge crossing the
channel where the water runs shallow.

The camera keeps descending toward the sandbank crossing until it fills the
frame.

Audio: only wind, water, and distant oystercatchers. No music, no voice.

No text of any kind appears on screen. No buildings, no city, no boats, no
people. Cold natural colour, no green saturation.
```

*Text-free by design — the anglicised/Irish name pair is live app copy composed over
this footage, per Design Principle 7.*

### V4 · `v04-gouache-motion` — 16:9, image_to_video

Reference image: `art/exploration/b4-solas/t3-strand.png`

```
Bring this painting to life with the smallest possible motion. The clouds
drift slowly across the sky. The shallow water at the tide edge moves
gently. Nothing else moves.

The image must remain a gouache and watercolour painting on heavy cold-press
paper throughout — visible paper grain, granulating pigment, dry-brush edges
that stay soft and painterly. Do not smooth, sharpen, or render it as
photography or 3D. The brushstrokes stay brushstrokes.

Audio: quiet wind and distant water only. No music.

Static camera. No zoom, no parallax, no push-in.
```

*If the paper grain crawls or the washes turn plastic, that is the finding.*

### V5a · `v05a-grainne-limestone` — 16:9, reference_to_video

Reference image: approved Gráinne interpretive portrait (see
`GRAINNE-ART-DIRECTION.md`; **not** the retired `GrainnePortraitMark`)

```
A gouache and watercolour painting in motion. This woman stands at the edge
of a sheltered bay in the west of Ireland in the sixteenth century, looking
out at the water. Pale limestone light, deep green moss, quiet weather.
Close to land, hand scale, calm.

She turns her head slowly to look further along the shore. That is the only
movement.

Plain working clothes of wool and linen, weathered and practical. No armour,
no jewellery, no heroic pose, no cloak in the wind, no ship. Nothing
decorative. She is a person who works on this water, not a figure in a
costume drama.

Visible paper texture, granulating pigment, soft atmospheric edges
throughout.

Audio: wind and water only. No music, no voice.
```

### V5b · `v05b-grainne-atlantic` — 16:9, reference_to_video

Same reference image as V5a.

```
The same woman, painted in the same gouache and watercolour manner, thirty
years later and under far greater pressure. She stands in a dark stone room,
lit from one high window. Atlantic blue-black dominates the frame. A single
mark of oxidised copper — a rust-red — in the shadow behind her.

She is still. She lifts her eyes to the light. That is the only movement.

Same face, same person, unmistakably. Plain dark wool. No armour, no
ornament, no crown, no court finery, no Tudor pageantry.

Visible paper texture, granulating pigment, soft edges. High contrast,
withheld, tense.

Audio: room tone only. No music, no voice.
```

*Scored on continuity against V5a and palette fidelity to `GRAINNE-ART-DIRECTION.md`
Ep 1 vs Ep 5.*

### V6 · `v06-the-crossing` — 16:9, text_to_video

```
Open Atlantic in a heavy following swell, seen low and close to the water,
almost at wave height. Grey-green water, long deep troughs, spray torn off
the crests by the wind. Overcast, cold, late in the day. The water is
genuinely dangerous and the physics are real — the mass and slowness of a
large swell, not choppy surface waves.

The camera holds low as one large swell lifts past and drops away.

No boat, no ship, no people, no land, no birds. Nothing romantic. This is
the sea as an obstacle.

Audio: wind and water only, heavy and continuous. No music.
```

### V9 · `v09-pangur-ban` — 16:9, text_to_video

```
A gouache and watercolour painting in motion. Ninth-century Irish monastic
scriptorium at night. One monk at a sloped writing desk, seen from behind
and slightly to the side, working by a single candle. Warm ochre light
against deep shadow.

A white cat sits on the desk at the edge of the vellum, watching the moving
pen. The cat's tail flicks once. The candle flame wavers. The monk's hand
continues writing.

Small, quiet, domestic, affectionate. No fantasy, no glowing manuscripts,
no Celtic knotwork ornament, no gold spectacle. The vellum page is blank —
no visible writing, letters, or text anywhere in frame.

Visible paper texture, granulating pigment, soft edges.

Audio: candle sound, the faint scratch of a pen, room tone. No music.
```

### V10 · `v10-anti-reference` — 9:16, text_to_video

```
A deliberately clichéd tourist advertisement for Ireland. Impossibly green
rolling hills under a rainbow. A red-haired woman in a flowing emerald gown
stands on a cliff edge with her hair blowing dramatically. Celtic knotwork
borders. Shamrocks. A distant round tower. Saturated emerald grading, lens
flare, sweeping drone camera move. Uplifting Celtic fiddle music with a bodhrán.
Everything is maximally picturesque.
```

*Calibration artifact for the editorial board. Never enters the asset pipeline;
file it beside V5 and label it as the standard we are refusing.*

## 7. Held for day two

- **V7 · The grant reel.** Six clips built with multi-turn editing for tonal
  consistency: the island, a county turning gold, the placename dissolve, the name-find,
  the return. All copy is live app text over the footage — nothing burned in.
  `STRATEGY.md` §6/U6 and step 9 put grant funding on the roadmap; funding bodies watch
  video. Doubles as the App Store preview.
- **V8 · Seanfhocal series.** One proverb per clip, 9:16, spoken, image-led. D6 chose An
  Féilire as the gentle ritual layer; ten a day turns a year of daily ritual content
  into five weeks of production. Start with *"Is fearr Gaeilge bhriste ná Béarla
  cliste"* — which is both a good proverb and an exact statement of the permission
  structure this product offers a hesitant learner.

Neither starts until V1 has told us whether the audio is Irish or English wearing Irish
spelling. That answer changes both.

## 8. Day-one outputs — reviewed

*2026-08-05.* Takes live in `art/video/` with prompt sidecars. Scores, kill
decisions, and the download→file map are in
[`art/video/CONTACT.md`](../art/video/CONTACT.md). Capture still does not imply
release eligibility (§2.6). V10 remains calibration-only.

Two batches:

1. **Batch A (`202608052059`)** — 1280×720 / ~6s (including prompts that asked
   for 9:16). Accidental 16:9 takes for V1a/V1b/V2/V3/V10 parked as `*-16x9.mp4`.
2. **Batch B (`202608052128`)** — 9:16 retakes for V1a, V1b, V2, V3, V10
   (720×1280 / ~6s); canonical for those five. V4–V6 and V9 remain Batch A only.

### Review summary

| Keep | Kill / iterate | Calibration |
| --- | --- | --- |
| V2 (probe only), V3, V4, V6, V9 (notes) | V1a, V1b, V5b; V5a weak | V10 |

**V1 answer (the question that spent two of ten):** Omni did not produce
intelligible Irish here. Auto-ASR (no Irish model available) heard *tá tú ar ais*
as “Tattoo her eyes,” and flattened V1b’s séimhiú/fada into English-shaped
tokens. Treat as English wearing Irish spelling until a native-speaker pass
says otherwise. That holds **V7** and **V8** spoken production.

**What earned the day:** V6 (crossing as physics), V4 (gouache survives motion),
V2 (mutation-as-action idea reads), V3 (placename engine plate), V10 (anti-
reference now enforceable beside any Gráinne keep). V5b’s blood-handprint
mark is the clearest register veto in the batch.
