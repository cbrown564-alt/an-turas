# ABAIR licensing map

*Researched 2026-07-04 from abair.ie (home, terms, contact pages). ABAIR is the key
audio partner candidate per STRATEGY.md U5.*

## What ABAIR is

- Project of the **Phonetics and Speech Laboratory, Trinity College Dublin** (School
  of Linguistic, Speech and Communication Sciences). ~20 years of Irish speech-tech
  work, publicly funded (Dept. of Rural & Community Development and the Gaeltacht;
  DCEDIY; COGG; National Lottery).
- Co-directors: **Ailbhe Ní Chasaide** and **Neasa Ní Chiaráin**.
- Offerings:
  - **ABAIR** — text-to-speech with dialect selection, including **Conamara
    (Connacht) voices** — exactly matching our D2 dialect policy — plus Ulster
    (Gweedore) and Munster voices for later expansion.
  - **ÉIST** — Irish speech-to-text (relevant to pronunciation feedback, U8, later).
  - **COMHRÁ** — speech-to-speech conversational beta.
  - Public GitHub: `phonlab-tcd`.

## What the terms actually say (as of July 2026)

- **Default licence is non-commercial.** Outputs may be used for personal and
  educational purposes only; *"You may not… use the Services for commercial purposes
  without prior written consent."*
- **TCD owns everything** — the technology, the voices, and materials. No rights to
  copy, modify, or **distribute outputs** without permission.
- No published commercial-licensing process, pricing, attribution rules, or API
  rate limits. The path is a direct written agreement.
- General contact: **info@abair.ie**; the site's contact form has a dedicated
  *business enquiries* category.

**Implication for us:** we cannot ship ABAIR-generated audio in a paid app — or even
arguably in a free commercial app — without a written agreement. And because our
architecture is offline-first (audio bundled in chapter packs), we specifically need
**redistribution** rights, not just API-call rights. This is a bigger ask than
"let us call your API", and must be named explicitly in the negotiation.

## The process, step by step

1. **Technical evaluation — now, free, no permission needed.**
   Run Chapter 1's script through the web demo's Conamara voices. Assess separately:
   (a) word/phrase-level quality for exercises, (b) sustained narrative reading
   quality, (c) Ulster voice quality as a preview of the NI prerequisite.
   Output: a go/no-go on quality before we invest negotiation effort.
2. **Written enquiry** via info@abair.ie + the business-enquiries contact form,
   addressed to the co-directors. One page: who we are, the app's mission
   (mission-aligned: publicly-funded Irish revival tech meeting an Irish-learning
   product), what we want (commercial licence to generate and **bundle** audio),
   ask for a call.
3. **Expect TCD's commercialisation office** (Trinity Innovation) to enter for any
   formal licence. University licensing runs in months, not weeks — start before we
   need the audio, i.e. now.
4. **Scope the agreement.** The checklist of things to nail down:
   - Voices covered (Conamara now; option on Ulster + Munster later).
   - **Pre-generation and bundling rights** (our model: batch-generate per content
     release, QA every clip, ship in offline packs) vs runtime API access.
   - Volume/fee structure (per-utterance, flat annual, or revenue share).
   - Attribution ("Guthanna le ABAIR/TCD" credit is cheap for us and valuable to a
     publicly funded project — offer it proactively).
   - Quality-control rights: can we pick among takes, adjust pronunciation via
     their input conventions, and reject clips?
   - Whether voice talent's underlying consents permit commercial redistribution
     (their voices come from real Gaeltacht speakers; rights may be layered).
   - Non-exclusivity (fine for us) and term/renewal.
5. **Leverage alignment.** ABAIR's funders (Gaeltacht dept., COGG) exist to promote
   Irish. If we pursue Foras na Gaeilge / Údarás grants (STRATEGY.md U6), a
   grant-supported project licensing ABAIR keeps public money in the Irish-language
   ecosystem — a story both sides can bring to their funders.

## Decision criteria (go/no-go on ABAIR vs alternatives)

| Criterion | Bar |
|---|---|
| Conamara voice naturalness — narrative reading | Testers don't comment on "robot voice" unprompted |
| Word-level clarity for drills | Clear broad/slender contrast audible |
| Bundling rights granted | Non-negotiable for offline-first |
| Cost | Sustainable at pre-generation volumes (thousands of clips per chapter, one-off) |
| Ulster voice quality | Adequate — gates the NI launch timeline (D2) |

## Fallbacks, in order

1. **Hybrid regardless of outcome (recommended plan):** recorded human native
   speaker(s) for narrative beats — the emotional register of storytelling is worth
   human voice — with ABAIR for the exercise long-tail (thousands of prompts,
   variants, and future content). The negotiation above covers the TTS half only.
2. **Azure Speech `ga-IE` neural voices** (e.g. Orla) — commercially licensed
   off-the-shelf, but dialect-generic standard Irish. Acceptable stopgap for
   exercise audio only; contradicts our dialect promise if used for narrative.
3. **Human-only audio** — gold standard, highest cost, slowest pipeline; viable if
   chapter cadence stays slow.
4. **No audio in early testing** — the current vertical slice ships without audio;
   fine for testing narrative pull, unacceptable for the real product (Irish
   orthography without audio actively harms learners).

## Immediate actions

- [ ] Run the Chapter 1 script through ABAIR's Conamara voices (step 1).
- [ ] Draft the one-page enquiry letter (step 2) — after the vertical slice exists,
      so we can show, not tell.
