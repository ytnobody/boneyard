#!/bin/bash
# test-validate.sh - Unit tests for scripts/validate-meta.sh
#
# Runs validate-meta.sh against a set of valid/invalid meta.toml fixtures and
# asserts the exit code and output.

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VALIDATE="$ROOT/scripts/validate-meta.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

expect_ok() {
  local label=$1 path=$2
  if "$VALIDATE" "$path" >/dev/null 2>&1; then
    echo "  ok  : $label"
    pass=$((pass + 1))
  else
    echo "  FAIL: $label (expected pass)"
    fail=$((fail + 1))
  fi
}

expect_fail() {
  local label=$1 path=$2
  if "$VALIDATE" "$path" >/dev/null 2>&1; then
    echo "  FAIL: $label (expected failure)"
    fail=$((fail + 1))
  else
    echo "  ok  : $label"
    pass=$((pass + 1))
  fi
}

# --- fixtures ---
cat > "$TMP/valid.toml" <<'EOF'
name = "my-lib"
author = "YTNOBODY"
description = "A test library"
license = "MIT"
keywords = ["test"]
EOF

cat > "$TMP/single-char-name.toml" <<'EOF'
name = "a"
author = "YTNOBODY"
description = "single char name"
EOF

cat > "$TMP/missing-name.toml" <<'EOF'
author = "YTNOBODY"
description = "missing name"
EOF

cat > "$TMP/uppercase-name.toml" <<'EOF'
name = "MyLib"
author = "YTNOBODY"
description = "uppercase name is invalid"
EOF

cat > "$TMP/missing-author.toml" <<'EOF'
name = "my-lib"
description = "missing author"
EOF

cat > "$TMP/empty-file.toml" <<'EOF'
EOF

echo "Testing validate-meta.sh"
expect_ok  "valid module"        "$TMP/valid.toml"
expect_ok  "single char name"    "$TMP/single-char-name.toml"
expect_fail "missing name field"  "$TMP/missing-name.toml"
expect_fail "uppercase name"     "$TMP/uppercase-name.toml"
expect_fail "missing author"     "$TMP/missing-author.toml"
expect_fail "empty file"         "$TMP/empty-file.toml"

# usage / missing file
if "$VALIDATE" >/dev/null 2>&1; then
  echo "  FAIL: no args should fail"
  fail=$((fail + 1))
else
  echo "  ok  : usage error with no args"
  pass=$((pass + 1))
fi
if "$VALIDATE" "$TMP/does-not-exist.toml" >/dev/null 2>&1; then
  echo "  FAIL: missing file should fail"
  fail=$((fail + 1))
else
  echo "  ok  : missing file fails"
  pass=$((pass + 1))
fi

echo
echo "validate-meta.sh: $pass passed, $fail failed"
[[ $fail -eq 0 ]]