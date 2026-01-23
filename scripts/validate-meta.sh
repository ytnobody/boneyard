#!/bin/bash
set -e

FILE=$1

if [[ -z "$FILE" ]]; then
  echo "Usage: validate-meta.sh <meta.toml>"
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "File not found: $FILE"
  exit 1
fi

# Check required fields
check_field() {
  local field=$1
  if ! grep -q "^${field} = " "$FILE"; then
    echo "Missing required field: $field"
    exit 1
  fi
}

check_field "name"
check_field "author"
check_field "description"

# Extract values
NAME=$(grep '^name = ' "$FILE" | sed 's/^name = "\(.*\)"$/\1/')
AUTHOR=$(grep '^author = ' "$FILE" | sed 's/^author = "\(.*\)"$/\1/')

# Validate author is uppercase
if [[ "$AUTHOR" != "${AUTHOR^^}" ]]; then
  echo "Author must be uppercase: $AUTHOR (expected: ${AUTHOR^^})"
  exit 1
fi

# Validate name format (lowercase, alphanumeric, hyphens)
if [[ ! "$NAME" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$ ]]; then
  echo "Invalid module name: $NAME (must be lowercase alphanumeric with hyphens)"
  exit 1
fi

echo "Validation passed"
echo "  name: $NAME"
echo "  author: $AUTHOR"
