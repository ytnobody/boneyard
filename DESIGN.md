# Boneyard Registration System Design

## Overview

Issue-driven module registration with automatic PR creation.

## Flow

```
1. User creates Issue
   └─> Issue template with meta.toml URL

2. GitHub Actions: on issue opened
   ├─> Extract URL from issue body
   ├─> Fetch meta.toml from URL
   ├─> Validate meta.toml
   │   ├─ Required fields present?
   │   ├─ Author name valid?
   │   └─ Repository accessible?
   ├─> If invalid: comment on issue, add "invalid" label
   └─> If valid: create PR

3. PR contains:
   ├─> index/A/AU/AUTHOR/module-name/meta.toml
   │   (fetched content + source_url added)
   └─> tags/{keyword}/A/AU/AUTHOR/module-name (symlinks)

4. Maintainer reviews & merges PR

5. Post-merge: GitHub Actions
   └─> Close original issue with comment
```

## Issue Template

```markdown
---
name: Register Module
about: Register a new module to Boneyard
labels: registration
---

## meta.toml URL

<!-- Paste the raw URL to your meta.toml -->

```
https://raw.githubusercontent.com/AUTHOR/REPO/main/meta.toml
```
```

## GitHub Actions Workflows

### 1. `register.yml` - On Issue Created

```yaml
name: Process Registration

on:
  issues:
    types: [opened]

jobs:
  process:
    if: contains(github.event.issue.labels.*.name, 'registration')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Extract URL from issue
        id: extract
        run: |
          # Parse issue body for meta.toml URL
          URL=$(echo "${{ github.event.issue.body }}" | grep -oP 'https://[^\s`]+meta\.toml')
          echo "url=$URL" >> $GITHUB_OUTPUT

      - name: Fetch and validate meta.toml
        id: validate
        run: |
          # Fetch meta.toml
          curl -fsSL "${{ steps.extract.outputs.url }}" -o meta.toml

          # Validate with script
          ./scripts/validate-meta.sh meta.toml

      - name: Create directory structure
        if: success()
        run: |
          # Parse meta.toml
          AUTHOR=$(grep '^author' meta.toml | cut -d'"' -f2)
          NAME=$(grep '^name' meta.toml | cut -d'"' -f2)
          KEYWORDS=$(grep '^keywords' meta.toml | sed 's/.*\[\(.*\)\].*/\1/' | tr -d ' "')

          # Create path: A/AU/AUTHOR
          PREFIX1="${AUTHOR:0:1}"
          PREFIX2="${AUTHOR:0:2}"
          INDEX_PATH="index/${PREFIX1}/${PREFIX2}/${AUTHOR}/${NAME}"

          # Create index directory
          mkdir -p "$INDEX_PATH"

          # Add source_url to meta.toml
          REPO_URL=$(echo "${{ steps.extract.outputs.url }}" | sed 's|/blob/.*||' | sed 's|/raw/.*||' | sed 's|raw.githubusercontent.com|github.com|')
          echo "source_url = \"${REPO_URL}\"" >> meta.toml
          mv meta.toml "$INDEX_PATH/meta.toml"

          # Create symlinks for tags
          IFS=',' read -ra TAGS <<< "$KEYWORDS"
          for tag in "${TAGS[@]}"; do
            tag=$(echo "$tag" | tr -d ' ')
            TAG_PATH="tags/${tag}/${PREFIX1}/${PREFIX2}/${AUTHOR}"
            mkdir -p "$TAG_PATH"
            ln -s "../../../../../index/${PREFIX1}/${PREFIX2}/${AUTHOR}/${NAME}" "$TAG_PATH/${NAME}"
          done

      - name: Create Pull Request
        if: success()
        uses: peter-evans/create-pull-request@v5
        with:
          title: "Add ${{ env.AUTHOR }}/${{ env.NAME }}"
          body: |
            Automated PR for module registration.

            Issue: #${{ github.event.issue.number }}
            Source: ${{ steps.extract.outputs.url }}
          branch: "register/${{ env.AUTHOR }}-${{ env.NAME }}"
          labels: registration

      - name: Comment on failure
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: ${{ github.event.issue.number }},
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: 'Validation failed. Please check your meta.toml.'
            })
            github.rest.issues.addLabels({
              issue_number: ${{ github.event.issue.number }},
              owner: context.repo.owner,
              repo: context.repo.repo,
              labels: ['invalid']
            })
```

### 2. `close-issue.yml` - On PR Merged

```yaml
name: Close Registration Issue

on:
  pull_request:
    types: [closed]

jobs:
  close:
    if: github.event.pull_request.merged && contains(github.event.pull_request.labels.*.name, 'registration')
    runs-on: ubuntu-latest
    steps:
      - name: Extract issue number
        id: extract
        run: |
          # Parse PR body for issue number
          ISSUE=$(echo "${{ github.event.pull_request.body }}" | grep -oP 'Issue: #\K\d+')
          echo "issue=$ISSUE" >> $GITHUB_OUTPUT

      - name: Close issue
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: ${{ steps.extract.outputs.issue }},
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: 'Your module has been registered! It will be available shortly.'
            })
            github.rest.issues.update({
              issue_number: ${{ steps.extract.outputs.issue }},
              owner: context.repo.owner,
              repo: context.repo.repo,
              state: 'closed'
            })
```

### 3. `crawl.yml` - Periodic Crawl

```yaml
name: Crawl Repositories

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours
  workflow_dispatch:

jobs:
  crawl:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Crawl all modules
        run: ./scripts/crawl.sh

      - name: Commit updates
        run: |
          git config user.name "Boneyard Bot"
          git config user.email "bot@boneyard.ca.land"
          git add .
          git diff --staged --quiet || git commit -m "Update module versions"
          git push
```

## Scripts

### `scripts/validate-meta.sh`

```bash
#!/bin/bash
set -e

FILE=$1

# Check required fields
grep -q '^name = ' "$FILE" || { echo "Missing: name"; exit 1; }
grep -q '^author = ' "$FILE" || { echo "Missing: author"; exit 1; }
grep -q '^description = ' "$FILE" || { echo "Missing: description"; exit 1; }

# Validate author is uppercase
AUTHOR=$(grep '^author' "$FILE" | cut -d'"' -f2)
if [[ "$AUTHOR" != "${AUTHOR^^}" ]]; then
  echo "Author must be uppercase: $AUTHOR"
  exit 1
fi

echo "Validation passed"
```

### `scripts/crawl.sh`

```bash
#!/bin/bash
set -e

# Find all meta.toml files
find index -name 'meta.toml' | while read meta; do
  DIR=$(dirname "$meta")
  SOURCE_URL=$(grep '^source_url' "$meta" | cut -d'"' -f2)

  echo "Crawling: $SOURCE_URL"

  # Get releases via GitHub API
  REPO=$(echo "$SOURCE_URL" | sed 's|https://github.com/||')
  RELEASES=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases" 2>/dev/null || echo "[]")

  # Process each release
  echo "$RELEASES" | jq -c '.[]' | while read release; do
    TAG=$(echo "$release" | jq -r '.tag_name')
    VERSION=$(echo "$TAG" | sed 's/^v//')
    PUBLISHED=$(echo "$release" | jq -r '.published_at')
    COMMIT=$(curl -fsSL "https://api.github.com/repos/${REPO}/git/ref/tags/${TAG}" 2>/dev/null | jq -r '.object.sha // empty')

    # Skip if already exists
    [[ -f "$DIR/${VERSION}.toml" ]] && continue

    # Create version file
    cat > "$DIR/${VERSION}.toml" <<EOF
version = "${VERSION}"
tag = "${TAG}"
commit = "${COMMIT}"
published = "${PUBLISHED}"
EOF
  done

  # Update latest.toml
  LATEST_TAG=$(echo "$RELEASES" | jq -r '.[0].tag_name // empty')
  if [[ -n "$LATEST_TAG" ]]; then
    VERSION=$(echo "$LATEST_TAG" | sed 's/^v//')
    COMMIT=$(curl -fsSL "https://api.github.com/repos/${REPO}/git/ref/tags/${LATEST_TAG}" 2>/dev/null | jq -r '.object.sha // empty')
  else
    # No releases, use main HEAD
    VERSION=""
    COMMIT=$(curl -fsSL "https://api.github.com/repos/${REPO}/git/ref/heads/main" 2>/dev/null | jq -r '.object.sha // empty')
  fi

  cat > "$DIR/latest.toml" <<EOF
version = "${VERSION:-null}"
tag = "${LATEST_TAG:-null}"
commit = "${COMMIT}"
updated = "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
done
```

## Security Considerations

1. **URL validation**: Only accept GitHub/GitLab URLs
2. **Rate limiting**: GitHub API has rate limits, use token for authenticated requests
3. **Malicious content**: meta.toml is just metadata, no code execution
4. **Symlink safety**: Symlinks only point within the repository

## Future Enhancements

- [ ] Support GitLab, Codeberg, etc.
- [ ] Webhook-based updates (instead of polling)
- [ ] Search API endpoint
- [ ] Module statistics (downloads, stars)
