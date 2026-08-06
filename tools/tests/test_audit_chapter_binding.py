from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

import audit_chapter_binding as binding  # noqa: E402


def build_tree(
    root: Path,
    *,
    exercise: dict,
    members: list[dict],
    manifest_texts: list[str],
    bundle: bool = True,
    family_extra: dict | None = None,
) -> Path:
    county = "mayo"
    families = root / "content" / county / "phrase-families"
    families.mkdir(parents=True)
    family = {
        "schema_version": 1,
        "id": "mayo.phrase-family.test",
        "lexeme_id": "lex.test",
        "status": "densify_draft",
        "members": members,
    }
    family.update(family_extra or {})
    (families / "test.v1.json").write_text(json.dumps(family), encoding="utf-8")

    if bundle:
        bundled = root / "ios" / "AnTuras" / "Resources" / "PhraseFamilies" / county
        bundled.mkdir(parents=True)
        (bundled / "test.v1.json").write_text(json.dumps(family), encoding="utf-8")

    audio = root / "ios" / "AnTuras" / "Resources" / "Audio"
    audio.mkdir(parents=True)
    (audio / "manifest.json").write_text(
        json.dumps(
            {
                "lines": [
                    {"slug": f"s{index}", "text": text, "sha256": "abc", "file": "x.mp3"}
                    for index, text in enumerate(manifest_texts)
                ]
            }
        ),
        encoding="utf-8",
    )

    pack_path = root / "pack.json"
    pack_path.write_text(
        json.dumps(
            {
                "pack": {
                    "id": "mayo.test",
                    "chapters": [
                        {
                            "id": "mayo.chapter",
                            "pages": [{"id": "mayo.chapter.page", "exercise": exercise}],
                        }
                    ],
                }
            }
        ),
        encoding="utf-8",
    )
    return pack_path


class BindingAuditTest(unittest.TestCase):
    def audit(self, **kwargs):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        pack_path = build_tree(root, **kwargs)
        return binding.audit(root, county="mayo", pack_path=pack_path)

    def codes(self, report) -> set[str]:
        return {item["code"] for item in report["findings"]}

    def test_clean_binding_has_no_blocking_findings(self):
        report = self.audit(
            exercise={
                "family": "freeTyping",
                "answer": "Tá an fharraige anseo.",
                "lexemeIDs": ["lex.test"],
                "phraseFamilyMemberIDs": ["m1"],
            },
            members=[
                {"id": "m1", "text": "Tá an fharraige anseo.", "qa_state": "qa_passed"}
            ],
            manifest_texts=["Tá an fharraige anseo."],
        )
        self.assertEqual(report["summary"]["blocking"], 0)
        self.assertEqual(self.codes(report), set())
        self.assertTrue(report["chapters"][0]["review_ready"])

    def test_unresolved_member_blocks(self):
        report = self.audit(
            exercise={
                "family": "freeTyping",
                "answer": "Tá an fharraige anseo.",
                "lexemeIDs": ["lex.test"],
                "phraseFamilyMemberIDs": ["missing"],
            },
            members=[
                {"id": "m1", "text": "Tá an fharraige anseo.", "qa_state": "qa_passed"}
            ],
            manifest_texts=["Tá an fharraige anseo."],
        )
        self.assertIn("unresolved_member", self.codes(report))
        self.assertEqual(report["summary"]["blocking"], 1)

    def test_bind_rule_mismatch_blocks(self):
        report = self.audit(
            exercise={
                "family": "freeTyping",
                "answer": "A different sentence.",
                "lexemeIDs": ["lex.test"],
                "phraseFamilyMemberIDs": ["m1"],
            },
            members=[
                {"id": "m1", "text": "Tá an fharraige anseo.", "qa_state": "qa_passed"}
            ],
            manifest_texts=["Tá an fharraige anseo."],
        )
        self.assertIn("bind_rule_mismatch", self.codes(report))
        self.assertEqual(report["summary"]["blocking"], 1)

    def test_bind_rule_folds_fadas_and_case(self):
        report = self.audit(
            exercise={
                "family": "freeTyping",
                "answer": "TA AN FHARRAIGE ANSEO.",
                "lexemeIDs": ["lex.test"],
                "phraseFamilyMemberIDs": ["m1"],
            },
            members=[
                {"id": "m1", "text": "Tá an fharraige anseo.", "qa_state": "qa_passed"}
            ],
            manifest_texts=["Tá an fharraige anseo."],
        )
        self.assertNotIn("bind_rule_mismatch", self.codes(report))

    def test_binds_against_audio_and_model_text(self):
        for field in ("audioText", "modelText"):
            report = self.audit(
                exercise={
                    "family": "listenChoose",
                    "answer": "sea",
                    field: "farraige",
                    "lexemeIDs": ["lex.test"],
                    "phraseFamilyMemberIDs": ["m1"],
                },
                members=[{"id": "m1", "text": "farraige", "qa_state": "qa_passed"}],
                manifest_texts=["farraige"],
            )
            self.assertNotIn("bind_rule_mismatch", self.codes(report), field)

    def test_missing_clip_is_advisory(self):
        report = self.audit(
            exercise={
                "family": "freeTyping",
                "answer": "Tá an fharraige anseo.",
                "lexemeIDs": ["lex.test"],
                "phraseFamilyMemberIDs": ["m1"],
            },
            members=[
                {"id": "m1", "text": "Tá an fharraige anseo.", "qa_state": "qa_passed"}
            ],
            manifest_texts=[],
        )
        self.assertIn("member_without_clip", self.codes(report))
        self.assertEqual(report["summary"]["blocking"], 0)

    def test_unreviewed_member_is_reported(self):
        report = self.audit(
            exercise={
                "family": "freeTyping",
                "answer": "Tá an fharraige anseo.",
                "lexemeIDs": ["lex.test"],
                "phraseFamilyMemberIDs": ["m1"],
            },
            members=[
                {
                    "id": "m1",
                    "text": "Tá an fharraige anseo.",
                    "qa_state": "spot_flagged",
                }
            ],
            manifest_texts=["Tá an fharraige anseo."],
        )
        self.assertIn("member_not_reviewed", self.codes(report))
        self.assertFalse(report["chapters"][0]["review_ready"])

    def test_comprehension_exercise_is_not_an_unbound_gap(self):
        report = self.audit(
            exercise={"family": "readRespond", "lexemeIDs": [], "answer": "x"},
            members=[{"id": "m1", "text": "x", "qa_state": "qa_passed"}],
            manifest_texts=["x"],
        )
        self.assertIn("unbound_comprehension_exercise", self.codes(report))
        self.assertNotIn("unbound_exercise", self.codes(report))

    def test_lexeme_carrying_exercise_without_members_is_a_gap(self):
        report = self.audit(
            exercise={"family": "matching", "lexemeIDs": ["lex.test"], "answer": "x"},
            members=[{"id": "m1", "text": "x", "qa_state": "qa_passed"}],
            manifest_texts=["x"],
        )
        self.assertIn("unbound_exercise", self.codes(report))

    def test_missing_bundle_copy_blocks(self):
        report = self.audit(
            exercise={
                "family": "freeTyping",
                "answer": "Tá an fharraige anseo.",
                "lexemeIDs": ["lex.test"],
                "phraseFamilyMemberIDs": ["m1"],
            },
            members=[
                {"id": "m1", "text": "Tá an fharraige anseo.", "qa_state": "qa_passed"}
            ],
            manifest_texts=["Tá an fharraige anseo."],
            bundle=False,
        )
        self.assertIn("bundle_missing", self.codes(report))
        self.assertGreater(report["summary"]["blocking"], 0)


class RealRepositoryTest(unittest.TestCase):
    """The shipped Mayo pack must keep loading in the app."""

    def test_mayo_pack_has_no_blocking_binding_findings(self):
        report = binding.audit(
            ROOT, county="mayo", pack_path=ROOT / binding.DEFAULT_PACK
        )
        blocking = [
            item for item in report["findings"] if item["code"] in binding.BLOCKING
        ]
        self.assertEqual(blocking, [], f"blocking binding findings: {blocking}")


if __name__ == "__main__":
    unittest.main()
