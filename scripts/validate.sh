#!/bin/bash
# Validate TOML file format
# Usage: ./scripts/validate.sh <file.toml>

set -e

FILE="$1"

if [ -z "$FILE" ]; then
    echo "Usage: $0 <file.toml>"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

echo "Validating TOML: $FILE"

# Check if file is valid TOML using Python (available on GitHub Actions)
python3 << EOF
import sys
try:
    import tomllib
except ImportError:
    import tomli as tomllib

try:
    with open("$FILE", "rb") as f:
        tomllib.load(f)
    print("TOML syntax: OK")
except Exception as e:
    print(f"TOML syntax error: {e}")
    sys.exit(1)
EOF

echo "Validation passed: $FILE"
