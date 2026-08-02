#!/usr/bin/env python3
"""Validate An Turas county story packs and print a readable report.

This mirrors the runtime Swift validator in
``ios/AnTuras/CountyStoryPack.swift`` (``CountyStoryPackValidator``) so a pack can
be checked without a simulator build — including the authored learning-contract
rules (rebuild plan, "Automated enforcement"), which fire wherever an exercise
carries a ``learningContract`` and keep identical error codes on both sides —
and adds the enforcement rules the rebuild plan requires but the runtime guard
does not implement:

* every target word of a ``completeCounty`` pack must carry a full four-stage
  lifecycle (introduced -> heard -> produced -> reused);
* every lexeme id referenced by the pack must belong to the twenty-word
  contract, under the ``lex.<ga with fadas folded>`` convention;
* every spoken Irish string used for playback must belong to the frozen
  ElevenLabs inventory (``content/audio/irish-inventory-v1.json``).

The runtime Swift validator stays the install-time guard; this is the authoring
and CI gate. Both are tested against the same real packs, so they cannot silently
disagree on the packs that ship.

Usage::

    python3 tools/validate_county_pack.py ios/AnTuras/Resources/CountyStories/*.json

Exits non-zero if any pack fails. See ``docs/STORY-LEARNING-REBUILD-PLAN.md``
("Automated enforcement") for the standards enforced here.
"""
from __future__ import annotations

import json
import sys
from dataclasses import dataclass, field
from pathlib import Path

SCHEMA_VERSION = 2
TARGET_WORD_COUNT = 20
REPO_ROOT = Path(__file__).resolve().parents[1]
IRISH_INVENTORY_PATH = REPO_ROOT / "content/audio/irish-inventory-v1.json"

# D27 containers: these host or end activities rather than being a way to answer, so
# they count toward the percentage quotas but never toward family diversity (mirror of
# CountyExerciseFamily.isContainer in Swift).
CONTAINERS = {"conversation", "completion", "contextualReview"}

# Exercise families and containers whose learner action is active production (mirror of
# CountyExerciseFamily.isActiveProduction in Swift).
ACTIVE_PRODUCTION_FAMILIES = {
    "sentenceConstruction",
    "freeTyping",
    "recordCompare",
    "grammarDiscovery",
    "conversation",
    "contextualReview",
}

# Families that must carry bundled audio to run.
AUDIO_FAMILIES = {"listenChoose", "recordCompare"}

# --- Shared contract vocabulary -------------------------------------------
# Keep these in sync with ios/AnTuras/Resources/Fixtures/contract-enums.json
# (parity-tested) and with the runtime enums in ios/AnTuras/CountyStoryPack.swift
# and ios/AnTuras/CountyActivityStateEngine.swift.

# Families whose learner action answers with target language. Conversation is a
# D27 distribution container, but its learner turns are a response method, so it
# lists here; completion and contextual review host or end activities without
# their own answer method.
RESPONSE_FAMILIES = frozenset(
    {
        "listenChoose",
        "sentenceConstruction",
        "fillGap",
        "matching",
        "freeTyping",
        "readRespond",
        "recordCompare",
        "grammarDiscovery",
        "conversation",
    }
)
PURE_CONTAINERS = frozenset({"completion", "contextualReview"})
AUTHORED_USES = ("ordering", "audioPrompted", "delayedRecall")
TARGET_CAPABILITIES = frozenset(
    {"recognised", "recalled", "produced", "interpreted", "spokenForComparison"}
)
COMPLETION_EVIDENCE_KINDS = frozenset(
    {
        "correctSelection",
        "correctConstruction",
        "correctedConstruction",
        "reconstructedResponse",
        "validDialogueTurn",
        "orderedSequence",
        "completedRecordCompare",
    }
)
MEMORY_EVENT_KINDS = frozenset({"success", "struggle", "hint", "recovery"})

# Families whose contract must name diagnostic cases: sentence construction,
# free typing, and the typed form of fill-in-the-blank (no options).
CONSTRUCTED_RESPONSE_FAMILIES = {"sentenceConstruction", "freeTyping"}

# The completion-evidence kinds an authored contract may declare per family —
# the adapter's mapping widened to the response methods each family offers
# (mirror of CountyExerciseFamily.compatibleCompletionEvidence in Swift). The
# completion container states capabilities, so it supports no target evidence.
FAMILY_COMPLETION_EVIDENCE = {
    "listenChoose": {"correctSelection"},
    "readRespond": {"correctSelection"},
    "grammarDiscovery": {"correctSelection"},
    "fillGap": {"correctSelection", "correctConstruction"},
    "sentenceConstruction": {"correctConstruction", "orderedSequence"},
    "freeTyping": {"correctConstruction"},
    "matching": {"reconstructedResponse"},
    "conversation": {"validDialogueTurn"},
    "recordCompare": {"completedRecordCompare"},
    "contextualReview": {"correctSelection", "correctedConstruction"},
    "completion": set(),
}

_FADA = str.maketrans("áéíóúÁÉÍÓÚ", "aeiouaeiou")
_inventory_texts: set[str] | None = None


def load_irish_inventory_texts() -> set[str] | None:
    """Return frozen inventory strings, or None when the inventory file is absent."""
    global _inventory_texts
    if _inventory_texts is not None:
        return _inventory_texts
    if not IRISH_INVENTORY_PATH.exists():
        return None
    payload = json.loads(IRISH_INVENTORY_PATH.read_text())
    _inventory_texts = {
        entry["text"]
        for entry in payload.get("entries", [])
        if isinstance(entry.get("text"), str) and entry["text"].strip()
    }
    return _inventory_texts


def load_phrase_family_members(county: str) -> dict[str, dict]:
    """Load legacy runtime and canonical v2 authoring members for a county."""
    folder = REPO_ROOT / "content" / county / "phrase-families"
    members: dict[str, dict] = {}
    if not folder.is_dir():
        return members
    paths = sorted(folder.glob("*.v1.json"))
    paths.extend(sorted((folder / "authoring-v2").glob("*.v2.json")))
    for path in paths:
        payload = json.loads(path.read_text())
        lexeme_id_value = payload.get("lexeme_id") or (payload.get("target") or {}).get(
            "lexeme_id"
        )
        for member in payload.get("members", []):
            mid = member.get("id")
            text = member.get("text") or (member.get("irish") or {}).get("normalized_text")
            if isinstance(mid, str) and isinstance(text, str) and mid and text.strip():
                candidate = {
                    "text": text.strip(),
                    "lexeme_id": lexeme_id_value,
                    "family_id": payload.get("id"),
                }
                existing = members.get(mid)
                if existing is not None and existing["text"] != candidate["text"]:
                    raise PackValidationError(
                        "duplicatePhraseFamilyMember",
                        f"{mid!r} has conflicting text in legacy/v2 family documents",
                    )
                members[mid] = candidate
    return members


def _fold_fadas(text: str) -> str:
    return text.translate(_FADA).lower().strip()


def _validate_phrase_family_members(page_id: str, pack_id: str, exercise: dict) -> None:
    """D30: named family members must resolve and match answer/audio/model text."""
    member_ids = exercise.get("phraseFamilyMemberIDs") or []
    if not member_ids:
        return
    audio_text = exercise.get("audioText")
    inventory = load_irish_inventory_texts()
    if (
        isinstance(audio_text, str)
        and audio_text.strip()
        and inventory is not None
        and audio_text.strip() not in inventory
    ):
        # The pack-level bind rule below owns this earlier failure. Avoid masking
        # audioNotInInventory with a derivative member-text mismatch.
        return
    county = pack_id.split(".", 1)[0] if isinstance(pack_id, str) else ""
    catalog = load_phrase_family_members(county)
    bound = {
        _fold_fadas(value)
        for key in ("answer", "audioText", "modelText")
        if isinstance((value := exercise.get(key)), str) and value.strip()
    }
    for member_id in member_ids:
        member = catalog.get(member_id)
        if member is None:
            raise PackValidationError(
                "unknownPhraseFamilyMember",
                f"{page_id} names phrase-family member {member_id!r} missing from {county} catalog",
            )
        if _fold_fadas(member["text"]) not in bound:
            raise PackValidationError(
                "phraseFamilyMemberMismatch",
                f"{page_id} member {member_id!r} text {member['text']!r} does not match "
                "answer/audioText/modelText under the bind rule",
            )


def lexeme_id(ga: str) -> str:
    """The lexeme id convention: ``lex.`` + the headword with fadas folded.

    ``caisleán`` -> ``lex.caislean``. This is the mapping between a pack's
    ``targetWords`` (keyed by ``ga``) and the ``lex.*`` ids used in
    ``introducedLexemeIDs``, exercise ``lexemeIDs`` and the lifecycle table.
    """
    return "lex." + ga.translate(_FADA).lower()


class PackValidationError(Exception):
    """A single validation failure, matching one Swift ``CountyStoryPackError``."""

    def __init__(self, code: str, detail: str):
        super().__init__(f"{code}: {detail}")
        self.code = code
        self.detail = detail


def _visibility_includes(visibility: str, mode: str) -> bool:
    if visibility == "both":
        return True
    if visibility == "storyOnly":
        return mode == "story"
    if visibility == "learningOnly":
        return mode == "learning"
    return False


def _validate_conversation_graph(page_id: str, graph: dict) -> None:
    """C1 contract: an authored conversation is a finite turn graph with a
    declared setting, a resolvable start and next references, at least two
    nodes, one genuine branch (a node with two fitting replies) and at least
    one terminal fitting reply — never a bare multiple-choice list. Mirrors
    ``validateConversationGraph`` in ``CountyStoryPack.swift``."""
    nodes = graph.get("nodes", [])
    node_ids = {node.get("id") for node in nodes}
    replies = [reply for node in nodes for reply in node.get("replies", [])]
    ok = (
        bool(graph.get("setting"))
        and len(nodes) >= 2
        and graph.get("start") in node_ids
        and all(node.get("replies") for node in nodes)
        and all(reply.get("next") is None or reply.get("next") in node_ids for reply in replies)
        and any(reply.get("isFitting") and reply.get("next") is None for reply in replies)
        and any(
            len([r for r in node.get("replies", []) if r.get("isFitting")]) >= 2
            for node in nodes
        )
    )
    if not ok:
        raise PackValidationError(
            "invalidConversationGraph", f"{page_id} fails the C1 turn-graph contract"
        )


def _fold_fada(text: str) -> str:
    """Case-insensitive, fada-folded comparison form (mirror of
    ``CountyStoryPackValidator.foldingFadas`` in Swift)."""
    return text.translate(_FADA).lower()


def _adapted_completion_evidence(exercise: dict) -> str | None:
    """The evidence the deterministic adapter declares from the family and its
    authored use (mirror of ``adaptedCompletionEvidence`` in Swift, with no
    resolved review candidate — the static gate needs only non-nil-ness)."""
    family = exercise.get("family")
    if family in ("listenChoose", "fillGap", "readRespond", "grammarDiscovery"):
        return "correctSelection"
    if family == "sentenceConstruction":
        return (
            "orderedSequence"
            if exercise.get("authoredUse") == "ordering"
            else "correctConstruction"
        )
    if family == "freeTyping":
        return "correctConstruction"
    if family == "matching":
        return "reconstructedResponse"
    if family == "conversation":
        return "validDialogueTurn"
    if family == "recordCompare":
        return "completedRecordCompare"
    if family == "contextualReview":
        return "correctSelection"
    return None  # completion states capabilities


def _resolved_completion_evidence(exercise: dict) -> str | None:
    """The authored evidence when a contract declares one, else the adapted
    family default — one vocabulary either way (mirror of Swift
    ``resolvedContract``)."""
    contract = exercise.get("learningContract")
    if contract is not None:
        return contract.get("completionEvidence")
    return _adapted_completion_evidence(exercise)


def _resolved_target_ids(exercise: dict) -> set[str]:
    contract = exercise.get("learningContract")
    if contract is not None:
        return {target.get("id") for target in contract.get("targets", [])}
    return set(exercise.get("lexemeIDs", []))


def _validate_learning_contract(page_id: str, exercise: dict, contract: dict) -> None:
    """Authored learning-contract rules (rebuild plan, "Automated
    enforcement"), mirrored from ``validateLearningContract`` in
    ``CountyStoryPack.swift``."""
    _validate_resolved_contract_completeness(page_id, exercise, contract)
    misconceptions = contract.get("misconceptions", [])
    declared = {m.get("id") for m in misconceptions}
    for option in exercise.get("options", []):
        if option.get("isCorrect"):
            continue
        if option.get("misconceptionID") not in declared:
            raise PackValidationError(
                "missingMisconceptionMapping",
                f"{page_id} distractor {option.get('id')} has no declared misconception mapping",
            )
    family = exercise.get("family")
    constructed = family in CONSTRUCTED_RESPONSE_FAMILIES or (
        family == "fillGap" and not exercise.get("options")
    )
    if constructed and not misconceptions:
        raise PackValidationError(
            "missingDiagnosticCases",
            f"{page_id} constructs a response but names no diagnostic cases",
        )
    answer = _fold_fada(exercise.get("answer") or "")
    hint = _fold_fada(contract.get("hint") or "")
    if answer and hint and (hint == answer or answer in hint):
        raise PackValidationError(
            "answerRevealingHint",
            f"{page_id} hint reveals the complete accepted answer",
        )
    target_ids = [target.get("id") for target in contract.get("targets", [])]
    recovery_targets = (contract.get("recovery") or {}).get("targetIDs")
    if recovery_targets is not None and set(recovery_targets) != set(target_ids):
        raise PackValidationError(
            "targetChangingRecovery",
            f"{page_id} recovery changes the declared target set",
        )
    evidence = contract.get("completionEvidence")
    if evidence is not None and evidence not in FAMILY_COMPLETION_EVIDENCE.get(family, set()):
        raise PackValidationError(
            "unsupportedCompletionEvidence",
            f"{page_id} declares {evidence}, which {family} cannot produce",
        )
    lexemes = set(exercise.get("lexemeIDs", []))
    off_target = [target for target in target_ids if target not in lexemes]
    if off_target:
        raise PackValidationError(
            "offTargetMemoryCredit",
            f"{page_id} credits memory to target(s) the exercise does not target: "
            f"{', '.join(off_target)}",
        )


def _validate_resolved_contract_completeness(page_id: str, exercise: dict, contract: dict) -> None:
    """Structural completeness for authored and adapted contracts under
    ``enforceLearningQuality`` — mirrors Swift
    ``validateResolvedContractCompleteness``."""
    objective = (contract.get("objective") or "").strip()
    success = (contract.get("successFeedback") or "").strip()
    hint = (contract.get("hint") or "").strip()
    recovery = contract.get("recovery") or {}
    guidance = (recovery.get("guidance") or "").strip()
    required = (recovery.get("requiredResponse") or "").strip()
    if not objective or not success or not hint or not guidance:
        raise PackValidationError(
            "incompleteLearningContract",
            f"{page_id} lacks a complete learning contract (objective, feedback, hint, recovery)",
        )
    if not required:
        raise PackValidationError(
            "recoveryOmitsFreshResponse",
            f"{page_id} recovery completes without requiring a fresh learner response",
        )
    family = exercise.get("family")
    evidence = contract.get("completionEvidence")
    if evidence is not None and evidence not in FAMILY_COMPLETION_EVIDENCE.get(family, set()):
        raise PackValidationError(
            "unsupportedCompletionEvidence",
            f"{page_id} declares {evidence}, which {family} cannot produce",
        )
    target_ids = [target.get("id") for target in contract.get("targets", [])]
    lexemes = set(exercise.get("lexemeIDs", []))
    off_target = [target for target in target_ids if target not in lexemes]
    if off_target:
        raise PackValidationError(
            "offTargetMemoryCredit",
            f"{page_id} credits memory to target(s) the exercise does not target: "
            f"{', '.join(off_target)}",
        )


def _adapted_learning_contract(exercise: dict) -> dict:
    """Mirror of Swift ``CountyLearningContract.adapting`` for offline checks."""
    family = exercise.get("family")
    return {
        "objective": exercise.get("objective") or "",
        "targets": [
            {"id": lexeme, "capability": "recognised"}
            for lexeme in exercise.get("lexemeIDs", [])
        ],
        "misconceptions": [
            {
                "id": "fallback",
                "rationale": "A response the authored diagnostics do not name.",
                "feedback": exercise.get("feedback") or "",
            }
        ],
        "successFeedback": exercise.get("feedback") or "",
        "hint": exercise.get("hint") or "",
        "recovery": {
            "guidance": exercise.get("recovery") or "",
            "requiredResponse": "Make the response again after the support.",
        },
        "completionEvidence": _adapted_completion_evidence(exercise),
    }


@dataclass
class PackReport:
    pack_id: str
    scope: str
    story_minutes: float
    learning_minutes: float
    exercise_distribution: dict[str, int]
    lifecycle_covered: int
    lifecycle_target: int
    required_audio_count: int
    missing_audio_ids: list[str]
    evidence_reference_count: int
    open_review_gates: list[str]
    word_lifecycle: list[tuple[str, bool]] = field(default_factory=list)
    # Exercises carrying an authored learning contract versus contracts the
    # deterministic adapter derives from the flat fields.
    contract_authored: int = 0
    contract_adapted: int = 0
    # Distractors mapped to a named misconception, over all distractors.
    distractors_mapped: int = 0
    distractor_count: int = 0
    # Completion-evidence kinds the pack declares (authored) or derives
    # (adapted), sorted.
    completion_evidence_kinds: list[str] = field(default_factory=list)


def validate(envelope: dict) -> PackReport:
    """Validate a decoded pack envelope. Raises ``PackValidationError`` on the
    first problem, then returns the readable report on success."""
    if envelope.get("schemaVersion") != SCHEMA_VERSION:
        raise PackValidationError("unsupportedSchema", "unsupported schema version")

    pack = envelope.get("pack", {})
    pack_id = pack.get("id", "")
    if not (pack.get("revision", 0) > 0 and "." in pack_id):
        raise PackValidationError(
            "invalidPackID", "needs a stable dotted id and a positive revision"
        )

    target_words = pack.get("targetWords", [])
    gas = [w.get("ga") for w in target_words]
    if len(target_words) != TARGET_WORD_COUNT or len(set(gas)) != TARGET_WORD_COUNT:
        raise PackValidationError(
            "invalidWordContract", "a pack must declare exactly twenty unique headwords"
        )
    contract_lexemes = {lexeme_id(ga) for ga in gas}

    chapters = pack.get("chapters", [])
    all_pages = [page for chapter in chapters for page in chapter.get("pages", [])]

    # No duplicate ids across chapters, pages and resources.
    seen: set[str] = set()
    for item in (
        [c.get("id") for c in chapters]
        + [p.get("id") for p in all_pages]
        + [r.get("id") for r in pack.get("resources", [])]
    ):
        if item in seen:
            raise PackValidationError("duplicateID", f"repeats the id {item}")
        seen.add(item)

    # Each chapter must be non-empty in both modes.
    for chapter in chapters:
        pages = chapter.get("pages", [])
        for mode in ("story", "learning"):
            if not any(_visibility_includes(p.get("visibility"), mode) for p in pages):
                raise PackValidationError(
                    "emptyModeChapter",
                    f"chapter {chapter.get('id')} is empty in {mode} mode",
                )

    page_ids = {p.get("id") for p in all_pages}
    completion = pack.get("completion", {})
    for mode, key in (("story", "storyPageIDs"), ("learning", "learningPageIDs")):
        visible = {
            p.get("id")
            for p in all_pages
            if _visibility_includes(p.get("visibility"), mode)
        }
        for pid in completion.get(key, []):
            if pid not in page_ids or pid not in visible:
                raise PackValidationError(
                    "invalidCompletionPage",
                    f"{mode} completion refers to invisible/missing page {pid}",
                )

    # Story mode must never contain a language exercise.
    for page in all_pages:
        if _visibility_includes(page.get("visibility"), "story") and page.get("kind") == "exercise":
            raise PackValidationError(
                "exerciseOnStoryPath", f"story mode contains exercise {page.get('id')}"
            )

    resources = {r.get("id"): r for r in pack.get("resources", [])}
    for page in all_pages:
        for rid in page.get("resourceIDs", []):
            if rid not in resources:
                raise PackValidationError("missingResource", f"unknown resource {rid}")
        visual = page.get("visualResourceID")
        if visual is not None:
            if visual not in page.get("resourceIDs", []) or resources.get(visual, {}).get("kind") not in ("image", "video"):
                raise PackValidationError(
                    "missingResource", f"visual resource {visual} missing or not an image/video"
                )
            visual_resource = resources[visual]
            if visual_resource.get("kind") == "video":
                fallback = visual_resource.get("fallbackResourceID")
                if resources.get(fallback, {}).get("kind") != "image":
                    raise PackValidationError(
                        "missingResource",
                        f"video visual {visual} has no image fallback",
                    )

    # Learning-mode ordering: an exercise may only use lexemes already introduced
    # by an earlier learning-visible page; option and audio integrity per exercise.
    learning_pages = [
        p for p in all_pages if _visibility_includes(p.get("visibility"), "learning")
    ]
    pages_by_id = {p.get("id"): p for p in all_pages}
    all_exercises = [p["exercise"] for p in all_pages if p.get("exercise")]
    introduced: set[str] = set()
    for page in learning_pages:
        if page.get("kind") == "exercise":
            exercise = page.get("exercise")
            if not exercise:
                raise PackValidationError("missingExercise", f"{page.get('id')} has no exercise")
            if not set(exercise.get("lexemeIDs", [])).issubset(introduced):
                raise PackValidationError(
                    "prematureLexeme",
                    f"{page.get('id')} uses language before it is introduced",
                )
            options = exercise.get("options", [])
            if options:
                correct = [o for o in options if o.get("isCorrect")]
                texts = {o.get("text", "").lower() for o in options}
                if len(correct) != 1 or len(texts) != len(options):
                    raise PackValidationError(
                        "duplicateAnswer",
                        f"{page.get('id')} repeats an answer or lacks a single correct option",
                    )
            if exercise.get("family") in AUDIO_FAMILIES:
                audio_here = [
                    resources[rid]
                    for rid in page.get("resourceIDs", [])
                    if resources.get(rid, {}).get("kind") == "audio"
                ]
                if exercise.get("audioText") is None or not audio_here:
                    raise PackValidationError(
                        "missingRequiredAudio", f"{page.get('id')} has no bundled audio"
                    )
            # F5: matching is a brief distinction task — two to four pairs per board.
            if exercise.get("family") == "matching":
                pair_count = len(exercise.get("pairs", []))
                if not 2 <= pair_count <= 4:
                    raise PackValidationError(
                        "invalidMatchingBoard",
                        f"{page.get('id')} boards {pair_count} pairs; matching takes two to four",
                    )
            # C1: a graph-authored conversation must be a real turn graph.
            if exercise.get("family") == "conversation" and exercise.get("conversation") is not None:
                _validate_conversation_graph(page.get("id"), exercise["conversation"])
            # C5: completion states capabilities, not points.
            if exercise.get("family") == "completion" and not exercise.get("capabilities"):
                raise PackValidationError(
                    "invalidCompletionPayload",
                    f"{page.get('id')} states no capabilities (C5)",
                )
            # C3: contextual review needs authored re-entry candidates.
            if exercise.get("family") == "contextualReview" and not exercise.get("reviewCandidates"):
                raise PackValidationError(
                    "invalidReviewPayload",
                    f"{page.get('id')} has no authored re-entry candidates (C3)",
                )
            # Learning-contract rules (rebuild plan step 12). Authored contracts
            # take the full distractor/diagnostic suite. Under
            # enforceLearningQuality every exercise must still resolve to a
            # complete contract (authored or adapted).
            contract = exercise.get("learningContract")
            if contract is not None:
                _validate_learning_contract(page.get("id"), exercise, contract)
            elif pack.get("enforceLearningQuality"):
                _validate_resolved_contract_completeness(
                    page.get("id"), exercise, _adapted_learning_contract(exercise)
                )
            _validate_phrase_family_members(page.get("id"), pack.get("id"), exercise)
            # C3: a review candidate must trace its target back to the origin
            # page's exercise.
            for candidate in exercise.get("reviewCandidates") or []:
                origin = pages_by_id.get(candidate.get("pageID")) or {}
                origin_exercise = origin.get("exercise")
                embedded = candidate.get("exercise") or {}
                if origin_exercise is None or set(embedded.get("lexemeIDs", [])) != set(
                    origin_exercise.get("lexemeIDs", [])
                ):
                    raise PackValidationError(
                        "untraceableReviewTarget",
                        f"{page.get('id')} candidate {candidate.get('id')} cannot trace "
                        "its target back to the origin exercise (C3)",
                    )
            # C5: a stated capability needs completed-target evidence behind it.
            # Conservative heuristic: a claim passes when any other exercise
            # shares a declared target and declares any completion evidence —
            # capability-to-evidence mapping is fuzzy, so when in doubt the
            # claim stands.
            if exercise.get("family") == "completion" and exercise.get("capabilities"):
                claimed = _resolved_target_ids(exercise)
                if claimed:
                    supported = any(
                        other is not exercise
                        and _resolved_completion_evidence(other) is not None
                        and claimed & _resolved_target_ids(other)
                        for other in all_exercises
                    )
                    if not supported:
                        raise PackValidationError(
                            "unsupportedCapabilityClaim",
                            f"{page.get('id')} claims a capability no completed-target "
                            "evidence supports (C5)",
                        )
        introduced.update(page.get("introducedLexemeIDs", []))

    # Bind rule: every spoken Irish string used for playback must already exist in
    # the frozen ElevenLabs inventory (content/audio/irish-inventory-v1.json).
    inventory = load_irish_inventory_texts()
    if inventory is not None:
        spoken: list[tuple[str, str]] = []
        for resource in pack.get("resources", []):
            if resource.get("kind") != "audio":
                continue
            value = resource.get("value")
            if isinstance(value, str) and value.strip():
                spoken.append((f"resource:{resource.get('id')}", value.strip()))

        def collect_audio_text(obj: object, trail: str) -> None:
            if isinstance(obj, dict):
                value = obj.get("audioText")
                if isinstance(value, str) and value.strip():
                    spoken.append((trail or "audioText", value.strip()))
                for key, child in obj.items():
                    collect_audio_text(child, f"{trail}.{key}" if trail else key)
            elif isinstance(obj, list):
                for index, child in enumerate(obj):
                    collect_audio_text(child, f"{trail}[{index}]")

        collect_audio_text(pack, "")
        for source, text in spoken:
            if text not in inventory:
                raise PackValidationError(
                    "audioNotInInventory",
                    f"{source} uses {text!r}, which is not in the frozen Irish inventory",
                )

    # Lifecycle ordering, on the flat page order across chapters.
    ordered_ids = [p.get("id") for p in all_pages]
    for entry in pack.get("lifecycle", []):
        stages = [
            entry.get("introducedPageID"),
            entry.get("heardPageID"),
            entry.get("producedPageID"),
            entry.get("reusedPageID"),
        ]
        positions = [ordered_ids.index(s) for s in stages if s in ordered_ids]
        if not (
            len(positions) == 4
            and positions[0] <= positions[1] < positions[2] < positions[3]
        ):
            raise PackValidationError(
                "invalidLifecycle", f"lifecycle {entry.get('id')} is missing or out of order"
            )

    # No pack may still lean on the fixed three-page chapter template.
    if (
        pack.get("scope") != "editorialPreview"
        and len(chapters) > 1
        and all(len(c.get("pages", [])) == 3 for c in chapters)
    ):
        raise PackValidationError(
            "legacyBeatStructure", "pack still depends on a fixed three-page chapter structure"
        )

    # --- Added rules beyond the runtime Swift guard -----------------------

    # Every referenced lexeme id must belong to the twenty-word contract.
    referenced_lexemes: set[str] = set()
    for page in all_pages:
        referenced_lexemes.update(page.get("introducedLexemeIDs", []))
        exercise = page.get("exercise")
        if exercise:
            referenced_lexemes.update(exercise.get("lexemeIDs", []))
    for entry in pack.get("lifecycle", []):
        referenced_lexemes.add(entry.get("id"))
    off_contract = sorted(referenced_lexemes - contract_lexemes)
    if off_contract:
        raise PackValidationError(
            "offContractLexeme",
            f"lexeme id(s) not among the twenty headwords: {', '.join(off_contract)}",
        )

    # A complete county must lifecycle all twenty words.
    if pack.get("scope") == "completeCounty":
        lifecycle_ids = {e.get("id") for e in pack.get("lifecycle", [])}
        missing = sorted(contract_lexemes - lifecycle_ids)
        if missing:
            raise PackValidationError(
                "incompleteLifecycle",
                f"complete county missing a lifecycle for: {', '.join(missing)}",
            )

    # Exercise distribution standards (only when quality is enforced).
    exercises = [p.get("exercise") for p in all_pages if p.get("exercise")]
    if pack.get("enforceLearningQuality") and exercises:
        total = len(exercises)
        by_family: dict[str, int] = {}
        for ex in exercises:
            by_family[ex.get("family")] = by_family.get(ex.get("family"), 0) + 1
        # D27: percentages run over every activity page, containers included, because a
        # conversation genuinely carries production load. Diversity counts response
        # families only, so a pack cannot satisfy it by stacking containers.
        family_diversity = len([f for f in by_family if f not in CONTAINERS])
        if family_diversity < 7:
            raise PackValidationError(
                "exerciseDistribution", "a learning path needs at least seven response families"
            )
        # The monotony cap measures what the learner actually does, so it counts a
        # declared authored use separately from its parent family (D27): ordering and
        # audio-prompted construction are not the same experience as plain tile building.
        by_use: dict[str, int] = {}
        for ex in exercises:
            key = ex.get("authoredUse") or ex.get("family")
            by_use[key] = by_use.get(key, 0) + 1
        if max(by_use.values()) / total > 0.25:
            raise PackValidationError(
                "exerciseDistribution", "one exercise family exceeds 25 percent of the path"
            )
        if sum(1 for e in exercises if e.get("operatesOnSentence")) / total < 0.5:
            raise PackValidationError(
                "exerciseDistribution", "at least half of exercises must use phrases or sentences"
            )
        if sum(1 for e in exercises if e.get("family") in ACTIVE_PRODUCTION_FAMILIES) / total < 0.4:
            raise PackValidationError(
                "exerciseDistribution", "at least 40 percent of exercises must require active production"
            )
        if sum(1 for e in exercises if e.get("recognitionMultipleChoice")) / total > 0.25:
            raise PackValidationError(
                "exerciseDistribution", "recognition multiple choice exceeds 25 percent of the path"
            )
        single_word_listen = sum(
            1
            for e in exercises
            if e.get("family") == "listenChoose" and not e.get("operatesOnSentence")
        )
        if single_word_listen / total > 0.1:
            raise PackValidationError(
                "exerciseDistribution", "single-word listen-and-pick exceeds 10 percent of the path"
            )

    return _build_report(pack, resources, all_pages, contract_lexemes)


def _build_report(pack, resources, all_pages, contract_lexemes) -> PackReport:
    def minutes(mode):
        secs = sum(
            p.get("estimatedSeconds", 0)
            for p in all_pages
            if _visibility_includes(p.get("visibility"), mode)
        )
        return round(secs / 60, 1)

    exercises = [p.get("exercise") for p in all_pages if p.get("exercise")]
    distribution: dict[str, int] = {}
    for ex in exercises:
        distribution[ex.get("family")] = distribution.get(ex.get("family"), 0) + 1

    referenced = [
        resources[rid]
        for p in all_pages
        for rid in p.get("resourceIDs", [])
        if rid in resources
    ]
    audio = [r for r in referenced if r.get("kind") == "audio"]

    lifecycle_ids = {e.get("id") for e in pack.get("lifecycle", [])}
    word_lifecycle = []
    for word in pack.get("targetWords", []):
        lid = lexeme_id(word.get("ga"))
        word_lifecycle.append((word.get("ga"), lid in lifecycle_ids))

    distractors = [
        option
        for ex in exercises
        for option in ex.get("options", [])
        if not option.get("isCorrect")
    ]

    return PackReport(
        pack_id=pack.get("id"),
        scope=pack.get("scope"),
        story_minutes=minutes("story"),
        learning_minutes=minutes("learning"),
        exercise_distribution=distribution,
        lifecycle_covered=len(lifecycle_ids),
        lifecycle_target=TARGET_WORD_COUNT,
        required_audio_count=len(audio),
        missing_audio_ids=sorted({r.get("id") for r in audio if r.get("status") != "bundled"}),
        evidence_reference_count=sum(1 for r in referenced if r.get("kind") in ("evidence", "source")),
        open_review_gates=[g.get("title") for g in pack.get("reviewGates", []) if g.get("status") != "complete"],
        word_lifecycle=word_lifecycle,
        contract_authored=sum(1 for ex in exercises if ex.get("learningContract") is not None),
        contract_adapted=sum(1 for ex in exercises if ex.get("learningContract") is None),
        distractors_mapped=sum(1 for o in distractors if o.get("misconceptionID") is not None),
        distractor_count=len(distractors),
        completion_evidence_kinds=sorted(
            {e for e in (_resolved_completion_evidence(ex) for ex in exercises) if e}
        ),
    )


def format_report(report: PackReport) -> str:
    lines = [
        f"{report.pack_id}  [{report.scope}]",
        f"  Story time     {report.story_minutes:>6} min",
        f"  Learning time  {report.learning_minutes:>6} min",
        f"  Exercises      {sum(report.exercise_distribution.values())} across {len(report.exercise_distribution)} families",
    ]
    if report.exercise_distribution:
        total = sum(report.exercise_distribution.values())
        for family, count in sorted(report.exercise_distribution.items(), key=lambda kv: -kv[1]):
            lines.append(f"      {family:<20} {count:>2}  ({count / total:.0%})")
    lines.append(f"  Word lifecycle {report.lifecycle_covered}/{report.lifecycle_target} words fully staged")
    missing = [ga for ga, covered in report.word_lifecycle if not covered]
    if missing and report.scope == "completeCounty":
        lines.append(f"      missing: {', '.join(missing)}")
    total_contracts = report.contract_authored + report.contract_adapted
    if total_contracts:
        lines.append(
            f"  Contract       {report.contract_authored} authored, "
            f"{report.contract_adapted} adapted (of {total_contracts} exercises)"
        )
    if report.distractor_count:
        lines.append(
            f"  Diagnostics    {report.distractors_mapped}/{report.distractor_count} "
            "distractors mapped to misconceptions"
        )
    if report.completion_evidence_kinds:
        lines.append(f"  Evidence kinds {', '.join(report.completion_evidence_kinds)}")
    lines.append(f"  Audio          {report.required_audio_count} references"
                 + (f", {len(report.missing_audio_ids)} not yet bundled" if report.missing_audio_ids else ""))
    if report.missing_audio_ids:
        lines.append(f"      unbundled: {', '.join(report.missing_audio_ids)}")
    lines.append(f"  Evidence       {report.evidence_reference_count} source/evidence references")
    if report.open_review_gates:
        lines.append(f"  Open gates     {', '.join(report.open_review_gates)}")
    else:
        lines.append("  Open gates     none")
    return "\n".join(lines)


def main(argv: list[str]) -> int:
    paths = argv[1:]
    if not paths:
        print(__doc__)
        return 2
    failures = 0
    for path in paths:
        envelope = json.loads(Path(path).read_text())
        try:
            report = validate(envelope)
        except PackValidationError as error:
            failures += 1
            print(f"FAIL  {path}\n      {error}")
            continue
        print(f"PASS  {format_report(report)}\n")
    if failures:
        print(f"{failures} pack(s) failed validation.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
