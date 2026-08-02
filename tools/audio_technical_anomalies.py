#!/usr/bin/env python3
"""Deterministic, offline technical checks for a local audio inventory.

The checks in this module are intentionally acoustic and mechanical. They can
identify a file that is absent, undecodable, silent, clipped, implausibly short
or long, or a level outlier in the inspected inventory. They do not assess
Irish pronunciation, dialect, meaning, or learner suitability.
"""

from __future__ import annotations

import math
import statistics
import subprocess
from pathlib import Path
from typing import Any, Iterable


SCHEMA_VERSION = 1
CONTRACT = "irish_audio_technical_anomaly_audit"
DECODER = "ffmpeg"
SAMPLE_RATE_HZ = 16_000
CHANNELS = 1
SHORT_DURATION_SECONDS = 0.25
LONG_DURATION_SECONDS = 15.0
SILENCE_PEAK = 0.001
CLIP_SAMPLE = 0.999
CLIP_FRACTION = 0.001
OUTLIER_IQR_MULTIPLIER = 3.0
LEVEL_OUTLIER_IQR_MULTIPLIER = 1.5
_MEASUREMENT_CACHE: dict[
    tuple[str, int, int, str], tuple[dict[str, float | int] | None, str | None]
] = {}


def _percentile(values: list[float], fraction: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    position = (len(ordered) - 1) * fraction
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return ordered[lower]
    weight = position - lower
    return ordered[lower] + (ordered[upper] - ordered[lower]) * weight


def _distribution(values: list[float]) -> dict[str, float | int | None]:
    if not values:
        return {
            "count": 0,
            "median": None,
            "q1": None,
            "q3": None,
            "iqr": None,
        }
    q1 = _percentile(values, 0.25)
    q3 = _percentile(values, 0.75)
    return {
        "count": len(values),
        "median": round(statistics.median(values), 4),
        "q1": round(q1, 4),
        "q3": round(q3, 4),
        "iqr": round(q3 - q1, 4),
    }


def _decode(path: Path) -> tuple[list[float], str | None]:
    try:
        result = subprocess.run(
            [
                DECODER,
                "-v",
                "error",
                "-i",
                str(path),
                "-ac",
                str(CHANNELS),
                "-ar",
                str(SAMPLE_RATE_HZ),
                "-f",
                "s16le",
                "pipe:1",
            ],
            check=True,
            capture_output=True,
            timeout=30,
        )
    except FileNotFoundError:
        return [], "decoder_unavailable"
    except subprocess.TimeoutExpired:
        return [], "decoder_timeout"
    except subprocess.CalledProcessError:
        return [], "decode_failed"

    payload = result.stdout
    if not payload or len(payload) % 2:
        return [], "decoded_sample_data_invalid"
    samples = [
        int.from_bytes(payload[index : index + 2], "little", signed=True) / 32768.0
        for index in range(0, len(payload), 2)
    ]
    if not samples:
        return [], "decoded_sample_data_empty"
    return samples, None


def _measure(samples: list[float]) -> dict[str, float | int]:
    peak = max(abs(sample) for sample in samples)
    rms = math.sqrt(sum(sample * sample for sample in samples) / len(samples))
    clipped = sum(abs(sample) >= CLIP_SAMPLE for sample in samples)
    return {
        "duration_seconds": round(len(samples) / SAMPLE_RATE_HZ, 4),
        "peak_db": round(20 * math.log10(max(peak, 1e-9)), 4),
        "rms_db": round(20 * math.log10(max(rms, 1e-9)), 4),
        "peak_linear": round(peak, 6),
        "clipped_sample_count": clipped,
        "clipped_fraction": round(clipped / len(samples), 6),
    }


def _outlier(
    value: float,
    distribution: dict[str, float | int | None],
    multiplier: float,
) -> str | None:
    q1 = distribution.get("q1")
    q3 = distribution.get("q3")
    iqr = distribution.get("iqr")
    if not isinstance(q1, (int, float)) or not isinstance(q3, (int, float)):
        return None
    if not isinstance(iqr, (int, float)) or iqr <= 0:
        return None
    lower = q1 - multiplier * iqr
    upper = q3 + multiplier * iqr
    if value < lower:
        return "low"
    if value > upper:
        return "high"
    return None


def _provenance(entry: dict[str, Any], source_manifest: str) -> dict[str, Any]:
    return {
        "source_manifest": source_manifest,
        "source_kind": "runtime_manifest",
        "manifest_slug": entry.get("slug"),
        "manifest_file": entry.get("file"),
        "manifest_sources": sorted(
            str(source)
            for source in (entry.get("sources") or [])
            if isinstance(source, str)
        ),
        "recorded_sha256": entry.get("recorded_sha256"),
        "actual_sha256": entry.get("actual_sha256"),
    }


def audit_inventory(
    entries: Iterable[dict[str, Any]],
    *,
    source_manifest: str,
) -> dict[str, Any]:
    """Audit local inventory entries and return a stable report.

    Each entry must contain ``path`` (a local :class:`~pathlib.Path` or
    ``None``), ``file``, and ``slug``. Optional manifest metadata is retained
    in the result as provenance. The function never writes, moves, or changes
    an audio file or its manifest row.
    """
    rows: list[dict[str, Any]] = []
    decoder_unavailable = False
    decoded: list[tuple[dict[str, Any], dict[str, float | int]]] = []

    for entry in sorted(
        entries,
        key=lambda item: (str(item.get("slug") or ""), str(item.get("file") or "")),
    ):
        path_value = entry.get("path")
        path = path_value if isinstance(path_value, Path) else None
        result: dict[str, Any] = {
            "slug": entry.get("slug"),
            "file": entry.get("file"),
            "text": entry.get("text"),
            "status": "pass",
            "reasons": [],
            "measurements": None,
            "provenance": _provenance(entry, source_manifest),
        }
        if path is None or not path.is_file():
            result["status"] = "quarantine"
            result["reasons"] = ["missing_file"]
            rows.append(result)
            continue
        if path.is_symlink():
            result["status"] = "quarantine"
            result["reasons"] = ["symlinked_file"]
            rows.append(result)
            continue

        stat = path.stat()
        cache_key = (
            str(path),
            stat.st_mtime_ns,
            stat.st_size,
            str(entry.get("actual_sha256") or ""),
        )
        cached = _MEASUREMENT_CACHE.get(cache_key)
        if cached is None:
            samples, error = _decode(path)
            measurements = _measure(samples) if not error else None
            _MEASUREMENT_CACHE[cache_key] = (measurements, error)
        else:
            measurements, error = cached
        if error or measurements is None:
            if error == "decoder_unavailable":
                decoder_unavailable = True
            result["status"] = "quarantine"
            result["reasons"] = [error or "decoded_measurements_unavailable"]
            rows.append(result)
            continue
        result["measurements"] = measurements
        decoded.append((result, measurements))
        rows.append(result)

    usable = [
        measurements
        for result, measurements in decoded
        if measurements["peak_linear"] > SILENCE_PEAK
    ]
    duration_values = [float(measurements["duration_seconds"]) for measurements in usable]
    level_values = [float(measurements["rms_db"]) for measurements in usable]
    duration_distribution = _distribution(duration_values)
    level_distribution = _distribution(level_values)

    for result, measurements in decoded:
        reasons: list[str] = []
        duration = float(measurements["duration_seconds"])
        peak = float(measurements["peak_linear"])
        clipped_fraction = float(measurements["clipped_fraction"])
        if peak <= SILENCE_PEAK:
            reasons.append("silent_audio")
        if clipped_fraction >= CLIP_FRACTION:
            reasons.append("clipped_audio")
        if duration < SHORT_DURATION_SECONDS:
            reasons.append("duration_below_minimum")
        if duration > LONG_DURATION_SECONDS:
            reasons.append("duration_above_maximum")
        if peak > SILENCE_PEAK:
            duration_outlier = _outlier(duration, duration_distribution, OUTLIER_IQR_MULTIPLIER)
            if duration_outlier:
                reasons.append(f"duration_outlier_{duration_outlier}")
            level_outlier = _outlier(
                float(measurements["rms_db"]),
                level_distribution,
                LEVEL_OUTLIER_IQR_MULTIPLIER,
            )
            if level_outlier:
                reasons.append(f"level_outlier_{level_outlier}")

        quarantine_reasons = {
            "silent_audio", "clipped_audio", "duration_below_minimum",
            "duration_above_maximum", "decode_failed", "decoder_timeout",
            "decoded_sample_data_invalid", "decoded_sample_data_empty",
            "decoder_unavailable", "missing_file", "symlinked_file",
        }
        review_reasons = {
            "duration_outlier_low", "duration_outlier_high",
            "level_outlier_low", "level_outlier_high",
        }
        if any(reason in quarantine_reasons for reason in reasons):
            result["status"] = "quarantine"
        elif any(reason in review_reasons for reason in reasons):
            result["status"] = "review"
        result["reasons"] = sorted(set(reasons))

    quarantine = [row["slug"] for row in rows if row["status"] == "quarantine"]
    review = [row["slug"] for row in rows if row["status"] == "review"]
    passed = [row["slug"] for row in rows if row["status"] == "pass"]
    return {
        "schema_version": SCHEMA_VERSION,
        "contract": CONTRACT,
        "read_only": True,
        "decoder": {
            "program": DECODER,
            "sample_rate_hz": SAMPLE_RATE_HZ,
            "channels": CHANNELS,
            "sample_format": "s16le",
        },
        "thresholds": {
            "short_duration_seconds": SHORT_DURATION_SECONDS,
            "long_duration_seconds": LONG_DURATION_SECONDS,
            "silence_peak_linear": SILENCE_PEAK,
            "clip_sample_linear": CLIP_SAMPLE,
            "clip_fraction": CLIP_FRACTION,
            "duration_outlier_iqr_multiplier": OUTLIER_IQR_MULTIPLIER,
            "level_outlier_iqr_multiplier": LEVEL_OUTLIER_IQR_MULTIPLIER,
        },
        "population": {
            "duration_seconds": duration_distribution,
            "rms_db": level_distribution,
            "usable_for_outlier_baselines": len(usable),
        },
        "rows": rows,
        "summary": {
            "inspected": len(rows),
            "passed": len(passed),
            "review_required": len(review),
            "quarantined": len(quarantine),
            "decoder_unavailable": decoder_unavailable,
            "quarantine_slugs": sorted(str(slug) for slug in quarantine),
            "review_slugs": sorted(str(slug) for slug in review),
        },
        "scope": "technical audio inspection only; no pronunciation, dialect, meaning, pedagogy, or learner-release judgment",
    }
