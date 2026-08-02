"""Tests for the authoring-only Irish pedagogy explanation corpus."""

from __future__ import annotations

import copy
import json
import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools"))

import validate_pedagogy_corpus as validator  # noqa: E402


class PedagogyCorpusTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.payload = validator.load_payload(REPO_ROOT)
        cls.errors = validator.validate_payload(cls.payload, REPO_ROOT)
        cls.summary = validator.summarize(cls.payload)

    def test_corpus_counts_are_explicit(self) -> None:
        self.assertEqual(self.summary["lessons"], 7)
        self.assertEqual(self.summary["lines"], 26)

    def test_narrative_tranche_reuses_exact_repository_examples(self) -> None:
        lessons = {lesson["id"]: lesson for lesson in self.payload["lessons"]}
        self.assertEqual(
            set(lessons) & {"grammar.identity-origin", "pronunciation.farraige-frames"},
            {"grammar.identity-origin", "pronunciation.farraige-frames"},
        )

        identity_examples = {
            example
            for line in lessons["grammar.identity-origin"]["lines"]
            for example in line["irish_examples"]
        }
        self.assertEqual(
            identity_examples,
            {"Is mise Gráinne.", "Is as Maigh Eo mé."},
        )
        pack = json.loads(
            (REPO_ROOT / "content/mayo/grainne-1593.pack.draft.json").read_text(
                encoding="utf-8"
            )
        )["pack"]
        pages = [page for chapter in pack["chapters"] for page in chapter["pages"]]
        identity_source = {
            page["exercise"]["answer"]
            for page in pages
            if page["id"]
            in {"mayo.in-the-record.build-identity", "mayo.in-the-record.retrieve-origin"}
        }
        self.assertEqual(identity_examples, identity_source)

        sea_examples = {
            example
            for line in lessons["pronunciation.farraige-frames"]["lines"]
            for example in line["irish_examples"]
        }
        self.assertEqual(
            sea_examples,
            {
                "Tá an fharraige anseo.",
                "Tá an long ar an bhfarraige.",
                "Cá bhfuil an fharraige?",
            },
        )
        sea_source = json.loads(
            (
                REPO_ROOT
                / "content/mayo/phrase-families/authoring-v2/farraige.sea-noun.v2.json"
            ).read_text(encoding="utf-8")
        )
        self.assertEqual(
            sea_examples,
            {member["irish"]["text"] for member in sea_source["members"]},
        )

        for lesson_id in ("grammar.identity-origin", "pronunciation.farraige-frames"):
            for line in lessons[lesson_id]["lines"]:
                self.assertTrue(line["source_refs"])
                self.assertTrue(all(ref["path"] for ref in line["source_refs"]))

    def test_current_corpus_is_valid_and_release_blocked(self) -> None:
        self.assertEqual(self.errors, [])
        for lesson in self.payload["lessons"]:
            for line in lesson["lines"]:
                self.assertEqual(line["learner_release"]["status"], "blocked")
                self.assertTrue(
                    all(
                        line["reviews"][gate]["status"] == "pending"
                        for gate in validator.REVIEW_GATES
                    )
                )

    def test_deterministic_flags_are_present_without_linguistic_judgment(self) -> None:
        for lesson in self.payload["lessons"]:
            for line in lesson["lines"]:
                expected = validator.deterministic_risk_flags(lesson, line)
                self.assertTrue(expected.issubset(set(line["risk_flags"])))
                self.assertIn("scope_guard", line["risk_flags"])
                self.assertIn("invented_text", line["risk_flags"])

    def test_missing_scope_guard_is_rejected(self) -> None:
        payload = copy.deepcopy(self.payload)
        payload["lessons"][0]["lines"][0]["risk_flags"].remove("scope_guard")
        errors = validator.validate_payload(payload, REPO_ROOT)
        self.assertTrue(any("missing deterministic flag scope_guard" in error for error in errors))

    def test_report_keeps_review_and_release_counts_visible(self) -> None:
        report = validator.render_report(self.summary, self.errors)
        self.assertIn("Lessons: **7**", report)
        self.assertIn("Explanation lines: **26**", report)
        self.assertIn("pedagogy:pending", report)
        self.assertIn("'blocked': 26", report)
        self.assertIn("does not grant teaching", report)


if __name__ == "__main__":
    unittest.main()
