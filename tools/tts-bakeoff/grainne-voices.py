#!/usr/bin/env python3
"""Generate a small ElevenLabs voice sampler for the Gráinne story."""

import os
from pathlib import Path
import requests

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tools/tts-bakeoff/grainne-voice-samples"
TEXT = (
    "Clew Bay is not scenery. It is a system of islands, boats, shore castles, "
    "and people who know what the coast can carry. At Rockfleet, Gráinne Ní Mháille "
    "holds a household and a harbour together. In 1593, when Bingham's pressure "
    "has broken the life she built, she crosses to London and makes the English state "
    "answer her."
)
VOICES = {
    "george-warm-storyteller": "JBFqnCBsd6RMkjVDRZzb",
    "sarah-mature-reassuring": "EXAVITQu4vr4xnSDxMaL",
    "roger-laid-back-resonant": "CwhRBWXzGAHq8TQ4Fs17",
    "jessica-playful-bright": "cgSgspJ2msm6clMCkdW9",
}

def main() -> None:
    env = ROOT / ".env"
    for line in env.read_text().splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip())
    api_key = os.environ.get("ELEVENLABS_API_KEY")
    if not api_key:
        raise SystemExit("ELEVENLABS_API_KEY is not set")
    OUT.mkdir(parents=True, exist_ok=True)
    for label, voice_id in VOICES.items():
        target = OUT / f"{label}.mp3"
        response = requests.post(
            f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format=mp3_44100_128",
            headers={"xi-api-key": api_key, "Content-Type": "application/json"},
            # The sample is English narration with Irish names; forcing `gle`
            # makes ElevenLabs reject the mixed-language passage.
            json={"text": TEXT, "model_id": "eleven_v3"},
            timeout=120,
        )
        response.raise_for_status()
        target.write_bytes(response.content)
        print(target)

if __name__ == "__main__":
    main()
