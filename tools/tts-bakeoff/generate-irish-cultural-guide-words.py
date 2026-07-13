#!/usr/bin/env python3
"""Generate a small Irish-word pronunciation set with the selected house voice."""

import json
import os
from pathlib import Path
import requests

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tools/tts-bakeoff/irish-cultural-guide-words"
VOICE_ID = "NPWroowF4phQhaPWjXPj"
ITEMS = {
    "01-farraige": "farraige",
    "02-baa": "bá",
    "03-long": "long",
    "04-aait": "áit",
    "05-caisleaan": "caisleán",
    "06-teaghlach": "teaghlach",
    "07-dearthaair": "deartháir",
    "08-ainm": "ainm",
    "09-freagair": "freagair",
    "10-ariiis": "arís",
    "11-as-maigh-eo-mee": "Is as Maigh Eo mé.",
    "12-is-mise-grainne": "Is mise Gráinne.",
    "13-ta-an-caisleaan-anseo": "Tá an caisleán anseo.",
    "14-tar-ar-ais": "Tar ar ais.",
}

def main() -> None:
    for line in (ROOT / ".env").read_text().splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip())
    api_key = os.environ.get("ELEVENLABS_API_KEY")
    if not api_key:
        raise SystemExit("ELEVENLABS_API_KEY is not set")
    OUT.mkdir(parents=True, exist_ok=True)
    metadata = {"voice_id": VOICE_ID, "model_id": "eleven_v3", "language_code": None, "items": []}
    for slug, text in ITEMS.items():
        response = requests.post(
            f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}?output_format=mp3_44100_192",
            headers={"xi-api-key": api_key, "Content-Type": "application/json"},
            # This voice is en-irish, not a Gaeilge voice; forcing `gle` is rejected.
            json={"text": text, "model_id": "eleven_v3"},
            timeout=120,
        )
        response.raise_for_status()
        target = OUT / f"{slug}.mp3"
        target.write_bytes(response.content)
        metadata["items"].append({"file": target.name, "text": text})
        print(target, flush=True)
    (OUT / "metadata.json").write_text(json.dumps(metadata, indent=2, ensure_ascii=False) + "\n")

if __name__ == "__main__":
    main()
