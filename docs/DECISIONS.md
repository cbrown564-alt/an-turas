# Decisions log

Short records of decisions that shape everything downstream. Add new entries at the top.

## D35 — Freeze the D32 harvest and hold the remaining credits as reserve (2026-08-06)

**Decision:** Close the D32 emergency Irish audio harvest as a production phase at the
end of cycle 2 (payload `d32.harvest.track-b.2026-08-05`). Do not open cycle 3. The
approximately **50,028** remaining prepaid credits are held as a **regeneration
reserve** for material that survives review, not as capture headroom. Corpus expansion
stops; `STATUS.md` §6 — freeze, select, and prove one learner-facing slice — becomes
the active sequence.

Two small maintenance items remain permitted against the reserve because they close
existing ledger state rather than expand the corpus: re-approving the **7** cancelled
batch lines (~300 estimated credits), and retiring or replacing the **2** Corca
Dhuibhne quarantine members.

**Why:** The harvest achieved its stated objective. **6,624** bundled runtime clips
exist across all **32** counties, checksums verify completely, and remaining resumable
work is zero. What has not moved is review: **zero** lines are learner-release-eligible,
**17** capture blockers and **141** review-before-release items are open, every v2
capture remains `generated_unreviewed`, and no qualified Irish speaker has approved any
subset. D32's own recorded risk — generating faster than the corpus can be attributed,
deduplicated, and assigned a plausible use — is now the binding constraint. A third
cycle would worsen the ratio of inventory to reviewed material and consume the reserve
that regeneration of the selected slice will need.

**Consequences:** D32's emergency capture exception lapses; the ordinary D31 gates
govern again, and a new provider payload requires an explicit user decision. The
harvested corpus stays as inventory with its provenance and gates intact — freezing
capture neither approves nor retires it. Track B/C/D/E tooling remains committed and
runnable for the reserve work; the closed cycle-2 claim owner
`codex.track-c.d32-cycle2-drain` must not be reused.

## D34 — Generated video is not an Irish-audio path (2026-08-06)

**Decision:** Gemini Omni Flash generated video is an exploration and marketing surface
only. It is not a source of spoken Irish for the app, and no in-app audio, teaching
material, or spoken marketing asset may take its audio track. The locked D31 Irish
Cultural Guide voice/model contract remains the sole Irish speech path.

**Why:** The day-one exploration spent two of its ten free daily clips on exactly this
question (`docs/OMNI-EXPLORATION.md` V1a/V1b). Omni did not produce intelligible Irish.
Auto-ASR — with no Irish model available, so English-biased — heard *tá tú ar ais* as
"Tattoo her eyes," and flattened V1b's séimhiú and fada into English-shaped tokens. The
model's own documentation says English is fully supported and other languages have not
been evaluated. Treat the output as English wearing Irish spelling. This is a mechanical
signal, not a native-speaker verdict; a qualified speaker could revisit it, but nothing
downstream may assume a different answer in the meantime.

**Consequences:** V7 (the grant reel) and V8 (the seanfhocal series) are held for their
spoken production and cannot proceed on generated audio. Silent and ambient uses are
unaffected: V6, V4, V3, V2, and V9 remain live exploration candidates on their visual
merits. Any future video that needs Irish speech must compose the D31 clips over the
footage rather than use the generated track. D34 constrains audio only — it does not
grant release eligibility to any generated visual, which stays `generated_unreviewed`
under `OMNI-EXPLORATION.md` §2.6, and the text-free-asset rule (Design Principle 7) and
interpretation-not-likeness rule (`docs/GRAINNE-ART-DIRECTION.md`) continue to apply.

## D32 — Nine-day Irish audio harvest (2026-08-02)

**Decision:** Use the remaining ElevenLabs subscription window as a one-time production
harvest across all 32 counties. The primary objective is to convert the available
credits into a broad, reusable corpus of written Irish phrase-family members and
spoken clips before expiry. Some generated text and audio will be inaccurate,
duplicated, unused, or later discarded; that wastage and rework are accepted.

The appendable v2 phrase-family/member store and strict batch schemas remain mandatory.
They are the harvest ledger, not a reason to wait for learner-release readiness. Draft
families may be captured under an explicit emergency-harvest approval when they carry
stable identity, provenance, invention/risk flags, text hashes, and a plausible
county/story/learning use. Capture, audio QA, pedagogy, and learner release remain
independent states. Unreviewed harvest output cannot support teaching or public-release
claims.

**Operating order:** generate provisional county vocabulary and phrase families first;
deduplicate and batch them by county/story/sense; capture in resumable manifests while
credits remain; then select, correct, review, wire, and promote the strongest material
after expiry. Prioritise broad county coverage, place/story openings and recaps,
dialogue roles, mutations and inflections, and reusable exercise surrounds. Keep the
locked Irish Cultural Guide voice/model unchanged. The normal 3,000–5,000 capture
planning target is superseded for this window by the available credit budget and the
nine-day deadline.

**Consequences:** D31's schemas, checksums, claims, leases, and release gates stay in
force. The emergency exception changes only the capture gate: pedagogy and native QA
block promotion, not provisional generation during the expiry window. `STATUS.md` and
`content/audio/README.md` own the operating checklist and must distinguish harvested,
reviewed, bundled, and learner-release-eligible counts.

## D33 — Keep pure-pedagogy explanations in a reviewable sidecar (2026-08-02)

**Decision:** Add an authoring-only `content/pedagogy/irish-explanations-v1.json`
contract for short English-framed explanations around exact Irish examples. Each line
must carry source references, invented pedagogical provenance, deterministic risk flags,
independent pedagogy/Irish-language/pronunciation review states, and a separate learner
release state. The first corpus remains a draft and every line remains release-blocked.

**Why:** The existing `grammarDiscovery` and `Pattern` runtime shapes can carry worked
cases, withheld production, and a rule, but they do not carry line-level evidence,
authored framing status, deterministic risk prompts, or orthogonal review/release
states. A sidecar is the smallest reversible extension and avoids weakening the
phrase-family, batch, county-pack, or runtime contracts.

**Consequences:** `tools/validate_pedagogy_corpus.py` is the offline mechanical check.
It validates structure, source paths, exact NFC Irish examples, visible risk prompts,
and pending/release separation; it does not decide whether Irish is grammatical,
idiomatic, dialectally appropriate, pedagogically sound, or correctly pronounced. A
future runtime bridge must preserve the sidecar's evidence and gates; corpus presence
does not authorize TTS, teaching claims, bundling, or learner release.

## D31 — Structured Irish authoring and controlled pre-expiry capture (2026-08-01)

**Decision:** Replace the proposed four-slots-per-spelling queue with an appendable v2
authoring store. Canonical family documents are county-, story-, placement-, and
lexeme-sense-specific; each member carries normalized Irish and English intent,
exercise consumers, provenance and durable invention state, risk metadata, and
independent authoring, review, capture-request, audio-QA, and learner-release states.
Generation uses an explicit, resumable batch manifest with a locked voice snapshot,
stable text/hash/slug and line identity, claim ownership, request/attempt/retry state,
provider result, error, file checksum, and QA. Inventory membership never proves a clip
was generated, and unreviewed capture never grants learner release.

**Capacity decision:** The pre-expiry planning target—not a claimed universal standard—
is approximately **3,000–5,000** controlled, metadata-rich An Turas utterances captured,
with roughly **1,200–1,500** of the strongest exercise-integrated lines selected for the
first learner-facing corpus. Within Irish, order work as exercise-bound phrase families,
reusable dialogue roles, place/story openings and recaps, then controlled listening
contrasts required by a named learning action. Exceed 5,000 only when every additional
line has a documented family, lesson pattern, dialogue variation, opening/recap, or
other learning use. Reserve capacity for weak-clip regeneration. A bounded minority of
remaining prepaid credits may support **Speaking Clearly** paired cue demonstrations as
separate-project work with separate contract records.

**Voice/model lock:** All Irish—teaching, story, and dialogue—uses ElevenLabs Irish
Cultural Guide (`NPWroowF4phQhaPWjXPj`) with `eleven_v3`, language `ga`, output
`mp3_44100_192`, and provider-default voice settings. The user has tested alternatives
and found them poor at Irish pronunciation. Do not schedule, suggest, or permit an
alternate Irish voice/model bake-off or V2/V3 migration. A manifest cannot override the
profile; any deviation requires a new explicit user decision and versioned contract
change before it can validate.

**Consequences:** `content/audio/authoring/phrase-family-store-v2.json` indexes canonical
families and batches; schemas and the offline validator live beside it. The unsafe
four-slot queue/seed is retired as migration input only and may never feed generation.
Coverage reports placement, spelling, gloss, sense, county, capture, and release counts
separately. D30's exercise-demand and place/story rules remain in force.

## D30 — Phrase-family fluency model for Irish teaching audio (2026-07-31)

**Decision:** Expand Irish teaching exposure as **phrase families** around soft-frozen
launch-county lexeme banks — not as mass orphan headword generation. A phrase family is
an authored set of full Irish utterances that all realise one taught lexeme (including
mutated/inflected forms) while varying the surrounds; every member is place- or
story-grounded. Family grouping lives with spine/story content; the audio inventory
remains a spoken-text → clip registry under the existing bind rule.

**First proof:** Co-design one Mayo vertical slice — *farraige*, ~4–6 members (≤2
invented pedagogical surrounds), consuming **sentence construction with a surround
change** first; add **delayed reuse** only after that fixture ACCEPT. Host the proof in
a sibling freeze-style fixture, then promote; do not mutate the D29 nine-step Clew Bay
freeze or production Mayo packs for the first pass.

**Gates:** Owner may draft and generate fixture TTS labeled unreviewed. Pedagogue review
and native-speaker audio QA (D17) may run in parallel after generate; both block teaching
claims, production promotion, and scale-out. Soft-freeze Mayo’s storyboard/pack ~20;
treat atlas headwords as provisional. Scale order: prove the two consuming patterns on
*farraige*, then densify Mayo’s taught lexemes; do not inventory-lead atlas coverage or
thin-width four-county families first.

**Why:** Creator-tier TTS is no longer scarce; unused audio, unreviewed longer Irish, and
place-detached inventing are. Exercise demand and QA must gate volume. Representative-slice
discipline (D22) and listening-first pedagogy (D11) require same-lexeme / varied-context
banks that Learning-mode can actually play.

**Consequences:** Record family schema beside county content before bulk generation.
Extend validators so packs reference family members under the bind rule. Keep Trinity/
ABAIR as a post-launch upgrade (D17). Glossary: `CONTEXT.md` (**phrase family**, **lexeme**).
Short ADR: `docs/adr/0001-phrase-family-fluency.md`.

## D29 — Representative Mayo Learning-mode run frozen (2026-07-30)

**Decision:** The learning-mechanics foundation proof is the nine-step Clew Bay
Learning-mode sequence recorded in
`docs/activity-quality/MAYO-REPRESENTATIVE-RUN-FREEZE.md`. D26/D27 architecture
is not reopened. Shell craft ACCEPT at `e4c6a8b` stands for F1/F5/F7 P0s.

The freeze locks: fixture ids and new ids for typing, conversation, speaking,
comprehension, completion, and contextual review; present-day-only conversation;
fixture-vs-production boundary; retained study correction, working-model centre,
scaffold-removal, and quiet motion/haptic rules; Coast Placement deferred to F9;
and cluster order Choice → Construction → Matching → Typing → Speaking →
Conversation → Consolidation (Grammar/Greenfield parked until the run operates).

**Why:** STATUS and D26 required an explicit synthesis before extracting the
shared runtime. Freezing one Clew Bay sequence prevents Rockfleet craft fixtures
from being mistaken for the end-to-end proof, and closes the four open study
questions without another architecture comparison.

**Consequences:** Design/IX implements clusters against the freeze and the
activity-quality spec; Composer scores each cluster; quality owner reviews after
ACCEPT merges. Production Mayo packs are not edited for this proof. The freeze
validates no learning outcome and clears no county gate.

## D28 — Chapter-opening motion density for Flow / Gemini Omni (2026-07-30)

**Decision:** Scale Gemini Omni / Google Flow video as **one muted ambient hero per
chapter opening**, not as page wallpaper. Prefer a still→motion pipeline: author or
select a text-free atmospheric still, then animate it into a 3–6s seamless loop with a
named still keyframe for Reduce Motion and missing playback.

Consequent rules:

- **Density:** Story mode places at most one looping visual hero on the chapter's first
  page (or the equivalent arrival beat). Interior narrative, exercise, evidence-detail,
  and Learning activity pages stay still or text-led unless a separate recorded decision
  opens a second slot (evidence light-sweep or transition bridge).
- **Evidence boundary:** Documentary scans, coins, crosses, charters, and plans are never
  replaced by generated video. Interpretive lighting sweeps may use generated relief only
  when captions and evidence UI keep the object non-documentary. Real archival images stay
  still evidence.
- **No reenactment / no burnt-in copy:** unchanged from the media audit and `DESIGN.md`.
- **Pack contract:** every video resource names an image `fallbackResourceID`; the page's
  `visualResourceID` must appear in `resourceIDs`; captions state generated interpretation.
- **Bundle budget:** target ≤2 MB per muted H.264/H.265 loop at ≤24 fps after encode;
  county offline packs own county video; pause off-screen and when inactive.
- **Generation order:** (1) wire existing loops; (2) fill missing chapter-opening stills;
  (3) animate openings that still lack motion; (4) only then consider transition bridges or
  phoneme articulation micro-videos after their own product contracts.

**Why:** The first nine Flow loops proved place-living atmosphere without invented
history. Generous monthly limits should deepen chapter arrivals across Mayo and the three
review counties, not decorate every page or reopen Learning-shell architecture. Selective
heroes keep language, place, and evidence inspectable while the learning-mechanics
foundation remains the active sprint.

**Consequences:** `docs/MEDIA-AUDIT.md` owns the operational slate and Flow queue. Pack
builders and validators must keep video↔fallback pairing. Missing openings stay queued as
still-then-motion work rather than forcing duplicate bay or castle footage across chapters.
This decision does not clear rights, specialist, or tester gates.

## D27 — Three layers: anatomy, ten response families, five containers (2026-07-30)

**Decision:** D26's flat list of fifteen "response families" becomes three named layers.

The **activity anatomy** is the fixed outer composition, unchanged from D26.

Ten **response families** satisfy the shared response contract — update response, check,
request hint, begin recovery, retry, complete: picture or map selection, sentence
construction, free typed production, fill-in-the-blank, listen and choose, listen and
type, record and compare, matching, read or listen and respond, and grammar discovery.

Five **containers** host or terminate response families rather than being one, and each
carries its own contract: conversation, radio-style listening, contextual mistake review,
**Words you carry** practice, and completion.

Consequent resolutions:

- **Sequencing** and **delayed retrieval** are authored uses, not families. Sequencing is
  sentence construction with an order objective; delayed retrieval is an authored use of
  contextual mistake review and **Words you carry** practice.
- **Grammar discovery** stays a family. Progressive reveal gated on a produce step is a
  response lifecycle no other family has, and it is `DRILL.md`'s `discover` projection.
- **Dialogue and branching roleplay merge** into the single **conversation** container,
  which owns turns, branching, resume, and node-graph validation. **Setting** —
  historical-bounded or present-day — is authored metadata, not a structural difference.
- **Single-choice families grade on selection**; multi-part families keep Check. A wrong
  selection shows its diagnostic immediately but leaves the attempt open; the struggle
  memory event fires only if the learner does not self-correct on the next touch or
  leaves. This supersedes DESIGN.md's universal editable-until-Check rule.
- **One spine, two projections.** Lexemes and patterns are the only corpus. Collection
  holds per-learner encounter metadata; scheduler holds due state. **Words you carry** is
  the surface over collection, scheduled review the surface over scheduler. This satisfies
  both `DRILL.md`'s no-disconnected-corpus guarantee and D26's collection-distinct-from-
  scheduler requirement.
- **Distribution quotas** are computed over all activity pages including containers, so
  conversation and radio count toward production and listening load. The seven-distinct
  rule counts response families only, so diversity cannot be met by stacking containers.
- **A conversation joins the representative Mayo slice**, so the runtime meets multi-turn,
  branching, and resume before the abstraction is extracted.

**Why:** D26's value is one stable anatomy, but five of its fifteen families could not
satisfy the response contract it also mandates — completion has no response, mistake
review and **Words you carry** select other families, radio is a segment timeline, and
roleplay is a multi-screen graph. Flattening three kinds of thing into one list would
have forced per-family exceptions into the shared runtime, which is the exact problem the
foundation sprint exists to remove. Naming the layers keeps D26's familiarity claim and
makes the contract genuinely shared.

The family reconciliation was also forced by evidence: `sequencing`, `delayedRetrieval`,
and `listenBuildSentence` remained live in `CountyExerciseFamily`, in
`ACTIVE_PRODUCTION_FAMILIES`, in the plan's component table, and in thirty-two authored
exercises, while D26's list omitted them. `DRILL.md`'s `discover` projection likewise
survived D26 unmentioned.

**Retained study primitives.** The synthesis step D26 required is recorded here, so the
disposable study code can be removed before the state engine is built. These transfer
into the shared shell:

- the response is the visual centre of the page;
- a simple choice grades on selection, with a repair window before any struggle signal;
- a wrong response stays editable and repair is the next touch;
- the diagnostic attaches to the affected target, not only to a panel;
- correct work survives repair;
- a language object visibly loses its support rather than being replaced;
- substantial response targets with a stable bottom action;
- audio fallback lives inside the task, never on an error page; and
- restart is fast enough to judge repetition honestly.

Three questions from `INTERACTION-STUDIES-REPORT.md` stay open and belong to the shell
build, not to another study: which supports recede within a task versus across later
activities; the quiet An Turas vocabulary for sound and haptics; and where local in-place
repair should override a generic feedback panel. They are answered by building the shell,
and the report preserves the observations needed to answer them.

Not retained: the three study views as a runtime, bespoke maps where a familiar choice
communicates the same thing, study-local visual constants as global tokens, and any
treatment of recognition or tile reconstruction as proof of free recall.

**Consequences:** D26's rationale is restated as a consistency and taste argument rather
than a learning-attention claim. Nothing tests whether familiar mechanics protect
attention for Irish until the four-county tester-readiness gate, which remains the first
contact with a learner other than the owner; the claim should not be asserted as
established before then.

Migration is cheap but real. Twenty-eight of the thirty-two affected exercises regenerate
through `tools/build_phase5_county_drafts.py`; Mayo's four are hand-reviewed revision-6
content needing editorial decisions. Swift and Python validators must move together.

The interaction-study and prototype code — 4,458 lines of views and 801 lines of tests
across seven files, five `AtlasPrototype` entry points, and their project entries — is
deleted once the retained-primitive synthesis is recorded and before the state engine is
built. `INTERACTION-STUDIES-REPORT.md` preserves the findings and git history preserves
the code.

This decision changes the taxonomy, the commit model, and the implementation order. It
does not validate learning outcomes or clear any county's history, pedagogy, language,
audio, rights, or tester gate.

## D26 — Adopt a familiar one-screen learning activity system (2026-07-30)

**Status:** D27 supersedes the flat activity set below with three layers and records the
family reconciliation. The anatomy, the familiarity principle, the reviewed-language
boundary, and the ungraded-speaking rule remain active as written.

**Decision:** Learning mode will use a stable **one screen, one task** activity
architecture rather than treating every exercise as a bespoke editorial composition.
Story pages remain authored, atmospheric, and free to vary with the account.
Activity pages use one familiar hierarchy: quiet progress and exit, optional short
context, one clear prompt, one dominant response area, one primary action,
diagnostic feedback on the same screen, and one continue action.

The core activity set was recorded here as fifteen items drawn from reference
activities 3–12, 14, 16, and 17–19 in `web/learning-activity-reference/index.html`.
D27 replaces that flat list with ten response families and five containers; the titles
and product rules, not the prototype numbering, remain canonical.

The interaction families share one shell, response lifecycle, feedback model,
accessibility behavior, and completion contract. Their working areas differ, but
routine controls do not adopt a new visual grammar on every screen. Recognition and
supported-construction formats remain useful, but do not by themselves claim recall
or production. Speaking remains ungraded. Authored conversation is finite, pre-written,
reviewed, and bounded to plausible present-day or explicitly reconstructed contexts;
it is not real-time generative conversation and never casts the learner into
undocumented history.

**Why:** The 48-activity HTML field guide made the tradeoff operable. Even in
deliberately limited visual form, the selected conventional activities made the task,
response, feedback, and next action substantially clearer than the app's more bespoke
exercise compositions. An Turas earns its distinctiveness through real stories, place,
evidence, reviewed language, audio, feedback, and its visual system—not by making
learners decipher a novel control for each exercise. A familiar activity set also costs
far less to build and maintain: one shell and one lifecycle instead of a bespoke
composition per exercise.

This is an argument from interaction consistency, task clarity, and implementation cost.
It is deliberately **not** a claim that familiar mechanics measurably protect attention
for Irish. That is an empirical question, the review behind this decision was conducted
by the owner rather than with learners, and nothing tests it before the four-county
tester-readiness gate. Do not cite D26 as evidence for a learning outcome.

**Consequences:** This decision closes D25's unresolved direction-selection gate. Do
not build more competing pedagogical or compositional directions before starting the
shared implementation. Existing iOS interaction studies remain disposable research
evidence and may contribute response or recovery details, but they do not constitute
three candidate product architectures awaiting another choice. Their complete
research and implementation record is in `INTERACTION-STUDIES-REPORT.md`.

The next proof is one representative Mayo Learning-mode run through the selected
shell and a representative subset of the activity families. After that slice passes,
extract the shared runtime and migrate the remaining families in bounded groups.
Before extracting that runtime, explicitly decide which local response, correction,
scaffold-removal, motion, and spatial details from the iOS studies improve the
selected shell. This is a synthesis step inside D26, not a reopening of the
architecture selection.
Production county content still cannot spread until the runtime, authored learning
contract, memory signals, gallery, validators, accessibility, simulator, and physical
device gates in `STORY-LEARNING-REBUILD-PLAN.md` pass. D26 changes the interaction
architecture and implementation order; it does not validate learning outcomes or
clear any county's history, pedagogy, language, audio, rights, or tester gate.

## D25 — Harden shared learning mechanics before further content spread (2026-07-30)

**Status:** D26 resolves the direction-selection requirement below. The shared
foundation, state, contract, memory, validation, and verification requirements remain
active; the instruction to compare more candidate architectures before consolidation
is superseded.

**Decision:** The next implementation sprint is the shared learning-mechanics
foundation, not another Mayo chapter revision, additional chapter authoring, county
expansion, or production-pack migration. Existing Mayo material is realistic fixture
content for proving the common runtime, response components, authored learning
contract, learner-memory signals, accessibility, and failure handling. The detailed
scope and gate live in `STORY-LEARNING-REBUILD-PLAN.md`.

Rapid in-app comparison was D25's original critical path. It required one fixed Mayo
fixture slice, two to four materially different interaction directions, and a user
choice before consolidation. The resulting studies and expanded activity reference
made the tradeoff operable; D26 records the choice and replaces that comparison gate
with a representative implementation slice.

Every exercise uses one attempt and support lifecycle: unanswered, attempt,
diagnostic feedback, hint or recovery, retry, and complete. Completion records
success, struggle, hint use, and recovery use against stable language-item ids.
Supported completion allows the learner to continue but does not claim clean recall.
Later review remains deterministic, explainable, optional, bounded, and free of
overdue task debt. Speaking remains ungraded record-and-compare.

**Why:** The Rockfleet proof established mechanic breadth and a working shared shell,
but spreading the current implementation would also spread component-specific state,
feedback, completion, scheduling, accessibility, and failure assumptions. Those
foundations should become correct and testable once before production content is
migrated across present and future counties.

**Consequences:** Do not use chapter count, exercise count, or another authored county
as evidence that this sprint passed. D25 originally prohibited building the complete
state engine, component library, schema migration, or scheduler before the prototype
choice; D26 now satisfies that prerequisite. The selected system may adapt publicly
observable interaction strengths from products such as Duolingo and Brilliant, but
never their identity, content, branded visuals, or reward economy.
The later gate requires the selected direction, a shared state engine, complete
exercise contracts, deterministic memory events, mirrored Swift/Python validation,
an internal mechanics gallery, automated coverage, and direct simulator and
physical-device verification. `DRILL.md` continues to own later scheduled-review
presentation and interval policy. After the gate passes, production packs may migrate
one representative slice at a time; county pedagogy, history, audio, rights, and
external-tester gates remain separate.

## D24 — Allow a new historian to close the expanded Mayo review (2026-07-24)

**Decision:** The historian who approved the six-episode Mayo prototype does not have
exclusive authority over the nine-chapter production review. A newly named historian
may close `history.expanded` by reviewing revision 6 at chapter weight, including
Chapters 2 and 4. The review may be split: an archival specialist may separately
confirm the candidate C04 folio and diplomatic wording.

**Evidence boundary:** A change of reviewer does not inherit or imply approval. The
new reviewer must explicitly record the reviewed revision, scope, date, requested
changes, and final disposition. The historian owns the Chapter 2 and Chapter 4
disposition. When C04 is split out, the archival specialist owns the folio and
diplomatic-wording disposition. General chapter approval is not a substitute for the
archival confirmation.

**Reviewer qualification:** Qualification is evidence-based, not credential-based.
The historian must show relevant work on sixteenth-century Irish history, Tudor
administration, or closely related primary-source research sufficient to judge the
chapter claims. The archival specialist must show experience reading early-modern
manuscripts, State Papers, diplomatic transcriptions, or equivalent records sufficient
to verify C04. A university post, degree, or institutional affiliation is not required.
The review record must state the evidence used to establish the reviewer's fit for
their assigned scope.

**Payment and conflicts:** Paid review is permitted and must be disclosed in the
internal review record. Prior contribution to the project does not disqualify a
reviewer from unrelated scope, but no person may be the sole approver of claims, copy,
interpretations, or transcriptions they authored. Any overlap between contribution and
assigned review scope requires a second qualified reviewer to record an independent
disposition. The record must identify the overlap and the independent reviewer.

**Public provenance:** With the reviewer's explicit consent, the public evidence
record may name the reviewer and show their review scope and completion date. Payment
details, contact information, working notes, qualification evidence, and conflict
documentation remain internal. Public credit must not imply that the reviewer approved
later revisions or scopes outside the recorded disposition.

Declining public naming does not prevent gate closure. The internal review record must
still identify the reviewer and preserve the qualification and conflict evidence. The
public evidence record may instead identify the role—qualified historian or archival
specialist—together with scope and completion date, without naming the person.

**Changes after approval:** A later change to a historical claim, source attribution,
certainty boundary, personal name, quotation, transcription, or evidence explanation
reopens the disposition covering that material. Re-review is scoped to the affected
claim, page, chapter, or archival finding unless the change alters the wider account.
Spelling, punctuation, layout, accessibility labels that preserve meaning, and
unrelated language exercises do not reopen historical review. The internal record
must link the approved content revision and any later re-review.

**Duration:** Historical approval has no automatic calendar expiry. Re-review is
triggered when material new primary evidence, a significant scholarly correction, or
a credible challenge affects an approved claim or evidence boundary. A trigger
reopens only the affected disposition unless its consequences change the wider
account. The trigger and resulting decision must be added to the internal review
record.

**Reviewer disagreement:** When qualified reviewers disagree on a claim, source,
transcription, certainty boundary, or wording, the affected disposition remains open.
The editor may adopt a more conservative formulation that every assigned reviewer
accepts, or obtain a third qualified disposition. The product owner may choose among
supported presentation options, but may not override the disagreement by presenting
the disputed point as settled fact. The review record must preserve the disagreement
and its resolution.

**Consequences:** The source brief and draft status may name a new reviewer when one is
engaged. The gate remains open until the chapter-weight review and C04 archival
confirmation are both recorded and any required changes are approved in the resulting
candidate. The same qualified person may supply both dispositions, but neither scope
may be omitted. Pedagogy, audio, rights, accessibility, device, and promotion gates
remain separate.

## D23 — Approve the nine-chapter Mayo production storyboard (2026-07-24)

**Decision:** Approve `GRAINNE-STORYBOARD-V2.md` as the production storyboard for the
Phase 4 Mayo rebuild. The county uses nine chapters. Chapter 2 introduces
*teaghlach, mac, deartháir,* and *bean*; Rockfleet becomes their reuse site and
introduces only *caisleán*. Rockfleet is reduced from twelve exercises to eight.
Chapter 4 keeps *long* as its only new word and relies on earlier place language.
For words introduced in Chapters 7–9, delayed retrieval plus the voyage-chart and
review handoff satisfy the final reuse stage.

**Evidence boundary:** Approval authorises production drafting from the existing claim
ledger; it does not clear new history. Chapter 2 and Chapter 4 need targeted historian
review at chapter weight, and the exact citation and wording behind C04 must be pinned
before release copy is approved. Expanded exercises, teaching audio, and Rockfleet
imagery remain behind their named external gates.

**Consequences:** The six-episode storyboard remains a prototype record rather than an
active production plan. Authoring proceeds in `content/mayo/grainne-1593.pack.draft.json`
while the proven Rockfleet pack remains bundled. The draft may become a structurally
complete county pack with open review gates, but it must not replace the bundled pack
or enter an external tester build until the Phase 4 specialist, audio, rights,
accessibility, and device gates pass.

## D22 — Rebuild story depth and learning quality before further testing (2026-07-15)

**Decision:** Enter a bounded Story and Learning rebuild before inviting another
external tester round. Mayo becomes the representative implementation: expand
Gráinne's account to eight to ten chapters and 60–90 minutes in Story mode, prove the
new page and exercise system on one complete Rockfleet chapter, then complete Mayo
before applying the pattern to Offaly, Dublin, and Meath. The other launch counties
normally require at least six chapters and 45 minutes of Story-mode content.

The learning path uses varied full-screen exercises interspersed between story pages.
Every county must prove the complete lifecycle of its 20 words, meaningful phrase and
sentence work, exercise variety, diagnostic recovery, reviewed audio, accessibility,
and source quality. The detailed gates live in `STORY-LEARNING-REBUILD-PLAN.md` and
`CONTENT-PIPELINE.md`.

**Why:** Feedback on the four-county road found Mayo worthwhile but too short, while
the three new counties barely counted as stories and repeated listen-and-pick
exercises. Repository inspection supports that judgment: each new county is a
twelve-beat editorial preview with four required interactions for 20 provisional
words, and completion schedules all 20 without proving that they were taught or
retrieved. The pack validator enforces a shape rather than a learning or narrative
outcome.

**Consequences:** D20 remains the historical record of an owner-reported Mayo pass and
an implemented four-county engineering proof. Its instruction to use that Mayo build
as the Phase 3 product pattern is superseded. D14–D15's four-to-six episode planning
range and the schema's three-beat episode rule are not production requirements. Do not
schedule the next external learner round until all four counties pass the internal
tester-readiness gate.

## D21 — One county sequence, with Story and Learning modes (2026-07-15)

**Decision:** Author each county once as an ordered sequence of stable pages and
filter it into two experiences.

- **Story mode** includes the complete narrative, evidence, and story-essential
  interaction, with no language-assessment gate.
- **Learning mode** keeps the causal story needed for meaning, omits optional
  narrative depth, and includes every required language exercise in its authored
  position.

The learner may switch mode without restarting. Finishing Story mode records that the
account was read and opens the next county. Only finishing Learning mode turns the
county gold, moves its 20 words into **Words you carry**, and makes them eligible for
later review. Speaking exercises remain ungraded record-and-compare experiences under
D11; microphone denial never traps progress.

**Why:** Two separate content sets would drift and double editorial cost. A single
sequence keeps story, evidence, and language context aligned while serving people who
want the full account and people who want a shorter learning path. Separate completion
states prevent Story mode from making a false 20-word claim.

**Consequences:** County packs need page-level mode visibility and separate Story- and
Learning-mode completion requirements. Progress migrates from beat indices to stable
page ids. The atlas gains a quiet read state distinct from gold. Story mode can advance
the route; scheduled language review remains downstream of Learning-mode completion.
`DRILL.md` continues to own scheduled return practice, not inline Learning mode.

## D20 — Phase 2 passes; enter the four-county product build (2026-07-14)

**Decision:** Accept the owner's report that the moderated complete-arc Mayo round
passes and leave Phase 2. Build the Phase 3 opening road as Mayo → Offaly → Dublin →
Meath, using Mayo as the proven pattern and preserving the county, evidence, language,
collection and return requirements already fixed in D12–D15.

**Evidence boundary:** The pass was reported directly on 14 July. The repository does
not yet contain a session record with participant count, observations or measured
recall, so documents must describe the transition as **owner-reported validation**
rather than reconstructing details that were not supplied.

**Consequences:** Phase 3 engineering may proceed. Offaly, Dublin and Meath can be
implemented as complete editorial-preview loops so their shared product behavior can
be tested, but they do not become production-cleared history or Irish. Each remains
behind the named historian/specialist, pedagogue, rights, native-speaker audio and
accessibility/device gates in its source brief. Public launch remains Phase 4 and is
not implied by completing the product build.

## D19 — TNA imagery is bundled only under the free educational model (2026-07-13)

**Decision:** Bundle the web-resolution image of The National Archives `SP 63/170
f. 201` while An Turas is entirely free, exclusively educational and has no commercial
involvement. Anticipated Irish-government funding does not change that educational,
non-commercial product posture.

**Why:** TNA permits copies of Crown copyright records to be used for education. The
real folio materially improves the central source encounter and is more honest than a
synthetic facsimile. The source remains credited beside every presentation.

**Consequences:** Commercialisation is a rights gate, not an automatic extension of
this decision. Before any paid access, advertising, commercial sponsorship, private
commercial distribution or other commercial involvement, release owners must either
obtain an appropriate TNA Image Library licence or remove all TNA document imagery from
the product. Transcriptions may remain subject to the applicable Open Government
Licence terms. Keep the unaltered source image and its provenance record; learner
highlights are interface overlays rather than edits to the archival file.

## D18 — SP 63/170 is Gráinne’s handled manuscript (2026-07-13)

**Decision:** Bind Episode 4’s name-find and source inspection to the July 1593
interrogatory and answers in The National Archives series `SP 63/170`: `f. 201` for
the questions and name-find, and `f. 202` for the answers and Burghley's notes. The September
draft in the Salisbury/Cecil Papers remains evidence for the royal response, but it is
not the manuscript image the learner handles.

**Why:** The interrogatory places Gráinne’s name at the head of eighteen questions and
preserves answers about her family, marriages, lands, maintenance and conflict. It is
closer to her presented case, aligns the interaction with the episode’s human stakes,
and has a clearer institutional route for obtaining and licensing a real reproduction.

**Consequences:** Story and source-guide copy must identify `SP 63/170`, July 1593,
and the calendar rendering “Grany Ne Malley”; it must not describe the inspected
object as the 6 September draft. Image handling follows the product-model gate recorded
in D19. The
September draft continues to support Episode 5’s order and incomplete relief.

## D17 — Irish Cultural Guide for the initial launch (2026-07-13)

**Decision:** Use ElevenLabs **Irish Cultural Guide** (`NPWroowF4phQhaPWjXPj`) as the
default voice for all initial-launch narrative and Irish teaching audio. The voice is
not perfect, but it is mostly accurate and materially better than the Gaeilge-first
alternatives tested in the current bake-off.

**Why:** The selected voice is good enough to carry a coherent first launch now. The
new Irish-language Voice Design alternatives were unexpectedly worse at Irish
pronunciation, so replacing the selected voice would reduce quality rather than
improve it.

**Consequences:** Generate all launch clips with Irish Cultural Guide and keep focused
audio QA for headwords, fadas, mutations, names, and phrases. Treat partnerships with
Trinity College Dublin, ABAIR, and other established Irish-language speech/data
organisations as a post-launch improvement path, not a launch blocker. Revisit the
voice after a partnership or stronger native Gaeilge resource is secured.

## D16 — Irish Cultural Guide as house voice for story audio (2026-07-13)

**Decision:** Use the ElevenLabs generated voice **Irish Cultural Guide**
(`NPWroowF4phQhaPWjXPj`) for Gráinne / Mayo narrative audio and as the default voice
for the next story-audio tests. Do not runtime-switch voices within a story.

**Why:** Browser review found the voice's Irish-English documentary character good
enough to move forward, despite some generation-to-generation variability. The decision
unblocks story prototyping while preserving a QA gate for Irish-language teaching audio.

**Consequences:** Generate → listen/review → approve → bundle remains the audio path.
No clip is considered release-ready solely because it came from the selected voice;
headwords, fadas, mutations, names, and short Irish phrases require focused QA. Gemini
3.1 remains a fallback for comparison, and ABAIR/Azure remain pronunciation benchmarks
or upgrade paths where the selected voice is not accurate enough.

## D15 — Gráinne's broader life, organised around the 1593 crisis (2026-07-11)

**Decision:** Stress-test Gráinne's broader life as the candidate flagship for Mayo's
entire county arc. The 1593 crisis, journey to London, documentary exchange, and
negotiation are its organising centre, not its complete chronological boundary.
Selected earlier and later episodes may establish the world that made her power
possible, what she built, what she stood to lose, what changed, and how she was
remembered.

**Why:** The 1593 material offers unusually strong surviving evidence and a dramatic
decision, but the crisis alone may not sustain Mayo's full narrative and language
journey without padding. Her wider life can supply human stakes, change over time,
places, relationships, and meaningful language contexts.

**Consequences:**

- The storyboard may range beyond 1593 but every selected episode must serve the
  central dramatic movement rather than completeness for its own sake.
- A cradle-to-grave chronology and catalogue of famous incidents are explicit
  non-goals.
- The source brief must test which earlier and later claims are strong enough to carry
  learner-facing narrative, not assume that a familiar biography is well evidenced.
- Gráinne still must pass D14's narrative-depth and 20-word language-platform tests;
  this scope decision does not predetermine that she can carry Mayo alone.

**Dramatic spine:**

> Can Gráinne preserve her family, authority, and way of life as Tudor power closes
> around Clew Bay?

An episode belongs only if it materially changes the learner's answer to that
question. “Way of life” means the specific Gaelic maritime, kinship, economic, and
political order in which Gráinne acted; it must not be shorthand for an innocent or
romanticised past. The arc must leave room for her raiding, coercion, wealth, and
pragmatic alliances as well as the pressure exerted by Tudor expansion.

**Episode model:** Mayo's core arc should comprise four to six short episodes, each
targeting roughly 8–12 minutes. Every episode needs a satisfying local movement, a
deliberate exit, and a narrative hook into what changes next. This is not one long
30–45 minute experience with incidental save points. The next episode is available
immediately: the arc is bingeable, with strong authored return points. The product
must not impose a timer or artificial wait to manufacture retention.

If the learner stops, return recognition and light contextual recall should restore
their place in the dramatic question. If they continue, the hook should flow directly
into the next episode without forcing a return ritual between episodes.

**Learner-action floor:** Every core episode must contain at least:

1. one meaningful act of historical discovery, such as finding, tracing, comparing,
   listening to, or closely inspecting something that changes understanding; and
2. one meaningful use of Irish connected to that episode's dramatic stakes.

The rest of an episode may ask only for attention. Decorative tapping and questions
that merely confirm the learner read the preceding sentence do not satisfy this floor.
An entirely observational core episode is not permitted.

**Twenty-word accounting:** The public promise means exactly 20 distinct lexical
headwords per county. Raw tokens, multiword expressions, grammatical constructions,
and inflected or emphatic variants cannot inflate the count. For example, *Is mise…*
is taught as a useful construction, but it is not itself counted as one “word,” and
related forms cannot be split into extra items merely to reach 20. The headwords must
be taught through reusable phrases and constructions rather than as an isolated list.

**Earned-word lifecycle:** Every countable word must pass three authored stages within
the county arc:

1. it first appears at a dramatic or practical need;
2. the learner uses it meaningfully, not merely by revealing or immediately parroting
   a translation; and
3. it returns in a later encounter or episode, preferably in a changed context.

All three stages are required in the content plan. They create a real opportunity to
learn without making demonstrated mastery a prerequisite for turning the county gold.

**Evidence ladder:** Every source carrying a material historical claim must support
three depths:

1. **Story view** — the source appears when it changes the narrative, and the learner
   finds, hears, or compares only what matters to that movement.
2. **Closer look** — optional transcription, translation, document or object context,
   and a concise account of what the source supports and leaves uncertain.
3. **Editorial record** — full citations, rights state, claim ledger, scholarly notes,
   and review history outside the story flow.

The story must remain coherent using only the first level. Progressive disclosure is
not permission for weak or inaccessible sourcing: the third level is mandatory even
when most learners never open it.

**Collection hierarchy:** Do not present evidence, language, and learner-made objects
as three equal collectible currencies. Evidence meaningfully handled in an episode
quietly accumulates in the county record. Earned Irish accumulates in the learner's
usable language. One personal artifact is awarded or completed only when the whole
county arc is complete. This hierarchy must remain progressively disclosed and must
not recreate the rejected dossier-first interface.

Mayo's personal artifact is a **learner-authored voyage chart** assembled across the
arc and completed when Mayo turns gold. It traces the story's Clew Bay–London–Mayo
movement, carries Gráinne's name and the learner's name, includes a short Irish
self-identification made from earned language, and bears restrained visual marks tied
to evidence the learner actually handled. It is explicitly a record of the learner's
journey through the story, not a replica or fabricated historical document.

**Post-county transition:** When the core arc is complete, reveal the personal
artifact, return to the island, turn the county gold, and make one designated next
county green with a clear narrative invitation. The historical and language spine
selects that next county. The learner does not encounter a county picker, tab
dashboard, or open-ended “what next?” menu. Completed counties remain revisitable;
collection browsing and review remain secondary actions.

**Grammar contract:** Irish is first encountered through sound, meaning, and dramatic
use. Give a short explicit explanation only when it helps the learner perform the
next meaningful action or understand a contrast they have already noticed; offer
deeper explanation optionally. No core episode may require opening a grammar note to
continue. The TEG-aligned grammar spine still governs sequencing behind the story.

## D14 — Complete one county arc at a time (2026-07-11)

**Decision:** The learner completes one county at a time. Each county has a designated
core story arc made of several encounters. That overall arc introduces and uses all
20 promised words; no single constituent story or encounter must contain all 20.
Mayo turns gold when the learner finishes its designated core encounters, then the
journey advances to the next county.

The preferred shape is for one flagship story, divided into several episodes, to
carry the entire county arc. This is a hypothesis that must be stress-tested for
narrative depth and its ability to provide meaningful dramatic uses for all 20 words.
If it fails either test, one or more side stories may complete the arc. This rule
applies to Gráinne and Mayo and to every later county; Gráinne has not yet passed the
test merely by being selected as the flagship.

**Why:** Requiring Gráinne's story to carry an arbitrary vocabulary quota would make
history serve a lesson container and would undermine the approved story-first
foundation. A coherent county arc preserves the simple one-county-at-a-time journey
and the concrete 20-word promise without forcing every word into Gráinne's material.

**Consequences:**

- The content model must distinguish a county arc, its constituent stories, and its
  core encounters.
- County briefs begin with a single-flagship hypothesis and record whether it passes
  the narrative-depth and language-platform tests before side stories are added.
- Side stories are an allowed editorial response to a demonstrated gap, not a quota
  or a default requirement for variety.
- A constituent story records only language that arises from its dramatic and
  evidentiary needs; the county arc accounts for coverage of the full 20-word promise.
- County completion is deterministic: every designated core encounter is complete.
- Green means the county currently in progress; gold means its core arc is complete;
  the learner then proceeds to the next county.
- D12's phrase “20 useful words per county” stands, but any wording that assigns all
  20 words to every playable story is superseded.

## D13 — Reset the first three stories around people and evidence (2026-07-11)

**Decision:** The existing first three content packs are prototypes and migration
inputs, not protected editorial choices. Mayo's flagship becomes **Gráinne Ní Mháille
and the 1593 petition**; Breastagh becomes a shorter, clearly labelled field note.
Offaly remains at Clonmacnoise but moves from an imagined late-eighth-century
scriptorium to the **Cross of the Scriptures, Flann Sinna, and the settlement c. 900**.
Dublin retains Sihtric but centres on the **first Irish silver penny c. 997**, rather
than a composite 795–900 raid-to-market story.

The opening story is allowed to break chronology to provide the strongest possible
hook. Mayo 1593 acts as a cold open; Offaly c. 900 visibly rewinds before the route
moves mostly forward. Main stories establish the secure account and surviving
evidence before any reconstruction. Reconstructed experiences are infrequent,
explicitly labelled, and do not carry county completion.

**Why:** The county reframing exposed continued anchoring to work created for the old
chapter spine. Breastagh has a beautiful interaction but too little recoverable human
story to represent Mayo or open the product. Clonmacnoise and Sihtric are strong
choices whose real objects and dates are richer than the fictional composites built
around them. The first encounter must prove the product's full emotional and
historical ambition while still earning foundational Irish naturally.

**Consequences:**

- `STORY-RESET.md` is the editorial brief and source starting point.
- Do not commission release audio or final illustration for the inherited Chapter
  1–3 narratives.
- Do not mechanically migrate Offaly and Dublin to story ids before their replacement
  source briefs and content shapes are agreed.
- Preserve story-keyed progress and reusable interactions; plan an explicit legacy
  migration once replacement story ids and completion semantics exist.
- Extend the content model to distinguish main county stories, field notes, evidence
  types, certainty, and reconstruction status.
- Meath must pass the same clean-slate test before the four-story launch sequence is
  treated as fixed.
- `EXPANSIVE-INTERFACE-VISION.md` explores the broader product vessel implied by this
  decision; its detailed interface proposals are not yet locked decisions.

## D12 — County-led stories, real anchors, and a concrete learning promise (2026-07-10)

**Decision:** The 32 counties are the product's primary visible journey and unit of
progress. Every playable county story is headed by a real, named anchor — a person,
myth, monument, community, or primary record — and gives the learner a substantial
reading or encounter of significance. It teaches **20 useful words per county**.
The historical spine remains the language-sequencing rail; it is no longer the sole
information architecture presented to a learner.

**Why:** Feedback was enthusiastic about learning Irish through history and culture,
but asked for the journey to feel like a trip around real Ireland, not a sequence of
generic scenes or eras. A county gives every story a place on the map, a clear unit of
completion, and a promise a learner can repeat. Named anchors and source-led readings
make the cultural claim earned rather than decorative.

**Consequences:**

- `COUNTY-ATLAS.md` is the product contract; `COUNTY-STORY-SLATE.md` is the researched
  development slate for all 32 first stories.
- Map semantics are fixed: **green** is the current county arc, **gold** means its
  designated core encounters are complete, and **white** means still ahead. A
  white county is an honest promise, not a disguised lock.
- A chapter becomes a pedagogical/production grouping. Existing Chapters 1–4 remain
  the launch-quality scope, but their shipped stories are explicitly Mayo, Offaly,
  Dublin, and Meath stops in the county journey.
- New content cannot be drafted from a generic role. It needs a county brief, named
  anchor, reading plan, 20-word plan, source register, rights check, and historian +
  Irish-language-pedagogue review.
- The app schema, map cards, CMS, and content pipeline must migrate toward a
  story-first/county-first model without breaking existing chapter progress. This is
  Phase 2 product work, not a claim that all 32 stories are ready now.

## D11 — Pronunciation: listening-first, permanently (2026-07-05)

**Decision:** No pronunciation scoring in the product roadmap. Listening-first
pedagogy is permanent: model audio, minimal-pair listening exercises, and ungraded
echo pages (record yourself beside the model, no pass/fail).

**Why:** Irish speech recognition is immature; bad scoring would erode trust faster
than no scoring. Playtesters did not ask for grades — they asked to hear Irish done
right. Echo remains a mirror, not a judge.

**Consequences:** U8 closed. ÉIST/ABAIR ASR stays a research watch, not a v1 feature.
Product copy and onboarding should set the expectation: ears first, mouth second, no
red X on your accent.

## D10 — Business model and launch scope (2026-07-05)

**Decision:** Premium subscription (paid product, not freemium-by-default). Pursue
public grant funding (Foras na Gaeilge, Údarás na Gaeltachta, NI streams) *on top
of* subscription revenue — grants accelerate content, they don't replace the business.
Launch at **Chapters 1–4** at production quality. Content stays bespoke: narrative +
illustration + expert-reviewed pedagogy per chapter, not templated exercises.

**Why:** Playtest validated that re-learners and diaspora respond to depth and care;
the moat is quality, not volume. Premium aligns price with bespoke production cost.
Grants are mission-aligned and available, but strings (openness, pricing) must be
understood before accepting — funding supplements, it doesn't dictate freemium.

**Consequences:** U6 substantially closed. Phase 3 launch target is four chapters
(Ogham → Normans, A1→A1/A2). Revenue model, grant applications, and content budget
are planned together. No race to chapter count at the expense of editorial standards.

## D9 — Content review CMS (2026-07-05)

**Decision:** The bundled JSON content-as-data format (D3) is validated for adding
new chapters. Phase 2 adds a **purpose-built content review layer** — low-key, not
enterprise CMS — with a beautiful UI so writers, linguists, historians, and engineers
can review and sign off on content cleanly and efficiently.

**Why:** Playtest confirmed the format works for engineering; production at Chapter 2+
scale needs a shared review surface. Stakeholders should comment, diff, and approve
without touching Xcode or raw JSON in an editor.

**Consequences:** Phase 2 engineering includes a review app (web or native-adjacent)
that reads the same chapter schema the iOS app ships. Editorial workflow (draft →
linguist review → historian review → audio QA → sign-off) is defined around this tool.
Exact stack TBD; the requirement is stakeholder-first, not feature-rich.

## D8 — Illustration scope: scene pages only (2026-07-05)

**Decision:** Illustration applies to **scene pages only**. Notes, exercises, beats,
and all other registers stay clean and typographic (per D4 register rules).

**Why:** Playtest and production planning agree: Solas an Atlantaigh carries the
narrative world; drilling registers stay readable. Scene-only scope keeps per-chapter
illustration cost predictable at pipeline scale.

**Consequences:** Content schema and art briefs tag `scene` pages as the only
illustrated surface. Chapter 2 pipeline proves cost-per-scene at this scope.

## D7 — Audio production model: all-generated with QA (2026-07-05)

**Decision (historical Chapter 1 baseline):** **Gemini 3.1 Flash TTS** was the production
voice engine for the Chapter 1 playtest. D16 supersedes this choice for Gráinne / Mayo
story audio. Every utterance remains generated, then human-QA'd (native-speaker review
per release). No hybrid human-recorded narrative for v1; no runtime voice switching.

**Why:** Gemini passed native-speaker review on Chapter 1 clips — fada pairs, full
chapter fidelity, Connacht prompt-steering holds. All-generated scales with the content
pipeline; QA catches drift. ABAIR remains the quality ceiling and a future upgrade
if bundling rights are granted; Azure `ga-IE` is deprioritised unless Gemini quality
regresses on later chapters.

**Consequences:** The audio pipeline remains script → generate → native-speaker QA →
bundle in chapter packs. `tools/tts-bakeoff/` is the generation/QA tooling path. For
Gráinne, use D16's selected voice; Gemini remains a fallback. ABAIR enquiry continues
as optional long-term dialect fidelity, not a blocker.

## D6 — Retention rituals: An Féilire (2026-07-05)

**Decision:** The retention stack is **narrative pull + gentle ritual**, not
gamification. Validated pull mechanisms: **tá tú ar ais** return greeting and the
**journey map** (An Turas). Other Phase 1 mechanics — recarve pages, amárach hooks,
Ar Ais visits — drew no negative feedback but went unmentioned; they stay in the
product as authored chapter devices, not as the global retention engine. The missing
flywheel is **An Féilire**: rituals borrowed from the real Irish calendar — daily
seanfhocal, seasonal beats keyed to Lúnasa and Samhain, launch moments aligned with
Seachtain na Gaeilge and the diaspora calendar. Gentle structure without manufactured
guilt.

**Why:** Playtest confirmed connection pulls people back; testers also need *some*
daily reason to open the app that isn't a streak. Ireland already has a calendar;
borrowing it keeps ritual authentic rather than manipulative.

**Consequences:** U3 substantially closed. An Féilire is Phase 3/4 product work but
Phase 2 content should tag calendar-tied material where natural. Recarve/Ar Ais remain
per-chapter authored tools, not deprecated.

## D5 — Phase 1 exit; enter Phase 2 (2026-07-05)

**Decision:** Phase 1 vertical slice criteria are met. Move to **Phase 2 — the content
pipeline**. Chapter 2 (*Oileán na Naomh*) is the pipeline proof.

**Why:** Early playtest feedback is strongly positive on the core thesis:
- Re-learners feel respected (D1 promise holds).
- The grammar ladder feels intentional (SPINE.md payload reads as designed, not accidental).
- The journey map answers "where is this going?"
- Testers return without streaks; **tá tú ar ais** and the journey map are the
  mechanisms they name.

**Consequences:** Phase 2 work begins: editorial board, CMS review layer, Chapter 2
authored through the pipeline, audio and illustration at production recipe. Phase 1
experiments (HTML prototype, bake-offs, illustration funnel) are frozen as reference.

## D4 — Canonical Illustration Style: Solas an Atlantaigh (2026-07-05)

**Decision:** Solas an Atlantaigh (B4 — Atlantic Light, Gouache/Watercolor style) is selected as the winning style direction for Chapter 1 and the baseline for subsequent content production.

**Why:** It scored exceptionally high in emotional and narrative pull. The gouache/watercolor medium captures the moody west-of-Ireland light and windy Atlantic atmosphere perfectly, creating an immersive scene window. The Jack B. Yeats-inspired character focus delivers high warmth without slipping into historical kitsch.

**Consequences:** 
1. The style bible is documented in Section 10 of `docs/ILLUSTRATIONS.md`.
2. Shipped scene stills live in `ios/AnTuras/Assets.xcassets/` (catalog IDs). Working
   exploration, direction refs, and archives live under repo-root `art/` — see
   `art/README.md`. Do not duplicate catalog images as loose `Resources` files.
3. `Models.swift` and `chapter1.json` are modified to support parsing and loading pages with custom image keys directly.
4. Clean register styling is maintained—illustration is kept strictly as a window for
   **scene pages** (D8); note and exercise views remain clean and typographic.

## D3 — Prototype platform: SwiftUI (2026-07-04)

**Decision:** The HTML vertical slice validated the basic mechanics, design taste,
and flow. Further validation requires native feel — the prototype moves to SwiftUI.

**Why:** Retention and "does it feel cared-for" judgments can't be trusted from a
browser page; the product is an iOS app and testers should hold the real thing.

**Consequences:** `ios/` hosts an xcodegen-managed SwiftUI app (An Turas). Chapter
content moves to bundled JSON — the first real artifact of the content-as-data
pipeline (STRATEGY.md Phase 2). The HTML prototype (`prototype/index.html`) is
frozen as the design reference; design changes land in Swift from now on.

## D2 — Dialect policy (2026-07-04)

**Decision:** Connacht Irish first. Expand to all three dialects over time. Ulster
Irish is a hard prerequisite for any major Northern Ireland launch.

**Why:** Connacht is the geographic and phonological "middle" of the three, contains
the largest Gaeltacht (Conamara), and maps closely enough to the written standard
(An Caighdeán) that learners can use mainstream references without whiplash. Ulster
is deferred, not demoted: launching in NI with Connacht-only audio would undercut the
cultural care that is our whole brand.

**Consequences:** All chapter audio, phrase choices, and pronunciation guidance use
Connacht forms where dialects diverge (e.g. *Cén chaoi a bhfuil tú?* not *Conas atá
tú?* / *Cad é mar atá tú?*). Content format must tag dialect-variable items from day
one so Ulster/Munster variants can be slotted in later without rewriting chapters.
ABAIR voice evaluation prioritises their Conamara voices.

## D1 — Primary learner persona (2026-07-04)

**Decision:** Primary = school-Irish re-learners (Ireland) + diaspora learners
(US/UK/AUS), treated as one content track since their needs overlap. Northern
Ireland is the cultural north star: we take special editorial care over NI history,
identity, and the cross-community story, ahead of a dedicated NI push.

**Why:** Re-learners are the largest motivated segment (latent knowledge + emotional
stakes); diaspora is the largest paying segment; both respond to the identity/
heritage engine. NI is the fastest-growing revival but demands Ulster dialect and
extra cultural groundwork first (see D2).

**Consequences:** Content assumes zero retained Irish but moves briskly and explains
*why* (re-learners resent being treated as blank slates); heavy use of identity hooks
(names, surnames, placenames, county affiliation); grammar notes explicitly address
"what school never explained". Marketing tone: reclamation, not gamified novelty.
