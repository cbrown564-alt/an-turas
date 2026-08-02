# Irish audio authoring, capture, and release

Irish audio now has three separate records:

1. county/story phrase-family documents own what a line means and how an exercise uses it;
2. generation batch manifests own capture requests and provider results; and
3. the spoken-text inventory and bundled MP3s own runtime playback.

Presence in one record never implies approval in another. In particular, captured or
unreviewed audio is not learner-release approval.

## Canonical files

| File | Role |
|------|------|
| `authoring/phrase-family-store-v2.json` | Appendable index of county/story/sense family documents, capacity policy, and registered batches |
| `authoring/schemas/phrase-family-v2.schema.json` | Member contract: target, text, binding, exercise use, provenance, risks, and orthogonal states |
| `authoring/schemas/generation-batch-v1.schema.json` | Deterministic capture handoff: identity, voice, claim, request, retry, result, checksum, error, and QA |
| `authoring/voice-profiles-v1.json` | The single user-locked Irish voice/model profile |
| `../{county}/phrase-families/authoring-v2/*.v2.json` | Canonical family/member authoring documents beside county story content |
| `authoring/batches/*.json` | Draft, approved, or closed generation manifests; a draft never permits provider calls |
| `irish-inventory-v1.json` | Legacy/runtime spoken-text registry and current clip QA state |
| `atlas-headwords-v1.json` | Provisional 640 county placements; not 640 reviewed families |
| `launch-phrases-conversations-v1.json` | Legacy migration input, not evidence that its lines are attested or approved |
| `archive/` | Legacy checksum lists from completed generation batches |

The retired four-slot `structured-authoring-queue-v1.json` and its seed are not
canonical and must not feed generation. Their useful 16 strings and corrected
provenance live at
`authoring/migration/structured-authoring-v1-fixture.json`, where
`generation_allowed` is false.

## Phrase-family member contract

A complete v2 member names:

- a stable lexeme, sense, part of speech, target form, and morphology;
- canonical NFC Irish text, idiomatic English intent, the production inventory slug,
  and a text SHA-256;
- county, story record, exact atlas placement and gloss, place, setting, and the
  learner's role;
- learning stages and member roles, dialect/register, a concrete purpose, and one or
  more implemented consuming exercises;
- structured repository/external provenance, a durable invented flag, and controlled
  risk flags; and
- independent authoring, editorial/pedagogy/Irish-language review, capture-request,
  audio-QA, and learner-release states.

Families are county/story/sense-specific and may contain any number of members. Roles
are coverage labels, not four exclusive slots: several lines may serve sentence use,
dialogue, later reuse, morphology, openings, or recaps. One spoken line may serve
several members; generation batches merge it by normalized text and voice rather than
duplicating TTS.

Draft members may remain incomplete only while capture is not requested and release is
blocked. Invented pedagogical text remains `invented: true` after review. It may request
capture only after an explicit pedagogy approval record, or under an explicit
fixture-only owner exception; neither path grants learner release.

## Authoring handoff

For each new slice, the authoring agent must:

1. append a county/story/sense `.v2.json` family, with every complete member bound to an
   existing story record, exact atlas placement/gloss, and consuming exercise record;
2. keep `invented: true` and the `invented_text` risk on composed pedagogical lines,
   recording only reviews that actually occurred;
3. register the family id/path in sorted order in `phrase-family-store-v2.json`, then
   run `check` and inspect `report` without treating its counts as approval;
4. build a purpose-named draft batch with the locked profile and register the inspected
   manifest in the store; and
5. leave provider execution blocked until capture requests name the exact batch line,
   the batch and line are approved, and the executing worker owns an active claim.

The offline tool creates and validates handoff records only. It contains no ElevenLabs
client and grants no authority to generate audio.

## Capture manifest and resumability

`tools/structured_audio_authoring.py` is offline and never calls a provider:

```bash
python3 -B tools/structured_audio_authoring.py check
python3 -B tools/structured_audio_authoring.py report
python3 -B tools/structured_audio_authoring.py build-batch \
  --batch-id irish.exercise.001 \
  --member-id ainm.grainne-named \
  --voice-profile-id voice.irish-cultural-guide.eleven-v3.v1 \
  --created-at 2026-08-01T12:00:00Z \
  --purpose "Mayo retrieval and dialogue capture 001" \
  --output content/audio/authoring/batches/irish.exercise.001.json
```

New manifests are drafts with `provider_calls_allowed: false`. Before execution, each
member needs a valid capture request, each line needs explicit batch approval, and a
partitioned batch needs a claim owner and lease. Provider execution records request id,
attempt count, retry timing, structured errors, canonical output path, byte count,
duration, and SHA-256. `succeeded` is valid only when the named MP3 exists and its
checksum matches. Text membership in `irish-inventory-v1.json` never sets that result.
After inspecting a new draft, register its id/path in the store's sorted
`batch_documents` list; unregistered manifests are not part of the canonical handoff.

## Locked Irish voice and model

All Irish generation—teaching, story, and dialogue—must use exactly:

- provider: ElevenLabs;
- voice: Irish Cultural Guide (`NPWroowF4phQhaPWjXPj`);
- model: `eleven_v3`;
- language: `ga`;
- output: `mp3_44100_192`; and
- voice settings: provider defaults, with no overrides.

The user has tested alternatives and found them poor at Irish pronunciation. The
contract forbids an alternate Irish voice/model bake-off and any V2/V3 migration.
Batch manifests cannot override the locked profile. A deviation requires a new explicit
user decision and a versioned contract change before any manifest can validate.

## Pre-expiry capacity plan

These are project planning targets, not evidence of a universal industry standard:

- **Primary:** capture approximately **3,000–5,000** controlled, metadata-rich An Turas
  utterances, then select roughly **1,200–1,500** of the strongest exercise-integrated
  lines for the first learner-facing release corpus.
- Within Irish, prioritise exercise-bound phrase families, reusable dialogue roles,
  place/story openings and recaps, then controlled listening contrasts only where a
  defined learning action requires them.
- Reserve capacity to regenerate weak clips. No Irish voice/model bake-off or migration
  is permitted; configuration work is bounded by the locked profile and requires a new
  explicit user decision before any deviation.
- Reserve a bounded minority of remaining prepaid credits for **Speaking Clearly**
  paired cue demonstrations. That is a separate project's work and must use its own
  contract-compliant records.

Do not exceed 5,000 An Turas captures unless every additional line names a phrase
family, lesson pattern, dialogue variation, story/place opening or recap, or another
documented learning use. Every generated line still needs contract-compliant text,
context, provenance, and generation control.

## Coverage accounting

`report` currently distinguishes 640 atlas placements, 191 orthographic spellings, 12
spellings with multiple glosses, authored sense families, covered placement ids,
captured members, and release-eligible members. The representative v2 proof covers only
two Mayo placements, two senses, and four utterances. It is evidence that the contract
works, not broad county coverage or linguistic validation.

## Runtime bind rule

Launch exercises may only set `audioText` to strings in `irish-inventory-v1.json` and
backed by a bundled clip. `tools/validate_county_pack.py` rejects unknown audio and now
resolves both legacy v1 and canonical v2 phrase-family members. The legacy inventory
builder remains available for existing clips, but new structured capture is handed off
through a v2 batch manifest rather than inferred from inventory membership.
