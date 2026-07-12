# Content review CMS

*Phase 2 foundation for D9 — low-key review layer, not an enterprise CMS.
Started 12 July 2026.*

## What shipped

| Piece | Path | Purpose |
| --- | --- | --- |
| Review UI | `tools/content-review/index.html` | Stakeholder-facing board: story list, workflow stages, sign-offs, notes |
| Manifest | `tools/content-review/manifest.json` | County stories currently in review (Mayo ×2, Offaly, Dublin, Meath) |
| This doc | `docs/CONTENT-REVIEW-CMS.md` | Scope, workflow, next engineering |

Open locally by serving the folder (browsers block `fetch` of JSON from `file://`):

```bash
cd tools/content-review && python3 -m http.server 8765
# then visit http://localhost:8765
```

## Workflow (locked to STATUS / pipeline)

`brief → draft → linguist → historian → audio → native_qa → signoff → bundle`

Roles: writer, Irish-language pedagogue (linguist), historian, audio QA / native
speaker. Engineers do not approve history or Irish.

## Non-goals (v1)

- Auth, multiplayer comments, or cloud sync
- Editing production JSON in the browser
- Replacing git as source of truth
- Full CMS asset library

Local sign-off state lives in `localStorage` for demo/review sessions only. Durable
approvals belong in the story brief checklist and eventual git-tracked review log.

## Next engineering (when needed)

1. Parse brief markdown into claim-ledger and 20-word panels inside the UI.
2. Diff viewer against `draft.json` / county pack schema.
3. Export a `review-log.md` snippet for commit.
4. Optional: tiny Swift “Review” debug target reading the same manifest.

Until then, this HTML surface is enough for board walkthroughs of the launch counties.
