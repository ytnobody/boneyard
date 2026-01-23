#!/bin/bash
# Build index files from packages
# Usage: ./scripts/build-index.sh

set -e

echo "Building index files..."

mkdir -p index

python3 << 'EOF'
import os
import datetime

try:
    import tomllib
except ImportError:
    import tomli as tomllib

# Collect all modules
modules = []
authors_by_letter = {}

packages_dir = "packages"

if not os.path.exists(packages_dir):
    print("No packages directory found")
    exit(0)

for root, dirs, files in os.walk(packages_dir):
    if "meta.toml" in files:
        meta_path = os.path.join(root, "meta.toml")
        try:
            with open(meta_path, "rb") as f:
                meta = tomllib.load(f)

            name = meta.get("name", "")
            author = meta.get("author", "")
            latest = meta.get("latest", "")

            if name and author:
                modules.append({
                    "name": name,
                    "author": author,
                    "latest": latest
                })

                # Group by first letter
                letter = author[0].upper()
                if letter not in authors_by_letter:
                    authors_by_letter[letter] = {}
                if author not in authors_by_letter[letter]:
                    # Calculate path
                    path = f"{letter}/{author[:2].upper()}/{author}"
                    authors_by_letter[letter][author] = {
                        "modules": [],
                        "path": path
                    }
                authors_by_letter[letter][author]["modules"].append(name)

        except Exception as e:
            print(f"Warning: Could not parse {meta_path}: {e}")

# Write all.toml
with open("index/all.toml", "w") as f:
    f.write(f'version = "1"\n')
    f.write(f'updated = "{datetime.datetime.utcnow().isoformat()}Z"\n')
    f.write(f'count = {len(modules)}\n\n')

    for mod in sorted(modules, key=lambda x: (x["author"], x["name"])):
        f.write("[[modules]]\n")
        f.write(f'name = "{mod["name"]}"\n')
        f.write(f'author = "{mod["author"]}"\n')
        f.write(f'latest = "{mod["latest"]}"\n\n')

print(f"Generated index/all.toml with {len(modules)} modules")

# Write per-letter index files
for letter, authors in sorted(authors_by_letter.items()):
    with open(f"index/{letter}.toml", "w") as f:
        f.write(f"# Modules by authors starting with {letter}\n\n")
        for author, info in sorted(authors.items()):
            f.write(f"[authors.{author}]\n")
            modules_str = ", ".join(f'"{m}"' for m in sorted(info["modules"]))
            f.write(f"modules = [{modules_str}]\n")
            f.write(f'path = "{info["path"]}"\n\n')

    print(f"Generated index/{letter}.toml with {len(authors)} authors")

print("\nIndex build complete!")
EOF
