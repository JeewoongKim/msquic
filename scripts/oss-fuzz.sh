#!/bin/bash -eu

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

: "${CC:?CC is required}"
: "${CXX:?CXX is required}"
: "${CFLAGS:?CFLAGS is required}"
: "${CXXFLAGS:?CXXFLAGS is required}"
: "${LIB_FUZZING_ENGINE:?LIB_FUZZING_ENGINE is required}"
: "${OUT:?OUT is required}"

cd "$ROOT_DIR"

#
# Build the instrumented static MsQuic library.
#
pwsh ./scripts/build.ps1 \
    -Static \
    -DisableTest \
    -DisablePerf \
    -DisableLogs \
    -Parallel 1

BUILD_CONFIG=$(find "$ROOT_DIR/build" -name 'msquic-config.cmake' -print -quit)
test -n "$BUILD_CONFIG"

BUILD_DIR=$(dirname "$BUILD_CONFIG")

LIBMSQUICDIR=$(
    cmake -LAH "$BUILD_DIR/CMakeCache.txt" |
        grep QUIC_OUTPUT_DIR |
        cut -d'=' -f2
)

QUICTLSLIB=$(
    cmake -LAH "$BUILD_DIR/CMakeCache.txt" |
        grep QUIC_TLS_LIB |
        cut -d'=' -f2
)

COMMON_INCLUDES=(
    "-I$ROOT_DIR/src/test"
    "-I$ROOT_DIR/src/inc"
    "-I$ROOT_DIR/src/platform"
    "-I$ROOT_DIR/src/generated/common"
    "-I$ROOT_DIR/src/generated/linux"
    "-I$BUILD_DIR/_deps/opensslquic-build/$QUICTLSLIB/include"
    "-isystem"
    "$ROOT_DIR/submodules/googletest/googletest/include"
    "-isystem"
    "$ROOT_DIR/submodules/googletest/googletest"
)

OBJ_DIR="${TMPDIR:-/tmp}/msquic-fuzz"
mkdir -p "$OBJ_DIR"

build_fuzzer()
{
    local source="$1"
    shift

    local filename
    local target
    local object

    filename=$(basename "$source")
    target="${filename%.*}"
    object="$OBJ_DIR/$target.o"

    case "$source" in
        *.c)
            "$CC" $CFLAGS \
                -DCX_PLATFORM_LINUX \
                -DQUIC_TEST_APIS \
                "${COMMON_INCLUDES[@]}" \
                "$@" \
                -c "$source" \
                -o "$object"
            ;;

        *.cc|*.cpp)
            "$CXX" $CXXFLAGS \
                -DCX_PLATFORM_LINUX \
                -DQUIC_TEST_APIS \
                "${COMMON_INCLUDES[@]}" \
                "$@" \
                -c "$source" \
                -o "$object"
            ;;

        *)
            echo "Unsupported fuzz target source: $source" >&2
            return 1
            ;;
    esac

    "$CXX" $CXXFLAGS \
        $LIB_FUZZING_ENGINE \
        "$object" \
        -o "$OUT/$target" \
        "$LIBMSQUICDIR/libmsquic.a"
}

#
# Existing legacy target.
#
build_fuzzer "$ROOT_DIR/src/fuzzing/fuzz.cc"

#
# Dedicated fuzz targets.
#
shopt -s nullglob
FUZZ_SOURCES=(
    "$ROOT_DIR"/src/fuzzing/*_fuzz.c
    "$ROOT_DIR"/src/fuzzing/*_fuzz.cc
    "$ROOT_DIR"/src/fuzzing/*_fuzz.cpp
)

for source in "${FUZZ_SOURCES[@]}"; do
    build_fuzzer "$source"
done

#
# spinquic is a normal tool with a special fuzzing build mode.
#
build_fuzzer \
    "$ROOT_DIR/src/tools/spin/spinquic.cpp" \
    -DFUZZING \
    -DQUIC_BUILD_STATIC
