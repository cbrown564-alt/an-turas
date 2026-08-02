#!/usr/bin/env python3
"""Deterministic, offline technical checks for a local audio inventory.

The checks in this module are intentionally acoustic and mechanical. They can
identify a file that is absent, undecodable, silent, clipped, implausibly short
or long, or a level outlier in the inspected inventory. They do not assess
Irish pronunciation, dialect, meaning, or learner suitability.
"""

from __future__ import annotations

import math
import os
import statistics
import subprocess
import tempfile
from pathlib import Path
from typing import Any, Iterable


SCHEMA_VERSION = 2
CONTRACT = "irish_audio_technical_anomaly_audit"
DECODER = "ffmpeg"
SAMPLE_RATE_HZ = 16_000
CHANNELS = 1
SHORT_DURATION_SECONDS = 0.25
LONG_DURATION_SECONDS = 15.0
SILENCE_PEAK = 0.001
CLIP_SAMPLE = 0.999
CLIP_MIN_SAMPLES = 16
CLIP_FRACTION = 0.0001
OUTLIER_IQR_MULTIPLIER = 3.0
LEVEL_OUTLIER_IQR_MULTIPLIER = 1.5
MIN_OUTLIER_BASELINE_SAMPLES = 8
DECODE_BATCH_SIZE = 32
DECODE_BATCH_TIMEOUT_SECONDS = 120
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


def _samples_from_payload(payload: bytes) -> tuple[list[float], str | None]:
    if not payload or len(payload) % 2:
        return [], "decoded_sample_data_invalid"
    samples = [
        int.from_bytes(payload[index : index + 2], "little", signed=True) / 32768.0
        for index in range(0, len(payload), 2)
    ]
    if not samples:
        return [], "decoded_sample_data_empty"
    return samples, None


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

    return _samples_from_payload(result.stdout)


def _decode_batch(paths: list[Path]) -> dict[Path, tuple[list[float], str | None]]:
    """Decode a bounded batch in one ffmpeg process.

    Each input is mapped to its own temporary raw PCM output, so a successful
    batch keeps exact per-file sample boundaries and therefore the same
    measurements as the single-file decoder. If ffmpeg cannot complete the
    batch, every path is retried through the conservative single-file path;
    partial batch output is never used.
    """
    if not paths:
        return {}
    try:
        with tempfile.TemporaryDirectory(prefix="irish-audio-decode-") as directory:
            output_paths = [Path(directory) / f"{index:03d}.s16le" for index in range(len(paths))]
            command = [DECODER, "-v", "error", "-nostdin"]
            for path in paths:
                command.extend(["-i", os.fspath(path)])
            for index, output_path in enumerate(output_paths):
                command.extend(
                    [
                        "-map",
                        f"{index}:a:0",
                        "-ac",
                        str(CHANNELS),
                        "-ar",
                        str(SAMPLE_RATE_HZ),
                        "-f",
                        "s16le",
                        os.fspath(output_path),
                    ]
                )
            try:
                subprocess.run(
                    command,
                    check=True,
                    capture_output=True,
                    timeout=DECODE_BATCH_TIMEOUT_SECONDS,
                )
            except FileNotFoundError:
                return {path: ([], "decoder_unavailable") for path in paths}
            except subprocess.TimeoutExpired:
                return {
                    path: _decode(path)
                    for path in paths
                }
            except subprocess.CalledProcessError:
                return {path: _decode(path) for path in paths}

            decoded: dict[Path, tuple[list[float], str | None]] = {}
            for path, output_path in zip(paths, output_paths):
                try:
                    payload = output_path.read_bytes()
                except OSError:
                    decoded[path] = ([], "decoded_sample_data_unavailable")
                    continue
                decoded[path] = _samples_from_payload(payload)
            return decoded
    except OSError:
        return {path: _decode(path) for path in paths}


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


def _kind(entry: dict[str, Any]) -> str:
    value = entry.get("kind")
    if isinstance(value, str) and value.strip():
        return value.strip().casefold()
    return "unknown"


def _text_length_bucket(text: object) -> str:
    if not isinstance(text, str) or not text.strip():
        return "unknown"
    word_count = len(text.split())
    if word_count == 1:
        return "one_word"
    if word_count <= 4:
        return "short_phrase"
    if word_count <= 7:
        return "long_phrase"
    return "long_sentence"


def _stratification(entry: dict[str, Any]) -> dict[str, str | None]:
    kind = _kind(entry)
    text_length_bucket = _text_length_bucket(entry.get("text"))
    return {
        "kind": kind,
        "text_length_bucket": text_length_bucket,
        "specific_group": f"kind:{kind}|length:{text_length_bucket}",
        "kind_group": f"kind:{kind}",
        "baseline_group": None,
        "fallback": None,
    }


def _baseline_group(
    metadata: dict[str, str | None],
    group_sizes: dict[str, int],
) -> tuple[str | None, str | None]:
    specific_group = metadata["specific_group"]
    kind_group = metadata["kind_group"]
    if specific_group and group_sizes.get(specific_group, 0) >= MIN_OUTLIER_BASELINE_SAMPLES:
        return specific_group, "kind_and_text_length"
    if kind_group and group_sizes.get(kind_group, 0) >= MIN_OUTLIER_BASELINE_SAMPLES:
        return kind_group, "kind_only"
    return None, "sparse_group_no_statistical_review"


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
    prepared: list[tuple[dict[str, Any], tuple[str, int, int, str]]] = []
    pending: dict[tuple[str, int, int, str], Path] = {}

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
            "stratification": _stratification(entry),
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
        prepared.append((result, cache_key))
        if cache_key not in _MEASUREMENT_CACHE:
            pending.setdefault(cache_key, path)
        rows.append(result)

    pending_paths = sorted(set(pending.values()), key=os.fspath)
    for start in range(0, len(pending_paths), DECODE_BATCH_SIZE):
        decoded_batch = _decode_batch(pending_paths[start : start + DECODE_BATCH_SIZE])
        for cache_key, path in pending.items():
            if path not in decoded_batch:
                continue
            samples, error = decoded_batch[path]
            measurements = _measure(samples) if not error else None
            _MEASUREMENT_CACHE[cache_key] = (measurements, error)

    decoded: list[tuple[dict[str, Any], dict[str, float | int]]] = []
    for result, cache_key in prepared:
        measurements, error = _MEASUREMENT_CACHE.get(
            cache_key,
            (None, "decoded_measurements_unavailable"),
        )
        if error or measurements is None:
            if error == "decoder_unavailable":
                decoder_unavailable = True
            result["status"] = "quarantine"
            result["reasons"] = [error or "decoded_measurements_unavailable"]
            continue
        result["measurements"] = measurements
        decoded.append((result, measurements))

    usable = [
        measurements
        for result, measurements in decoded
        if measurements["peak_linear"] > SILENCE_PEAK
    ]

    group_values: dict[str, list[dict[str, float | int]]] = {}
    for result, measurements in decoded:
        if measurements["peak_linear"] <= SILENCE_PEAK:
            continue
        metadata = result["stratification"]
        assert isinstance(metadata, dict)
        for group in (metadata["specific_group"], metadata["kind_group"]):
            if isinstance(group, str):
                group_values.setdefault(group, []).append(measurements)
    group_sizes = {group: len(values) for group, values in group_values.items()}
    baseline_distributions: dict[str, dict[str, Any]] = {}
    for group, values in sorted(group_values.items()):
        baseline_distributions[group] = {
            "count": len(values),
            "duration_seconds": _distribution(
                [float(measurements["duration_seconds"]) for measurements in values]
            ),
            "rms_db": _distribution(
                [float(measurements["rms_db"]) for measurements in values]
            ),
            "eligible_for_row_outlier_review": len(values) >= MIN_OUTLIER_BASELINE_SAMPLES,
        }

    for result, measurements in decoded:
        reasons: list[str] = []
        duration = float(measurements["duration_seconds"])
        peak = float(measurements["peak_linear"])
        clipped_fraction = float(measurements["clipped_fraction"])
        if peak <= SILENCE_PEAK:
            reasons.append("silent_audio")
        if (
            int(measurements["clipped_sample_count"]) >= CLIP_MIN_SAMPLES
            and clipped_fraction >= CLIP_FRACTION
        ):
            reasons.append("clipped_audio")
        if duration < SHORT_DURATION_SECONDS:
            reasons.append("duration_below_minimum")
        if duration > LONG_DURATION_SECONDS:
            reasons.append("duration_above_maximum")
        metadata = result["stratification"]
        assert isinstance(metadata, dict)
        baseline_group, fallback = _baseline_group(metadata, group_sizes)
        metadata["baseline_group"] = baseline_group
        metadata["fallback"] = fallback
        if peak > SILENCE_PEAK and baseline_group:
            baseline = baseline_distributions[baseline_group]
            duration_outlier = _outlier(
                duration,
                baseline["duration_seconds"],
                OUTLIER_IQR_MULTIPLIER,
            )
            if duration_outlier:
                reasons.append(f"duration_outlier_{duration_outlier}")
            level_outlier = _outlier(
                float(measurements["rms_db"]),
                baseline["rms_db"],
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
            "clip_minimum_samples": CLIP_MIN_SAMPLES,
            "clip_fraction": CLIP_FRACTION,
            "clip_rule": "clipped_sample_count >= clip_minimum_samples AND clipped_fraction >= clip_fraction",
            "duration_outlier_iqr_multiplier": OUTLIER_IQR_MULTIPLIER,
            "level_outlier_iqr_multiplier": LEVEL_OUTLIER_IQR_MULTIPLIER,
            "minimum_outlier_baseline_samples": MIN_OUTLIER_BASELINE_SAMPLES,
        },
        "population": {
            "stratification": {
                "fields": ["kind", "text_length_bucket"],
                "group_order": "kind_and_text_length, then kind_only",
                "sparse_group_policy": "absolute checks remain active; statistical outlier review is omitted",
            },
            "baseline_groups": baseline_distributions,
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
