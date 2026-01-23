# Contributing to Boneyard

Thank you for your interest in contributing to the Calcium module registry!

## Registering Your Module

### Prerequisites

1. Your module must be hosted in a public Git repository (GitHub, GitLab, etc.)
2. Your repository must contain a `meta.toml` file

### Step 1: Create meta.toml

Add `meta.toml` to your repository root:

```toml
name = "my-module"
author = "YOURNAME"
description = "A brief description of your module"
license = "MIT"
keywords = ["utility", "helper"]
entry = "mod.ca"
```

### Step 2: Open an Issue

[Create a new issue](https://github.com/calcium-lang/boneyard/issues/new) with the URL to your `meta.toml`:

```
https://github.com/yourname/my-module/blob/main/meta.toml
```

That's all you need to do! We'll take it from there.

## Versioning

Boneyard automatically discovers versions from your Git repository:

- **With releases**: Users can install `@1.0.0`, `@2.0.0`, etc.
- **Without releases**: Users can install by commit hash `@abc1234`
- **No version specified**: Latest release or main HEAD

To create a release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## meta.toml Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Module name |
| `author` | Yes | Author name (uppercase recommended) |
| `description` | Yes | Brief description |
| `license` | No | License identifier (default: MIT) |
| `keywords` | No | Search keywords |
| `entry` | No | Entry point file (default: mod.ca) |

## Updating Your Module

Just push new releases to your repository. Boneyard will automatically pick them up during the next crawl.

## Removing Your Module

Open an issue requesting removal, and we'll remove it from the registry.

## Questions?

Open an issue if you have any questions!
