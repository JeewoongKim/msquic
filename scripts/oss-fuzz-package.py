#!/usr/bin/env python3

import argparse
import json
import os
import re
import shutil
from pathlib import Path


def package(manifest_path, bin_dir, out_dir):
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    if not isinstance(manifest, dict) or set(manifest) != {"targets"}:
        raise ValueError("Manifest must contain only 'targets'")

    targets = manifest["targets"]
    if not isinstance(targets, list) or not targets:
        raise ValueError("'targets' must be a non-empty array")

    seen = set()
    sources = []

    # Validate the full manifest before copying any files.
    for entry in targets:
        if not isinstance(entry, dict) or set(entry) != {"name"}:
            raise ValueError("Each target must contain only 'name'")

        name = entry["name"]

        if not isinstance(name, str) or not re.fullmatch(
            r"[A-Za-z0-9_-]+", name
        ):
            raise ValueError(f"Invalid fuzzer name: {name!r}")

        if name in seen:
            raise ValueError(f"Duplicate fuzzer: {name}")
        seen.add(name)

        source = bin_dir / name
        if not source.is_file():
            raise FileNotFoundError(f"Missing fuzzer: {source}")
        if not os.access(source, os.X_OK):
            raise PermissionError(f"Not executable: {source}")

        sources.append((name, source))

    out_dir.mkdir(parents=True, exist_ok=True)

    for name, source in sources:
        shutil.copy2(source, out_dir / name)
        print(f"Packaged: {name}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--bin-dir", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    try:
        package(args.manifest, args.bin_dir, args.out)
    except (OSError, ValueError) as error:
        parser.exit(1, f"error: {error}\n")


if __name__ == "__main__":
    main()
