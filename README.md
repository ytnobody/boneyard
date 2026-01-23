# Boneyard

The official module registry for [Calcium](https://github.com/calcium-lang/calcium).

## Overview

Boneyard is a GitHub-based module registry where Calcium packages are registered via Pull Requests. The actual module code stays in authors' repositories - only metadata is stored here.

## Using Modules

```calcium
// Import a module from Boneyard
use "https://boneyard.ca.land/AUTHOR/module@1.0.0/mod.ca"!;

// Example
use "https://boneyard.ca.land/JOHNDOE/http@1.0.0/client.ca"!;
```

## Publishing a Module

### 1. Prepare your module

```
my-calcium-lib/
├── mod.ca              # Entry point
├── lib.ca
└── README.md
```

### 2. Create a git tag

```bash
git tag v1.0.0
git push origin v1.0.0
```

### 3. Calculate file hashes

```bash
sha256sum mod.ca lib.ca
```

### 4. Submit a Pull Request

Fork this repository and add your module:

```bash
# Create directory structure
mkdir -p packages/Y/YO/YOURNAME/my-lib

# Create meta.toml
cat > packages/Y/YO/YOURNAME/my-lib/meta.toml << 'EOF'
name = "my-lib"
author = "YOURNAME"
description = "My awesome library"
repository = "https://github.com/yourname/my-calcium-lib"
license = "MIT"
keywords = ["utility"]
latest = "1.0.0"
EOF

# Create version file
cat > packages/Y/YO/YOURNAME/my-lib/1.0.0.toml << 'EOF'
version = "1.0.0"
published = "2025-01-23"
entry = "mod.ca"
base_url = "https://raw.githubusercontent.com/yourname/my-calcium-lib/v1.0.0/"

[files]
"mod.ca" = "sha256:a1b2c3d4..."
"lib.ca" = "sha256:b2c3d4e5..."
EOF

git add .
git commit -m "Add YOURNAME/my-lib@1.0.0"
```

Then create a Pull Request!

## Directory Structure

```
boneyard/
├── index/
│   ├── all.toml        # All modules (auto-generated)
│   └── {A-Z}.toml      # By author initial (auto-generated)
├── packages/
│   └── {A}/{AB}/{AUTHOR}/{MODULE}/
│       ├── meta.toml       # Module metadata
│       └── {VERSION}.toml  # Version-specific file list
└── scripts/
    ├── validate.sh     # PR validation
    └── build-index.sh  # Index generation
```

## Validation

All PRs are automatically validated:

- TOML format check
- URL reachability verification
- Checksum validation
- License documentation check

## License

Modules without a specified license are auto-assigned MIT license.

---

Part of the [Calcium](https://github.com/calcium-lang/calcium) project.
