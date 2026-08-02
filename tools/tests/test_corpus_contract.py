import json
import sys
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools/tts-bakeoff"))

import corpus_contract as contract  # noqa: E402


class CorpusContractTests(unittest.TestCase):
    def test_real_pending_batch_is_blocked_without_mutating_source(self):
        report = contract.build_batch("mayo")
        self.assertEqual(report["batch_id"], "mayo-phrase-family-pending-v1")
        self.assertEqual(len(report["items"]), 7)
        self.assertEqual(report["contract_status"], "blocked")
        self.assertEqual(len(report["issues"]), 35)
        self.assertTrue(
            all(item["contract_status"] == "blocked" for item in report["items"])
        )
        self.assertTrue(
            all(item["capture_disposition"] == "generated_unreviewed" for item in report["items"])
        )

    def test_manifest_order_and_resumable_ids_are_deterministic(self):
        first = contract.build_batch("mayo")
        second = contract.build_batch("mayo")
        self.assertEqual(first, second)
        ids = [item["resumable_id"] for item in first["items"]]
        self.assertEqual(ids, sorted(ids))
        self.assertEqual(
            ids[0], "mayo/mayo.phrase-family.ait/ait.where-place"
        )

    def test_locked_provider_configuration_is_exact(self):
        report = contract.build_batch("mayo")
        self.assertEqual(report["provider"], "ElevenLabs")
        self.assertEqual(report["voice"], {"name": "Irish Cultural Guide", "id": "NPWroowF4phQhaPWjXPj"})
        self.assertEqual(report["model_id"], "eleven_v3")
        self.assertEqual(report["language_code"], "ga")
        self.assertEqual(report["approved_cap"], 25000)

    def test_valid_item_has_no_contract_issues(self):
        item = {
            "county": "mayo",
            "member": {
                "text": "Cá bhfuil an áit?",
                "provenance": {"kind": "invented", "refs": ["mayo.clew-bay.locate-place"]},
                "county": "mayo",
                "sense": "where the place is",
                "exercise": {"ids": ["mayo.learning.ait.where-place"]},
                "capture_disposition": "generated_unreviewed",
            },
            "item_id": "mayo/mayo.phrase-family.ait/ait.where-place",
            "text": "Cá bhfuil an áit?",
        }
        self.assertEqual(contract.validate_item(item), [])


if __name__ == "__main__":
    unittest.main()

