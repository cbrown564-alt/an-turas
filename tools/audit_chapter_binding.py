#!/usr/bin/env python3
"""Audit chapter binding between a county pack, the phrase-family catalog, and audio.

Three layers must agree for one exercise to run (docs/CHAPTER-BINDING.md §2):

1. the pack exercise's ``phraseFamilyMemberIDs`` and its answer/audio/model text;
2. a v1 phrase-family member with that id and matching text;
3. a bundled, checksummed clip for that text.

Layers 1 and 2 are enforced in Swift at pack load
(``CountyStoryPack.validatePhraseFamilyMembers``), which throws
``unknownPhraseFamilyMember`` or ``phraseFamilyMemberMismatch``. That check runs
too late to plan work: it fails the pack in the app rather than reporting what
content needs fixing. This tool applies the same bind rule offline, from the
content side, and adds the audio and bundle-drift checks the Swift validator
cannot see.

It reports binding and review readiness. It does not judge Irish grammar,
dialect, pronunciation, pedagogy, or history, it approves nothing, and it never
changes any state.
"""

from __future__ import annotations

import argparse
import json
import sys
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]

SCHEMA_VERSION = 1
CONTRACT = "county_chapter_binding_audit"

DEFAULT_COUNTY = "mayo"
DEFAULT_PACK = "content/mayo/grainne-1593.pack.draft.json"
MANIFEST_PATH = "ios/AnTuras/Resources/Audio/manifest.json"

# Mirrors CountyStoryPack.foldingFadas and tools/validate_county_pack.py::_FADA.
_FADA = str.maketrans("áéíóúÁÉÍÓÚ", "aeiouaeiou")

# Blocking findings fail `check`. These are the two the runtime itself throws on,
# plus a stale bundle, which ships content the repository does not describe.
BLOCKING = frozenset(
    {"unresolved_member", "bind_rule_mismatch", "bundle_drift", "bundle_missing"}
)

# Review states that mean a bound member is not yet safe to teach from.
UNREVIEWED_QA_STATES = frozenset(
    {"generated_unreviewed", "spot_flagged", "pending_generation"}
)


def fold(text: Any) -> str:
    """The bind-rule comparison form: NFC, fada-folded, lowercased, trimmed."""
    if not isinstance(text, str):
        return ""
    return unicodedata.normalize("NFC", text).translate(_FADA).lower().strip()


def normalize(text: Any) -> str:
    if not isinstance(text, str):
        return ""
    return unicodedata.normalize("NFC", text).strip()


def load_json(path: Path) -> Any:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def load_catalog(root: Path, county: str) -> tuple[dict[str, dict[str, Any]], list[str]]:
    """Load the v1 phrase-family catalog the runtime would see for a county.

    `PhraseFamilyCatalog.familyURLs` filters bundle resources to `.v1.json`, so
    v2 authoring members are deliberately not loaded here — the app cannot see
    them either (docs/CHAPTER-BINDING.md §1).
    """
    catalog: dict[str, dict[str, Any]] = {}
    sources: list[str] = []
    family_dir = root / "content" / county / "phrase-families"
    for path in sorted(family_dir.glob("*.v1.json")):
        family = load_json(path)
        sources.append(str(path.relative_to(root)))
        review = family.get("review") or {}
        for member in family.get("members", []):
            member_id = member.get("id")
            if not isinstance(member_id, str):
                continue
            catalog[member_id] = {
                "id": member_id,
                "text": normalize(member.get("text")),
                "qa_state": member.get("qa_state"),
                "family_id": family.get("id"),
                "family_status": family.get("status"),
                "lexeme_id": family.get("lexeme_id"),
                "teaching_claims_allowed": bool(review.get("teaching_claims_allowed")),
                "source": str(path.relative_to(root)),
            }
    return catalog, sources


def bundle_findings(root: Path, county: str) -> list[dict[str, Any]]:
    """Compare the authored catalog against the copy the app actually bundles."""
    findings: list[dict[str, Any]] = []
    source_dir = root / "content" / county / "phrase-families"
    bundle_dir = root / "ios" / "AnTuras" / "Resources" / "PhraseFamilies" / county
    if not bundle_dir.is_dir():
        return [
            {
                "code": "bundle_missing",
                "detail": f"no bundled phrase-family directory at {bundle_dir}",
                "chapter": None,
                "page": None,
            }
        ]
    for path in sorted(source_dir.glob("*.v1.json")):
        mirror = bundle_dir / path.name
        if not mirror.is_file():
            findings.append(
                {
                    "code": "bundle_missing",
                    "detail": f"{path.name} is authored but not bundled",
                    "chapter": None,
                    "page": None,
                }
            )
        elif mirror.read_bytes() != path.read_bytes():
            findings.append(
                {
                    "code": "bundle_drift",
                    "detail": f"{path.name} differs between content and bundle",
                    "chapter": None,
                    "page": None,
                }
            )
    for mirror in sorted(bundle_dir.glob("*.v1.json")):
        if not (source_dir / mirror.name).is_file():
            findings.append(
                {
                    "code": "bundle_orphan",
                    "detail": f"{mirror.name} is bundled but not authored",
                    "chapter": None,
                    "page": None,
                }
            )
    return findings


def store_conflicts(root: Path, county: str, catalog: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    """Compare review posture for ids that exist in both the v1 and v2 stores.

    Two stores describing the same member can disagree, and only the v1 answer
    reaches the app. A member the v2 store calls reviewed is still unreviewed as
    far as the runtime is concerned (docs/CHAPTER-BINDING.md §1).
    """
    findings: list[dict[str, Any]] = []
    v2_dir = root / "content" / county / "phrase-families" / "authoring-v2"
    for path in sorted(v2_dir.glob("*.json")):
        family = load_json(path)
        for member in family.get("members", []):
            member_id = member.get("id")
            twin = catalog.get(member_id) if isinstance(member_id, str) else None
            states = member.get("states") or {}
            reviews = states.get("reviews") or {}
            if not reviews:
                continue
            all_approved = all(
                (record or {}).get("status") == "approved"
                for record in reviews.values()
            )

            release = states.get("learner_release") or {}
            reasons = release.get("reasons") or []
            if all_approved and any("review_pending" in str(item) for item in reasons):
                findings.append(
                    {
                        "code": "release_state_contradiction",
                        "chapter": None,
                        "page": None,
                        "member_id": member_id,
                        "detail": (
                            "v2 member records every review approved but its "
                            f"learner_release reasons still claim {reasons}"
                        ),
                    }
                )

            if twin is not None and all_approved and twin["qa_state"] in UNREVIEWED_QA_STATES:
                findings.append(
                    {
                        "code": "store_state_conflict",
                        "chapter": None,
                        "page": None,
                        "member_id": member_id,
                        "detail": (
                            f"v2 records every review approved but the v1 member the "
                            f"app loads is {twin['qa_state']}"
                        ),
                    }
                )
    return findings


def pair_candidates(
    exercise: dict[str, Any], catalog: dict[str, dict[str, Any]]
) -> list[dict[str, Any]]:
    """Catalog members whose text equals a matching pair's Irish side.

    Recorded as evidence for a decision, not as a binding. The bind rule does
    not read ``pairs``, so these cannot be wired without a runtime change.
    """
    by_text = {fold(member["text"]): member for member in catalog.values()}
    candidates: list[dict[str, Any]] = []
    for pair in exercise.get("pairs") or []:
        member = by_text.get(fold(pair.get("left")))
        candidates.append(
            {
                "pair_id": pair.get("id"),
                "irish": pair.get("left"),
                "english": pair.get("right"),
                "member_id": member["id"] if member else None,
                "qa_state": member["qa_state"] if member else None,
            }
        )
    return candidates


def audit(root: Path, *, county: str, pack_path: Path) -> dict[str, Any]:
    pack = load_json(pack_path)["pack"]
    catalog, catalog_sources = load_catalog(root, county)
    manifest = load_json(root / MANIFEST_PATH)
    clips_by_text: dict[str, dict[str, Any]] = {
        fold(row.get("text")): row
        for row in manifest.get("lines", [])
        if row.get("text")
    }

    findings: list[dict[str, Any]] = list(bundle_findings(root, county))
    findings.extend(store_conflicts(root, county, catalog))
    chapters: list[dict[str, Any]] = []

    for chapter in pack.get("chapters", []):
        chapter_id = chapter.get("id")
        exercises = 0
        bound_exercises = 0
        bound_members: list[dict[str, Any]] = []

        for page in chapter.get("pages", []):
            exercise = page.get("exercise")
            if not isinstance(exercise, dict):
                continue
            exercises += 1
            page_id = page.get("id")
            member_ids = exercise.get("phraseFamilyMemberIDs") or []

            # The runtime binds against answer, audioText, and modelText only.
            bind_targets = {
                fold(value)
                for value in (
                    exercise.get("answer"),
                    exercise.get("audioText"),
                    exercise.get("modelText"),
                )
                if fold(value)
            }

            if not member_ids:
                lexemes = exercise.get("lexemeIDs") or []
                if not lexemes:
                    # Comprehension and reading exercises teach no lexeme and
                    # have nothing to bind.
                    findings.append(
                        {
                            "code": "unbound_comprehension_exercise",
                            "chapter": chapter_id,
                            "page": page_id,
                            "detail": (
                                f"{exercise.get('family')} exercise names no "
                                f"phrase-family member; teaches no lexeme"
                            ),
                        }
                    )
                    continue

                # A bind target with a bundled clip is real Irish, so a member
                # carrying it would bind. A target with no clip is English prose
                # or an instruction ("all pairs"), which the rule cannot express
                # however the content is authored.
                irish_targets = sorted(
                    target for target in bind_targets if target in clips_by_text
                )
                findings.append(
                    {
                        "code": (
                            "bindable_needs_member"
                            if irish_targets
                            else "unbindable_by_rule"
                        ),
                        "chapter": chapter_id,
                        "page": page_id,
                        "detail": (
                            (
                                f"{exercise.get('family')} exercise has Irish bind "
                                f"target(s) {irish_targets} with bundled audio but no "
                                f"catalog member carries the text"
                            )
                            if irish_targets
                            else (
                                f"{exercise.get('family')} exercise binds against "
                                f"{sorted(bind_targets)}, which carries no Irish; the "
                                f"bind rule reads answer/audioText/modelText only"
                            )
                        ),
                        "candidates": pair_candidates(exercise, catalog),
                        "lexemes": lexemes,
                    }
                )
                continue
            bound_exercises += 1

            for member_id in member_ids:
                member = catalog.get(member_id)
                if member is None:
                    findings.append(
                        {
                            "code": "unresolved_member",
                            "chapter": chapter_id,
                            "page": page_id,
                            "member_id": member_id,
                            "detail": (
                                "not in the v1 catalog the runtime loads; the pack "
                                "would throw unknownPhraseFamilyMember"
                            ),
                        }
                    )
                    continue

                if fold(member["text"]) not in bind_targets:
                    findings.append(
                        {
                            "code": "bind_rule_mismatch",
                            "chapter": chapter_id,
                            "page": page_id,
                            "member_id": member_id,
                            "detail": (
                                f"member text {member['text']!r} matches no "
                                f"answer/audioText/modelText; the pack would throw "
                                f"phraseFamilyMemberMismatch"
                            ),
                        }
                    )
                    continue

                clip = clips_by_text.get(fold(member["text"]))
                if clip is None:
                    findings.append(
                        {
                            "code": "member_without_clip",
                            "chapter": chapter_id,
                            "page": page_id,
                            "member_id": member_id,
                            "detail": f"no bundled clip for {member['text']!r}",
                        }
                    )
                elif not clip.get("sha256"):
                    findings.append(
                        {
                            "code": "clip_without_checksum",
                            "chapter": chapter_id,
                            "page": page_id,
                            "member_id": member_id,
                            "detail": f"clip {clip.get('file')} has no checksum",
                        }
                    )

                if member["qa_state"] in UNREVIEWED_QA_STATES:
                    findings.append(
                        {
                            "code": "member_not_reviewed",
                            "chapter": chapter_id,
                            "page": page_id,
                            "member_id": member_id,
                            "detail": (
                                f"qa_state={member['qa_state']} in family "
                                f"{member['family_id']} (status "
                                f"{member['family_status']})"
                            ),
                        }
                    )
                bound_members.append(member)

        chapters.append(
            {
                "chapter": chapter_id,
                "exercises": exercises,
                "bound_exercises": bound_exercises,
                "unbound_exercises": exercises - bound_exercises,
                "bound_members": len(bound_members),
                "distinct_members": len({row["id"] for row in bound_members}),
                "qa_states": dict(
                    Counter(row["qa_state"] for row in bound_members).most_common()
                ),
                "review_ready": all(
                    row["qa_state"] not in UNREVIEWED_QA_STATES for row in bound_members
                )
                and exercises == bound_exercises
                and exercises > 0,
            }
        )

    by_code = Counter(item["code"] for item in findings)
    blocking = [item for item in findings if item["code"] in BLOCKING]

    return {
        "schema_version": SCHEMA_VERSION,
        "contract": CONTRACT,
        "scope": (
            "mechanical binding and review-readiness audit; not linguistic "
            "approval and not learner release"
        ),
        "read_only": True,
        "county": county,
        "sources": {
            "pack": str(pack_path.relative_to(root)),
            "catalog": catalog_sources,
            "manifest": MANIFEST_PATH,
            "bind_rule": (
                "CountyStoryPack.validatePhraseFamilyMembers; fada-folded, "
                "lowercased, trimmed comparison against answer/audioText/modelText"
            ),
        },
        "summary": {
            "chapters": len(chapters),
            "catalog_members": len(catalog),
            "findings": len(findings),
            "blocking": len(blocking),
            "by_code": dict(by_code.most_common()),
            "review_ready_chapters": sorted(
                row["chapter"] for row in chapters if row["review_ready"]
            ),
        },
        "chapters": chapters,
        "findings": findings,
    }


def render(report: dict[str, Any]) -> str:
    lines: list[str] = []
    summary = report["summary"]
    lines.append(f"Chapter binding audit — {report['county']}")
    lines.append(
        f"  {summary['chapters']} chapters, {summary['catalog_members']} catalog "
        f"members, {summary['findings']} findings ({summary['blocking']} blocking)"
    )
    lines.append("")
    lines.append(
        f"  {'chapter':<26} {'ex':>3} {'bound':>6} {'members':>8}  qa states"
    )
    for row in report["chapters"]:
        states = ", ".join(f"{key}:{value}" for key, value in row["qa_states"].items())
        flag = "  ready" if row["review_ready"] else ""
        lines.append(
            f"  {row['chapter']:<26} {row['exercises']:>3} "
            f"{row['bound_exercises']:>6} {row['distinct_members']:>8}  "
            f"{states or '-'}{flag}"
        )
    lines.append("")

    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for item in report["findings"]:
        grouped[item["code"]].append(item)
    for code in sorted(grouped, key=lambda key: (key not in BLOCKING, key)):
        marker = "BLOCKING" if code in BLOCKING else "advisory"
        lines.append(f"  [{marker}] {code} ({len(grouped[code])})")
        for item in grouped[code]:
            where = " · ".join(
                part for part in (item.get("page"), item.get("member_id")) if part
            )
            lines.append(f"      {where or item.get('chapter') or '-'}: {item['detail']}")
        lines.append("")
    return "\n".join(lines)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("command", choices=("report", "check"))
    parser.add_argument("--county", default=DEFAULT_COUNTY)
    parser.add_argument("--pack", default=DEFAULT_PACK)
    parser.add_argument("--chapter", help="Limit output to one chapter id.")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--out")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])
    report = audit(ROOT, county=args.county, pack_path=ROOT / args.pack)

    if args.chapter:
        report["chapters"] = [
            row for row in report["chapters"] if row["chapter"] == args.chapter
        ]
        report["findings"] = [
            item for item in report["findings"] if item.get("chapter") == args.chapter
        ]
        report["summary"]["findings"] = len(report["findings"])
        report["summary"]["blocking"] = sum(
            1 for item in report["findings"] if item["code"] in BLOCKING
        )

    if args.out:
        Path(args.out).write_text(
            json.dumps(report, ensure_ascii=False, indent=1) + "\n", encoding="utf-8"
        )
        print(f"wrote {args.out}")
    elif args.json:
        print(json.dumps(report, ensure_ascii=False, indent=1))
    else:
        print(render(report))

    if args.command == "check":
        return 1 if report["summary"]["blocking"] else 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
