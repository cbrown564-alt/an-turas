# Spot-listen queue — 2026-07-31

Generation complete for all 289 inventory strings. Clips remain
`generated_unreviewed` unless flagged below. Native-speaker QA (D17) is still required
before release. This pass is an owner priority ear-list from duration outliers and
known fada/mutation risks — not a completed QA gate.

## Flagged (44 unique)

- Ceannaigh agus díol; tabhair an t-airgead dom agus tóg é.
- Cárb as tú?
- Cén t-ainm atá ort?
- Féach ar an mballa mór cloiche.
- Is as Maigh Eo mé.
- Léigh an t-inscríbhinn anois agus guí.
- Ná caill an long.
- Téigh go Londain agus iarr freagra.
- abhainn
- arm
- as
- bia
- bá
- bád
- can
- cath
- chuaigh
- cnoc
- cónaí
- cósta
- deartháir
- dlí
- díol
- fan
- farraige
- fill
- féach
- guí
- lá
- mac
- mór
- nua
- rí
- sean
- tar
- teaghlach
- tháinig
- téigh
- tóg
- túr
- áit
- álainn
- áth
- éan

## Duration outliers

- `arm` ('arm') duration=1.44
- `as` ('as') duration=1.76
- `baa` ('bá') duration=1.52
- `baad` ('bád') duration=1.44
- `bia` ('bia') duration=1.84
- `can` ('can') duration=1.68
- `cath` ('cath') duration=1.84
- `cnoc` ('cnoc') duration=1.84
- `dlii` ('dlí') duration=1.6
- `eean` ('éan') duration=1.44
- `fan` ('fan') duration=1.6
- `fill` ('fill') duration=1.84
- `guii` ('guí') duration=1.6
- `laa` ('lá') duration=1.44
- `mac` ('mac') duration=1.6
- `moor` ('mór') duration=1.68
- `nua` ('nua') duration=1.44
- `tar` ('tar') duration=1.44
- `tuur` ('túr') duration=1.44

## Bind rule

Launch exercises may only set `audioText` to strings in
`content/audio/irish-inventory-v1.json`. New Irish without a clip stays silent
until a post-ElevenLabs provider can regenerate.

## D32 Track D — risk-ranked review queue (2026-08-02)

This is a repository-backed editorial and structural triage pass. It is not a
native-speaker review, pedagogy review, historian review, pronunciation verdict, or
completed audio QA. Existing `qa_passed` labels in legacy records are not reissued by
this pass. All learner-release states remain blocked unless the independent contract
records say otherwise.

Queue references use the following stable record ids:

- `launch.<county>.<phrases|conversation>.<nn>` — line in
  `launch-phrases-conversations-v1.json`;
- `pack.<page-id>.exercise` — exact `audioText` line in a county draft pack;
- `legacy.<member-id>` and `v2.<member-id>` — phrase-family member records; and
- `batch.<batch-id>.<line-id>` — generation-batch line.

`P0` is urgent triage, not a capture decision by itself. Each item has a capture
disposition: `capture-blocked` withholds a line even from provisional capture;
`review-before-release` permits a D32 capture candidate only when the v2/batch contract
allows it; and `operational-watch` means an existing claim, lease, or result must be
resolved before another request. `P1` is a high-risk Irish/name/mutation/inflection/
register line needing targeted external review. `P2` is the existing spot-listen and
duration-outlier tail. “Capture candidate” below never means learner-release eligible.

### P0 — urgent triage with explicit capture disposition

- **Capture-blocked — missing runtime records:** `launch.mayo.conversation.03` — `Maith.` — and
  `launch.dublin.conversation.14` — `Slán.` — are present in the legacy launch bank but
  absent from `irish-inventory-v1.json`. Proposed correction: either retire each legacy
  line or author a complete v2 member with provenance, risk flags, an exercise consumer,
  and a registered batch. Do not bind either line or infer a clip from bank membership.
  Evidence: `content/audio/launch-phrases-conversations-v1.json`; the mechanical check
  is `tools/audit_irish_review_queue.py`.

- **Review-before-release — meaning mismatch:** `launch.mayo.phrases.07`,
  `pack.mayo.rockfleet.listen-build-together.exercise`, and
  `pack.mayo.rockfleet.speaking.exercise` all use `Tá muid go léir.`. The launch bank
  gloss says “We are all here”; both pack exercises say “We are all”. Proposed
  correction: choose the intended English intent for each consuming exercise and then
  have the Irish-language reviewer confirm whether the spoken line should stay as-is
  or carry an explicit location. No Irish rewrite is made here.

- **Review-before-release — mutation spelling inconsistency:** `launch.dublin.phrases.11` is
  `Téigh go dtí an mhargadh.` while `launch.dublin.conversation.04`, the Dublin atlas
  placement, and the surrounding market lines use `margadh` after `an`. Proposed
  correction to test, not apply: reconcile the article + noun form with the
  Irish-language reviewer and update all dependent line/member records together.

- **Review-before-release — Meath hear/build mismatch:** `launch.meath.phrases.01` and
  `pack.meath.before-the-grant.hear-existing-place.exercise` say
  `Tá ainm ar an talamh sean agus tá baile ann.`, while
  `pack.meath.before-the-grant.build-named-land.exercise` drops `sean` and changes the
  English intent. Proposed correction: make the heard line, construction answer, gloss,
  and target lexeme set agree; do not silently choose whether `sean` belongs.

- **Review-before-release — possession/location frame is unresolved:** `launch.meath.phrases.04`,
  `pack.meath.first-fortification.hear-fortification.exercise`,
  `pack.meath.first-fortification.type-position.exercise`, and
  `pack.meath.first-fortification.retrieve-site.exercise` use `Tá cónaí sa teach`
  without the explicit person frame used by `An bhfuil cónaí ort anseo?` and
  `Tá cónaí orm sa bhaile.`. Proposed correction: reconcile subject, place meaning,
  register, and learner role across the conversation and sentence exercises before
  teaching use. If retained for D32 capture, keep the exact-line v2/batch controls and
  the learner-release gate open.

- **Capture-blocked — Offaly patronage line has conflicting intents:**
  `launch.offaly.phrases.03` and `pack.offaly.king-and-abbot.hear-king.exercise` use
  `Déan cros mhór don rí le sonraí beaga.`. The launch gloss says “with small details”;
  the pack translation says “and look at the small details”; the sibling construction
  `pack.offaly.king-and-abbot.build-patronage.exercise` changes to
  `Déanann Colmán...`. Proposed correction: reconcile command/declarative form,
  English intent, and the historical learner role with the Irish-language, pedagogy,
  and Offaly history reviewers. The source brief keeps Colmán/Flann patronage and the
  inscription specialist gate open.

- **Review-before-release — inscription line is a compound review block:**
  `launch.offaly.phrases.05`, `pack.offaly.inscription.hear-reading.exercise`, and
  `pack.offaly.inscription.type-prayer.exercise` use
  `Léigh an t-inscríbhinn anois agus guí` / `Léigh anois agus guí ar son Flann.`.
  The Offaly source brief records damaged letters, competing readings, and an open
  medieval-art/inscription gate. Proposed correction: verify the article/noun form,
  imperative and prayer relationship, then align the line with the bounded historical
  paraphrase. Do not invent a transcription or close the specialist gate.

- **Capture-blocked — exact spoken text has conflicting English intents:** the audit reports these ids
  for manual reconciliation: `launch.meath.conversation.05`,
  `launch.offaly.conversation.03`, `launch.mayo.conversation.09`,
  `launch.offaly.conversation.01`, `launch.meath.phrases.08`,
  `launch.dublin.conversation.06`, `launch.mayo.conversation.12`, and
  `launch.dublin.conversation.12`, together with their corresponding `pack.*` and
  `legacy.*` records. The separate `Tá muid go léir.` item above is a location-marker
  mismatch. Proposed correction: decide which English intent belongs to the exact
  exercise/role and make the source records agree; preserve pending Irish review and do
  not “fix” a line from translation inference. Benign paraphrases remain review context,
  not automatic defects.

- **Capture-blocked — legacy generation inputs:** `legacy.ait.where-place`, `legacy.ba.where-bay`,
  `legacy.bean.she-is-woman`, `legacy.dearthair.brother-here`,
  `legacy.freagair.answer`, `legacy.mac.the-son-here`, and
  `legacy.mise.i-am-from-frame` remain `pending_generation`. D31 makes the v1 bank
  migration-only, so these are not capture-ready records. Proposed correction: migrate
  only after a complete v2 member, stable provenance, explicit risk flags, a consuming
  exercise, capture authorization, and a registered batch exist.

- **Operational-watch — existing batch lease needs an operational handoff:**
  `batch.mayo.d31.capture-prep.2026-08-02.mayo.d31.capture-prep.2026-08-02.line.3db7de3f60203217`
  (`Gráinne is ainm di.` / `v2.ainm.grainne-named`) has an approved line request and
  active claim, but `provider_result.status` is still `not_started` and audio QA is
  `not_started`. Proposed correction: resolve the existing lease/result or release it
  through the runner’s controlled path before making another request. Do not duplicate,
  overwrite, or treat the claim as audio QA.

### Withhold even from provisional capture — compact blocker set

The mechanical audit currently reports 12 capture-blocked findings. The concrete
spoken lines are `Maith.`, `Slán.`, `An bhfuil cónaí ort anseo?`, `An bhfuil tú ag
foghlaim?`, `Cá bhfuil an caisleán?`, `Cá bhfuil an chros?`, `Cad atá agat?`, `Cé hé an
rí?`, `Déan cros mhór don rí le sonraí beaga.`, `Iarr freagra.`, and `Téigh ar ais go dtí
an chathair.`. The seven legacy member ids
`ait.where-place`, `ba.where-bay`, `bean.she-is-woman`, `dearthair.brother-here`,
`freagair.answer`, `mac.the-son-here`, and `mise.i-am-from-frame` are also withheld
because they remain retired v1 `pending_generation` inputs. The active Gráinne line is
not in this blocker set: it is an `operational-watch` and must not be duplicated.

### P1 — review before learner release

Risk-flagged P1 lines, and the P0 items explicitly marked `review-before-release`, may
be captured during D32 only through a valid v2 identity/provenance/risk/use record and
an authorized, approved, claimed batch line. They remain withheld from learner release
until the independent Irish-language, pedagogy, historical, exercise, and audio-QA
reviews pass.

- **Mayo identity and named-place cluster:**
  `launch.mayo.phrases.01`, `legacy.as.from-mayo`,
  `pack.mayo.clew-bay.build-origin.exercise`, and
  `pack.mayo.in-the-record.retrieve-origin.exercise` use `Is as Maigh Eo mé.`;
  `launch.mayo.phrases.04`, `legacy.iarr.go-and-ask`, `legacy.teigh.go-london-ask`,
  and `pack.mayo.road-to-london.listen-build-request.exercise` use
  `Téigh go Londain agus iarr freagra.`. Verify county/place forms, imperative and
  register, and the boundary between a present-day learner line and a historical
  process. Keep `Maigh Eo`, `Londain`, and all fadas pending external review.

- **Mayo personal-name and pronoun cluster:**
  `launch.mayo.phrases.05`, `pack.mayo.in-the-record.build-identity.exercise`,
  `pack.mayo.in-the-record.type-name.exercise`, `legacy.ainm.grainne-named`,
  `v2.ainm.grainne-named`, and `legacy.mise.i-am-grainne` use
  `Is mise Gráinne.` / `Gráinne is ainm di.`. The v2 record explicitly distinguishes
  an identification line from dialogue as Gráinne, so preserve that distinction while
  checking name form, `di`, learner role, and exercise intent.

- **Mayo origin-question register:** `launch.mayo.conversation.01`,
  `legacy.as.where-from`, and the paired `Is as Maigh Eo mé.` line use `Cárb as tú?`.
  This is a dialect/register and contraction review item, not a proposed correction.

- **Mayo mutation/inflection cluster:** review together rather than one clip at a time:
  `legacy.ba.ship-in-bay`, `legacy.ba.return-to-bay`, `legacy.caislean.castle-on-coast`,
  `legacy.costa.castle-on-coast`, `legacy.costa.it-on-coast`,
  `legacy.long.ship-in-bay`, `legacy.long.ship-on-sea`, `legacy.teigh.go-on-road`,
  `legacy.tar.come-back-bay`, `v2.farraige.ship-on-sea`,
  `v2.farraige.sea-here`, and `v2.farraige.where-sea`. Review `bhá`, `mbá`, `gcósta`,
  `bhfarraige`, `fharraige`, and `mbóthar` in their full frames. The v2 *farraige*
  members remain `legacy_unverified` for audio QA and learner release despite legacy
  inventory labels.

- **Dublin named-place and historical-object cluster:**
  `launch.dublin.phrases.06`, `pack.dublin.coin-travels.notice-past-directions.exercise`,
  `pack.dublin.coin-travels.speak-the-route.exercise`,
  `pack.dublin.port-before-mint.build-ship.exercise`,
  `pack.dublin.port-before-mint.type-place-name.exercise`, and
  `pack.dublin.named-king.notice-name-frame.exercise` require review of
  `Gleann Dá Loch`, `Baile Átha Cliath`, `Sihtric`, `rí`, and the coin/mint role. The
  Dublin source brief still requires a numismatist to select the learner-facing penny
  and lock its legend; the pack is a research draft.

- **Opening and recap owners:** likely launch surfaces with Irish word/audio resources
  need review as page records even when they do not yet carry a phrase-line clip:
  `pack.mayo.clew-bay.opening`, `pack.mayo.in-the-record.opening`,
  `pack.mayo.royal-answer.opening`, `pack.dublin.port-before-mint.opening`,
  `pack.dublin.named-king.opening`, `pack.dublin.first-penny.opening`,
  `pack.dublin.read-the-legend.opening`, `pack.meath.before-the-grant.opening`,
  `pack.meath.ford.opening`, `pack.meath.stone-castle.opening`,
  `pack.offaly.river-road.opening`, `pack.offaly.settlement.opening`,
  `pack.offaly.carved-cross.opening`, and `pack.offaly.inscription.opening`, with
  their matching `.consequence` pages. Confirm that any eventual spoken Irish is
  bound to a reviewed inventory/v2 member and that narrative prose is not silently
  treated as capture-ready dialogue or recap audio.

- **Dublin article and inflection cluster:**
  `launch.dublin.phrases.05`, `launch.dublin.phrases.10`,
  `launch.dublin.conversation.08`, plus `launch.dublin.phrases.11` and
  `launch.dublin.conversation.04` need a single Irish-language pass over article,
  mutation, genitive, and place/object meaning. Do not infer a correction from the
  audio slug.

- **Meath place-name and article cluster:**
  `launch.meath.phrases.03`, `launch.meath.conversation.03`,
  `launch.meath.phrases.10`, `pack.meath.ford.build-ford.exercise`,
  `pack.meath.ford.fill-here.exercise`, `pack.meath.ford.type-two-positions.exercise`,
  and `pack.meath.town-and-afterlife.retrieve-whole-story.exercise` involve `t-áth`, `Áth Troim`,
  `an abhainn`, `an baile`, and `ansiúd`. Confirm the exact place-name, article and
  preposition forms against the Meath source brief; the grant, phasing, and conquest
  gates remain open.

- **Meath mutation and pronoun cluster:**
  `launch.meath.phrases.05`, `launch.meath.phrases.06`,
  `launch.meath.conversation.07`, `launch.meath.conversation.13`,
  `pack.meath.stone-castle.hear-stone-wall.exercise`,
  `pack.meath.town-and-afterlife.speak-present-place.exercise` need a review of
  `mballa`, `gcaisleán`, `mbaile`, `mór`, and `cloiche` in their complete clauses. The
  queue records review pressure, not a grammar verdict.

- **Offaly mutation and inscription cluster:**
  `launch.offaly.phrases.04`, `launch.offaly.conversation.05`,
  `launch.offaly.conversation.12`, `pack.offaly.carved-cross.hear-looking.exercise`,
  `pack.offaly.carved-cross.type-attention.exercise`, and
  `pack.offaly.original-and-replica.speak-whole-place.exercise` use `gcros`, `gcloch`,
  `gcros chloiche`, `chros`, and `chloch`. Review the full article/preposition frames
  with the same language reviewer who handles the inscription line.

- **Short name/reference frames:**
  `launch.mayo.conversation.02`, `launch.mayo.conversation.11`,
  `launch.dublin.phrases.08`, `launch.dublin.conversation.13`,
  `launch.meath.conversation.11`, `legacy.ainm.what-is-your-name`, and
  `legacy.ainm.name-of-place` use `Cén t-ainm...` / `Cad is ainm duit?`. Check the
  distinction among `ort`, `duit`, `ar an áit`, and `ar an rí`; keep the fadas and
  pronoun frames visible in the review record.

- **Past/imperative and role risk:** `launch.mayo.phrases.03`,
  `legacy.caill.do-not-lose-ship`, `legacy.long.do-not-lose`,
  `pack.dublin.first-penny.hear-coin-movement.exercise`,
  `pack.dublin.first-penny.type-past.exercise`, and
  `pack.offaly.king-and-abbot.build-patronage.exercise` combine past forms, commands,
  named objects, or historical actors. They are review-before-release lines; D32 capture
  may proceed only with exact-line approval and the contract-compliant v2/batch controls.
  The relevant external language/pedagogy/history reviews remain required before release.

### P2 — existing spot-listen and duration tail

Retain the original 44-item ear-list above. The current inventory has 43 entries with
`qa_state: spot_flagged`; the extra `farraige` item remains in the original list because
the legacy family was marked `qa_passed`, while the v2 record correctly keeps its audio
state `legacy_unverified`. The current 43 inventory items are the duration/known-risk
tail: `abhainn`, `arm`, `as`, `bia`, `bá`, `bád`, `can`, `cath`, `chuaigh`, `cnoc`,
`cónaí`, `cósta`, `deartháir`, `dlí`, `díol`, `fan`, `fill`, `féach`, `guí`, `lá`, `mac`,
`mór`, `nua`, `rí`, `sean`, `tar`, `teaghlach`, `tháinig`, `téigh`, `tóg`, `túr`, `áit`,
`álainn`, `áth`, and `éan`, plus the eight flagged launch phrases already listed in
the original record. Review these in the locked `Irish Cultural Guide` profile; no
pronunciation judgment is made by the queue.

### Capture boundary and external gates

- The only checked-in line that is structurally in an approved v2 capture request is
  `v2.ainm.grainne-named` / the active `batch.mayo.d31.capture-prep.2026-08-02...`
  line. This is an existing user-authorized handoff, not a new Track D authorization;
  resolve its active claim before duplicating it. Its provider result and audio QA are
  still open.
- No other legacy v1 `pending_generation` member is capture-safe. D32 permits provisional
  capture only after the exact v2 identity/provenance/risk/use/authorization and batch
  checks exist. Existing *farraige* clips need QA/release-state reconciliation, not an
  automatic duplicate capture.
- Safe-to-capture is not learner-release eligible. Native-speaker Irish-language QA,
  pedagogy review, exercise/meaning review, and audio QA remain required for all launch
  material. Historical/name gates remain open for Mayo, Dublin, Meath, and Offaly; the
  Dublin numismatics gate and Offaly inscription/art gate are additional blockers.

Run the mechanical, non-linguistic audit with:

```bash
python3 -B tools/audit_irish_review_queue.py report
python3 -B tools/audit_irish_review_queue.py check
```

`check` is expected to remain non-zero while capture-blocked findings exist. It catches
inventory identity problems, missing bind records, unsafe exact-text intent conflicts,
retired legacy generation inputs, and unsafe batch state; review-before-release prompts
and operational watches do not make the check fail. A passing check would still not
decide whether an Irish line is idiomatic or correctly pronounced, and a non-zero check
does not cancel valid D32 capture of a separate, non-blocked line under the contract.
