import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "build_logainm_foundation_index", ROOT / "tools/build_logainm_foundation_index.py"
)
module = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(module)


class LogainmFoundationIndexTests(unittest.TestCase):
    def test_preserves_forms_hierarchy_coordinates_and_attribution(self):
        snapshot = {
            "fetchedAt": "2026-07-13T00:00:00+00:00",
            "attribution": "Required attribution",
            "records": [{
                "ID": 45008,
                "DateModified": "2026-06-01T00:00:00Z",
                "Permalink": "https://www.logainm.ie/en/45008",
                "Placenames": [
                    {"Language": "ga", "Wording": "Ceathrúnach", "Genetive": "Ceathrúnaí", "Main": True},
                    {"Language": "en", "Wording": "Carrownagh", "Main": True},
                ],
                "Categories": [{"ID": "TOWNLAND", "NameEN": "Townland"}],
                "IncludedIn": [{"NameGA": "Sligeach", "NameEN": "Sligo"}],
                "Geography": [{"Accurate": True, "Coordinates": [{"Latitude": 54.2131, "Longitude": -8.41126}]}],
            }],
        }
        result = module.build(snapshot)
        entry = result["entries"][0]
        self.assertEqual(entry["canonicalDisplay"], "Ceathrúnach")
        self.assertIn("Carrownagh", entry["searchKeys"])
        self.assertEqual(entry["foundation"]["coordinates"]["lat"], 54.2131)
        self.assertEqual(entry["foundation"]["attribution"], "Required attribution")


if __name__ == "__main__":
    unittest.main()
