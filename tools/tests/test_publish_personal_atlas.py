import importlib.util
import base64
import copy
import json
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "publish_personal_atlas", ROOT / "tools/publish_personal_atlas.py"
)
publisher = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(publisher)

BUILD_SPEC = importlib.util.spec_from_file_location(
    "build_personal_atlas_release", ROOT / "tools/build_personal_atlas_release.py"
)
builder = importlib.util.module_from_spec(BUILD_SPEC)
assert BUILD_SPEC.loader is not None
BUILD_SPEC.loader.exec_module(builder)


class PersonalAtlasPublisherTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        pack = json.loads(
            (ROOT / "ios/AnTuras/Resources/personal-atlas-subjects.json").read_text()
        )
        cls.subject = copy.deepcopy(pack["subjects"][0])
        for index, assertion in enumerate(cls.subject["assertions"]):
            assertion["assertionId"] = f"assertion-{index}"
        cls.subject["editorial"]["shortAnswerAssertionId"] = "assertion-0"
        branches = (
            (cls.subject.get("nameProfile") or {}).get("etymologyBranches")
            or (cls.subject.get("placeProfile") or {}).get("derivationBranches")
            or []
        )
        for branch in branches:
            branch["assertionId"] = "assertion-0"
        cls.subject["variantRelationships"] = [
            {"display": item, "relationship": "relatedForm", "note": None}
            for item in cls.subject["variants"]
            if item != cls.subject["canonicalDisplay"]
        ]

    def review(self):
        return {
            "stage": "showcase",
            "reviewedAt": "2026-07-13T00:00:00Z",
            "signoffs": {
                "onomastics": True,
                "historian": True,
                "nativeSpeaker": True,
                "rights": True,
                "accessibility": True,
            },
            "claims": {
                str(index): {
                    "reviewer": "Named specialist",
                    "rights": "cleared",
                    "decision": "accept",
                    "audio": "intentionally-unavailable",
                }
                for index, _ in enumerate(self.subject["assertions"])
            },
        }

    def test_release_gate_rejects_missing_signoffs(self):
        review = self.review()
        review["signoffs"]["onomastics"] = False
        with self.assertRaises(SystemExit):
            publisher.validate_release(self.subject, review)

    def test_public_record_uses_durable_review_not_pilot_authority(self):
        review = self.review()
        publisher.validate_release(self.subject, review)
        record = publisher.public_record(self.subject, review)
        self.assertTrue(record["assertions"])
        self.assertTrue(
            all(claim["reviewer"] == "Named specialist" for claim in record["assertions"])
        )
        self.assertTrue(
            all(claim["rightsState"] == "cleared" for claim in record["assertions"])
        )

    def test_release_builder_emits_verifiable_ed25519_detail_pack(self):
        review = self.review()
        record = publisher.public_record(self.subject, review)
        source = {
            "version": "2.0.0",
            "contentDate": "2026-07-13",
            "attribution": "Test attribution",
            "subjects": [record],
        }
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            private_key = root / "private.pem"
            public_key = root / "public.pem"
            subprocess.run(
                ["openssl", "genpkey", "-algorithm", "ED25519", "-out", private_key],
                check=True,
                capture_output=True,
            )
            subprocess.run(
                ["openssl", "pkey", "-in", private_key, "-pubout", "-out", public_key],
                check=True,
                capture_output=True,
            )
            release = builder.build_release(
                source, root / "release", private_key, "test-key", False
            )
            artifact = release["artifacts"][0]
            signature = root / "signature.bin"
            signature.write_bytes(base64.b64decode(artifact["signature"]))
            result = subprocess.run(
                [
                    "openssl", "pkeyutl", "-verify", "-pubin", "-inkey", public_key,
                    "-sigfile", signature, "-rawin", "-in",
                    root / "release" / artifact["path"],
                ],
                capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr.decode())


if __name__ == "__main__":
    unittest.main()
