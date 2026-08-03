"""Tests for the mechanical D32 Track D Irish review audit."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools"))

import audit_irish_review_queue as audit  # noqa: E402


class IrishReviewAuditTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.result = audit.audit_sources(REPO_ROOT)
        cls.findings = cls.result["findings"]
        cls.finding_ids = {item["finding_id"] for item in cls.findings}

    def test_current_source_counts_are_explicit(self) -> None:
        self.assertEqual(self.result["summary"]["launch_rows"], 104)
        self.assertEqual(self.result["summary"]["legacy_members"], 79)
        self.assertEqual(self.result["summary"]["v2_members"], 1484)
        self.assertEqual(self.result["summary"]["inventory_spot_flagged"], 43)

    def test_missing_launch_inventory_is_a_hard_bind_rule_finding(self) -> None:
        for finding_id in (
            "launch.mayo.conversation.03.missing-inventory",
            "launch.dublin.conversation.14.missing-inventory",
        ):
            self.assertIn(finding_id, self.finding_ids)
            item = next(
                finding
                for finding in self.findings
                if finding["finding_id"] == finding_id
            )
            self.assertEqual(item["gate"], audit.CAPTURE_BLOCKED)

    def test_exact_text_translation_conflicts_are_flagged_without_rewriting(self) -> None:
        item = next(
            finding
            for finding in self.findings
            if finding["finding_id"] == "semantic-conflict.taa-muid-go-leeir"
        )
        self.assertEqual(item["priority"], "P0")
        self.assertIn("We are all", item["message"])
        self.assertIn("We are all here", item["message"])
        self.assertIn("do not silently rewrite", item["disposition"])
        self.assertEqual(item["gate"], audit.REVIEW_BEFORE_RELEASE)

        unsafe = next(
            finding
            for finding in self.findings
            if finding["finding_id"] == "semantic-conflict.caa-bhfuil-an-caisleaan"
        )
        self.assertEqual(unsafe["gate"], audit.CAPTURE_BLOCKED)

    def test_legacy_pending_generation_is_never_treated_as_capture_ready(self) -> None:
        item = next(
            finding
            for finding in self.findings
            if finding["finding_id"] == "legacy.pending-generation-inputs"
        )
        self.assertEqual(item["priority"], "P0")
        self.assertIn("complete v2", item["disposition"])
        self.assertEqual(item["gate"], audit.CAPTURE_BLOCKED)
        self.assertEqual(self.result["summary"]["legacy_pending_generation"], 7)

    def test_completed_capture_has_no_stale_operational_claim_watch(self) -> None:
        matching = [
            finding
            for finding in self.findings
            if finding["category"] == "batch_state"
            and finding["record_id"].startswith(
                "batch.mayo.d31.capture-prep.2026-08-02"
            )
        ]
        self.assertFalse(matching)
        self.assertEqual(self.result["summary"]["operational_watches"], 0)

    def test_gate_counts_keep_review_risks_out_of_capture_check(self) -> None:
        summary = self.result["summary"]
        self.assertEqual(
            summary["capture_blockers"]
            + summary["review_before_release"]
            + summary["operational_watches"],
            summary["findings"],
        )
        self.assertEqual(summary["hard_findings"], summary["capture_blockers"])
        self.assertGreater(summary["review_before_release"], summary["capture_blockers"])

    def test_schema_identity_mismatch_is_capture_blocked(self) -> None:
        findings = audit.identity_findings(
            finding_prefix="batch.example.line",
            record_id="batch.example.line",
            text="Tá ainm agam.",
            declared_normalized_text="Tá ainm agam.",
            declared_slug="wrong-slug",
            declared_sha256="0" * 64,
            source_label="generation-batch line",
            evidence=["fixture.json"],
        )
        self.assertEqual(
            {item.category for item in findings}, {"schema_identity"}
        )
        self.assertTrue(all(item.gate == audit.CAPTURE_BLOCKED for item in findings))
        self.assertEqual(len(findings), 2)

    def test_helpers_keep_identity_and_risk_checks_mechanical(self) -> None:
        self.assertEqual(
            audit.canonical_audio_slug("Cá bhfuil an fharraige?"),
            "caa-bhfuil-an-fharraige",
        )
        self.assertEqual(
            audit.normalize_text("  Tá\n an long sa bhá. "),
            "Tá an long sa bhá.",
        )
        flags = audit.text_risk_flags("Téigh go Londain agus iarr freagra.")
        self.assertIn("personal_or_place_name", flags)
        self.assertIn("long_or_coordinated_line", flags)
        self.assertIn("fada_or_diacritic", flags)

    def test_report_disclaims_linguistic_and_release_approval(self) -> None:
        report = audit.render_report(self.result)
        self.assertIn("does not judge pronunciation", report)
        self.assertIn("does not grant capture or", report)
        self.assertIn("learner release", report)


if __name__ == "__main__":
    unittest.main()
