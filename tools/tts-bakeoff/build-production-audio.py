#!/usr/bin/env python3
"""Build and verify the app's bundled ElevenLabs speech catalog.

Catalog sources (union, deduped by slug):
- legacy chapter JSON speech / listen / lens / seanfhocal / gloss lines
- Swift AtlasAudioLine / SoundRow / Self(ga:) literals
- county draft packs and bundled CountyStories / Fixtures packs
- content/audio/irish-inventory-v1.json (preferred teaching inventory)

Personalized ``{name}`` lines remain dynamic exclusions.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
RESOURCE_DIR = ROOT / "ios/AnTuras/Resources"
AUDIO_DIR = RESOURCE_DIR / "Audio"
MANIFEST_PATH = AUDIO_DIR / "manifest.json"
INVENTORY_PATH = ROOT / "content/audio/irish-inventory-v1.json"
VOICE_ID = "NPWroowF4phQhaPWjXPj"
VOICE_NAME = "Irish Cultural Guide"
MODEL_ID = "eleven_v3"
LANGUAGE_CODE = "ga"
OUTPUT_FORMAT = "mp3_44100_192"
CHAPTERS = ("chapter1.json", "chapter2.json", "chapter3.json")
SWIFT_LITERAL_AUDIO = re.compile(
    r'(?:AtlasAudioLine\(ga:|SoundRow\(text:|Self\(ga:)\s*"([^"\\]+)"'
)
VALID_KINDS = ("headword", "phrase", "conversation", "legacy")


@dataclass
class CatalogLine:
    slug: str
    text: str
    sources: set[str] = field(default_factory=set)
    kind: str = "legacy"


def slug(text: str) -> str:
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


def load_env() -> None:
    path = ROOT / ".env"
    if not path.exists():
        return
    for raw_line in path.read_text().splitlines():
        if "=" not in raw_line or raw_line.lstrip().startswith("#"):
            continue
        key, value = raw_line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


def county_pack_paths() -> list[Path]:
    paths: list[Path] = []
    paths.extend(sorted((ROOT / "content").glob("*/*.pack.draft.json")))
    stories = RESOURCE_DIR / "CountyStories"
    if stories.exists():
        paths.extend(sorted(stories.glob("*.json")))
    fixtures = RESOURCE_DIR / "Fixtures"
    if fixtures.exists():
        paths.extend(sorted(fixtures.glob("*.json")))
    return paths


def walk_pack_audio(value: object, add, source: str) -> None:
    if isinstance(value, list):
        for child in value:
            walk_pack_audio(child, add, source)
        return
    if not isinstance(value, dict):
        return

    if value.get("kind") == "audio" and isinstance(value.get("value"), str):
        text = value["value"].strip()
        kind = "phrase" if (" " in text or any(ch in text for ch in ".!?")) else "headword"
        add(text, f"{source}:resource", kind)

    audio_text = value.get("audioText")
    if isinstance(audio_text, str) and audio_text.strip():
        text = audio_text.strip()
        kind = "conversation" if "?" in text else (
            "phrase" if " " in text else "headword"
        )
        add(text, f"{source}:audioText", kind)

    for child in value.values():
        walk_pack_audio(child, add, source)


def build_catalog(
    *,
    from_inventory: bool = False,
    kinds: set[str] | None = None,
) -> tuple[list[CatalogLine], list[dict[str, object]]]:
    catalog: dict[str, CatalogLine] = {}
    dynamic: dict[str, set[str]] = {}

    def add(text: object, source: str, kind: str = "legacy") -> None:
        if not isinstance(text, str) or not text.strip():
            return
        text = text.strip()
        if "{name}" in text:
            dynamic.setdefault(text, set()).add(source)
            return
        key = slug(text)
        if not key:
            return
        if kinds is not None and kind not in kinds:
            # Still record if an existing entry of an allowed kind already owns the slug
            existing = catalog.get(key)
            if existing is None or (kinds is not None and existing.kind not in kinds):
                return
        line = catalog.setdefault(key, CatalogLine(slug=key, text=text, kind=kind))
        line.sources.add(source)
        # Prefer more specific teaching kinds over legacy when merging
        priority = {"headword": 3, "phrase": 2, "conversation": 2, "legacy": 1}
        if priority.get(kind, 0) > priority.get(line.kind, 0):
            line.kind = kind
            line.text = text

    def walk_chapter(value: object, source: str) -> None:
        if isinstance(value, list):
            for child in value:
                walk_chapter(child, source)
            return
        if not isinstance(value, dict):
            return

        spoken = value.get("s")
        if (
            isinstance(spoken, str)
            and "t" not in value
            and any(key in value for key in ("g", "reaction", "who"))
        ):
            add(spoken, f"{source}:speech", "legacy")
        if isinstance(value.get("say"), str):
            add(value["say"], f"{source}:listen", "legacy")
        if value.get("type") in ("lens", "seanfhocal"):
            add(value.get("ga"), f"{source}:{value['type']}", "legacy")
        if all(isinstance(value.get(key), str) for key in ("t", "g", "s")):
            add(value["t"], f"{source}:gloss", "legacy")

        for child in value.values():
            walk_chapter(child, source)

    if from_inventory:
        if not INVENTORY_PATH.exists():
            raise RuntimeError(
                f"Missing inventory {INVENTORY_PATH}; run assemble_irish_inventory.py first"
            )
        inventory = json.loads(INVENTORY_PATH.read_text())
        for entry in inventory.get("entries", []):
            text = entry.get("text")
            kind = entry.get("kind", "legacy")
            counties = ",".join(entry.get("counties") or []) or "inventory"
            add(text, f"inventory:{kind}:{counties}", kind)
    else:
        for filename in CHAPTERS:
            path = RESOURCE_DIR / filename
            if path.exists():
                walk_chapter(json.loads(path.read_text()), filename)

        for swift_path in sorted((ROOT / "ios/AnTuras").glob("*.swift")):
            for match in SWIFT_LITERAL_AUDIO.finditer(swift_path.read_text()):
                add(match.group(1), f"{swift_path.name}:literal", "legacy")

        for pack_path in county_pack_paths():
            rel = pack_path.relative_to(ROOT)
            root = json.loads(pack_path.read_text())
            pack = root.get("pack", root)
            walk_pack_audio(pack, add, str(rel))

        if INVENTORY_PATH.exists():
            inventory = json.loads(INVENTORY_PATH.read_text())
            for entry in inventory.get("entries", []):
                text = entry.get("text")
                kind = entry.get("kind", "legacy")
                counties = ",".join(entry.get("counties") or []) or "inventory"
                add(text, f"inventory:{kind}:{counties}", kind)

    if kinds is not None:
        catalog = {
            key: line for key, line in catalog.items() if line.kind in kinds
        }

    dynamic_items = [
        {
            "text": text,
            "sources": sorted(sources),
            "reason": "Personalized learner names require a reviewed recording strategy.",
        }
        for text, sources in sorted(dynamic.items())
    ]
    return sorted(catalog.values(), key=lambda item: item.slug), dynamic_items


def verify_voice(session: Any) -> dict[str, object]:
    response = session.get(
        f"https://api.elevenlabs.io/v1/voices/{VOICE_ID}", timeout=30
    )
    response.raise_for_status()
    voice = response.json()
    actual_name = voice.get("name")
    if actual_name != VOICE_NAME:
        raise RuntimeError(
            f"Voice {VOICE_ID} is named {actual_name!r}, expected {VOICE_NAME!r}"
        )
    return voice


def generate_clip(session: Any, line: CatalogLine, target: Path) -> None:
    response = session.post(
        f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}",
        params={"output_format": OUTPUT_FORMAT},
        json={
            "text": line.text,
            "model_id": MODEL_ID,
            "language_code": LANGUAGE_CODE,
        },
        timeout=120,
    )
    response.raise_for_status()
    content_type = response.headers.get("content-type", "")
    if "audio" not in content_type and not response.content.startswith(b"ID3"):
        raise RuntimeError(
            f"Unexpected response for {line.slug}: {content_type or 'unknown content type'}"
        )
    temporary = target.with_suffix(".mp3.part")
    temporary.write_bytes(response.content)
    temporary.replace(target)


def probe(path: Path) -> dict[str, object]:
    command = [
        "ffprobe",
        "-v",
        "error",
        "-show_entries",
        "format=duration,format_name:stream=codec_name,sample_rate,channels",
        "-of",
        "json",
        str(path),
    ]
    try:
        result = subprocess.run(command, check=True, capture_output=True, text=True)
    except FileNotFoundError as error:
        raise RuntimeError("ffprobe is required to validate generated audio") from error
    return json.loads(result.stdout)


def file_record(line: CatalogLine, path: Path) -> dict[str, object]:
    media = probe(path)
    streams = media.get("streams") or []
    stream = streams[0] if streams else {}
    format_info = media.get("format") or {}
    duration = float(format_info.get("duration", 0))
    if stream.get("codec_name") != "mp3" or duration <= 0:
        raise RuntimeError(f"Invalid MP3 output: {path}")
    return {
        "slug": line.slug,
        "text": line.text,
        "sources": sorted(line.sources),
        "kind": line.kind,
        "file": path.name,
        "bytes": path.stat().st_size,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "duration_seconds": round(duration, 3),
        "codec": stream.get("codec_name"),
        "sample_rate_hz": int(stream.get("sample_rate", 0)),
        "channels": stream.get("channels"),
        "qa_state": "generated_unreviewed",
    }


def merge_manifest_records(
    new_records: list[dict[str, object]],
    dynamic: list[dict[str, object]],
    *,
    replace_all: bool,
) -> list[dict[str, object]]:
    """Merge newly generated/verified records into the existing manifest.

    Inventory batch runs must not delete legacy chapter clips that are still
    bundled on disk. Full catalog runs (no --kind / replace_all) rewrite fully.
    """
    by_slug: dict[str, dict[str, object]] = {}
    if not replace_all and MANIFEST_PATH.exists():
        existing = json.loads(MANIFEST_PATH.read_text())
        for line in existing.get("lines", []):
            by_slug[str(line["slug"])] = line
    for record in new_records:
        by_slug[str(record["slug"])] = record
    records = sorted(by_slug.values(), key=lambda item: str(item["slug"]))
    write_manifest(records, dynamic)
    return records


def write_manifest(
    records: list[dict[str, object]], dynamic: list[dict[str, object]]
) -> None:
    manifest = {
        "schema_version": 2,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "provider": "ElevenLabs",
        "voice": {"name": VOICE_NAME, "id": VOICE_ID},
        "model_id": MODEL_ID,
        "language_code": LANGUAGE_CODE,
        "output_format": OUTPUT_FORMAT,
        "slug_rule": "lowercase; fada vowels double; non-ASCII letters become word breaks",
        "qa_policy": "Generated clips require Irish-language and editorial listening review before release sign-off.",
        "lines": records,
        "dynamic_exclusions": dynamic,
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")


def verify_manifest(
    records: list[dict[str, object]], dynamic: list[dict[str, object]]
) -> None:
    if not MANIFEST_PATH.exists():
        raise RuntimeError(f"Missing production manifest: {MANIFEST_PATH}")
    manifest = json.loads(MANIFEST_PATH.read_text())
    expected_metadata = {
        "schema_version": 2,
        "provider": "ElevenLabs",
        "voice": {"name": VOICE_NAME, "id": VOICE_ID},
        "model_id": MODEL_ID,
        "language_code": LANGUAGE_CODE,
        "output_format": OUTPUT_FORMAT,
    }
    for key, expected in expected_metadata.items():
        if manifest.get(key) != expected:
            raise RuntimeError(
                f"Manifest {key} is {manifest.get(key)!r}, expected {expected!r}"
            )
    # Compare without requiring kind field on older records
    def normalize(lines: list[dict[str, object]]) -> list[dict[str, object]]:
        out = []
        for line in lines:
            item = {k: v for k, v in line.items() if k != "kind"}
            out.append(item)
        return out

    if normalize(manifest.get("lines") or []) != normalize(records):
        raise RuntimeError("Manifest clip records do not match the bundled catalog")
    if manifest.get("dynamic_exclusions") != dynamic:
        raise RuntimeError("Manifest dynamic exclusions do not match the speech catalog")


def write_checksum_archive(records: list[dict[str, object]], label: str) -> Path:
    archive_dir = ROOT / "content/audio/archive"
    archive_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    path = archive_dir / f"checksums-{label}-{stamp}.json"
    payload = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "label": label,
        "clip_count": len(records),
        "clips": [
            {
                "slug": r["slug"],
                "text": r["text"],
                "sha256": r["sha256"],
                "bytes": r["bytes"],
                "duration_seconds": r["duration_seconds"],
            }
            for r in records
        ],
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    return path


def update_inventory_qa_states(present_slugs: set[str]) -> None:
    if not INVENTORY_PATH.exists():
        return
    inventory = json.loads(INVENTORY_PATH.read_text())
    for entry in inventory.get("entries", []):
        if entry.get("slug") in present_slugs:
            if entry.get("qa_state") == "pending_generation":
                entry["qa_state"] = "generated_unreviewed"
    inventory["counts"] = {
        "total": len(inventory.get("entries", [])),
        "headword": sum(1 for e in inventory["entries"] if e["kind"] == "headword"),
        "phrase": sum(1 for e in inventory["entries"] if e["kind"] == "phrase"),
        "conversation": sum(
            1 for e in inventory["entries"] if e["kind"] == "conversation"
        ),
        "already_generated": sum(
            1
            for e in inventory["entries"]
            if e["qa_state"] in ("generated_unreviewed", "spot_flagged", "qa_passed")
        ),
        "pending_generation": sum(
            1 for e in inventory["entries"] if e["qa_state"] == "pending_generation"
        ),
    }
    inventory["generated_at"] = datetime.now(timezone.utc).isoformat()
    INVENTORY_PATH.write_text(json.dumps(inventory, ensure_ascii=False, indent=2) + "\n")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="List catalog state only")
    parser.add_argument("--force", action="store_true", help="Regenerate existing clips")
    parser.add_argument(
        "--verify-only", action="store_true", help="Validate the complete existing catalog"
    )
    parser.add_argument(
        "--from-inventory",
        action="store_true",
        help="Build catalog only from content/audio/irish-inventory-v1.json",
    )
    parser.add_argument(
        "--kind",
        action="append",
        choices=VALID_KINDS,
        help="Limit generation to one or more kinds (repeatable)",
    )
    parser.add_argument(
        "--missing-only",
        action="store_true",
        help="With --dry-run, print only missing clips",
    )
    parser.add_argument(
        "--archive-checksums",
        action="store_true",
        help="Write content/audio/archive checksum snapshot after run",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    load_env()
    kinds = set(args.kind) if args.kind else None
    lines, dynamic = build_catalog(from_inventory=args.from_inventory, kinds=kinds)
    AUDIO_DIR.mkdir(parents=True, exist_ok=True)

    missing = [line for line in lines if not (AUDIO_DIR / f"{line.slug}.mp3").exists()]
    chars = sum(len(line.text) for line in missing)
    print(
        f"Catalog: {len(lines)} static clips; {len(dynamic)} dynamic exclusions; "
        f"{len(missing)} missing (~{chars} chars)"
    )

    if args.dry_run:
        shown = missing if args.missing_only else lines
        for line in shown:
            state = "present" if (AUDIO_DIR / f"{line.slug}.mp3").exists() else "missing"
            print(f"{state:7} [{line.kind}] {line.slug}: {line.text}")
        return 0

    key = os.environ.get("ELEVENLABS_API_KEY")
    if not args.verify_only and not key:
        raise SystemExit("ELEVENLABS_API_KEY is not set")

    session = None
    if not args.verify_only:
        try:
            import requests
        except ModuleNotFoundError as error:
            raise SystemExit(
                "Install the requests package to generate audio; verify-only mode has no network dependency."
            ) from error
        session = requests.Session()
        session.headers.update({"xi-api-key": key, "Content-Type": "application/json"})
        verify_voice(session)

    records: list[dict[str, object]] = []
    for index, line in enumerate(lines, start=1):
        target = AUDIO_DIR / f"{line.slug}.mp3"
        if args.verify_only and not target.exists():
            raise RuntimeError(f"Missing production clip: {target.name}")
        if not args.verify_only and (args.force or not target.exists()):
            print(f"[{index}/{len(lines)}] generate {line.slug}", flush=True)
            generate_clip(session, line, target)
            time.sleep(0.08)
        records.append(file_record(line, target))

    replace_all = kinds is None and not args.from_inventory
    if args.verify_only and replace_all:
        verify_manifest(records, dynamic)
    else:
        merged = merge_manifest_records(
            records, dynamic, replace_all=replace_all and not args.from_inventory
        )
        if args.from_inventory or kinds is not None:
            # Keep legacy clips: merge inventory/batch into full on-disk set
            all_mp3 = {
                path.stem: path for path in AUDIO_DIR.glob("*.mp3")
            }
            # Rebuild manifest from all known records + any on-disk leftovers already in merged
            records = merged
        update_inventory_qa_states({str(r["slug"]) for r in records})
        if args.archive_checksums:
            label = "+".join(sorted(kinds)) if kinds else (
                "inventory" if args.from_inventory else "full"
            )
            path = write_checksum_archive(records, label)
            print(f"Checksum archive: {path}")

    expected = {record["file"] for record in records}
    extras = sorted(path.name for path in AUDIO_DIR.glob("*.mp3") if path.name not in expected)
    if extras and replace_all and not args.from_inventory:
        print("Unreferenced MP3 files: " + ", ".join(extras), file=sys.stderr)
    print(f"Verified {len(records)} MP3 clips; manifest: {MANIFEST_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
