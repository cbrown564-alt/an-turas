# Mayo county pack — draft status

*Structurally complete revision-7 pre-clearance draft of the nine-chapter Mayo pack,
authored against
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
| 1 | Clew Bay and Umhaill (`mayo.clew-bay`) | **draft authored** — *farraige, bá, áit, as*; opening `video.mayo-clew-bay-tide-loop` |
| 2 | Marriage, kin, and alliances (`mayo.kin-alliances`) | **review draft authored** — *teaghlach, mac, deartháir, bean*; opening visual queued (D28) |
| 3 | Rockfleet (`mayo.rockfleet`) | **revised** — only *caisleán*; opening `video.mayo-rockfleet-sea-surge` |
| 4 | Power at sea (`mayo.power-at-sea`) | **review draft authored** — *long*; still `image.mayo-galway-bay-trading` pending Flow |
| 5 | Bingham closes in (`mayo.bingham-pressure`) | **review draft authored** — *caill*; still `image.mayo-tudor-pressure` pending Flow |
| 6 | The road to London (`mayo.road-to-london`) | **review draft authored** — *iarr, téigh, tar*; opening `video.mayo-galley-sea-passage` |
| 7 | Gráinne in the record (`mayo.in-the-record`) | **review draft authored** — *ainm, mise*; documentary `image.sp63-170` |
| 8 | The royal answer (`mayo.royal-answer`) | **review draft authored** — *freagair, tabhair*; still `image.mayo-royal-court-interior` pending Flow |
| 9 | Return and afterlife (`mayo.return-afterlife`) | **review draft authored** — *arís, cósta*; interim coastal still pending return loop |

## Internal assembly result

The draft now records the complete authoring shape:

- nine chapters and 100 authored pages;
- 86.2 estimated Story-mode minutes and 104.1 estimated Learning-mode minutes;
- 38 exercises across all 12 mechanic families, with every enforced distribution
  ratio passing;
- one introduction and a complete ordered lifecycle for each of the 20 headwords;
- D-B and D-C applied to Rockfleet;
- `scope: completeCounty` and `enforceLearningQuality: true`;
- revision 7 (revision 6 historical fixes retained; revision 7 wires D28 chapter-opening
  visuals without changing historical claims); and
- a passing offline validator report.

Revision 6 applied the July historical review's reversible fixes before external
clearance: the candidate Carew MS 601 / SP 12/159 trail is attached to C04 while
historian confirmation remains open; the Sidney beat is Story-only until that
confirmation; C02's archive bias now appears in a bounded closer look; Chapter 2 and
4 wording is tightened; C06, C10, C14, and C15 resource statuses now match their
actual review scope; and stale representative-chapter copy is removed. Revision 7 does
not close `history.expanded`, approve release prose, or promote the pack into the app.

`completeCounty` means the authored data is structurally complete. It does not mean
the copy is specialist-approved, the audio is ready, or the pack is promoted into the
app.

## Open external gates (cannot be closed in-repo)

Historian re-clearance for the Chapter 2 and Chapter 4 chapter-weight claims and the
C04 (Sidney) citation; under D24, a newly named historian may own the Chapter 2 and
Chapter 4 disposition while an archival specialist separately confirms the C04 folio
and diplomatic wording. The same qualified person may perform both parts, but
`history.expanded` stays open until both dispositions are recorded. Each review record
must identify its revision or sources, scope, date, requested changes, and final
disposition. Qualification is evidence-based under D24: relevant historical or
primary-source work for the chapter reviewer, and relevant early-modern manuscript,
State Paper, or diplomatic-transcription work for the archival reviewer; academic
titles and institutional affiliation are not required. Paid review is allowed with
internal disclosure, but nobody may solely approve material they authored; overlapping
contribution and
review scope requires a second qualified independent disposition. With consent,
public provenance may show reviewer name, scope, and completion date; payment,
contact, working notes, qualification evidence, and conflict records remain internal.
If naming consent is withheld, the gate may still close when the internal record is
complete; public provenance then shows qualified role, scope, and date without a name.
After approval, changes to historical claims, attribution, certainty, names,
quotations, transcriptions, or evidence explanations reopen only the affected
disposition. Non-semantic spelling, punctuation, layout, accessibility-label, and
unrelated exercise changes do not.
Historical approval does not expire by date. Material new primary evidence, a
significant scholarly correction, or a credible challenge reopens the affected
disposition.
If qualified reviewers disagree, the affected disposition remains open until they
accept a conservative shared formulation or a third qualified disposition resolves
it. The product owner cannot convert an unresolved dispute into settled release copy.
The remaining external gates are Irish-language pedagogue review of the expanded
exercises, native-speaker audio QA on every teaching clip, and Rockfleet imagery
rights. See
`docs/GRAINNE-STORYBOARD-V2.md` (D-F) and the source brief. The July 2026 research
packet that prepares that historian pass is in
`docs/mayo-historical-review/` (start with
`00-analysis-and-recommendations.md`): C04 is pin-able from Sidney’s 1582/3 memoir;
Ch2 and Ch4 are conditionally clear at chapter weight with light copy binds.

The validator currently reports 20 referenced audio resources as not yet bundled.
That is intentional and keeps the native-speaker audio gate visible.

## Promotion checklist (after external review)

1. Give revision 6 to the historian and pedagogue; apply their revisions without
   closing a gate until the named reviewer has approved the resulting copy.
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
