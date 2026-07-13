#!/usr/bin/env python3
import os
from pathlib import Path
import requests

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tools/tts-bakeoff/irish-cultural-guide-samples"
VOICE_ID = "NPWroowF4phQhaPWjXPj"
CLIPS = {
    "01-clew-bay-opening": "On the Mayo coast, power travels by water. Clew Bay is a working geography of islands, boats, shore castles, and families who know every inlet. At Rockfleet, Gráinne Ní Mháille holds a harbour and a household together.",
    "02-the-squeeze": "In 1593, Bingham's pressure has broken the life Gráinne built. Kin are held, her livelihood is under strain, and the coast no longer answers to her as it once did. The remaining path leads away from Mayo, towards the Queen and the English court.",
    "03-the-petition": "Gráinne crosses to London not as a legend, but as a woman with names, claims, and a case the state must answer. Her petition asks for enough to live on, and offers service against the Queen's enemies. Behind the polite plea is the harder truth: her world has been squeezed until paper is her remaining weapon.",
}

def main():
    for line in (ROOT / ".env").read_text().splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip())
    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key:
        raise SystemExit("ELEVENLABS_API_KEY is not set")
    OUT.mkdir(parents=True, exist_ok=True)
    for slug, text in CLIPS.items():
        response = requests.post(
            f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}?output_format=mp3_44100_192",
            headers={"xi-api-key": key, "Content-Type": "application/json"},
            json={"text": text, "model_id": "eleven_v3"},
            timeout=120,
        )
        response.raise_for_status()
        target = OUT / f"{slug}.mp3"
        target.write_bytes(response.content)
        print(target)

if __name__ == "__main__":
    main()
