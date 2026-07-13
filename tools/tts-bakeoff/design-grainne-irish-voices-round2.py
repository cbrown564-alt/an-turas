#!/usr/bin/env python3
"""Second-pass ElevenLabs Voice Design exploration for Gráinne narration."""

import base64
import json
import os
from pathlib import Path
import requests

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tools/tts-bakeoff/grainne-irish-voice-previews-round2"
TEXT = (
    "On the Mayo coast, power travels by water. Clew Bay is a working geography "
    "of islands, boats, shore castles, and families who know every inlet. At Rockfleet, "
    "Gráinne Ní Mháille holds a harbour and a household together. When the pressure of "
    "Bingham's government breaks that life, she goes to London—not as a legend, but as "
    "a woman with names, claims, and a case the state must answer."
)
DESIGNS = {
    "mayo-native-female": (
        "A native Irish-English woman from County Mayo, Ireland, with a clearly recognisable "
        "but understated west-of-Ireland accent. Female, 45-55. High quality. "
        "A calm public-history narrator: warm, intelligent, intimate, and unshowy. "
        "Natural Irish-English vowels and rhythm, gentle Connacht lilt, measured pace. "
        "Do not sound American, English, Scottish, theatrical, or generically British."
    ),
    "irish-radio-female": (
        "A native Irish woman from the west of Ireland speaking contemporary Irish English, "
        "like a thoughtful national radio documentary presenter. Female, 40-50. High quality. "
        "Distinctive natural Irish cadence, warm lower register, precise consonants, restrained emotion, "
        "slow conversational delivery. Clearly Irish, never American or English; avoid a fantasy Celtic accent."
    ),
    "connacht-elder-female": (
        "A native English-speaking woman from Connacht, Ireland, with an authentic mature Irish accent. "
        "Female, 60-70. High quality. Persona: trusted local historian. "
        "Weathered, warm, quietly authoritative, slightly husky, deliberate but conversational. "
        "The Irishness should come from natural pronunciation and cadence, not exaggerated musicality. "
        "Do not use an American, English, Scottish, or stage-Irish voice."
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
    metadata = {"text": TEXT, "previews": []}
    for name, description in DESIGNS.items():
        response = requests.post(
            "https://api.elevenlabs.io/v1/text-to-voice/design?output_format=mp3_44100_192",
            headers={"xi-api-key": key, "Content-Type": "application/json"},
            json={"voice_description": description, "text": TEXT},
            timeout=180,
        )
        response.raise_for_status()
        for index, preview in enumerate(response.json()["previews"], 1):
            filename = f"{name}-{index}.mp3"
            (OUT / filename).write_bytes(base64.b64decode(preview["audio_base_64"]))
            metadata["previews"].append({
                "file": filename,
                "design": name,
                "generated_voice_id": preview["generated_voice_id"],
                "description": description,
            })
            print(OUT / filename, flush=True)
    (OUT / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")

if __name__ == "__main__":
    main()
