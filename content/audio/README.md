# Irish audio inventory (ElevenLabs sprint)

Canonical frozen Irish strings for teaching audio. Runtime playback keys off
**spoken text → slug → MP3** (`Speech.swift`), not pack resource IDs.

## Files

| File | Role |
|------|------|
| `irish-inventory-v1.json` | Canonical inventory: every Irish string to generate |
| `atlas-headwords-v1.json` | Provisional 20 lemmas × 32 counties |
| `atlas-headwords-v1.md` | Human-readable atlas bank |
| `launch-phrases-conversations-v1.json` | Launch phrase + conversation banks |
| `archive/` | Checksum lists after generation batches |

## Inventory entry schema

```json
{
  "text": "farraige",
  "slug": "farraige",
  "kind": "headword",
  "counties": ["mayo"],
  "gloss": "sea",
  "source": "draft-pack",
  "qa_state": "pending_generation"
}
```

- `kind`: `headword` | `phrase` | `conversation`
- `source`: `draft-pack` | `invented` | `weave` | `freeze-fixture` | `legacy-chapter`
- `qa_state`: `pending_generation` | `generated_unreviewed` | `spot_flagged` | `qa_passed`

## Bind rule

After inventory freeze, launch exercises may only set `audioText` to strings present
in `irish-inventory-v1.json`. New Irish without a clip stays silent until a
post-ElevenLabs provider can regenerate.

## Rebuild

```bash
python3 tools/tts-bakeoff/assemble_irish_inventory.py
python3 tools/tts-bakeoff/build-production-audio.py --from-inventory --dry-run
python3 tools/tts-bakeoff/build-production-audio.py --from-inventory --kind headword
```
