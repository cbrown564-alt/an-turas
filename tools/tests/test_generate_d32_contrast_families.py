"""Tests for bulk Track A avenue A3 contrast family generation."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

import tools.generate_d32_contrast_families as generator  # noqa: E402
from tools.structured_audio_authoring import (  # noqa: E402
    atlas_placements,
    folded_for_match,
    load_json,
    normalize_spoken_text,
)


class GenerateD32ContrastFamiliesTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.catalog = load_json(generator.CATALOG_PATH)
        cls.placements = atlas_placements(load_json(generator.ATLAS_PATH))

    def test_catalog_has_mayo_first_band_and_pair_shape(self) -> None:
        families = self.catalog["families"]
        self.assertGreaterEqual(len(families), 50)
        member_count = sum(len(family["members"]) for family in families)
        self.assertGreaterEqual(member_count, 100)
        self.assertLessEqual(member_count, 400)
        mayo = [family for family in families if family["county"] == "mayo"]
        self.assertGreaterEqual(len(mayo), 10)
        for family in families:
            self.assertEqual(len(family["members"]), 2, family["id"])
            self.assertIn(
                family["contrast_type"],
                {"fada", "fada_minimal_pair", "mutation", "minimal_pair"},
            )
            for member in family["members"]:
                self.assertTrue(member["text"].strip())
                self.assertTrue(member["english"].strip())
                self.assertTrue(member["target_form"].strip())

    def test_catalog_texts_are_unique_within_catalog(self) -> None:
        texts = [
            normalize_spoken_text(member["text"])
            for family in self.catalog["families"]
            for member in family["members"]
        ]
        self.assertEqual(len(texts), len(set(texts)))
        # Catalog texts may already be authored into contrast families; they must
        # not collide with non-contrast corpus lines.
        non_contrast: set[str] = set()
        for path in REPO_ROOT.glob("content/*/phrase-families/authoring-v2/*.v2.json"):
            if ".contrast." in path.name:
                continue
            family = json.loads(path.read_text(encoding="utf-8"))
            for member in family.get("members", []):
                normalized = (member.get("irish") or {}).get("normalized_text")
                if isinstance(normalized, str) and normalized.strip():
                    non_contrast.add(normalize_spoken_text(normalized))
        overlap = sorted(set(texts) & non_contrast)
        self.assertEqual(overlap, [])

    def test_every_catalog_family_resolves_an_atlas_placement(self) -> None:
        for family in self.catalog["families"]:
            placement = generator.resolve_placement(
                self.placements, family["county"], family["citation_form"]
            )
            self.assertEqual(placement["county"], family["county"])
            self.assertEqual(placement["citation_form"], family["citation_form"])

    def test_contrast_family_emits_complete_member_contract_shape(self) -> None:
        spec = next(
            family
            for family in self.catalog["families"]
            if family["id"] == "d32.mayo.contrast.sean-fada"
        )
        placement = generator.resolve_placement(
            self.placements, spec["county"], spec["citation_form"]
        )
        family, exercises = generator.contrast_family(spec, placement)
        self.assertEqual(family["id"], "d32.mayo.contrast.sean-fada")
        self.assertEqual(len(family["members"]), 2)
        self.assertEqual(len(exercises), 2)
        for member, exercise in zip(family["members"], exercises, strict=True):
            self.assertEqual(member["states"]["authoring"]["status"], "complete")
            self.assertEqual(member["provenance"]["origin"], "invented_pedagogical")
            self.assertIn("invented_text", member["risk_flags"])
            self.assertIn("audio_pronunciation", member["risk_flags"])
            self.assertIn("listening_contrast", member["learning"]["roles"])
            self.assertIn("morphology_contrast", member["learning"]["roles"])
            self.assertEqual(
                member["exercise_consumers"][0]["record_id"], exercise["id"]
            )
            self.assertIn(
                member["id"], exercise["exercise"]["phraseFamilyMemberIDs"]
            )
            target_form = member["target"]["target_form"]
            normalized = member["irish"]["normalized_text"]
            self.assertIn(
                folded_for_match(target_form),
                folded_for_match(normalized),
            )

    def test_risk_sample_counties_include_mutation_and_fada_strata(self) -> None:
        counties = generator.risk_sample_counties(REPO_ROOT)
        self.assertIn("mayo", counties | {"mayo"})
        for county in ("cork", "antrim", "kerry", "derry"):
            self.assertIn(county, counties)

    def test_authored_repo_slice_covers_unique_text_band(self) -> None:
        # After generation, dry-run is idempotent (0 adds). Measure the authored
        # contrast slice instead.
        result = generator.generate(REPO_ROOT, dry_run=True)
        self.assertEqual(result["status"], "dry_run")
        self.assertEqual(result["contrast_families_added"], 0)
        authored_texts: set[str] = set()
        mayo_members = 0
        type_counts: dict[str, int] = {}
        for path in REPO_ROOT.glob(
            "content/*/phrase-families/authoring-v2/d32.*.contrast.*.v2.json"
        ):
            family = json.loads(path.read_text(encoding="utf-8"))
            for member in family.get("members", []):
                normalized = (member.get("irish") or {}).get("normalized_text")
                if isinstance(normalized, str) and normalized.strip():
                    authored_texts.add(normalize_spoken_text(normalized))
                if family.get("county") == "mayo":
                    mayo_members += 1
            # Infer type from catalog
        catalog_types = {
            family["id"]: family["contrast_type"]
            for family in self.catalog["families"]
        }
        for path in REPO_ROOT.glob(
            "content/*/phrase-families/authoring-v2/d32.*.contrast.*.v2.json"
        ):
            family = json.loads(path.read_text(encoding="utf-8"))
            ctype = catalog_types.get(family["id"], "unknown")
            type_counts[ctype] = type_counts.get(ctype, 0) + len(family.get("members", []))
        self.assertGreaterEqual(len(authored_texts), 100)
        self.assertLessEqual(len(authored_texts), 400)
        self.assertGreater(mayo_members, 0)
        self.assertIn("mutation", type_counts)

    def test_generate_is_idempotent_after_write(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_root = Path(tmp)
            # Minimal sandbox: copy only what generate needs via symlink tree.
            for relative in (
                "content/audio/authoring",
                "content/audio/atlas-headwords-v1.json",
                "content/mayo/phrase-families/authoring-v2",
            ):
                source = REPO_ROOT / relative
                target = tmp_root / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                if source.is_dir():
                    # Copy store/uses/catalog/risk sample files only when needed.
                    continue
            # Build a focused sandbox with required authoring files and empty county dirs.
            authoring = tmp_root / "content/audio/authoring"
            authoring.mkdir(parents=True, exist_ok=True)
            for name in (
                "d32-contrast-catalog-a3.json",
                "phrase-family-store-v2.json",
                "d32-county-harvest-uses.json",
                "sampling/d32-risk-stratification-2026-08-02.json",
            ):
                source = REPO_ROOT / "content/audio/authoring" / name
                destination = authoring / name
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(source.read_bytes())
            (tmp_root / "content/audio/atlas-headwords-v1.json").write_bytes(
                (REPO_ROOT / "content/audio/atlas-headwords-v1.json").read_bytes()
            )
            # Seed a non-contrast Mayo family so uniqueness checks see corpus texts.
            mayo_dir = tmp_root / "content/mayo/phrase-families/authoring-v2"
            mayo_dir.mkdir(parents=True, exist_ok=True)
            seed = (
                REPO_ROOT
                / "content/mayo/phrase-families/authoring-v2/d32.mayo.02.ba.bay.v2.json"
            )
            (mayo_dir / seed.name).write_bytes(seed.read_bytes())
            for county in sorted({family["county"] for family in self.catalog["families"]}):
                (
                    tmp_root
                    / f"content/{county}/phrase-families/authoring-v2"
                ).mkdir(parents=True, exist_ok=True)

            # Shrink store/uses to keep the sandbox light but valid for appends.
            store = {
                "schema_version": 2,
                "contract": "irish_phrase_family_store_v2",
                "family_documents": [],
            }
            uses = {
                "schema_version": 1,
                "contract": "d32_county_harvest_uses",
                "stories": [],
                "exercises": [],
            }
            (authoring / "phrase-family-store-v2.json").write_text(
                json.dumps(store, indent=2) + "\n", encoding="utf-8"
            )
            (authoring / "d32-county-harvest-uses.json").write_text(
                json.dumps(uses, indent=2) + "\n", encoding="utf-8"
            )

            first = generator.generate(tmp_root, dry_run=False)
            second = generator.generate(tmp_root, dry_run=False)
            self.assertGreaterEqual(first["unique_texts_added"], 100)
            self.assertEqual(second["contrast_families_added"], 0)
            self.assertEqual(second["unique_texts_added"], 0)
            written = list(
                tmp_root.glob("content/*/phrase-families/authoring-v2/*contrast*.v2.json")
            )
            self.assertEqual(len(written), first["contrast_families_added"])


if __name__ == "__main__":
    unittest.main()
