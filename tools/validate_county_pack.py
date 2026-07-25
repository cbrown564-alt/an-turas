#!/usr/bin/env python3
"""Validate An Turas county story packs and print a readable report.

This mirrors the runtime Swift validator in
``ios/AnTuras/CountyStoryPack.swift`` (``CountyStoryPackValidator``) so a pack can
be checked without a simulator build, and adds the two enforcement rules the
rebuild plan requires but the runtime guard does not yet implement:

* every target word of a ``completeCounty`` pack must carry a full four-stage
  lifecycle (introduced -> heard -> produced -> reused);
* every lexeme id referenced by the pack must belong to the twenty-word
  contract, under the ``lex.<ga with fadas folded>`` convention.

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

# Exercise families whose learner action is active production (mirror of
# CountyExerciseFamily.isActiveProduction in Swift).
ACTIVE_PRODUCTION_FAMILIES = {
    "listenBuildSentence",
    "sentenceConstruction",
    "typing",
    "dialogue",
    "sequencing",
    "speaking",
    "delayedRetrieval",
}

# Families that must carry bundled audio to run.
AUDIO_FAMILIES = {"listenIdentify", "listenBuildSentence", "speaking"}

_FADA = str.maketrans("áéíóúÁÉÍÓÚ", "aeiouaeiou")


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

    # Learning-mode ordering: an exercise may only use lexemes already introduced
    # by an earlier learning-visible page; option and audio integrity per exercise.
    learning_pages = [
        p for p in all_pages if _visibility_includes(p.get("visibility"), "learning")
    ]
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
        introduced.update(page.get("introducedLexemeIDs", []))

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
        if len(by_family) < 7:
            raise PackValidationError(
                "exerciseDistribution", "a learning path needs at least seven mechanic families"
            )
        if max(by_family.values()) / total > 0.25:
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
            if e.get("family") == "listenIdentify" and not e.get("operatesOnSentence")
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
