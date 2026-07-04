#!/usr/bin/env python3
"""Chapter 1 TTS bake-off — generate candidates, review by ear, install your picks."""

from __future__ import annotations

import argparse
import base64
import json
import os
import shutil
import subprocess
import sys
import time
import wave
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "ios/AnTuras/Resources/Audio/manifest.json"
CANDIDATES = Path(__file__).resolve().parent / "candidates"
WINNERS = Path(__file__).resolve().parent / "winners.json"
REVIEW_HTML = Path(__file__).resolve().parent / "review.html"
OUTPUT = ROOT / "ios/AnTuras/Resources/Audio"

ELEVEN_Daire = "JBFqnCBsd6RMkjVDRZzb"  # George
ELEVEN_BRID = "cgSgspJ2msm6clMCkdW9"  # Jessica
GEMINI_3_MODEL = "gemini-3.1-flash-tts-preview"
GEMINI_2_MODEL = "gemini-2.5-flash-preview-tts"
GEMINI_Daire = "Charon"
GEMINI_BRID = "Leda"
ABAIR_VOICE = "ga_MU_cmg_piper"  # public API; Connemara is web-demo only

# Order shown in review.html — pronunciation-critical lines first.
PRIORITY_SLUGS = ("feear", "seaan", "mac", "dearthaair", "deirfiuur", "cill-ala")

PROVIDERS = ("abair", "elevenlabs", "gemini-3-flash", "gemini-2.5-flash")


def load_env() -> None:
    env_path = ROOT / ".env"
    if not env_path.exists():
        return
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


def load_lines() -> list[dict]:
    return json.loads(MANIFEST.read_text())["lines"]


def ensure_mp3(path: Path) -> Path:
    if path.suffix == ".mp3":
        return path
    mp3 = path.with_suffix(".mp3")
    if mp3.exists():
        return mp3
    subprocess.run(
        [
            "ffmpeg", "-y", "-loglevel", "error", "-i", str(path),
            "-codec:a", "libmp3lame", "-qscale:a", "2", str(mp3),
        ],
        check=True,
    )
    return mp3


def write_wav(path: Path, pcm: bytes, rate: int = 24000) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(rate)
        wf.writeframes(pcm)


def gemini_prompt(text: str, speaker: str) -> str:
    if speaker == "brid":
        persona = "bright young female Connacht Irish voice, quick but clear"
    else:
        persona = "unhurried male west-of-Ireland Connacht Irish voice"
    if text.strip().lower() in ("féar", "fear", "seán", "sean"):
        return (
            f'Irish minimal pair: speak exactly "{text}" as written in Connacht Irish. '
            f"The fada vowel length must be audible and correct. Do not translate."
        )
    if len(text.split()) == 1:
        return (
            f'The Irish word "{text}", pronounced in Connacht Irish. '
            f"Speak exactly as written in a {persona}. Do not translate."
        )
    return (
        f"Speak this Irish phrase exactly as written, in a {persona}. "
        f'Do not translate. Text: "{text}"'
    )


def generate_abair(line: dict, out: Path) -> None:
    resp = requests.get(
        "https://synthesis.abair.ie/api/synthesise",
        params={"input": line["text"], "voice": ABAIR_VOICE, "normalise": "true"},
        timeout=60,
    )
    resp.raise_for_status()
    audio_b64 = resp.json().get("audioContent")
    if not audio_b64:
        raise RuntimeError(f"ABAIR returned no audio for {line['slug']}")
    wav = out.with_suffix(".wav")
    wav.parent.mkdir(parents=True, exist_ok=True)
    wav.write_bytes(base64.b64decode(audio_b64))
    ensure_mp3(wav)


def generate_elevenlabs(line: dict, out: Path, api_key: str) -> None:
    voice = ELEVEN_BRID if line["speaker"] == "brid" else ELEVEN_Daire
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128"
    resp = requests.post(
        url,
        headers={"xi-api-key": api_key, "Content-Type": "application/json"},
        json={"text": line["text"], "model_id": "eleven_v3", "language_code": "gle"},
        timeout=120,
    )
    resp.raise_for_status()
    mp3 = out.with_suffix(".mp3")
    mp3.parent.mkdir(parents=True, exist_ok=True)
    mp3.write_bytes(resp.content)


def generate_gemini(line: dict, out: Path, api_key: str, model: str) -> None:
    from google import genai
    from google.genai import types

    client = genai.Client(api_key=api_key)
    voice = GEMINI_BRID if line["speaker"] == "brid" else GEMINI_Daire
    last_error: Exception | None = None
    response = None
    for attempt in range(8):
        try:
            response = client.models.generate_content(
                model=model,
                contents=gemini_prompt(line["text"], line["speaker"]),
                config=types.GenerateContentConfig(
                    response_modalities=["AUDIO"],
                    speech_config=types.SpeechConfig(
                        voice_config=types.VoiceConfig(
                            prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name=voice)
                        )
                    ),
                ),
            )
            break
        except Exception as exc:
            last_error = exc
            if "429" in str(exc) or "RESOURCE_EXHAUSTED" in str(exc):
                delay = 65 if attempt < 3 else 90
                print(f"  rate-limited, waiting {delay}s …")
                time.sleep(delay)
                continue
            raise
    else:
        raise last_error or RuntimeError("Gemini TTS failed")

    content = response.candidates[0].content
    if content is None or not content.parts:
        raise RuntimeError(f"Gemini returned no audio for {line['slug']}")
    data = content.parts[0].inline_data.data
    pcm = base64.b64decode(data) if isinstance(data, str) else data
    wav = out.with_suffix(".wav")
    write_wav(wav, pcm)
    ensure_mp3(wav)


GENERATORS = {
    "abair": lambda line, out, _: generate_abair(line, out),
    "elevenlabs": lambda line, out, key: generate_elevenlabs(line, out, key),
    "gemini-3-flash": lambda line, out, key: generate_gemini(line, out, key, GEMINI_3_MODEL),
    "gemini-2.5-flash": lambda line, out, key: generate_gemini(line, out, key, GEMINI_2_MODEL),
}


def migrate_legacy_gemini() -> None:
    """Move first-run `candidates/gemini/` into `gemini-2.5-flash/`."""
    legacy = CANDIDATES / "gemini"
    target = CANDIDATES / "gemini-2.5-flash"
    if not legacy.is_dir():
        return
    target.mkdir(parents=True, exist_ok=True)
    for path in legacy.iterdir():
        dest = target / path.name
        if not dest.exists():
            shutil.move(str(path), dest)
    if not any(legacy.iterdir()):
        legacy.rmdir()


def generate_all(providers: list[str], force: bool = False) -> None:
    load_env()
    migrate_legacy_gemini()
    eleven_key = os.environ.get("ELEVENLABS_API_KEY")
    gemini_key = os.environ.get("GEMINI_API_KEY")
    if not eleven_key or not gemini_key:
        sys.exit("ELEVENLABS_API_KEY and GEMINI_API_KEY required in .env")

    for provider in providers:
        fn = GENERATORS.get(provider)
        if fn is None:
            sys.exit(f"Unknown provider: {provider}")

    for provider in providers:
        fn = GENERATORS[provider]
        for line in load_lines():
            slug = line["slug"]
            out = CANDIDATES / provider / slug
            mp3 = out.with_suffix(".mp3")
            if mp3.exists() and not force:
                print(f"skip {provider}/{slug}")
                continue
            print(f"gen  {provider}/{slug} …")
            try:
                key = gemini_key if provider.startswith("gemini") else eleven_key
                fn(line, out, key)
            except Exception as exc:
                print(f"FAIL {provider}/{slug}: {exc}", file=sys.stderr)
            if provider.startswith("gemini"):
                time.sleep(7)
            else:
                time.sleep(0.3)


def init_winners() -> None:
    lines = load_lines()
    data = {
        "_readme": [
            "Fill bundle_winner per line after listening in review.html.",
            "Allowed values: abair (eval only — do not ship), elevenlabs, gemini-3-flash, gemini-2.5-flash.",
            "Then run: python bakeoff.py install",
        ],
        "_meta": {
            "eleven_model": "eleven_v3 (language_code=gle)",
            "gemini_3_model": GEMINI_3_MODEL,
            "gemini_2_model": GEMINI_2_MODEL,
            "abair_voice": ABAIR_VOICE,
        },
        "lines": {
            line["slug"]: {
                "text": line["text"],
                "speaker": line["speaker"],
                "note": line.get("note"),
                "bundle_winner": None,
            }
            for line in lines
        },
    }
    WINNERS.write_text(json.dumps(data, indent=2) + "\n")
    print(f"wrote template {WINNERS}")


def review() -> None:
    migrate_legacy_gemini()
    lines = load_lines()
    priority = [l for s in PRIORITY_SLUGS for l in lines if l["slug"] == s]
    rest = [l for l in lines if l["slug"] not in PRIORITY_SLUGS]
    ordered = priority + rest

    rows: list[str] = []
    for line in ordered:
        slug = line["slug"]
        note = line.get("note", "")
        cells = [
            f'<tr class="{"priority" if slug in PRIORITY_SLUGS else ""}">',
            f'<td class="slug">{slug}</td>',
            f'<td class="irish">{line["text"]}</td>',
            f'<td class="speaker">{line["speaker"]}</td>',
        ]
        for provider in PROVIDERS:
            mp3 = CANDIDATES / provider / f"{slug}.mp3"
            if mp3.exists():
                rel = os.path.relpath(mp3, REVIEW_HTML.parent)
                cells.append(
                    f'<td><audio controls preload="none" src="{rel}"></audio></td>'
                )
            else:
                cells.append('<td class="missing">—</td>')
        if note:
            cells.append(f'<td class="note">{note}</td>')
        else:
            cells.append("<td></td>")
        cells.append("</tr>")
        rows.append("\n".join(cells))

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Chapter 1 TTS bake-off — listen &amp; pick</title>
  <style>
    body {{ font: 16px/1.5 system-ui, sans-serif; margin: 2rem; max-width: 1400px; }}
    h1 {{ font-weight: 600; }}
    .lede {{ color: #444; max-width: 70ch; }}
    table {{ border-collapse: collapse; width: 100%; margin-top: 1.5rem; }}
    th, td {{ border-bottom: 1px solid #ddd; padding: 0.6rem 0.5rem; vertical-align: top; }}
    th {{ text-align: left; font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.04em; color: #666; }}
    tr.priority {{ background: #fff8e6; }}
    td.irish {{ font-family: "Iowan Old Style", "Palatino Linotype", serif; font-size: 1.1rem; }}
    td.note {{ font-size: 0.85rem; color: #666; max-width: 16rem; }}
    td.missing {{ color: #bbb; }}
    audio {{ width: 180px; height: 32px; }}
    .providers {{ font-size: 0.9rem; color: #555; margin-top: 1rem; }}
  </style>
</head>
<body>
  <h1>Chapter 1 TTS bake-off</h1>
  <p class="lede">Listen across providers. <strong>Pronunciation beats polish.</strong>
  Priority rows are minimal-pair and fada-critical lines (*féar*/*fear*, *Seán*/*sean*).
  ABAIR is evaluation-only until TCD grants bundling rights.</p>
  <p class="providers">Providers: ABAIR ({ABAIR_VOICE}) · ElevenLabs (eleven_v3, gle) ·
  Gemini 3 ({GEMINI_3_MODEL}) · Gemini 2.5 ({GEMINI_2_MODEL})</p>
  <table>
    <thead>
      <tr>
        <th>Slug</th><th>Irish</th><th>Speaker</th>
        <th>ABAIR</th><th>ElevenLabs</th><th>Gemini 3</th><th>Gemini 2.5</th><th>Note</th>
      </tr>
    </thead>
    <tbody>
{"".join(rows)}
    </tbody>
  </table>
  <p class="lede">When done, set <code>bundle_winner</code> in
  <code>tools/tts-bakeoff/winners.json</code> and run <code>python bakeoff.py install</code>.</p>
</body>
</html>
"""
    REVIEW_HTML.write_text(html)
    print(f"wrote {REVIEW_HTML}")


def install() -> None:
    if not WINNERS.exists():
        sys.exit("Missing winners.json — run: python bakeoff.py init-winners")

    data = json.loads(WINNERS.read_text())
    OUTPUT.mkdir(parents=True, exist_ok=True)
    installed = 0
    for slug_id, row in data.get("lines", {}).items():
        provider = row.get("bundle_winner")
        if not provider:
            print(f"skip {slug_id}: no bundle_winner set")
            continue
        if provider == "abair":
            print(f"WARN {slug_id}: ABAIR cannot be bundled — pick a licensed provider", file=sys.stderr)
            continue
        src = CANDIDATES / provider / f"{slug_id}.mp3"
        if not src.exists():
            print(f"missing {src}", file=sys.stderr)
            continue
        shutil.copy2(src, OUTPUT / f"{slug_id}.mp3")
        print(f"installed {slug_id}.mp3 <= {provider}")
        installed += 1

    meta = data.get("_meta", {})
    meta["installed_count"] = installed
    data["_meta"] = meta
    WINNERS.write_text(json.dumps(data, indent=2) + "\n")
    shutil.copy2(WINNERS, OUTPUT / "winners.json")
    print(f"done — {installed} clips in {OUTPUT}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "command",
        choices=["generate", "init-winners", "review", "install"],
    )
    parser.add_argument(
        "--provider",
        action="append",
        dest="providers",
        choices=list(GENERATORS.keys()),
        help="Limit generation to these providers (repeatable)",
    )
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    if args.command == "generate":
        providers = args.providers or ["gemini-3-flash"]
        generate_all(providers, force=args.force)
    elif args.command == "init-winners":
        init_winners()
    elif args.command == "review":
        review()
    elif args.command == "install":
        install()


if __name__ == "__main__":
    main()
