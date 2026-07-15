# An Turas

Build an evidence-grounded iOS experience for learning Irish through the real stories of Ireland. Keep language and place inseparable. Avoid generic gamification, invented participation in history, and decorative Irishness.

Deepen the current proof before adding counties: island → Mayo dossier → Gráinne Ní Mháille → evidence → first Irish → collection.

## Document owners

- `PRODUCT.md`: audience, promise, behavior, and product principles
- `DESIGN.md`: visual and interaction system
- `STATUS.md`: current facts, active work, blockers, and next steps
- `docs/DECISIONS.md`: durable product decisions
- `docs/STRATEGY.md`: launch strategy and unresolved strategic questions
- `docs/README.md`: documentation index and authority map

Update the owner; do not add a competing plan or summary. Story slates and exploratory reports remain inputs until a recorded decision promotes them.

## Implementation

- The app is in `ios/AnTuras/`; tests are in `ios/AnTurasTests/` and `ios/AnTurasUITests/`.
- `ios/project.yml` owns the generated Xcode project. Regenerate it after target, source, resource, or build-setting changes.
- Keep historical claims, Irish text, pronunciation, sources, and uncertainty inspectable. Generated art must not contain interface copy or pose as documentary evidence.
- Compare materially different visual directions in the working flow when composition is unresolved.
- Run relevant tests and inspect changed screens on an iPhone simulator. Check Dynamic Type, VoiceOver labels, Reduce Motion, touch targets, and both appearances when affected. Compilation alone is not app verification.
