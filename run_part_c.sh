#!/bin/bash
# Part C: Fuzzing with UBSAN (ASAN disabled due to macOS compatibility)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

echo "===== Part C: Fuzzing with UBSAN (1 hour) ====="
echo "Note: Using UBSAN only (not ASAN) due to macOS compatibility issues"
echo ""

export AFL_MAP_SIZE=65536
export AFL_SKIP_CPUFREQ=1
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1

rm -rf "${BUILD_DIR}/output-c-sanitizers"

"${BUILD_DIR}/AFLplusplus/afl-fuzz" \
  -i "${BUILD_DIR}/seeds" \
  -o "${BUILD_DIR}/output-c-sanitizers" \
  -V 3600 \
  -m none \
  -- "${BUILD_DIR}/harness-c-ubsan" @@ /tmp/out.png

echo ""
echo "Results: tail -1 ${BUILD_DIR}/output-c-sanitizers/default/plot_data"
