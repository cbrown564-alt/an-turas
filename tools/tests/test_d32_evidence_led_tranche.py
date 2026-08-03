#!/usr/bin/env python3
"""Tests for queue-02 evidence-led (A5) authoring."""

from __future__ import annotations

import unittest

from tools.generate_d32_evidence_led_tranche import (
    QUEUE_02,
    build_source_register,
    frames_for,
)
from tools.structured_audio_authoring import normalize_spoken_text


class EvidenceLedTrancheTests(unittest.TestCase):
    def test_source_register_covers_all_eight_counties(self) -> None:
        register = build_source_register()
        counties = [item["county"] for item in register["counties"]]
        self.assertEqual(
            counties,
            [
                "cork",
                "galway",
                "kerry",
                "longford",
                "louth",
                "roscommon",
                "tipperary",
                "waterford",
            ],
        )
        for item in register["counties"]:
            self.assertTrue(item["anchor"])
            self.assertTrue(item["language_field"])
            self.assertTrue(item["exercise_demand"])
            self.assertFalse(item["blocked"])
            self.assertEqual(item["id"], f"register.{item['county']}")
            self.assertIn("slate", item["packet_status"])

    def test_frames_are_unique_and_in_yield_band(self) -> None:
        texts: set[str] = set()
        for meta in QUEUE_02:
            for position in range(1, 21):
                ga = f"focal{position}"
                gloss = f"sense{position}"
                for frame in frames_for(meta, ga, gloss, position):
                    normalized = normalize_spoken_text(frame["text"])
                    self.assertNotIn(normalized, texts)
                    texts.add(normalized)
        # 6 counties × 20 × 3 + 2 myth counties × 20 × 4 = 520
        self.assertEqual(len(texts), 520)
        self.assertGreaterEqual(len(texts), 200)
        self.assertLessEqual(len(texts), 600)

    def test_myth_counties_include_explicit_label_frames(self) -> None:
        for county in ("louth", "roscommon"):
            meta = next(item for item in QUEUE_02 if item["county"] == county)
            frames = frames_for(meta, "tarbh", "bull", 1)
            joined = " ".join(frame["text"].casefold() for frame in frames)
            self.assertIn("finscéal", joined)
            self.assertEqual(len(frames), 4)
            self.assertTrue(any(frame["suffix"] == "myth" for frame in frames))

    def test_non_myth_counties_have_three_frames(self) -> None:
        for meta in QUEUE_02:
            if meta["myth_labelled"]:
                continue
            frames = frames_for(meta, "ainm", "name", 20)
            self.assertEqual(len(frames), 3)
            self.assertEqual(
                [frame["suffix"] for frame in frames],
                ["evidence", "pattern", "notice"],
            )


if __name__ == "__main__":
    unittest.main()
