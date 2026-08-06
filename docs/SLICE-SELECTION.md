# Slice selection — ranking the frozen corpus for review

*Draft proposal, 2026-08-06. Awaiting approval; nothing here is implemented.*

`STATUS.md` §6 step 1 says to rank the captured material by story relevance, reuse,
pedagogical purpose, risk, and mechanical audio quality. This document proposes exactly
how, against fields that actually exist in the repository. Read with `PRODUCT.md`,
`docs/DECISIONS.md` D22/D30/D31/D35, and `content/audio/README.md`.

## 1. What the ranking is for

The harvest is frozen (**D35**). **6,624** clips exist and **0** are learner-release-
eligible. The scarce resource is no longer credits — it is qualified Irish-speaker
review time, plus pedagogue and historical review.

So the ranking's job is **not** to grade the corpus. It is to answer one question:

> Which small, coherent set of lines should a qualified speaker review *first*, such
> that approving it unlocks one complete, provable learner-facing slice?

Everything below follows from that. A line that is excellent but isolated ranks below a
mediocre line that a Mayo chapter cannot run without.

### Two rankings, not one

`STATUS.md` §6 currently reads as a single ranking. It is two, and they treat risk in
opposite directions. Conflating them would produce a slice made of the corpus's most
dangerous material.

| | **A · Slice selection** | **B · Review order** |
| --- | --- | --- |
| Question | Which lines form the first slice? | Within the slice, what does the reviewer see first? |
| Scope | The eligible Mayo pool | The selected slice only |
| Risk acts as | **Penalty** — a risky line is an expensive, failure-prone first proof | **Boost** — review the riskiest first, so failures surface early and cheap |
| Rationale | D22 representative-slice discipline: prove the pattern on solid ground | The existing sampler's logic: risk is where review time earns most |

The existing `sampling/d32-risk-stratification-*.json` is already ranking **B** and
should be reused for it. Only **A** needs building.

## 2. Candidate pool — hard gates before any scoring

Gates are pass/fail and are applied first. Scoring never rescues a gated-out line.

1. **Captured and succeeded.** `batch_states` contains `succeeded`
   (**6,262** of **6,271** unique text/voice keys qualify).
2. **Runtime clip present and checksum-verified** at the filesystem/manifest layer
   (currently **6,624/6,624**).
3. **Not retired.** Excludes the **2** Corca Dhuibhne semantic quarantines.
4. **Not a capture blocker.** Excludes anything in the review-queue audit's **17**
   hard findings.
5. **Not technically quarantined.** Currently **0**. The **43** duration/level outliers
   are *not* gated out — they are scored down and flagged for listening.
6. **County and story scope** — see §3.

## 3. Scope: which slice

**Proposal: Mayo / Gráinne 1593.** It is the only county with a nine-chapter production
draft, it owns the verified representative Rockfleet loop, and D30's first proof
(*farraige*) already lives there. Proving the pattern anywhere else would abandon the
one runtime path that is known to work end to end.

Pool sizing, from the 2026-08-05 stratification:

- **236** unique text/voice keys tagged `mayo`, across **115** senses
- **212** carry story `d32.mayo.grainne-1593`; **24** carry `mayo.grainne-1593`
- **all 236** have at least one `exercise_consumer_id`
- risk scores run **13–26** (mode **18**)

Two scope wrinkles need your call (§7): the two story-id spellings, and **11** Mayo-
tagged keys whose story ids belong to Tyrone, Donegal, Laois, Dublin, Waterford, or
Down — shared lines that surface in multiple county stories.

`priority` is **P0** on **6,244** of **6,271** keys and carries no information. It is
excluded from scoring.

## 4. Criteria

Each criterion scores **0–5** from deterministic fields, then multiplies by its weight.
No hand-tuning per line; if a line scores wrong, the rule is wrong and gets fixed.

### C1 · Story relevance — weight **5**

Does a Mayo chapter actually need this line?

| Score | Condition |
| --- | --- |
| 5 | Exercise consumer bound to a chapter in the nine-chapter draft, and story id is the Mayo Gráinne story |
| 3 | Mayo story id, exercise consumer exists, chapter binding indirect |
| 1 | Mayo county tag only; story id belongs to another county's story |
| 0 | No exercise consumer (cannot occur in this pool — all 236 have one) |

Highest weight because it is the only criterion that speaks to whether approval unlocks
anything. A slice of unbound lines is inventory with a review stamp.

### C2 · Reuse — weight **4**

How much does one approval buy? Counts distinct `exercise_consumer_ids`,
`family_ids`, and `placement_ids`, plus cross-county recurrence of the normalized text.

**Reuse and duplication must be separated.** The `duplicates` stratum holds **244**
keys, and they are two different things wearing one label:

- identical text, **consistent** intent across counties → genuine reuse, score **up**
- identical text, **conflicting** intent → a semantic defect, score **0** and route to
  C4 as a risk flag, never into the first slice

### C3 · Pedagogical purpose — weight **4**

| Score | Condition |
| --- | --- |
| 5 | Consumed by a D30 pattern (sentence construction with a surround change; delayed reuse) **and** appears among the pedagogy sidecar's **148** exact examples |
| 3 | Consumed by a D30 pattern, no sidecar coverage |
| 2 | Carries target morphology (mutation/inflection) with a clear teaching role |
| 0 | Decorative or atmospheric only |

### C4 · Risk — weight **−3** (penalty; see §1)

Built from `risk_score`, `risk_flags`, and `categories`. Penalized hardest:
`invented_text` without a source, conflicting-intent duplicates, and the
names/places sensitivity that `STATUS.md` already flags as unusually dialect- and
convention-dependent.

This deliberately pushes proper names *out* of the first slice. They are the material
most likely to fail native review and the least diagnostic about whether the runtime
pattern works. They get their own later pass.

### C5 · Mechanical audio quality — weight **3**

| Score | Condition |
| --- | --- |
| 5 | Track D pass; duration and level near distribution centre |
| 2 | Track D pass; near a distribution edge |
| 0 | Among the **43** listening-review outliers |

Mechanical only. Per `STATUS.md`, this cannot establish grammatical, dialectal,
semantic, or pedagogical correctness, and a high C5 is never evidence of good Irish.

## 5. Selection is not just top-N

Ranking alone would return sixty variants of the strongest lexeme. After scoring, select
greedily under coverage constraints, in the manner of the risk sampler's per-stratum
quota:

- **cap per family** — no family may exceed ~15% of the slice
- **cover both D30 consuming patterns** — surround change *and* delayed reuse
- **cover the chapters the slice claims to prove**, not one chapter deeply
- **include the *farraige* family** — it is D30's designated first proof, and continuity
  of the proof matters more than its score

Output is deterministic and seeded, so the same corpus yields the same slice.

## 6. Deliverable

Matching the existing tooling contracts:

- `tools/rank_slice_candidates.py` — offline, read-only, no provider calls
- `content/audio/authoring/slice-selection/d35-mayo-slice-<date>.json` — every
  candidate with per-criterion subscores, the applied gates, the selected slice, and
  the coverage constraints that bound it
- a short human-readable review packet: the slice grouped by chapter and family, with
  Irish text, English intent, provenance, and risk flags visible per line

The report must make a reviewer able to say "this line is wrong, and here is why the
ranker chose it." Scores are auditable, not authoritative.

**What this does not do:** it does not approve anything, does not change any state in
the v2 store, does not touch the credit reserve, and does not imply learner release.
Ranking is review *planning*, exactly as the risk stratification is.

## 7. Open questions

1. **Slice size.** Recommend **~60 lines** — one focused native-speaker session, and
   enough to cover both D30 patterns across several chapters. D31's 1,200–1,500 first
   learner corpus is the eventual target, not the first review batch.
2. **Scope confirmation.** Mayo / Gráinne 1593, per §3?
3. **Risk direction.** Confirm risk penalizes slice selection (§1). This is the one
   place this proposal departs from a plain reading of `STATUS.md` §6.
4. **The 11 cross-county keys** — include as reuse-rich, or exclude as scope creep?
   Recommend excluding from the first slice and treating shared lines as a later,
   higher-value pass once the pattern is proven.
5. **Weights.** 5/4/4/−3/3 as above, or a different balance?
