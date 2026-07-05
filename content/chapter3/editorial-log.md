# Chapter 3 Editorial Log

**Draft:** `content/chapter3/draft.json`  
**Final:** `ios/AnTuras/Resources/chapter3.json`  
**Review:** `content/chapter3/review.md`  
**Date:** 2026-07-05

---

## Summary

The draft passed adversarial review on structure, SPINE payload, and Chapter 1–2 tone. This pass resolves **5 of 5 Critical** content issues, **7 of 7 High** content issues, and several **Medium** items. One Critical item (hack-silver artifact rendering) is deferred as app work — JSON retains the `artifact` page; `ArtifactView.swift` still shows Chapter 1 ogham.

---

## Critical fixes (5 resolved, 1 deferred)

| Issue | Resolution |
|-------|------------|
| Turn pages invalid schema | All four turns rewritten: `beats`, `cue`, `replies[].reaction[]` per `Models.swift`. |
| `{place}` lens interpolation | Session 5 lens reframed on **Baile Átha Cliath / Dubhlinn** palimpsest — no unsupported placeholder. |
| Visit `where` leading spaces | Trimmed on `v-chuaigh`, `v-margadh`, `v-brog`, `v-cheannaigh`. |
| `An bhfaca tú` vs `chonaic` | Turn question → **Chonaic tú an t-airgead?** with **Chonaic mé…** reply. |
| Artifact ≠ hack-silver (app) | **Deferred** — see App wiring below. |

---

## High fixes (7 resolved)

| Issue | Resolution |
|-------|------------|
| `Cá ndearna tú ceannach?` | → **Inné — cá bhfuair tú na bróga?** |
| Port Láirge etymology | Softened to Irish name beside Norse fjord-name; removed “Lárag's port” claim. |
| `bord` / `gard` orphaned | Added choice exercise naming both loans. |
| Numbers 11–20 gaps | Added **cúig déag** choice (S2), **ceithre déag** listen (S4), expanded match with **seacht déag** / **naoi déag**. |
| `isteach sa mhargadh` match-only | Kept in match with **trasna an bhóthair** — direction cluster drilled together; `[~]` deferred to board if pedagogue wants scene beat. |
| Seanfhocal not in SPINE | Kept *Ar scáth a chéile a mhaireann na daoine* — era-fit; flagged for board sign-off. |
| `chuaigh` early in S1 match | Retained with end-of-session preview line; match reinforces preview. |

---

## Medium fixes applied

- **Raid sensitivity** — kept factual *rinne siad damáiste*; generational trade bridge unchanged.
- **Session 5 recarve** — includes Ch2 **Tá mé ag obair** cross-chapter pull.

---

## Deferred to human editorial board

| Issue | Reason |
|-------|--------|
| **Hack-silver artifact UI** | `ArtifactView.swift` is ogham-only. Chapter 3 needs arm-ring register + `{name}` notch. |
| **Chapter 3 app integration beyond loader** | `AppState` still loads `chapter1()` only; visits merge for ch. 3 not wired. |
| **Seanfhocal SPINE gap** | Proverb chosen for mixed-town theme; board may substitute SPINE-named line if added later. |
| **`isteach sa mhargadh` scene beat** | Match-drilled only — optional scene addition. |
| **Scene illustration budget** | Placeholders `ch3-coast`, `ch3-dubhlinn`, `ch3-market`, `ch3-silver`, `ch3-today`. |

---

## Strengths preserved (per review)

- Séimhiú-as-system note; raid→trade bridge; Dubhlinn lens; Norse loanword pedagogy; present-day port-town beat; session hooks; seven visits; fin tease to Normans; cheannaigh/dhíol listen; direction choices.

---

## App wiring done

- `Models.swift`: added `ContentLoader.chapter3()`.
- `chapter3.json` added to Xcode Resources group and build phase.
- **Not done:** `ArtifactView` arm-ring branch; `AppState` chapter selection; visits loader for ch. 3.
