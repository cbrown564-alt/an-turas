"""Tests for deterministic Irish audio risk stratification and sampling."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import sys

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools"))

import stratify_irish_audio as stratifier  # noqa: E402


def family(
    family_id: str,
    text: str,
    *,
    county: str = "mayo",
    roles: list[str] | None = None,
    risk_flags: list[str] | None = None,
    member_id: str | None = None,
) -> dict:
    member_id = member_id or f"{family_id}.opening"
    normalized = stratifier.normalize_text(text)
    return {
        "id": family_id,
        "county": county,
        "story_ref": {"record_id": f"{county}.story"},
        "target": {"sense_id": f"{county}.sense", "citation_form": "ainm"},
        "atlas_placements": [{"id": f"atlas.{county}.01"}],
        "members": [
            {
                "id": member_id,
                "irish": {
                    "text": text,
                    "normalized_text": normalized,
                    "inventory_slug": stratifier.audio_slug(normalized),
                    "text_sha256": stratifier.text_sha256(normalized),
                },
                "binding": {
                    "atlas_placement_ids": [f"atlas.{county}.01"],
                    "place": {"id": f"{county}.place", "label": county},
                },
                "learning": {"roles": roles or ["story_opening"]},
                "exercise_consumers": [
                    {"record_id": f"{family_id}.exercise"}
                ],
                "provenance": {"invented": False},
                "states": {
                    "authoring": {"status": "complete"},
                    "capture_request": {"status": "not_requested"},
                    "learner_release": {"status": "blocked"},
                },
                "risk_flags": risk_flags or [],
            }
        ],
    }


class StratifyTests(unittest.TestCase):
    def write_fixture(self, root: Path) -> None:
        family_dir = root / "content/mayo/phrase-families/authoring-v2"
        family_dir.mkdir(parents=True)
        rows = [
            family(
                "mayo.grainne",
                "Tá Gráinne ar an bhfarraige.",
                risk_flags=["initial_mutation", "fada"],
            ),
            family(
                "mayo.grainne.duplicate",
                "Tá Gráinne ar an bhfarraige.",
                member_id="duplicate.member",
                roles=["productive_pattern"],
            ),
            family(
                "mayo.plain",
                "Tá baile anseo.",
                county="dublin",
                roles=["story_recap"],
            ),
        ]
        for row in rows:
            path = family_dir / f"{row['id']}.v2.json"
            path.write_text(json.dumps(row, ensure_ascii=False), encoding="utf-8")
        launch = {
            "counties": {
                "mayo": {
                    "phrases": [{"text": "Tá Gráinne ar an bhfarraige."}],
                    "conversation": [],
                }
            }
        }
        launch_path = root / "content/audio/launch-phrases-conversations-v1.json"
        launch_path.parent.mkdir(parents=True, exist_ok=True)
        launch_path.write_text(json.dumps(launch), encoding="utf-8")

    def test_deduplicates_and_is_reproducible(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.write_fixture(root)
            first = stratifier.stratify(root, seed="fixture.seed", sample_quota=2)
            second = stratifier.stratify(root, seed="fixture.seed", sample_quota=2)
            self.assertEqual(first, second)
            self.assertEqual(first["summary"]["unique_text_voice_keys"], 2)
            self.assertEqual(first["summary"]["duplicate_keys"], 1)
            self.assertEqual(
                len({item["key"] for item in first["samples"]}),
                len(first["samples"]),
            )

    def test_risk_categories_cover_requested_review_dimensions(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.write_fixture(root)
            report = stratifier.stratify(root, seed="categories", sample_quota=5)
            item = next(
                row for row in report["risk_items"]
                if row["normalized_text"] == "Tá Gráinne ar an bhfarraige."
            )
            self.assertTrue(
                {
                    "names",
                    "places",
                    "mutations",
                    "fadas",
                    "phoneme_grapheme",
                    "story_lines",
                    "launch_lines",
                    "duplicates",
                }.issubset(item["categories"])
            )
            self.assertEqual(item["priority"], "P0")
            self.assertIn("digraph:bh", item["grapheme_features"])
            self.assertIn("fada:á", item["grapheme_features"])

    def test_manifest_keeps_review_planning_separate_from_release(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.write_fixture(root)
            report = stratifier.stratify(root, sample_quota=1)
            self.assertEqual(
                report["scope"],
                "mechanical review planning only; no capture or learner-release decision",
            )
            self.assertEqual(report["locked_voice"]["voice_id"], stratifier.LOCKED_VOICE_ID)
            self.assertIn("grapheme features are a mechanical coverage proxy", report["grapheme_coverage"]["interpretation"])
            self.assertTrue(all(item["priority"] in {"P0", "P1", "P2"} for item in report["samples"]))


if __name__ == "__main__":
    unittest.main()
