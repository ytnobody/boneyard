#!/bin/bash
set -e

# Optional: GitHub token for higher rate limits
# export GITHUB_TOKEN="your_token_here"

AUTH_HEADER=""
if [[ -n "$GITHUB_TOKEN" ]]; then
  AUTH_HEADER="-H \"Authorization: token $GITHUB_TOKEN\""
fi

github_api() {
  local url=$1
  if [[ -n "$GITHUB_TOKEN" ]]; then
    curl -fsSL -H "Authorization: token $GITHUB_TOKEN" "$url" 2>/dev/null
  else
    curl -fsSL "$url" 2>/dev/null
  fi
}

# Find all meta.toml files in index
find index -name 'meta.toml' 2>/dev/null | while read meta; do
  DIR=$(dirname "$meta")
  SOURCE_URL=$(grep '^source_url = ' "$meta" | sed 's/^source_url = "\(.*\)"$/\1/' || true)

  if [[ -z "$SOURCE_URL" ]]; then
    echo "Skipping $meta: no source_url"
    continue
  fi

  echo "Crawling: $SOURCE_URL"

  # Extract repo path from GitHub URL
  REPO=$(echo "$SOURCE_URL" | sed 's|https://github.com/||')

  # Get releases via GitHub API
  RELEASES=$(github_api "https://api.github.com/repos/${REPO}/releases" || echo "[]")

  if [[ "$RELEASES" == "[]" || -z "$RELEASES" ]]; then
    echo "  No releases found"
  else
    # Process each release
    echo "$RELEASES" | jq -c '.[]' 2>/dev/null | while read release; do
      TAG=$(echo "$release" | jq -r '.tag_name')
      VERSION=$(echo "$TAG" | sed 's/^v//')
      PUBLISHED=$(echo "$release" | jq -r '.published_at')

      # Skip if already exists
      if [[ -f "$DIR/${VERSION}.toml" ]]; then
        continue
      fi

      # Get commit SHA for this tag
      TAG_INFO=$(github_api "https://api.github.com/repos/${REPO}/git/ref/tags/${TAG}" || echo "{}")
      COMMIT=$(echo "$TAG_INFO" | jq -r '.object.sha // empty')

      # If it's an annotated tag, we need to dereference it
      OBJ_TYPE=$(echo "$TAG_INFO" | jq -r '.object.type // empty')
      if [[ "$OBJ_TYPE" == "tag" ]]; then
        TAG_OBJ=$(github_api "https://api.github.com/repos/${REPO}/git/tags/${COMMIT}" || echo "{}")
        COMMIT=$(echo "$TAG_OBJ" | jq -r '.object.sha // empty')
      fi

      echo "  Adding version: $VERSION (tag: $TAG)"

      # Create version file
      cat > "$DIR/${VERSION}.toml" <<EOF
version = "$VERSION"
tag = "$TAG"
commit = "$COMMIT"
published = "$PUBLISHED"
EOF
    done
  fi

  # Update latest.toml
  LATEST_TAG=$(echo "$RELEASES" | jq -r '.[0].tag_name // empty' 2>/dev/null || true)

  if [[ -n "$LATEST_TAG" && "$LATEST_TAG" != "null" ]]; then
    VERSION=$(echo "$LATEST_TAG" | sed 's/^v//')
    TAG_INFO=$(github_api "https://api.github.com/repos/${REPO}/git/ref/tags/${LATEST_TAG}" || echo "{}")
    COMMIT=$(echo "$TAG_INFO" | jq -r '.object.sha // empty')

    # Dereference annotated tag if needed
    OBJ_TYPE=$(echo "$TAG_INFO" | jq -r '.object.type // empty')
    if [[ "$OBJ_TYPE" == "tag" ]]; then
      TAG_OBJ=$(github_api "https://api.github.com/repos/${REPO}/git/tags/${COMMIT}" || echo "{}")
      COMMIT=$(echo "$TAG_OBJ" | jq -r '.object.sha // empty')
    fi

    cat > "$DIR/latest.toml" <<EOF
version = "$VERSION"
tag = "$LATEST_TAG"
commit = "$COMMIT"
updated = "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
  else
    # No releases, use main HEAD
    MAIN_REF=$(github_api "https://api.github.com/repos/${REPO}/git/ref/heads/main" || echo "{}")
    COMMIT=$(echo "$MAIN_REF" | jq -r '.object.sha // empty')

    if [[ -z "$COMMIT" || "$COMMIT" == "null" ]]; then
      # Try master branch
      MASTER_REF=$(github_api "https://api.github.com/repos/${REPO}/git/ref/heads/master" || echo "{}")
      COMMIT=$(echo "$MASTER_REF" | jq -r '.object.sha // empty')
    fi

    cat > "$DIR/latest.toml" <<EOF
version = ""
tag = ""
commit = "$COMMIT"
updated = "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
  fi

  echo "  Updated latest.toml"
done

echo "Crawl complete"
