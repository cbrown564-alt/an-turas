"""Focused checks for the appendable story-slate Personal Atlas tranche."""

from __future__ import annotations

import json
import sqlite3
import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools"))

import generate_personal_atlas_name_place_families as generator  # noqa: E402


class PersonalAtlasNamePlaceGeneratorTests(unittest.TestCase):
    def test_story_slate_subjects_have_stable_source_and_family_routes(self):
        indexed = generator.family_index()
        ids = [subject["id"] for subject in generator.STORY_SLATE_SUBJECTS]
        self.assertGreaterEqual(len(generator.STORY_SLATE_SUBJECTS), 40)
        self.assertEqual(len(ids), len(set(ids)))

        atlas_ids = {
            subject["id"]
            for subject in json.loads(generator.SUBJECTS_PATH.read_text(encoding="utf-8"))[
                "subjects"
            ]
        }
        overlap = set(ids) & atlas_ids
        self.assertEqual(overlap, set(), f"story-slate ids collide with A1 subjects: {overlap}")

        for subject in generator.STORY_SLATE_SUBJECTS:
            self.assertIn("authoring_source", subject)
            source = subject["authoring_source"]
            self.assertEqual(
                source["path"], "content/audio/authoring/d32-county-harvest-uses.json"
            )
            self.assertEqual(source["supports"], "pattern_only")
            family = generator.subject_family(indexed, subject)
            self.assertIsNotNone(family, subject["id"])
            self.assertEqual(family["county"], generator.expected_county(subject))

    def test_historical_names_are_bounded_observer_material(self):
        historical = [
            subject
            for subject in generator.STORY_SLATE_SUBJECTS
            if subject.get("authoring_kind") == "historical_name"
        ]
        self.assertGreaterEqual(len(historical), 20)
        self.assertTrue(all(subject["kind"] == "name" for subject in historical))
        self.assertTrue(all(subject["canonicalDisplay"] for subject in historical))
        self.assertTrue(
            all(subject["authoring_source"]["supports"] == "pattern_only" for subject in historical)
        )

    def test_place_forms_resolve_to_the_expected_logainm_county(self):
        connection = sqlite3.connect(generator.FOUNDATION_PATH)
        try:
            places = [
                subject
                for subject in generator.STORY_SLATE_SUBJECTS
                if subject["kind"] == "place"
            ]
            self.assertGreaterEqual(len(places), 15)
            for subject in places:
                match = generator.logainm_match(subject, connection)
                self.assertIsNotNone(match, subject["id"])
                self.assertIn(
                    generator.expected_county(subject).casefold(),
                    match["hierarchy"].casefold(),
                )
        finally:
            connection.close()


if __name__ == "__main__":
    unittest.main()
