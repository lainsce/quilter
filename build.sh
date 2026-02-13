#!/bin/bash
# Build script for Quilter (Ergo/Cogito port)
#
# Prerequisites:
#   1. Ergo compiler built: cd ergo-repo && meson setup ergo/build ergo && meson compile -C ergo/build
#   2. Cogito library built: cd ergo-repo && meson setup cogito/build cogito && meson compile -C cogito/build
#   3. SDL3, SDL3_ttf, freetype2 installed
#
# Usage:
#   ./build.sh              # Compile only (type check)
#   ./build.sh run          # Compile and run
#   ./build.sh check        # Type check only

set -e

# --- Configuration ---
# Adjust these paths to match your setup
ERGO_REPO="${ERGO_REPO:-../ergo}"
ERGO_BIN="${ERGO_BIN:-${ERGO_REPO}/ergo/build/ergo}"
COGITO_SRC="${ERGO_REPO}/cogito/src"
COGITO_LIB="${ERGO_REPO}/cogito/build"

# Auto-detect ergo binary
if [ ! -x "$ERGO_BIN" ]; then
    ERGO_BIN=$(command -v ergo 2>/dev/null || true)
fi

if [ -z "$ERGO_BIN" ] || [ ! -x "$ERGO_BIN" ]; then
    echo "Error: Ergo compiler not found."
    echo "Set ERGO_REPO to point to the lainsce/ergo repository, or ERGO_BIN to the ergo binary."
    exit 1
fi

# Environment
export ERGO_CC_FLAGS="${ERGO_CC_FLAGS:--D_GNU_SOURCE}"
export ERGO_COGITO_CFLAGS="${ERGO_COGITO_CFLAGS:--I${COGITO_SRC}}"
export ERGO_COGITO_FLAGS="${ERGO_COGITO_FLAGS:--L${COGITO_LIB} -lcogito -Wl,-rpath,${COGITO_LIB}}"
export ERGO_RAYLIB_CFLAGS="${ERGO_RAYLIB_CFLAGS:-}"
export ERGO_RAYLIB_FLAGS="${ERGO_RAYLIB_FLAGS:--lm -lpthread -ldl -lrt -lX11}"

MODE="${1:-check}"
ENTRY="main.ergo"

case "$MODE" in
    run)
        echo "Building and running Quilter..."
        "$ERGO_BIN" run "$ENTRY"
        ;;
    check)
        echo "Type-checking Quilter..."
        "$ERGO_BIN" "$ENTRY"
        echo "OK: compilation succeeded."
        ;;
    *)
        echo "Usage: $0 [run|check]"
        exit 1
        ;;
esac
