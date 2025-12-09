#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
AFLPLUSPLUS_DIR="${BUILD_DIR}/AFLplusplus"

echo "===== Building Custom PNG Mutator ====="

if [ ! -d "${AFLPLUSPLUS_DIR}" ]; then
    echo "ERROR: AFL++ not found. Please run build.sh first."
    exit 1
fi

echo "Compiling png_mutator.c to shared library..."

gcc -shared -fPIC -O3 \
    -I"${AFLPLUSPLUS_DIR}/include" \
    "${SCRIPT_DIR}/png_mutator.c" \
    -o "${BUILD_DIR}/png_mutator.so"

echo ""
echo "Custom mutator built successfully: ${BUILD_DIR}/png_mutator.so"
echo ""
echo "To use with AFL++, set:"
echo "  export AFL_CUSTOM_MUTATOR_LIBRARY=${BUILD_DIR}/png_mutator.so"
echo ""
