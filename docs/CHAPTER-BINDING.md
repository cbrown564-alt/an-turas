# Chapter binding — scope for one Mayo chapter

*2026-08-06. Scopes the binding work that `docs/SLICE-SELECTION.md` §8.4 identified as a
prerequisite for `STATUS.md` §6 step 2. Read with D30, D31, and D35.*

## 1. Correction to the slice-selection finding

`SLICE-SELECTION.md` §8.1 reported that only 2 of 236 Mayo members bind to a production
pack page, and framed binding as unbuilt work. The count is right; the framing was
wrong, and the difference changes what to do.

**The pack is bound.** Its **38** exercises carry **42** phrase-family member references
across **25** exercises. They resolve — but to a **v1** phrase-family store
(`content/mayo/phrase-families/*.v1.json`, **79** members), not to the **v2** authoring
store the harvest wrote into.

There are two parallel stores, and the runtime only knows one of them:

| | v1 store | v2 authoring store |
| --- | --- | --- |
| Location | `content/mayo/phrase-families/*.v1.json` | `.../authoring-v2/*.json` |
| Mayo members | **79** | **236** |
| Referenced by the pack | **36** distinct members | **2** |
| Read by the app | **yes** | **no** |
| Review metadata | family-level QA states | per-member review/release states |
| Holds the D30 QA pass | **yes** (`farraige`, 4/4 `qa_passed`) | no |

`PhraseFamilyCatalog.familyURLs` in `ios/AnTuras/CountyStoryPack.swift:1322` filters
bundle resources to `.v1.json` and decodes the v1 shape (`lexeme_id`, `members[].text`).
**The 236 harvested v2 members are invisible to the application.** No amount of native
review makes a v2 member reachable by a learner.

The runtime also validates binding in both directions at pack load
(`CountyStoryPack.swift:1100`): `unknownPhraseFamilyMember` if an exercise names a member
absent from the county catalog, and `phraseFamilyMemberMismatch` if member text does not
match the exercise answer/audio/model under the D30 bind rule. Binding is enforced, not
advisory — a bad binding fails the pack, it does not degrade quietly.

So the accurate statement is: **the harvest is unbound and unreachable, while the pack is
bound to a smaller, older, partly reviewed store.**

## 2. What binding actually means here

Three layers must agree for one exercise:

1. **Pack exercise** — `phraseFamilyMemberIDs`, plus `answer` / `audioText` / `modelText`
2. **Phrase-family catalog** — a v1 member with matching `id` and exact `text`
3. **Audio manifest** — a bundled, checksummed clip for that text

Layers 1 and 2 are enforced in Swift. Layer 3 is enforced by the reconcile tooling.

## 3. Scope: `mayo.clew-bay`

Twelve pages, **3** exercises. Current state:

| Exercise | Family | Member refs | State |
| --- | --- | --- | --- |
| `listen-farraige` | listenChoose | `farraige.citation` | **`qa_passed`** — pedagogue and native audio QA passed 2026-08-01 |
| `build-origin` | sentenceConstruction | `as.from-mayo` | **`spot_flagged`** — the `as` family is 3/3 spot_flagged, the weakest in the store |
| `match-coast` | matching | **none** | unbound; spans `lex.farraige`, `lex.ba`, `lex.ait` |

**Clew Bay is not unbound — it is two-thirds bound and blocked on review, not on wiring.**
The work is therefore smaller than §8.4 implied, and differently shaped:

1. **`match-coast` cannot be bound under the current rule** — see §6.2. Its three
   candidate members exist and are exact, but a `matching` exercise binds against
   `"all pairs"`, so wiring it needs a runtime change rather than authoring.
2. **`as.from-mayo` needs its `spot_flagged` state resolved** — review, correct, or
   replace. Until then the chapter cannot claim a clean learning path.
3. **`ba` and `ait` need enough reviewed members** to support `match-coast`.

Nothing in this list requires the harvested v2 corpus. Everything in it requires native
Irish review, which is exactly the constraint D35 identified.

## 4. How harvested material could ever reach the runtime

Three options, if and when the v2 corpus is wanted in the app:

**A · Project selected v2 members into v1-shaped files.** The v1 schema is small
(`lexeme_id`, `members[{id, text}]`), so a tool could emit v1 files from approved v2
members. No Swift change. Cheapest path, and it keeps the enforced bind rule intact. Cost:
two stores stay in sync by tooling, and v1 loses v2's per-member review states.

**B · Teach the runtime to read v2.** Extend `PhraseFamilyCatalog` to decode the v2 shape
and bundle the v2 files. Richer metadata reaches the app and one store becomes canonical.
Cost: touches the D30 bind-rule validation and the D29 freeze fixtures, and needs device
verification — which is already an open gate.

**C · Keep v2 as the harvest ledger and promote line by line.** The pack keeps using v1;
individual harvested lines are authored into v1 only as they pass review. Cost: manual,
does not scale past a few hundred lines. Benefit: nothing unreviewed can reach a learner
by accident, and no runtime change is needed to prove the first slice.

**Recommendation: C now, A when volume justifies it.** The first chapter needs ~10
correct lines, not 236 available ones. C requires no runtime change and cannot leak
unreviewed material into the app; A becomes worth building once review throughput —
not inventory — is the thing being scaled. B should wait until there is a reason beyond
tidiness, because it modifies enforced validation while the device gate is still open.

## 5. Proposed work for Clew Bay

Ordered, with the review dependency made explicit. Steps 1–2 are mechanical and can start
now; steps 3–5 are gated on a qualified Irish speaker.

1. **Binding audit — done.** `tools/audit_chapter_binding.py` applies the runtime's own
   bind rule offline and adds the audio, bundle-drift, and store-conflict checks the
   Swift validator cannot see. See §6 for what it found.
2. **`match-coast` candidates — done, and the answer is that the rule forbids it.**
   The candidates exist and are unambiguous, but the bind rule cannot express a matching
   exercise. See §6.2.
3. **Native review of the Clew Bay set** — `farraige` is already passed; `as.from-mayo`
   plus the `ba`/`ait` candidates are the actual ask. Roughly **8–12 lines**, far smaller
   than the 60-line slice, and the honest first review batch.
4. **Resolve `as.from-mayo`** on the review outcome: approve, correct, or replace.
5. **Verify the bound chapter** — pack loads without a binding error, audio plays, and
   the Story and Learning paths run. This intersects the open simulator/device gate.

Only after step 5 does §6 step 2 have something real to connect. The 60-line ranked slice
remains useful as a *later* review queue once binding, not review, is the bottleneck.

## 6. Audit results

*`tools/audit_chapter_binding.py report`, 2026-08-06. Report:
`content/audio/authoring/slice-selection/mayo-chapter-binding-2026-08-06.json`.*

**Every binding in the Mayo pack is valid.** All **42** references resolve against the
v1 catalog and satisfy the bind rule, and the bundled copies match the authored files.
**Zero blocking findings** — the pack loads. What is missing is review and audio, not
wiring, which confirms §3 across all nine chapters rather than only Clew Bay.

| Chapter | Exercises | Bound | Members | QA states |
| --- | --- | --- | --- | --- |
| `mayo.clew-bay` | 3 | 2 | 2 | qa_passed 1, spot_flagged 1 |
| `mayo.kin-alliances` | 4 | 3 | 6 | unreviewed 5, spot_flagged 1 |
| `mayo.rockfleet` | 8 | 4 | 4 | unreviewed 5 |
| `mayo.power-at-sea` | 4 | 3 | 4 | unreviewed 4, qa_passed 2 |
| `mayo.bingham-pressure` | 4 | 3 | 5 | spot_flagged 4, unreviewed 3 |
| `mayo.road-to-london` | 4 | 3 | 4 | spot_flagged 2, unreviewed 2 |
| `mayo.in-the-record` | 5 | 3 | 3 | unreviewed 2, spot_flagged 1 |
| `mayo.royal-answer` | 3 | 1 | 2 | unreviewed 2 |
| `mayo.return-afterlife` | 3 | 3 | 7 | unreviewed 7 |

**No chapter is review-ready.** Findings: **39** bound members not reviewed, **17** bound
members with no bundled clip, **9** lexeme-carrying exercises with no member reference,
**4** comprehension exercises with none (expected — they teach no lexeme), and two
state-consistency findings below.

Clew Bay remains the cheapest first chapter: **1** unreviewed member (`as.from-mayo`),
**1** unbound exercise (`match-coast`), and no missing audio.

### 6.1 The two stores disagree about review state

`ainm.grainne-named` records **every v2 review approved** while the **v1 member the app
actually loads is `generated_unreviewed`**. Only the v1 answer reaches the runtime, so
the member is unreviewed as far as the app is concerned regardless of what v2 says.

The same member also contradicts *itself*: its v2 `learner_release` is `blocked` with
reasons `editorial_review_pending, pedagogy_review_pending, irish_language_review_pending`
— stale against its own approved review records. It is the only member in **7,060** with
that contradiction, which points at the contract-repair migration rather than at a
systemic fault.

This matters beyond tidiness: `rank_slice_candidates.py` reads `states.reviews` to mark
lines "already approved — no review time needed", and **4** of the 60 selected lines
carry that mark. At least one of them is not approved anywhere the runtime can see.
Treat that flag as provisional until the stores agree.

### 6.2 The bind rule now reads `pairs[].left`

**Rule change, 2026-08-06.** `CountyStoryPack.validatePhraseFamilyMembers` previously
bound only against `answer`, `audioText`, and `modelText`. A `matching` exercise answers
`"all pairs"` and carries its Irish in `pairs[].left`, so matching exercises could not
name a phrase-family member at all — adding `phraseFamilyMemberIDs` would have failed the
pack at load with `phraseFamilyMemberMismatch`. Pair left sides are now bind targets.

The rule stays strict in the direction that matters: a member matching *no* pair still
throws, covered by `testMatchingRejectsAMemberThatMatchesNoPair`. The Python audit mirrors
the same targets so the two cannot drift.

With the rule widened, the nine lexeme-carrying unbound exercises resolve three ways:

| Classification | Count | What it means |
| --- | --- | --- |
| `bindable_now` | **4** | matching exercises whose pairs resolve to existing catalog members — adding the ids is pure wiring |
| `bindable_needs_member` | **2** | an Irish bind target with bundled audio, but no member carries the text |
| `unbindable_by_rule` | **3** | the bind targets carry no Irish at all |

**The four `bindable_now` exercises** cover all **15** matching pairs, each resolving to
an exact citation member with bundled audio: `match-coast` → `farraige.citation`
(**`qa_passed`**), `ba.citation`, `ait.citation`; and the same pattern in `match-kin`,
`match-household`, and `match-record`.

**The two `bindable_needs_member`** are `mayo.rockfleet.listen-build-together` and
`mayo.rockfleet.speaking`, which both bind against *"Tá muid go léir."* — a line with a
bundled, checksummed clip that **no member in either store carries**. One authored v1
member binds both.

**The three `unbindable_by_rule`** are the two sequencing `sentenceConstruction` exercises
(English ordering prose) and the `grammarDiscovery` exercise (an English rule statement).
These are not content gaps and no authoring fixes them; they simply teach through English
framing rather than through a bound Irish string.

**Not yet verified in the app.** The Swift change type-checks cleanly, and the two new
XCTest cases are written, but this host has no CoreSimulator runtime, so the iOS test
suite has not been run. Wiring the four exercises should follow a real test run, not
precede it.

## 7. What this does not change

D35 stands: the harvest is frozen and the credits stay a regeneration reserve. Nothing
here approves Irish, and a bound exercise is not a reviewed one. Chapter binding is
plumbing; the gates in `STATUS.md` remain exactly where they were.
