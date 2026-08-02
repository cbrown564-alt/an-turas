# Irish pedagogy explanations

This directory is the authoring home for short English-framed explanations around
carefully scoped Irish words and sentences. It is deliberately separate from the
runtime county packs and the Irish audio phrase-family/batch contracts.

The first corpus is
`irish-explanations-v1.json`. It is a reversible sidecar because the existing
`grammarDiscovery` runtime shape can carry worked cases and a withheld rule, but does
not carry line-level source references, invented pedagogical framing, deterministic
risk flags, or independent pedagogy/Irish-language/pronunciation/release states.

Each line must keep the Irish examples exact, identify repository evidence, and label
the English framing as invented pedagogical composition. `scope_guard` is required so
the explanation names what it does not claim. The validator infers mechanical flags
from visible text and lesson area; it does not decide whether Irish is grammatical,
idiomatic, dialectally appropriate, or correctly pronounced.

Review and release are separate:

- `pedagogy`, `irish_language`, and `audio_pronunciation` reviews remain independent;
- the corpus may remain an authoring draft while all learner-release states are blocked;
- no line in this first corpus authorizes TTS, runtime bundling, or teaching claims; and
- an eventual runtime bridge must preserve exact Irish text, provenance, risk flags, and
  the pending gates rather than treating an explanation as approval.

Run the standard-library validator from the repository root:

```bash
python3 -B tools/validate_pedagogy_corpus.py report
python3 -B tools/validate_pedagogy_corpus.py check
```

The count report is intentionally explicit: it reports lesson and line totals,
review-state totals, release-state totals, and deterministic risk flags. It does not
claim native-speaker, pedagogy, historical, or pronunciation review.
