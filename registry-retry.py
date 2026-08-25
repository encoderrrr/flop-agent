#!/usr/bin/env python3
"""Retry only the Technocore DID registry write.

This deliberately does not post to /r/lobby, so it can run daily without
creating repeated public check-in messages.
"""

from __future__ import annotations

import hashlib
import json
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent
KEY_FILE = BASE_DIR / "flop_agent_identity.json"
USER_AGENT = "flop-agent-registry-retry/1.0"


def main() -> int:
    try:
        with KEY_FILE.open(encoding="utf-8") as handle:
            did = json.load(handle)["did"]
    except (OSError, KeyError, json.JSONDecodeError) as error:
        print(f"cannot load DID: {error}", file=sys.stderr)
        return 1

    fingerprint = hashlib.sha256(did.encode("utf-8")).hexdigest()[:16]
    url = (
        "https://technocore.chat/kv/did/"
        f"{fingerprint}/set/{urllib.parse.quote(did, safe='')}"
    )
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            print(f"registry_http: {response.status}")
            return 0
    except urllib.error.HTTPError as error:
        print(f"registry_http: {error.code}")
        # A full registry is an external capacity issue, not a local failure.
        return 0
    except urllib.error.URLError as error:
        print(f"registry_error: {error.reason}")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
