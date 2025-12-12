#!/bin/bash
# Part C: Fuzzing with FULL ASAN+UBSAN (Linux only)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

echo "===== Part C: Fuzzing with ASAN+UBSAN (1 hour) ====="
echo "Note: Using FULL ASAN+UBSAN (Linux-compatible)"
echo ""

# Increase system limits for ASAN
sudo sysctl -w vm.mmap_rnd_bits=28 2>/dev/null || true

export AFL_SKIP_CPUFREQ=1
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1

rm -rf "${BUILD_DIR}/output-c-sanitizers"

AFL_USE_ASAN=1 AFL_USE_UBSAN=1 "${BUILD_DIR}/AFLplusplus/afl-fuzz" \
  -i "${BUILD_DIR}/seeds" \
  -o "${BUILD_DIR}/output-c-sanitizers" \
  -V 3600 \
  -m none \
  -- "${BUILD_DIR}/harness-c-linux" @@ /tmp/out.png

echo ""
echo "Results: tail -1 ${BUILD_DIR}/output-c-sanitizers/default/plot_data"
echo "Crashes: ls -la ${BUILD_DIR}/output-c-sanitizers/default/crashes/"
