#!/bin/bash
# Part B.1: Fuzzing WITHOUT seeds

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

echo "===== Part B.1: Fuzzing WITHOUT Seeds (1 hour) ====="

export AFL_MAP_SIZE=65536
export AFL_SKIP_CPUFREQ=1
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1

rm -rf "${BUILD_DIR}/output-b1-no-seeds"

"${BUILD_DIR}/AFLplusplus/afl-fuzz" \
  -i "${BUILD_DIR}/empty-seeds" \
  -o "${BUILD_DIR}/output-b1-no-seeds" \
  -V 3600 \
  -- "${BUILD_DIR}/harness-b" @@ /tmp/out.png

echo ""
echo "Results: tail -1 ${BUILD_DIR}/output-b1-no-seeds/default/plot_data"
