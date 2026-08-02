"""Fixtures for deterministic, non-linguistic audio anomaly detection."""

from __future__ import annotations

import hashlib
import json
import math
import struct
import sys
import tempfile
import wave
from unittest import mock
from pathlib import Path

import unittest


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

import audio_technical_anomalies as technical  # noqa: E402
import structured_audio_reconciliation as reconciliation  # noqa: E402


def write_wave(
    path: Path,
    duration: float,
    amplitude: float,
    *,
    constant: bool = False,
    clipped_samples: int = 0,
) -> None:
    rate = technical.SAMPLE_RATE_HZ
    count = int(rate * duration)
    frames = []
    for index in range(count):
        value = amplitude if constant else amplitude * math.sin(2 * math.pi * 220 * index / rate)
        if index < clipped_samples:
            value = 1.0
        frames.append(struct.pack("<h", max(-32768, min(32767, round(value * 32767)))))
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(rate)
        output.writeframes(b"".join(frames))


def entry(path: Path | None, slug: str, *, recorded_sha256: str | None = None) -> dict:
    return {
        "slug": slug,
        "file": f"{slug}.mp3",
        "path": path,
        "text": slug,
        "sources": [f"fixture:{slug}"],
        "recorded_sha256": recorded_sha256,
        "actual_sha256": hashlib.sha256(path.read_bytes()).hexdigest() if path else None,
    }


def typed_entry(
    path: Path,
    slug: str,
    *,
    kind: str,
    text: str,
) -> dict:
    result = entry(path, slug)
    result.update({"kind": kind, "text": text})
    return result


class AudioTechnicalAnomalyTests(unittest.TestCase):
    def test_representative_failures_are_quarantined_with_reasons(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixtures = {
                "normal-a": (1.0, 0.18, False),
                "normal-b": (1.0, 0.20, False),
                "normal-c": (1.0, 0.22, False),
                "normal-d": (1.0, 0.24, False),
                "low-level": (1.0, 0.002, False),
                "clipped": (1.0, 1.0, True),
                "silent": (1.0, 0.0, True),
                "short": (0.1, 0.2, False),
                "long": (16.0, 0.2, False),
            }
            rows = []
            for slug, (duration, amplitude, constant) in fixtures.items():
                path = root / f"{slug}.mp3"
                write_wave(path, duration, amplitude, constant=constant)
                rows.append(entry(path, slug))
            (root / "corrupt.mp3").write_bytes(b"not an audio file")
            rows.extend([
                entry(root / "corrupt.mp3", "corrupt"),
                entry(None, "missing"),
            ])

            first = technical.audit_inventory(rows, source_manifest="fixture/manifest.json")
            second = technical.audit_inventory(rows, source_manifest="fixture/manifest.json")

        self.assertEqual(first, second)
        by_slug = {row["slug"]: row for row in first["rows"]}
        self.assertEqual(by_slug["missing"]["status"], "quarantine")
        self.assertEqual(by_slug["missing"]["reasons"], ["missing_file"])
        self.assertIn("decode_failed", by_slug["corrupt"]["reasons"])
        self.assertIn("silent_audio", by_slug["silent"]["reasons"])
        self.assertIn("clipped_audio", by_slug["clipped"]["reasons"])
        self.assertIn("duration_below_minimum", by_slug["short"]["reasons"])
        self.assertIn("duration_above_maximum", by_slug["long"]["reasons"])
        self.assertEqual(by_slug["low-level"]["status"], "review")
        self.assertIn("level_outlier_low", by_slug["low-level"]["reasons"])
        self.assertEqual(first["summary"]["quarantined"], 6)
        self.assertEqual(first["summary"]["review_required"], 1)
        self.assertEqual(first["rows"][0]["provenance"]["source_manifest"], "fixture/manifest.json")
        self.assertTrue(first["read_only"])

    def test_short_full_scale_transient_is_quarantined(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "transient.mp3"
            write_wave(path, 2.0, 0.2, clipped_samples=16)
            report = technical.audit_inventory(
                [entry(path, "transient")],
                source_manifest="fixture/manifest.json",
            )

        row = report["rows"][0]
        self.assertEqual(row["status"], "quarantine")
        self.assertIn("clipped_audio", row["reasons"])
        self.assertEqual(row["measurements"]["clipped_sample_count"], 16)
        self.assertEqual(report["thresholds"]["clip_minimum_samples"], 16)
        self.assertEqual(
            report["thresholds"]["clip_rule"],
            "clipped_sample_count >= clip_minimum_samples AND clipped_fraction >= clip_fraction",
        )

    def test_outlier_baselines_stratify_kind_and_text_length(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            rows = []
            for index in range(8):
                path = root / f"headword-{index}.mp3"
                write_wave(path, 1.0, 0.2)
                rows.append(
                    typed_entry(path, f"headword-{index}", kind="headword", text="ainm")
                )
            for index in range(8):
                path = root / f"sentence-{index}.mp3"
                write_wave(path, 3.44, 0.2)
                rows.append(
                    typed_entry(
                        path,
                        f"sentence-{index}",
                        kind="phrase",
                        text="Is ainm stairiúil é Gráinne Ní Mháille.",
                    )
                )

            report = technical.audit_inventory(rows, source_manifest="fixture/manifest.json")

        by_slug = {row["slug"]: row for row in report["rows"]}
        self.assertEqual(by_slug["headword-0"]["status"], "pass")
        self.assertEqual(by_slug["sentence-0"]["status"], "pass")
        self.assertEqual(
            by_slug["sentence-0"]["stratification"]["baseline_group"],
            "kind:phrase|length:long_phrase",
        )
        self.assertEqual(
            report["population"]["stratification"]["fields"],
            ["kind", "text_length_bucket"],
        )

    def test_sparse_stratum_omits_statistical_review_but_keeps_absolute_checks(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            rows = []
            for index in range(7):
                path = root / f"sparse-{index}.mp3"
                write_wave(path, 1.0, 0.2 if index else 0.002)
                rows.append(
                    typed_entry(path, f"sparse-{index}", kind="conversation", text="Tá sé anseo.")
                )
            report = technical.audit_inventory(rows, source_manifest="fixture/manifest.json")

        by_slug = {row["slug"]: row for row in report["rows"]}
        self.assertEqual(by_slug["sparse-0"]["status"], "pass")
        self.assertEqual(
            by_slug["sparse-0"]["stratification"]["fallback"],
            "sparse_group_no_statistical_review",
        )

    def test_decode_batches_are_bounded_and_cached_on_repeat(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            rows = []
            for index in range(3):
                path = root / f"batch-{index}.mp3"
                write_wave(path, 0.5, 0.2)
                rows.append(entry(path, f"batch-{index}"))

            technical._MEASUREMENT_CACHE.clear()
            with mock.patch.object(
                technical,
                "_decode_batch",
                wraps=technical._decode_batch,
            ) as decode_batch:
                first = technical.audit_inventory(rows, source_manifest="fixture/manifest.json")
                second = technical.audit_inventory(rows, source_manifest="fixture/manifest.json")

        self.assertEqual(first, second)
        self.assertEqual(decode_batch.call_count, 1)
        self.assertEqual(len(decode_batch.call_args.args[0]), 3)
        self.assertLessEqual(len(decode_batch.call_args.args[0]), technical.DECODE_BATCH_SIZE)

    def test_reconciliation_surfaces_technical_quarantine_without_mutation(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            bundle = root / reconciliation.BUNDLE_RELATIVE
            bundle.mkdir(parents=True)
            silent = bundle / "silent.mp3"
            write_wave(silent, 1.0, 0.0, constant=True)
            manifest = {
                "schema_version": 2,
                "provider": "ElevenLabs",
                "voice": {"name": "Irish Cultural Guide", "id": "NPWroowF4phQhaPWjXPj"},
                "model_id": "eleven_v3",
                "language_code": "ga",
                "output_format": "mp3_44100_192",
                "lines": [{
                    "slug": "silent",
                    "text": "ciúin",
                    "kind": "headword",
                    "file": "silent.mp3",
                    "sha256": hashlib.sha256(silent.read_bytes()).hexdigest(),
                    "bytes": silent.stat().st_size,
                    "qa_state": "generated_unreviewed",
                    "sources": ["fixture:technical"],
                }],
            }
            (bundle / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
            report = reconciliation.scan_runtime_bundle(root)

        self.assertEqual(report["technical_audio"]["summary"]["quarantined"], 1)
        finding = next(item for item in report["findings"] if item["code"] == "audio_technical_quarantine")
        self.assertEqual(finding["disposition"], "quarantine")
        self.assertEqual(finding["reasons"], ["silent_audio"])
        self.assertEqual(finding["provenance"]["manifest_slug"], "silent")
        technical_row = next(
            row for row in report["technical_audio"]["rows"] if row["slug"] == "silent"
        )
        self.assertEqual(technical_row["stratification"]["kind"], "headword")
        self.assertTrue(report["technical_audio"]["read_only"])


if __name__ == "__main__":
    unittest.main()
