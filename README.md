<p align="center">
  <img src="resources/boneyard-logo.png" alt="Boneyard" width="200">
</p>

# Boneyard

The official module registry for [Calcium](https://github.com/ytnobody/calcium-lang).

## Overview

Boneyard is a module registry that automatically indexes Calcium packages. Authors register their module's `meta.toml` URL, and Boneyard periodically crawls repositories to collect version information from Git releases.

## Using Modules

```calcium
// Import a specific version
use "https://boneyard.ca.land/AUTHOR/module@1.0.0/mod.ca"!;

// Import a specific commit
use "https://boneyard.ca.land/AUTHOR/module@abc1234/mod.ca"!;

// Import latest (latest release, or main HEAD if no releases)
use "https://boneyard.ca.land/AUTHOR/module/mod.ca"!;
```

## Publishing a Module

### 1. Add meta.toml to your repository

Create `meta.toml` in your repository root:

```toml
name = "my-lib"
author = "YOURNAME"
description = "My awesome library"
license = "MIT"
keywords = ["utility", "helper"]
entry = "mod.ca"
```

### 2. (Optional) Create a release

```bash
git tag v1.0.0
git push origin v1.0.0
```

If you create releases, users can install specific versions. Without releases, users can specify commit hashes or get the latest main branch.

### 3. Submit your module

[Open an issue](https://github.com/ytnobody/boneyard/issues/new) with:

- The URL to your `meta.toml` (e.g., `https://github.com/yourname/my-lib/blob/main/meta.toml`)

That's it! Boneyard will crawl your repository and index available versions.

## Version Resolution

| User specifies | What gets installed |
|----------------|---------------------|
| `@1.0.0` | Exact version (from release tag `v1.0.0`) |
| `@abc1234` | Exact commit |
| (nothing) | Latest release, or main HEAD if no releases |

## meta.toml Reference

```toml
# Required
name = "my-lib"              # Module name
author = "YOURNAME"          # Author name (uppercase)
description = "Description"  # Brief description

# Optional
license = "MIT"              # Default: MIT
keywords = ["tag1", "tag2"]  # For search
entry = "mod.ca"             # Entry point (default: mod.ca)
```

## How It Works

1. Authors submit `meta.toml` URL via issue
2. Boneyard fetches `meta.toml`, adds `source_url`, and saves to `index/`
3. Boneyard periodically crawls `index/`, checking each `source_url`
4. Release tags and latest commit are saved as TOML files
5. Users can install any indexed version

## Directory Structure

```
boneyard/
├── index/
│   └── A/AU/AUTHOR/module-name/
│       ├── meta.toml                # Module metadata + source URL
│       ├── 0.1.2.toml               # Release v0.1.2
│       ├── 0.2.0.toml               # Release v0.2.0
│       └── latest.toml              # Latest (newest release or main HEAD)
└── tags/
    └── {keyword}/
        └── A/AU/AUTHOR/
            └── module-name -> (symlink to index)
```

The `tags/` directory contains symlinks organized by keyword, enabling fast tag-based search without data duplication.

### meta.toml

```toml
name = "module-name"
author = "AUTHOR"
description = "A brief description"
license = "MIT"
keywords = ["utility", "helper"]
entry = "mod.ca"
source_url = "https://github.com/author/module-name"
```

The crawler traverses `index/` and fetches updates from each `source_url`.

### Version TOML (e.g., 0.1.2.toml)

```toml
version = "0.1.2"
tag = "v0.1.2"
commit = "abc1234def5678..."
published = "2025-01-23T10:00:00Z"
```

### latest.toml

```toml
version = "0.2.0"          # or null if no releases
tag = "v0.2.0"             # or null
commit = "def5678abc1234..."
updated = "2025-01-23T12:00:00Z"
```

---

Part of the [Calcium](https://github.com/ytnobody/calcium-lang) project.
