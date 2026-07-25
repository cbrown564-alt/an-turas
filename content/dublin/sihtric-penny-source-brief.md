# Dublin source brief — Sihtric's first Irish penny c. 997

*Historian-ready packet · started 12 July 2026 · status: **research draft, not
cleared**. Replaces the inherited Chapter 3 795–900 raid-to-market composite (D13).*

## Phase 5 pre-clearance draft — 24 July 2026

`sihtric-penny.pack.draft.json` now applies the complete Mayo authoring pattern and
is bundled in the app as review-only content:

- six chapters and 68 stable pages, with variable chapter lengths;
- a 49.4-minute estimated Story path and a causally complete 67.2-minute Learning
  path projected from the same pages;
- 30 exercises across all 12 mechanic families;
- one introduction, heard use, active production and later reuse for each of the 20
  provisional headwords; and
- object-specific work on port context, mint motive, hammered manufacture,
  obverse/reverse reading, legend expansion and the Glendalough findspot.

The draft passes `tools/validate_county_pack.py` with `scope: completeCounty` and
learning-quality enforcement enabled. `completeCounty` describes the authored data,
not specialist clearance. The app labels the full pack **Review draft** and keeps
county gold, the made object and word scheduling locked until the numismatist,
historian, pedagogy, native-speaker audio and rights gates below close.

The six chapters are:

1. *The port before the mint*
2. *A named king*
3. *Why a mint?*
4. *The first penny*
5. *Read the legend*
6. *The penny travels*

The expanded draft is anchored to the National Museum of Ireland's
[Silver penny of SITRIC REX DUBLIN](https://www.museum.ie/en-IE/Collections-Research/Collection/Glendalough-Power%2C-Prayer-Pilgrimage/Artefact/Silver-penny-of-SITRIC-REX-DUBLIN/b1f12cbd-72ce-48a6-9f54-8ec41aaa42ee)
and [earliest Irish coinage overview](https://www.museum.ie/en-IE/collections-research/art-and-industry-collections/art-industry-collections-list/numismatics/airgead-a-thousand-years-of-irish-coins-currency/950-1450-vikings%2C-normans-and-medieval-mints),
with the [British Museum object record](https://www.britishmuseum.org/collection/object/C_1838-0919-8)
as a second museum reference for early type and legend context. A numismatist still
must select the production specimen, lock both-face transcription and classification,
and resolve the learner-facing date convention.

## Phase 3 prototype binding — 14 July 2026

The earlier Phase 3 app contained a four-episode / twelve-beat editorial preview under
`dublin.sihtric-penny`. It proves the reusable county-story flow while keeping the
learner-facing specimen, legend and mint motive explicitly provisional. It does
**not** change this packet's research-draft status.

The prototype carries twenty provisional headwords: *airgead, pingin, rí, baile,
linn, dubh, long, margadh, ceannaigh, díol, tabhair, tóg, téigh, tar, chuaigh,
tháinig, ainm, cathair, abhainn,* and *trádáil*. A pedagogue and native-speaker audio
reviewer must approve or replace the set and pronunciation guides. The app uses a
rights-safe coin diagram until a numismatist selects the exact specimen and reading.

## Identity

| Field | Value |
| --- | --- |
| County | Baile Átha Cliath / Dublin |
| Proposed story id | `dublin.sihtric-penny` |
| Named anchors | Sihtric Silkbeard (Sitric / SITRIC); Dublin mint; silver penny |
| Organising centre | First coins struck in Ireland, c. 995–997 |
| Significant encounter | Handle/read a penny legend (SITRIC / DYFLIN or equivalent type) |
| Legacy bridge | `chapter3.json` mechanics/progress migrate; composite timeline does not |
| Review state | Editorial research draft |

## Dramatic proposition

> Around 997, Dublin struck the first coins made in Ireland. The king put his name
> and his city on silver. What kind of port needs a mint?

795 raids become bounded prior context—not an enacted fictional victim story that
leaps to a different century's market.

## Significant reading / object encounter

1. **Hiberno-Norse Phase I silver penny** — preferably a type naming Sihtric and
   Dublin / DYFLIN; NMI holds a Glendalough-excavated example labelled minted AD 995.
2. **Design relationship** to Æthelred II Crux-type pennies — imitation as pragmatic
   prestige, not “forgery” lesson for beginners.
3. **City context** — Dubhlinn / Áth Cliath as Norse-Gaelic port, market, and mint
   without a two-century montage.

## Claim ledger

| ID | Claim | Certainty | Support | Notes |
| --- | --- | --- | --- | --- |
| D01 | First locally struck Irish coinage appears in Dublin under Sihtric III Silkbeard c. 995–997 | story | Numismatic consensus; NMI object labels | Prefer “c. 995–997” over a single year unless board locks one |
| D02 | Early issues imitate contemporary Æthelred II types (e.g. Crux) | story | Numismatic literature | Explain as accepted design language |
| D03 | Some coins name Sihtric and Dublin; others mix English royal/moneyer legends | story/close | Phase I corpus | Learner object should be a clear Sihtric/Dublin example if possible |
| D04 | Motives include paying men and displaying royal authority | close | Scholarly inference | Soft on L1 |
| D05 | Sihtric was a Norse king of Dublin with Irish dynastic ties (e.g. Gormlaith traditions) | story/close | Annals + synthesis | Keep family detail light for beginner arc |
| D06 | Dublin was already a significant port/market before the mint | story | Archaeology; historical synthesis | Supports language of buy/sell/move |
| D07 | 795 as first recorded Viking raid on Ireland | story | Annals | Context only; not the flagship dramatic present |
| D08 | Chapter 3 fictional victim → market leap as Sihtric's biography | exclude | Editorial composite | Release |
| D09 | Hack-silver arm-ring as period money practice | story/close | Viking silver economy | Artifact may adapt; must not outrank the penny as evidence centre |

## Provisional 20-word field (pedagogue to lock)

Past, go, come, buy, sell, coin, silver, king, town, river, boat, market, left, right,
north/south as needed, name, city, money, take, give — aligned to D13 language job;
exact weave TBD.

## Rights plan

| Asset | Action |
| --- | --- |
| NMI penny images | Request educational licence or commission measured drawing/obverse-reverse |
| Legend transcription | Historian/numismatist-approved; show expansion clearly |
| British Museum / other pennies | Backup image path if NMI rights lag |
| Map of Dubhlinn | Original atlas drawing preferred |

## Board checklist

- [ ] Numismatist: pick the learner-facing type and legend reading
- [ ] Historian: Sihtric biography bounds for L1
- [ ] Pedagogue: 20-word weave; past-tense spine fit
- [ ] Rights: coin imagery
- [ ] Product: arm-ring artifact retain/adapt vs new mint-related personal artifact
- [ ] Legacy: Chapter 3 raid pages → context or retire

## Reading list

1. NMI artefact page — Silver penny of SITRIC REX DUBLIN
2. NMI Airgead / Hiberno-Norse mint overview
3. Standard Hiberno-Norse Phase I summaries (board to name preferred catalogue)
4. Legacy `content/chapter3/` for salvage only
