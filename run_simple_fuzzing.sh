#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
AFLPLUSPLUS_DIR="${BUILD_DIR}/AFLplusplus"
SEEDS_DIR="${BUILD_DIR}/seeds"
EMPTY_SEEDS_DIR="${BUILD_DIR}/empty-seeds"

# Set AFL environment variables to bypass macOS issues
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
export AFL_SKIP_CPUFREQ=1

echo "===== ECS160 HW3: LibPNG Fuzzing ====="
echo ""
echo "Available experiments:"
echo "  1. Part B.1 - AFL++ without seeds (1 hour)"
echo "  2. Part B.2 - AFL++ with seeds (1 hour)"
echo "  3. Part C   - AFL++ with ASAN/UBSAN (1 hour)"
echo "  4. Quick test (30 seconds)"
echo ""
echo "Select experiment to run (1-4): "
read -r choice

case $choice in
    1)
        echo "Running Part B.1 (AFL++ without seeds)..."
        OUTPUT_DIR="${BUILD_DIR}/output-b1-no-seeds"
        rm -rf "${OUTPUT_DIR}"
        mkdir -p "${OUTPUT_DIR}"

        echo "Starting fuzzing for 1 hour..."
        echo "Press Ctrl+C to stop early"
        "${AFLPLUSPLUS_DIR}/afl-fuzz" \
            -i "${EMPTY_SEEDS_DIR}" \
            -o "${OUTPUT_DIR}" \
            -V 1h \
            -n \
            -- "${BUILD_DIR}/harness-b" @@ || true

        echo ""
        echo "Fuzzing complete! Results in: ${OUTPUT_DIR}"
        ;;

    2)
        echo "Running Part B.2 (AFL++ with seeds)..."
        OUTPUT_DIR="${BUILD_DIR}/output-b2-with-seeds"
        rm -rf "${OUTPUT_DIR}"
        mkdir -p "${OUTPUT_DIR}"

        echo "Starting fuzzing for 1 hour..."
        echo "Press Ctrl+C to stop early"
        "${AFLPLUSPLUS_DIR}/afl-fuzz" \
            -i "${SEEDS_DIR}" \
            -o "${OUTPUT_DIR}" \
            -V 1h \
            -n \
            -- "${BUILD_DIR}/harness-b" @@ || true

        echo ""
        echo "Fuzzing complete! Results in: ${OUTPUT_DIR}"
        ;;

    3)
        echo "Running Part C (AFL++ with ASAN/UBSAN)..."
        OUTPUT_DIR="${BUILD_DIR}/output-c-sanitizers"
        rm -rf "${OUTPUT_DIR}"
        mkdir -p "${OUTPUT_DIR}"

        echo "Starting fuzzing for 1 hour..."
        echo "Press Ctrl+C to stop early"
        "${AFLPLUSPLUS_DIR}/afl-fuzz" \
            -i "${SEEDS_DIR}" \
            -o "${OUTPUT_DIR}" \
            -V 1h \
            -m none \
            -n \
            -- "${BUILD_DIR}/harness-c" @@ || true

        echo ""
        echo "Fuzzing complete! Results in: ${OUTPUT_DIR}"
        ;;

    4)
        echo "Running quick test (30 seconds)..."
        OUTPUT_DIR="${BUILD_DIR}/test-output"
        rm -rf "${OUTPUT_DIR}"
        mkdir -p "${OUTPUT_DIR}"

        echo "Starting quick test..."
        echo "This will run for about 30 seconds, then press Ctrl+C"
        "${AFLPLUSPLUS_DIR}/afl-fuzz" \
            -i "${SEEDS_DIR}" \
            -o "${OUTPUT_DIR}" \
            -n \
            -- "${BUILD_DIR}/harness-b" @@ || true

        echo ""
        echo "Test complete! Results in: ${OUTPUT_DIR}"
        ;;

    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

# Show results
if [ -d "${OUTPUT_DIR}/default" ]; then
    echo ""
    echo "===== Results ====="
    echo ""
    echo "Statistics:"
    cat "${OUTPUT_DIR}/default/fuzzer_stats" | grep -E "execs_done|corpus_count|saved_crashes|saved_hangs" || true
    echo ""

    CRASHES=$(ls -1 "${OUTPUT_DIR}/default/crashes/" 2>/dev/null | grep -v "README" | wc -l | tr -d ' ')
    echo "Crashes found: ${CRASHES}"

    if [ "${CRASHES}" -gt 0 ]; then
        echo ""
        echo "Crash files:"
        ls -lh "${OUTPUT_DIR}/default/crashes/" | grep -v "README"
        echo ""
        echo "To reproduce a crash:"
        echo "  ${BUILD_DIR}/harness-b ${OUTPUT_DIR}/default/crashes/<crash-file>"
    fi
else
    echo "No results found. Check if fuzzing started correctly."
fi
