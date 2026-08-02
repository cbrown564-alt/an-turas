#!/usr/bin/env python3
"""Plan a resumable, generation-ready Irish audio capture campaign.

This command is deliberately dry-run by default. It collects the existing
runtime catalog, canonical inventory, atlas coverage, and authored phrase
families, then writes inventory-shaped batches that the existing ElevenLabs
builder can consume with ``--inventory-path``. It never calls a provider.

Phrase-family expansion is treated as authored source material. The planner
also emits authoring slots for citation, contextual phrase, sentence-pattern,
dialogue-turn, and variant coverage. Empty slots are not generation requests:
the campaign must not silently invent Irish text.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import sys
import unicodedata
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[2]
INVENTORY_PATH = ROOT / "content/audio/irish-inventory-v1.json"
ATLAS_PATH = ROOT / "content/audio/atlas-headwords-v1.json"
LAUNCH_BANK_PATH = ROOT / "content/audio/launch-phrases-conversations-v1.json"
MANIFEST_PATH = ROOT / "ios/AnTuras/Resources/Audio/manifest.json"
RUNTIME_BUILDER = ROOT / "tools/tts-bakeoff/build-production-audio.py"

DEFAULT_BATCH_SIZE = 100
EXPANSION_BANDS = (
    ("context_phrase", "one place- or story-grounded phrase"),
    ("sentence_pattern", "one reusable sentence pattern"),
    ("dialogue_turn", "one useful dialogue turn or response"),
    ("variant", "one meaningful morphological or register variant"),
)
KIND_PRIORITY = {"conversation": 0, "phrase": 1, "headword": 2, "legacy": 3}
SOURCE_PRIORITY = {
    "phrase_family": 10,
    "runtime_catalog": 20,
    "canonical_inventory": 30,
    "launch_bank": 30,
    "atlas_coverage": 40,
}


def normalize_text(value: str) -> str:
    """Normalize only Unicode form and whitespace; preserve spoken wording."""

    return " ".join(unicodedata.normalize("NFC", value).strip().split())


def slug(text: str) -> str:
    """Match the existing runtime slug rule used by Speech.swift."""

    fadas = {"á": "aa", "é": "ee", "í": "ii", "ó": "oo", "ú": "uu"}
    flat: list[str] = []
    for char in text.lower():
        if char in fadas:
            flat.append(fadas[char])
        elif char.isascii() and char.isalpha():
            flat.append(char)
        else:
            flat.append(" ")
    return "-".join("".join(flat).split())


def lexeme_id(text: str) -> str:
    """Match county-pack lexeme IDs, which fold fadas one-to-one."""

    return "lex." + text.translate(str.maketrans("áéíóúÁÉÍÓÚ", "aeiouaeiou")).lower()


def relative(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def relevant_source_paths() -> list[Path]:
    paths = [INVENTORY_PATH, ATLAS_PATH, LAUNCH_BANK_PATH, MANIFEST_PATH]
    paths.extend(sorted((ROOT / "content").glob("*/phrase-families/*.json")))
    paths.extend(sorted((ROOT / "content").glob("*/*.pack.draft.json")))
    paths.extend(sorted((ROOT / "ios/AnTuras/Resources/Fixtures").glob("*.json")))
    paths.extend(sorted((ROOT / "ios/AnTuras/Resources/CountyStories").glob("*.json")))
    paths.extend(
        sorted((ROOT / "ios/AnTuras/Resources").glob("chapter[123].json"))
    )
    return [path for path in paths if path.exists()]


def source_snapshot(paths: Iterable[Path]) -> list[dict[str, Any]]:
    return [
        {"path": relative(path), "sha256": sha256(path), "bytes": path.stat().st_size}
        for path in sorted(set(paths))
    ]


@dataclass
class Candidate:
    text: str
    slug: str
    kind: str
    counties: set[str] = field(default_factory=set)
    gloss: str = ""
    sources: set[str] = field(default_factory=set)
    source_categories: set[str] = field(default_factory=set)
    provenance: list[dict[str, Any]] = field(default_factory=list)
    lexeme_ids: set[str] = field(default_factory=set)
    qa_states: set[str] = field(default_factory=set)
    priority: int = 99

    def merge(
        self,
        *,
        kind: str,
        county: str | None,
        gloss: str,
        source: str,
        category: str,
        provenance: dict[str, Any],
        lexeme_id: str | None = None,
        qa_state: str | None = None,
    ) -> None:
        self.kind = min(
            (self.kind, kind), key=lambda value: KIND_PRIORITY.get(value, 99)
        )
        if county:
            self.counties.add(county)
        if gloss and not self.gloss:
            self.gloss = gloss
        self.sources.add(source)
        self.source_categories.add(category)
        self.provenance.append(provenance)
        if lexeme_id:
            self.lexeme_ids.add(lexeme_id)
        if qa_state:
            self.qa_states.add(qa_state)
        self.priority = min(self.priority, SOURCE_PRIORITY.get(category, 99))

    def export(self, bundled_slugs: set[str]) -> dict[str, Any]:
        qa_state = next(
            (state for state in ("qa_passed", "spot_flagged", "generated_unreviewed") if state in self.qa_states),
            "capture_unreviewed",
        )
        return {
            "text": self.text,
            "slug": self.slug,
            "kind": self.kind,
            "counties": sorted(self.counties),
            "gloss": self.gloss,
            "source": sorted(self.sources)[0] if self.sources else "bulk-capture",
            "qa_state": qa_state,
            "capture_state": "already_bundled" if self.slug in bundled_slugs else "pending_capture",
            "priority": self.priority,
            "source_categories": sorted(self.source_categories),
            "lexeme_ids": sorted(self.lexeme_ids),
            "provenance": self.provenance,
        }


def add_candidate(
    candidates: dict[str, Candidate],
    collisions: dict[str, dict[str, Any]],
    *,
    text: str,
    kind: str,
    category: str,
    source: str,
    provenance: dict[str, Any],
    county: str | None = None,
    gloss: str = "",
    lexeme_id: str | None = None,
    qa_state: str | None = None,
) -> None:
    normalized = normalize_text(text)
    if not normalized or "{name}" in normalized:
        return
    key = slug(normalized)
    if not key:
        return
    existing = candidates.get(key)
    if existing is None:
        existing = Candidate(normalized, key, kind)
        candidates[key] = existing
    elif existing.text != normalized:
        collision = collisions.setdefault(
            key,
            {"texts": {existing.text}, "provenance": list(existing.provenance)},
        )
        collision["texts"].add(normalized)
        collision["provenance"].append({**provenance, "text": normalized})
        return
    existing.merge(
        kind=kind,
        county=county,
        gloss=gloss,
        source=source,
        category=category,
        provenance=provenance,
        lexeme_id=lexeme_id,
        qa_state=qa_state,
    )


def load_runtime_catalog() -> tuple[list[Any], list[dict[str, Any]]]:
    spec = importlib.util.spec_from_file_location("production_audio", RUNTIME_BUILDER)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load {RUNTIME_BUILDER}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module.build_catalog()


def collect_phrase_families(
    add,
) -> tuple[int, int, set[str]]:
    observations = 0
    unique_texts: set[str] = set()
    family_lexemes: set[str] = set()
    for path in sorted((ROOT / "content").glob("*/phrase-families/*.json")):
        payload = load_json(path)
        family_id = payload.get("id", path.stem)
        lexeme_id = payload.get("lexeme_id")
        county = payload.get("county") or path.parent.parent.name
        family_lexemes.add(str(lexeme_id or ""))
        for index, member in enumerate(payload.get("members", [])):
            text = member.get("text")
            if not isinstance(text, str):
                continue
            observations += 1
            unique_texts.add(normalize_text(text))
            add(
                text=text,
                kind="phrase" if " " in normalize_text(text) else "headword",
                category="phrase_family",
                source=str(member.get("source", "phrase-family")),
                county=county,
                gloss=str(member.get("gloss", "")),
                lexeme_id=lexeme_id,
                qa_state=str(member.get("qa_state", "capture_unreviewed")),
                provenance={
                    "path": relative(path),
                    "locator": f"members[{index}]",
                    "family_id": family_id,
                    "member_id": member.get("id"),
                    "morphology": member.get("morphology"),
                    "invented": bool(member.get("invented", False)),
                    "attested_in": member.get("attested_in", []),
                    "place_note": member.get("place_note"),
                },
            )
    return observations, len(unique_texts), family_lexemes - {""}


def build_authoring_slots(atlas: dict[str, Any], family_lexemes: set[str]) -> list[dict[str, Any]]:
    words: dict[str, dict[str, Any]] = {}
    for county, payload in atlas.get("counties", {}).items():
        for index, word in enumerate(payload.get("words", []), start=1):
            text = normalize_text(str(word.get("ga", "")))
            key = slug(text)
            if not key:
                continue
            words.setdefault(
                key,
                {
                    "text": text,
                    "slug": key,
                    "gloss": word.get("en", ""),
                    "counties": set(),
                    "atlas_slots": [],
                },
            )
            words[key]["counties"].add(county)
            words[key]["atlas_slots"].append(f"{county}:{index}")

    slots: list[dict[str, Any]] = []
    for word in sorted(words.values(), key=lambda item: item["slug"]):
        covered = lexeme_id(word["text"]) in family_lexemes
        for band, description in EXPANSION_BANDS:
            slots.append(
                {
                    "slot_id": f"{word['slug']}:{band}",
                    "band": band,
                    "description": description,
                    "text": None,
                    "status": "partially_covered" if covered else "needs_authored_text",
                    "citation_form": word["text"],
                    "gloss": word["gloss"],
                    "counties": sorted(word["counties"]),
                    "atlas_slots": sorted(word["atlas_slots"]),
                    "provenance": {"path": relative(ATLAS_PATH)},
                }
            )
    return slots


def build_plan(batch_size: int = DEFAULT_BATCH_SIZE) -> dict[str, Any]:
    candidates: dict[str, Candidate] = {}
    collisions: dict[str, dict[str, Any]] = {}

    inventory = load_json(INVENTORY_PATH)
    for index, entry in enumerate(inventory.get("entries", [])):
        add_candidate(
            candidates,
            collisions,
            text=str(entry.get("text", "")),
            kind=str(entry.get("kind", "legacy")),
            category="canonical_inventory",
            source=str(entry.get("source", "canonical-inventory")),
            county=None,
            gloss=str(entry.get("gloss", "")),
            qa_state=str(entry.get("qa_state", "capture_unreviewed")),
            provenance={
                "path": relative(INVENTORY_PATH),
                "locator": f"entries[{index}]",
                "counties": entry.get("counties", []),
            },
        )

    runtime_lines, dynamic = load_runtime_catalog()
    for line in runtime_lines:
        add_candidate(
            candidates,
            collisions,
            text=line.text,
            kind=line.kind,
            category="runtime_catalog",
            source="runtime-catalog",
            provenance={
                "path": relative(RUNTIME_BUILDER),
                "sources": sorted(line.sources),
            },
        )

    family_observations, family_unique, family_lexemes = collect_phrase_families(
        lambda **kwargs: add_candidate(candidates, collisions, **kwargs)
    )

    atlas = load_json(ATLAS_PATH)
    slots = build_authoring_slots(atlas, family_lexemes)
    atlas_rows = sum(len(payload.get("words", [])) for payload in atlas.get("counties", {}).values())
    for county, payload in atlas.get("counties", {}).items():
        for index, word in enumerate(payload.get("words", []), start=1):
            add_candidate(
                candidates,
                collisions,
                text=str(word.get("ga", "")),
                kind="headword",
                category="atlas_coverage",
                source="atlas",
                county=county,
                gloss=str(word.get("en", "")),
                provenance={
                    "path": relative(ATLAS_PATH),
                    "locator": f"counties.{county}.words[{index - 1}]",
                    "coverage_role": "planned_headword_slot",
                },
            )

    bundled_slugs = set()
    if MANIFEST_PATH.exists():
        bundled_slugs = {
            str(line.get("slug")) for line in load_json(MANIFEST_PATH).get("lines", [])
        }

    exported = [candidate.export(bundled_slugs) for candidate in candidates.values()]
    exported.sort(key=lambda row: (row["priority"], KIND_PRIORITY.get(row["kind"], 99), row["slug"]))
    pending = [row for row in exported if row["capture_state"] == "pending_capture"]

    batches: list[dict[str, Any]] = []
    for offset in range(0, len(pending), batch_size):
        rows = pending[offset : offset + batch_size]
        number = offset // batch_size + 1
        batches.append(
            {
                "id": f"batch-{number:03d}",
                "entry_count": len(rows),
                "text_characters": sum(len(row["text"]) for row in rows),
                "slugs": [row["slug"] for row in rows],
                "status": "pending_capture",
            }
        )

    snapshot = source_snapshot(relevant_source_paths())
    run_fingerprint = hashlib.sha256(
        json.dumps(
            {
                "snapshot": snapshot,
                "batch_size": batch_size,
                "expansion_bands": EXPANSION_BANDS,
            },
            sort_keys=True,
        ).encode()
    ).hexdigest()[:12]

    return {
        "schema_version": 1,
        "campaign": {
            "id": f"irish-bulk-capture-{run_fingerprint}",
            "mode": "temporary_pre_expiry_capture",
            "provider": "ElevenLabs",
            "voice": {"name": "Irish Cultural Guide", "id": "NPWroowF4phQhaPWjXPj"},
            "model_id": "eleven_v3",
            "language_code": "ga",
            "qa_policy": "Capture may be generated_unreviewed; native-speaker and pedagogue review remain later release gates.",
            "bind_rule": "Launch exercises may only set audioText to strings present in the canonical inventory after review and promotion.",
            "safe_default": "dry_run_no_network",
        },
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_snapshot": snapshot,
        "counts": {
            "reusable_unique_corpus": len(exported),
            "pending_capture_requests": len(pending),
            "already_bundled": len(exported) - len(pending),
            "runtime_catalog_lines": len(runtime_lines),
            "dynamic_exclusions": len(dynamic),
            "atlas_rows": atlas_rows,
            "atlas_unique_headwords": len({row["citation_form"] for row in slots}),
            "phrase_family_observations": family_observations,
            "phrase_family_unique_texts": family_unique,
            "phrase_family_lexemes": len(family_lexemes),
            "authored_expansion_slots": len(slots),
            "slug_collisions": len(collisions),
        },
        "entries": exported,
        "batches": batches,
        "authoring_slots": slots,
        "slug_collisions": {
            key: {
                "texts": sorted(value["texts"]),
                "provenance": value["provenance"],
            }
            for key, value in sorted(collisions.items())
        },
    }


def inventory_payload(plan: dict[str, Any], rows: list[dict[str, Any]]) -> dict[str, Any]:
    counts = Counter(row["kind"] for row in rows)
    return {
        "schema_version": 1,
        "generated_at": plan["generated_at"],
        "campaign": plan["campaign"],
        "bind_rule": plan["campaign"]["bind_rule"],
        "voice": plan["campaign"]["voice"],
        "counts": {
            "total": len(rows),
            "headword": counts.get("headword", 0),
            "phrase": counts.get("phrase", 0),
            "conversation": counts.get("conversation", 0),
            "pending_generation": len(rows),
        },
        "entries": rows,
    }


def write_plan(plan: dict[str, Any], output_dir: Path) -> None:
    batches_dir = output_dir / "batches"
    batches_dir.mkdir(parents=True, exist_ok=True)
    output_dir.mkdir(parents=True, exist_ok=True)
    rows_by_slug = {row["slug"]: row for row in plan["entries"]}
    for batch in plan["batches"]:
        rows = [rows_by_slug[slug_id] for slug_id in batch["slugs"]]
        batch["inventory_path"] = relative(batches_dir / f"{batch['id']}.inventory.json")
        (batches_dir / f"{batch['id']}.inventory.json").write_text(
            json.dumps(inventory_payload(plan, rows), ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    (output_dir / "plan.json").write_text(
        json.dumps(plan, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (output_dir / "authoring-slots.json").write_text(
        json.dumps(plan["authoring_slots"], ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    first_batch = batches_dir / "batch-001.inventory.json"
    (output_dir / "README.md").write_text(
        "# Irish bulk capture run\n\n"
        "This is a generation-ready, pre-expiry capture plan. It was created without network access. "
        "Every batch is inventory-shaped and can be previewed with:\n\n"
        "```bash\n"
        f"python3 {RUNTIME_BUILDER} --dry-run --from-inventory "
        f"--inventory-path {first_batch}\n"
        "```\n\n"
        "After explicit scope approval, run one batch at a time without `--dry-run`. "
        "The existing builder skips MP3s already present, so an interrupted batch can be resumed. "
        "Generated clips remain `generated_unreviewed`; this plan does not approve teaching audio.\n",
        encoding="utf-8",
    )


def resume_report(run_dir: Path) -> dict[str, Any]:
    plan = load_json(run_dir / "plan.json")
    audio_dir = ROOT / "ios/AnTuras/Resources/Audio"
    batches = []
    for batch in plan.get("batches", []):
        missing = [
            slug_id
            for slug_id in batch.get("slugs", [])
            if not (audio_dir / f"{slug_id}.mp3").exists()
        ]
        batches.append(
            {
                "id": batch["id"],
                "entry_count": batch["entry_count"],
                "missing_clips": len(missing),
                "status": "complete" if not missing else "pending_capture",
            }
        )
    return {"campaign": plan.get("campaign", {}), "batches": batches}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview counts and batches; this is also the default mode",
    )
    parser.add_argument(
        "--write-plan",
        type=Path,
        help="Write plan.json, authoring slots, and batch inventories to this directory",
    )
    parser.add_argument(
        "--batch-size", type=int, default=DEFAULT_BATCH_SIZE, help="Requests per batch"
    )
    parser.add_argument(
        "--include-present",
        action="store_true",
        help="Include already-bundled lines in batches for a complete export",
    )
    parser.add_argument("--resume", type=Path, help="Report resumable state for a prior plan")
    parser.add_argument("--json", action="store_true", help="Print the preview as JSON")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.batch_size <= 0:
        raise SystemExit("--batch-size must be positive")
    if args.resume:
        report = resume_report(args.resume)
        print(json.dumps(report, ensure_ascii=False, indent=2) if args.json else report)
        return 0

    plan = build_plan(args.batch_size)
    if args.include_present:
        all_rows = plan["entries"]
        batches: list[dict[str, Any]] = []
        for offset in range(0, len(all_rows), args.batch_size):
            rows = all_rows[offset : offset + args.batch_size]
            batches.append(
                {
                    "id": f"batch-{offset // args.batch_size + 1:03d}",
                    "entry_count": len(rows),
                    "text_characters": sum(len(row["text"]) for row in rows),
                    "slugs": [row["slug"] for row in rows],
                    "status": "reference_or_capture",
                }
            )
        plan["batches"] = batches
        plan["counts"]["exported_batch_requests"] = len(all_rows)
    else:
        plan["counts"]["exported_batch_requests"] = plan["counts"]["pending_capture_requests"]

    if args.write_plan:
        write_plan(plan, args.write_plan)

    preview = {
        "campaign": plan["campaign"],
        "counts": plan["counts"],
        "batches": [
            {
                "id": batch["id"],
                "entry_count": batch["entry_count"],
                "text_characters": batch["text_characters"],
            }
            for batch in plan["batches"]
        ],
        "output_dir": str(args.write_plan) if args.write_plan else None,
    }
    if args.json:
        print(json.dumps(preview, ensure_ascii=False, indent=2))
    else:
        print(f"Campaign: {plan['campaign']['id']} (dry-run; no network)")
        for key, value in plan["counts"].items():
            print(f"{key}: {value}")
        for batch in preview["batches"]:
            print(
                f"{batch['id']}: {batch['entry_count']} requests, "
                f"{batch['text_characters']} text chars"
            )
        if args.write_plan:
            print(f"Wrote generation-ready plan: {args.write_plan}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
