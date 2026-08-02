#!/usr/bin/env python3
"""Build deterministic Irish audio risk strata and distinctive sample manifests.

This is an offline review-planning tool. It does not judge Irish grammar,
pronunciation, dialect, pedagogy, history, or audio quality, and it never changes
capture, claim, lease, checksum, QA, or learner-release state.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import sys
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[1]
LOCKED_VOICE_ID = "NPWroowF4phQhaPWjXPj"
LOCKED_VOICE = {
    "provider": "ElevenLabs",
    "voice_id": LOCKED_VOICE_ID,
    "model_id": "eleven_v3",
    "language_code": "ga",
    "output_format": "mp3_44100_192",
    "voice_settings": {"mode": "provider_defaults", "overrides": {}},
}

STRATA = (
    "names",
    "places",
    "mutations",
    "fadas",
    "phoneme_grapheme",
    "story_lines",
    "launch_lines",
    "duplicates",
    "outliers",
    "provisional_source",
    "high_risk",
)
RISK_WEIGHTS = {
    "names": 4,
    "places": 3,
    "mutations": 5,
    "fadas": 2,
    "phoneme_grapheme": 3,
    "story_lines": 3,
    "launch_lines": 5,
    "duplicates": 4,
    "outliers": 5,
    "provisional_source": 4,
    "high_risk": 0,
}

NAME_RE = re.compile(
    r"\b(?:Gráinne|Sihtric|Colmán|Flann|Fionn|Brian|Brigid|"
    r"Medb|Méabh|Piaras|Yeats|Cú Chulainn|Kavanagh|O'Neill)\b",
    re.IGNORECASE,
)
MUTATION_RE = re.compile(
    r"\b(?:an|ar an|sa|chuig an|go dtí an|don|leis an|ón)\s+"
    r"[A-Za-zÁÉÍÓÚáéíóú]+",
    re.IGNORECASE,
)
PLACE_RE = re.compile(
    r"\b(?:anseo|ansiúd|baile|cathair|abhainn|farraige|cladach|"
    r"caisleán|oileán|bóthar|margadh|loch|cnoc|talamh|áit)\b",
    re.IGNORECASE,
)
DIGRAPHS = ("bh", "ch", "dh", "fh", "gh", "mh", "ph", "sh", "th")
IRISH_LETTERS = frozenset("abcdefghijklmnoprstuvwyzáéíóú")
ALLOWED_PUNCTUATION = frozenset(" .,?!;:'-()")


def normalize_text(value: Any) -> str:
    if not isinstance(value, str):
        return ""
    return " ".join(unicodedata.normalize("NFC", value).strip().split())


def text_sha256(text: str) -> str:
    return hashlib.sha256(normalize_text(text).encode("utf-8")).hexdigest()


def audio_slug(text: str) -> str:
    fadas = {"á": "aa", "é": "ee", "í": "ii", "ó": "oo", "ú": "uu"}
    pieces: list[str] = []
    for char in normalize_text(text).lower():
        if char in fadas:
            pieces.append(fadas[char])
        elif char.isascii() and char.isalpha():
            pieces.append(char)
        else:
            pieces.append(" ")
    return "-".join("".join(pieces).split())


def stable_rank(seed: str, stratum: str, key: str) -> str:
    payload = "\0".join((seed, stratum, key)).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def family_paths(root: Path) -> list[Path]:
    return sorted(
        path
        for path in root.glob("content/*/phrase-families/authoring-v2/*.v2.json")
        if path.is_file()
    )


def launch_texts(root: Path) -> set[str]:
    path = root / "content/audio/launch-phrases-conversations-v1.json"
    if not path.is_file():
        return set()
    payload = read_json(path)
    texts: set[str] = set()
    for county in (payload.get("counties") or {}).values():
        if not isinstance(county, dict):
            continue
        for kind in ("phrases", "conversation"):
            for row in county.get(kind, []):
                if isinstance(row, dict):
                    text = normalize_text(row.get("text"))
                    if text:
                        texts.add(text)
    return texts


def batch_index(root: Path) -> dict[tuple[str, str], dict[str, Any]]:
    index: dict[tuple[str, str], dict[str, Any]] = {}
    batch_root = root / "content/audio/authoring/batches"
    if not batch_root.is_dir():
        return index
    for path in sorted(batch_root.glob("*.json")):
        payload = read_json(path)
        voice = (payload.get("voice_profile") or {}).get("voice_id", LOCKED_VOICE_ID)
        for line in payload.get("lines", []):
            if not isinstance(line, dict):
                continue
            text = normalize_text(line.get("normalized_text"))
            if not text:
                continue
            key = (text, voice)
            row = index.setdefault(
                key,
                {
                    "batch_ids": set(),
                    "line_ids": set(),
                    "member_ids": set(),
                    "states": set(),
                    "paths": set(),
                },
            )
            row["batch_ids"].add(payload.get("batch_id"))
            row["line_ids"].add(line.get("line_id"))
            row["member_ids"].update(line.get("member_ids") or [])
            row["states"].add(
                f"{(payload.get('execution') or {}).get('state')}:{(line.get('provider_result') or {}).get('status')}"
            )
            row["paths"].add(path.relative_to(root).as_posix())
    for row in index.values():
        for field in ("batch_ids", "line_ids", "member_ids", "states", "paths"):
            row[field] = sorted(value for value in row[field] if value)
    return index


def grapheme_features(text: str) -> tuple[str, ...]:
    lowered = normalize_text(text).lower()
    features: set[str] = set()
    for digraph in DIGRAPHS:
        if digraph in lowered:
            features.add(f"digraph:{digraph}")
    for char in lowered:
        if char in IRISH_LETTERS:
            features.add(f"letter:{char}")
        if char in "áéíóú":
            features.add(f"fada:{char}")
    return tuple(sorted(features))


def family_context(family: dict[str, Any]) -> dict[str, Any]:
    story = family.get("story_ref") or {}
    target = family.get("target") or {}
    placement_ids = sorted(
        {
            item.get("id")
            for item in family.get("atlas_placements", [])
            if isinstance(item, dict) and item.get("id")
        }
        | {
            item
            for member in family.get("members", [])
            for item in (member.get("binding") or {}).get("atlas_placement_ids", [])
            if item
        }
    )
    return {
        "family_id": family.get("id"),
        "county": family.get("county"),
        "story_id": story.get("record_id"),
        "sense_id": target.get("sense_id"),
        "citation_form": target.get("citation_form"),
        "placement_ids": placement_ids,
    }


def row_categories(row: dict[str, Any], *, launch: set[str], duplicate: bool) -> set[str]:
    text = row["normalized_text"]
    roles = {role for role in row["learning_roles"] if isinstance(role, str)}
    categories: set[str] = set()
    if NAME_RE.search(text) or any(
        token and token[:1].isupper() for token in text.split() if token not in {"Tá", "Cé"}
    ):
        categories.add("names")
    if row["place_ids"] or PLACE_RE.search(text):
        categories.add("places")
    if MUTATION_RE.search(text) or any(
        "mutation" in flag or "initial_" in flag for flag in row["risk_flags"]
    ):
        categories.add("mutations")
    if any(char in text for char in "áéíóúÁÉÍÓÚ"):
        categories.add("fadas")
    if row["rare_graphemes"]:
        categories.add("phoneme_grapheme")
    if roles & {"story_opening", "story_recap", "story", "context_introduction"}:
        categories.add("story_lines")
    if text in launch:
        categories.add("launch_lines")
    if duplicate:
        categories.add("duplicates")
    if "invented_text" in row["risk_flags"] or "source_ambiguity" in row["risk_flags"]:
        categories.add("provisional_source")
    if row["outlier_reasons"]:
        categories.add("outliers")
    return categories


def risk_score(categories: Iterable[str], rare_count: int) -> int:
    return sum(RISK_WEIGHTS.get(category, 0) for category in categories) + min(3, rare_count)


def priority_for_score(score: int) -> str:
    if score >= 12:
        return "P0"
    if score >= 7:
        return "P1"
    return "P2"


def stratify(
    root: Path = ROOT,
    *,
    seed: str = "d32.audio-risk.v1",
    sample_quota: int = 8,
    source_revision: str = "unknown",
    created_at: str = "2026-08-02T00:00:00Z",
) -> dict[str, Any]:
    if not seed or sample_quota < 1:
        raise ValueError("seed is required and sample_quota must be positive")
    paths = family_paths(root)
    if not paths:
        raise ValueError("no authoring-v2 family documents found")
    launch = launch_texts(root)
    batches = batch_index(root)
    raw: dict[tuple[str, str], dict[str, Any]] = {}

    for path in paths:
        family = read_json(path)
        context = family_context(family)
        for member in family.get("members", []):
            irish = member.get("irish") or {}
            text = normalize_text(irish.get("normalized_text") or irish.get("text"))
            if not text:
                continue
            voice = LOCKED_VOICE_ID
            key = (text, voice)
            row = raw.setdefault(
                key,
                {
                    "normalized_text": text,
                    "voice_id": voice,
                    "text_sha256": text_sha256(text),
                    "inventory_slug": audio_slug(text),
                    "member_ids": set(),
                    "family_ids": set(),
                    "counties": set(),
                    "story_ids": set(),
                    "sense_ids": set(),
                    "placement_ids": set(),
                    "source_paths": set(),
                    "learning_roles": set(),
                    "risk_flags": set(),
                    "place_ids": set(),
                    "exercise_consumer_ids": set(),
                    "declared": [],
                },
            )
            row["member_ids"].add(member.get("id"))
            row["family_ids"].add(context["family_id"])
            row["counties"].add(context["county"])
            row["story_ids"].add(context["story_id"])
            row["sense_ids"].add(context["sense_id"])
            row["placement_ids"].update(context["placement_ids"])
            row["source_paths"].add(path.relative_to(root).as_posix())
            row["learning_roles"].update((member.get("learning") or {}).get("roles", []))
            row["risk_flags"].update(member.get("risk_flags") or [])
            row["place_ids"].update(
                (member.get("binding") or {}).get("atlas_placement_ids", [])
            )
            row["exercise_consumer_ids"].update(
                consumer.get("record_id")
                for consumer in member.get("exercise_consumers", [])
                if isinstance(consumer, dict) and consumer.get("record_id")
            )
            row["declared"].append(
                {
                    "normalized_text": irish.get("normalized_text"),
                    "inventory_slug": irish.get("inventory_slug"),
                    "text_sha256": irish.get("text_sha256"),
                }
            )

    lengths = sorted(len(row["normalized_text"]) for row in raw.values())
    low_cut = lengths[max(0, math.floor((len(lengths) - 1) * 0.05))]
    high_cut = lengths[min(len(lengths) - 1, math.ceil((len(lengths) - 1) * 0.95))]
    feature_counts = Counter(
        feature
        for row in raw.values()
        for feature in grapheme_features(row["normalized_text"])
    )
    duplicate_keys = {
        key
        for key, row in raw.items()
        if len(row["member_ids"]) > 1
        or len(row["family_ids"]) > 1
        or len((batches.get(key) or {}).get("member_ids", [])) > 1
    }

    items: list[dict[str, Any]] = []
    for key, row in sorted(raw.items()):
        text = row["normalized_text"]
        features = grapheme_features(text)
        rare = tuple(feature for feature in features if feature_counts[feature] <= max(2, len(raw) // 100))
        outlier_reasons: set[str] = set()
        if len(text) <= low_cut or len(text) >= high_cut:
            outlier_reasons.add("length_tail")
        if any(char not in IRISH_LETTERS and char not in ALLOWED_PUNCTUATION for char in text.lower()):
            outlier_reasons.add("unexpected_character")
        if any(entry["normalized_text"] != text for entry in row["declared"]):
            outlier_reasons.add("identity_normalization_mismatch")
        if any(entry["inventory_slug"] != row["inventory_slug"] for entry in row["declared"]):
            outlier_reasons.add("identity_slug_mismatch")
        if any(entry["text_sha256"] != row["text_sha256"] for entry in row["declared"]):
            outlier_reasons.add("identity_hash_mismatch")
        row["rare_graphemes"] = rare
        row["outlier_reasons"] = tuple(sorted(outlier_reasons))
        categories = row_categories(row, launch=launch, duplicate=key in duplicate_keys)
        score = risk_score(categories, len(rare))
        batch = batches.get(key) or {}
        items.append(
            {
                "key": f"{text}\\0{key[1]}",
                "normalized_text": text,
                "voice_id": key[1],
                "text_sha256": row["text_sha256"],
                "inventory_slug": row["inventory_slug"],
                "member_ids": sorted(value for value in row["member_ids"] if value),
                "family_ids": sorted(value for value in row["family_ids"] if value),
                "counties": sorted(value for value in row["counties"] if value),
                "story_ids": sorted(value for value in row["story_ids"] if value),
                "sense_ids": sorted(value for value in row["sense_ids"] if value),
                "placement_ids": sorted(value for value in row["placement_ids"] if value),
                "source_paths": sorted(value for value in row["source_paths"] if value),
                "exercise_consumer_ids": sorted(row["exercise_consumer_ids"]),
                "batch_ids": batch.get("batch_ids", []),
                "batch_line_ids": batch.get("line_ids", []),
                "batch_states": batch.get("states", []),
                "risk_flags": sorted(row["risk_flags"]),
                "grapheme_features": list(features),
                "rare_graphemes": list(rare),
                "outlier_reasons": list(row["outlier_reasons"]),
                "categories": sorted(categories),
                "risk_score": score,
                "priority": priority_for_score(score),
            }
        )

    by_key = {item["key"]: item for item in items}
    high_risk_count = max(1, math.ceil(len(items) * 0.20))
    high_risk_keys = {
        item["key"]
        for item in sorted(
            items,
            key=lambda item: (
                -item["risk_score"],
                stable_rank(seed, "high_risk", item["key"]),
            ),
        )[:high_risk_count]
    }
    for item in items:
        if item["key"] in high_risk_keys:
            item["categories"] = sorted(set(item["categories"]) | {"high_risk"})
    selected: dict[str, set[str]] = defaultdict(set)
    selected_keys: set[str] = set()
    for stratum in STRATA:
        candidates = [item for item in items if stratum in item["categories"]]
        candidates.sort(key=lambda item: stable_rank(seed, stratum, item["key"]))
        for item in candidates:
            if len(selected[stratum]) >= sample_quota:
                break
            if item["key"] in selected_keys:
                continue
            selected[stratum].add(item["key"])
            selected_keys.add(item["key"])

    samples = []
    for key in sorted(selected_keys, key=lambda value: stable_rank(seed, "sample", value)):
        item = dict(by_key[key])
        item["sample_id"] = "sample." + stable_rank(seed, "sample", key)[:16]
        item["selection_strata"] = sorted(
            stratum for stratum, keys in selected.items() if key in keys
        )
        samples.append(item)

    category_counts = Counter(
        category for item in items for category in item["categories"]
    )
    return {
        "schema_version": 1,
        "contract": "irish_audio_risk_stratification_sampling",
        "created_at": created_at,
        "source_revision": source_revision,
        "scope": "mechanical review planning only; no capture or learner-release decision",
        "seed": seed,
        "sample_quota_per_stratum": sample_quota,
        "locked_voice": LOCKED_VOICE,
        "risk_weights": RISK_WEIGHTS,
        "summary": {
            "family_documents": len(paths),
            "unique_text_voice_keys": len(items),
            "member_references": sum(len(item["member_ids"]) for item in items),
            "duplicate_keys": sum("duplicates" in item["categories"] for item in items),
            "sample_count": len(samples),
            "category_counts": dict(sorted(category_counts.items())),
            "unfilled_strata": [
                stratum for stratum in STRATA if len(selected[stratum]) < sample_quota
            ],
        },
        "grapheme_coverage": {
            "interpretation": "grapheme features are a mechanical coverage proxy, not phoneme or pronunciation evidence",
            "feature_counts": dict(sorted(feature_counts.items())),
            "sample_feature_counts": dict(
                sorted(
                    Counter(
                        feature
                        for item in samples
                        for feature in item["grapheme_features"]
                    ).items()
                )
            ),
        },
        "strata": {
            stratum: {
                "candidate_count": sum(stratum in item["categories"] for item in items),
                "selected_sample_ids": sorted(
                    item["sample_id"]
                    for item in samples
                    if stratum in item["selection_strata"]
                ),
            }
            for stratum in STRATA
        },
        "risk_items": items,
        "samples": samples,
    }


def write_manifest(report: dict[str, Any], output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("stratify",))
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--seed", default="d32.audio-risk.v1")
    parser.add_argument("--sample-quota", type=int, default=8)
    parser.add_argument("--source-revision", default="unknown")
    parser.add_argument("--created-at", default="2026-08-02T00:00:00Z")
    args = parser.parse_args(argv)
    try:
        report = stratify(
            args.root.resolve(),
            seed=args.seed,
            sample_quota=args.sample_quota,
            source_revision=args.source_revision,
            created_at=args.created_at,
        )
        output_path = (
            args.output if args.output.is_absolute() else args.root / args.output
        ).resolve()
        write_manifest(report, output_path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(str(exc), file=sys.stderr)
        return 1
    try:
        display_output = str(output_path.relative_to(args.root.resolve()))
    except ValueError:
        display_output = str(output_path)
    print(
        json.dumps(
            {
                "output": display_output,
                "summary": report["summary"],
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
