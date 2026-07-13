# Content review CMS

*Phase 2 foundation for D9 — low-key review layer, not an enterprise CMS.
Started 12 July 2026.*

## What shipped

| Piece | Path | Purpose |
| --- | --- | --- |
| Review UI | `tools/content-review/index.html` | Story workflow plus personal-subject previews, assertion review, rights/audio/accessibility gates, query demand, and export |
| Manifest | `tools/content-review/manifest.json` | County stories currently in review (Mayo ×2, Offaly, Dublin, Meath) |
| This doc | `docs/CONTENT-REVIEW-CMS.md` | Scope, workflow, next engineering |

Open locally by serving the repository root (the personal review surface reads the
same JSON pack that ships in iOS):

```bash
python3 -m http.server 8765
# then visit http://localhost:8765/tools/content-review/
```

## Workflow (locked to STATUS / pipeline)

`brief → draft → linguist → historian → audio → native_qa → signoff → bundle`

Roles: writer, Irish-language pedagogue (linguist), historian, audio QA / native
speaker. Engineers do not approve history or Irish.

## Personal-atlas progression

`showcase candidate → specialist reviewed → showcase`

The tool stores claim decisions, named reviewers, rights, audio resolution, discipline
sign-offs, accessibility, private query demand counts, and reviewer notes. It disables
advancement while a release gate is open and exports a JSON review log for durable
review. `tools/publish_personal_atlas.py` accepts only the final `showcase` state and
revalidates the gates before producing the public preview payload.

## Non-goals

- Auth, multiplayer comments, or cloud sync
- Editing production JSON in the browser
- Replacing git as source of truth
- Full CMS asset library

Local sign-off state lives in `localStorage` for demo/review sessions only. Durable
approvals belong in the story brief checklist and eventual git-tracked review log.

## Next engineering (when needed)

1. Parse brief markdown into claim-ledger and 20-word panels inside the UI.
2. Diff viewer against `draft.json` / county pack schema.
3. Import a reviewed durable log from the production identity/auth system.
4. Optional: tiny Swift “Review” debug target reading the same manifest.

The browser-local tool is an operational prototype, not a substitute for authenticated
durable approvals. It is sufficient to validate the complete claim-level workflow.
