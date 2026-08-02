"""Tests for the offline gates around structured Irish audio execution."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools"))

import structured_audio_authoring as authoring  # noqa: E402
import structured_audio_generation as generation  # noqa: E402


class StructuredAudioGenerationTests(unittest.TestCase):
    def test_usage_snapshot_requires_numeric_account_values(self):
        snapshot = generation.usage_snapshot(
            {"character_count": 1_700, "character_limit": 236_000}
        )
        self.assertEqual(snapshot.used_credits, 1_700.0)
        self.assertEqual(snapshot.remaining_credits, 234_300.0)
        with self.assertRaises(generation.GateError):
            generation.usage_snapshot(
                {"character_count": "1700", "character_limit": 236_000}
            )

    def test_canonical_path_rejects_temp_and_legacy_destinations(self):
        with self.assertRaises(generation.GateError):
            generation.canonical_audio_path(
                REPO_ROOT,
                "tools/tts-bakeoff/irish-cultural-guide-words/farraige.mp3",
            )
        with self.assertRaises(generation.GateError):
            generation.canonical_audio_path(
                REPO_ROOT,
                "../irish-audio-run/ios/AnTuras/Resources/Audio/farraige.mp3",
            )
        self.assertEqual(
            generation.canonical_audio_path(
                REPO_ROOT,
                "ios/AnTuras/Resources/Audio/farraige.mp3",
            ),
            REPO_ROOT / "ios/AnTuras/Resources/Audio/farraige.mp3",
        )

    def test_batch_identity_matches_checked_in_contract(self):
        batch_path = REPO_ROOT / generation.DEFAULT_BATCH
        batch = json.loads(batch_path.read_text(encoding="utf-8"))
        self.assertEqual(
            generation.immutable_batch_identity(batch),
            authoring.batch_identity_sha256(batch),
        )

    def test_provider_costs_do_not_relabel_the_request_estimate(self):
        costs = generation.provider_reported_costs(
            {"estimated_credits": 42.0, "estimated_characters": 42}
        )
        self.assertEqual(costs, {"reported_credits": None, "reported_characters": None})

    def test_copy_without_overwrite_preserves_existing_bytes(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            staged = root / "staged.mp3"
            target = root / "target.mp3"
            staged.write_bytes(b"new")
            target.write_bytes(b"existing")
            with self.assertRaises(generation.GateError):
                generation.copy_without_overwrite(staged, target)
            self.assertEqual(target.read_bytes(), b"existing")


if __name__ == "__main__":
    unittest.main()
