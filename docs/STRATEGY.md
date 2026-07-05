# Strategy: the map at day one

*Written 2026-07-04. This is a living document — revise as decisions get made.*

## 1. The thesis, restated sharply

Irish is the rare language where the strongest learner motivation is not utility but
**identity**. Nobody learns Irish to order coffee in Dublin — English works fine.
People learn it to reclaim something: heritage, community, a political and cultural
statement, a connection to place. The 2021 NI census showed Irish ability up 23.6% in
a decade (228,600 people, 12.4% of the population); Irish-medium schooling in NI keeps
growing (7,598 pupils in 2025); GCSE Irish entries rose ~15% in 2024. The demand curve
is real and rising, and it is *identity-shaped* — which is exactly the motivation
existing apps cannot serve, because their engagement model (streaks, XP, leagues) is
language-agnostic by design.

Our bet: **a narrative journey through Irish history, with the language woven through
it, is a stronger retention engine for this audience than gamification** — and it is
only buildable if you commit to a single language pair, which we have.

## 2. How do we get there — the path

### Phase 0 — Decisions (weeks, not months)
These block everything else; see §3 (Unknowns).
1. Pick the primary learner persona.
2. Pick the dialect policy.
3. Sketch the **historical spine**: the ordered list of eras/chapters and, for each,
   the narrative hook and the language payload it naturally carries.

### Phase 1 — The vertical slice ✓
Build **one chapter end-to-end** before building any platform:
- One historical era (candidate: early Christian Ireland / the monastic world — visually
  rich, politically safe, and full of loanword-era vocabulary; or start at Ogham for
  the "beginning of the written language" symmetry).
- ~2 weeks of daily learning content: narrative scenes, vocabulary, one or two grammar
  concepts introduced *because the story needs them*, SRS review dressed in the
  chapter's world.
- Real illustration style tests (this app lives or dies on visual identity).
- Put it in front of 10–20 real target learners. Measure: do they come back without
  streaks? What do they say pulled them back?

**Status (2026-07-05):** Complete. Chapter 1 shipped in SwiftUI; playtest validated
return without streaks. Validated pull: *tá tú ar ais* greeting and journey map.
An Féilire chosen as the gentle ritual layer for later phases. See D5–D6 in
`DECISIONS.md`.

### Phase 2 — The content pipeline ← *now*
The uncomfortable truth: this is a **content company with an app attached**. The
platform work (SwiftUI app, SRS engine, audio playback, progress model) is
well-understood engineering. The differentiator is a repeatable pipeline:
- Authoring format: lessons and narratives as structured data (JSON in bundled chapter
  packs) so writers, linguists, and illustrators work in parallel with engineering —
  **validated in Phase 1** (D3, D9).
- **Content review CMS:** a purpose-built, low-key review layer with a beautiful UI so
  all stakeholders can review, comment, and sign off efficiently (D9).
- An editorial board: at minimum one qualified Irish-language linguist/teacher and one
  historian reviewing every chapter. Cultural legitimacy is the moat; one viral
  "this app got the tuiseal ginideach wrong" thread is expensive.
- Audio: **Gemini 3.1 Flash TTS, all-generated with native-speaker QA** per release
  (D7). Illustration: **Solas an Atlantaigh on scene pages only** (D4, D8).
- **Proof:** Chapter 2 (*Oileán na Naomh*) produced end-to-end through the pipeline.

### Phase 3 — Build out and launch
- iOS app: SwiftUI, offline-first, content shipped as data + downloadable chapter packs.
- SRS underneath everything (FSRS — same algorithm family blas and modern Anki use);
  the innovation is not the scheduler, it's the *clothing*: reviews framed as
  returning to places/characters, not as flashcard debt.
- **An Féilire:** gentle daily rituals borrowed from the real Irish calendar
  (seanfhocal, seasonal beats, launch moments) — the flywheel alongside narrative pull
  (D6).
- Pedagogical alignment with TEG (Teastas Eorpach na Gaeilge) CEFR levels so progress
  maps to something externally real — "you are on track for TEG A1" beats "you have
  4,200 XP".
- **Launch scope: Chapters 1–4** at production quality (D10). **Premium subscription**
  with grant funding pursued on top, not instead of revenue.
- Launch moments that align with the real Irish calendar: Seachtain na Gaeilge
  (March), Samhain, St Patrick's Day diaspora spike.

## 3. Major unknowns — status

### Resolved

**U1. Primary learner → D1.** School-Irish re-learners + diaspora primary; NI as
cultural north star.

**U2. Dialect policy → D2.** Connacht first; Ulster required before NI launch.

**U3. Retention loop → D5/D6.** Narrative pull validated: *tá tú ar ais* greeting and
journey map pull testers back without streaks. Recarve, amárach hooks, and Ar Ais drew
no negative feedback but went unmentioned — they remain authored chapter devices.
Gentle ritual layer: **An Féilire** (real-calendar seanfhocal, seasonal beats,
calendar-aligned launch moments). Meaning as engine, calendar as flywheel — not
gamification.

**U5. Audio → D7.** Gemini 3.1 Flash TTS, all-generated with native-speaker QA per
release. Passed native-speaker review on Chapter 1. ABAIR remains optional upgrade if
bundling rights granted.

**U6. Business model → D10.** Premium subscription. Grant funding on top (Foras na
Gaeilge, Údarás, NI streams). Bespoke content. Chapters 1–4 at launch.

**U8. Pronunciation feedback → D11.** Listening-first permanent. Echo pages ungraded;
no pronunciation scoring in the roadmap.

### Still open

**U4. Does history gate language, or run alongside it?** If narrative unlocks are
the reward for language work, story becomes the carrot (motivating but risks
resentment). If they're parallel tracks, drilling loses its engine. Probably:
language effort unlocks story, but review is always dressed as revisiting, never as
debt. Phase 1 mechanics suggest this holds; no explicit decision logged yet.

**U7. Handling contested history.** A history-of-Ireland app cannot avoid
plantation, famine, partition, and the Troubles — and our growth market is Northern
Ireland. We need editorial principles written *before* we need them: multiple voices,
primary sources, warmth without triumphalism. Turas proves Irish can be
cross-community; the app should be a door, not a flag. Required before Chapter 10
production.

### Reference — original framing (superseded where marked ✓)

**U1. Who is the primary learner?** ✓ See D1.

**U2. Dialect policy.** ✓ See D2.

**U3. What is the actual retention loop?** ✓ See D5/D6.

**U4. Does history gate language, or run alongside it?** (Still open — see above.)

**U5. Audio: humans, synthesis, or hybrid?** ✓ See D7.

**U6. Business model and funding.** ✓ See D10.

**U7. Handling contested history.** (Still open — see above.)

**U8. Pronunciation feedback.** ✓ See D11.

## 4. Largest challenges

1. **Content cost is the business model risk.** Bespoke narrative + illustration +
   expert-reviewed pedagogy per chapter is orders of magnitude more expensive per
   learner-hour than Duolingo's templated exercises. The quality is the moat, but the
   burn is real. Mitigation: vertical slice first; pipeline before volume; public
   funding; and depth-over-breadth (one language pair forever is a feature).
2. **Irish is legitimately hard for anglophones** — VSO order, initial mutations
   (séimhiú/urú), the copula vs *bí* distinction, prepositional pronouns (*agam*,
   *agat*…), and an orthography that looks unpronounceable until the broad/slender
   system clicks. Our promise is that we *explain* these, beautifully, where others
   drill or ignore. That requires genuinely excellent pedagogy — the scarcest input.
3. **Retention without gamification is unproven.** Narrative pull is proven in
   television, not in daily 10-minute learning habits. We may need a hybrid: meaning
   as the engine, light structure (gentle reminders, rituals) as the flywheel — while
   refusing the manipulative end of the spectrum. This is the core product-design
   research question.
4. **The expert bottleneck.** Qualified Irish-language pedagogues, dialect-consistent
   voice talent, and historians who can write for a popular audience form a small
   pool, already courted by TG4, Gaelchultúr, universities, and other apps.
5. **Political and cultural legitimacy.** Get the history or the language wrong —
   or strike a "plastic shamrock" tone — and the exact community whose endorsement we
   need becomes the loudest critic. Mitigation: advisory board, native speakers on
   staff, humility in marketing, engage Conradh na Gaeilge early.
6. **Duolingo's default mindshare.** "I'm learning Irish" ≈ "I'm on Duolingo" for
   millions. We don't beat that head-on; we position as *where you go when you mean
   it* — and where Duolingo drop-outs land.
7. **Licensing landmines.** Foclóir Gaeilge–Béarla, Foclóir.ie, and much reference
   audio belong to Foras na Gaeilge. Dúchas.ie folklore has its own terms. Budget
   for licensing conversations, not scraping.

## 5. Resource landscape

### Linguistic infrastructure (mostly Foras na Gaeilge / DCU / TCD)
- **Teanglann.ie** — Ó Dónaill dictionary, grammar database (full declensions/
  conjugations), and per-word audio *in all three dialects*. The single most
  important reference.
- **Foclóir.ie** — the modern English→Irish dictionary with rich contextual examples.
- **Gaois.ie** (DCU Fiontar) — corpora (~21M+ words of contemporary Irish),
  terminology (téarma.ie), and research tooling.
- **ABAIR.ie** (TCD) — dialect-specific Irish text-to-speech and emerging speech
  tech; has education-oriented tools; the key audio-partnership conversation.
- **TEG** (Teastas Eorpach na Gaeilge, Maynooth) — the CEFR-aligned Irish syllabus
  and exams; our external progress ladder.
- **Gramadach na Gaeilge / Nualéargais** — deep grammar reference (German-origin,
  English translation) for pedagogy research.

### Cultural and historical goldmines
- **Dúchas.ie** — the National Folklore Collection digitised, including the Schools'
  Collection (1930s children collecting folklore from elders, in Irish and English).
  Near-perfect raw material for narrative chapters.
- **Logainm.ie** — the placenames database. Placenames are the single best
  culture↔language bridge (every learner's town name *means something* in Irish).
- **Ainm.ie** — Irish-language biography.
- **TG4 / Cúla4 / RTÉ Raidió na Gaeltachta** — authentic listening; potential
  partnership for graded listening content.
- Museums/archives: National Museum, National Library, RIA — imagery licensing for
  visual narratives.

### Community and institutional (offline)
- **Conradh na Gaeilge** — the revival organisation; advocacy, classes, credibility.
- **Oideas Gael** (Gleann Cholm Cille), **Gael Linn**, **Gaelchultúr** — immersion
  courses and adult education; possible content partners and a "graduate to the
  Gaeltacht" pathway our app could feed (a real-world reward no gamified app offers).
- **Turas (East Belfast) / Glór na Móna (West Belfast)** — the NI revival on the
  ground; essential relationships for the NI story done right.
- **Foras na Gaeilge / Údarás na Gaeltachta / NI funding streams** — grant money for
  exactly this kind of project.

## 6. Competitive landscape

*Full report (pedagogy, features, positioning, failed experiments):
`COMPETITIVE-RESEARCH.md`.*

| Competitor | What it is | Threat level | What we learn |
|---|---|---|---|
| **Duolingo Irish** | Gamified generalist; 1M+ Irish learners historically | High (distribution), low (product depth) | The market exists; the drop-outs are our funnel |
| **blas.** | New (2025) Celtic-specific app; FSRS spaced repetition, systematic mutation drilling; freemium; iOS/Android/web | **Highest product threat** | Owns "rigour for Celtic languages"; validates single-family depth; does *not* do culture/history/narrative |
| **Gaeilgeoir** | Immersion audio stories + cultural insights | Medium — closest to our angle | Study closely; gauge how deep their "culture" really goes |
| **Bitesize Irish** | Established subscription lessons + podcast, diaspora-focused | Medium | Proves diaspora pays; strong SEO/email presence |
| **Let's Learn Irish** | Live group classes + community | Low–medium | Community is a retention engine; potential partner |
| **Pimsleur / Drops / Mango / Ling** | Generalist apps with Irish courses | Low | Vocab/audio niches; no depth, no culture |
| **Free institutional** | DCU's free Irish 101–108 MOOCs (Fáilte ar Líne), Ranganna.ie | Low | Sets the "free" baseline for structured courses |
| **Indirect** | TikTok/Instagram Gaeilgeoirí, podcasts (Motherfoclóir), YouTube, Anki decks | — | Where the audience already hangs out; marketing channels more than competitors |

**Positioning read:** blas owns *rigour*. Duolingo owns *habit*. Bitesize owns the
*diaspora email list*. Nobody owns **"learn Irish by falling in love with the story
of Ireland."** That ground is open — but blas's existence proves serious builders
have noticed Irish, so the window for claiming the identity/narrative position is
now, not in two years.

## 7. Proposed next steps

1. ~~Decide U1 (persona) and U2 (dialect)~~ — D1, D2.
2. ~~Draft the historical spine~~ — `SPINE.md` (needs historian/pedagogue review).
3. ~~Build Phase 1 vertical slice; playtest~~ — D5 exit.
4. **Phase 2 (now):** build content review CMS (D9); stand up editorial board; produce
   Chapter 2 through the pipeline; document illustration and audio production recipes.
5. Open grant-funding research (strings before accepting — D10).
6. Write contested-history editorial principles before Chapter 10 (U7).
7. ABAIR enquiry optional — quality ceiling / future upgrade, not Phase 2 blocker (D7).
