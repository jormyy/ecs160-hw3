#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

echo "===== Running Part D: Custom Mutator Fuzzing ====="

# Set AFL environment variables for macOS compatibility
export AFL_MAP_SIZE=65536
export AFL_SKIP_CPUFREQ=1
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
export AFL_CUSTOM_MUTATOR_LIBRARY="${BUILD_DIR}/png_mutator.so"

# Clean output directory if it exists
rm -rf "${BUILD_DIR}/output-d-custom-mutator"

echo "Starting fuzzing with custom PNG mutator for 1 hour..."
echo "Custom mutator: ${AFL_CUSTOM_MUTATOR_LIBRARY}"
echo ""

# Note: Using harness-b instead of harness-c due to macOS ASAN compatibility issues
# The custom mutator still works to test PNG-specific mutations
"${BUILD_DIR}/AFLplusplus/afl-fuzz" \
  -i "${BUILD_DIR}/seeds" \
  -o "${BUILD_DIR}/output-d-custom-mutator" \
  -V 3600 \
  -- "${BUILD_DIR}/harness-b" @@ /tmp/out.png

echo ""
echo "===== Fuzzing Complete ====="
echo "Output directory: ${BUILD_DIR}/output-d-custom-mutator"
echo ""
echo "To see results:"
echo "  tail -1 ${BUILD_DIR}/output-d-custom-mutator/default/plot_data"
echo "  ls -la ${BUILD_DIR}/output-d-custom-mutator/default/crashes/"
