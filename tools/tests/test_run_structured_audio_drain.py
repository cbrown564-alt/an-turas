"""Tests for the continuous structured-audio drain worker."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools"))

import run_structured_audio_drain as drain_worker  # noqa: E402


class StructuredAudioDrainTests(unittest.TestCase):
    def test_validated_contract_is_reused_for_every_batch_preflight(self):
        contract = SimpleNamespace(store={"batch_documents": []})
        batches = [
            ("first.json", {"batch_id": "first", "execution": {"state": "approved", "provider_calls_allowed": True}}),
            ("second.json", {"batch_id": "second", "execution": {"state": "approved", "provider_calls_allowed": True}}),
        ]

        with (
            mock.patch.object(drain_worker.authoring, "validate_contract", return_value=([], contract)) as validate,
            mock.patch.object(drain_worker, "registered_batches", return_value=batches),
            mock.patch.object(
                drain_worker.generation,
                "preflight",
                side_effect=[
                    {"ok": True, "active_lines": []},
                    {"ok": True, "active_lines": []},
                ],
            ) as preflight,
        ):
            result = drain_worker.drain(REPO_ROOT, dry_run=True)

        validate.assert_called_once_with(root=REPO_ROOT)
        self.assertEqual(preflight.call_count, 2)
        for call in preflight.call_args_list:
            self.assertIs(call.kwargs["validated_contract"], contract)
            self.assertEqual(call.kwargs["contract_errors"], [])
        self.assertTrue(result["ok"])


if __name__ == "__main__":
    unittest.main()
