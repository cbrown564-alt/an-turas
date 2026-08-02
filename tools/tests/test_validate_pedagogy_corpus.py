"""Tests for the authoring-only Irish pedagogy explanation corpus."""

from __future__ import annotations

import copy
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

    def test_first_corpus_counts_are_explicit(self) -> None:
        self.assertEqual(self.summary["lessons"], 5)
        self.assertEqual(self.summary["lines"], 18)

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
        self.assertIn("Lessons: **5**", report)
        self.assertIn("Explanation lines: **18**", report)
        self.assertIn("pedagogy:pending", report)
        self.assertIn("'blocked': 18", report)
        self.assertIn("does not grant teaching", report)


if __name__ == "__main__":
    unittest.main()
