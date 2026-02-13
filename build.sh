#!/bin/bash
# Build script for Quilter (Ergo/Cogito port)
#
# Prerequisites:
#   - Ergo compiler installed (https://github.com/lainsce/ergo)
#   - Cogito library installed
#   - SDL3, SDL3_ttf, freetype2 installed
#
# Usage:
#   ./build.sh              # Type check only
#   ./build.sh run          # Compile and run

set -e

ERGO_BIN="${ERGO_BIN:-$(command -v ergo 2>/dev/null || true)}"

if [ -z "$ERGO_BIN" ] || [ ! -x "$ERGO_BIN" ]; then
    echo "Error: Ergo compiler not found."
    echo "Install from https://github.com/lainsce/ergo"
    exit 1
fi

export ERGO_CC_FLAGS="${ERGO_CC_FLAGS:--D_GNU_SOURCE}"

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
