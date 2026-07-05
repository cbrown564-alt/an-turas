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

### Phase 1 — The vertical slice
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

### Phase 2 — The content pipeline
The uncomfortable truth: this is a **content company with an app attached**. The
platform work (SwiftUI app, SRS engine, audio playback, progress model) is
well-understood engineering. The differentiator is a repeatable pipeline:
- Authoring format: lessons and narratives as structured data (likely JSON/Markdown
  hybrid) so writers, linguists, and illustrators work in parallel with engineering.
- An editorial board: at minimum one qualified Irish-language linguist/teacher and one
  historian reviewing every chapter. Cultural legitimacy is the moat; one viral
  "this app got the tuiseal ginideach wrong" thread is expensive.
- Audio strategy decided (recorded native speakers vs ABAIR synthesis vs hybrid).

### Phase 3 — Build out and launch
- iOS app: SwiftUI, offline-first, content shipped as data + downloadable chapter packs.
- SRS underneath everything (FSRS — same algorithm family blas and modern Anki use);
  the innovation is not the scheduler, it's the *clothing*: reviews framed as
  returning to places/characters, not as flashcard debt.
- Pedagogical alignment with TEG (Teastas Eorpach na Gaeilge) CEFR levels so progress
  maps to something externally real — "you are on track for TEG A1" beats "you have
  4,200 XP".
- Launch moments that align with the real Irish calendar: Seachtain na Gaeilge
  (March), Samhain, St Patrick's Day diaspora spike.

## 3. Major unknowns to discuss

**U1. Who is the primary learner?** The candidates are very different products:
- *The Irish adult with "school Irish" guilt* — 1.87M in RoI claim some Irish; most
  had 13 years of school Irish and can't hold a conversation. Latent knowledge,
  deep emotional stakes, largest addressable group.
- *The Northern Ireland revival learner* — fastest-growing, most identity-motivated,
  politically charged context, includes a remarkable cross-community strand
  (e.g. Turas in East Belfast teaching Irish to Protestant/unionist learners).
- *The diaspora* (US/UK/Australia) — biggest raw numbers, lowest baseline, most
  romantic motivation, pays for subscriptions, drove Duolingo's million-plus Irish
  learners.
- *Complete-beginner hobbyists* — Duolingo's crowd; hardest to retain.

The history-narrative concept serves all four, but tone, assumed knowledge, and
marketing differ enormously. **Recommendation to discuss: primary = school-Irish
re-learners + diaspora (they overlap in content needs), with NI as the cultural
north star we take special care over.**

**U2. Dialect policy.** Ulster, Connacht, and Munster Irish differ audibly in
pronunciation and noticeably in grammar/vocabulary. An Caighdeán Oifigiúil (the
official standard) exists for writing but nobody *speaks* it natively. Duolingo was
criticised for audio that matched no dialect consistently. Options: teach the
Caighdeán with deliberate exposure to all three dialects (Teanglann's audio gives all
three per word); or pick one (Ulster fits the NI story; Connacht is the "middle"
choice). This is a real cultural-politics decision, not a technical one.

**U3. What is the actual retention loop?** "Connection instead of streaks" is a
thesis, not a mechanism. Candidate mechanics to test: story cliffhangers between
sessions; a daily *seanfhocal* (proverb) ritual; chapter artifacts you collect
(a personal "museum" of Ireland); alignment with the real calendar; progress framed
as a physical journey across a map of Ireland. The vertical slice exists to find out
which of these actually pulls people back.

**U4. Does history gate language, or run alongside it?** If narrative unlocks are
the reward for language work, story becomes the carrot (motivating but risks
resentment). If they're parallel tracks, drilling loses its engine. Probably:
language effort unlocks story, but review is always dressed as revisiting, never as
debt.

**U5. Audio: humans, synthesis, or hybrid?** ABAIR (Trinity College Dublin) has
dialect-specific Irish TTS built over 20 years — the obvious partner/licensing
conversation to have early. Recorded native speakers are the gold standard but
expensive at narrative scale. Likely hybrid: humans for narrative voice, ABAIR for
generated/long-tail content — but ABAIR's licensing terms for commercial apps are an
open question to investigate.

**U6. Business model and funding.** Freemium subscription is the default. But note:
Foras na Gaeilge and Údarás na Gaeltachta fund Irish-language technology; NI has
Irish-language funding streams post-Identity and Language Act. Public money is
genuinely available — with strings (possibly around openness and pricing) that need
understanding before taking it.

**U7. Handling contested history.** A history-of-Ireland app cannot avoid
plantation, famine, partition, and the Troubles — and our growth market is Northern
Ireland. We need editorial principles written *before* we need them: multiple voices,
primary sources, warmth without triumphalism. Turas proves Irish can be
cross-community; the app should be a door, not a flag.

**U8. Pronunciation feedback.** Learners want to know "am I saying it right?"
Irish speech recognition is immature (ABAIR has research-grade ASR). Decide early
whether v1 attempts pronunciation scoring or deliberately punts (listening-first
pedagogy is defensible).

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

1. Decide U1 (persona) and U2 (dialect) — everything downstream depends on them.
2. Draft the historical spine: ~10–14 chapters from Ogham to the Belfast revival,
   each with its narrative hook and language payload.
3. Open the ABAIR licensing conversation and map Foras na Gaeilge grant schemes.
4. Design + build the Phase 1 vertical slice; recruit 10–20 test learners
   (candidate pools: r/gaeilge, Irish language Discords, a Conradh na Gaeilge branch).
