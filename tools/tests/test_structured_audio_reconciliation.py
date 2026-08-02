"""Focused tests for the read-only Irish audio reconciliation and recovery plan."""

from __future__ import annotations

import copy
import hashlib
import json
import sys
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools"))

import structured_audio_authoring as authoring  # noqa: E402
import structured_audio_reconciliation as reconciliation  # noqa: E402


class StructuredAudioReconciliationTests(unittest.TestCase):
    def test_checked_in_state_has_separate_stage_counts_and_findings(self):
        report = reconciliation.reconcile(
            REPO_ROOT,
            as_of=datetime(2026, 8, 2, 12, 0, tzinfo=timezone.utc),
        )

        self.assertTrue(report["contract_check"]["valid"])
        self.assertGreaterEqual(report["stage_counts"]["authored"]["members"], 4)
        self.assertGreaterEqual(report["stage_counts"]["authorized"]["batch_line_records"], 1)
        self.assertGreaterEqual(report["stage_counts"]["captured"]["v2_provider_success_records"], 1)
        self.assertGreaterEqual(report["stage_counts"]["checksum_verified"]["runtime_manifest_records"], 362)
        self.assertEqual(report["stage_counts"]["bundled"]["inventory_entries"], 292)
        self.assertEqual(report["stage_counts"]["audio_qa_reviewed"]["inventory_entries"], 47)
        self.assertEqual(report["stage_counts"]["learner_release_eligible"]["members"], 0)
        scoreboard = report["scoreboard"]
        self.assertIn("mayo", scoreboard["authored"]["counties"])
        self.assertGreaterEqual(scoreboard["registered_lines"]["registered"], 5)
        self.assertGreaterEqual(scoreboard["registered_lines"]["approved"], 1)
        self.assertEqual(scoreboard["registered_lines"]["claimed"], 0)
        self.assertGreaterEqual(scoreboard["registered_lines"]["succeeded"], 1)
        self.assertEqual(scoreboard["registered_lines"]["failed"], 0)
        self.assertGreaterEqual(scoreboard["bundled_clips"]["new_v2"], 1)
        self.assertEqual(scoreboard["bundled_clips"]["legacy"], 362)
        self.assertEqual(
            scoreboard["checksum_state"]["verified"],
            scoreboard["checksum_state"]["bundle_manifest_records"],
        )
        self.assertEqual(scoreboard["remaining_resumable_work"]["preflight_candidates"], 0)
        self.assertEqual(report["asset_checks"]["missing_bundle_files"], [])
        self.assertEqual(report["asset_checks"]["orphan_bundle_files"], [])
        self.assertEqual(report["asset_checks"]["bundle_checksum_mismatches"], [])
        codes = {item["code"] for item in report["findings"]}
        self.assertIn("duplicate_batch_normalized_text_voice", codes)
        self.assertIn("bundle_lines_outside_inventory", codes)
        self.assertIn("inventory_bundle_qa_drift", codes)

    def test_bundle_scan_detects_missing_orphan_and_checksum_drift(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            bundle_dir = root / reconciliation.BUNDLE_RELATIVE
            bundle_dir.mkdir(parents=True)
            (bundle_dir / "good.mp3").write_bytes(b"good")
            (bundle_dir / "orphan.mp3").write_bytes(b"orphan")
            manifest = {
                "schema_version": 2,
                "provider": "ElevenLabs",
                "voice": {"name": "Irish Cultural Guide", "id": "NPWroowF4phQhaPWjXPj"},
                "model_id": "eleven_v3",
                "language_code": "ga",
                "output_format": "mp3_44100_192",
                "lines": [
                    {
                        "slug": "good",
                        "text": "maith",
                        "file": "good.mp3",
                        "sha256": "0" * 64,
                        "bytes": 99,
                        "qa_state": "generated_unreviewed",
                    },
                    {
                        "slug": "missing",
                        "text": "nua",
                        "file": "missing.mp3",
                        "sha256": "1" * 64,
                        "bytes": 1,
                        "qa_state": "generated_unreviewed",
                    },
                ],
            }
            (bundle_dir / "manifest.json").write_text(
                json.dumps(manifest), encoding="utf-8"
            )

            report = reconciliation.scan_runtime_bundle(root)

        self.assertEqual(report["missing_files"], ["missing"])
        self.assertEqual(report["orphan_files"], ["orphan.mp3"])
        self.assertEqual(report["checksum_mismatches"], ["good"])
        codes = {item["code"] for item in report["findings"]}
        self.assertIn("missing_bundle_file", codes)
        self.assertIn("orphan_bundle_file", codes)
        self.assertIn("bundle_checksum_mismatch", codes)
        self.assertIn("bundle_byte_count_mismatch", codes)

    def test_bundle_classification_requires_a_structured_batch_source_for_new(self):
        bundle = {
            "rows": [
                {"slug": "new", "sources": ["structured_batch:batch.new"]},
                {"slug": "old", "sources": ["inventory:headword:mayo"]},
            ],
            "checksum_verified_rows": [],
            "by_slug": {},
        }
        classification, findings = reconciliation.classify_bundled_clips(
            bundle, ["batch.new"]
        )

        self.assertEqual(classification["new_v2_records"], 1)
        self.assertEqual(classification["legacy_records"], 1)
        self.assertEqual(findings, [])

    def test_extended_ledgers_report_ids_provenance_checksums_and_resume_work(self):
        report = reconciliation.reconcile(
            REPO_ROOT,
            as_of=datetime(2026, 8, 2, 12, 0, tzinfo=timezone.utc),
        )
        extended = report["scoreboard"]["extended_artifacts"]
        atlas = extended["atlas_names_places"]
        self.assertEqual(atlas["names"], 50)
        self.assertEqual(atlas["places"], 30)
        self.assertEqual(atlas["stable_ids"]["declared"], 80)
        self.assertEqual(atlas["stable_ids"]["missing"], 640)
        self.assertEqual(atlas["checksum_state"]["verified"], 0)
        self.assertEqual(atlas["checksum_state"]["missing_recorded_checksum"], 2)

        narration = extended["pedagogy_narration"]
        self.assertGreater(narration["narration_pages"], 0)
        self.assertEqual(narration["comparison"]["paired_pack_ids"], 4)
        self.assertGreater(narration["review_gates_open"], 0)

        references = extended["external_reference_comparison"]
        self.assertEqual(references["comparison"]["hierarchy_repair_records"], 4)
        self.assertEqual(references["comparison"]["open_countyless_records"], 229)
        self.assertEqual(references["comparison"]["open_multi_county_records"], 312)
        codes = {item["code"] for item in report["findings"]}
        self.assertIn("artifact_records_missing_stable_id", codes)
        self.assertIn("artifact_checksum_not_recorded", codes)
        self.assertIn("pedagogy_narration_runtime_drift", codes)

    def test_extended_artifact_scan_keeps_duplicate_ids_as_manual_error(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            path = root / "synthetic.json"
            payload = {"sha256": "0" * 64}
            path.write_text(json.dumps(payload), encoding="utf-8")
            summary, findings = reconciliation._summarize_extended_artifact(
                root,
                path,
                "synthetic_artifact",
                [
                    {"id": "same", "text": "Dia dhuit", "source": "source-a"},
                    {"id": "same", "text": "  Dia   dhuit ", "source": "source-b"},
                ],
                payload=payload,
            )

        self.assertEqual(summary["collision_state"]["duplicate_stable_ids"], {"same": 2})
        self.assertEqual(summary["collision_state"]["duplicate_normalized_texts"], {"Dia dhuit": 2})
        self.assertEqual(summary["checksum_state"]["mismatched"], True)
        codes = {item["code"] for item in findings}
        self.assertIn("artifact_duplicate_stable_id", codes)
        self.assertIn("artifact_duplicate_normalized_text", codes)
        self.assertIn("artifact_checksum_mismatch", codes)

    def test_provider_success_requires_durable_file_and_checksum(self):
        line = {
            "inventory_slug": "good",
            "audio": {
                "output_path": "ios/AnTuras/Resources/Audio/good.mp3",
                "sha256": "0" * 64,
                "bytes": 4,
                "duration_seconds": 1.0,
            },
            "request": {"status": "approved"},
            "claim": {"status": "completed"},
            "retry": {"attempt_count": 1},
            "provider_result": {
                "status": "succeeded",
                "provider_request_id": "provider.synthetic",
                "started_at": "2026-08-02T10:00:00Z",
                "completed_at": "2026-08-02T10:00:01Z",
                "reported_credits": 4.0,
                "reported_characters": 4,
            },
        }
        batch = {"execution": {"state": "approved"}}
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            target = root / line["audio"]["output_path"]
            target.parent.mkdir(parents=True)
            target.write_bytes(b"good")
            issues = reconciliation.provider_success_issues(root, batch, line)

        self.assertFalse(issues["valid"])
        self.assertTrue(issues["checksum_ok"] is False)
        self.assertIn("audio_checksum_mismatch", issues["issues"])

    def test_interrupted_attempt_and_expired_lease_are_findings(self):
        _, loaded = authoring.validate_contract()
        synthetic = copy.deepcopy(loaded)
        batch = copy.deepcopy(synthetic.batches[1])
        line = batch["lines"][2]
        line["provider_result"]["status"] = "in_progress"
        line["claim"] = {
            "status": "claimed",
            "owner_id": "worker.synthetic",
            "claimed_at": "2026-08-02T08:00:00Z",
            "lease_expires_at": "2026-08-02T08:01:00Z",
        }
        synthetic.batches = [batch]
        bundle = reconciliation.scan_runtime_bundle(REPO_ROOT)
        _, findings = reconciliation._batch_records(
            REPO_ROOT,
            synthetic,
            bundle,
            datetime(2026, 8, 2, 12, 0, tzinfo=timezone.utc),
        )
        codes = {item["code"] for item in findings}
        self.assertIn("interrupted_provider_attempt", codes)
        self.assertIn("stale_claim_lease", codes)

    def test_post_hoc_capture_chronology_is_reported_without_rewriting_timestamps(self):
        report = reconciliation.reconcile(root=REPO_ROOT, as_of=reconciliation.parse_timestamp("2026-08-02T20:00:00Z"))
        chronology = [
            finding
            for finding in report["findings"]
            if finding["code"] == "capture_chronology_unverified"
        ]
        self.assertGreaterEqual(len(chronology), 8)
        self.assertTrue(all(item["original_evidence_preserved"] is True for item in chronology))

    def test_resume_plan_is_explicitly_read_only(self):
        report = reconciliation.reconcile(
            REPO_ROOT,
            as_of=datetime(2026, 8, 2, 12, 0, tzinfo=timezone.utc),
        )
        plan = reconciliation.build_resume_plan(
            report, batch_id="mayo.d31.capture-prep.2026-08-02"
        )

        self.assertTrue(plan["read_only"])
        self.assertTrue(all(not item["automatic_mutations"] for item in plan["plans"]))
        stale = next(item for item in plan["plans"] if item["inventory_slug"] == "graainne-is-ainm-di")
        self.assertEqual(stale["disposition"], "do_not_resume")
        self.assertTrue(all("--json" in command for command in plan["commands"]))

    def test_reconciliation_does_not_change_checked_in_json(self):
        paths = [
            authoring.STORE_PATH,
            authoring.INVENTORY_PATH,
            REPO_ROOT / "ios/AnTuras/Resources/Audio/manifest.json",
            REPO_ROOT / "ios/AnTuras/Resources/personal-atlas-subjects.json",
            REPO_ROOT / "content/audio/atlas-headwords-v1.json",
            REPO_ROOT / "content/personal-atlas/logainm-audit.json",
            REPO_ROOT / "content/mayo/grainne-1593.pack.draft.json",
        ]
        before = {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in paths}
        reconciliation.reconcile(
            REPO_ROOT,
            as_of=datetime(2026, 8, 2, 12, 0, tzinfo=timezone.utc),
        )
        after = {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in paths}
        self.assertEqual(before, after)


if __name__ == "__main__":
    unittest.main()
