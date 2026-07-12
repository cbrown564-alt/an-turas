# Legacy Chapters 1–3 salvage map

*12 July 2026 · inventory before replacement story ids change production content.
Rule: preserve progress and reusable craft; do not protect superseded editorial centres
(D13).*

## Legend

| Tag | Meaning |
| --- | --- |
| **retain** | Keep as-is in the product grammar |
| **adapt** | Keep mechanic/asset; re-author copy or binding |
| **field-note** | Rehome as labelled reconstruction / short encounter |
| **retire** | Do not ship as flagship reality; may remain in git history |

## Chapter 1 → Mayo

| Asset | Tag | Notes |
| --- | --- | --- |
| Story-keyed progress / migration from ch.1 saves | retain | Already migrated toward `mayo.breastagh-stones`; plan second migration to `mayo.grainne-1593` without wiping learners |
| Ogham stroke carver / share card | field-note | Belongs with Breastagh field note, not Gráinne flagship |
| Breastagh inscription reading | field-note | Keep damaged-reading honesty |
| Fictional Dáire / Bríd / widow guides | retire (flagship) / adapt (field-note only if needed) | Must never be presented as Breastagh people |
| *Is mise…* / name / origin language | adapt | Re-earn inside Gráinne weave |
| Recarve / tá tú ar ais | retain | Product grammar |
| Listen / echo / turn / lens primitives | retain | Rebind to new scenes |
| Killala lens | adapt or retire | Mayo geography may shift to Clew Bay / Rockfleet lenses |
| Ar Ais visits tied to fictional guides | adapt | Re-author visits for Gráinne arc people/places/sources |
| Ch.1 scene illustrations (if any) | retire for release | D13: no release art for superseded narrative |
| Gemini TTS for superseded copy | retire | Do not QA for release |

## Chapter 2 → Offaly

| Asset | Tag | Notes |
| --- | --- | --- |
| Clonmacnoise place / Shannon setting | adapt | Keep place; move dramatic present to c. 900 cross |
| Illuminated-initial artifact | adapt | Only if cross/settlement story earns a learner-made initial or related craft object |
| *tá* / daily verbs / time / colour / food | adapt | Re-earn from settlement evidence, not gospel-race fiction |
| Gospel-book race / Book of Kells tease | retire | Explicit D13 release |
| Pangur Bán continuity as headline | retire | Optional later literature field note, not Offaly flagship |
| Invented scribe guides | retire | |
| Pipeline/process docs | retain | `CONTENT-PIPELINE.md` still governs |
| `content/chapter2/` draft/review logs | retain (archive) | Salvage reference only |

## Chapter 3 → Dublin

| Asset | Tag | Notes |
| --- | --- | --- |
| Sihtric as named anchor | adapt | Keep person; centre the penny |
| Hack-silver arm-ring artifact | adapt | Silver economy adjunct; penny is evidence centre |
| Past tense / directions / market language | adapt | Bind to mint/port c. 997 |
| 795 raid enacted via fictional victim | retire | Context entry at most |
| Composite 795→900 market leap as biography | retire | |
| Norse loanword payload | adapt | Keep if earned by port/mint scenes |
| Dubhlinn lens | adapt | Strong keep with new centre |
| `content/chapter3/` logs | retain (archive) | |

## Cross-cutting engineering (all chapters)

| Asset | Tag | Notes |
| --- | --- | --- |
| Page types (scene, note, listen, echo, turn, recarve, lens, exercises) | retain | |
| Haptics / chalk-before-carve / optical centre registers | retain | |
| Multi-chapter progress persistence | adapt | Becomes multi-county / story-id persistence |
| Merged Ar Ais loader | retain | Re-author visit content |
| Journey map / county colours | adapt | D12 semantics; replace 13-chapter framing |
| Museum niches per chapter artifact | adapt | One personal artifact per county arc |
| ContentLoader chapter1–3 wiring | adapt | Toward county packs |
| Debug deep-links | retain | Extend for episode ids |

## Progress migration principles

1. Never delete a learner's completion silently when story ids change.
2. Map `chapter1` / `mayo.breastagh-stones` → Mayo progress bucket; Breastagh completion
   must not auto-gold Mayo after Gráinne becomes flagship.
3. Offaly/Dublin legacy completions remain as prototype badges or migrate to “legacy
   path” until replacement arcs ship.
4. Record migration in AppState with explicit version flag.

## Production sequence implication

Do not rewrite Chapter 2–3 JSON in place. Author replacement county packs from the new
briefs; lift retain/adapt mechanics; leave retired narrative in archive.

## Salvage owners

| Work | Owner |
| --- | --- |
| Mechanic retain/adapt list above | Engineering |
| Copy retire decisions | Editor + historian |
| Language adapt lists | Pedagogue |
| Progress migration design | Engineering (before Gráinne JSON ships) |
