#!/usr/bin/env python3
"""Build and verify the app's bundled ElevenLabs speech catalog.

The catalog is derived from the SwiftUI content that can request speech:
authored speech/reply/reaction beats, listen prompts, lenses, proverbs, glosses,
and literal AtlasAudioLine/SoundRow calls. Personalized ``{name}`` lines are
listed as dynamic exclusions because a pre-generated house voice cannot speak
an arbitrary learner name honestly.
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
VOICE_ID = "NPWroowF4phQhaPWjXPj"
VOICE_NAME = "Irish Cultural Guide"
MODEL_ID = "eleven_v3"
LANGUAGE_CODE = "ga"
OUTPUT_FORMAT = "mp3_44100_192"
CHAPTERS = ("chapter1.json", "chapter2.json", "chapter3.json")
SWIFT_LITERAL_AUDIO = re.compile(
    r'(?:AtlasAudioLine\(ga:|SoundRow\(text:|Self\(ga:)\s*"([^"\\]+)"'
)


@dataclass
class CatalogLine:
    slug: str
    text: str
    sources: set[str] = field(default_factory=set)


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


def build_catalog() -> tuple[list[CatalogLine], list[dict[str, object]]]:
    catalog: dict[str, CatalogLine] = {}
    dynamic: dict[str, set[str]] = {}

    def add(text: object, source: str) -> None:
        if not isinstance(text, str) or not text.strip():
            return
        text = text.strip()
        if "{name}" in text:
            dynamic.setdefault(text, set()).add(source)
            return
        key = slug(text)
        if not key:
            return
        line = catalog.setdefault(key, CatalogLine(slug=key, text=text))
        line.sources.add(source)

    def walk(value: object, source: str) -> None:
        if isinstance(value, list):
            for child in value:
                walk(child, source)
            return
        if not isinstance(value, dict):
            return

        spoken = value.get("s")
        # Glosses also use `s`, but there it is a rough sound hint. A real
        # speech beat/reply has a meaning or reaction and no `t` headword.
        if (
            isinstance(spoken, str)
            and "t" not in value
            and any(key in value for key in ("g", "reaction", "who"))
        ):
            add(spoken, f"{source}:speech")
        if isinstance(value.get("say"), str):
            add(value["say"], f"{source}:listen")
        if value.get("type") in ("lens", "seanfhocal"):
            add(value.get("ga"), f"{source}:{value['type']}")
        if all(isinstance(value.get(key), str) for key in ("t", "g", "s")):
            add(value["t"], f"{source}:gloss")

        for child in value.values():
            walk(child, source)

    for filename in CHAPTERS:
        walk(json.loads((RESOURCE_DIR / filename).read_text()), filename)

    for swift_path in sorted((ROOT / "ios/AnTuras").glob("*.swift")):
        for match in SWIFT_LITERAL_AUDIO.finditer(swift_path.read_text()):
            add(match.group(1), f"{swift_path.name}:literal")

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
        "file": path.name,
        "bytes": path.stat().st_size,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "duration_seconds": round(duration, 3),
        "codec": stream.get("codec_name"),
        "sample_rate_hz": int(stream.get("sample_rate", 0)),
        "channels": stream.get("channels"),
        "qa_state": "generated_unreviewed",
    }


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
    if manifest.get("lines") != records:
        raise RuntimeError("Manifest clip records do not match the bundled catalog")
    if manifest.get("dynamic_exclusions") != dynamic:
        raise RuntimeError("Manifest dynamic exclusions do not match the speech catalog")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="List catalog state only")
    parser.add_argument("--force", action="store_true", help="Regenerate existing clips")
    parser.add_argument(
        "--verify-only", action="store_true", help="Validate the complete existing catalog"
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    load_env()
    lines, dynamic = build_catalog()
    AUDIO_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Catalog: {len(lines)} static clips; {len(dynamic)} dynamic exclusions")

    if args.dry_run:
        for line in lines:
            state = "present" if (AUDIO_DIR / f"{line.slug}.mp3").exists() else "missing"
            print(f"{state:7} {line.slug}: {line.text}")
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
            # Avoid a burst of requests while keeping the build practical.
            time.sleep(0.08)
        records.append(file_record(line, target))

    expected = {record["file"] for record in records}
    extras = sorted(path.name for path in AUDIO_DIR.glob("*.mp3") if path.name not in expected)
    if extras:
        print("Unreferenced MP3 files: " + ", ".join(extras), file=sys.stderr)
    if args.verify_only:
        verify_manifest(records, dynamic)
    else:
        write_manifest(records, dynamic)
    print(f"Verified {len(records)} MP3 clips; manifest: {MANIFEST_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
