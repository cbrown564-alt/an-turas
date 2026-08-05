# Art layout

Working and shipped stills have separate homes. Do not leave the “real” file in more than one place.

| Path | Role | Ships in app? |
| --- | --- | --- |
| `ios/AnTuras/Assets.xcassets/` | **Only** learner-facing stills and evidence images (plus AppIcon) | Yes |
| `art/exploration/` | Style-branch contact sheets (`--art` debug via `ios/art-exploration` symlink) | Debug only |
| `art/video/` | Omni video exploration clips + prompt sidecars (`docs/OMNI-EXPLORATION.md`); contact sheet `art/video/CONTACT.md` | No until reviewed and promoted |
| `art/direction/` | Locked north-star / palette references for docs | No |
| `art/archive/` | Superseded prototypes (e.g. early Gráinne scenes) | No |
| `art/candidates/` | New generations awaiting review | No |
| `tmp/` | Local screenshots and agent dumps (gitignored) | No |
| `compare/` | Competitive UI reference captures | No |

## Promotion rule

1. Generate into `art/candidates/`.
2. Approve against `docs/MEDIA-AUDIT.md` IDs and `DESIGN.md` (text-free, no fake evidence).
3. Copy into an `Assets.xcassets/<id>.imageset` named to the audit ID.
4. Delete or move the candidate to `art/archive/`.

Never keep an approved still only under `art/` or `docs/`. Never duplicate a catalog imageset as a loose file under `ios/AnTuras/Resources/`.

## Finding Gráinne

- Live dossier coast: `grainne-clew-bay` in `Assets.xcassets`
- Live person hero: `grainne-crossing` in `Assets.xcassets`
- Chapter atmosphere (Mayo pack): `mayo-*` imagesets (e.g. `mayo-clew-bay-coastal`)
- Storyboard north star / palette: `art/direction/grainne-six-episode-*.png`
- Superseded return scene: `art/archive/grainne-return.png`
