# Sensitive county review route (`queue-04-sensitive-review-first`)

Operational review-route register for Bulk Track A avenue **A7**. It secures
history, community, rights, and language-source review before any further family
volume for six counties. It does **not** record community approval, historian
sign-off, rights clearance, or learner release.

Authoritative Track A posture remains in [`STATUS.md`](../../STATUS.md) and the
partition table in
[`content/audio/authoring/d32-county-authoring-queue.md`](../../content/audio/authoring/d32-county-authoring-queue.md).
Machine-readable companion:
[`content/audio/authoring/queue-04-sensitive-review-register.json`](../../content/audio/authoring/queue-04-sensitive-review-register.json).

Related open strategy item: [`STRATEGY.md`](../STRATEGY.md) **U7** (contested
history editorial principles). Related slate rule:
[`COUNTY-STORY-SLATE.md`](../COUNTY-STORY-SLATE.md) § *Source and review route*.

## Policy (non-negotiable)

1. **Review route before volume.** Do not expand unique-text yield for these
   counties to chase the Track A harvest target.
2. **No invented approval.** Absence of a named reviewer, date, and record means
   the lane is open / blocked — never implied as passed.
3. **Multi-perspective history is mandatory** for contested anchors. One partisan
   primary source is research input, not a finished packet.
4. **Rights before quotation.** No treaty clause, letter, poem, archival image,
   modern adaptation, or community memory enters learner-facing copy until licence
   or permission is recorded.
5. **Language source before dialect claims.** Provisional D32 frames use standard
   pedagogical Irish; Ulster / Munster / local register claims need a named
   language source and Irish-language review.
6. **Existing provisional families stay provisional.** Harvest capture does not
   grant linguistic, historical, community, rights, or learner-release approval.

## Shared checklist (every county)

Mark each item only when a durable record exists (path, reviewer role, date).
Until then the item stays open and family volume stays blocked.

### History

- [ ] Named independent local / period historian or equivalent specialist engaged
- [ ] Multi-perspective brief written (at least two attributed community or
      documentary viewpoints where the slate requires it)
- [ ] Primary readings selected from inspectable editions (CELT, ISOS, DIB,
      archival catalogues, scholarly editions) — not anonymous web paraphrase
- [ ] Contested terms, date precision, and myth-vs-record labels listed
- [ ] No learner-facing historical claim beyond the approved brief

### Community

- [ ] Cross-community or local reader plan recorded (who, remit, not-yet-contacted
      is an honest status)
- [ ] Place-name and public naming practice reviewed (especially Doire / Derry /
      Londonderry and NI terminology)
- [ ] Civilian / aftermath experience required where the slate marks sensitivity
- [ ] Explicit statement that no community endorsement has been obtained until a
      signed review record exists

### Rights

- [ ] Source register started before drafting (see slate + Personal Atlas rights
      register patterns)
- [ ] Licence or permission recorded for every quotation, image, audio, or
      adaptation intended for release
- [ ] Heritage-site visitor copy used only for place orientation, not as hidden
      primary evidence
- [ ] Contact details and contracts kept out of git; only agreement references in
      the durable rights system

### Language

- [ ] Irish county and place forms confirmed in Logainm (and NI parity sources
      where relevant)
- [ ] Irish-language reviewer assigned for dialect, register, and invented-frame
      fitness
- [ ] Pronunciation / audio QA remains a separate gate after capture
- [ ] Pedagogy review remains a separate gate; sensitive framing is not a
      substitute for Irish-language approval

### Volume gate

- [ ] All four lanes above have named owners and an agreed first review packet
- [ ] Only then may Track A author net-new unique text beyond binding-honest
      minimums
- [ ] `prepare-harvest` for these counties stays out of score-chase payloads until
      the volume gate opens

## County register

| County | Story binding | Why sensitive | History lane | Community lane | Rights lane | Language lane | Volume |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Derry | `d32.derry.city-walls-siege` — walls / siege 1688–89 | Contested siege memory; inside/outside walls; public naming | Open — multi-perspective local history treatment required | Open — cross-community reader required; naming practice inspectable | Open — contemporary voices need edition + permission | Open — Logainm/NI forms; no dialect claim yet | **Blocked** |
| Donegal | `d32.donegal.flight-of-the-earls` — Rathmullan / 1607 | Flight of the Earls; plantation aftermath; Ulster politics | Open — contemporary account + place source; no generic witness headline | Open — Ulster / Donegal reader for departure framing | Open — annal/edition rights before quotation | Open — Ulster Irish source before local-register claims | **Blocked** |
| Leitrim | `d32.leitrim.brian-na-murtha` — Brian na Múrtha O'Rourke | Tudor expansion, trial, execution; conquest framing risk | Open — state record + Irish source pair; avoid simple conquest narrative | Open — Breifne / local history reader | Open — trial/state-paper edition rights | Open — place/person forms; no invented trial speech | **Blocked** |
| Limerick | `d32.limerick.treaty-of-limerick` — Sarsfield / Treaty 1691 | Contested treaty memory; promise vs aftermath | Open — treaty clause + civilian-aware context | Open — Limerick local / cross-tradition reader | Open — treaty text licence; no unsourced clause paraphrase as fact | Open — Munster forms only after language source | **Blocked** |
| Tyrone | `d32.tyrone.hugh-oneill-dungannon` — Hugh O'Neill at Dungannon | Competing descriptions of one leader; sequential link to Donegal flight | Open — annal + state-paper contrast; no single-voice biography | Open — Tyrone / Ulster reader; connect without repeating Rathmullan | Open — edition rights for competing excerpts | Open — person/place forms; historical-name lines stay review-pending | **Blocked** |
| Wexford | `d32.wexford.bagenal-harvey-1798` — 1798 Rebellion | Uprising, reprisal, aftermath; multi-community civilian experience | Open — balanced primary accounts from more than one community | Open — mandatory multi-community readers; no triumphalist drill | Open — 1798 sources/adaptations need permission | Open — no invented rebel speech as attestation | **Blocked** |

## Existing family posture (audit)

As of this register, each county already has provisional D32 v2 families (scaffold
members bound to the harvest-uses story ids). Those families:

- remain `draft` with `linguistic_approval: false` and
  `historical_authenticity: false`;
- carry invented pedagogical text and `source_ambiguity` risk flags;
- keep learner release blocked;
- now also carry explicit sensitive-route release reasons
  (`sensitive_county_review_pending`, `history_community_review_pending`,
  `rights_review_pending`, `language_source_review_pending`);
- must not be treated as evidence that history or community review has begun.

No community, historian, rights, or Irish-language approval is claimed for any of
these six counties.

## Ready vs blocked

| Outcome | State |
| --- | --- |
| Review-route documentation and checklist | **Ready** (this file + JSON register) |
| Queue A7 entry condition clarity | **Ready** |
| Metadata hardening on existing families | **Ready** (gates marked; no volume chase) |
| Named reviewers / completed lane records | **Blocked** — none recorded |
| Net-new unique-text authoring for yield | **Blocked** |
| Provider capture for new sensitive volume | **Blocked** (and out of scope for A7) |
| Learner release | **Blocked** |

## What would open volume later

A later session may author net-new unique text for a county only when that
county's four lanes have named owners, a first source packet path, and an
explicit note here flipping its Volume cell from **Blocked** to **Conditional**.
Until STRATEGY U7 principles and the county packet exist, keep yield at TBD and
do not score-chase.
