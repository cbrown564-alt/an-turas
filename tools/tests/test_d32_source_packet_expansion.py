"""Tests for A6 / queue-03 source-packet expansion."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))
sys.path.insert(0, str(REPO_ROOT / "tools"))

import generate_d32_source_packet_expansion as a6  # noqa: E402


class SourcePacketExpansionTests(unittest.TestCase):
    def test_queue_counties_match_status_table(self):
        self.assertEqual(
            set(a6.QUEUE_03_COUNTIES),
            {
                "antrim",
                "armagh",
                "carlow",
                "cavan",
                "clare",
                "down",
                "fermanagh",
                "kildare",
                "kilkenny",
                "laois",
                "monaghan",
                "sligo",
                "westmeath",
                "wicklow",
            },
        )
        self.assertEqual(set(a6.PACKETS), set(a6.QUEUE_03_COUNTIES))

    def test_logainm_confirmed_sites_exist_in_index(self):
        confirmed = a6.confirmed_logainm_irish()
        for county, packet in a6.PACKETS.items():
            for site in packet["sites"]:
                if site["status"] == "logainm_index_confirmed":
                    self.assertIn(
                        a6.normalize(site["ga"]),
                        confirmed,
                        msg=f"{county} site {site['ga']!r} missing from Logainm index",
                    )

    def test_packet_register_records_are_unique_and_complete(self):
        atlas = a6.load_json(a6.ATLAS_PATH)
        register = a6.build_packet_register(atlas, write_briefs=False)
        self.assertEqual(len(register["counties"]), 14)
        self.assertGreaterEqual(len(register["records"]), 14)
        ids = [item["id"] for item in register["records"]]
        self.assertEqual(len(ids), len(set(ids)))
        by_id = {item["id"]: item for item in register["records"]}
        self.assertIn("d32.packet.antrim.county-form", by_id)
        self.assertEqual(
            by_id["d32.packet.antrim.place.clochán-an-aifir"]["ga"],
            "Clochán an Aifir",
        )
        self.assertTrue(
            all(item["packet_status"] == "stub_confirmed" for item in register["counties"])
        )

    def test_templates_keep_target_form_in_text(self):
        for county in a6.QUEUE_03_COUNTIES:
            display = a6.load_json(a6.ATLAS_PATH)["counties"][county]["display"]
            county_ga, county_en = a6.county_ga_en(display)
            for template in a6.templates_for(county, county_ga, county_en):
                text = template["text"].format(ga="ainm", gloss="name")
                self.assertIn("ainm", text)

    def test_dedupe_stories_prefers_instance_id(self):
        stories = [
            {"id": "d32.demo", "title": "a"},
            {"id": "d32.demo", "title": "b", "record_instance_id": "d32.demo.primary"},
            {"id": "d32.other", "title": "c"},
            {"id": "d32.demo", "title": "d"},
        ]
        deduped = a6.dedupe_stories(stories)
        self.assertEqual([item["id"] for item in deduped], ["d32.demo", "d32.other"])
        self.assertEqual(deduped[0]["record_instance_id"], "d32.demo.primary")


if __name__ == "__main__":
    unittest.main()
