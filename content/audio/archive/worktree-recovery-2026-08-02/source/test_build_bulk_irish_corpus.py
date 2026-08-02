#!/usr/bin/env python3
"""Generation-free tests for the Irish bulk capture planner."""

from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tools/tts-bakeoff/build_bulk_irish_corpus.py"
PRODUCTION = ROOT / "tools/tts-bakeoff/build-production-audio.py"


def load_module():
    spec = importlib.util.spec_from_file_location("bulk_corpus", SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load {SCRIPT}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


bulk = load_module()


class BulkIrishCorpusTests(unittest.TestCase):
    def test_normalization_preserves_spoken_text_but_collapses_layout(self):
        self.assertEqual(bulk.normalize_text("  Cá  bhfuil\nan  áit? "), "Cá bhfuil an áit?")
        self.assertEqual(bulk.slug("Cá bhfuil an áit?"), "caa-bhfuil-an-aait")

    def test_preview_collects_sources_and_authoring_slots_without_network(self):
        plan = bulk.build_plan(batch_size=100)
        counts = plan["counts"]
        self.assertEqual(counts["runtime_catalog_lines"], 362)
        self.assertEqual(counts["phrase_family_observations"], 79)
        self.assertEqual(counts["authored_expansion_slots"], 764)
        self.assertLessEqual(counts["pending_capture_requests"], 20)
        self.assertGreaterEqual(counts["slug_collisions"], 1)
        self.assertEqual(plan["campaign"]["safe_default"], "dry_run_no_network")
        self.assertTrue(all(row["provenance"] for row in plan["entries"]))
        self.assertTrue(all(slot["text"] is None for slot in plan["authoring_slots"]))
        self.assertEqual(
            Counter(slot["status"] for slot in plan["authoring_slots"]),
            Counter({"partially_covered": 80, "needs_authored_text": 684}),
        )

    def test_batches_are_stable_and_cover_each_pending_request_once(self):
        plan = bulk.build_plan(batch_size=7)
        rows = plan["entries"][:20]
        batches = [
            rows[offset : offset + 7] for offset in range(0, len(rows), 7)
        ]
        slugs = [row["slug"] for batch in batches for row in batch]
        self.assertEqual(len(batches), 3)
        self.assertEqual(set(slugs), {row["slug"] for row in rows})
        self.assertEqual(len(slugs), len(set(slugs)))

    def test_exported_batch_is_accepted_by_existing_builder_in_dry_run(self):
        with tempfile.TemporaryDirectory() as directory:
            run_dir = Path(directory) / "run"
            plan = bulk.build_plan(batch_size=100)
            synthetic = {
                "schema_version": 1,
                "generated_at": plan["generated_at"],
                "campaign": plan["campaign"],
                "bind_rule": plan["campaign"]["bind_rule"],
                "voice": plan["campaign"]["voice"],
                "counts": {"total": 1, "phrase": 1, "pending_generation": 1},
                "entries": [
                    {
                        "text": "Focal tástála",
                        "slug": "focal-taastaa-la",
                        "kind": "phrase",
                        "counties": ["mayo"],
                        "gloss": "test word",
                        "source": "test",
                        "qa_state": "capture_unreviewed",
                        "capture_state": "pending_capture",
                        "provenance": [{"path": "test"}],
                    }
                ],
            }
            batch = run_dir / "batches/batch-001.inventory.json"
            batch.parent.mkdir(parents=True)
            batch.write_text(json.dumps(synthetic, ensure_ascii=False))
            result = subprocess.run(
                [
                    sys.executable,
                    str(PRODUCTION),
                    "--dry-run",
                    "--from-inventory",
                    "--inventory-path",
                    str(batch),
                    "--missing-only",
                ],
                cwd=ROOT,
                check=True,
                capture_output=True,
                text=True,
            )
            self.assertIn("Catalog: 1 static clips", result.stdout)
            self.assertIn("missing [phrase]", result.stdout)
            self.assertNotIn("ELEVENLABS_API_KEY", result.stderr)

    def test_collision_report_keeps_both_text_variants_out_of_silent_deduplication(self):
        plan = bulk.build_plan()
        collision = plan["slug_collisions"].get("freagair")
        self.assertIsNotNone(collision)
        self.assertEqual(collision["texts"], ["Freagair.", "freagair"])
        self.assertTrue(collision["provenance"])


if __name__ == "__main__":
    unittest.main()
