#!/usr/bin/env python3
"""Export only release-gated personal-atlas subjects for the public web preview.

The review log comes from tools/content-review. Pack breadth and the legacy
`authored` depth never make a subject publishable.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PACK = ROOT / "ios/AnTuras/Resources/personal-atlas-subjects.json"
DEFAULT_OUTPUT = ROOT / "web/personal-atlas/public-subjects.json"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("review_log", type=Path)
    parser.add_argument("--pack", type=Path, default=DEFAULT_PACK)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--allow-empty", action="store_true")
    args = parser.parse_args()

    pack = json.loads(args.pack.read_text(encoding="utf-8"))
    review_export = json.loads(args.review_log.read_text(encoding="utf-8"))
    reviews = review_export.get("reviews", {})
    released = []

    for subject in pack["subjects"]:
        review = reviews.get(f"subject:{subject['id']}", {})
        if review.get("stage") != "showcase":
            continue
        validate_release(subject, review)
        released.append(public_record(subject, review))

    if not released and not args.allow_empty:
        raise SystemExit("No subject passed the showcase release gates; refusing an empty public release.")

    payload = {
        "version": pack["version"],
        "contentDate": pack["contentDate"],
        "attribution": pack["attribution"],
        "subjects": released,
    }
    canonical = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()
    payload["sha256"] = hashlib.sha256(canonical).hexdigest()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Exported {len(released)} release-gated subjects to {args.output}")
    return 0


def validate_release(subject: dict, review: dict) -> None:
    if not review.get("reviewedAt"):
        raise SystemExit(f"{subject['id']}: missing durable review date")
    assertion_ids = {item.get("assertionId") for item in subject["assertions"]}
    if None in assertion_ids or len(assertion_ids) != len(subject["assertions"]):
        raise SystemExit(f"{subject['id']}: assertions need unique durable assertionId values")
    if subject["editorial"].get("shortAnswerAssertionId") not in assertion_ids:
        raise SystemExit(f"{subject['id']}: short answer is not mapped to an assertion")
    branches = (
        (subject.get("nameProfile") or {}).get("etymologyBranches")
        or (subject.get("placeProfile") or {}).get("derivationBranches")
        or []
    )
    for branch in branches:
        if branch.get("assertionId") not in assertion_ids:
            raise SystemExit(f"{subject['id']}: branch {branch['label']!r} is not mapped to an assertion")
    typed_variants = {
        item["display"] for item in subject.get("variantRelationships") or []
    }
    untyped = {
        item for item in subject.get("variants", [])
        if item != subject["canonicalDisplay"] and item not in typed_variants
    }
    if untyped:
        raise SystemExit(f"{subject['id']}: untyped variants: {sorted(untyped)}")
    signoffs = review.get("signoffs", {})
    required = ["historian", "nativeSpeaker", "rights", "accessibility"]
    required.append("onomastics" if subject["kind"] == "name" else "placenames")
    missing = [key for key in required if not signoffs.get(key)]
    if missing:
        raise SystemExit(f"{subject['id']}: missing sign-offs: {', '.join(missing)}")

    claim_reviews = review.get("claims", {})
    for index, assertion in enumerate(subject["assertions"]):
        claim = claim_reviews.get(str(index), {})
        if not assertion.get("evidenceIds"):
            raise SystemExit(f"{subject['id']} claim {index}: no evidence")
        if not claim.get("reviewer", "").strip():
            raise SystemExit(f"{subject['id']} claim {index}: no named reviewer")
        if claim.get("rights") not in {"cleared", "link-only"}:
            raise SystemExit(f"{subject['id']} claim {index}: rights not cleared")
        if claim.get("decision") != "accept":
            raise SystemExit(f"{subject['id']} claim {index}: not accepted")
        if claim.get("audio") not in {"verified", "intentionally-unavailable"}:
            raise SystemExit(f"{subject['id']} claim {index}: audio state unresolved")


def public_record(subject: dict, review: dict) -> dict:
    """Publish the complete app subject without demand, feedback, or workflow data."""
    public_assertions = []
    for index, assertion in enumerate(subject["assertions"]):
        claim_review = review["claims"][str(index)]
        public_assertions.append(
            {
                **assertion,
                "reviewer": claim_review["reviewer"],
                "reviewedAt": review["reviewedAt"],
                "rightsState": claim_review["rights"],
                "reviewHistory": [
                    {
                        "reviewer": claim_review["reviewer"],
                        "reviewedAt": review["reviewedAt"],
                        "decision": claim_review["decision"],
                        "note": review.get("note") or None,
                    }
                ],
            }
        )
    return {
        **subject,
        "editorial": {**subject["editorial"], "releaseState": "public"},
        "assertions": public_assertions,
    }


if __name__ == "__main__":
    raise SystemExit(main())
