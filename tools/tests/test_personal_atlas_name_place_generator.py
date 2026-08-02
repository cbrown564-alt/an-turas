"""Focused checks for the appendable story-slate Personal Atlas tranche."""

from __future__ import annotations

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
        self.assertEqual(len(generator.STORY_SLATE_SUBJECTS), 9)
        ids = [subject["id"] for subject in generator.STORY_SLATE_SUBJECTS]
        self.assertEqual(len(ids), len(set(ids)))

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
        self.assertEqual(len(historical), 5)
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
            self.assertEqual(len(places), 4)
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
