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
CONTRACT_ENUMS = REPO_ROOT / "ios/AnTuras/Resources/Fixtures/contract-enums.json"
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

    def test_audio_text_must_belong_to_frozen_inventory(self):
        page = self.pack["pack"]["chapters"][0]["pages"][0]
        exercise = page.get("exercise")
        if not exercise:
            # First page may be narrative; find any exercise.
            for chapter in self.pack["pack"]["chapters"]:
                for candidate in chapter["pages"]:
                    if candidate.get("exercise"):
                        page = candidate
                        exercise = candidate["exercise"]
                        break
        exercise["audioText"] = "Níl an líne seo san inventory."
        self._expect("audioNotInInventory")

    def test_unknown_phrase_family_member_rejected(self):
        for chapter in self.pack["pack"]["chapters"]:
            for page in chapter["pages"]:
                exercise = page.get("exercise")
                if exercise and exercise.get("answer"):
                    exercise["phraseFamilyMemberIDs"] = ["farraige.not-a-real-member"]
                    self._expect("unknownPhraseFamilyMember")
                    return
        self.fail("no exercise with an answer found")

    def test_phrase_family_member_mismatch_rejected(self):
        for chapter in self.pack["pack"]["chapters"]:
            for page in chapter["pages"]:
                exercise = page.get("exercise")
                if not exercise:
                    continue
                # Castle-here member must not bind to an unrelated answer.
                if exercise.get("answer") == "Tá an caisleán anseo.":
                    exercise["phraseFamilyMemberIDs"] = ["farraige.ship-on-sea"]
                    self._expect("phraseFamilyMemberMismatch")
                    return
        self.fail("no castle-here exercise found")

    def test_wired_phrase_family_members_pass(self):
        # Bundled Rockfleet now carries D30 member ids where answers match.
        report = v.validate(self.pack)
        self.assertGreaterEqual(
            sum(
                1
                for ch in self.pack["pack"]["chapters"]
                for p in ch["pages"]
                if (p.get("exercise") or {}).get("phraseFamilyMemberIDs")
            ),
            1,
        )
        self.assertEqual(report.pack_id, "mayo.grainne-1593")

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


class ContainerPayloadRules(unittest.TestCase):
    """C1 turn-graph, C5 completion and C3 review payload gates, mirrored from Swift."""

    def setUp(self):
        self.pack = load(MAYO_PACK)

    def _expect(self, code):
        with self.assertRaises(v.PackValidationError) as ctx:
            v.validate(self.pack)
        self.assertEqual(ctx.exception.code, code)

    def _dialogue_exercise(self):
        for page in self.pack["pack"]["chapters"][0]["pages"]:
            exercise = page.get("exercise") or {}
            if exercise.get("family") == "conversation":
                return page, exercise
        raise AssertionError("Mayo pack lost its conversation exercise")

    @staticmethod
    def _graph(next_target="n2"):
        return {
            "setting": "present-day",
            "start": "n1",
            "nodes": [
                {
                    "id": "n1",
                    "partner": "Cárb as tú?",
                    "partnerGloss": "Where are you from?",
                    "audioText": None,
                    "replies": [
                        {"id": "a", "text": "Is as Maigh Eo mé.", "gloss": None,
                         "isFitting": True, "diagnostic": None, "next": next_target,
                         "audioText": None},
                        {"id": "b", "text": "Bá.", "gloss": None,
                         "isFitting": False, "diagnostic": "That names the bay.",
                         "next": None, "audioText": None},
                    ],
                },
                {
                    "id": "n2",
                    "partner": "Cén t-ainm atá ort?",
                    "partnerGloss": None,
                    "audioText": None,
                    "replies": [
                        {"id": "c", "text": "Is mise …", "gloss": None,
                         "isFitting": True, "diagnostic": None, "next": "n3",
                         "audioText": None},
                        {"id": "d", "text": "Cé thusa?", "gloss": None,
                         "isFitting": True, "diagnostic": None, "next": "n3",
                         "audioText": None},
                    ],
                },
                {
                    "id": "n3",
                    "partner": "Slán go fóill.",
                    "partnerGloss": None,
                    "audioText": None,
                    "replies": [
                        {"id": "e", "text": "Slán go fóill.", "gloss": None,
                         "isFitting": True, "diagnostic": None, "next": None,
                         "audioText": None},
                    ],
                },
            ],
        }

    def test_valid_conversation_graph_passes(self):
        _, exercise = self._dialogue_exercise()
        exercise["options"] = []
        exercise["conversation"] = self._graph()
        self.assertEqual(v.validate(self.pack).pack_id, "mayo.grainne-1593")

    def test_conversation_graph_rejects_dangling_next(self):
        _, exercise = self._dialogue_exercise()
        exercise["options"] = []
        exercise["conversation"] = self._graph(next_target="nowhere")
        self._expect("invalidConversationGraph")

    def test_conversation_graph_rejects_missing_setting(self):
        _, exercise = self._dialogue_exercise()
        exercise["options"] = []
        graph = self._graph()
        graph["setting"] = ""
        exercise["conversation"] = graph
        self._expect("invalidConversationGraph")

    def test_conversation_graph_rejects_a_bare_single_exchange(self):
        _, exercise = self._dialogue_exercise()
        exercise["options"] = []
        graph = self._graph()
        graph["nodes"] = graph["nodes"][:1]
        exercise["conversation"] = graph
        self._expect("invalidConversationGraph")

    def test_completion_requires_capabilities(self):
        _, exercise = self._dialogue_exercise()
        exercise["family"] = "completion"
        exercise["options"] = []
        self._expect("invalidCompletionPayload")

    def test_contextual_review_requires_candidates(self):
        _, exercise = self._dialogue_exercise()
        exercise["family"] = "contextualReview"
        exercise["options"] = []
        self._expect("invalidReviewPayload")


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


class MirroredRuleGaps(unittest.TestCase):
    """Failing fixtures for pre-existing mirrored codes that had none."""

    def setUp(self):
        self.pack = load(MAYO_PACK)

    def _expect(self, code):
        with self.assertRaises(v.PackValidationError) as ctx:
            v.validate(self.pack)
        self.assertEqual(ctx.exception.code, code)

    def _first_exercise_page(self):
        for chapter in self.pack["pack"]["chapters"]:
            for page in chapter["pages"]:
                if page["kind"] == "exercise" and page.get("exercise"):
                    return page, page["exercise"]
        raise AssertionError("Mayo pack lost its exercises")

    def test_pack_id_must_be_dotted_with_positive_revision(self):
        self.pack["pack"]["id"] = "mayo"
        self._expect("invalidPackID")

    def test_chapter_must_be_non_empty_in_both_modes(self):
        for page in self.pack["pack"]["chapters"][0]["pages"]:
            page["visibility"] = "learningOnly"
        self._expect("emptyModeChapter")

    def test_completion_must_reference_visible_pages(self):
        self.pack["pack"]["completion"]["learningPageIDs"].append("mayo.rockfleet.missing")
        self._expect("invalidCompletionPage")

    def test_exercise_page_needs_an_exercise_payload(self):
        page, _ = self._first_exercise_page()
        page["exercise"] = None
        self._expect("missingExercise")

    def test_options_may_not_repeat_the_correct_answer(self):
        _, exercise = self._first_exercise_page()
        exercise["options"][1]["text"] = exercise["options"][0]["text"]
        self._expect("duplicateAnswer")

    def test_audio_family_needs_audio_text_and_bundled_reference(self):
        page, exercise = self._first_exercise_page()
        self.assertEqual(exercise["family"], "listenChoose")
        exercise["audioText"] = None
        self._expect("missingRequiredAudio")

    def test_legacy_three_page_chapters_are_rejected(self):
        # Re-chunk the 23-page pack into three-page chapters (one appended
        # story page makes 24) without disturbing page order, so every earlier
        # rule still passes and only the fixed-template shape fails.
        pack = self.pack["pack"]
        pages = [page for chapter in pack["chapters"] for page in chapter["pages"]]
        pages.append(
            {
                "id": "mayo.rockfleet.epilogue-test",
                "legacyBeatIndex": None,
                "title": "Epilogue",
                "context": "Rockfleet",
                "body": "The tide keeps its own time.",
                "detail": None,
                "visibility": "storyOnly",
                "requirement": "optional",
                "kind": "narrative",
                "estimatedSeconds": 30,
                "introducedLexemeIDs": [],
                "resourceIDs": [],
                "exercise": None,
                "presentation": None,
                "advanceLabel": None,
                "visualResourceID": None,
                "visualCaption": None,
                "displayItems": None,
            }
        )
        pack["chapters"] = [
            {
                "id": f"mayo.test-chapter-{index // 3}",
                "title": f"Test chapter {index // 3}",
                "place": "Rockfleet",
                "pages": pages[index : index + 3],
            }
            for index in range(0, len(pages), 3)
        ]
        self._expect("legacyBeatStructure")


class ContractRules(unittest.TestCase):
    """The authored learning-contract rules fire wherever an exercise carries a
    ``learningContract``, mirrored 1:1 with the Swift validator. Production
    packs stay flat and adapted until the production-slice migration, so these
    tests inject a contract into the bundled Mayo pack and break one rule."""

    def setUp(self):
        self.pack = load(MAYO_PACK)

    def _expect(self, code):
        with self.assertRaises(v.PackValidationError) as ctx:
            v.validate(self.pack)
        self.assertEqual(ctx.exception.code, code)

    def _exercise_page(self, family):
        for chapter in self.pack["pack"]["chapters"]:
            for page in chapter["pages"]:
                exercise = page.get("exercise")
                if exercise and exercise.get("family") == family:
                    return page, exercise
        raise AssertionError(f"Mayo pack lost its {family} exercise")

    @staticmethod
    def _contract(exercise, **overrides):
        contract = {
            "objective": exercise.get("objective"),
            "targets": [
                {"id": lexeme, "capability": "recalled"}
                for lexeme in exercise.get("lexemeIDs", [])
            ],
            "misconceptions": [
                {
                    "id": "fallback",
                    "rationale": "A response the named diagnostics do not cover.",
                    "feedback": "Try the line again with the model.",
                }
            ],
            "successFeedback": "The line holds.",
            "hint": "Keep the frame.",
            "recovery": {
                "guidance": "Read the model once, then answer again.",
                "requiredResponse": "Make the response again after the support.",
            },
            "completionEvidence": "correctConstruction",
        }
        contract.update(overrides)
        return contract

    def test_valid_authored_contract_passes(self):
        _, exercise = self._exercise_page("freeTyping")
        exercise["learningContract"] = self._contract(exercise)
        report = v.validate(self.pack)
        self.assertEqual(report.contract_authored, 1)
        self.assertEqual(report.contract_adapted, 11)

    def test_distractor_without_misconception_mapping(self):
        _, exercise = self._exercise_page("listenChoose")
        exercise["learningContract"] = self._contract(
            exercise, completionEvidence="correctSelection"
        )
        self._expect("missingMisconceptionMapping")

    def test_distractor_referencing_undeclared_misconception(self):
        _, exercise = self._exercise_page("listenChoose")
        exercise["options"][1]["misconceptionID"] = "ghost"
        exercise["learningContract"] = self._contract(
            exercise, completionEvidence="correctSelection"
        )
        self._expect("missingMisconceptionMapping")

    def test_constructed_response_without_diagnostics(self):
        _, exercise = self._exercise_page("freeTyping")
        exercise["learningContract"] = self._contract(exercise, misconceptions=[])
        self._expect("missingDiagnosticCases")

    def test_hint_equal_to_the_accepted_answer(self):
        _, exercise = self._exercise_page("freeTyping")
        exercise["learningContract"] = self._contract(
            exercise, hint=exercise["answer"]
        )
        self._expect("answerRevealingHint")

    def test_hint_containing_the_answer_fada_folded(self):
        _, exercise = self._exercise_page("freeTyping")
        folded = exercise["answer"].translate(v._FADA).lower()
        exercise["learningContract"] = self._contract(
            exercise, hint=f"Write it once: {folded} — then check."
        )
        self._expect("answerRevealingHint")

    def test_recovery_declaring_a_different_target_set(self):
        _, exercise = self._exercise_page("freeTyping")
        contract = self._contract(exercise)
        contract["recovery"]["targetIDs"] = ["lex.teaghlach"]
        exercise["learningContract"] = contract
        self._expect("targetChangingRecovery")

    def test_recovery_restating_the_same_targets_passes(self):
        _, exercise = self._exercise_page("freeTyping")
        contract = self._contract(exercise)
        contract["recovery"]["targetIDs"] = list(exercise["lexemeIDs"])
        exercise["learningContract"] = contract
        self.assertEqual(v.validate(self.pack).pack_id, "mayo.grainne-1593")

    def test_evidence_incompatible_with_the_family(self):
        _, exercise = self._exercise_page("freeTyping")
        exercise["learningContract"] = self._contract(
            exercise, completionEvidence="validDialogueTurn"
        )
        self._expect("unsupportedCompletionEvidence")

    def test_memory_credit_naming_an_untargeted_lexeme(self):
        _, exercise = self._exercise_page("freeTyping")
        exercise["learningContract"] = self._contract(
            exercise,
            targets=[{"id": "lex.teaghlach", "capability": "recalled"}],
        )
        self._expect("offTargetMemoryCredit")

    @staticmethod
    def _review_candidate(origin_page_id, lexemes):
        return {
            "id": "cand.test",
            "pageID": origin_page_id,
            "label": "the castle word",
            "exercise": {
                "family": "listenChoose",
                "objective": "Hear caisleán again.",
                "prompt": "Hear the word again, then choose its meaning.",
                "answer": "castle",
                "options": [],
                "tokens": [],
                "pairs": [],
                "feedback": "It holds this time.",
                "hint": "Replay the word.",
                "recovery": "Replay and answer again.",
                "lexemeIDs": lexemes,
                "operatesOnSentence": False,
                "recognitionMultipleChoice": True,
            },
        }

    def _review_exercise(self, candidate):
        page, exercise = self._exercise_page("freeTyping")
        exercise["family"] = "contextualReview"
        exercise["reviewCandidates"] = [candidate]
        return page, exercise

    def test_review_candidate_must_trace_to_its_origin(self):
        candidate = self._review_candidate(
            "mayo.rockfleet.listen-caislean", ["lex.teaghlach"]
        )
        self._review_exercise(candidate)
        self._expect("untraceableReviewTarget")

    def test_review_candidate_traced_to_origin_passes(self):
        candidate = self._review_candidate(
            "mayo.rockfleet.listen-caislean", ["lex.caislean"]
        )
        self._review_exercise(candidate)
        self.assertEqual(v.validate(self.pack).pack_id, "mayo.grainne-1593")

    def _completion_exercise(self, lexemes):
        page, exercise = self._exercise_page("readRespond")
        exercise["family"] = "completion"
        exercise["options"] = []
        exercise["lexemeIDs"] = lexemes
        exercise["capabilities"] = [
            {
                "id": "say",
                "title": "You can say where you are.",
                "detail": "The frame is yours.",
                "symbol": "person.wave.2",
            }
        ]
        return page, exercise

    def test_capability_claim_without_supporting_evidence(self):
        # No exercise targets lex.farraige, so a completion targeting only it
        # has no completed-target evidence behind its claims.
        arrival = self.pack["pack"]["chapters"][0]["pages"][0]
        arrival["introducedLexemeIDs"] = arrival["introducedLexemeIDs"] + ["lex.farraige"]
        self._completion_exercise(["lex.farraige"])
        self._expect("unsupportedCapabilityClaim")

    def test_capability_claim_with_supporting_evidence_passes(self):
        # listen-caislean targets lex.caislean with declared (adapted) evidence.
        self._completion_exercise(["lex.caislean"])
        self.assertEqual(v.validate(self.pack).pack_id, "mayo.grainne-1593")


class SharedEnumList(unittest.TestCase):
    """Runtime and validator enums are checked against one shared documented
    list (rebuild plan, 'Automated enforcement') so a pack cannot pass offline
    and fail after decoding."""

    def setUp(self):
        self.enums = load(CONTRACT_ENUMS)

    def test_python_constants_match_the_shared_list(self):
        self.assertEqual(set(self.enums["responseFamilies"]), v.RESPONSE_FAMILIES)
        self.assertEqual(set(self.enums["pureContainers"]), v.PURE_CONTAINERS)
        self.assertEqual(tuple(self.enums["authoredUses"]), v.AUTHORED_USES)
        self.assertEqual(set(self.enums["targetCapabilities"]), v.TARGET_CAPABILITIES)
        self.assertEqual(
            set(self.enums["completionEvidenceKinds"]), v.COMPLETION_EVIDENCE_KINDS
        )
        self.assertEqual(set(self.enums["memoryEventKinds"]), v.MEMORY_EVENT_KINDS)

    def test_shared_list_covers_every_family_exactly_once(self):
        response = self.enums["responseFamilies"]
        containers = self.enums["pureContainers"]
        self.assertEqual(len(response), len(set(response)))
        self.assertTrue(set(response).isdisjoint(containers))
        # The compatibility table declares an entry for every family and only
        # names known evidence kinds.
        self.assertEqual(set(v.FAMILY_COMPLETION_EVIDENCE), set(response) | set(containers))
        for kinds in v.FAMILY_COMPLETION_EVIDENCE.values():
            self.assertLessEqual(kinds, v.COMPLETION_EVIDENCE_KINDS)


if __name__ == "__main__":
    unittest.main()
