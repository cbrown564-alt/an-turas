"""Tests for Bulk Track A avenue A2 story-dialogue role templates."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools"))

import generate_d32_county_families as gen  # noqa: E402


class StoryDialogueRoleTemplateTests(unittest.TestCase):
    def test_lean_templates_produce_distinct_frames(self):
        lean = [template for template in gen.STORY_DIALOGUE_ROLE_TEMPLATES if template["tier"] == "lean"]
        self.assertEqual(len(lean), 4)
        texts = {template["text"]("long", "ship", "Maigh Eo") for template in lean}
        self.assertEqual(len(texts), 4)
        self.assertIn("Cad é an long?", texts)
        self.assertIn("Éist leis an long.", texts)
        self.assertIn("Baineann an scéal leis an long.", texts)

    def test_dedupe_stories_keeps_stable_instance(self):
        stories = [
            {"id": "d32.mayo.grainne-1593", "county": "mayo", "title": "A"},
            {
                "id": "d32.mayo.grainne-1593",
                "county": "mayo",
                "title": "B",
                "record_instance_id": "d32.mayo.grainne-1593.primary",
            },
            {"id": "d32.cork.nano-nagle", "county": "cork", "title": "C"},
            {"id": "d32.cork.nano-nagle", "county": "cork", "title": "D"},
        ]
        deduped = gen.dedupe_stories(stories)
        self.assertEqual([item["id"] for item in deduped], ["d32.cork.nano-nagle", "d32.mayo.grainne-1593"])
        mayo = next(item for item in deduped if item["id"] == "d32.mayo.grainne-1593")
        self.assertEqual(mayo["record_instance_id"], "d32.mayo.grainne-1593.primary")

    def test_story_dialogue_tranche_is_idempotent_and_net_new(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            content = root / "content"
            mayo_dir = content / "mayo" / "phrase-families" / "authoring-v2"
            mayo_dir.mkdir(parents=True)
            authoring = content / "audio" / "authoring"
            authoring.mkdir(parents=True)

            atlas = {
                "schema_version": 1,
                "counties": {
                    "mayo": {
                        "display": "Maigh Eo / Mayo",
                        "words": [
                            {"ga": "bá", "en": "bay"},
                            {"ga": "long", "en": "ship"},
                        ],
                    }
                },
            }
            family = {
                "schema_version": 2,
                "contract": "irish_phrase_family",
                "id": "d32.mayo.02.ba.bay",
                "county": "mayo",
                "story_ref": {
                    "path": "content/audio/authoring/d32-county-harvest-uses.json",
                    "record_id": "d32.mayo.grainne-1593",
                },
                "target": {
                    "lexeme_id": "lex.ba",
                    "citation_form": "bá",
                    "sense_id": "mayo.ba.bay",
                    "part_of_speech": "noun",
                    "english_sense": "bay",
                },
                "atlas_placements": [{"id": "atlas.mayo.01.ba", "gloss": "bay"}],
                "status": "draft",
                "claims": {
                    "linguistic_approval": False,
                    "historical_authenticity": False,
                    "note": "fixture",
                },
                "members": [
                    {
                        "id": "d32.mayo.02.ba.bay.opening",
                        "family_id": "d32.mayo.02.ba.bay",
                        "irish": {
                            "text": "Tá bá anseo.",
                            "normalized_text": "Tá bá anseo.",
                        },
                    }
                ],
            }
            family_path = mayo_dir / "d32.mayo.02.ba.bay.v2.json"
            family_path.write_text(json.dumps(family, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            store = {
                "family_documents": [
                    {
                        "family_id": "d32.mayo.02.ba.bay",
                        "path": "content/mayo/phrase-families/authoring-v2/d32.mayo.02.ba.bay.v2.json",
                    }
                ]
            }
            uses = {
                "schema_version": 1,
                "contract": "d32_county_harvest_uses",
                "created_at": "2026-08-03T12:00:00Z",
                "status": "provisional_authoring_input_only",
                "stories": [
                    {
                        "id": "d32.mayo.grainne-1593",
                        "county": "mayo",
                        "title": "Gráinne Ní Mháille and the 1593 petition",
                        "anchor": "Gráinne Ní Mháille · Clew Bay and the 1593 petition",
                        "source_record": "docs/COUNTY-STORY-SLATE.md",
                        "status": "development-slate-input",
                        "place_label": "Maigh Eo / Mayo",
                    },
                    {
                        "id": "d32.mayo.grainne-1593",
                        "county": "mayo",
                        "title": "duplicate should collapse",
                        "anchor": "dup",
                        "source_record": "docs/COUNTY-STORY-SLATE.md",
                        "status": "development-slate-input",
                        "place_label": "Maigh Eo / Mayo",
                    },
                ],
                "exercises": [],
            }
            (content / "audio").mkdir(exist_ok=True)
            atlas_path = content / "audio" / "atlas-headwords-v1.json"
            atlas_path.write_text(json.dumps(atlas), encoding="utf-8")
            store_path = authoring / "phrase-family-store-v2.json"
            store_path.write_text(json.dumps(store), encoding="utf-8")
            uses_path = authoring / "d32-county-harvest-uses.json"
            uses_path.write_text(json.dumps(uses), encoding="utf-8")

            stories = {"mayo": gen.STORIES["mayo"]}
            with mock.patch.object(gen, "ROOT", root), mock.patch.object(
                gen, "ATLAS_PATH", atlas_path
            ), mock.patch.object(gen, "STORE_PATH", store_path), mock.patch.object(
                gen, "USES_PATH", uses_path
            ), mock.patch.object(gen, "STORIES", stories):
                first = gen.append_story_dialogue_tranche(
                    lean_words=1,
                    deepen_words=1,
                    deepen_counties=("mayo",),
                )
                second = gen.append_story_dialogue_tranche(
                    lean_words=1,
                    deepen_words=1,
                    deepen_counties=("mayo",),
                )

            self.assertGreaterEqual(first["new_unique_texts"], 6)
            self.assertEqual(second["new_unique_texts"], 0)
            self.assertEqual(second["new_members"], 0)

            updated_uses = json.loads(uses_path.read_text(encoding="utf-8"))
            self.assertEqual(len(updated_uses["stories"]), 1)
            updated_family = json.loads(family_path.read_text(encoding="utf-8"))
            roles = {
                role
                for item in updated_family["members"]
                for role in item.get("learning", {}).get("roles", [])
            }
            self.assertTrue({"dialogue_turn", "listening_contrast", "story_recap"} <= roles)
            texts = {item["irish"]["normalized_text"] for item in updated_family["members"]}
            self.assertIn("Seo scéal Maigh Eo: bá.", texts)
            self.assertIn("Tá bá anseo.", texts)
            self.assertIn("Cad é an bá?", texts)


if __name__ == "__main__":
    unittest.main()
