#!/usr/bin/env python3
"""Wire launch county packs to the frozen Irish audio inventory.

- Flip audio resources to ``bundled`` when the spoken value has an on-disk MP3.
- Set thin conversation ``audioText`` to inventory lines (bind rule).
- Attach matching audio resource IDs on those conversation pages.
- Sync Phase 5 drafts into ``ios/AnTuras/Resources/CountyStories/``.

Does not replace the bundled Mayo Rockfleet representative slice with the
nine-chapter review draft.
"""

from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INVENTORY = ROOT / "content/audio/irish-inventory-v1.json"
AUDIO_DIR = ROOT / "ios/AnTuras/Resources/Audio"
DRAFTS = {
    "mayo": ROOT / "content/mayo/grainne-1593.pack.draft.json",
    "dublin": ROOT / "content/dublin/sihtric-penny.pack.draft.json",
    "meath": ROOT / "content/meath/trim-de-lacy.pack.draft.json",
    "offaly": ROOT / "content/offaly/cross-of-the-scriptures.pack.draft.json",
}
PHASE5_BUNDLED = {
    "dublin": ROOT / "ios/AnTuras/Resources/CountyStories/dublin.sihtric-penny.json",
    "meath": ROOT / "ios/AnTuras/Resources/CountyStories/meath.trim-de-lacy.json",
    "offaly": ROOT
    / "ios/AnTuras/Resources/CountyStories/offaly.cross-of-the-scriptures.json",
}
MAYO_BUNDLED = ROOT / "ios/AnTuras/Resources/CountyStories/mayo.grainne-1593.json"

# Thin MC conversations → inventory partner lines (must exist in inventory).
CONVERSATION_AUDIO: dict[str, str] = {
    "mayo.rockfleet.dialogue": "Cá bhfuil an caisleán?",
    "mayo.road-to-london.dialogue-ask": "Iarr freagra.",
    "dublin.named-king.answer-the-name": "Cé hé an rí?",
    "dublin.first-penny.answer-journey": "Téigh ar ais go dtí an chathair.",
    "meath.grant.answer-possession": "Cad atá agat?",
    "meath.first-fortification.answer-where-live": "An bhfuil cónaí ort anseo?",
    "offaly.settlement.build-learning": "An bhfuil tú ag foghlaim?",
    "offaly.carved-cross.dialogue-object": "Cá bhfuil an chros?",
}


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


def audio_resource_id(text: str) -> str:
    return "audio.inventory." + slug(text)


def load_inventory_texts() -> set[str]:
    data = json.loads(INVENTORY.read_text())
    return {entry["text"] for entry in data["entries"]}


def flip_resources(pack: dict) -> int:
    flipped = 0
    for resource in pack.get("resources", []):
        if resource.get("kind") != "audio":
            continue
        value = (resource.get("value") or "").strip()
        if not value:
            continue
        if not (AUDIO_DIR / f"{slug(value)}.mp3").exists():
            continue
        if resource.get("status") != "bundled":
            resource["status"] = "bundled"
            flipped += 1
    return flipped


def ensure_audio_resource(pack: dict, text: str) -> str:
    rid = audio_resource_id(text)
    resources = pack.setdefault("resources", [])
    for resource in resources:
        if resource.get("id") == rid:
            resource["value"] = text
            resource["kind"] = "audio"
            resource["status"] = "bundled"
            return rid
        if resource.get("kind") == "audio" and resource.get("value") == text:
            resource["status"] = "bundled"
            return resource["id"]
    resources.append(
        {
            "id": rid,
            "kind": "audio",
            "value": text,
            "status": "bundled",
        }
    )
    return rid


def wire_conversations(pack: dict, inventory: set[str]) -> list[str]:
    wired: list[str] = []
    for chapter in pack.get("chapters", []):
        for page in chapter.get("pages", []):
            page_id = page.get("id")
            if page_id not in CONVERSATION_AUDIO:
                continue
            exercise = page.get("exercise")
            if not isinstance(exercise, dict) or exercise.get("family") != "conversation":
                continue
            text = CONVERSATION_AUDIO[page_id]
            if text not in inventory:
                raise SystemExit(f"{page_id}: {text!r} not in inventory")
            if not (AUDIO_DIR / f"{slug(text)}.mp3").exists():
                raise SystemExit(f"{page_id}: missing MP3 for {text!r}")
            exercise["audioText"] = text
            rid = ensure_audio_resource(pack, text)
            ids = list(page.get("resourceIDs") or [])
            if rid not in ids:
                ids.append(rid)
            page["resourceIDs"] = ids
            wired.append(page_id)
    return wired


def assert_audio_texts_in_inventory(pack: dict, inventory: set[str], label: str) -> None:
    bad: list[str] = []

    def walk(obj: object) -> None:
        if isinstance(obj, dict):
            value = obj.get("audioText")
            if isinstance(value, str) and value.strip() and value not in inventory:
                bad.append(value)
            for child in obj.values():
                walk(child)
        elif isinstance(obj, list):
            for child in obj:
                walk(child)

    walk(pack)
    if bad:
        raise SystemExit(f"{label}: audioText not in inventory: {bad}")


def write_json(path: Path, payload: dict) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")


def wire_pack(path: Path, inventory: set[str], *, bump_revision: bool) -> dict:
    envelope = json.loads(path.read_text())
    pack = envelope["pack"]
    flipped = flip_resources(pack)
    wired = wire_conversations(pack, inventory)
    assert_audio_texts_in_inventory(pack, inventory, str(path))
    if bump_revision:
        pack["revision"] = int(pack.get("revision") or 1) + 1
    print(
        f"{path.relative_to(ROOT)}: flipped={flipped} conversations={wired} "
        f"revision={pack.get('revision')}"
    )
    write_json(path, envelope)
    return envelope


def wire_mayo_bundled(inventory: set[str]) -> None:
    """Wire the Rockfleet representative slice without replacing it with Mayo draft."""
    envelope = json.loads(MAYO_BUNDLED.read_text())
    pack = envelope["pack"]
    flipped = flip_resources(pack)
    wired = wire_conversations(pack, inventory)
    assert_audio_texts_in_inventory(pack, inventory, str(MAYO_BUNDLED))
    write_json(MAYO_BUNDLED, envelope)
    print(
        f"{MAYO_BUNDLED.relative_to(ROOT)}: flipped={flipped} conversations={wired} "
        "(representative slice)"
    )


def main() -> int:
    inventory = load_inventory_texts()

    # Mayo nine-chapter review draft is hand-assembled; wire in place.
    wire_pack(DRAFTS["mayo"], inventory, bump_revision=False)

    # Phase 5 drafts are owned by build_phase5_county_drafts.py (already emits
    # bundled audio + conversation audioText). Sync is a no-op check.
    for county, bundled_path in PHASE5_BUNDLED.items():
        draft_envelope = json.loads(DRAFTS[county].read_text())
        assert_audio_texts_in_inventory(draft_envelope["pack"], inventory, str(DRAFTS[county]))
        write_json(bundled_path, draft_envelope)
        pending = [
            r["id"]
            for r in draft_envelope["pack"].get("resources", [])
            if r.get("kind") == "audio" and r.get("status") != "bundled"
        ]
        if pending:
            raise SystemExit(f"{county} still has unbundled audio: {pending}")
        print(f"synced {bundled_path.relative_to(ROOT)} (phase5 generator)")

    wire_mayo_bundled(inventory)

    stamp = datetime.now(timezone.utc).isoformat()
    print(f"done {stamp}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
