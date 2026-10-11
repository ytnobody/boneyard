#!/bin/bash
# test-build-search.sh - Unit tests for scripts/build-search.sh
#
# Builds a throwaway index tree with a few modules, runs build-search.sh into a
# temp output, and verifies the generated JSON.

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/scripts/build-search.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

check() {
  local label=$1
  if [[ $2 -eq 0 ]]; then
    echo "  ok  : $label"
    pass=$((pass + 1))
  else
    echo "  FAIL: $label"
    fail=$((fail + 1))
  fi
}

# --- fixtures: two modules in the A/AU/AUTHOR/name layout ---
mkdir -p "$TMP/index/y/yt/ytnobody/json"
cat > "$TMP/index/y/yt/ytnobody/json/meta.toml" <<'EOF'
name = "json"
author = "ytnobody"
description = "json parser / builder"
license = "MIT"
keywords = ["json", "data"]
EOF
cat > "$TMP/index/y/yt/ytnobody/json/latest.toml" <<'EOF'
version = "1.0.0"
tag = "v1.0.0"
commit = "abc123"
updated = "2026-10-11T00:00:00Z"
EOF

mkdir -p "$TMP/index/j/jo/johndoe/http"
cat > "$TMP/index/j/jo/johndoe/http/meta.toml" <<'EOF'
name = "http"
author = "JOHNDOE"
description = "http client"
license = "MIT"
keywords = ["http", "net"]
EOF
cat > "$TMP/index/j/jo/johndoe/http/latest.toml" <<'EOF'
version = "0.2.1"
tag = "v0.2.1"
commit = "def456"
updated = "2026-10-11T00:00:00Z"
EOF

# Module with no releases (latest.toml has empty version)
mkdir -p "$TMP/index/m/my/mydev/util"
cat > "$TMP/index/m/my/mydev/util/meta.toml" <<'EOF'
name = "util"
author = "mydev"
description = "utility helpers"
license = "MIT"
keywords = []
EOF
cat > "$TMP/index/m/my/mydev/util/latest.toml" <<'EOF'
version = ""
tag = ""
commit = "aaa111"
updated = "2026-10-11T00:00:00Z"
EOF

echo "Testing build-search.sh"
OUT="$TMP/out/search.json"
(cd "$TMP" && "$BUILD" out/search.json >/dev/null 2>&1)
check "generates search.json" $?

COUNT=$(jq -r 'length' "$OUT")
check "indexes all modules (expected 3, got $COUNT)" $([[ "$COUNT" == "3" ]] && echo 0 || echo 1)

# first module (json) resolution
NAME=$(jq -r '.[] | select(.name=="json") | .name' "$OUT")
VER=$(jq -r '.[] | select(.name=="json") | .latest_version' "$OUT")
check "json latest_version is 1.0.0" $([[ "$VER" == "1.0.0" ]] && echo 0 || echo 1)
check "json present" $([[ "$NAME" == "json" ]] && echo 0 || echo 1)

# keywords array preserved
KW=$(jq -c '.[] | select(.name=="http") | .keywords' "$OUT")
check "http keywords = [\"http\",\"net\"]" $([[ "$KW" == '["http","net"]' ]] && echo 0 || echo 1)

# module with no releases has empty latest
NOVER=$(jq -r '.[] | select(.name=="util") | .latest_version' "$OUT")
check "util latest_version is empty" $([[ "$NOVER" == "" ]] && echo 0 || echo 1)

# author case is preserved from meta
AUTH=$(jq -r '.[] | select(.name=="http") | .author' "$OUT")
check "http author preserved" $([[ "$AUTH" == "JOHNDOE" ]] && echo 0 || echo 1)

echo
echo "build-search.sh: $pass passed, $fail failed"
[[ $fail -eq 0 ]]