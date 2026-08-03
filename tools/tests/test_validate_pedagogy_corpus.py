"""Tests for the authoring-only Irish pedagogy explanation corpus."""

from __future__ import annotations

import copy
import json
import sys
import unicodedata
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools"))

import validate_pedagogy_corpus as validator  # noqa: E402


def _nfc(text: str) -> str:
    return " ".join(unicodedata.normalize("NFC", text).strip().split())


class PedagogyCorpusTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.payload = validator.load_payload(REPO_ROOT)
        cls.errors = validator.validate_payload(cls.payload, REPO_ROOT)
        cls.summary = validator.summarize(cls.payload)
        cls.unique_texts = {
            _nfc(example)
            for lesson in cls.payload["lessons"]
            for line in lesson["lines"]
            for example in line["irish_examples"]
        }

    def test_corpus_counts_are_explicit(self) -> None:
        self.assertEqual(self.summary["lessons"], 21)
        self.assertEqual(self.summary["lines"], 203)
        self.assertGreaterEqual(len(self.unique_texts), 50)
        self.assertLessEqual(len(self.unique_texts), 200)
        self.assertEqual(len(self.unique_texts), 148)

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
        # Pedagogy must reuse exact repository Irish; the family may also hold
        # additional story-dialogue members outside this lesson.
        self.assertTrue(
            sea_examples.issubset(
                {member["irish"]["text"] for member in sea_source["members"]}
            )
        )

        for lesson_id in ("grammar.identity-origin", "pronunciation.farraige-frames"):
            for line in lessons[lesson_id]["lines"]:
                self.assertTrue(line["source_refs"])
                self.assertTrue(all(ref["path"] for ref in line["source_refs"]))

    def test_a4_lessons_bind_to_existing_family_members(self) -> None:
        lessons = {lesson["id"]: lesson for lesson in self.payload["lessons"]}
        required = {
            "grammar.historical-name",
            "grammar.place-name",
            "grammar.baile-identity",
            "grammar.cathair-identity",
            "grammar.caislean-identity",
            "grammar.given-name",
            "grammar.surname-name",
            "grammar.presence-question",
            "grammar.place-noun-anseo",
            "pronunciation.feach-frame",
            "grammar.name-relation",
            "grammar.story-place-frames",
            "spelling.fada-place-person",
            "pronunciation.sean-name-shell",
        }
        self.assertTrue(required.issubset(set(lessons)))

        for lesson_id in required:
            for line in lessons[lesson_id]["lines"]:
                self.assertTrue(line["source_refs"])
                for ref in line["source_refs"]:
                    self.assertTrue(
                        ref["path"].endswith(".v2.json"),
                        msg=f"{line['id']} should bind a v2 family path",
                    )
                    self.assertEqual(ref["supports"], "repository_text")
                    self.assertIn("members[id=", ref["field"])
                    self.assertTrue(ref["field"].endswith(".irish.text"))

        historical = {
            example
            for line in lessons["grammar.historical-name"]["lines"]
            for example in line["irish_examples"]
        }
        self.assertIn("Is ainm stairiúil é Gráinne Ní Mháille.", historical)
        self.assertIn("An é Sihtric an t-ainm stairiúil?", historical)

        castle = {
            example
            for line in lessons["grammar.caislean-identity"]["lines"]
            for example in line["irish_examples"]
        }
        self.assertEqual(
            castle,
            {
                "Is caisleán é Caisleán Charraig an Logha.",
                "An caisleán é Caisleán Charraig an Logha?",
            },
        )

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

    def test_source_record_field_and_exact_irish_text_are_bound(self) -> None:
        payload = copy.deepcopy(self.payload)
        line = next(
            line
            for lesson in payload["lessons"]
            for line in lesson["lines"]
            if line["id"] == "grammar.identity-origin.framing"
        )
        source = line["source_refs"][0]

        source["record_id"] = "mayo.in-the-record.retrieve-origin"
        errors = validator.validate_payload(payload, REPO_ROOT)
        self.assertTrue(any("id selector(s)" in error for error in errors))

        payload = copy.deepcopy(self.payload)
        line = next(
            line
            for lesson in payload["lessons"]
            for line in lesson["lines"]
            if line["id"] == "grammar.identity-origin.framing"
        )
        line["irish_examples"] = ["This is not the repository answer."]
        errors = validator.validate_payload(payload, REPO_ROOT)
        self.assertTrue(any("does not match any Irish example" in error for error in errors))

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
        self.assertIn("Lessons: **21**", report)
        self.assertIn("Explanation lines: **203**", report)
        self.assertIn("pedagogy:pending", report)
        self.assertIn("'blocked': 203", report)
        self.assertIn("does not grant teaching", report)


if __name__ == "__main__":
    unittest.main()
