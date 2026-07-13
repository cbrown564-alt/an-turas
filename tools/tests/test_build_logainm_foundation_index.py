import importlib.util
import sqlite3
import tempfile
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

    def test_accepts_live_camel_case_record_and_geography_object(self):
        snapshot = {
            "fetchedAt": "2026-07-13T00:00:00+00:00", "attribution": "Required",
            "records": [{
                "id": 1, "dateModified": "2025-01-10", "permalink": "https://www.logainm.ie/1.aspx",
                "placenames": [{"language": "ga", "wording": "Ráth Bhile", "main": True},
                               {"language": "en", "wording": "Rathvilly", "main": True}],
                "categories": [{"id": "BAR", "nameEN": "barony"}],
                "includedIn": [{"nameGA": "Ceatharlach", "nameEN": "Carlow"}],
                "geography": {"coordinates": [{"latitude": 52.84, "longitude": -6.65}]},
            }],
        }
        entry = module.build(snapshot)["entries"][0]
        self.assertEqual(entry["canonicalDisplay"], "Ráth Bhile")
        self.assertEqual(entry["foundation"]["coordinates"], {"lat": 52.84, "lon": -6.65})

    def test_database_is_searchable_and_preserves_foundation_detail(self):
        snapshot = {
            "fetchedAt": "2026-07-13T00:00:00+00:00", "attribution": "Required",
            "records": [{"id": 1, "permalink": "https://www.logainm.ie/1.aspx",
                "placenames": [{"language": "ga", "wording": "Ráth Bhile", "main": True},
                               {"language": "en", "wording": "Rathvilly", "main": True}],
                "categories": [{"nameEN": "barony"}], "includedIn": [{"nameEN": "Carlow"}],
                "geography": {"coordinates": [{"latitude": 52.84, "longitude": -6.65}]}}],
        }
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "foundation.sqlite"
            self.assertEqual(module.build_database(snapshot, path), 1)
            database = sqlite3.connect(path)
            self.assertEqual(database.execute(
                "SELECT place_id FROM aliases WHERE search_key = ?", ("rath bhile",)
            ).fetchone()[0], 1)
            self.assertEqual(database.execute(
                "SELECT canonical, latitude FROM places WHERE id = 1"
            ).fetchone(), ("Ráth Bhile", 52.84))

    def test_out_of_bounds_and_sentinel_coordinates_are_not_shipped(self):
        base = {
            "placenames": [{"language": "en", "wording": "Test", "main": True}],
            "categories": [{"nameEN": "place"}],
        }
        for place_id, latitude, longitude in ((1, 0, 0), (2, 57.3, 0.6), (3, 53.2, 172.3)):
            place = dict(base, id=place_id, geography={
                "coordinates": [{"latitude": latitude, "longitude": longitude}]
            })
            self.assertIsNone(module.build_entry(place, "Required")["foundation"]["coordinates"])


if __name__ == "__main__":
    unittest.main()
