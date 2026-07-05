# Chapter 3 Adversarial Review

## Verdict

**PASS WITH REVISIONS** — The draft delivers the SPINE past-tense arc, Dubhlinn setting, Norse loanword payload, and Chapter 1–2 literary register. It cannot ship without editor fixes on **turn page schema**, visit location strings, `{place}` interpolation, and several orphaned-vocab gaps. Pipeline gap: `artifact` page still renders Chapter 1 ogham in `ArtifactView.swift`, not hack-silver arm-ring.

---

## Critical (must fix before ship)

- **Turn pages use invalid schema (Sessions 1–4).** Draft uses `context` / `prompt` / top-level `s` / `who` on `type: turn`. `Models.swift` expects `beats`, `cue`, and `replies[].reaction[]`. All four turn blocks will fail decode until rewritten.

- **`{place}` in Session 5 lens (invalid interpolation).** Only `{name}` is supported in `TurnView.swift` / content pipeline. `{place}` will render literally or break lens display. Reframe lens on a fixed town pair (e.g. Baile Átha Cliath / Dubhlinn) or prose-only present-day beat.

- **Visit `where` strings with leading spaces (`v-chuaigh`, `v-margadh`, `v-brog`, `v-cheannaigh`).** Frame/location must match scene sluglines; leading spaces are sloppy and may surface in UI.

- **Past question `An bhfaca tú` vs taught `chonaic` (Session 4 turn).** Learners drilled **Chonaic mé**; turn question used **An bhfaca tú** without bridge. Pedagogue will flag dialect/register mismatch at A1. Align question to **Chonaic tú…?** or gloss the pair explicitly.

- **Artifact page ≠ Chapter 3 artifact (Session 5 + pipeline).** JSON closes with `{ "type": "artifact" }`; journey promises **Fáinne airgid / Viking hack-silver** (`glyph: armring`). `ArtifactView.swift` is ogham-only. Blocker for integrated QA, not JSON schema.

---

## High (should fix)

- **`Cá ndearna tú ceannach?` (Session 3 turn).** Unnatural Irish for “where did you buy?” Replace with **Cá bhfuair tú na bróga?** or similar attested question.

- **Port Láirge etymology “Lárag's port” (Session 4 note).** Historically disputed; Norse fjord-name sits beside Irish **Port Láirge**. Soften to “Irish name for Waterford, beside the Norse fjord-name.”

- **`bord` and `gard` orphaned (Session 3).** Listed in note/match but never in scene speech or dedicated exercise. Add choice or scene beat.

- **Numbers 11–20 unevenly drilled.** Scene/note list full range; listen hits *trí déag*, typein *aon déag*, choice/listen cover *ceithre déag* / *fiche*; **cúig déag**, **seacht déag**, **naoi déag** under-tested. Add at least one exercise or flag `[~]`.

- **Direction `isteach sa mhargadh` (Session 2 match).** Appears in match only — not in note pairs or scene. Teach or cut.

- **Seanfhocal not named in SPINE.** Closing sequence requires seanfhocal page; draft uses *Ar scáth a chéile a mhaireann na daoine* — era-appropriate but board must approve choice. Document in editorial log.

- **`chuaigh` in Session 1 match before Session 2 teaching.** Preview line at session end helps; match still tests *chuaigh* early. Acceptable if editor adds gloss “you'll walk tomorrow” — or move *chuaigh* match to Session 2 recarve intro.

---

## Medium (editor's call)

- **Raid scene sensitivity (Session 1).** “Rinne siad damáiste” is restrained; present-day assimilation theme lands well. Board may want one beat acknowledging victims by name — not a content blocker.

- **Two lens pages (Sessions 2 and 5).** Dubhlinn + port-town palimpsest — rich but dense. Consider merging town-decode into present-day scene if illustration budget is tight.

- **Sigur as Norse name without `{name}` personalization.** Fine for prototype; arm-ring scene uses `{name}` — good balance.

- **Recarve pulls Ch2 `Tá mé ag obair` (Session 5).** Nice cross-chapter bridge; visit loader still reads chapter 1 only — log as app deferral.

- **Longphort** in present-day narration — not in payload; acceptable as English/Irish gloss in beat prose.

---

## Low / nit

- **Speech beats missing `who`** on some choral lines (number lists, market noise).

- **Bran the hound** — comic potential underused after Session 1.

- **Pronunciation `dum` for *dom* in *an fáinne dom* — minor PH scheme variance.

- **Visit `v-deis` tests command `Téigh ar dheis`** — frame says “give the command back”; good pedagogy, slightly meta.

---

## Strengths (keep these)

- **Séimhiú-as-system grammar note** — ties *chonaic / tháinig / chuaigh* together; SPINE order respected.

- **Raid → trade generational bridge** — honours hook without glorifying violence; market creole theme strong.

- **Dubhlinn lens** — dubh + linn correct; Baile Átha Cliath coexistence note is historian-safe.

- **Norse loanword note** — “words wearing Irish grammar” (*cheannaigh mé bróga*) — best line in the draft.

- **Present-day beat** — Dublin/Waterford/Wexford/Limerick, *margadh/pingin/bróg/brogue* chain — SPINE-quality.

- **Session hooks 1–4** chain directions → market → silver → Normans cleanly.

- **Seven visits**, sessions 0–4, `check: exact` throughout — schema-aligned once Irish fixes land.

- **Fin tease to Normans** — *tá … agam* forward pull matches SPINE Ch4.

- **Exercise design:** *cheannaigh* vs *dhíol* listen; direction left/right choice; assemble *Tháinig na longa ó thuaidh*.

---

## Payload coverage checklist

- [x] past tense — regular + irregulars (*chuaigh, tháinig, rinne, chonaic*)
- [x] directions and movement
- [x] trade / market vocabulary
- [~] money and numbers 11–20 — taught; 15–17–19 under-drilled before editor pass
- [x] Norse loanwords (*margadh*, *pingin*, *bróg* + *bord*, *gard*)
- [x] founding of port towns — note + present-day
- [x] séimhiú grammar note (past-tense system)
- [~] seanfhocal — present (*Ar scáth a chéile…*) but not named in SPINE
- [x] artifact concept (hack-silver arm-ring + town decode)
- [x] present-day beat (Dublin, Waterford, Wexford, Limerick)

---

## App / pipeline gaps (separate from content)

- `ArtifactView.swift` — no arm-ring / hack-silver register
- `ContentLoader.chapter3()` — required for merge
- `ContentLoader.visits()` — still chapter 1 only; ch. 3 visits not wired
- `AppState` — still loads `chapter1()` only
- Scene images `ch3-*` — placeholders only (D8)
