import importlib.util
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "build_personal_web_previews", ROOT / "tools/build_personal_web_previews.py"
)
module = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(module)


class PersonalWebPreviewTests(unittest.TestCase):
    def test_preview_is_crawlable_source_visible_and_app_linked(self):
        subject = {
            "id": "place.test",
            "kind": "place",
            "canonicalDisplay": "Áit Tástála",
            "subtitle": "test place",
            "editorial": {"shortAnswer": "A reviewed answer.", "contentVersion": "1"},
            "assertions": [{
                "statement": "A material claim", "certainty": "recorded", "scope": "test",
                "reviewedAt": "2026-07-13", "reviewer": "Named reviewer",
                "rightsState": "cleared", "evidenceIds": ["e1"],
            }],
            "evidence": [{"id": "e1", "citation": "Source citation", "stableURL": "https://example.invalid/source"}],
        }
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary)
            module.build({"attribution": "Attribution", "subjects": [subject]}, output)
            page = (output / "subjects/place.test/index.html").read_text()
            self.assertIn('name="robots" content="index,follow"', page)
            self.assertIn("Source citation", page)
            self.assertIn("anturas://personal/place.test", page)
            self.assertNotIn("queryDemand", page)


if __name__ == "__main__":
    unittest.main()
