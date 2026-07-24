# Mayo pack — page-level claim audit

*Cross-cutting editorial / historical claim ledger for the nine-chapter Mayo review draft (revision 5). Completeness and draft-vs-ledger consistency; not a substitute for the targeted deep research passes on Chapters 2 and 4 / C04.*

| Field | Value |
| --- | --- |
| Draft | `content/mayo/grainne-1593.pack.draft.json` (rev 5) |
| Narrative extract | `docs/mayo-historical-review/_WORKING-narrative-extract.md` |
| Claim ledger | `content/mayo/grainne-1593-source-brief.md` (C01–C18) |
| Storyboard | `docs/GRAINNE-STORYBOARD-V2.md` |
| Narrative pages audited | **61** across 9 chapters (38 Learning exercises out of scope except where they smuggle claims) |
| Audit date | 24 July 2026 |

---

## Method

1. Read every narrative page body, detail, context, and display item in the working extract (aligned to pack JSON).
2. Tag each **material historical assertion** to ledger IDs **C01–C18**, or mark **geography / framing / meta** (no new claim).
3. Ignore pure language pedagogy (glosses, scaffolds, exercise prompts) unless the stem asserts history.
4. Score **certainty fit** against the ledger (`story` / `close` / `afterlife` / `exclude`) and storyboard L1/L2 placement.
5. Flag: invented scene; certainty mismatch; afterlife as fact; English-source bias hidden; seizure/tolling sanitised; Greenwich dialogue; murder on L1.
6. Cross-check storyboard **Do not** rules and open-gate labeling (`reviewGates`, evidence resource statuses).
7. Light external check only for the surprising C04 “meeting” wording (Sidney tradition supports a meeting/report; draft correctly withholds the “~200 men” figure while the cite is open).

**Verdict key (ledger column)**

| Verdict | Meaning |
| --- | --- |
| Ready | Mapping and certainty fit for draft; no copy fix required for claim hygiene |
| Ready+gate | Content bounded, but depends on an open historian/expanded gate before release prose |
| Needs fix | Certainty, Do-not, or consistency problem in authored copy |
| Framing | Geography, method limit, or transition — no ledger claim, or claim only as setup |

**Certainty abbreviations:** S = story · C = close · A = afterlife · X = exclude

---

## Severity-ranked findings

### Blockers (release prose / historian clearance)

1. **Expanded chapter-weight claims still behind open gates.** Chapters 2 and 4 promote C05–C07 and C03–C04 to load-bearing narrative; `reviewGates.history.expanded` is **open**, and evidence resources `evidence.kin-c05-c07`, `evidence.marriages-c05`, `evidence.children-c06`, `evidence.power-c03-c04`, `evidence.clew-bay-umhaill`, `evidence.sidney-recognition` are `historian-review-open`. Presentation correctly says targeted review remains open — but **release clearance cannot close** until D-F / board pass. *Not a smuggling bug; a hard gate.*

2. **C04 on the Learning spine while the citation is unpinned.** `mayo.power-at-sea.official-recognition` is visibility **`both`**, so Learning mode treats Sidney’s galleys/fighting-men recognition as causal spine. Storyboard places Ch4 Sidney detail at **L2** and requires the exact cite before final prose; pack detail still says the citation “remain[s] under targeted review.” **Demote to `storyOnly` until the cite is pinned**, or pin C04 before any Learning release path.

3. **C10 resource status conflicts with prototype-complete gate.** `evidence.kin-held-c10` is `historian-review-open` even though C10 is a core prototype tipping fact (`history.prototype` = complete) and `mayo.bingham-pressure.kin-held` asserts it on L1 (`both`). Either re-mark the resource as prototype-approved or open a real C10 wording pass — **do not leave the status ambiguous**.

### Should-fix (before next historian pass)

4. **C02 never surfaces.** Ledger: “Absent from Irish annals; English admin sources dominate — say affirmatively in L2.” Draft shows English paperwork shaping voice (Ch5 two-voices, Ch7 shaped-voice) but **never states annal silence / English-source dominance**. Add one bounded closer-look or Story-only beat.

5. **Dual C06 evidence statuses.** `evidence.family-c06` = `historian-approved-prototype` while `evidence.children-c06` = `historian-review-open`. Same claim ID, opposite gate signals — consolidate.

6. **C04 wording: “recorded meeting” without date or cite.** Snippet: *“Sir Henry Sidney recorded meeting a notable sea captain… a woman with galleys and fighting men.”* Recognition + meeting are traditional; draft wisely omits “~200 men.” Still: add date band (e.g. mid-1570s Galway visit / later letter tradition) only after cite pin; keep “in his words” (already present).

7. **Owen naming asymmetry.** Context uses `Eóghan / Owen`; body only “Owen.” First closer-look mention should carry both forms once (*Eóghan / Owen*), matching Tibbott / Donal na Píopa practice.

8. **Royal-draft personal names not yet mirrored on L1.** Source brief royal answer names Morogh/Murrough and Tibbott; Ch8 `named-kin` says “sons and her brother Donal” without the sons’ names. Acceptable condensation — but historian should confirm condensation vs approved L1 paraphrase (*“release the imprisoned kin”* / sons’ estates) so the draft does not drift from the cleared petition/royal paraphrase set.

9. **Ch9 C14–C15 bundled as `expanded-review-open`.** 1595 pressing-again (C14, story) is load-bearing on `ask-again` (`both`); death/galley soft edge (C15, close) is correctly `storyOnly`. Split resource statuses so story C14 is not held hostage to soft C15.

### Polish

10. Rockfleet matching exercise objective still says “four Rockfleet headwords” after D-B (only *caisleán* is introduced there; kin words are reuse). Pedagogical, not historical — fix wording to “one new place word and three reused kin words.”
11. Presentation `sourceDetail` cites “Claims C01–C16” without noting C17/C18 as excluded/afterlife-handled (already correct in copy; metadata only).
12. Brother form: draft **Donal / Donal na Píopa** throughout; period English often **Donell O’Piper**. Keep Irish/preferred form on L1; put Donell in L3/source credit when royal draft is cited.
13. `mayo.rockfleet.learning-consequence` detail still speaks like a single-chapter proof (“does not yet turn the county gold”) inside a complete-county draft — meta polish.

### Explicit non-findings (checked clean)

| Risk | Result |
| --- | --- |
| Invented Greenwich dialogue | **Clean** — deferred; afterlife only |
| Murder asserted on L1 | **Clean** — C09 `storyOnly`, unsettled |
| C17 (battlement divorce / one-year marriage / hair-cut / ship-birth) as fact | **Clean** — marriages page rejects; afterlife does not revive |
| C18 “pirate queen” as fact | **Clean** — rejected by name in woman-power detail |
| Seizure/tolling sanitised into pure trade | **Clean** — Ch1 umhaill + Ch4 trade-tolls/seizure keep taking visible |
| Afterlife smuggled as 1593 eyewitness | **Clean** — record-legend + court-threshold + Ch7 distractor |
| English bias presented as neutral inventory | **Clean** — two-voices, maintenance, shaped-voice |
| Learner “raids” or “defeats Bingham” | **Clean** — seizure detail forbids learner raid |

---

## Full page ledger

Certainty fit = does surface wording match ledger level and storyboard L1/L2 intent?

### Chapter 1 — `mayo.clew-bay` (9 narrative)

| Page id | Material claims | Claim IDs | Certainty fit | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| `opening` | Mayo Atlantic edge; sea as livelihood/power; Gráinne’s people worked this sea | C01 (bg) | S OK | Ready+gate | Geography + polity setup; C01 resource open |
| `the-bay` | Clew Bay as sheltered islanded inlet / route system | geography | — | Framing | No person claim |
| `islands` | Clare Island at mouth; Achill north; inhabited inner isles; sea mobility as power | geography + C01 bg | S OK | Framing | Place names OK; interpretive “land-bound lord” is framing not new claim |
| `place` | Territory named Umhaill / the Owles | C01 | S OK | Ready+gate | Naming beat |
| `umhaill` | Uí Mháille living by fishing, trade, tolls, seizure; “normal Atlantic lordship” | C01, C03 | S OK | Ready+gate | *“Sanitising it into pure commerce would falsify the record”* — anti-sanitize explicit |
| `origin` | Mayo origin frame; foreshadows later self-naming to English state | framing + pedagogy | — | Framing | No new historical assertion |
| `sea-captain` | Sidney recorded meeting a woman sea captain with galleys and fighting men; English official voice | C04 | S OK; cite open | Ready+gate | `storyOnly`; omits ~200; detail flags citation review. Snippet: *“recorded meeting a notable sea captain… galleys and fighting men.”* |
| `limit` | Geography real; sea-power recognition attested; coastline cannot narrate a full life | meta + C01/C04 | OK | Framing | Evidence limit page |
| `consequence` | Sea power needs kin/household to endure | framing → Ch2 | — | Framing | Transition only |

### Chapter 2 — `mayo.kin-alliances` (6 narrative)

| Page id | Material claims | Claim IDs | Certainty fit | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| `family-power` | Kinship/household as structure of authority; papers name relationships, not private scenes | C06 (bg), meta | S/C OK | Ready+gate | Chapter-weight expansion (D-F) |
| `marriages` | Married Dónal an Chogaidh Ó Flaithbheartaigh; later Risdeárd an Iarainn Bourke; sequence supportable, dates/stories not | C05; rejects C17 | S OK | Ready+gate | *“does not stage a battlement divorce or repeat the one-year-marriage tale as fact”* |
| `named-kin` | Sons including Tibbott; brother Donal na Píopa; later leverage | C06, C10 foreshadow | S OK (surface sons/brother) | Ready+gate | Keeps Méadhbh etc. off L1 — correct |
| `woman-power` | Woman exercising maritime/political authority recognised in English record; not “pirate queen” | C01/C04 bg; rejects C18 | S OK | Ready | *“modern title 'pirate queen'”* refused |
| `evidence-limit` | Interrogatory preserves political family facts, not domestic texture | meta + C11 bg | OK | Framing | |
| `consequence` | Need defensible base → Rockfleet | C07 hook | S OK | Ready+gate | |

### Chapter 3 — `mayo.rockfleet` (11 narrative)

| Page id | Material claims | Claim IDs | Certainty fit | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| `arrival` | Rockfleet at tide line; boats arrive/shelter/leave | C07 + geography | S OK | Ready | Prototype-approved place |
| `tide-detail` | Tide/wind/depth shape approach | geography | — | Framing | |
| `water-road` | Inlet + boats extend authority across bay | C07 framing | S OK | Framing | |
| `household` | 1593 papers name children and brother in crisis; pressure reaches household | C06 | S OK | Ready | |
| `kin-detail` | Associated with Bourke marriage and later base; followers/alliances | C05, C07 | S OK | Ready | *“Rockfleet is associated with… Bourke marriage and later base”* — bounded |
| `system` | Harbour + stronghold + household as connected system | C07 interpretive | S OK | Ready | Detail labels interpretation |
| `record-detail` | State Papers name parents, marriages, children, lands, maintenance for a case | C11 bg | S OK | Ready | Shows SP as evidence, not diary |
| `limit` | Place + association + papers ≠ recoverable private day | meta | OK | Framing | |
| `pressure` | Future squeeze: boats seized, kin held, maintenance cut | C08/C10 seed | S OK | Ready | Anticipatory; not a dated scene |
| `story-consequence` | Coast as set of stakes | framing | — | Framing | |
| `learning-consequence` | Language reuse; gold not yet | meta/pedagogy | — | Framing | County-draft meta polish (#13) |

### Chapter 4 — `mayo.power-at-sea` (6 narrative)

| Page id | Material claims | Claim IDs | Certainty fit | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| `opening` | Ships move goods, tolls, force; maritime authority moves | C03 | S OK | Ready+gate | Chapter-weight expansion |
| `maintenance` | 1593 self-account: maintained by land and sea; petitioning voice shaped to persuade | C03 | S OK | Ready+gate | Bias visible |
| `trade-tolls` | Trade and tolls both depend on enforceable local authority | C03 | S OK | Ready+gate | *“Calling the whole system trade would make it cleaner than the evidence allows.”* |
| `seizure` | Opportunistic seizure; officials = disorder; her account = survival/service; sources disagree in purpose | C03, C08 | S OK | Ready+gate | No learner raid |
| `official-recognition` | Sidney: galleys and fighting men; later papers bargain/suppress; cite under review | C04, C08 | S OK but L1 vs L2 | **Needs fix** | Visibility `both` while storyboard L2 + cite open → blocker #2 |
| `consequence` | System vulnerable to imprisonment, seizure, denial of maintenance | C08 | S OK | Ready+gate | |

### Chapter 5 — `mayo.bingham-pressure` (6 narrative)

| Page id | Material claims | Claim IDs | Certainty fit | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| `opening` | Bingham presidency intensifies pressure on ships, routes, income, people | C08 | S OK | Ready | |
| `two-voices` | Her plea vs Bingham’s disorder frame; neither side fully proven | C08 | S OK | Ready | Bias explicit |
| `kin-held` | By 1593 Tibbott imprisoned (treason); Donal held | C10 | S OK | Ready+gate | Resource status inconsistent (#3) |
| `fleet-leverage` | Maintenance by land/sea stripped; maritime leverage fails | C08, C03, C10 | S OK | Ready | Systemic loss, not single stolen-ship scene |
| `owen-boundary` | She blames Bingham’s side for Owen’s death; accounts conflict; not settled murder | C09 | C OK | Ready | `storyOnly`; *“does not pronounce a settled murder”* |
| `consequence` | Local answers closed → petition to Queen | C10 → C11 | S OK | Ready | |

### Chapter 6 — `mayo.road-to-london` (6 narrative)

| Page id | Material claims | Claim IDs | Certainty fit | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| `petition` | 1593 ask for maintenance + family relief; offered service against Queen’s enemies | C11 | S OK | Ready | Matches approved L1 petition shape |
| `terms` | Petition translates maritime life into Tudor categories | C11 meta | S OK | Ready | Not autobiography |
| `motion` | Must go to London / come into court process | C12 framing | S OK | Ready | |
| `crossing` | Papers prove process, not day-by-day voyage; no invented dialogue/audience | C12 restraint | S/C OK | Ready | Explicit anti-invention |
| `court-threshold` | Queen’s process; Burghley’s eighteen articles; Greenwich meeting = later storytelling | C11, C12 | S/C OK | Ready | *“Later storytelling richly furnishes a meeting at Greenwich… audience tradition belongs in afterlife”* |
| `consequence` | Name/relationships will be held on paper | C11 | S OK | Ready | |

### Chapter 7 — `mayo.in-the-record` (5 narrative)

| Page id | Material claims | Claim IDs | Certainty fit | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| `opening` | Calendar heading “Grany Ne Malley”; eighteen questions; July 1593 SP 63/170 | C11 | S OK | Ready | Compact MS form still awaiting diplomatic transcription (board checklist) |
| `name-find` | Anglicised administrative spelling ≠ preferred Irish form | C11 | S OK | Ready | |
| `family-answers` | Answers name father, marriages, children, lands, maintenance | C05, C06, C03, C11 | S OK | Ready | Does not force Dubhdara onto L1 (optional vs approved paraphrase) |
| `shaped-voice` | Testimony and political instrument at once | C11 meta | S OK | Ready | Do-not: not private diary |
| `royal-question` | Written case demands written answer; no private audience recovered | C13 hook | S OK | Ready | |

### Chapter 8 — `mayo.royal-answer` (6 narrative)

| Page id | Material claims | Claim IDs | Certainty fit | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| `opening` | Draft 6 Sept 1593 to Bingham; distinct from July MS | C13 | S OK | Ready | |
| `terms` | Order: release imprisoned kin; maintenance from sons’ estates if peaceable; not proof of full effect | C13, C14 | S OK | Ready | Matches cleared L1 royal paraphrase |
| `named-kin` | Draft names sons and brother Donal | C13, C06, C10 | S OK | Ready | Sons unnamed on surface (#8) |
| `paper-effect` | Order ≠ outcome; Bingham still controls coast | C14 | S OK | Ready | |
| `resistance` | Bingham resisted full effect | C14 | S OK | Ready | |
| `consequence` | By 1595 pressing again; unfinished preservation | C14 | S OK | Ready+gate | Tied to expanded C14–C15 resource bundle |

### Chapter 9 — `mayo.return-afterlife` (6 narrative)

| Page id | Material claims | Claim IDs | Certainty fit | Verdict | Notes |
| --- | --- | --- | --- | --- | --- |
| `ask-again` | By 1595 pressing case again; no invented second journey required | C14 | S OK | Ready+gate | |
| `present-coast` | Clew Bay / islands / Rockfleet still there; place ≠ proof of every later tale | geography + C07 present | OK | Framing | |
| `record-legend` | Later: refuse to bow, dagger, Latin with Elizabeth = reception; documents = petition/answer act | C16; not C17 | A OK | Ready | Affirmative afterlife |
| `later-edge` | Galley association into early 1600s; death c.1603 soft; no deathbed scene | C15 | C OK | Ready+gate | Softened correctly |
| `chart` | Learner voyage chart, not historical replica | meta artifact | — | Framing | |
| `consequence` | No clean victory; record and legend kept distinct | C14, C16 synthesis | OK | Ready | |

**Counts:** 61 narrative pages · Needs fix: 1 page (`official-recognition`) · Ready+gate: ~20 (mostly Ch1–2, Ch4, Ch8–9 gate bundles) · Framing: ~18 · Ready: remainder.

---

## Consistency issues

| Area | Issue | Severity |
| --- | --- | --- |
| Evidence resource statuses | C06 split approved vs review-open; C10 review-open vs prototype-complete; C14 story bundled with C15 close | Should-fix |
| C04 placement | Ch1 `storyOnly` (good) vs Ch4 `both` (Learning spine) | Blocker |
| Personal names | Tibbott consistent; Donal / Donal na Píopa vs period Donell; Owen vs Eóghan | Polish / should-fix |
| Place names | Umhaill / Owles; Clew Bay / Cuan Mó (context); Rockfleet / Carraig a Chabhlaigh (title) — consistent | OK |
| Documentary name | “Grany Ne Malley” calendar form used as approved learner-facing form | OK |
| Marriage Irish forms | Dónal an Chogaidh Ó Flaithbheartaigh; Risdeárd an Iarainn Bourke — consistent with ledger | OK |
| Claim coverage gaps | C02 absent; C17/C18 correctly excluded in prose; no evidence resource for C02/C17/C18 (C17/C18 OK) | Should-fix (C02) |
| Open-gate labeling in copy | C04 pages self-label citation review; most Ch2/Ch4 pages do **not** tell the learner the chapter is under expanded review (resources/gates carry that) | Acceptable for draft; historian pass still required |
| Beyond-prototype expansion | Ch2, Ch4 entire chapters; Ch1 C01/C04; Ch9 soft C15 — flagged in `sourceDetail` and resources | Tracked, not unlabeled at pack level |
| Exercise claim hygiene | Ch7 comprehension distractor *“later story about refusing to bow”* correctly false | OK |
| D-B leftover | “four Rockfleet headwords” | Polish |

---

## Storyboard “Do not” compliance matrix

| Chapter | Do not (storyboard) | Draft compliance | Evidence |
| --- | --- | --- | --- |
| 1 | Catalogue every raid; invent childhood dialogue; lead with “pirate queen” (C18) | **Pass** | No raid catalogue; no childhood scene; pirate queen refused in Ch2 (and never led in Ch1) |
| 2 | Stage battlement “divorce” as fact (C17); assert disputed fixed marriage chronology | **Pass** | Explicit rejection; dates bounded |
| 3 | (No separate Do-not; keep record limits) | **Pass** | Limit + record-detail pages |
| 4 | Sanitize livelihood into pure “trade”; assert unpinned C04 figure as hard L1 | **Partial** | Anti-sanitize **Pass**; C04 on `both` with open cite **Fail** (blocker #2). ~200 omitted **Pass** |
| 5 | Learner defeats Bingham; romanticise rebellion; year-by-year tour; murder on L1 (C09) | **Pass** | Continuous pressure; Owen closer-look only |
| 6 | Invent audience conversation; teach evidence taxonomy; lead with caveats | **Pass** | Greenwich deferred; crossing refuses dialogue; petition leads with action |
| 7 | Treat interrogatory as private diary | **Pass** | shaped-voice + exercise distractors |
| 8 | Resolve whole Mayo afterlife; complete chart early | **Pass** | Chart wait to Ch9; resistance left open |
| 9 | Equate folklore with September letter; revoke gold with extras; open county picker | **Pass** | record-legend separates; no picker in copy |

---

## Recommended copy-change queue (historian pass)

Priority order for the next specialist pass:

1. **Pin or demote C04** — Prefer: pin Sidney letter cite + approved paraphrase (include or consciously omit “three galleys and two hundred fighting men”). Until then: set `mayo.power-at-sea.official-recognition` → `storyOnly` so Learning spine does not carry an unpinned recognition.
2. **Close D-F chapter-weight review for Ch2 and Ch4** — Confirm marriage name forms and sequence bounds (C05); children named only as 1593 stakes (C06); maintenance/tolling/seizure wording (C03); no romance.
3. **Reconcile evidence resource statuses** — Especially C06 dual status, C10 vs `history.prototype`, split C14 vs C15.
4. **Add one L2 C02 beat** — Affirm absence from Irish annals / English administrative dominance without turning the chapter into historiography class.
5. **Owen first mention** — “Eóghan (Owen)” once on `owen-boundary`.
6. **Optional royal-draft name pass** — Decide whether L1 should name Murrough/Morogh beside Tibbott when discussing sons’ estates / release, matching source-brief significant-reading list.
7. **Sidney Ch1 polish** — After cite pin, align “meeting” / date band / “in his words” with the chosen quotation; keep citation humility until then.
8. **Pedagogue polish (non-history)** — Rockfleet “four headwords” objective; learning-consequence county-gold meta line.

---

## Claim → chapter coverage summary

| ID | Ledger certainty | Appears in draft narrative? | Primary pages | Hygiene |
| --- | --- | --- | --- | --- |
| C01 | S | Yes | Ch1 opening–umhaill, woman-power | Gate open |
| C02 | C | **No** | — | Should add L2 |
| C03 | S | Yes | Ch1 umhaill; Ch4 opening–seizure; Ch7 family-answers | Gate open (Ch4 weight) |
| C04 | S | Yes | Ch1 sea-captain; Ch4 official-recognition | Cite open; Ch4 visibility issue |
| C05 | S | Yes | Ch2 marriages; Ch3 kin-detail; Ch7 family-answers | Gate open |
| C06 | S/C | Yes | Ch2 named-kin; Ch3 household; Ch5/8 kin | Dual resource status |
| C07 | S | Yes | Ch2 consequence; Ch3 throughout; Ch9 present-coast | Prototype OK |
| C08 | S | Yes | Ch3 pressure seed; Ch4–5 | Bias visible |
| C09 | C | Yes | Ch5 owen-boundary only | Correct |
| C10 | S | Yes | Ch2 foreshadow; Ch5 kin-held; Ch8 | Resource status odd |
| C11 | S | Yes | Ch6–7 | Correct |
| C12 | S/C | Yes | Ch6 motion–court-threshold | Greenwich deferred |
| C13 | S | Yes | Ch8 opening–named-kin | Correct |
| C14 | S | Yes | Ch8 paper-effect–consequence; Ch9 ask-again | Bundled with C15 gate |
| C15 | C | Yes | Ch9 later-edge | Softened |
| C16 | A | Yes | Ch9 record-legend (+ Ch7 distractor) | Affirmative only |
| C17 | A/X | Rejected only | Ch2 marriages | Correct |
| C18 | X | Rejected only | Ch2 woman-power | Correct |

---

## Audit conclusion

The authored draft is **claim-disciplined**: seizure/tolling stays visible, Greenwich and C16 stay in afterlife, C09 stays unsettled, C17/C18 stay out of fact voice, and evidence limits are repeatedly taught. The main failures are **gate hygiene and Learning-path placement of unpinned C04**, plus the **missing C02 L2 affirmation** and **inconsistent evidence resource statuses** — not wholesale invention or afterlife smuggling. Treat Chapters 2 and 4 plus C04 citation as the historian critical path before any promotion beyond the review draft.
