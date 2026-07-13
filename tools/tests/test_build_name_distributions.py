import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "build_name_distributions", ROOT / "tools/build_name_distributions.py"
)
module = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(module)


class NameDistributionTests(unittest.TestCase):
    def row(self, **changes):
        row = {
            "subject_id": "name.surname.obrien",
            "dataset": "Agreed aggregate fixture",
            "year": "1926",
            "geography": "County-level aggregate",
            "count": "120",
            "suppressed": "false",
            "source_url": "https://example.invalid/dataset",
            "rights_state": "cleared",
            "note": "Common in this record; not a family-origin claim.",
        }
        row.update(changes)
        return row

    def test_builds_only_aggregate_app_shape(self):
        result = module.build([self.row()])
        item = result["name.surname.obrien"][0]
        self.assertEqual(item["count"], 120)
        self.assertNotIn("person", item)
        self.assertNotIn("address", item)

    def test_suppression_cannot_leak_a_count(self):
        with self.assertRaises(ValueError):
            module.build([self.row(suppressed="true")])

    def test_uncleared_rights_are_rejected(self):
        with self.assertRaises(ValueError):
            module.build([self.row(rights_state="pending")])


if __name__ == "__main__":
    unittest.main()
