#!/bin/bash
# build-search.sh - Generate index/search.json from the Boneyard index.
#
# Scans every registered module under index/ and emits a denormalized JSON
# index at <output> (default: index/search.json) for fast client-side search.
#
# Usage: build-search.sh [output-path]

set -e

OUT="${1:-index/search.json}"

# Module layout: index/A/AU/AUTHOR/name/meta.toml
META_FILES=$(find index -mindepth 5 -maxdepth 5 -name 'meta.toml' 2>/dev/null || true)

if [[ -z "$META_FILES" ]]; then
  echo "No modules found; writing empty array to $OUT"
  mkdir -p "$(dirname "$OUT")"
  echo "[]" > "$OUT"
  exit 0
fi

# One JSON object per line, then slurped into an array with jq.
ACC=$(mktemp)
trap 'rm -f "$ACC"' EXIT

echo "-- Building search index" >&2
printf '%s\n' "$META_FILES" | sort | while read -r meta; do
  DIR=$(dirname "$meta")
  REL=${meta#index/}

  AUTHOR=$(grep '^author = ' "$meta" 2>/dev/null | head -1 | sed 's/^author = "\(.*\)"$/\1/' || true)
  NAME=$(grep '^name = ' "$meta" 2>/dev/null | head -1 | sed 's/^name = "\(.*\)"$/\1/' || true)
  DESC=$(grep '^description = ' "$meta" 2>/dev/null | head -1 | sed 's/^description = "\(.*\)"$/\1/' || true)
  # keywords = ["a", "b"] is valid quoted JSON, use it directly.
  KEYS=$(grep '^keywords = ' "$meta" 2>/dev/null | head -1 | sed 's/^keywords = //' || true)
  if [[ -z "$KEYS" || "$KEYS" == "[]" ]]; then
    KEYS="[]"
  fi

  VER=""
  TAG=""
  if [[ -f "$DIR/latest.toml" ]]; then
    VER=$(grep '^version = ' "$DIR/latest.toml" 2>/dev/null | head -1 | sed 's/^version = "\(.*\)"$/\1/' || true)
    TAG=$(grep '^tag = ' "$DIR/latest.toml" 2>/dev/null | head -1 | sed 's/^tag = "\(.*\)"$/\1/' || true)
  fi

  jq -nc \
    --arg author "$AUTHOR" \
    --arg name "$NAME" \
    --arg path "$(dirname "$REL")" \
    --arg description "$DESC" \
    --argjson keywords "$KEYS" \
    --arg latest_version "$VER" \
    --arg latest_tag "$TAG" \
    '{author:$author,name:$name,path:$path,description:$description,keywords:$keywords,latest_version:$latest_version,latest_tag:$latest_tag}' \
    >> "$ACC"
done

mkdir -p "$(dirname "$OUT")"
jq -s '.' "$ACC" > "$OUT"
echo "Wrote $OUT ($(jq -r 'length' "$OUT") modules)" >&2