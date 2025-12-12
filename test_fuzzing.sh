#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

echo "===== Testing Fuzzing Setup ====="
echo ""

# Test 1: Check binaries exist
echo "[1/5] Checking binaries..."
if [ -f "${BUILD_DIR}/harness-b" ] && [ -f "${BUILD_DIR}/harness-c" ]; then
    echo "  ✓ Harness binaries found"
else
    echo "  ✗ Harness binaries missing. Run ./build.sh first"
    exit 1
fi

# Test 2: Check AFL++ exists
echo "[2/5] Checking AFL++..."
if [ -f "${BUILD_DIR}/AFLplusplus/afl-fuzz" ]; then
    echo "  ✓ AFL++ found"
else
    echo "  ✗ AFL++ missing. Run ./build.sh first"
    exit 1
fi

# Test 3: Check seeds
echo "[3/5] Checking seed files..."
if [ -d "${BUILD_DIR}/seeds" ] && [ "$(ls -A ${BUILD_DIR}/seeds 2>/dev/null)" ]; then
    SEED_COUNT=$(ls -1 ${BUILD_DIR}/seeds | wc -l | tr -d ' ')
    echo "  ✓ Found ${SEED_COUNT} seed files"
else
    echo "  ✗ No seed files found. Run ./download_seeds.sh first"
    exit 1
fi

# Test 4: Test harness manually
echo "[4/5] Testing harness with a seed file..."
FIRST_SEED=$(ls ${BUILD_DIR}/seeds/*.png | head -1)
if ${BUILD_DIR}/harness-b "${FIRST_SEED}" >/dev/null 2>&1; then
    echo "  ✓ Harness executes successfully"
else
    echo "  ✗ Harness failed to execute"
    exit 1
fi

# Test 5: Quick AFL test (5 seconds)
echo "[5/5] Running quick AFL test (5 seconds)..."
rm -rf "${BUILD_DIR}/quick-test-output"

timeout 5s ${BUILD_DIR}/AFLplusplus/afl-fuzz \
    -i "${BUILD_DIR}/seeds" \
    -o "${BUILD_DIR}/quick-test-output" \
    -Q \
    -- "${BUILD_DIR}/harness-b" @@ 2>&1 | grep -E "(Getting to work|PROGRAM ABORT)" || true

if [ -d "${BUILD_DIR}/quick-test-output/default" ]; then
    echo "  ✓ AFL++ fuzzing started successfully!"
    echo ""
    echo "Test fuzzing results:"
    ls -la "${BUILD_DIR}/quick-test-output/default/" | head -10
    rm -rf "${BUILD_DIR}/quick-test-output"
else
    echo "  ⚠ AFL++ may have issues. Check the error above."
    echo ""
    echo "If you see a crash reporting warning, run:"
    echo "  sudo launchctl unload -w /System/Library/LaunchAgents/com.apple.ReportCrash.plist"
fi

echo ""
echo "===== Setup Test Complete ====="
echo ""
echo "Everything looks good! You can now run fuzzing with:"
echo "  ./run_fuzzing.sh"
echo ""
echo "Or run individual experiments (see FUZZING_GUIDE.md)"
