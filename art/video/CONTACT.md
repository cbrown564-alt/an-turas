# Omni video contact sheet — day one

*Filed 2026-08-05. Reviewed 2026-08-05 against `docs/OMNI-EXPLORATION.md` §4.
Prompts and mechanics: same doc §5–§6. Capture still does not imply release
eligibility.*

## Status

**Reviewed (provisional).** Scores below are an editorial pass on the filed takes.
Native-speaker QA is still required for any Irish-audio claim that might ship;
Whisper has no Irish locale, so audio findings use English auto-detect as a
failure-mode probe only. V10 remains calibration-only — never promote.

## Batch notes

- **Batch A (`202608052059`):** first UI downloads; all 1280×720 / ~6s.
- **Batch B (`202608052128`):** 9:16 retakes for V1a, V1b, V2, V3, V10
  (720×1280 / ~6s). Canonical for those five; Batch A parked as `*-16x9.mp4`.
- Clip length is ~6s everywhere, not the ~10s unit the slate assumed.
- Sidecar `interaction_id` unknown (UI download).

## Day-one verdict (before the arithmetic)

| # | Canonical | Decision | One-line finding |
| --- | --- | --- | --- |
| V1a | 9:16 | **Kill / iterate** | Intended *tá tú ar ais*; ASR hears English “Tattoo her eyes.” Not Irish enough to open the dialogue path. |
| V1b | 9:16 | **Kill / iterate** | Séimhiú and fada collapse (*bhean*→“Bain”, *Sláinte mhaith*→“Slantomite”). Different woman from V1a. |
| V2 | 9:16 | **Keep (probe only)** | The teaching idea reads: `cat` → descending `h` → `chat`, audio timed. Not an app asset (burned-in type). Softness of *chat* unverified. |
| V3 | 9:16 | **Keep / light iterate** | Tidal sandbank descent works; cold register; distant buildings sneak in against the prompt. |
| V4 | 16:9 | **Keep (Phase 3 proof)** | Gouache/paper survives motion; water moves more than sky; not plastic. |
| V5a | 16:9 | **Weak keep / iterate** | Quiet bay register is close; face/costume do not lock to approved Gráinne portraiture. |
| V5b | 16:9 | **Kill** | “Oxidised copper” became a dripping blood-handprint. Thriller register; continuity with V5a fails. |
| V6 | 16:9 | **Keep** | Hostile open-Atlantic swell, low and close — strongest clip in the batch. |
| V9 | 16:9 | **Keep with notes** | Pangur charm is real; camera restlessness and a near-blank page mark need a cleaner take. |
| V10 | 9:16 | **Keep (calibration only)** | Does the anti-reference job: emerald gown, shamrocks, Celtic corners, rainbow, flare. Never pipeline. |

**Day-two gate:** V1 says the audio is English wearing Irish spelling (or worse).
Hold V7 (grant reel) and V8 (seanfhocal) spoken tracks until a better Irish take
exists; silent / ambient / image-led work can proceed from V3–V6 and V9.

## Scorecard (canonical takes)

Scale 1–5. `—` = not applicable. Veto asked first: does this make Irish feel more
worth learning, or like every other app with a video budget?

| # | Veto | Pull | Belong | Register | Continuity | Repeat | Irish | Motion honesty | Material | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| V1a | Fail | 3 | 3 | 4 | 2 vs V1b | 2 | **1** | 2 | — | Documentary face/window good; Irish fails. |
| V1b | Fail | 3 | 3 | 4 | 2 vs V1a | 2 | **1** | 3 | — | Teaching cadence present; phonology wrong. |
| V2 | Pass* | 4 | 2† | 4 | 4 | 3 | 2 | **5** | — | *Marketing/pedagogy only. †Burned-in type. |
| V3 | Pass | 4 | 4 | 4 | 4 | 4 | — | 4 | — | Sandbank is the subject; lose buildings. |
| V4 | Pass | 3 | **5** | 4 | 4 vs still | 4 | — | 3 | **4** | Ambient life without plasticising pigment. |
| V5a | Soft pass | 3 | 3 | 3 | 2 vs portrait / V5b | 2 | — | 2 | 3 | Head turn tiny; deckle border OK if intentional. |
| V5b | **Veto** | 2 | 1 | **1** | 1 | 1 | — | 2 | 3 | Blood mark kills it. |
| V6 | Pass | **5** | 4 | **5** | 5 | 4 | — | **5** | — | Difficulty of the crossing made legible. |
| V9 | Pass | **5** | 3 | 3 | 3 | 3 | — | 3 | 3 | Charm high; slightly storybook; restless camera. |
| V10 | N/A (anti) | 2 | 0 | 0‡ | 5 as cliché | 5 | — | 3 | — | ‡Succeeds by failing Killala. File beside V5. |

## Findings by clip

### V1a · `v01a-irish-dialogue-tatuarais` (9:16)

Warm older woman by a whitewashed window; soft daylight; smile lands. Speech energy
is brief (~0.6–1.4s). Whisper (en detect): **“Tattoo her eyes.”** — the exact
anglicising failure mode §3 warned about. Lip motion present but irrelevant if the
vowels are wrong. **Irish: 1.**

### V1b · `v01b-irish-dialogue-seimhiu` (9:16)

Different woman from V1a (short silver hair, chunky grey knit — not the window
portrait). Longer speech window. Whisper: **“Bean and Bain, Moe Bain, Slantomite.”**
*Bean* survives; *an bhean* / *mo bhean* lose the séimhiú; *Sláinte mhaith* loses
fada and *mh*. **Irish: 1.** Hard-case test failed informatively.

### V2 · `v02-seimhiu-kinetic` (9:16)

Wet limestone, serif incisions, water beading. Mid-clip shows `h` descending above
`cat`; settles as `chat`. Audio “Cat. Chat.” roughly synced to the change. Idea
reads in six seconds — Omni’s text-synced-to-action claim holds for this prompt.
Whether *chat* is Irish /xat/ or English “chat” needs a native ear; ASR treats it
as English. **Not an in-app asset** (§2.1).

### V3 · `v03-placename-bealfeirste` (9:16)

Aerial descent over a tidal mouth; sandbanks and mud under flat overcast light;
cold, unglamorous. Sandbank becomes the frame by the end. Distant settlement on the
far bank violates “no buildings.” Still the clearest Logainm-engine proof in the
batch. Prefer 9:16 over the 16:9 park.

### V4 · `v04-gouache-motion` (16:9)

Source: `art/exploration/b4-solas/t3-strand.png`. Remains visibly gouache/watercolour
on paper through the clip — grain and soft edges hold. Mean frame change is higher
in the water than the sky (subtle weather drift, not a parallax toy). Phase 3
“motion later” assumption survives.

### V5a · `v05a-grainne-limestone` (16:9)

Painterly bay, limestone/moss palette, plain working clothes — closer to the Ep 1
brief than to costume drama. Does **not** read as the same person as live
`grainne-crossing` (different face, no continuity lock). Head turn is minimal.
Deckled paper edge present.

### V5b · `v05b-grainne-atlantic` (16:9)

Stone room and upward glance are in the brief; the rust-red accent rendered as a
**dripping blood handprint**. That is a veto for Belonging/Register. Aged face does
not read as the same woman as V5a thirty years on — more “different casting.” Kill;
do not put beside V5a in any board pack without a replacement take.

### V6 · `v06-the-crossing` (16:9)

Low, near wave-height Atlantic swell; mass and troughs feel real; no boat, land, or
figures. Cold, unromantic, physics-led. Best answer to “does motion clarify what a
still cannot?” in this batch.

### V9 · `v09-pangur-ban` (16:9)

Monk, candle, white cat — immediately legible Pangur Bán. Warm ochre vs stone cool
works. Camera jumps from wide scriptorium to hand/cat insert (more coverage than
the “one continuous quiet shot” ask). Parchment nearly blank, with a small mark in
the tight shot. Slightly polished/storybook vs Solas register, but the strongest
standalone marketing candidate after V6.

### V10 · `v10-anti-reference` (9:16)

Emerald gown, red hair on a cliff, floating shamrocks, golden Celtic corner knots,
rainbow, lens flare — maximally the thing §2.4 refuses. Mission accomplished.
Label clearly; never enter the asset pipeline; park beside any future Gráinne keep.

## Filename map (download → file)

### Batch A — 16:9 (202608052059)

| Download | File |
| --- | --- |
| `Woman_speaking_Irish_by_window_202608052059.mp4` | `v01a-irish-dialogue-tatuarais-16x9.mp4` |
| `Woman_speaking_Irish_language_202608052059.mp4` | `v01b-irish-dialogue-seimhiu-16x9.mp4` |
| `Letter_presses_into_stone_surface_202608052059.mp4` | `v02-seimhiu-kinetic-16x9.mp4` |
| `Aerial_descent_over_tidal_river_202608052059.mp4` | `v03-placename-bealfeirste-16x9.mp4` |
| `Painting_with_subtle_motion_202608052059.mp4` | `v04-gouache-motion.mp4` |
| `Woman_looking_at_water_202608052059.mp4` | `v05a-grainne-limestone.mp4` |
| `Woman_lifts_eyes_to_light_202608052059.mp4` | `v05b-grainne-atlantic.mp4` |
| `Open_Atlantic_heavy_swell_passing_202608052059.mp4` | `v06-the-crossing.mp4` |
| `Monk_writing_by_candle_light_202608052059.mp4` | `v09-pangur-ban.mp4` |
| `Woman_standing_on_Irish_cliff_202608052059.mp4` | `v10-anti-reference-16x9.mp4` |

### Batch B — 9:16 (202608052128)

| Download | File |
| --- | --- |
| `Woman_speaking_Irish_by_window_202608052128.mp4` | `v01a-irish-dialogue-tatuarais.mp4` |
| `Woman_teaching_Irish_language_202608052128.mp4` | `v01b-irish-dialogue-seimhiu.mp4` |
| `Letter_pressing_into_limestone_s…_202608052128.mp4` | `v02-seimhiu-kinetic.mp4` |
| `Aerial_camera_descending_over_river_202608052128.mp4` | `v03-placename-bealfeirste.mp4` |
| `Woman_standing_on_Irish_cliff_202608052128.mp4` | `v10-anti-reference.mp4` |
