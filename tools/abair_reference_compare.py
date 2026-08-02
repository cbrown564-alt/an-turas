#!/usr/bin/env python3
"""Offline-only ABAIR reference ingest and acoustic comparison.

This tool never calls ABAIR, uploads audio, copies audio into the repository, or
produces a pronunciation/correctness score. It accepts only explicitly sourced
local files and emits derived measurements for human review.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import subprocess
import sys
import unicodedata
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
SCHEMA = ROOT / "content/audio/authoring/schemas/abair-reference-comparison-v1.schema.json"
TERMS_URL = "https://abair.ie/terms"
SAMPLE_RATE = 16_000
FRAME_LENGTH = 400
HOP_LENGTH = 160


class ComparisonError(RuntimeError):
    pass


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize_text(value: str) -> str:
    return " ".join(unicodedata.normalize("NFC", value).split())


def local_audio(path_value: str, base: Path) -> Path:
    if not isinstance(path_value, str) or not path_value.strip():
        raise ComparisonError("audio path is required")
    if "://" in path_value:
        raise ComparisonError(f"network audio is forbidden: {path_value}")
    path = Path(path_value).expanduser()
    if not path.is_absolute():
        path = base / path
    if path.is_symlink():
        raise ComparisonError(f"symlinked audio is forbidden: {path}")
    path = path.resolve()
    if not path.is_file():
        raise ComparisonError(f"local audio file is missing or symlinked: {path}")
    if path.suffix.lower() not in {".wav", ".mp3", ".flac", ".m4a", ".aiff", ".aif", ".ogg"}:
        raise ComparisonError(f"unsupported local audio type: {path.suffix}")
    return path


def decode_pcm(path: Path) -> np.ndarray:
    try:
        result = subprocess.run(
            [
                "ffmpeg", "-v", "error", "-i", str(path), "-ac", "1", "-ar",
                str(SAMPLE_RATE), "-f", "s16le", "pipe:1",
            ],
            check=True,
            capture_output=True,
        )
    except FileNotFoundError as error:
        raise ComparisonError("ffmpeg is required for offline audio analysis") from error
    except subprocess.CalledProcessError as error:
        detail = error.stderr.decode("utf-8", errors="replace").strip()
        raise ComparisonError(f"ffmpeg could not decode {path}: {detail}") from error
    audio = np.frombuffer(result.stdout, dtype="<i2").astype(np.float64) / 32768.0
    if audio.size == 0:
        raise ComparisonError(f"audio contains no samples: {path}")
    return audio


def frames(audio: np.ndarray) -> np.ndarray:
    if audio.size < FRAME_LENGTH:
        audio = np.pad(audio, (0, FRAME_LENGTH - audio.size))
    count = 1 + max(0, (audio.size - FRAME_LENGTH) // HOP_LENGTH)
    padded = np.pad(audio, (0, max(0, (count - 1) * HOP_LENGTH + FRAME_LENGTH - audio.size)))
    indices = np.arange(FRAME_LENGTH)[None, :] + HOP_LENGTH * np.arange(count)[:, None]
    return padded[indices] * np.hanning(FRAME_LENGTH)[None, :]


def signal_features(audio: np.ndarray) -> dict[str, float]:
    windowed = frames(audio)
    raw_frames = frames(audio) / np.maximum(np.hanning(FRAME_LENGTH)[None, :], 1e-12)
    rms = np.sqrt(np.mean(raw_frames * raw_frames, axis=1))
    spectrum = np.abs(np.fft.rfft(windowed, axis=1))
    frequencies = np.fft.rfftfreq(FRAME_LENGTH, 1 / SAMPLE_RATE)
    magnitude_sum = np.maximum(spectrum.sum(axis=1), 1e-12)
    centroid = (spectrum * frequencies[None, :]).sum(axis=1) / magnitude_sum
    bandwidth = np.sqrt(
        (spectrum * (frequencies[None, :] - centroid[:, None]) ** 2).sum(axis=1)
        / magnitude_sum
    )
    signs = np.sign(raw_frames)
    zcr = np.mean(signs[:, 1:] != signs[:, :-1], axis=1)
    return {
        "duration_seconds": round(audio.size / SAMPLE_RATE, 4),
        "rms_db": round(float(20 * np.log10(max(float(np.mean(rms)), 1e-9))), 4),
        "peak_db": round(float(20 * np.log10(max(float(np.max(np.abs(audio))), 1e-9))), 4),
        "spectral_centroid_hz": round(float(np.mean(centroid)), 4),
        "spectral_bandwidth_hz": round(float(np.mean(bandwidth)), 4),
        "zero_crossing_rate": round(float(np.mean(zcr)), 6),
        "envelope": rms,
    }


def correlation(left: np.ndarray, right: np.ndarray) -> float | None:
    size = min(left.size, right.size)
    if size < 2:
        return None
    left = left[:size] - np.mean(left[:size])
    right = right[:size] - np.mean(right[:size])
    denominator = np.linalg.norm(left) * np.linalg.norm(right)
    if denominator <= 1e-12:
        return None
    return round(float(np.dot(left, right) / denominator), 4)


def compare_pair(pair: dict[str, Any], manifest_dir: Path) -> dict[str, Any]:
    eleven_path = local_audio(pair["elevenlabs_path"], manifest_dir)
    abair_path = local_audio(pair["abair_path"], manifest_dir)
    actual_sha = sha256_file(abair_path)
    if actual_sha != pair.get("abair_sha256"):
        raise ComparisonError(f"ABAIR checksum mismatch for {pair.get('pair_id')}")
    eleven = signal_features(decode_pcm(eleven_path))
    abair = signal_features(decode_pcm(abair_path))
    envelope_similarity = correlation(eleven.pop("envelope"), abair.pop("envelope"))
    differences = {
        key: round(abair[key] - eleven[key], 4)
        for key in abair
        if key in eleven
    }
    observations: list[str] = []
    if abs(differences["duration_seconds"]) > 0.25:
        observations.append("duration differs materially; inspect speaking rate or truncation")
    if envelope_similarity is not None and envelope_similarity < 0.35:
        observations.append("unaligned energy envelopes differ; inspect timing and phrasing")
    if not observations:
        observations.append("no coarse acoustic anomaly crossed the review heuristics")
    return {
        "pair_id": pair["pair_id"],
        "text": pair["text"],
        "inventory_slug": pair.get("inventory_slug"),
        "elevenlabs": eleven,
        "abair": abair,
        "abair_sha256": actual_sha,
        "differences_abair_minus_elevenlabs": differences,
        "unaligned_envelope_similarity": envelope_similarity,
        "observations": observations,
        "interpretation": {
            "correctness_claim": False,
            "pronunciation_score": None,
            "human_audio_review_required": True,
            "note": "Acoustic agreement or difference is not evidence of Irish correctness, dialect authenticity, or learner suitability.",
        },
    }


def validate_manifest(manifest: dict[str, Any], allow: bool) -> None:
    if manifest.get("schema_version") != 1 or manifest.get("contract") != "offline_abair_reference_comparison":
        raise ComparisonError("invalid ABAIR comparison manifest contract")
    if manifest.get("network_access") is not False:
        raise ComparisonError("comparison manifest must declare network_access=false")
    terms = manifest.get("terms") or {}
    required = ("terms_url", "permission_basis", "use_scope", "redistribution_allowed", "local_only")
    if any(field not in terms for field in required):
        raise ComparisonError("terms metadata is incomplete")
    if terms["terms_url"] != TERMS_URL:
        raise ComparisonError(f"terms_url must be {TERMS_URL}")
    if terms["local_only"] is not True:
        raise ComparisonError("ABAIR references must be local-only")
    if not terms["permission_basis"].strip():
        raise ComparisonError("permission_basis must name the lawful basis")
    if terms.get("lawful_acquisition_attested") is not True:
        raise ComparisonError("lawful_acquisition_attested=true is required")
    if not allow:
        raise ComparisonError("comparison is disabled by default; pass --enable-offline-comparison")
    if manifest.get("comparison_enabled") is not True:
        raise ComparisonError("manifest comparison_enabled must be true for an enabled run")
    if terms["use_scope"] not in {"internal_evaluation", "noncommercial_educational", "written_permission"}:
        raise ComparisonError("unsupported ABAIR use scope")
    if terms["use_scope"] != "written_permission" and terms["redistribution_allowed"] is True:
        raise ComparisonError("redistribution requires written permission")
    if terms["use_scope"] == "written_permission" and not terms.get("permission_reference"):
        raise ComparisonError("written_permission scope requires permission_reference")


def ingest(args: argparse.Namespace) -> dict[str, Any]:
    pairs_path = Path(args.pairs).expanduser().resolve()
    raw = json.loads(pairs_path.read_text(encoding="utf-8"))
    if not isinstance(raw, list) or not raw:
        raise ComparisonError("pairs input must be a non-empty JSON list")
    rows: list[dict[str, Any]] = []
    for index, row in enumerate(raw):
        if not isinstance(row, dict):
            raise ComparisonError(f"pair {index} must be an object")
        pair = dict(row)
        pair.setdefault("pair_id", pair.get("inventory_slug") or f"pair-{index + 1:04d}")
        pair["text"] = normalize_text(str(pair.get("text", "")))
        if not pair["text"]:
            raise ComparisonError(f"pair {index} has no text")
        abair_path = local_audio(pair.get("abair_path", ""), pairs_path.parent)
        pair["abair_path"] = str(abair_path)
        pair["abair_sha256"] = sha256_file(abair_path)
        pair.setdefault("abair_source", "https://abair.ie/synthesis")
        pair.setdefault("acquired_at", datetime.now(timezone.utc).isoformat())
        rows.append(pair)
    output = {
        "schema_version": 1,
        "contract": "offline_abair_reference_comparison",
        "comparison_enabled": False,
        "network_access": False,
        "terms": {
            "terms_url": TERMS_URL,
            "permission_basis": args.permission_basis,
            "lawful_acquisition_attested": True,
            "use_scope": args.use_scope,
            "redistribution_allowed": False,
            "local_only": True,
            "permission_reference": args.permission_reference,
        },
        "pairs": rows,
    }
    Path(args.output).expanduser().resolve().write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return {"ingested": len(rows), "output": str(Path(args.output).expanduser().resolve()), "comparison_enabled": False}


def analyze(args: argparse.Namespace) -> dict[str, Any]:
    manifest_path = Path(args.manifest).expanduser().resolve()
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    validate_manifest(manifest, args.enable_offline_comparison)
    results = [compare_pair(pair, manifest_path.parent) for pair in manifest.get("pairs", [])]
    return {
        "schema_version": 1,
        "contract": "offline_abair_reference_comparison_report",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_manifest": str(manifest_path),
        "network_access": False,
        "audio_retained_or_copied": False,
        "results": results,
        "release_eligible": False,
        "correctness_claim": False,
        "report_note": "This report is a mechanistic comparison aid only. It does not establish pronunciation correctness, dialect authenticity, native-speaker acceptance, pedagogy, or release eligibility.",
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    ingest_parser = subparsers.add_parser("ingest")
    ingest_parser.add_argument("--pairs", required=True)
    ingest_parser.add_argument("--output", required=True)
    ingest_parser.add_argument("--permission-basis", required=True)
    ingest_parser.add_argument("--use-scope", choices=["internal_evaluation", "noncommercial_educational", "written_permission"], required=True)
    ingest_parser.add_argument("--permission-reference")
    analyze_parser = subparsers.add_parser("analyze")
    analyze_parser.add_argument("--manifest", required=True)
    analyze_parser.add_argument("--output", required=True)
    analyze_parser.add_argument("--enable-offline-comparison", action="store_true")
    args = parser.parse_args(argv)
    try:
        result = ingest(args) if args.command == "ingest" else analyze(args)
        if args.command == "analyze":
            Path(args.output).expanduser().resolve().write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (ComparisonError, OSError, json.JSONDecodeError, ValueError) as error:
        print(f"BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
