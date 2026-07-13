import importlib.util
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


audit = load("audit_logainm_coverage", ROOT / "tools/audit_logainm_coverage.py")
builder = load("build_logainm_foundation_index_for_audit", ROOT / "tools/build_logainm_foundation_index.py")


class LogainmCoverageAuditTests(unittest.TestCase):
    def test_flags_source_sentinel_but_accepts_safely_nulled_projection(self):
        snapshot = {
            "fetchedAt": "2026-07-13T00:00:00+00:00", "attribution": "Required",
            "records": [{
                "id": 1, "dateModified": "2026-07-01", "permalink": "https://www.logainm.ie/1.aspx",
                "placenames": [{"language": "ga", "wording": "Áit", "main": True},
                               {"language": "en", "wording": "Place", "main": True}],
                "categories": [{"nameEN": "place"}],
                "includedIn": [{"nameEN": "Mayo", "category": {"id": "CON"}}],
                "geography": {"coordinates": [{"latitude": 0, "longitude": 0}]},
            }],
        }
        with tempfile.TemporaryDirectory() as directory:
            database = Path(directory) / "foundation.sqlite"
            builder.build_database(snapshot, database)
            report = audit.profile(snapshot, database)

        self.assertEqual(report["summary"]["sourceInvalidCoordinates"], 1)
        self.assertEqual(report["summary"]["shippedMissingCoordinates"], 1)
        coordinate_check = next(
            item for item in report["checks"] if item["check"] == "invalid_coordinates_shipped"
        )
        self.assertEqual(coordinate_check["status"], "pass")
        self.assertEqual(report["releaseGate"], "fail", "A one-county fixture must fail coverage")


if __name__ == "__main__":
    unittest.main()
