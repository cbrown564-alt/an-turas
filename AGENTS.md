# An Turas agent guidance

Global guidance in `~/.codex/AGENTS.md` applies here.

## Product mandate

Build an evidence-grounded iOS experience for learning Irish through the real stories of Ireland. Preserve the learner as themselves, keep language and place inseparable, and avoid generic gamification, invented participation in history, or decorative Irishness.

The current product proof is one complete loop: island → Mayo dossier → Gráinne Ní Mháille → evidence → first Irish → collection. Deepen and verify that loop before repeating it across counties.

## Canonical documents

- `PRODUCT.md` owns the audience, promise, product behavior, and design principles.
- `DESIGN.md` owns the visual and interaction system.
- `STATUS.md` owns current facts, active work, blockers, and next steps.
- `docs/DECISIONS.md` owns durable product decisions.
- `docs/STRATEGY.md` owns launch strategy and unresolved strategic questions.
- `docs/README.md` is the documentation index and authority map.

Update the owner document instead of adding a competing plan or summary. Treat story slates and exploratory reports as inputs until a decision promotes them.

## Implementation boundaries

- The active application is `ios/AnTuras/`; tests are in `ios/AnTurasTests/` and `ios/AnTurasUITests/`.
- `ios/project.yml` owns the generated Xcode project. Regenerate after target, source, resource, or build-setting changes.
- Keep historical claims, Irish text, pronunciation, source status, and uncertainty inspectable. Generated art must not contain interface copy or pretend to be documentary evidence.
- For visual prototypes, compare genuinely different compositions in the working flow. Judge image-led and text-led directions on equal terms.
- Verify Swift changes with the relevant unit or UI tests and inspect changed screens on an iPhone simulator. Check Dynamic Type, VoiceOver labels, Reduce Motion, touch targets, and light/dark appearance when affected.

## Commands

```sh
xcodegen generate --spec ios/project.yml
xcodebuild -project ios/AnTuras.xcodeproj -scheme AnTuras -destination '<installed iOS Simulator>' test
```

Use a concrete installed simulator destination. Do not claim the complete app is verified from compilation alone.
