#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

: "${OUT:?OSS-Fuzz OUT environment variable is required}"
: "${LIB_FUZZING_ENGINE:?LIB_FUZZING_ENGINE is required}"

# Preserve the workaround from the existing OSS-Fuzz integration.
export CFLAGS="${CFLAGS:-} -Wno-error=invalid-unevaluated-string"
export CXXFLAGS="${CXXFLAGS:-} -Wno-error=invalid-unevaluated-string"

cd "$ROOT_DIR"

pwsh ./scripts/build.ps1 \
    -Static \
    -DisableTest \
    -DisablePerf \
    -DisableLogs \
    -Parallel 1 \
    -ConfigureOnly

BUILD_CONFIG="$(find "$ROOT_DIR/build" \
    -name 'msquic-config.cmake' -print -quit)"

if [[ -z "$BUILD_CONFIG" ]]; then
    echo "Could not locate the MsQuic CMake build directory" >&2
    exit 1
fi

BUILD_DIR="$(dirname "$BUILD_CONFIG")"

cmake -S "$ROOT_DIR" -B "$BUILD_DIR" \
    -DQUIC_BUILD_FUZZERS=ON

cmake --build "$BUILD_DIR" \
    --target all_fuzzers \
    --parallel 1

python3 "$ROOT_DIR/scripts/oss-fuzz-package.py" \
    --manifest "$ROOT_DIR/src/fuzzing/oss-fuzz.json" \
    --bin-dir "$BUILD_DIR/fuzzers" \
    --out "$OUT"
