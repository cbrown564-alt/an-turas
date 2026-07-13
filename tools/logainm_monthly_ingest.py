#!/usr/bin/env python3
"""Fetch monthly Logainm v1.1 changes into a provenance-preserving snapshot.

Official contract: X-Api-Key authentication, one-indexed pagination, maximum 1,000
rows per page, and ModifiedSince incremental filtering. The API key is never placed
in a URL or written to output.
"""

from __future__ import annotations

import argparse
import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable


API_ROOT = "https://www.logainm.ie/api/v1.1/"
ATTRIBUTION = "Irish-language placename data by Logainm © Government of Ireland and licensed under CC BY 4.0."
FetchPage = Callable[[int, str | None], dict]


def field(value: dict, *names: str):
    """Read both the documented PascalCase and live camelCase API fields."""
    for name in names:
        if name in value:
            return value[name]
    return None


def api_fetcher(api_key: str, delay: float) -> FetchPage:
    last_request = 0.0

    def fetch(page: int, modified_since: str | None) -> dict:
        nonlocal last_request
        wait = delay - (time.monotonic() - last_request)
        if wait > 0:
            time.sleep(wait)
        parameters = {"Page": page, "PerPage": 1000}
        if modified_since:
            parameters["ModifiedSince"] = modified_since
        url = API_ROOT + "?" + urllib.parse.urlencode(parameters)
        request = urllib.request.Request(
            url,
            headers={"X-Api-Key": api_key, "Accept": "application/json"},
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                last_request = time.monotonic()
                return json.load(response)
        except urllib.error.HTTPError as error:
            if error.code == 401:
                raise SystemExit("Logainm rejected LOGAINM_API_KEY") from error
            if error.code == 429:
                raise SystemExit("Logainm rate limit reached; stop and retry later") from error
            raise

    return fetch


def update_snapshot(existing: dict | None, modified_since: str | None, fetch: FetchPage) -> dict:
    records = {
        str(field(item, "ID", "id")): item for item in (existing or {}).get("records", [])
    }
    page = 1
    total_pages = 1
    while page <= total_pages:
        payload = fetch(page, modified_since)
        total_pages = int(field(payload, "TotalPages", "totalPages") or 1)
        current_page = field(payload, "CurrentPage", "currentPage")
        if int(current_page or page) != page:
            raise ValueError(f"Logainm returned page {current_page} while page {page} was requested")
        for item in field(payload, "Results", "results") or []:
            place_id = str(field(item, "ID", "id"))
            replacement = field(item, "ReplacementID", "replacementID", "replacementId")
            if replacement:
                records.pop(place_id, None)
            else:
                records[place_id] = item
        page += 1

    fetched_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    return {
        "schemaVersion": 1,
        "apiVersion": "1.1",
        "fetchedAt": fetched_at,
        "modifiedSince": modified_since,
        "attribution": ATTRIBUTION,
        "licence": "CC BY 4.0",
        "source": API_ROOT,
        "records": sorted(records.values(), key=lambda item: int(field(item, "ID", "id"))),
    }


def atomic_write(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    temporary.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    parser.add_argument("--modified-since", help="ISO date; defaults to the prior snapshot fetch date")
    parser.add_argument("--delay", type=float, default=1.0, help="minimum seconds between API pages")
    args = parser.parse_args()
    key = os.environ.get("LOGAINM_API_KEY")
    if not key:
        raise SystemExit("Set LOGAINM_API_KEY from the Gaois Developer Hub")
    existing = json.loads(args.output.read_text(encoding="utf-8")) if args.output.exists() else None
    modified_since = args.modified_since
    if modified_since is None and existing and existing.get("fetchedAt"):
        modified_since = existing["fetchedAt"][:10]
    snapshot = update_snapshot(existing, modified_since, api_fetcher(key, args.delay))
    atomic_write(args.output, snapshot)
    print(f"Stored {len(snapshot['records'])} Logainm records in {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
