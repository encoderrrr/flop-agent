#!/usr/bin/env python3
"""Print this Agent's public DID without making a network request.

If the identity file is missing, the first run creates a new local identity.
Restore an encrypted backup before running this command when the old DID must
be preserved.
"""

from agent import load_or_create_identity


def main() -> int:
    _private_key, did = load_or_create_identity()
    print(did)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
