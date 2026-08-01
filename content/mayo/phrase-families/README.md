# Mayo phrase-family densify index

*D30 scale-out after *farraige* pedagogue + native QA pass (2026-08-01).*

**Source of truth:** `content/mayo/phrase-families/`. Bundled copy for the runtime
catalog: `ios/AnTuras/Resources/PhraseFamilies/mayo/` (keep in sync when editing).

## Status — all 20 Mayo taught lexemes densified

| Family | File | Members | Invented | Status |
|---|---|---|---|---|
| *farraige* | `farraige.v1.json` | 4 | 2 | **qa_passed_scale_ready** (B+C craft ACCEPT) |
| *bá* | `ba.v1.json` | 4 | 1 | densify_draft |
| *long* | `long.v1.json` | 5 | 0 | densify_draft |
| *áit* | `ait.v1.json` | 4 | 1 | densify_draft |
| *caisleán* | `caislean.v1.json` | 5 | 0 | densify_draft |
| *as* | `as.v1.json` | 3 | 0 | densify_draft |
| *caill* | `caill.v1.json` | 3 | 0 | densify_draft |
| *iarr* | `iarr.v1.json` | 5 | 0 | densify_draft |
| *téigh* | `teigh.v1.json` | 4 | 0 | densify_draft |
| *ainm* | `ainm.v1.json` | 4 | 0 | densify_draft |
| *mise* | `mise.v1.json` | 4 | 1 | densify_draft |
| *tar* | `tar.v1.json` | 4 | 0 | densify_draft |
| *freagair* | `freagair.v1.json` | 4 | 1 | densify_draft |
| *tabhair* | `tabhair.v1.json` | 4 | 0 | densify_draft |
| *arís* | `aris.v1.json` | 3 | 0 | densify_draft |
| *cósta* | `costa.v1.json` | 4 | 0 | densify_draft |
| *teaghlach* | `teaghlach.v1.json` | 4 | 0 | densify_draft (kin) |
| *mac* | `mac.v1.json` | 4 | 1 | densify_draft (kin) |
| *bean* | `bean.v1.json` | 3 | 1 | densify_draft (kin) |
| *deartháir* | `dearthair.v1.json` | 4 | 1 | densify_draft (kin) |

## Learning-page wiring

Exercises may declare `phraseFamilyMemberIDs`. Python and Swift validators require each
id to resolve in this catalog and to match `answer` / `audioText` / `modelText` under
the bind rule (fada-folded).

Wired where answers already matched members:

- Mayo draft: 25 exercises
- Bundled Rockfleet: 6 exercises
- Farraige B/C + Clew Bay freeze fixtures: bound where applicable

## Rules

- Prefer attested pack / inventory utterances; ≤2 invented per family.
- Do not generate TTS until a consuming Learning exercise needs the clip.
- Each new family still needs its own pedagogue + native QA before teaching claims
  (except *farraige*, already passed).
- Sync edits into `ios/AnTuras/Resources/PhraseFamilies/mayo/` after changing content.
