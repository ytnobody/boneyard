# Contributing to Boneyard

Thank you for your interest in contributing to the Calcium module registry!

## Adding a New Module

### Prerequisites

1. Your module must be hosted in a public Git repository (GitHub recommended)
2. You must have created a version tag (e.g., `v1.0.0`)
3. Your module should include a `mod.ca` entry point

### Step-by-Step Guide

#### 1. Fork this repository

Click the "Fork" button on GitHub.

#### 2. Create your package directory

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/boneyard
cd boneyard

# Create directory (use uppercase for author name)
# Pattern: packages/{FIRST_LETTER}/{FIRST_TWO_LETTERS}/{AUTHOR}/{MODULE}
mkdir -p packages/J/JO/JOHNDOE/my-module
```

#### 3. Create meta.toml

```toml
# packages/J/JO/JOHNDOE/my-module/meta.toml

name = "my-module"
author = "JOHNDOE"
description = "A brief description of your module"
repository = "https://github.com/johndoe/calcium-my-module"
license = "MIT"
keywords = ["utility", "helper"]
latest = "1.0.0"
```

#### 4. Create version file

Calculate SHA256 hashes for your files:

```bash
sha256sum mod.ca lib.ca
```

Then create the version file:

```toml
# packages/J/JO/JOHNDOE/my-module/1.0.0.toml

version = "1.0.0"
published = "2025-01-23"
entry = "mod.ca"
base_url = "https://raw.githubusercontent.com/johndoe/calcium-my-module/v1.0.0/"

[files]
"mod.ca" = "sha256:abc123..."
"lib.ca" = "sha256:def456..."
```

#### 5. Submit Pull Request

```bash
git add .
git commit -m "Add JOHNDOE/my-module@1.0.0"
git push origin main
```

Then create a Pull Request on GitHub.

### Adding a New Version

1. Create a new tag in your module repository
2. Add a new version file (e.g., `1.1.0.toml`)
3. Update `latest` in `meta.toml`
4. Submit a Pull Request

## Validation

Your PR will be automatically validated for:

- Valid TOML syntax
- Required fields present
- URLs are reachable
- Checksums match

## License

If you don't specify a license, MIT will be auto-applied.

Recommended licenses:
- MIT (default)
- Apache-2.0
- BSD-3-Clause
- GPL-3.0

## Questions?

Open an issue if you have any questions!
