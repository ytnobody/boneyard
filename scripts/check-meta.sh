#!/bin/bash
# Check required fields in meta.toml
# Usage: ./scripts/check-meta.sh <meta.toml>

set -e

FILE="$1"

if [ -z "$FILE" ]; then
    echo "Usage: $0 <meta.toml>"
    exit 1
fi

echo "Checking required fields: $FILE"

python3 << EOF
import sys

try:
    import tomllib
except ImportError:
    import tomli as tomllib

REQUIRED_FIELDS = ["name", "author", "description", "repository", "latest"]
RECOMMENDED_FIELDS = ["license", "keywords"]

with open("$FILE", "rb") as f:
    data = tomllib.load(f)

errors = []
warnings = []

# Check required fields
for field in REQUIRED_FIELDS:
    if field not in data:
        errors.append(f"Missing required field: {field}")
    elif not data[field]:
        errors.append(f"Empty required field: {field}")

# Check recommended fields
for field in RECOMMENDED_FIELDS:
    if field not in data:
        warnings.append(f"Missing recommended field: {field}")

# Validate repository URL
if "repository" in data:
    repo = data["repository"]
    if not repo.startswith("https://"):
        errors.append(f"Repository must be HTTPS URL: {repo}")

# Validate license if present
if "license" in data:
    license = data["license"]
    valid_licenses = ["MIT", "Apache-2.0", "BSD-3-Clause", "BSD-2-Clause",
                      "GPL-3.0", "GPL-2.0", "LGPL-3.0", "MPL-2.0", "ISC", "Unlicense"]
    if license not in valid_licenses:
        warnings.append(f"Unknown license: {license} (consider using SPDX identifier)")

# Print results
if warnings:
    print("Warnings:")
    for w in warnings:
        print(f"  - {w}")

if errors:
    print("\nErrors:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)

# Auto-apply MIT license warning
if "license" not in data:
    print("\nNote: No license specified. MIT license will be auto-applied.")

print("\nMeta check passed!")
EOF
