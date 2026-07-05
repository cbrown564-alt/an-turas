# Chapter 2 Editorial Log

**Draft:** `content/chapter2/draft.json`  
**Final:** `ios/AnTuras/Resources/chapter2.json`  
**Review:** `content/chapter2/review.md`  
**Date:** 2026-07-05

---

## Summary

The draft passed adversarial review on structure, tone, and SPINE grammar arc. This pass resolves **7 of 8 Critical** content issues, **11 of 11 High** content issues, and several clear **Medium** fixes. One Critical item (illuminated-initial artifact rendering) is deferred as app work — JSON retains the `artifact` page; `ArtifactView.swift` still shows Chapter 1 ogham.

---

## Critical fixes (7 resolved, 1 deferred)

| Issue | Resolution |
|-------|------------|
| Book of Kells identity claim | Present-day scene reframed: learner's book is *like* surviving gospel manuscripts; Kells named as famous survivor, not as *the* book they finished. |
| Round tower at c. 780 | Removed; boat lands at Shannon bank instead. |
| Pangur / Reichenau anachronism | Historical scene foreshadows scribe-and-cat pairing only; no Reichenau attribution in 780. Full `tá` restored in Irish line. |
| Invented Dáire–Murchadh cousin | Cut; grammar note now: "In the last chapter, Dáire taught you **Is mise**…" |
| `an mil` (ungrammatical) | All instances → **mil** (narration, choice key, visit `v-maith`). |
| Visit `v-chlog` frame/answer mismatch | Frame now: "Dawn light — six by the scriptorium clock." |
| Lens etymology (`Mac Nóis` as saint) | Corrected to meadow of sons of Nós; Ciarán named as founder in `note`. |
| Artifact ≠ illuminated initial (app) | **Deferred** — see App wiring below. |

---

## High fixes (11 resolved)

| Issue | Resolution |
|-------|------------|
| Daily verb list (`Obair` noun among imperatives) | List → *Scríobh. Léigh. Meil. Ith. Codail.*; added **Tá mé ag meilt** and **Tá mé ag codladh**. |
| `Cé tusa?` vs Ch1 `Cé thusa?` | Kept **Cé thusa?** with gloss bridging Connacht *tusa* / Munster *Cé thú?* |
| Visit `sa seomra ndath` | → **i seomra na ndath** |
| Monastic/sky time not drilled | Added choice: **Tá sé tráthnóna** vs morning/clock distractors. |
| Colours `buí`, `bán` orphaned | Added to Session 3 match pairs. |
| Food `bainne`, `im` orphaned | Added to Session 4 match pairs. |
| Dialect tags thin | Expanded on **Tá muid…**, **Cé thusa?**, **An bhfuil tú ag obair?** (existing Connacht tags on *An maith leat* retained). |
| `an psalm` in Irish pair | → **an salm** |
| Elliptical Pangur line | → **agus tá Pangur Bán ag lorg luch** |
| Session 5 missing `hook` | Added Viking tease hook on session object. |
| Listen before proverb taught | Moved `listen` to after abbot scene + `seanfhocal` page. |

---

## Medium fixes applied

- **Matins → Prím** in scriptorium arrival scene (aligns with Session 2 hour note).
- **Murchadh name disambiguation** — one beat clarifies this is a different man, centuries later.
- **Choice distractor** `Tá mé deich` → `Tá sé deich a chlog` (time vs lateness).
- **Liturgical hour names** — note now glosses Prím/Téire/Nóin/Vespers consistently.
- **`Is corcra é` echo gloss** — stresses classification, not personhood.

---

## Deferred to human editorial board

| Issue | Reason |
|-------|--------|
| **Illuminated-initial artifact UI** | `ArtifactView.swift` is ogham-only (~170 lines, share card, hand-carve flow). Chapter 2 needs a distinct register (vellum initial, `{name}`). Straightforward content JSON; non-trivial app feature. |
| **Chapter 2 app integration beyond loader** | `AppState` still loads `chapter1()` only; visits merge, progress keys, map unlock for ch. 2 need product decision. |
| **Full D2 dialect tagging pass** | Partial improvement; board may want systematic audit of `a sé a chlog`, all food/time items. |
| **Numbers 1–10 exercise coverage** | Scene lists all ten; match/recarve drill subset — acceptable spacing per review, but *aon/dó/trí/ceithre/naoi* never exercised. |
| **Scene illustration budget** | Seven text-only scene beats remain valid (D8); art pass can add `ch2-*` images to high-value beats. |
| **`typein` density** | Two fada typeins retained; optional **`Is maith liom …`** typein left to pedagogue. |
| **Visit location `san refectóir`** | Low pedagogue nit; kept as draft. |

---

## Remaining known gaps

1. **Payload coverage:** Daily routine verbs now include *meilt* and *codladh* in speech; *madainn* appears in note pairs but only *tráthnóna* is choice-drilled (not *madainn* / *meán lae* individually).
2. **Artifact page** in JSON is schema-valid but renders Ch1 ogham until app work lands.
3. **Visits** remain authored in `chapter2.json`; `ContentLoader.visits()` still reads chapter 1 only — ch. 2 Ar Ais not wired.
4. **Recarve `Is mise`** without `{name}` still relies on Ch1 name capture (same as draft).

---

## Strengths preserved (per review)

- Tá vs *is mise* through-line, narrative voice, progressive-before-habitual order, ink-colour material culture, *is maith liom* pedagogy, seanfhocal landing, session hooks 1–4, seven visits, fin tease to Vikings, exercise design (glas/gorm, listen minimal pairs, VSO assemble).

---

## App wiring done

- `Models.swift`: added `ContentLoader.chapter2()`.
- `chapter2.json` added to Xcode `Resources` group and build phase.
- **Not done:** `ArtifactView` chapter-2 branch; `AppState` chapter selection; visits loader for ch. 2.
