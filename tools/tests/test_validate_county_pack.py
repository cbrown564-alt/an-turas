"""Tests for the county-pack validator (tools/validate_county_pack.py).

The core regression is that every pack shipped in the bundle validates here — if
this validator and the runtime Swift guard disagreed on a shipping pack, one of
them would be wrong. The remaining tests cover the added enforcement rules and a
representative sample of the mirrored Swift rules, by mutating a known-good pack.
"""
import copy
import json
import sys
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools"))

import validate_county_pack as v  # noqa: E402
import build_phase5_county_drafts as phase5  # noqa: E402

PACKS_DIR = REPO_ROOT / "ios/AnTuras/Resources/CountyStories"
BUNDLED_PACKS = sorted(PACKS_DIR.glob("*.json"))
MAYO_PACK = PACKS_DIR / "mayo.grainne-1593.json"
MAYO_REVIEW_DRAFT = REPO_ROOT / "content/mayo/grainne-1593.pack.draft.json"
PHASE5_DRAFTS = {
    "offaly.cross-of-the-scriptures": REPO_ROOT
    / "content/offaly/cross-of-the-scriptures.pack.draft.json",
    "dublin.sihtric-penny": REPO_ROOT
    / "content/dublin/sihtric-penny.pack.draft.json",
    "meath.trim-de-lacy": REPO_ROOT
    / "content/meath/trim-de-lacy.pack.draft.json",
}
PHASE5_BUNDLED = {
    pack_id: PACKS_DIR / f"{pack_id}.json"
    for pack_id in PHASE5_DRAFTS
}


def load(path):
    return json.loads(Path(path).read_text())


class BundledPacksValidate(unittest.TestCase):
    def test_every_bundled_pack_validates(self):
        self.assertTrue(BUNDLED_PACKS, "expected bundled county packs to exist")
        for path in BUNDLED_PACKS:
            with self.subTest(pack=path.name):
                report = v.validate(load(path))
                self.assertEqual(report.pack_id, load(path)["pack"]["id"])

    def test_mayo_report_shape(self):
        report = v.validate(load(MAYO_PACK))
        self.assertGreater(report.story_minutes, 0)
        self.assertGreater(report.learning_minutes, 0)
        # The representative chapter fully stages its two proven lexemes.
        self.assertEqual(report.lifecycle_covered, 2)
        self.assertIn("Native-speaker audio QA", report.open_review_gates)


class MayoReviewDraftValidates(unittest.TestCase):
    def test_complete_nine_chapter_draft_passes_strict_rules(self):
        envelope = load(MAYO_REVIEW_DRAFT)
        report = v.validate(envelope)

        self.assertEqual(report.scope, "completeCounty")
        self.assertEqual(len(envelope["pack"]["chapters"]), 9)
        self.assertEqual(sum(report.exercise_distribution.values()), 38)
        # D27: nine families and containers, down from twelve pre-absorption.
        self.assertEqual(len(report.exercise_distribution), 9)
        self.assertEqual(report.lifecycle_covered, 20)
        self.assertGreaterEqual(report.story_minutes, 60)
        self.assertLessEqual(report.story_minutes, 90)

        pages = {
            page["id"]: page
            for chapter in envelope["pack"]["chapters"]
            for page in chapter["pages"]
        }
        resources = {resource["id"]: resource for resource in envelope["pack"]["resources"]}
        for lifecycle in envelope["pack"]["lifecycle"]:
            with self.subTest(lexeme=lifecycle["id"]):
                stage_pages = [
                    pages[lifecycle[key]]
                    for key in (
                        "introducedPageID",
                        "heardPageID",
                        "producedPageID",
                        "reusedPageID",
                    )
                ]
                self.assertTrue(
                    all(page["visibility"] != "storyOnly" for page in stage_pages),
                    "every lifecycle stage must appear in Learning mode",
                )
                self.assertIn(
                    lifecycle["id"],
                    stage_pages[0]["introducedLexemeIDs"],
                    "the lifecycle introduction must introduce its own lexeme",
                )
                heard_page = stage_pages[1]
                self.assertTrue(
                    any(
                        resources[resource_id]["kind"] == "audio"
                        for resource_id in heard_page["resourceIDs"]
                    ),
                    "the heard stage must reference an audio resource",
                )
                self.assertIn(
                    lifecycle["id"],
                    stage_pages[2]["exercise"]["lexemeIDs"],
                    "the production exercise must operate on its own lexeme",
                )


class Phase5ReviewDraftsValidate(unittest.TestCase):
    def test_three_complete_county_drafts_pass_strict_rules(self):
        for pack_id, path in PHASE5_DRAFTS.items():
            with self.subTest(pack=pack_id):
                envelope = load(path)
                report = v.validate(envelope)

                self.assertEqual(report.pack_id, pack_id)
                self.assertEqual(report.scope, "completeCounty")
                self.assertEqual(len(envelope["pack"]["chapters"]), 6)
                self.assertGreaterEqual(report.story_minutes, 45)
                self.assertEqual(sum(report.exercise_distribution.values()), 30)
                self.assertEqual(len(report.exercise_distribution), 9)
                self.assertEqual(report.lifecycle_covered, 20)
                self.assertTrue(report.open_review_gates)

                visual_pages = [
                    page
                    for chapter in envelope["pack"]["chapters"]
                    for page in chapter["pages"]
                    if page["visualResourceID"] is not None
                ]
                resources = {
                    resource["id"]: resource
                    for resource in envelope["pack"]["resources"]
                }
                # D28: one chapter-opening hero each; counties may mix video loops and
                # interim stills while Flow animation catches up.
                expected_visuals = {
                    "dublin.sihtric-penny": 6,
                    "meath.trim-de-lacy": 3,
                    "offaly.cross-of-the-scriptures": 2,
                }
                self.assertEqual(len(visual_pages), expected_visuals[pack_id])
                opening_visuals = [
                    page
                    for chapter in envelope["pack"]["chapters"]
                    for page in chapter["pages"][:1]
                    if page["visualResourceID"] is not None
                ]
                self.assertEqual(len(opening_visuals), expected_visuals[pack_id])
                for page in visual_pages:
                    visual = resources[page["visualResourceID"]]
                    self.assertIn(visual["kind"], ("video", "image"))
                    self.assertTrue(page["visualCaption"])
                    if visual["kind"] == "video":
                        fallback = resources[visual["fallbackResourceID"]]
                        self.assertEqual(fallback["kind"], "image")
                self.assertTrue(
                    any(
                        resources[page["visualResourceID"]]["kind"] == "video"
                        for page in visual_pages
                    )
                )

                pages = {
                    page["id"]: page
                    for chapter in envelope["pack"]["chapters"]
                    for page in chapter["pages"]
                }
                resources = {
                    resource["id"]: resource
                    for resource in envelope["pack"]["resources"]
                }
                for word_lifecycle in envelope["pack"]["lifecycle"]:
                    stage_pages = [
                        pages[word_lifecycle[key]]
                        for key in (
                            "introducedPageID",
                            "heardPageID",
                            "producedPageID",
                            "reusedPageID",
                        )
                    ]
                    self.assertIn(
                        word_lifecycle["id"],
                        stage_pages[0]["introducedLexemeIDs"],
                    )
                    self.assertTrue(
                        any(
                            resources[resource_id]["kind"] == "audio"
                            for resource_id in stage_pages[1]["resourceIDs"]
                        )
                    )
                    self.assertIn(
                        word_lifecycle["id"],
                        stage_pages[1]["exercise"]["lexemeIDs"],
                        "the heard exercise must operate on its own lexeme",
                    )
                    self.assertIn(
                        word_lifecycle["id"],
                        stage_pages[2]["exercise"]["lexemeIDs"],
                    )
                    self.assertIn(
                        stage_pages[2]["exercise"]["family"],
                        v.ACTIVE_PRODUCTION_FAMILIES,
                        "the production stage must use an active mechanic",
                    )

    def test_generated_drafts_are_current(self):
        specs = [phase5.offaly_spec(), phase5.dublin_spec(), phase5.meath_spec()]
        for spec in specs:
            with self.subTest(pack=spec["id"]):
                generated = phase5.assemble(spec)
                self.assertEqual(generated, load(PHASE5_DRAFTS[spec["id"]]))
                self.assertEqual(generated, load(PHASE5_BUNDLED[spec["id"]]))


class LexemeConvention(unittest.TestCase):
    def test_fada_folding(self):
        self.assertEqual(v.lexeme_id("caisleán"), "lex.caislean")
        self.assertEqual(v.lexeme_id("bá"), "lex.ba")
        self.assertEqual(v.lexeme_id("téigh"), "lex.teigh")
        self.assertEqual(v.lexeme_id("arís"), "lex.aris")


class AddedRules(unittest.TestCase):
    def setUp(self):
        self.pack = load(MAYO_PACK)

    def _expect(self, code):
        with self.assertRaises(v.PackValidationError) as ctx:
            v.validate(self.pack)
        self.assertEqual(ctx.exception.code, code)

    def test_complete_county_requires_all_twenty_lifecycles(self):
        # Promote the representative chapter to a full county without filling
        # in the other eighteen lifecycles: it must now fail.
        self.pack["pack"]["scope"] = "completeCounty"
        self._expect("incompleteLifecycle")

    def test_off_contract_lexeme_rejected(self):
        # Reference a lexeme id that is not one of the twenty headwords.
        page = self.pack["pack"]["chapters"][0]["pages"][0]
        page["introducedLexemeIDs"] = page.get("introducedLexemeIDs", []) + ["lex.dragon"]
        self._expect("offContractLexeme")

    def test_representative_chapter_allows_partial_lifecycle(self):
        # The shipping representative pack has 2 lifecycles for 20 words and must
        # still pass — the all-twenty rule is scoped to completeCounty only.
        report = v.validate(self.pack)
        self.assertEqual(report.scope, "representativeChapter")

    def test_video_visual_with_image_fallback_is_valid(self):
        page = self.pack["pack"]["chapters"][0]["pages"][0]
        page["resourceIDs"].append("video.test")
        page["visualResourceID"] = "video.test"
        self.pack["pack"]["resources"].append(
            {
                "id": "video.test",
                "kind": "video",
                "value": "video.test",
                "status": "production-video-loop",
                "fallbackResourceID": "image.clew-bay",
            }
        )

        self.assertEqual(v.validate(self.pack).pack_id, "mayo.grainne-1593")

    def test_video_visual_requires_image_fallback(self):
        page = self.pack["pack"]["chapters"][0]["pages"][0]
        page["resourceIDs"].append("video.test")
        page["visualResourceID"] = "video.test"
        self.pack["pack"]["resources"].append(
            {
                "id": "video.test",
                "kind": "video",
                "value": "video.test",
                "status": "production-video-loop",
                "fallbackResourceID": "evidence.rockfleet-c07",
            }
        )

        self._expect("missingResource")


class MirroredSwiftRules(unittest.TestCase):
    def setUp(self):
        self.pack = load(MAYO_PACK)

    def _expect(self, code):
        with self.assertRaises(v.PackValidationError) as ctx:
            v.validate(self.pack)
        self.assertEqual(ctx.exception.code, code)

    def test_word_count_must_be_twenty(self):
        self.pack["pack"]["targetWords"].pop()
        self._expect("invalidWordContract")

    def test_duplicate_page_id(self):
        pages = self.pack["pack"]["chapters"][0]["pages"]
        pages[1]["id"] = pages[0]["id"]
        self._expect("duplicateID")

    def test_exercise_may_not_appear_in_story_mode(self):
        # Make an exercise page visible to story mode.
        for page in self.pack["pack"]["chapters"][0]["pages"]:
            if page["kind"] == "exercise":
                page["visibility"] = "both"
                break
        self._expect("exerciseOnStoryPath")

    def test_premature_lexeme(self):
        # Point the first exercise at a lexeme introduced later in the pack.
        for page in self.pack["pack"]["chapters"][0]["pages"]:
            if page["kind"] == "exercise":
                page["exercise"]["lexemeIDs"] = ["lex.costa"]  # cósta, introduced late/never here
                break
        self._expect("prematureLexeme")

    def test_lifecycle_order_enforced(self):
        entry = self.pack["pack"]["lifecycle"][0]
        entry["introducedPageID"], entry["reusedPageID"] = (
            entry["reusedPageID"],
            entry["introducedPageID"],
        )
        self._expect("invalidLifecycle")

    def test_missing_resource_reference(self):
        self.pack["pack"]["chapters"][0]["pages"][0]["resourceIDs"] = ["resource.does-not-exist"]
        self._expect("missingResource")

    def test_matching_board_is_capped_at_four_pairs(self):
        # F5: a fifth pair turns the brief distinction board into a mastery chore.
        for page in self.pack["pack"]["chapters"][0]["pages"]:
            exercise = page.get("exercise") or {}
            if exercise.get("family") == "matching":
                exercise["pairs"].append(
                    {"id": "costa", "left": "cósta", "right": "coast"}
                )
                break
        self._expect("invalidMatchingBoard")

    def test_matching_board_needs_at_least_two_pairs(self):
        for page in self.pack["pack"]["chapters"][0]["pages"]:
            exercise = page.get("exercise") or {}
            if exercise.get("family") == "matching":
                exercise["pairs"] = exercise["pairs"][:1]
                break
        self._expect("invalidMatchingBoard")

    def test_unsupported_schema(self):
        self.pack["schemaVersion"] = 99
        self._expect("unsupportedSchema")


class D27LayerRules(unittest.TestCase):
    """Percentages run over every activity page; diversity counts families only."""

    def setUp(self):
        self.pack = load(MAYO_REVIEW_DRAFT)

    def _exercises(self):
        return [
            page["exercise"]
            for chapter in self.pack["pack"]["chapters"]
            for page in chapter["pages"]
            if page.get("exercise")
        ]

    def _expect(self, code):
        with self.assertRaises(v.PackValidationError) as ctx:
            v.validate(self.pack)
        self.assertEqual(ctx.exception.code, code)

    def test_containers_do_not_satisfy_family_diversity(self):
        # Collapse everything but six response families into the conversation
        # container. Thirty-eight activities across seven distinct values still
        # fails, because only response families count toward diversity.
        keep = {"listenChoose", "sentenceConstruction", "fillGap",
                "matching", "freeTyping", "readRespond"}
        for exercise in self._exercises():
            if exercise["family"] not in keep:
                exercise["family"] = "conversation"
        families = {e["family"] for e in self._exercises()}
        self.assertEqual(len(families), 7)
        self._expect("exerciseDistribution")

    def test_conversation_counts_toward_production(self):
        # A container carries real production load, so moving production into
        # conversation must not break the 40 percent floor.
        for exercise in self._exercises():
            if exercise["family"] == "recordCompare":
                exercise["family"] = "conversation"
        report = v.validate(self.pack)
        self.assertNotIn("recordCompare", report.exercise_distribution)
        self.assertEqual(report.exercise_distribution["conversation"], 5)

    def test_authored_use_is_counted_apart_from_its_family(self):
        # Absorbing ordering and audio-prompted construction into sentence
        # construction concentrates the pack. The authored use keeps the
        # monotony cap measuring what the learner actually does, so erasing it
        # must trip the cap.
        for exercise in self._exercises():
            exercise.pop("authoredUse", None)
        self._expect("exerciseDistribution")


if __name__ == "__main__":
    unittest.main()
