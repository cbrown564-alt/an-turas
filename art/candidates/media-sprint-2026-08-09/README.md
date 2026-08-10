# Media sprint candidates — 2026-08-09

This directory contains non-shipping still masters and their metadata sidecars for
the two-day generation sprint. Every generated file starts
`generated_unreviewed`. Promotion still follows `art/README.md` and requires review
against `docs/MEDIA-AUDIT.md`, `DESIGN.md`, and the relevant story pack.

## Naming

- Still master: `<asset-id>--t<two-digit-take>.png`
- Still sidecar: `<asset-id>--t<two-digit-take>.json`
- Motion master: `<video-id>--t<two-digit-take>.mp4`
- Motion sidecar: `<video-id>--t<two-digit-take>.json`
- Derived fallback: `<video-id>--t<two-digit-take>--fallback.jpg`

The asset id names the intended durable resource. A take id identifies one provider
result and is never reused. Raw masters and sidecars stay here; approved delivery
encodes are copied into the shipping asset location only after promotion.

## Required metadata

Each sidecar records the stable job and take ids; county, story, chapter, placement,
and narrative purpose; prompt and exclusions; provider/model/task/settings; generation
time; parent or reference assets; generated-versus-documentary status; likeness,
evidence, and rights risks; checksum and technical facts; review scores, disposition,
and notes; and any derived motion or fallback ids.

The manifest is the queue and roll-up. Sidecars are the canonical record of what was
actually generated.
