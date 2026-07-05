# Chapter 2 Adversarial Review

## Verdict

**PASS WITH REVISIONS** — The draft hits the SPINE grammar arc, session shape, and Chapter 1 literary register. It is not a structural rewrite. It **cannot** ship without historian sign-off on the present-day beat and three in-scene anachronisms, pedagogue fixes on several Irish lines, and one visits frame/answer contradiction. Pipeline gap: the `artifact` page still renders Chapter 1 ogham in `ArtifactView.swift`, not an illuminated initial.

---

## Critical (must fix before ship)

- **Book of Kells identity claim (Session 5, present-day scene).** Narration says the gospel the learner helped finish “lives under glass in Dublin: the Book of Kells.” Clonmacnoise produced manuscripts; it did not produce *that* book. Tradition links the Book of Kells to Columban houses (Iona → Kells), not the Shannon scriptorium in this story. Reframe: “a book like the one that would become the Book of Kells” or “gospel books from this age — including the Book of Kells — still shout corcra and gorm under glass.” As written, a historian rejects the chapter.

- **Round tower at c. 780 AD (Session 2, scene).** “a boat land below the round tower” — Clonmacnoise’s round tower is dated ~1124 CE. No round tower stood there in the subtitle era (~780). Delete the tower or replace with a feature that existed (early wooden buildings, the Shannon landing, a cross slab).

- **Pangur Bán / Reichenau timeline (Session 4, scene).** Cillín “copies a poem … an Irish monk once wrote at Reichenau.” The *Pangur Bán* poem is 9th-century; Reichenau/St-Paul manuscript tradition postdates this scene’s ~780 setting. You can foreshadow the poem’s *idea* (cat and scribe) without attributing the Reichenau copy to “once wrote at Reichenau” in the present tense of 780. Present-day beat correctly separates cat from poem — historical scene must match.

- **Invented continuity: “Murchadh's distant cousin Dáire” (Session 1, grammar note).** Chapter 1 never mentions Murchadh. Dáire has no stated kinship. The opening scene already bridges eras (“from Dáire's stone yard”). The cousin line is fabricated and will read as a bug to anyone who just played Chapter 1. Cut the cousin; keep “Dáire taught you **Is mise** in the last chapter.”

- **`an mil` — ungrammatical honey (Session 4 + visits).** Repeated in narration (“**Is maith liom an mil**”), choice answer key (`Ní maith liom an mil`), and visit `v-maith` (`Is maith liom an mil`). Honey is *mil* (f.); the natural like-pattern is **Is maith liom mil** (no article), parallel to **Is maith liom bainne** in the same note. A pedagogue will flag every instance.

- **Visit `v-chlog` frame contradicts answer (visits).** Frame: “The sun is at **mid-morning**.” Expected answer: **`Tá sé a sé a chlog`** (“six o'clock”). Either change the frame to dawn/six o'clock or change the answer to a mid-morning phrase (and teach it first — currently only `Tá sé moch sa mhaidin` appears in a note pair, with no `:00` mid-morning clock form).

- **Lens etymology error (Session 2, `lens`).** `Mac Nóis` glossed as “son of Nós — **the saint who founded this place**.” Cluain Mhic Nóis = meadow of the sons of Nós; the founding figure associated with the site is **Ciarán**, not “Mac Nóis” as a saint-name. Fix the `parts[].en` strings and the `meaning` line before this ships as a placename lesson.

- **Artifact page ≠ Chapter 2 artifact (Session 5 + pipeline).** JSON closes with `{ "type": "artifact" }` (correct schema), but `ArtifactView.swift` is still “Do chloch féin — your own stone” / ogham only. Journey promises **Litir mhaisithe / your initial, illuminated**. Content assumes `{name}` interpolation on the initial in Session 5 scene copy; the app does not render it yet. Blocker for integrated QA, not for JSON schema alone.

---

## High (should fix)

- **Daily verb inventory mixes word classes (Session 1, scene).** `Scríobh. Léigh. Meilt. Ith. Codail. Obair.` — *Obair* is a noun (“work”), not an imperative parallel to *Codail* / *Ith*. Outline lists *codladh*; scene never gives **Tá mé ag codladh** or **ag obair** as a taught line (only *Tá mé ag obair* in exercises). Align the list (imperatives *Scríobh, Léigh, Meil, Ith, Codail* + teach **obair** as noun) or teach **Tá mé ag meilt / ag codladh** to match SPINE “daily routine verbs.”

- **`Cé tusa?` vs Chapter 1 `Cé thusa?` (Session 1, turn).** Chapter 1 established **Cé thusa?** with pronunciation `kay HUSS-ah`. Chapter 2 switches to **Cé tusa?** (`kay TUSS-ah`) with a dialect gloss — valid Connacht, but unexplained pivot from the phrase the learner just drilled. Either tag Chapter 1 retroactively, bridge explicitly (“same question, slightly different shape”), or stay on *thusa* until dialect chapter.

- **Ungrammatical visit location `sa seomra ndath` (`v-corcra`).** Scene place is **Seomra na ndath**; visit has **sa seomra ndath** (missing *na*, wrong mutation pattern). Should be **i seomra na ndath** / **sa seomra na ndath** — match the scene slug.

- **Monastic / sky time vocab introduced, not drilled (Session 2, note).** Paras teach **Madainn, Meán lae, Tráthnóna** and liturgical **Prím, Téire, Nóin**; pairs drill different phrases (`Tá sé moch sa mhaidin`, `Tá sé in am lóin`, `Tá sé déanach`). SPINE promises “telling time by the monastic hours” — currently one clock exercise (`Tá sé a trí a chlog`), one listen (*cúig*), no exercise touches *madainn* / *tráthnóna* / hour names. Add at least one choice or match, or downgrade the prose claim.

- **Colours `buí` and `bán` orphaned (Session 3).** Spoken in scene (`Corcra. Gorm. Dearg. Buí. Dubh. Bán.`) but absent from match (only corcra, gorm, dearg, dubh). Listen/choice cover gorm/glas and dearg/dubh/bán — *buí* never tested.

- **Food `bainne` and `im` orphaned (Session 4).** Note pairs list six foods; match tests four (no bainne, no im). Visit tests honey only. Weak for SPINE “food” payload.

- **Dialect tags (D2) too thin.** Only three glosses tag Connacht/Munster/Ulster (`Cé tusa?`, `An maith leat…`, and a vague VSO question footnote). Variable items like **`Tá muid`** (vs Munster *Tá muid* / Ulster *Tá muid* same spelling but different pronunciation), **`a sé a chlog`**, **`Cé tusa?` vs `Cé thú?`** on Murchadh’s first line — inconsistent with DECISIONS D2 “tag dialect-variable items from day one.”

- **English residue inside Irish (Session 3, grammar note pair).** `Léann Cillín an psalm.` — *psalm* is English/Latin in an Irish sentence. Use **an salm** or **an tslálm** in a pedagogy-facing pair.

- **Elliptical Irish presented as model (Session 4, scene).** `Tá mé ag lorg rudaí — agus Pangur Bán ag lorg luch.` Second clause drops **tá**; fine in literary English narration, risky as the chapter’s only Pangur line for A1 learners. Prefer **agus tá Pangur Bán ag lorg luch** or keep the ellipsis only in English narration.

- **Session 5 missing `hook`.** Sessions 1–4 carry amárach teases; Session 5 (finale) has none. Outline expects fin tease to Chapter 3 — put it on the session (`hook`) or ensure `fin` alone carries it (fin does tease Vikings; session-level hook is still absent vs schema pattern in S1–4).

- **Listen exercise before seanfhocal scene (Session 5).** `listen` asks learners to identify **`Ní neart go cur le chéile`** before the abbot speaks it in the following scene. Framing says “you'll meet it properly in a moment” — acceptable only if listen is ungraded ear-priming; still harsh for A1. Consider moving listen after the seanfhocal page or swapping with a phrase already taught in-session.

---

## Medium (editor's call)

- **Seven scene pages without `image` (Sessions 1–5).** D8 allows it; Chapter 1 also omits images on some beats. Here, high-value moments (Lauds bell, pigment boat arrival, abbot entry, refectory without cat image until later) are text-only. Not invalid — but illustration budget (`ch2-dawn`, `ch2-scriptorium`, `ch2-inks`, `ch2-cat`, `ch2-today`) underuses the Solas an Atlantaigh window.

- **Grammar note mixes Latin/English hour names (Session 2).** **Prím, Téire, Nóin, Vespers** — three Irish/ Latin and one English. Pick one register (Irish + gloss, or all English with Irish daily words separate).

- **Numbers 1–10: display vs drill gap (Session 2).** Full choral list in scene (`Aon… deich`); match tests four numerals. Recarve pulls *seacht* and *deich* — acceptable spacing, but *aon, dó, trí, ceithre, naoi* never appear in exercises.

- **Copula colour sentence may scramble tá/is consolidation (Session 3, echo).** `Is corcra é` taught as “identity again, for the ink” — clever, but arrives the same session as habitual **Scríobhann** / **Léann** and right after Session 1’s hard-won tá/is split. Consider a gloss that stresses classification (“purple is what it is”) not personhood.

- **Murchadh reuse of name.** Same given name as the master scribe after Dáire in Chapter 1 — not wrong, but learners may think it is the same character. One line of disambiguation (“another Murchadh, centuries later”) would help.

- **Present-day Pangur beat is good; historical scene overshoots.** The closing prose (“not the cat, but the poem”) is SPINE-quality. Trim the historical scene so it does not pre-copy the manuscript tradition.

- **`typein` density low.** Two fada typeins (Sessions 2 and 5) vs Chapter 1’s name capture + multiple exact checks. Fine if intentional — re-learners may want one **`Is maith liom …`** typein.

- **Recarve `Is mise` without `{name}` (Session 2).** Matches visit pattern from Chapter 1 — OK — but Session 5 assemble uses **`Is mise {name}`** without a preceding capture typein in this chapter (relies on Chapter 1 name in app state).

- **Choice distractor `Tá mé deich` (Session 2).** “I am ten” — funny, but confuses number-as-attribute before numbers are fully drilled. Keep or swap for **`Tá sé deich a chlog`** as the time distractor.

---

## Low / nit

- **English liturgy in Irish dawn (Session 1).** “expecting you since **Matins**” — later note uses **Prím**. Pick Irish or gloss on first use.

- **Speech beats missing `who` (Sessions 1–4).** `Tá mé ag scríobh`, number chains, colour list, `Tá bainne ann freisin` — schema-legal; Chapter 1 usually attributes lines. UI may look bare.

- **Pronunciation `melj` for *Meilt* (Session 1).** Minor; *melj* or *mel*t — consistent with informal PH scheme elsewhere.

- **Visit `san refectóir`.** Acceptable if the app treats *refectóir* as `an refectóir`; slightly Hiberno-Latin. Consider **sa refectóir** / **san refhactóir** if a pedagogue fusses.

- **Hook Session 1** promises pages remaining (quire count) — Session 2 delivers numbers but never “pages remain” phrasing. Minor tease payoff gap.

- **Inscription `INITIUM` (Session 3).** Nice manuscript beat; Latin not Irish — fine as inscription register (Chapter 1 uses Latin ogham name).

- **`gloss` on `An bhfuil tú ag obair?` note (Session 1).** Claims Munster “often says” the same sentence — true orthographically, low pedagogical value; Ulster deferral is hand-wavy.

---

## Strengths (keep these)

- **Tá vs is mise** through-line is the clearest grammar spine since Chapter 1 — note, choices, turn, recarves, and Session 5 assemble all reinforce without mush (`Tá mé Cillín` / `Is mise ag obair` distractors are well chosen).

- **Narrative voice** matches Chapter 1 warmth: bells, vellum, ink horns, “the living present,” Murchadh counting quires with his eyes — editorial tone is on-brand.

- **Progressive present taught the right way first** — `Tá mé ag scríobh/obair/léamh` before habitual `Scríobhann/Léann/Itheann` in Session 3 note; SPINE order respected.

- **Ink colours tied to material culture** — corcra/lichen, gorm/woad, dearg/minium, dubh/iron gall — not a generic colour worksheet.

- ***Is maith liom / Ní maith liom*** note explains copula “good with me” without school jargon; turn at the refectory table is socially motivated.

- **Seanfhocal landing** — abbot speaks **`Ní neart go cur le chéile`**, dedicated `seanfhocal` page, museum callback to Dáire’s proverb — correct Chapter 2 closing grammar.

- **Session hooks 1–4** chain pigments → fast day → abbot visit cleanly; recarve intros wear scriptorium clothes (SPINE rule 6).

- **Visits count and session indexing** — seven visits, sessions 0–4, `check: exact` throughout — schema-aligned with `Models.swift` (modulo Irish fixes above).

- **Fin tease to Chapter 3** — past tense, Dubhlinn, Viking Irish — strong forward pull.

- **Exercise design highlights:** `Tá maith liom` vs `Is maith liom` choice; `glas` vs `gorm`; listen minimal pairs (*cúig* vs *ceithre*, *dearg* vs *dubh*); assemble tiles for VSO **`Scríobhann Cillín`**.

---

## Payload coverage checklist

- [x] tá + VSO present tense — Session 1–3 (`Tá mé ag…`, `Scríobhann…`, VSO note)
- [~] daily routine verbs — scríobh/léamh/ithe/obair drilled; **codladh/meilt weak**; imperative list flawed (*Obair* noun)
- [~] time / monastic hours — clock **`Tá sé a … a chlog`** + note; **Prím/madainn/tráthnóna not exercised**
- [~] numbers 1–10 — full scene list; **partial match/recarve only**
- [~] colours (inks) — six spoken; **four matched; buí/bán under-drilled**
- [~] food — six in note; **four matched; bainne/im not tested**
- [x] is maith liom / ní maith liom — Session 4 note, choices, assemble, turn, match (fix **`an mil`**)
- [x] VSO grammar note — Sessions 1 and 3
- [x] tá vs is mise note — Session 1 (remove false cousin line)
- [x] seanfhocal Ní neart go cur le chéile — Session 5
- [~] illuminated initial artifact — **in narrative + JSON page; app still ogham**
- [~] present-day Kells + Pangur beat — **present-day prose good; historical identity/over-specific attribution must be fixed**

---

*Reviewer: adversarial pass against `outline.md`, `chapter1.json`, `Models.swift`, `SPINE.md`, `DECISIONS.md` (D2, D8, D11). JSON parses; page types decode; images only on `scene` pages.*
