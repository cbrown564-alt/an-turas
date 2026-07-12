---
target: Phase 1 personal atlas
total_score: 22
p0_count: 1
p1_count: 4
timestamp: 2026-07-12T22-08-52Z
slug: ios-anturas-personalatlassearchview-swift
---
# Phase 1 Personal Atlas — Adversarial Critique

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|---|---:|---|
| 1 | Visibility of System Status | 3 | Search and save update immediately, but result truncation, coverage depth, and research state are not clear. |
| 2 | Match System / Real World | 2 | Warm personal language is undermined by internal labels and premature Irish canonicalisation. |
| 3 | User Control and Freedom | 3 | Native back, clear search, reversible save, and sheet dismissal work; unresolved content has weak recovery. |
| 4 | Consistency and Standards | 3 | Native structure is coherent, but fixed type and gesture-built selectors break iOS accessibility conventions. |
| 5 | Error Prevention | 2 | Broad matching plus silent truncation can turn low-specificity suggestions into apparent ambiguity. |
| 6 | Recognition Rather Than Recall | 2 | Variants help, but ambiguity rows omit distinguishing evidence and sources require mental cross-referencing. |
| 7 | Flexibility and Efficiency | 1 | Search is limited to 80 bundled subjects; no broad Logainm shell, map/address point, or direct learning route. |
| 8 | Aesthetic and Minimalist Design | 3 | The opening is strong; result pages become long sequences of similarly weighted sections. |
| 9 | Error Recovery | 2 | No-result copy is honest, but pack failure crashes and research gaps offer little action. |
| 10 | Help and Documentation | 1 | No family-research handoff, contextual certainty help, correction path, or accessible map/list. |
| **Total** | | **22/40** | **Acceptable foundation; do not advance yet** |

## Anti-Patterns Verdict

**Visual shell: pass. Feature as a whole: fail.** The first-run surface feels authored and on-brand: restrained limestone field, serif hierarchy, quiet hooks, standard iOS navigation, and no gamification, heraldry, tourist-green kitsch, or generic SaaS card grid.

The illusion breaks across results. The corpus says it was generated; authored subjects reuse family-wide story-beat templates; and the UI exposes production labels such as `AUTHORED`, `FOUNDATION`, and “pilot pack.” All 110 pronunciation records are unavailable. The result is a polished shell around visibly programmatic content—the exact opposite of the feature's “made with care for what I entered” promise.

The deterministic detector returned exit 0 and `[]`, but this is a non-signal: it is an HTML/CSS rule engine and found nothing in SwiftUI. Native technical inspection found the issues the detector could not. No browser overlay applies to this iOS target.

## Overall Impression

**Phase 1 is code-complete, not phase-complete. Do not advance to Phase 2.** Debug and Release simulator builds pass, the bundle is structurally consistent, search works, privacy is thoughtful, and the first encounter is emotionally precise. But the release manifest is still `draft` with all six sign-offs false; the name content explicitly awaits specialist review and a licensed modern surname authority; there is no pilot evidence for comprehension, recall, trust, or engagement; and several central UI paths violate the project's accessibility and evidence contracts.

The single biggest opportunity is to stop treating breadth as proof. A smaller set of genuinely reviewed, audible, source-specific, subject-specific experiences would validate this product thesis better than 80 pages whose differences are mostly data substitutions.

## What's Working

1. **The hook belongs in the product.** “A name you carry” and “A place you know” are intimate without being extractive, and they sit beside rather than displace the island journey.
2. **Privacy and family-history boundaries are unusually good.** Raw searches are not persisted; recent history is opt-in and stores published subject IDs only; surname pages explicitly distinguish name history from a user's family history.
3. **The technical foundation is coherent.** Debug and Release builds succeed. The pack has 80 index entries and 80 subjects with no missing pairs, duplicate IDs, broken evidence references, invalid coordinates, or currently unknown routes.

## Priority Issues

### [P0] Phase 1's acceptance gate has not been met

**Why it matters:** `tools/content-review/manifest.json` still marks the surface `draft` and all writer, linguist, historian, onomastics, audio, and native-QA sign-offs are false. The content note says the name pack awaits specialist review and licensing. Nevertheless the UI presents claims as “Reviewed … pilot-editorial · reviewed-for-pilot.” There is no recorded hard-case study or evidence for next-day recall, surname/family comprehension, trust, or downstream engagement.

**Fix:** Freeze Phase 2. Make release state mechanically block unreviewed claims; replace the generic reviewer with named domain review; complete rights and claim-location records; run the declared hard-case study; publish the resulting exit-gate table before changing phase status.

**Suggested command:** `$impeccable harden`

### [P1] The content is broad but not yet personal or lovable

**Why it matters:** The 80-subject corpus contains repeated story-beat arrays across all 19 authored places, 15 authored surnames, and 14 authored given names. All 110 pronunciation records are unavailable, and 85 lack phonetic guidance. Twenty-eight of 30 place entries use editorial synthesis plus a generic Logainm homepage link rather than a subject record. A user opening several entries will notice the scaffold immediately.

**Fix:** Either shrink the showcase to the subjects the team can genuinely author and review, or split the experience visibly into a small authored layer and a modest verified index. Give every showcase subject a distinct narrative centre, useful pronunciation, claim-specific evidence, and an ending connected to Irish or the journey. Remove `AUTHORED` from user-facing UI until it denotes actual bespoke editorial treatment.

**Suggested command:** `$impeccable polish`

### [P1] The primary flow violates the accessibility contract

**Why it matters:** The Phase 1 views mostly use fixed point sizes—including labels below the 11-point floor—rather than semantic Dynamic Type. Historical-form chips are `.onTapGesture` views with no Button trait, selected-state semantics, or guaranteed 44-point target. Search changes are not announced; ambiguity labels discard distinguishing metadata; the search transition ignores Reduce Motion.

**Fix:** Migrate to semantic text styles; make historical forms selectable Buttons with `.isSelected`; enforce 44×44 targets; announce result-count/no-result/truncation changes; retain variant, kind, county/place class, and depth in accessibility values; respect Reduce Motion in search; QA accessibility sizes, VoiceOver, Increased Contrast, and dark mode.

**Suggested command:** `$impeccable audit`

### [P1] Evidence exists in data but disappears at the trust surface

**Why it matters:** The model stores `evidenceIds` and `competingAssertionIds`, and all current references resolve. The sources sheet then renders every assertion followed by every source without linking them. Story beats and branches appear without claim-level provenance. Users must perform their own mental join to understand why the app believes a statement.

**Fix:** Put a “Why we say this” affordance beside each material claim and branch; open directly on its supporting evidence; show recorded form, inference, dispute, and unknown inline; render competing readings and what would distinguish them; use human source titles instead of raw URLs.

**Suggested command:** `$impeccable clarify`

### [P1] Search does not deliver the promised place and ambiguity experience

**Why it matters:** Search covers only 80 bundled subjects, including 30 places, rather than the planned Logainm-backed all-island shell. Prefix and substring results are mixed, then silently capped at 12; static simulation found 22 prefixes exceeding that cap. The ambiguity screen promises distinguishing evidence but supplies no map, source, period, or repeated-place context.

**Fix:** Separate exact matches, genuine duplicates, and broad suggestions; show total and truncation; add confidence thresholds and refinement; provide county, place class, official/local forms, source state, and map/list context before selection; add the reviewed cached Logainm index or explicitly narrow the Phase 1 promise.

**Suggested command:** `$impeccable harden`

## Persona Red Flags

### First-time diaspora member or adult relearner

- Searching Smith foregrounds `Mac Gabhann` before the later caveat, which can feel like the app has converted the user's identity rather than investigated it.
- `AUTHORED`, `FOUNDATION`, and “pilot pack” expose production taxonomy at a personally sensitive moment.
- “Hear it” repeatedly leads to unavailable audio, weakening the most natural bridge into Irish.
- The family-history boundary provides no private worksheet or official archive handoff.
- Most results end with saving/version metadata rather than an earned sentence of Irish or a real road into the journey.

### VoiceOver or large-text user

- Historical-form chips do not reliably expose action or selection.
- Fixed 9.5–14 point labels do not scale with accessibility settings.
- Ambiguity rows omit metadata needed to choose safely.
- Search result changes and truncation are silent.
- Place results provide neither the planned map nor an equivalent accessible list.

### Onomastician, local historian, or careful native speaker

- `pilot-editorial` and `reviewed-for-pilot` read as false authority beside a manifest with no specialist sign-offs.
- Generic Logainm homepage links do not support subject-specific place claims.
- Claim competition exists in the schema but is invisible in the interface.
- Reused story beats make distinct names and places sound editorially interchangeable.

## Minor Observations

- `PersonalAtlasLoader.decode` calls `fatalError` for a missing or malformed pack. The build copies JSON but does not schema-decode it, and there is no test target.
- `xcodebuild test` exits 66 because the scheme has no test action; normalization, ranking, decoding, persistence migration, routes, and accessibility have no regression coverage.
- The sources sheet has no explicit Done button.
- Raw URLs are shown as link labels.
- `saveExcerpt` is modelled but unused; the planned sourced share excerpt is absent.
- Unknown string routes fail silently, though all 16 current route occurrences resolve.
- No name distribution records are present despite the model and product promise.
- The app target is iPhone-only; iPad/Split View is not currently shipped and was not scored as an iPhone defect.

## Questions to Consider

- Is an 80-row generated pilot stronger evidence than eight entries with real sound, source objects, and named expert review?
- If a Smith user sees `Mac Gabhann` before the caveat, has the app respected their name or performed Irishness onto it?
- What specific idea should a user accurately retell tomorrow for each showcase subject?
- Should the emotional ending be a bookmark and content version, or language earned and a real road into the journey?
