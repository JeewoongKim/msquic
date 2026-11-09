#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

: "${OUT:?OSS-Fuzz OUT environment variable is required}"
: "${LIB_FUZZING_ENGINE:?LIB_FUZZING_ENGINE is required}"

# Preserve the workaround from the existing OSS-Fuzz integration.
export CFLAGS="${CFLAGS:-} -Wno-error=invalid-unevaluated-string"
export CXXFLAGS="${CXXFLAGS:-} -Wno-error=invalid-unevaluated-string"

cd "$ROOT_DIR"

pwsh ./scripts/build.ps1 -ForFuzzing -Parallel 1
pwsh ./scripts/oss-fuzz-binplace.ps1
