#!/usr/bin/env python3
"""Generate a Gaeilge-first ElevenLabs Voice Design comparison set."""

import base64
import json
import os
from pathlib import Path
import requests

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tools/tts-bakeoff/grainne-gaeilge-voice-previews"
TEXT = (
    "Is as Maigh Eo mé. Tá an bá agus an caisleán os comhair na farraige. "
    "Is mise Gráinne. Tá mo theaghlach anseo, agus tá an long ag teacht ar ais. "
    "Iarr cabhair, tabhair freagra, agus téigh go dtí an cósta."
)
DESCRIPTION = (
    "A native speaker of Irish (Gaeilge) from Connacht or Connemara, Ireland. "
    "This must be Irish-language speech, not English spoken with an Irish accent. "
    "Female, 35-50. High quality. Warm, clear, patient educational narrator for a "
    "cultural-history language app. Natural Connacht pronunciation, accurate fada "
    "vowel length, careful broad and slender consonants, relaxed conversational rhythm, "
    "and gentle authority. Do not translate, anglicise, or pronounce the text as English."
)

def main() -> None:
    for line in (ROOT / ".env").read_text().splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip())
    api_key = os.environ.get("ELEVENLABS_API_KEY")
    if not api_key:
        raise SystemExit("ELEVENLABS_API_KEY is not set")
    OUT.mkdir(parents=True, exist_ok=True)
    response = requests.post(
        "https://api.elevenlabs.io/v1/text-to-voice/design?output_format=mp3_44100_192",
        headers={"xi-api-key": api_key, "Content-Type": "application/json"},
        json={"voice_description": DESCRIPTION, "text": TEXT},
        timeout=180,
    )
    response.raise_for_status()
    metadata = {"text": TEXT, "description": DESCRIPTION, "previews": []}
    for index, preview in enumerate(response.json()["previews"], 1):
        filename = f"gaeilge-connacht-{index}.mp3"
        (OUT / filename).write_bytes(base64.b64decode(preview["audio_base_64"]))
        metadata["previews"].append({
            "file": filename,
            "generated_voice_id": preview["generated_voice_id"],
        })
        print(OUT / filename, flush=True)
    (OUT / "metadata.json").write_text(json.dumps(metadata, indent=2, ensure_ascii=False) + "\n")

if __name__ == "__main__":
    main()
