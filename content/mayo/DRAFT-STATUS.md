# Mayo county pack — draft status

*Structurally complete review draft of the nine-chapter Mayo pack, authored against
the approved storyboard (`docs/GRAINNE-STORYBOARD-V2.md`). The draft lives here in
`content/mayo/` so the shipping pack in
`ios/AnTuras/Resources/CountyStories/mayo.grainne-1593.json` (the proven
representative Rockfleet chapter) stays correct and enforced until the external
history, pedagogy, audio, and rights gates close.*

Draft file: `content/mayo/grainne-1593.pack.draft.json`
Validate with: `python3 tools/validate_county_pack.py content/mayo/grainne-1593.pack.draft.json`

## Chapters authored

| # | Chapter | Status |
| --- | --- | --- |
| 1 | Clew Bay and Umhaill (`mayo.clew-bay`) | **draft authored** — introduces *farraige, bá, áit, as* |
| 2 | Marriage, kin, and alliances (`mayo.kin-alliances`) | **review draft authored** — introduces *teaghlach, mac, deartháir, bean* |
| 3 | Rockfleet (`mayo.rockfleet`) | **revised** — introduces only *caisleán*; eight-exercise consolidation chapter |
| 4 | Power at sea (`mayo.power-at-sea`) | **review draft authored** — introduces *long* and reuses the coast words |
| 5 | Bingham closes in (`mayo.bingham-pressure`) | **review draft authored** — introduces *caill* |
| 6 | The road to London (`mayo.road-to-london`) | **review draft authored** — introduces *iarr, téigh, tar* |
| 7 | Gráinne in the record (`mayo.in-the-record`) | **review draft authored** — introduces *ainm, mise* |
| 8 | The royal answer (`mayo.royal-answer`) | **review draft authored** — introduces *freagair, tabhair* |
| 9 | Return and afterlife (`mayo.return-afterlife`) | **review draft authored** — introduces *arís, cósta* and completes the chart |

## Internal assembly result

The draft now records the complete authoring shape:

- nine chapters and 99 authored pages;
- 84.8 estimated Story-mode minutes and 105.5 estimated Learning-mode minutes;
- 38 exercises across all 12 mechanic families, with every enforced distribution
  ratio passing;
- one introduction and a complete ordered lifecycle for each of the 20 headwords;
- D-B and D-C applied to Rockfleet;
- `scope: completeCounty` and `enforceLearningQuality: true`;
- revision 5; and
- a passing offline validator report.

`completeCounty` means the authored data is structurally complete. It does not mean
the copy is specialist-approved, the audio is ready, or the pack is promoted into the
app.

## Open external gates (cannot be closed in-repo)

Historian re-clearance for the Chapter 2 and Chapter 4 chapter-weight claims and the
C04 (Sidney) citation; Irish-language pedagogue review of the expanded exercises;
native-speaker audio QA on every teaching clip; Rockfleet imagery rights. See
`docs/GRAINNE-STORYBOARD-V2.md` (D-F) and the source brief.

The validator currently reports 20 referenced audio resources as not yet bundled.
That is intentional and keeps the native-speaker audio gate visible.

## Promotion checklist (after external review)

1. Apply historian and pedagogue revisions to the review draft.
2. Generate, bundle, and clear every required teaching clip.
3. Clear or replace the Rockfleet imagery.
4. Update the app's representative-chapter opening and completion copy for a complete
   county.
5. Replace the bundled Rockfleet pack with the reviewed county pack and regenerate
   the Xcode project if resources change.
6. Run the full Swift and Python suites, timed walkthroughs, migration and offline
   checks.
7. Inspect both modes on a simulator and physical device in both appearances, at
   accessibility text sizes, with VoiceOver labels, Increased Contrast, and Reduce
   Motion.
