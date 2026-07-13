#!/usr/bin/env python3
"""Build independently signed, versioned personal-atlas detail packs.

Input must already be the release-gated output of publish_personal_atlas.py. The
private Ed25519 key is supplied at release time and is never stored in the repo.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path


def canonical_json(value: object) -> bytes:
    return json.dumps(
        value, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")


def sign(data: bytes, private_key: Path) -> str:
    # Ed25519 is a one-shot algorithm. Some OpenSSL builds cannot determine the
    # input size when pkeyutl reads a pipe, so give it a real, short-lived file.
    with tempfile.NamedTemporaryFile() as source:
        source.write(data)
        source.flush()
        process = subprocess.run(
            [
                "openssl", "pkeyutl", "-sign", "-rawin", "-inkey",
                str(private_key), "-in", source.name,
            ],
            capture_output=True,
            check=False,
        )
    if process.returncode:
        raise SystemExit(process.stderr.decode("utf-8", errors="replace").strip())
    return base64.b64encode(process.stdout).decode("ascii")


def build_release(
    source: dict,
    output: Path,
    private_key: Path | None,
    public_key_id: str,
    allow_empty: bool,
) -> dict:
    subjects = source.get("subjects", [])
    if subjects and private_key is None:
        raise SystemExit("A private Ed25519 signing key is required for a non-empty release.")
    if not subjects and not allow_empty:
        raise SystemExit("Refusing an empty detail-pack release without --allow-empty.")

    subject_directory = output / "subjects"
    subject_directory.mkdir(parents=True, exist_ok=True)
    artifacts = []
    index = []

    for subject in subjects:
        data = canonical_json(subject)
        subject_id = subject["id"]
        filename = f"{subject_id}.json"
        (subject_directory / filename).write_bytes(data)
        artifacts.append(
            {
                "subjectId": subject_id,
                "version": subject["editorial"]["contentVersion"],
                "path": f"subjects/{filename}",
                "sha256": hashlib.sha256(data).hexdigest(),
                "signature": sign(data, private_key),
                "contentDate": source["contentDate"],
            }
        )
        index.append(
            {
                "id": subject_id,
                "kind": subject["kind"],
                "canonicalDisplay": subject["canonicalDisplay"],
                "variants": subject["variants"],
                "subtitle": subject["subtitle"],
            }
        )

    release = {
        "releaseId": f"personal-atlas-{source['version']}-{source['contentDate']}",
        "version": source["version"],
        "contentDate": source["contentDate"],
        "publicKeyId": public_key_id,
        "artifacts": artifacts,
    }
    (output / "manifest.json").write_text(
        json.dumps(release, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (output / "index.json").write_text(
        json.dumps(
            {
                "version": source["version"],
                "contentDate": source["contentDate"],
                "attribution": source["attribution"],
                "subjects": index,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    return release


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--private-key", type=Path)
    parser.add_argument("--public-key-id", default="anturas-personal-atlas-v1")
    parser.add_argument("--allow-empty", action="store_true")
    args = parser.parse_args()

    source = json.loads(args.source.read_text(encoding="utf-8"))
    release = build_release(
        source,
        args.output,
        args.private_key,
        args.public_key_id,
        args.allow_empty,
    )
    print(f"Built {len(release['artifacts'])} signed detail packs in {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
