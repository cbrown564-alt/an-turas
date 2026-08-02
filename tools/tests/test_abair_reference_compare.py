from __future__ import annotations

import json
import sys
import tempfile
import unittest
import wave
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

import abair_reference_compare as compare  # noqa: E402


def write_tone(path: Path, frequency: int) -> None:
    rate = 16_000
    samples = (0.2 * np.sin(2 * np.pi * frequency * np.arange(rate) / rate) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(rate)
        output.writeframes(samples.tobytes())


class AbairReferenceComparisonTests(unittest.TestCase):
    def test_manifest_is_disabled_until_explicitly_enabled(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            audio = root / "reference.wav"
            write_tone(audio, 220)
            pairs = root / "pairs.json"
            pairs.write_text(json.dumps([{
                "pair_id": "demo",
                "text": "Farraige",
                "elevenlabs_path": str(audio),
                "abair_path": str(audio),
            }]), encoding="utf-8")
            manifest = root / "manifest.json"
            args = type("Args", (), {
                "pairs": str(pairs),
                "output": str(manifest),
                "permission_basis": "local educational evaluation",
                "use_scope": "internal_evaluation",
                "permission_reference": None,
            })()
            result = compare.ingest(args)
            self.assertFalse(result["comparison_enabled"])
            self.assertFalse(json.loads(manifest.read_text())["network_access"])
            with self.assertRaises(compare.ComparisonError):
                compare.validate_manifest(json.loads(manifest.read_text()), allow=False)

    def test_enabled_analysis_emits_measurements_not_a_score(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            audio = root / "reference.wav"
            write_tone(audio, 220)
            manifest = {
                "schema_version": 1,
                "contract": "offline_abair_reference_comparison",
                "comparison_enabled": True,
                "network_access": False,
                "terms": {
                    "terms_url": compare.TERMS_URL,
                    "permission_basis": "local educational evaluation",
                    "lawful_acquisition_attested": True,
                    "use_scope": "internal_evaluation",
                    "redistribution_allowed": False,
                    "local_only": True,
                    "permission_reference": None,
                },
                "pairs": [{
                    "pair_id": "demo",
                    "text": "Farraige",
                    "elevenlabs_path": str(audio),
                    "abair_path": str(audio),
                    "abair_source": "https://abair.ie/synthesis",
                    "acquired_at": "2026-08-02T00:00:00Z",
                    "abair_sha256": compare.sha256_file(audio),
                }],
            }
            path = root / "manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            args = type("Args", (), {
                "manifest": str(path),
                "enable_offline_comparison": True,
            })()
            report = compare.analyze(args)
            self.assertFalse(report["correctness_claim"])
            self.assertFalse(report["release_eligible"])
            self.assertIn("duration_seconds", report["results"][0]["elevenlabs"])
            self.assertIsNone(report["results"][0]["interpretation"]["pronunciation_score"])


if __name__ == "__main__":
    unittest.main()
