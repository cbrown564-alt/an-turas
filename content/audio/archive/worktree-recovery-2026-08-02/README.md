# Quarantined worktree audio recovery

This directory preserves 20 Irish MP3s recovered from the dirty
`codex/build-clew-bay-learning-run` worktree on 2026-08-02.

The files were produced by the retired pre-D31 bulk-inventory path. Their snapshot
records identify the locked Irish Cultural Guide voice, `eleven_v3`, language `ga`,
`mp3_44100_192`, exact text, source phrase-family record, duration, byte count, and
SHA-256 checksum. The included source files record the dry-run planner that assembled
that inventory. The snapshots cover the larger worktree catalog; only the 20 files in
`clips/` are preserved here.

These files are deliberately **not** in the runtime audio directory, canonical v2
batch ledger, or learner-release inventory:

- 19 slugs were absent from the canonical bundle;
- `graainne-is-ainm-di.mp3` conflicts with a different canonical capture for the same
  slug;
- none has a complete registered D31/D32 request, claim, provider-result, and batch
  identity trail.

Do not copy these files into `ios/AnTuras/Resources/Audio/` directly. A future recovery
must migrate the exact text into a registered v2 family and batch, verify the archived
checksum and voice snapshot, resolve the `graainne-is-ainm-di` collision explicitly,
and leave audio QA and learner release pending.

The authoritative current runtime remains
[`../../../../ios/AnTuras/Resources/Audio/manifest.json`](../../../../ios/AnTuras/Resources/Audio/manifest.json).
