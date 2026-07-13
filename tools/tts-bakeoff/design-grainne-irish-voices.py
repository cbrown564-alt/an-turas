#!/usr/bin/env python3
"""Generate ElevenLabs Voice Design previews for the Gráinne narrator."""

import base64
import json
import os
from pathlib import Path
import requests

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tools/tts-bakeoff/grainne-irish-voice-previews"
TEXT = (
    "Clew Bay is not scenery. It is a system of islands, boats, shore castles, "
    "and people who know what the coast can carry. At Rockfleet, Gráinne Ní Mháille "
    "holds a household and a harbour together. In 1593, when Bingham's pressure "
    "has broken the life she built, she crosses to London and makes the English state "
    "answer her."
)
DESIGNS = {
    "connacht-female": (
        "Native English speaker from the west of Ireland, with a soft Connacht Irish lilt. "
        "Female, 35-45. High quality. Persona: intimate historical storyteller. "
        "Warm, intelligent, grounded emotion; measured pace, clear diction, lyrical but restrained."
    ),
    "west-ireland-male": (
        "Native English speaker from Galway or Mayo in the west of Ireland, with a natural Irish lilt. "
        "Male, 40-55. High quality. Persona: weathered coastal narrator. "
        "Low, warm resonance; calm, unhurried delivery with quiet authority and human tenderness."
    ),
    "irish-documentary-female": (
        "Native English speaker from Ireland, clearly Irish rather than American or English. "
        "Female, 45-60. High quality. Persona: trusted public-history narrator. "
        "Mature, warm, precise, and reflective; deliberate pacing with gentle emphasis on names and place."
    ),
}

def main() -> None:
    for line in (ROOT / ".env").read_text().splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip())
    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key:
        raise SystemExit("ELEVENLABS_API_KEY is not set")
    OUT.mkdir(parents=True, exist_ok=True)
    meta = {"text": TEXT, "previews": []}
    for name, description in DESIGNS.items():
        response = requests.post(
            "https://api.elevenlabs.io/v1/text-to-voice/design?output_format=mp3_44100_192",
            headers={"xi-api-key": key, "Content-Type": "application/json"},
            json={"voice_description": description, "text": TEXT, "model_id": "eleven_ttv_v3"},
            timeout=180,
        )
        response.raise_for_status()
        for index, preview in enumerate(response.json()["previews"], 1):
            filename = f"{name}-{index}.mp3"
            (OUT / filename).write_bytes(base64.b64decode(preview["audio_base_64"]))
            meta["previews"].append({"file": filename, "design": name, "generated_voice_id": preview["generated_voice_id"], "description": description})
            print(OUT / filename)
    (OUT / "metadata.json").write_text(json.dumps(meta, indent=2) + "\n")

if __name__ == "__main__":
    main()
