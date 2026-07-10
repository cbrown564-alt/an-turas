# Decisions log

Short records of decisions that shape everything downstream. Add new entries at the top.

## D12 — County-led stories, real anchors, and a concrete learning promise (2026-07-10)

**Decision:** The 32 counties are the product's primary visible journey and unit of
progress. Every playable county story is headed by a real, named anchor — a person,
myth, monument, community, or primary record — and gives the learner a substantial
reading or encounter of significance. It teaches **20 useful words per county**.
The historical spine remains the language-sequencing rail; it is no longer the sole
information architecture presented to a learner.

**Why:** Feedback was enthusiastic about learning Irish through history and culture,
but asked for the journey to feel like a trip around real Ireland, not a sequence of
generic scenes or eras. A county gives every story a place on the map, a clear unit of
completion, and a promise a learner can repeat. Named anchors and source-led readings
make the cultural claim earned rather than decorative.

**Consequences:**

- `COUNTY-ATLAS.md` is the product contract; `COUNTY-STORY-SLATE.md` is the researched
  development slate for all 32 first stories.
- Map semantics are fixed: **green** is the current county/story, **gold** means all
  shipped stories in that county are complete, and **white** means still ahead. A
  white county is an honest promise, not a disguised lock.
- A chapter becomes a pedagogical/production grouping. Existing Chapters 1–4 remain
  the launch-quality scope, but their shipped stories are explicitly Mayo, Offaly,
  Dublin, and Meath stops in the county journey.
- New content cannot be drafted from a generic role. It needs a county brief, named
  anchor, reading plan, 20-word plan, source register, rights check, and historian +
  Irish-language-pedagogue review.
- The app schema, map cards, CMS, and content pipeline must migrate toward a
  story-first/county-first model without breaking existing chapter progress. This is
  Phase 2 product work, not a claim that all 32 stories are ready now.

## D11 — Pronunciation: listening-first, permanently (2026-07-05)

**Decision:** No pronunciation scoring in the product roadmap. Listening-first
pedagogy is permanent: model audio, minimal-pair listening exercises, and ungraded
echo pages (record yourself beside the model, no pass/fail).

**Why:** Irish speech recognition is immature; bad scoring would erode trust faster
than no scoring. Playtesters did not ask for grades — they asked to hear Irish done
right. Echo remains a mirror, not a judge.

**Consequences:** U8 closed. ÉIST/ABAIR ASR stays a research watch, not a v1 feature.
Product copy and onboarding should set the expectation: ears first, mouth second, no
red X on your accent.

## D10 — Business model and launch scope (2026-07-05)

**Decision:** Premium subscription (paid product, not freemium-by-default). Pursue
public grant funding (Foras na Gaeilge, Údarás na Gaeltachta, NI streams) *on top
of* subscription revenue — grants accelerate content, they don't replace the business.
Launch at **Chapters 1–4** at production quality. Content stays bespoke: narrative +
illustration + expert-reviewed pedagogy per chapter, not templated exercises.

**Why:** Playtest validated that re-learners and diaspora respond to depth and care;
the moat is quality, not volume. Premium aligns price with bespoke production cost.
Grants are mission-aligned and available, but strings (openness, pricing) must be
understood before accepting — funding supplements, it doesn't dictate freemium.

**Consequences:** U6 substantially closed. Phase 3 launch target is four chapters
(Ogham → Normans, A1→A1/A2). Revenue model, grant applications, and content budget
are planned together. No race to chapter count at the expense of editorial standards.

## D9 — Content review CMS (2026-07-05)

**Decision:** The bundled JSON content-as-data format (D3) is validated for adding
new chapters. Phase 2 adds a **purpose-built content review layer** — low-key, not
enterprise CMS — with a beautiful UI so writers, linguists, historians, and engineers
can review and sign off on content cleanly and efficiently.

**Why:** Playtest confirmed the format works for engineering; production at Chapter 2+
scale needs a shared review surface. Stakeholders should comment, diff, and approve
without touching Xcode or raw JSON in an editor.

**Consequences:** Phase 2 engineering includes a review app (web or native-adjacent)
that reads the same chapter schema the iOS app ships. Editorial workflow (draft →
linguist review → historian review → audio QA → sign-off) is defined around this tool.
Exact stack TBD; the requirement is stakeholder-first, not feature-rich.

## D8 — Illustration scope: scene pages only (2026-07-05)

**Decision:** Illustration applies to **scene pages only**. Notes, exercises, beats,
and all other registers stay clean and typographic (per D4 register rules).

**Why:** Playtest and production planning agree: Solas an Atlantaigh carries the
narrative world; drilling registers stay readable. Scene-only scope keeps per-chapter
illustration cost predictable at pipeline scale.

**Consequences:** Content schema and art briefs tag `scene` pages as the only
illustrated surface. Chapter 2 pipeline proves cost-per-scene at this scope.

## D7 — Audio production model: all-generated with QA (2026-07-05)

**Decision:** **Gemini 3.1 Flash TTS** is the production voice engine. Every utterance
is generated, then human-QA'd (native-speaker review per release). No hybrid
human-recorded narrative for v1; no runtime voice switching.

**Why:** Gemini passed native-speaker review on Chapter 1 clips — fada pairs, full
chapter fidelity, Connacht prompt-steering holds. All-generated scales with the content
pipeline; QA catches drift. ABAIR remains the quality ceiling and a future upgrade
if bundling rights are granted; Azure `ga-IE` is deprioritised unless Gemini quality
regresses on later chapters.

**Consequences:** U5 closed for Phase 2. Audio pipeline: script → generate → native
speaker QA → bundle in chapter packs. `tools/tts-bakeoff/` is the generation/QA
tooling path. ABAIR enquiry continues as optional long-term dialect fidelity, not a
blocker.

## D6 — Retention rituals: An Féilire (2026-07-05)

**Decision:** The retention stack is **narrative pull + gentle ritual**, not
gamification. Validated pull mechanisms: **tá tú ar ais** return greeting and the
**journey map** (An Turas). Other Phase 1 mechanics — recarve pages, amárach hooks,
Ar Ais visits — drew no negative feedback but went unmentioned; they stay in the
product as authored chapter devices, not as the global retention engine. The missing
flywheel is **An Féilire**: rituals borrowed from the real Irish calendar — daily
seanfhocal, seasonal beats keyed to Lúnasa and Samhain, launch moments aligned with
Seachtain na Gaeilge and the diaspora calendar. Gentle structure without manufactured
guilt.

**Why:** Playtest confirmed connection pulls people back; testers also need *some*
daily reason to open the app that isn't a streak. Ireland already has a calendar;
borrowing it keeps ritual authentic rather than manipulative.

**Consequences:** U3 substantially closed. An Féilire is Phase 3/4 product work but
Phase 2 content should tag calendar-tied material where natural. Recarve/Ar Ais remain
per-chapter authored tools, not deprecated.

## D5 — Phase 1 exit; enter Phase 2 (2026-07-05)

**Decision:** Phase 1 vertical slice criteria are met. Move to **Phase 2 — the content
pipeline**. Chapter 2 (*Oileán na Naomh*) is the pipeline proof.

**Why:** Early playtest feedback is strongly positive on the core thesis:
- Re-learners feel respected (D1 promise holds).
- The grammar ladder feels intentional (SPINE.md payload reads as designed, not accidental).
- The journey map answers "where is this going?"
- Testers return without streaks; **tá tú ar ais** and the journey map are the
  mechanisms they name.

**Consequences:** Phase 2 work begins: editorial board, CMS review layer, Chapter 2
authored through the pipeline, audio and illustration at production recipe. Phase 1
experiments (HTML prototype, bake-offs, illustration funnel) are frozen as reference.

## D4 — Canonical Illustration Style: Solas an Atlantaigh (2026-07-05)

**Decision:** Solas an Atlantaigh (B4 — Atlantic Light, Gouache/Watercolor style) is selected as the winning style direction for Chapter 1 and the baseline for subsequent content production.

**Why:** It scored exceptionally high in emotional and narrative pull. The gouache/watercolor medium captures the moody west-of-Ireland light and windy Atlantic atmosphere perfectly, creating an immersive scene window. The Jack B. Yeats-inspired character focus delivers high warmth without slipping into historical kitsch.

**Consequences:** 
1. The style bible is documented in Section 10 of `docs/ILLUSTRATIONS.md`.
2. Scene assets are moved into the app's default resources under `art/`.
3. `Models.swift` and `chapter1.json` are modified to support parsing and loading pages with custom image keys directly.
4. Clean register styling is maintained—illustration is kept strictly as a window for
   **scene pages** (D8); note and exercise views remain clean and typographic.

## D3 — Prototype platform: SwiftUI (2026-07-04)

**Decision:** The HTML vertical slice validated the basic mechanics, design taste,
and flow. Further validation requires native feel — the prototype moves to SwiftUI.

**Why:** Retention and "does it feel cared-for" judgments can't be trusted from a
browser page; the product is an iOS app and testers should hold the real thing.

**Consequences:** `ios/` hosts an xcodegen-managed SwiftUI app (An Turas). Chapter
content moves to bundled JSON — the first real artifact of the content-as-data
pipeline (STRATEGY.md Phase 2). The HTML prototype (`prototype/index.html`) is
frozen as the design reference; design changes land in Swift from now on.

## D2 — Dialect policy (2026-07-04)

**Decision:** Connacht Irish first. Expand to all three dialects over time. Ulster
Irish is a hard prerequisite for any major Northern Ireland launch.

**Why:** Connacht is the geographic and phonological "middle" of the three, contains
the largest Gaeltacht (Conamara), and maps closely enough to the written standard
(An Caighdeán) that learners can use mainstream references without whiplash. Ulster
is deferred, not demoted: launching in NI with Connacht-only audio would undercut the
cultural care that is our whole brand.

**Consequences:** All chapter audio, phrase choices, and pronunciation guidance use
Connacht forms where dialects diverge (e.g. *Cén chaoi a bhfuil tú?* not *Conas atá
tú?* / *Cad é mar atá tú?*). Content format must tag dialect-variable items from day
one so Ulster/Munster variants can be slotted in later without rewriting chapters.
ABAIR voice evaluation prioritises their Conamara voices.

## D1 — Primary learner persona (2026-07-04)

**Decision:** Primary = school-Irish re-learners (Ireland) + diaspora learners
(US/UK/AUS), treated as one content track since their needs overlap. Northern
Ireland is the cultural north star: we take special editorial care over NI history,
identity, and the cross-community story, ahead of a dedicated NI push.

**Why:** Re-learners are the largest motivated segment (latent knowledge + emotional
stakes); diaspora is the largest paying segment; both respond to the identity/
heritage engine. NI is the fastest-growing revival but demands Ulster dialect and
extra cultural groundwork first (see D2).

**Consequences:** Content assumes zero retained Irish but moves briskly and explains
*why* (re-learners resent being treated as blank slates); heavy use of identity hooks
(names, surnames, placenames, county affiliation); grammar notes explicitly address
"what school never explained". Marketing tone: reclamation, not gamified novelty.
