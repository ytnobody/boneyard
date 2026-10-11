#!/bin/bash
# test-all.sh - Run all Boneyard script unit tests.

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== validate-meta.sh ==="
"$ROOT/scripts/test-validate.sh"

echo
echo "=== build-search.sh ==="
"$ROOT/scripts/test-build-search.sh"

echo
echo "All script tests passed."