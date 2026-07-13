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
    def test_repairs_countyless_records_with_provenance(self):
        snapshot = {
            "fetchedAt": "2026-07-13T00:00:00+00:00", "attribution": "Required",
            "records": [
                {
                    "id": 1,
                    "placenames": [{"language": "en", "wording": "Down", "main": True}],
                    "categories": [{"id": "CON", "nameEN": "county"}],
                },
                {
                    "id": 2,
                    "placenames": [{"language": "en", "wording": "Parish", "main": True}],
                    "categories": [{"id": "PAR", "nameEN": "civil parish"}],
                    "includedIn": [
                        {"id": 1, "nameEN": "Down", "category": {"id": "CON"}}
                    ],
                },
                {
                    "id": 3,
                    "placenames": [{"language": "en", "wording": "Townland", "main": True}],
                    "categories": [{"id": "BF", "nameEN": "townland"}],
                    "includedIn": [
                        {"id": 2, "nameEN": "Parish", "category": {"id": "PAR"}}
                    ],
                },
            ],
        }
        entry = module.build(snapshot)["entries"][2]
        self.assertEqual(entry["foundation"]["hierarchy"], "Parish / Down")
        self.assertEqual(entry["foundation"]["hierarchyRepairs"], [{
            "county": "Down", "method": "inferred_existing_hierarchy",
            "sources": ["logainm:1", "logainm:2"],
        }])

    def test_county_root_does_not_infer_itself_through_a_cluster(self):
        snapshot = {
            "fetchedAt": "2026-07-13T00:00:00+00:00", "attribution": "Required",
            "records": [{
                "id": 100001,
                "placenames": [{"language": "en", "wording": "Armagh", "main": True}],
                "categories": [{"id": "CON", "nameEN": "county"}],
                "cluster": {"members": [{"placeID": 2}]},
            }, {
                "id": 2,
                "placenames": [{"language": "en", "wording": "Historic Armagh", "main": True}],
                "categories": [{"id": "CONH", "nameEN": "historic county"}],
                "includedIn": [
                    {"id": 100001, "nameEN": "Armagh", "category": {"id": "CON"}}
                ],
            }],
        }
        county = next(
            item for item in module.build(snapshot)["entries"]
            if item["foundation"]["logainmId"] == 100001
        )
        self.assertEqual(county["foundation"]["hierarchy"], "Ireland")
        self.assertEqual(county["foundation"]["hierarchyRepairs"], [])

    def test_reviewed_repair_overrides_ambiguous_parent_inference(self):
        snapshot = {
            "fetchedAt": "2026-07-13T00:00:00+00:00", "attribution": "Required",
            "records": [{
                "id": 56408,
                "placenames": [{"language": "en", "wording": "Clankilvoragh", "main": True}],
                "categories": [{"id": "BF", "nameEN": "townland"}],
                "includedIn": [
                    {"id": 2737, "nameEN": "Magheralin", "category": {"id": "PAR"}}
                ],
            }],
        }
        repairs = {"records": {"56408": {
            "expectedEnglish": "Clankilvoragh", "counties": ["Armagh"],
            "method": "reviewed_external_evidence",
            "sources": ["osni:50k-townlands", "cso:census-1851-armagh"],
        }}}
        entry = module.build(snapshot, repairs)["entries"][0]
        self.assertEqual(entry["foundation"]["hierarchy"], "Magheralin / Armagh")
        self.assertEqual(entry["foundation"]["hierarchyRepairs"][0]["county"], "Armagh")
        self.assertEqual(
            entry["foundation"]["hierarchyRepairs"][0]["method"],
            "reviewed_external_evidence",
        )

    def test_repair_rejects_a_stale_identity_match(self):
        snapshot = {
            "fetchedAt": "2026-07-13T00:00:00+00:00", "attribution": "Required",
            "records": [{
                "id": 56408,
                "placenames": [{"language": "en", "wording": "Different", "main": True}],
                "categories": [{"id": "BF", "nameEN": "townland"}],
            }],
        }
        repairs = {"records": {"56408": {
            "expectedEnglish": "Clankilvoragh", "counties": ["Armagh"],
            "method": "reviewed_external_evidence", "sources": [],
        }}}
        with self.assertRaisesRegex(ValueError, "expected English form"):
            module.build(snapshot, repairs)

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
            repairs = database.execute(
                "SELECT hierarchy_repairs FROM places WHERE id = 1"
            ).fetchone()[0]
            self.assertIsNone(repairs)

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
