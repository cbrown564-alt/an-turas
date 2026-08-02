#!/usr/bin/env python3
"""Validate the authoring-only Irish pedagogy explanation corpus.

This validator checks structure, source paths, exact NFC Irish examples, review/release
state separation, and deterministic text-visible risk prompts. It does not judge Irish
grammar, idiom, dialect, pedagogy, or pronunciation.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CORPUS_PATH = Path("content/pedagogy/irish-explanations-v1.json")

ALLOWED_AREAS = {"grammar", "spelling", "pronunciation"}
ALLOWED_KINDS = {"framing", "intuition", "example", "contrast", "boundary"}
ALLOWED_FLAGS = {
    "fada",
    "initial_mutation",
    "pronoun_reference",
    "named_entity",
    "audio_pronunciation",
    "scope_guard",
    "invented_text",
    "explanation_claim",
    "source_ambiguity",
    "dialect_register",
    "long_sentence",
}
REVIEW_GATES = ("pedagogy", "irish_language", "audio_pronunciation")
REVIEW_STATES = {
    "not_requested",
    "pending",
    "approved",
    "changes_requested",
    "rejected",
}
RELEASE_STATES = {"blocked", "eligible", "retired"}
MUTATION_TRIGGER_RE = re.compile(
    r"\b(?:an|ar an|sa|chuig an|go dtí an|don|leis an|ón)\s+",
    re.IGNORECASE,
)
PRONOUN_RE = re.compile(
    r"\b(?:mé|tú|sé|sí|é|í|duit|ort|uait|dom|agam|agat|ann|di|linn)\b",
    re.IGNORECASE,
)
NAMED_ENTITY_PATTERNS = (
    "Gráinne",
    "Dáire",
    "Áine",
    "Rónán",
    "Seán",
)


def load_payload(root: Path = ROOT) -> dict[str, Any]:
    return json.loads((root / CORPUS_PATH).read_text(encoding="utf-8"))


def deterministic_risk_flags(lesson: dict[str, Any], line: dict[str, Any]) -> set[str]:
    """Infer only visible, mechanical prompts; never infer a linguistic verdict."""

    examples = line.get("irish_examples") or []
    joined_examples = " ".join(example for example in examples if isinstance(example, str))
    flags = {"scope_guard", "explanation_claim"}
    provenance = line.get("provenance") or {}
    if provenance.get("invented") is True:
        flags.add("invented_text")
    if any(char in joined_examples for char in "áéíóúÁÉÍÓÚ"):
        flags.add("fada")
    if MUTATION_TRIGGER_RE.search(joined_examples):
        flags.add("initial_mutation")
    if PRONOUN_RE.search(joined_examples):
        flags.add("pronoun_reference")
    if any(pattern in joined_examples for pattern in NAMED_ENTITY_PATTERNS):
        flags.add("named_entity")
    if lesson.get("area") == "pronunciation":
        flags.add("audio_pronunciation")
    if len(line.get("english", "")) > 180 or any(len(example) > 80 for example in examples):
        flags.add("long_sentence")
    return flags


def _required_text(value: Any, label: str, errors: list[str]) -> bool:
    if not isinstance(value, str) or not value.strip():
        errors.append(f"{label}: required non-empty text")
        return False
    return True


def validate_payload(payload: Any, root: Path = ROOT) -> list[str]:
    errors: list[str] = []
    if not isinstance(payload, dict):
        return ["corpus: top level must be an object"]

    required = {
        "schema_version",
        "contract",
        "id",
        "status",
        "language",
        "review_policy",
        "lessons",
    }
    missing = sorted(required - payload.keys())
    errors.extend(f"corpus: missing required field {field}" for field in missing)
    if payload.get("schema_version") != 1:
        errors.append("corpus.schema_version: expected 1")
    if payload.get("contract") != "irish_pedagogy_explanations":
        errors.append("corpus.contract: expected irish_pedagogy_explanations")
    if payload.get("status") not in {"draft", "active", "retired"}:
        errors.append("corpus.status: expected draft, active, or retired")

    language = payload.get("language")
    if not isinstance(language, dict) or language.get("target") != "ga" or language.get("framing") != "en":
        errors.append("corpus.language: expected target ga with English framing")

    policy = payload.get("review_policy")
    if not isinstance(policy, dict):
        errors.append("corpus.review_policy: required object")
    else:
        if policy.get("learner_release") != "blocked":
            errors.append("corpus.review_policy.learner_release: must remain blocked")
        required_reviews = policy.get("required_reviews")
        if not isinstance(required_reviews, list) or set(required_reviews) != set(REVIEW_GATES):
            errors.append("corpus.review_policy.required_reviews: must name all three independent review gates")
        _required_text(policy.get("capture_note"), "corpus.review_policy.capture_note", errors)

    lessons = payload.get("lessons")
    if not isinstance(lessons, list) or not lessons:
        errors.append("corpus.lessons: required non-empty array")
        return errors

    lesson_ids: set[str] = set()
    line_ids: set[str] = set()
    for lesson_index, lesson in enumerate(lessons, start=1):
        lesson_label = f"lessons[{lesson_index}]"
        if not isinstance(lesson, dict):
            errors.append(f"{lesson_label}: must be an object")
            continue
        for field in ("id", "title", "memory_hook", "scope"):
            _required_text(lesson.get(field), f"{lesson_label}.{field}", errors)
        lesson_id = lesson.get("id")
        if lesson_id in lesson_ids:
            errors.append(f"{lesson_label}.id: duplicate {lesson_id}")
        lesson_ids.add(lesson_id)
        if lesson.get("area") not in ALLOWED_AREAS:
            errors.append(f"{lesson_label}.area: unsupported area")
        lines = lesson.get("lines")
        if not isinstance(lines, list) or not lines:
            errors.append(f"{lesson_label}.lines: required non-empty array")
            continue

        for line_index, line in enumerate(lines, start=1):
            line_label = f"{lesson_label}.lines[{line_index}]"
            if not isinstance(line, dict):
                errors.append(f"{line_label}: must be an object")
                continue
            for field in ("id", "english"):
                _required_text(line.get(field), f"{line_label}.{field}", errors)
            line_id = line.get("id")
            if line_id in line_ids:
                errors.append(f"{line_label}.id: duplicate {line_id}")
            line_ids.add(line_id)
            if line.get("kind") not in ALLOWED_KINDS:
                errors.append(f"{line_label}.kind: unsupported kind")

            examples = line.get("irish_examples")
            if not isinstance(examples, list) or not examples:
                errors.append(f"{line_label}.irish_examples: required non-empty array")
                examples = []
            for example_index, example in enumerate(examples, start=1):
                if not _required_text(example, f"{line_label}.irish_examples[{example_index}]", errors):
                    continue
                if unicodedata.normalize("NFC", example) != example:
                    errors.append(f"{line_label}.irish_examples[{example_index}]: must already be NFC")

            source_refs = line.get("source_refs")
            if not isinstance(source_refs, list) or not source_refs:
                errors.append(f"{line_label}.source_refs: required non-empty array")
            else:
                for source_index, source in enumerate(source_refs, start=1):
                    source_label = f"{line_label}.source_refs[{source_index}]"
                    if not isinstance(source, dict):
                        errors.append(f"{source_label}: must be an object")
                        continue
                    for field in ("path", "record_id", "field"):
                        _required_text(source.get(field), f"{source_label}.{field}", errors)
                    if source.get("supports") not in {
                        "repository_text",
                        "external_attestation",
                        "pattern_only",
                        "exercise_context",
                        "migration_only",
                    }:
                        errors.append(f"{source_label}.supports: unsupported provenance type")
                    source_path = source.get("path")
                    if isinstance(source_path, str) and not (root / source_path).is_file():
                        errors.append(f"{source_label}.path: file does not exist: {source_path}")

            provenance = line.get("provenance")
            if not isinstance(provenance, dict):
                errors.append(f"{line_label}.provenance: required object")
            else:
                if provenance.get("origin") != "invented_pedagogical":
                    errors.append(f"{line_label}.provenance.origin: must be invented_pedagogical")
                if provenance.get("invented") is not True:
                    errors.append(f"{line_label}.provenance.invented: must remain true")
                _required_text(provenance.get("composition_note"), f"{line_label}.provenance.composition_note", errors)

            risk_flags = line.get("risk_flags")
            if not isinstance(risk_flags, list) or len(risk_flags) != len(set(risk_flags)):
                errors.append(f"{line_label}.risk_flags: required unique array")
                risk_flags = []
            unknown_flags = sorted(set(risk_flags) - ALLOWED_FLAGS)
            errors.extend(f"{line_label}.risk_flags: unknown flag {flag}" for flag in unknown_flags)
            inferred = deterministic_risk_flags(lesson, line)
            missing_flags = sorted(inferred - set(risk_flags))
            errors.extend(
                f"{line_label}.risk_flags: missing deterministic flag {flag}"
                for flag in missing_flags
            )

            reviews = line.get("reviews")
            if not isinstance(reviews, dict):
                errors.append(f"{line_label}.reviews: required object")
            else:
                for gate in REVIEW_GATES:
                    review = reviews.get(gate)
                    if not isinstance(review, dict):
                        errors.append(f"{line_label}.reviews.{gate}: required object")
                        continue
                    if review.get("status") not in REVIEW_STATES:
                        errors.append(f"{line_label}.reviews.{gate}.status: unsupported state")
                    if review.get("status") == "pending" and review.get("record") is not None:
                        errors.append(f"{line_label}.reviews.{gate}: pending review cannot have a record")

            release = line.get("learner_release")
            if not isinstance(release, dict):
                errors.append(f"{line_label}.learner_release: required object")
            else:
                if release.get("status") not in RELEASE_STATES:
                    errors.append(f"{line_label}.learner_release.status: unsupported state")
                if not isinstance(release.get("reasons"), list) or not release.get("reasons"):
                    errors.append(f"{line_label}.learner_release.reasons: required non-empty array")
                if release.get("status") == "eligible":
                    errors.append(f"{line_label}.learner_release: first corpus cannot be learner-release eligible")

    return errors


def summarize(payload: dict[str, Any]) -> dict[str, Any]:
    lessons = payload.get("lessons", [])
    lines = [line for lesson in lessons for line in lesson.get("lines", [])]
    risk_counts = Counter(flag for line in lines for flag in line.get("risk_flags", []))
    review_counts = Counter(
        f"{gate}:{line.get('reviews', {}).get(gate, {}).get('status')}"
        for line in lines
        for gate in REVIEW_GATES
    )
    release_counts = Counter(line.get("learner_release", {}).get("status") for line in lines)
    return {
        "lessons": len(lessons),
        "lines": len(lines),
        "risk_flags": dict(sorted(risk_counts.items())),
        "review_states": dict(sorted(review_counts.items())),
        "learner_release_states": dict(sorted(release_counts.items())),
    }


def render_report(summary: dict[str, Any], errors: list[str], *, path: Path = CORPUS_PATH) -> str:
    lines = [
        "# Irish pedagogy explanation corpus",
        "",
        "Authoring-only report. It does not judge Irish grammar, idiom, dialect, pedagogy,",
        "or pronunciation, and it does not grant teaching, TTS, bundling, or learner release.",
        "",
        f"Corpus: `{path}`",
        f"Validation: **{'PASS' if not errors else 'FAIL'}**",
        "",
        "## Counts",
        "",
        f"- Lessons: **{summary['lessons']}**",
        f"- Explanation lines: **{summary['lines']}**",
        f"- Learner-release states: `{summary['learner_release_states']}`",
        "",
        "## Review states",
        "",
    ]
    lines.extend(f"- `{key}`: {value}" for key, value in summary["review_states"].items())
    lines.extend(["", "## Deterministic risk flags", ""])
    lines.extend(f"- `{key}`: {value}" for key, value in summary["risk_flags"].items())
    if errors:
        lines.extend(["", "## Errors", ""])
        lines.extend(f"- {error}" for error in errors)
    return "\n".join(lines)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("report", "check"))
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    try:
        payload = load_payload()
    except (OSError, json.JSONDecodeError) as error:
        print(f"invalid {CORPUS_PATH}: {error}")
        return 1
    errors = validate_payload(payload)
    summary = summarize(payload)
    if args.command == "report":
        print(render_report(summary, errors))
    else:
        if errors:
            print(f"invalid {CORPUS_PATH}")
            for error in errors:
                print(f"- {error}")
        else:
            print(f"valid {CORPUS_PATH} lessons={summary['lessons']} lines={summary['lines']}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
