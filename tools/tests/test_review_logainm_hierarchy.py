import importlib.util
import unittest
from pathlib import Path


SPEC = importlib.util.spec_from_file_location(
    "review_logainm_hierarchy", Path(__file__).parents[1] / "review_logainm_hierarchy.py"
)
module = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(module)


def place(place_id, category_id, parents=(), languages=("ga", "en"), cluster=()):
    return {
        "id": place_id,
        "placenames": [{"language": language, "wording": language} for language in languages],
        "categories": [{"id": category_id, "nameEN": category_id}],
        "includedIn": [
            {"id": parent_id, "nameEN": name, "category": {"id": parent_category}}
            for parent_id, name, parent_category in parents
        ],
        "cluster": {"members": [{"placeID": member_id} for member_id in cluster]} if cluster else None,
        "geography": {"coordinates": [{"latitude": 54.0, "longitude": -7.0}]},
    }


class HierarchyReviewTests(unittest.TestCase):
    def test_recovers_county_through_parent(self):
        county = place(1, "CON")
        parish = place(2, "PAR", [(1, "Down", "CON")])
        townland = place(3, "BF", [(2, "Parish", "PAR")])
        records = {record["id"]: record for record in [county, parish, townland]}
        self.assertEqual(module.infer_counties(3, records), {"Down"})
        self.assertEqual(
            module.countyless_disposition(townland, records), "recover_from_existing_hierarchy"
        )

    def test_does_not_force_physical_feature_to_one_county(self):
        river = place(4, "ABH", [(1, "Down", "CON"), (2, "Armagh", "CON")])
        self.assertEqual(
            module.multi_county_disposition(river), "plausible_cross_boundary_feature"
        )

    def test_no_form_record_is_excluded_from_manual_queue(self):
        record = place(5, "?", languages=())
        self.assertEqual(module.form_state(record), "no_usable_form")
        self.assertEqual(
            module.countyless_disposition(record, {5: record}), "exclude_no_usable_form"
        )


if __name__ == "__main__":
    unittest.main()
