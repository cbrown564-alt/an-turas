"""Adversarial tests for the v2 Irish authoring and generation contract."""

from __future__ import annotations

import copy
import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools"))

import structured_audio_authoring as contract  # noqa: E402
import validate_county_pack  # noqa: E402


class StructuredAudioAuthoringTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.errors, cls.loaded = contract.validate_contract()
        cls.families = {family["id"]: family for family in cls.loaded.families}

    def member_errors(self, member: dict, family_id: str) -> list[str]:
        errors: list[str] = []
        contract.validate_member(
            member,
            self.families[family_id],
            REPO_ROOT,
            self.loaded.placements,
            self.loaded.inventory,
            errors,
        )
        return errors

    def reviewed_invented_contract(self) -> contract.LoadedContract:
        loaded = copy.deepcopy(self.loaded)
        member = loaded.members["farraige.sea-here"]
        member["states"]["reviews"]["pedagogy"] = {
            "status": "approved",
            "record": {
                "reviewer_ref": "review.synthetic.pedagogue",
                "reviewed_at": "2026-08-01",
                "scope": "Synthetic transition test only",
                "evidence_ref": "tools/tests/test_structured_audio_authoring.py",
            },
        }
        member["states"]["capture_request"] = {
            "status": "requested",
            "requested_by": "author.synthetic",
            "requested_at": "2026-08-01T10:00:00Z",
            "authorization": {
                "basis": "pedagogy_approved",
                "authorized_by": "owner.synthetic",
                "authorized_at": "2026-08-01T10:01:00Z",
                "reason": "Exercise-bound reviewed invention transition test",
                "fixture_only": False,
            },
            "batch_line_ids": [],
        }
        return loaded

    def test_checked_in_contract_is_valid(self):
        self.assertEqual(self.errors, [])

    def test_county_pack_validator_can_resolve_canonical_v2_members(self):
        members = validate_county_pack.load_phrase_family_members("mayo")
        self.assertEqual(
            members["ainm.grainne-named"]["text"], "Gráinne is ainm di."
        )
        self.assertEqual(
            members["farraige.sea-here"]["text"], "Tá an fharraige anseo."
        )

    def test_coverage_keeps_placements_spellings_senses_and_release_separate(self):
        report = contract.coverage_report(self.loaded)
        self.assertEqual(report["atlas"]["county_placements"], 640)
        self.assertEqual(report["atlas"]["orthographic_headwords"], 191)
        self.assertEqual(report["atlas"]["orthographic_headwords_in_multiple_counties"], 96)
        self.assertEqual(report["atlas"]["orthographic_headwords_with_multiple_glosses"], 12)
        self.assertGreaterEqual(report["authoring_store"]["atlas_placements_covered"], 2)
        self.assertLessEqual(
            report["authoring_store"]["atlas_placements_covered"],
            report["atlas"]["county_placements"],
        )
        self.assertGreaterEqual(report["authoring_store"]["distinct_senses"], 2)
        self.assertEqual(report["authoring_store"]["learner_release_eligible_members"], 0)
        self.assertEqual(
            report["planning_targets"]["capture_inventory"],
            {"minimum_utterances": 3000, "maximum_utterances": 5000},
        )
        self.assertEqual(
            report["planning_targets"]["first_learner_release_inventory"],
            {"minimum_utterances": 1200, "maximum_utterances": 1500},
        )
        self.assertEqual(
            self.loaded.store["capacity_policy"]["irish_priority_order"],
            contract.IRISH_PRIORITY_ORDER,
        )
        self.assertIn(
            "bounded minority",
            self.loaded.store["capacity_policy"]["reserves"]["speaking_clearly"],
        )

    def test_store_is_appendable_beyond_sixteen_members(self):
        family_id = "mayo.grainne-1593.farraige.sea-noun"
        template = copy.deepcopy(self.loaded.members["farraige.ship-on-sea"])
        for index in range(20):
            member = copy.deepcopy(template)
            member["id"] = f"farraige.future-draft-{index:02d}"
            member["states"]["authoring"]["status"] = "draft"
            member["irish"] = None
            member["english"] = None
            member["target"]["target_form"] = None
            member["target"]["morphology"] = None
            member["exercise_consumers"] = []
            member["states"]["audio_qa"] = {
                "status": "not_generated",
                "record": None,
                "batch_line_id": None,
            }
            member["states"]["learner_release"] = {
                "status": "blocked",
                "reasons": ["authoring_incomplete"],
            }
            self.assertEqual(self.member_errors(member, family_id), [])

    def test_outer_inner_family_identity_is_enforced(self):
        member = copy.deepcopy(self.loaded.members["ainm.grainne-named"])
        member["family_id"] = "mayo.wrong-family"
        errors = self.member_errors(member, "mayo.grainne-1593.ainm.name-noun")
        self.assertTrue(any("family_id does not match" in error for error in errors))

    def test_store_outer_family_identity_and_order_are_enforced(self):
        store = copy.deepcopy(self.loaded.store)
        store["family_documents"].reverse()
        store["family_documents"][0]["family_id"] = "mayo.wrong.outer-id"
        with tempfile.TemporaryDirectory() as temporary:
            store_path = Path(temporary) / "store.json"
            store_path.write_text(
                json.dumps(store, ensure_ascii=False, indent=2), encoding="utf-8"
            )
            errors, _ = contract.validate_contract(store_path=store_path)
        self.assertTrue(any("sorted unique family_id" in error for error in errors))
        self.assertTrue(any("outer family id" in error for error in errors))

    def test_missing_source_and_story_records_are_rejected(self):
        member = copy.deepcopy(self.loaded.members["ainm.grainne-named"])
        member["provenance"]["source_refs"][0]["record_id"] = "missing.page"
        member["exercise_consumers"][0]["record_id"] = "missing.exercise"
        errors = self.member_errors(member, "mayo.grainne-1593.ainm.name-noun")
        self.assertTrue(any("record_id 'missing.page' not found" in error for error in errors))
        self.assertTrue(any("record_id 'missing.exercise' not found" in error for error in errors))

    def test_exercise_family_and_member_binding_are_enforced(self):
        member = copy.deepcopy(self.loaded.members["farraige.where-sea"])
        member["exercise_consumers"][0]["response_family"] = "listenChoose"
        errors = self.member_errors(member, "mayo.grainne-1593.farraige.sea-noun")
        self.assertTrue(any("response family does not match exercise" in error for error in errors))

        member = copy.deepcopy(self.loaded.members["farraige.where-sea"])
        member["id"] = "farraige.unbound-copy"
        errors = self.member_errors(member, "mayo.grainne-1593.farraige.sea-noun")
        self.assertTrue(any("exercise does not bind this member id" in error for error in errors))

    def test_inventory_provenance_conflict_is_rejected(self):
        member = copy.deepcopy(self.loaded.members["farraige.sea-here"])
        member["provenance"]["origin"] = "repository_draft"
        member["provenance"]["invented"] = False
        member["risk_flags"].remove("invented_text")
        errors = self.member_errors(member, "mayo.grainne-1593.farraige.sea-noun")
        self.assertTrue(any("provenance conflicts with inventory" in error for error in errors))

    def test_reviewed_invention_can_request_capture_without_losing_origin(self):
        member = self.reviewed_invented_contract().members["farraige.sea-here"]
        self.assertTrue(member["provenance"]["invented"])
        self.assertEqual(
            self.member_errors(member, "mayo.grainne-1593.farraige.sea-noun"), []
        )

    def test_unreviewed_invention_cannot_silently_request_capture(self):
        member = copy.deepcopy(self.loaded.members["farraige.sea-here"])
        member["states"]["reviews"]["pedagogy"] = {
            "status": "pending",
            "record": None,
        }
        member["states"]["capture_request"] = {
            "status": "requested",
            "requested_by": "author.synthetic",
            "requested_at": "2026-08-01T10:00:00Z",
            "authorization": {
                "basis": "pedagogy_approved",
                "authorized_by": "owner.synthetic",
                "authorized_at": "2026-08-01T10:01:00Z",
                "reason": "Unsafe test",
                "fixture_only": False,
            },
            "batch_line_ids": [],
        }
        errors = self.member_errors(member, "mayo.grainne-1593.farraige.sea-noun")
        self.assertTrue(any("requires approved pedagogy review" in error for error in errors))

    def test_fixture_exception_is_explicit_and_bounded(self):
        member = copy.deepcopy(self.loaded.members["farraige.sea-here"])
        member["states"]["capture_request"] = {
            "status": "requested",
            "requested_by": "author.synthetic",
            "requested_at": "2026-08-01T10:00:00Z",
            "authorization": {
                "basis": "fixture_owner_exception",
                "authorized_by": "owner.synthetic",
                "authorized_at": "2026-08-01T10:01:00Z",
                "reason": "D30 fixture-only generation path",
                "fixture_only": True,
            },
            "batch_line_ids": [],
        }
        self.assertEqual(
            self.member_errors(member, "mayo.grainne-1593.farraige.sea-noun"), []
        )
        member["learning"]["fixture_only"] = False
        errors = self.member_errors(member, "mayo.grainne-1593.farraige.sea-noun")
        self.assertTrue(any("fixture exception" in error for error in errors))

    def test_unknown_enums_and_unsafe_release_are_rejected(self):
        member = copy.deepcopy(self.loaded.members["ainm.grainne-named"])
        member["risk_flags"].append("mystery_risk")
        member["states"]["reviews"]["editorial"]["status"] = "banana"
        member["states"]["learner_release"] = {"status": "eligible", "reasons": []}
        errors = self.member_errors(member, "mayo.grainne-1593.ainm.name-noun")
        self.assertTrue(any("unknown risk flags" in error for error in errors))
        self.assertTrue(any("invalid review status" in error for error in errors))
        self.assertTrue(any("release requires approved" in error for error in errors))
        self.assertTrue(any("release requires passed audio QA" in error for error in errors))

    def test_malformed_list_values_report_errors_instead_of_crashing(self):
        member = copy.deepcopy(self.loaded.members["ainm.grainne-named"])
        member["binding"]["atlas_placement_ids"] = [{}]
        member["learning"]["stages"] = [{}]
        member["learning"]["roles"] = [{}]
        member["risk_flags"] = [{}]
        member["states"]["capture_request"]["batch_line_ids"] = [{}]
        errors = self.member_errors(member, "mayo.grainne-1593.ainm.name-noun")
        self.assertTrue(any("atlas placement ids" in error for error in errors))
        self.assertTrue(any("learning stages" in error for error in errors))
        self.assertTrue(any("member roles" in error for error in errors))
        self.assertTrue(any("risk flags" in error for error in errors))
        self.assertTrue(any("batch_line_ids" in error for error in errors))

    def test_canonical_slug_matches_every_inventory_entry_and_generated_file(self):
        inventory = json.loads(contract.INVENTORY_PATH.read_text(encoding="utf-8"))
        for entry in inventory["entries"]:
            self.assertEqual(contract.canonical_audio_slug(entry["text"]), entry["slug"])
            if entry["qa_state"] in {"generated_unreviewed", "spot_flagged", "qa_passed"}:
                self.assertTrue(
                    (REPO_ROOT / "ios/AnTuras/Resources/Audio" / f"{entry['slug']}.mp3").is_file()
                )

    def test_batch_builder_is_deterministic_and_deduplicates_member_ids(self):
        first = contract.build_batch(
            self.loaded,
            batch_id="test.batch",
            member_ids=["ainm.grainne-named", "ainm.grainne-named"],
            voice_profile_id="voice.irish-cultural-guide.eleven-v3.v1",
            created_at="2026-08-01T00:00:00Z",
            purpose="Determinism test",
        )
        second = contract.build_batch(
            self.loaded,
            batch_id="test.batch",
            member_ids=["ainm.grainne-named"],
            voice_profile_id="voice.irish-cultural-guide.eleven-v3.v1",
            created_at="2026-08-01T00:00:00Z",
            purpose="Determinism test",
        )
        self.assertEqual(first, second)
        self.assertEqual(first["counts"]["lines"], 1)
        self.assertEqual(first["lines"][0]["provider_result"]["status"], "not_started")
        self.assertEqual(
            first["lines"][0]["capture_disposition"], "generated_unreviewed"
        )
        self.assertFalse(first["execution"]["provider_calls_allowed"])

    def test_harvest_planner_normalizes_nfc_and_reuses_registered_lines(self):
        family = copy.deepcopy(self.families["mayo.grainne-1593.ainm.name-noun"])
        family["members"][0]["irish"]["text"] = "Gra\u0301inne is ainm di."
        family["members"][0]["irish"]["normalized_text"] = "stale"
        plan = contract.prepare_harvest(
            self.loaded,
            [(REPO_ROOT / "content/mayo/phrase-families/authoring-v2/ainm.name-noun.v2.json", family)],
            root=REPO_ROOT,
            created_at="2026-08-02T00:00:00Z",
        )
        self.assertEqual(plan["errors"], [])
        normalized = plan["normalized_documents"][0]["family"]["members"][0]["irish"]
        self.assertEqual(normalized["text"], "Gráinne is ainm di.")
        self.assertEqual(normalized["normalized_text"], "Gráinne is ainm di.")
        self.assertEqual(normalized["text_sha256"], contract.text_sha256(normalized["text"]))
        self.assertEqual(plan["batches"], [])
        self.assertEqual(plan["skipped_registered"][0]["action"], "reuse_registered_line")

    def test_harvest_planner_merges_duplicate_text_voice_lines_and_blocks_drafts(self):
        first = copy.deepcopy(self.families["mayo.grainne-1593.ainm.name-noun"])
        duplicate = copy.deepcopy(self.families["mayo.grainne-1593.farraige.sea-noun"])
        duplicate["id"] = "mayo.grainne-1593.farraige.duplicate-sense"
        duplicate["members"] = [duplicate["members"][1]]
        duplicate["target"]["sense_id"] = "farraige.duplicate-sense"
        duplicate["members"][0]["family_id"] = duplicate["id"]
        duplicate["members"][0]["target"]["sense_id"] = "farraige.duplicate-sense"
        duplicate["members"][0]["target"]["target_form"] = "Gráinne"
        duplicate["members"][0]["irish"]["text"] = "Gráinne is ainm di."
        duplicate["members"][0]["states"]["audio_qa"] = {
            "status": "not_generated",
            "record": None,
            "batch_line_id": None,
        }
        duplicate["members"][0]["exercise_consumers"] = [
            copy.deepcopy(self.families["mayo.grainne-1593.farraige.sea-noun"]["members"][1]["exercise_consumers"][0])
        ]
        duplicate["members"][0]["exercise_consumers"][0]["record_id"] = "mayo.farraige-family.build-sea-here"
        draft = copy.deepcopy(first["members"][0])
        draft["id"] = "ainm.future-draft"
        draft["family_id"] = first["id"]
        draft["states"]["authoring"]["status"] = "draft"
        draft["irish"] = None
        draft["english"] = None
        draft["exercise_consumers"] = []
        draft["target"]["target_form"] = None
        draft["states"]["capture_request"] = {
            "status": "not_requested",
            "requested_by": None,
            "requested_at": None,
            "authorization": None,
            "batch_line_ids": [],
        }
        first["members"].append(draft)
        test_contract = copy.deepcopy(self.loaded)
        test_contract.batches = []
        plan = contract.prepare_harvest(
            test_contract,
            [
                (REPO_ROOT / "first.v2.json", first),
                (REPO_ROOT / "duplicate.v2.json", duplicate),
            ],
            root=REPO_ROOT,
            created_at="2026-08-02T00:00:00Z",
        )
        self.assertEqual(plan["errors"], [])
        self.assertEqual(len(plan["duplicate_findings"]), 1)
        self.assertEqual(
            plan["duplicate_findings"][0]["action"], "merge_one_manifest_line"
        )
        self.assertEqual(len(plan["batches"]), 1)
        batch = plan["batches"][0]
        self.assertFalse(batch["execution"]["provider_calls_allowed"])
        self.assertEqual(batch["execution"]["state"], "draft")
        self.assertEqual(batch["lines"][0]["member_ids"], ["ainm.grainne-named", "farraige.sea-here"])
        self.assertEqual(
            plan["blocked_members"],
            [{"member_id": "ainm.future-draft", "reason": "authoring_incomplete_or_missing_canonical_irish"}],
        )

    def test_harvest_batch_ids_partition_county_story_and_sense(self):
        family = copy.deepcopy(self.families["mayo.grainne-1593.farraige.sea-noun"])
        family["members"] = [family["members"][0]]
        test_contract = copy.deepcopy(self.loaded)
        test_contract.batches = []
        plan = contract.prepare_harvest(
            test_contract,
            [(REPO_ROOT / "farraige.v2.json", family)],
            root=REPO_ROOT,
            created_at="2026-08-02T00:00:00Z",
        )
        self.assertEqual(
            [batch["batch_id"] for batch in plan["batches"]],
            ["d32.harvest.mayo.mayo-grainne-1593.farraige-sea-noun"],
        )
        self.assertTrue(
            plan["batches"][0]["purpose"].startswith("D32 emergency harvest — mayo /")
        )

    def test_harvest_writer_emits_only_draft_manifests_without_registration(self):
        test_contract = copy.deepcopy(self.loaded)
        test_contract.batches = []
        family = copy.deepcopy(self.families["mayo.grainne-1593.farraige.sea-noun"])
        plan = contract.prepare_harvest(
            test_contract,
            [(REPO_ROOT / "farraige.v2.json", family)],
            root=REPO_ROOT,
            created_at="2026-08-02T00:00:00Z",
        )
        with tempfile.TemporaryDirectory(dir=REPO_ROOT) as temporary:
            output_dir = Path(temporary).relative_to(REPO_ROOT)
            written = contract.write_harvest_outputs(
                plan,
                root=REPO_ROOT,
                output_dir=str(output_dir),
            )
            self.assertEqual(len(written), 1)
            manifest = json.loads((REPO_ROOT / written[0]).read_text(encoding="utf-8"))
            self.assertEqual(manifest["execution"]["state"], "draft")
            self.assertFalse(manifest["execution"]["provider_calls_allowed"])

    def test_batch_capture_disposition_is_required_and_locked(self):
        batch = copy.deepcopy(self.loaded.batches[0])
        batch["lines"][0].pop("capture_disposition")
        errors: list[str] = []
        contract.validate_batch(batch, self.loaded, REPO_ROOT, errors)
        self.assertTrue(any("capture_disposition" in error for error in errors))

    def test_voice_and_model_are_locked_in_every_batch(self):
        with self.assertRaisesRegex(ValueError, "user-locked"):
            contract.build_batch(
                self.loaded,
                batch_id="test.bad-voice",
                member_ids=["ainm.grainne-named"],
                voice_profile_id="voice.some-alternative",
                created_at="2026-08-01T00:00:00Z",
                purpose="Voice-lock test",
            )

        batch = copy.deepcopy(self.loaded.batches[0])
        batch["voice_profile"]["model_id"] = "eleven_multilingual_v2"
        errors: list[str] = []
        contract.validate_batch(batch, self.loaded, REPO_ROOT, errors)
        self.assertTrue(any("voice profile snapshot" in error for error in errors))

    def test_voice_profile_document_cannot_redefine_the_user_lock(self):
        payload = json.loads(contract.VOICE_PROFILES_PATH.read_text(encoding="utf-8"))
        payload["profiles"][0]["voice_settings"]["overrides"] = {"stability": 0.5}
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            path = root / contract.VOICE_PROFILES_PATH.relative_to(REPO_ROOT)
            path.parent.mkdir(parents=True)
            path.write_text(json.dumps(payload), encoding="utf-8")
            errors: list[str] = []
            contract.load_voice_profiles(root, errors)
        self.assertTrue(any("exact user-locked" in error for error in errors))

    def test_distinct_texts_cannot_share_an_inventory_slug(self):
        payload = {
            "entries": [
                {"text": "A-b", "slug": "a-b", "qa_state": "pending_generation"},
                {"text": "A b", "slug": "a-b", "qa_state": "pending_generation"},
            ]
        }
        errors: list[str] = []
        contract.inventory_index(payload, REPO_ROOT, errors)
        self.assertTrue(any("collides" in error for error in errors))

    def test_batch_outer_identity_counts_slug_and_order_are_enforced(self):
        batch = copy.deepcopy(self.loaded.batches[0])
        batch["counts"]["lines"] = 99
        batch["lines"][0]["inventory_slug"] = "wrong"
        batch["lines"][0]["line_id"] = "arbitrary"
        errors: list[str] = []
        contract.validate_batch(batch, self.loaded, REPO_ROOT, errors)
        self.assertTrue(any("stored counts" in error for error in errors))
        self.assertTrue(any("inventory_slug mismatch" in error for error in errors))
        self.assertTrue(any("deterministic line_id mismatch" in error for error in errors))
        self.assertTrue(any("manifest identity checksum mismatch" in error for error in errors))

    def test_approved_batch_requires_explicit_member_capture_request(self):
        loaded = copy.deepcopy(self.loaded)
        batch = copy.deepcopy(loaded.batches[0])
        batch["execution"] = {
            "state": "approved",
            "provider_calls_allowed": True,
            "approved_by": "owner.synthetic",
            "approved_at": "2026-08-01T11:00:00Z",
        }
        batch["lines"][0]["request"] = {
            "status": "approved",
            "approved_by": "owner.synthetic",
            "approved_at": "2026-08-01T11:00:00Z",
        }
        for member_id in batch["lines"][0]["member_ids"]:
            loaded.members[member_id]["states"]["capture_request"] = {
                "status": "not_requested",
                "requested_by": None,
                "requested_at": None,
                "authorization": None,
                "batch_line_ids": [],
            }
        batch["counts"] = contract.expected_batch_counts(batch)
        errors: list[str] = []
        contract.validate_batch(batch, loaded, REPO_ROOT, errors)
        self.assertTrue(any("requires requested member capture" in error for error in errors))

    def test_succeeded_result_requires_real_checksum_and_retry_metadata(self):
        loaded = self.reviewed_invented_contract()
        batch = contract.build_batch(
            loaded,
            batch_id="test.existing-audio",
            member_ids=["farraige.sea-here"],
            voice_profile_id="voice.irish-cultural-guide.eleven-v3.v1",
            created_at="2026-08-01T00:00:00Z",
            purpose="Existing-audio transition test",
        )
        line = batch["lines"][0]
        batch["execution"] = {
            "state": "approved",
            "provider_calls_allowed": True,
            "approved_by": "owner.synthetic",
            "approved_at": "2026-08-01T11:00:00Z",
        }
        line["request"] = {
            "status": "approved",
            "approved_by": "owner.synthetic",
            "approved_at": "2026-08-01T11:00:00Z",
        }
        loaded.members["farraige.sea-here"]["states"]["capture_request"][
            "batch_line_ids"
        ] = [line["line_id"]]
        line["provider_result"] = {
            "status": "succeeded",
            "provider_request_id": "provider.synthetic",
            "started_at": "2026-08-01T12:00:00Z",
            "completed_at": "2026-08-01T12:00:01Z",
            "reported_credits": 22.0,
            "reported_characters": 22,
        }
        line["claim"] = {
            "status": "completed",
            "owner_id": "worker.synthetic",
            "claimed_at": "2026-08-01T11:30:00Z",
            "lease_expires_at": "2026-08-01T12:30:00Z",
        }
        line["retry"]["attempt_count"] = 1
        path = REPO_ROOT / line["audio"]["output_path"]
        line["audio"]["sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
        line["audio"]["bytes"] = path.stat().st_size
        line["audio"]["duration_seconds"] = 1.0
        line["audio_qa"] = {"status": "pending", "record": None}
        batch["counts"] = contract.expected_batch_counts(batch)
        errors: list[str] = []
        contract.validate_batch(batch, loaded, REPO_ROOT, errors)
        self.assertEqual(errors, [])

        line["audio"]["sha256"] = "0" * 64
        errors = []
        contract.validate_batch(batch, loaded, REPO_ROOT, errors)
        self.assertTrue(any("audio checksum mismatch" in error for error in errors))

    def test_failed_result_requires_structured_retryable_error(self):
        loaded = self.reviewed_invented_contract()
        batch = contract.build_batch(
            loaded,
            batch_id="test.failed-audio",
            member_ids=["farraige.sea-here"],
            voice_profile_id="voice.irish-cultural-guide.eleven-v3.v1",
            created_at="2026-08-01T00:00:00Z",
            purpose="Failure transition test",
        )
        line = batch["lines"][0]
        batch["execution"] = {
            "state": "approved",
            "provider_calls_allowed": True,
            "approved_by": "owner.synthetic",
            "approved_at": "2026-08-01T11:00:00Z",
        }
        line["request"] = {
            "status": "approved",
            "approved_by": "owner.synthetic",
            "approved_at": "2026-08-01T11:00:00Z",
        }
        loaded.members["farraige.sea-here"]["states"]["capture_request"][
            "batch_line_ids"
        ] = [line["line_id"]]
        line["provider_result"]["status"] = "failed"
        line["retry"]["attempt_count"] = 1
        batch["counts"] = contract.expected_batch_counts(batch)
        errors: list[str] = []
        contract.validate_batch(batch, loaded, REPO_ROOT, errors)
        self.assertTrue(any("explicit claim owner" in error for error in errors))

        line["claim"] = {
            "status": "claimed",
            "owner_id": "worker.synthetic",
            "claimed_at": "2026-08-01T11:30:00Z",
            "lease_expires_at": "2026-08-01T12:30:00Z",
        }
        batch["counts"] = contract.expected_batch_counts(batch)
        errors = []
        contract.validate_batch(batch, loaded, REPO_ROOT, errors)
        self.assertTrue(any("structured error metadata" in error for error in errors))

        line["error"] = {
            "code": "timeout",
            "message": "Synthetic failure",
            "retriable": True,
            "occurred_at": "2026-08-01T12:00:00Z",
        }
        errors = []
        contract.validate_batch(batch, loaded, REPO_ROOT, errors)
        self.assertEqual(errors, [])

    def test_legacy_queue_fixture_is_retired_and_never_generation_ready(self):
        fixture = json.loads(
            (
                REPO_ROOT
                / "content/audio/authoring/migration/structured-authoring-v1-fixture.json"
            ).read_text(encoding="utf-8")
        )
        self.assertEqual(fixture["status"], "retired_migration_input_only")
        self.assertFalse(fixture["generation_allowed"])
        self.assertEqual(len(fixture["records"]), 16)
        self.assertEqual(
            sum(
                1
                for record in fixture["records"]
                if record["corrected_origin"] == "invented_pedagogical"
            ),
            10,
        )

    def test_schema_documents_are_valid_json_and_explicit_contracts(self):
        for schema_path in (
            REPO_ROOT
            / "content/audio/authoring/schemas/phrase-family-v2.schema.json",
            REPO_ROOT
            / "content/audio/authoring/schemas/generation-batch-v1.schema.json",
        ):
            payload = json.loads(schema_path.read_text(encoding="utf-8"))
            self.assertEqual(
                payload["$schema"], "https://json-schema.org/draft/2020-12/schema"
            )
            self.assertTrue(payload["required"])
            definitions = payload.get("$defs", {})
            for value in contract.walk_objects(payload):
                reference = value.get("$ref")
                if isinstance(reference, str) and reference.startswith("#/$defs/"):
                    self.assertIn(reference.removeprefix("#/$defs/"), definitions)


if __name__ == "__main__":
    unittest.main()
