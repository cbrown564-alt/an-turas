import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "logainm_monthly_ingest", ROOT / "tools/logainm_monthly_ingest.py"
)
module = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(module)


class LogainmIngestTests(unittest.TestCase):
    def test_paginates_merges_and_removes_replaced_records(self):
        pages = {
            1: {"CurrentPage": 1, "TotalPages": 2, "Results": [{"ID": 2, "Placenames": []}]},
            2: {"CurrentPage": 2, "TotalPages": 2, "Results": [{"ID": 1, "ReplacementID": 2}]},
        }
        requested = []

        def fetch(page, modified_since):
            requested.append((page, modified_since))
            return pages[page]

        existing = {"records": [{"ID": 1, "Placenames": [{"Wording": "Old"}]}]}
        result = module.update_snapshot(existing, "2026-06-01", fetch)
        self.assertEqual(requested, [(1, "2026-06-01"), (2, "2026-06-01")])
        self.assertEqual([item["ID"] for item in result["records"]], [2])
        self.assertEqual(result["licence"], "CC BY 4.0")

    def test_rejects_wrong_page_to_avoid_silent_partial_snapshot(self):
        with self.assertRaises(ValueError):
            module.update_snapshot(None, None, lambda page, since: {
                "CurrentPage": 2, "TotalPages": 2, "Results": []
            })


if __name__ == "__main__":
    unittest.main()
