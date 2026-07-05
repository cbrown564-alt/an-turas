# Irish TTS landscape — pronunciation research

*Researched 2026-07-04 for the Chapter 1 bake-off. Updated 2026-07-05 with bake-off
decisions. The bar is fada vowel length and dialect authenticity, not “sounds fine to
an English speaker.”*

## Decision (2026-07-05, updated)

| Provider | Verdict |
|---|---|
| **Gemini 3.1 Flash TTS** | **Production voice** — passed native-speaker review; all-generated with QA per release (D7). Prompt-steered Connacht, commercially usable. Install via `tools/tts-bakeoff/` (`bundle_winner: gemini-3-flash`). |
| **ABAIR** | **Optional upgrade** — quality ceiling; evaluation-only until TCD grants bundling rights ([ABAIR.md](ABAIR.md)). Not a Phase 2 blocker. |
| **Azure Speech `ga-IE`** | **Deprioritised** — superseded by Gemini passing native-speaker review; revisit only if quality regresses on later chapters. |
| **ElevenLabs `eleven_v3`** | **Rejected** — not good enough on Irish pronunciation (e.g. *féar*/*fear*). |
| **Gemini 2.5 Flash TTS** | **Rejected** — superseded by 3.1; not good enough. |

**Production audio strategy (D7):** every utterance generated via Gemini 3.1, then
native-speaker QA'd before bundling in offline chapter packs. No hybrid human recording
for v1.

## Tier 1 — purpose-built for Irish (Gaeilge)

### ABAIR (TCD) — **best quality benchmark, licensing blocked**

- **What:** ~20 years of Irish speech tech; voices trained on native Gaeltacht speakers.
- **Dialects:** Connemara (Connacht), Dingle (Munster), Gweedore (Ulster) — the only
  product with explicit dialect selection.
- **Access:** Web demo at [abair.ie](https://abair.ie/synthesis); SAPI/NVDA plugins;
  unofficial public API at `synthesis.abair.ie` (currently exposes Munster Piper voice
  `ga_MU_cmg_piper` — Connemara voices are web-demo only).
- **Pronunciation:** Won our bake-off on 19/21 lines with 2.5 Gemini jury; correctly
  distinguishes *féar*/*fear*, *Seán*/*sean* where generalist models fail.
- **Blocker:** Non-commercial by default; bundling needs written TCD agreement
  ([ABAIR.md](ABAIR.md)).

### Azure Speech `ga-IE` — **follow-up bake-off (licensed native Irish)**

- **Voices:** `ga-IE-OrlaNeural` (female), `ga-IE-ColmNeural` (male).
- **Quality:** Microsoft reported MOS 4.62 for Irish neural voices (low-resource
  language launch, 2020). Dialect-generic “standard Irish” — not Connemara-specific,
  but actually speaks **Gaeilge**, not English-with-an-accent.
- **Pros:** Commercial licence off-the-shelf; SSML for phoneme-level pronunciation
  tweaks; stable API.
- **Cons:** Does not match our D2 Connacht-first promise as cleanly as ABAIR.
- **Status:** Scheduled as the next bake-off round after Gemini 3.1 playtest clips.
  Needs `AZURE_SPEECH_KEY` + region in `.env`.

## Tier 2 — generalist models

### Gemini 3.1 Flash TTS (`gemini-3.1-flash-tts-preview`) — **selected for playtest**

- **What:** Google’s low-latency TTS (April 2026); 70+ languages; inline accent/style
  tags.
- **Irish:** No dedicated `ga-IE` voice — steered via prompt (“Connacht Irish,
  long é in féar”). Manual bake-off: **quite good** — good enough to ship playtest
  clips while Azure and ABAIR are pursued.
- **Pros:** Strong controllability; commercially usable via Gemini API.
- **Cons:** Prompt-steered accent, not native dialect model; verify fada pairs by ear.

### ElevenLabs `eleven_v3` — **rejected**

- Listed **GLE Irish** among 74 languages; tested with `language_code: gle`.
- **Rejected:** pronunciation not good enough for a language-learning app — failed
  minimal pairs (e.g. *féar* pronounced as *fear*). Irish-*accent* English library
  voices are the wrong product entirely.

### Gemini 2.5 Flash TTS — **rejected**

- Previous generation. Superseded by 3.1; not good enough for our bar.

## Tier 3 — not Gaeilge (avoid for this app)

| Provider | Code | Why skip |
|---|---|---|
| **Amazon Polly** | `en-IE` Niamh | Irish-*English* accent, not Gaeilge. No `ga-IE`. |
| **ElevenLabs accent voices** | Niamh, Jamie, Seán | English with Irish lilt — wrong language. |
| **Apple AVSpeech** | `ga-IE` | **No system voice shipped** as of iOS 26. |
| **OpenAI / Cartesia / Deepgram** | — | No Irish (Gaeilge) locale found. |

## Next steps

1. **Install Gemini 3.1 picks** — set `bundle_winner: gemini-3-flash` in
   `tools/tts-bakeoff/winners.json`, run `python bakeoff.py install`.
2. **Production pipeline** — script → generate → native-speaker QA → bundle per chapter
   release (D7).
3. **ABAIR** — optional upgrade if bundling rights granted; send commercial enquiry
   ([ABAIR-enquiry.md](ABAIR-enquiry.md)) when convenient, not blocking Phase 2.

## Sources

- [ABAIR.ie](https://www.abair.ie/) — dialect TTS, terms, contact
- [Azure Irish neural voices announcement](https://techcommunity.microsoft.com/blog/azure-ai-foundry-blog/neural-text-to-speech-previews-five-new-languages-with-innovative-models-in-the-/1907604) — MOS 4.62 for ga-IE
- [ElevenLabs language support](https://help.elevenlabs.io/hc/en-us/articles/13313366263441) — GLE Irish in v3
- [Gemini 3.1 Flash TTS](https://ai.google.dev/gemini-api/docs/models/gemini-3.1-flash-tts-preview)
- [Amazon Polly voices](https://docs.aws.amazon.com/polly/latest/dg/available-voices.html) — en-IE only, no ga-IE
