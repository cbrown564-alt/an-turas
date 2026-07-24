# Mayo county pack — draft status

*Working draft of the nine-chapter Mayo pack, authored against the approved
storyboard (`docs/GRAINNE-STORYBOARD-V2.md`). The draft lives here in `content/mayo/`
so the shipping pack in `ios/AnTuras/Resources/CountyStories/mayo.grainne-1593.json`
(the proven representative Rockfleet chapter) stays correct and enforced while the
county is assembled. The draft is swapped into `Resources` only when complete.*

Draft file: `content/mayo/grainne-1593.pack.draft.json`
Validate with: `python3 tools/validate_county_pack.py content/mayo/grainne-1593.pack.draft.json`

## Chapters authored

| # | Chapter | Status |
| --- | --- | --- |
| 1 | Clew Bay and Umhaill (`mayo.clew-bay`) | **draft authored** — introduces *farraige, bá, áit, as* |
| 2 | Marriage, kin, and alliances | not started |
| 3 | Rockfleet (`mayo.rockfleet`) | proven chapter carried in from the shipping pack; D-B/D-C not yet applied |
| 4 | Power at sea | not started |
| 5 | Bingham closes in | not started |
| 6 | The road to London | not started |
| 7 | Gráinne in the record | not started |
| 8 | The royal answer | not started |
| 9 | Return and afterlife | not started |

## Deliberately deferred until the county is complete

These are correct-to-defer, not oversights:

- **`enforceLearningQuality` is `false`** in the draft. A partial pack cannot meet the
  full-county exercise-distribution ratios (e.g. single-word listen-and-pick reads 13%
  with only 15 exercises but must land ≤10% across the finished ~38). Re-enable at
  assembly.
- **D-B (Rockfleet word reassignment)** is not yet applied. Chapter 3 still *introduces*
  *teaghlach/mac/bean*; once Chapter 2 introduces them, Chapter 3 becomes their reuse
  site and its `introducedLexemeIDs` + lifecycle change.
- **D-C (Rockfleet exercise trim 12→~8)** happens during distribution rebalancing so the
  county lands in the 30–45 band with legal ratios.
- **The 20-word lifecycle table** still holds only the 2 proven entries. It is filled to
  all 20 at the end, when every reuse chapter exists (cross-chapter reuse for Ch1–6
  words; delayed retrieval + chart/review for Ch7–9 words, per D-E).
- **`scope` stays `representativeChapter`** until all nine chapters and 20 lifecycles
  exist, then flips to `completeCounty` (which turns on the all-20 lifecycle check).
- **Audio** for new chapters is marked `pending-native-qa` and shows as unbundled in the
  validator report — accurate; native-speaker QA is an open external gate.

## Open external gates (cannot be closed in-repo)

Historian re-clearance for the Chapter 2 and Chapter 4 chapter-weight claims and the
C04 (Sidney) citation; Irish-language pedagogue review of the expanded exercises;
native-speaker audio QA on every teaching clip; Rockfleet imagery rights. See
`docs/GRAINNE-STORYBOARD-V2.md` (D-F) and the source brief.

## Assembly checklist (final step before swap)

1. All nine chapters authored; narrative + exercises complete.
2. Apply D-B and D-C to Chapter 3.
3. Rebalance exercises to 30–45 with legal distribution; re-enable `enforceLearningQuality`.
4. Author the full 20-word lifecycle table.
5. Flip `scope` to `completeCounty`; validator must pass with all rules on.
6. Bump `revision`; swap draft into `ios/AnTuras/Resources/CountyStories/`.
7. Run the full simulator + Python suites; verify on a physical device and at
   accessibility sizes.
