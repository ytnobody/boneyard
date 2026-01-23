#!/bin/bash
# Verify URLs and checksums for a version file
# Usage: ./scripts/verify-files.sh <version.toml>

set -e

FILE="$1"

if [ -z "$FILE" ]; then
    echo "Usage: $0 <version.toml>"
    exit 1
fi

echo "Verifying files for: $FILE"

python3 << EOF
import sys
import urllib.request
import hashlib

try:
    import tomllib
except ImportError:
    import tomli as tomllib

with open("$FILE", "rb") as f:
    data = tomllib.load(f)

base_url = data.get("base_url", "")
files = data.get("files", {})

if not base_url:
    print("Error: base_url is required")
    sys.exit(1)

if not files:
    print("Error: files section is required")
    sys.exit(1)

errors = []

for filepath, expected_hash in files.items():
    url = base_url.rstrip("/") + "/" + filepath
    print(f"Checking: {url}")

    try:
        with urllib.request.urlopen(url, timeout=30) as response:
            content = response.read()

            # Check hash if provided with sha256: prefix
            if expected_hash.startswith("sha256:"):
                expected = expected_hash[7:]
                actual = hashlib.sha256(content).hexdigest()
                if actual != expected:
                    errors.append(f"Hash mismatch for {filepath}: expected {expected}, got {actual}")
                else:
                    print(f"  Hash OK: {filepath}")
            else:
                # Legacy format or just presence check
                print(f"  Reachable: {filepath}")

    except urllib.error.URLError as e:
        errors.append(f"Cannot fetch {url}: {e}")
    except Exception as e:
        errors.append(f"Error checking {filepath}: {e}")

if errors:
    print("\nErrors found:")
    for err in errors:
        print(f"  - {err}")
    sys.exit(1)

print("\nAll files verified successfully!")
EOF
