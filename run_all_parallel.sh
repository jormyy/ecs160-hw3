#!/bin/bash

# Run all fuzzing experiments in parallel
# This takes advantage of your 10 CPU cores to save time

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

echo "======================================"
echo "Running All Fuzzing Experiments in Parallel"
echo "======================================"
echo "This will run for 1 hour total (not 3 hours)"
echo ""
echo "Experiments:"
echo "  - Part B.1: No seeds"
echo "  - Part B.2: With seeds"
echo "  - Part C: UBSAN only"
echo "  - Part D: Custom mutator"
echo ""
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

# Set AFL environment variables
export AFL_MAP_SIZE=65536
export AFL_SKIP_CPUFREQ=1
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1

# Clean output directories
rm -rf "${BUILD_DIR}/output-b1-no-seeds"
rm -rf "${BUILD_DIR}/output-b2-with-seeds"
rm -rf "${BUILD_DIR}/output-c-sanitizers"
rm -rf "${BUILD_DIR}/output-d-custom-mutator"

echo ""
echo "Starting Part B.1 (no seeds) in background..."
"${BUILD_DIR}/AFLplusplus/afl-fuzz" \
  -i "${BUILD_DIR}/empty-seeds" \
  -o "${BUILD_DIR}/output-b1-no-seeds" \
  -V 3600 \
  -- "${BUILD_DIR}/harness-b" @@ /tmp/out-b1.png \
  > "${BUILD_DIR}/output-b1.log" 2>&1 &
PID_B1=$!
echo "  PID: $PID_B1"

sleep 2

echo "Starting Part B.2 (with seeds) in background..."
"${BUILD_DIR}/AFLplusplus/afl-fuzz" \
  -i "${BUILD_DIR}/seeds" \
  -o "${BUILD_DIR}/output-b2-with-seeds" \
  -V 3600 \
  -- "${BUILD_DIR}/harness-b" @@ /tmp/out-b2.png \
  > "${BUILD_DIR}/output-b2.log" 2>&1 &
PID_B2=$!
echo "  PID: $PID_B2"

sleep 2

echo "Starting Part C (UBSAN) in background..."
"${BUILD_DIR}/AFLplusplus/afl-fuzz" \
  -i "${BUILD_DIR}/seeds" \
  -o "${BUILD_DIR}/output-c-sanitizers" \
  -V 3600 \
  -m none \
  -- "${BUILD_DIR}/harness-c-ubsan" @@ /tmp/out-c.png \
  > "${BUILD_DIR}/output-c.log" 2>&1 &
PID_C=$!
echo "  PID: $PID_C"

sleep 2

echo "Starting Part D (custom mutator) in background..."
export AFL_CUSTOM_MUTATOR_LIBRARY="${BUILD_DIR}/png_mutator.so"
"${BUILD_DIR}/AFLplusplus/afl-fuzz" \
  -i "${BUILD_DIR}/seeds" \
  -o "${BUILD_DIR}/output-d-custom-mutator" \
  -V 3600 \
  -- "${BUILD_DIR}/harness-b" @@ /tmp/out-d.png \
  > "${BUILD_DIR}/output-d.log" 2>&1 &
PID_D=$!
echo "  PID: $PID_D"

echo ""
echo "======================================"
echo "All experiments running in parallel!"
echo "======================================"
echo ""
echo "PIDs:"
echo "  Part B.1: $PID_B1"
echo "  Part B.2: $PID_B2"
echo "  Part C:   $PID_C"
echo "  Part D:   $PID_D"
echo ""
echo "Logs:"
echo "  Part B.1: ${BUILD_DIR}/output-b1.log"
echo "  Part B.2: ${BUILD_DIR}/output-b2.log"
echo "  Part C:   ${BUILD_DIR}/output-c.log"
echo "  Part D:   ${BUILD_DIR}/output-d.log"
echo ""
echo "Waiting for all experiments to complete (1 hour)..."
echo "You can monitor progress with:"
echo "  watch -n 5 './extract_results.sh'"
echo ""

# Wait for all background processes
wait $PID_B1
echo "✓ Part B.1 complete"
wait $PID_B2
echo "✓ Part B.2 complete"
wait $PID_C
echo "✓ Part C complete"
wait $PID_D
echo "✓ Part D complete"

echo ""
echo "======================================"
echo "All experiments complete!"
echo "======================================"
echo ""
echo "Extract results with: ./extract_results.sh"
