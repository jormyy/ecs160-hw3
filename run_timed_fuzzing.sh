#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
AFLPLUSPLUS_DIR="${BUILD_DIR}/AFLplusplus"
SEEDS_DIR="${BUILD_DIR}/seeds"
EMPTY_SEEDS_DIR="${BUILD_DIR}/empty-seeds"

# Set AFL environment variables
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
export AFL_SKIP_CPUFREQ=1

echo "===== ECS160 HW3: LibPNG Fuzzing ====="
echo ""
echo "Available experiments:"
echo "  1. Part B.1 - AFL++ without seeds (1 hour)"
echo "  2. Part B.2 - AFL++ with seeds (1 hour)"
echo "  3. Part C   - AFL++ with ASAN/UBSAN (1 hour)"
echo "  4. Run ALL experiments sequentially (3 hours total)"
echo ""
echo "Select experiment to run (1-4): "
read -r choice

# Function to run fuzzing with actual timeout
run_with_timeout() {
    local time_limit=$1
    local output_dir=$2
    shift 2
    local cmd=("$@")

    # Start fuzzing in background
    "${cmd[@]}" &
    local fuzz_pid=$!

    echo "Fuzzing PID: $fuzz_pid"
    echo "Will run for $time_limit seconds..."

    # Wait for time limit
    sleep "$time_limit"

    # Kill the fuzzer
    echo ""
    echo "Time limit reached, stopping fuzzer..."
    kill -INT "$fuzz_pid" 2>/dev/null || true
    sleep 2
    kill -KILL "$fuzz_pid" 2>/dev/null || true

    wait "$fuzz_pid" 2>/dev/null || true
}

case $choice in
    1)
        echo "Running Part B.1 (AFL++ without seeds) for 1 hour..."
        OUTPUT_DIR="${BUILD_DIR}/output-b1-no-seeds"
        rm -rf "${OUTPUT_DIR}"
        mkdir -p "${OUTPUT_DIR}"

        run_with_timeout 3600 "${OUTPUT_DIR}" \
            "${AFLPLUSPLUS_DIR}/afl-fuzz" \
            -i "${EMPTY_SEEDS_DIR}" \
            -o "${OUTPUT_DIR}" \
            -n \
            -- "${BUILD_DIR}/harness-b" @@

        echo ""
        echo "Fuzzing complete! Results in: ${OUTPUT_DIR}"
        ;;

    2)
        echo "Running Part B.2 (AFL++ with seeds) for 1 hour..."
        OUTPUT_DIR="${BUILD_DIR}/output-b2-with-seeds"
        rm -rf "${OUTPUT_DIR}"
        mkdir -p "${OUTPUT_DIR}"

        run_with_timeout 3600 "${OUTPUT_DIR}" \
            "${AFLPLUSPLUS_DIR}/afl-fuzz" \
            -i "${SEEDS_DIR}" \
            -o "${OUTPUT_DIR}" \
            -n \
            -- "${BUILD_DIR}/harness-b" @@

        echo ""
        echo "Fuzzing complete! Results in: ${OUTPUT_DIR}"
        ;;

    3)
        echo "Running Part C (AFL++ with ASAN/UBSAN) for 1 hour..."
        OUTPUT_DIR="${BUILD_DIR}/output-c-sanitizers"
        rm -rf "${OUTPUT_DIR}"
        mkdir -p "${OUTPUT_DIR}"

        run_with_timeout 3600 "${OUTPUT_DIR}" \
            "${AFLPLUSPLUS_DIR}/afl-fuzz" \
            -i "${SEEDS_DIR}" \
            -o "${OUTPUT_DIR}" \
            -m none \
            -n \
            -- "${BUILD_DIR}/harness-c" @@

        echo ""
        echo "Fuzzing complete! Results in: ${OUTPUT_DIR}"
        ;;

    4)
        echo "Running ALL experiments sequentially (3 hours total)..."
        echo "Start time: $(date)"
        echo ""

        # Part B.1
        echo "=========================================="
        echo "Part B.1: AFL++ without seeds (1 hour)"
        echo "=========================================="
        OUTPUT_DIR_B1="${BUILD_DIR}/output-b1-no-seeds"
        rm -rf "${OUTPUT_DIR_B1}"
        mkdir -p "${OUTPUT_DIR_B1}"

        # Use crash harness (removes error handling to expose crashes)
        HARNESS_B="${BUILD_DIR}/harness-crash-b"
        if [ ! -f "${HARNESS_B}" ]; then
            HARNESS_B="${BUILD_DIR}/harness-b"
        fi

        run_with_timeout 3600 "${OUTPUT_DIR_B1}" \
            "${AFLPLUSPLUS_DIR}/afl-fuzz" \
            -i "${EMPTY_SEEDS_DIR}" \
            -o "${OUTPUT_DIR_B1}" \
            -n \
            -- "${HARNESS_B}" @@

        echo ""
        echo "Part B.1 complete! Results in: ${OUTPUT_DIR_B1}"
        echo ""

        # Part B.2
        echo "=========================================="
        echo "Part B.2: AFL++ with seeds (1 hour)"
        echo "=========================================="
        OUTPUT_DIR_B2="${BUILD_DIR}/output-b2-with-seeds"
        rm -rf "${OUTPUT_DIR_B2}"
        mkdir -p "${OUTPUT_DIR_B2}"

        # Use crash harness (removes error handling to expose crashes)
        HARNESS_B="${BUILD_DIR}/harness-crash-b"
        if [ ! -f "${HARNESS_B}" ]; then
            HARNESS_B="${BUILD_DIR}/harness-b"
        fi

        run_with_timeout 3600 "${OUTPUT_DIR_B2}" \
            "${AFLPLUSPLUS_DIR}/afl-fuzz" \
            -i "${SEEDS_DIR}" \
            -o "${OUTPUT_DIR_B2}" \
            -n \
            -- "${HARNESS_B}" @@

        echo ""
        echo "Part B.2 complete! Results in: ${OUTPUT_DIR_B2}"
        echo ""

        # Part C
        echo "=========================================="
        echo "Part C: AFL++ with ASAN/UBSAN (1 hour)"
        echo "=========================================="
        OUTPUT_DIR_C="${BUILD_DIR}/output-c-sanitizers"
        rm -rf "${OUTPUT_DIR_C}"
        mkdir -p "${OUTPUT_DIR_C}"

        # Use crash harness with sanitizers
        HARNESS_C="${BUILD_DIR}/harness-crash-c"
        if [ ! -f "${HARNESS_C}" ]; then
            HARNESS_C="${BUILD_DIR}/harness-c"
        fi

        run_with_timeout 3600 "${OUTPUT_DIR_C}" \
            "${AFLPLUSPLUS_DIR}/afl-fuzz" \
            -i "${SEEDS_DIR}" \
            -o "${OUTPUT_DIR_C}" \
            -m none \
            -n \
            -- "${HARNESS_C}" @@

        echo ""
        echo "Part C complete! Results in: ${OUTPUT_DIR_C}"
        echo ""

        # Final summary
        echo "=========================================="
        echo "ALL EXPERIMENTS COMPLETE"
        echo "End time: $(date)"
        echo "=========================================="
        echo ""

        echo "===== Part B.1 Results (No Seeds) ====="
        if [ -d "${OUTPUT_DIR_B1}/default" ]; then
            cat "${OUTPUT_DIR_B1}/default/fuzzer_stats" 2>/dev/null | grep -E "execs_done|corpus_count|saved_crashes|saved_hangs" || true
            CRASHES_B1=$(ls -1 "${OUTPUT_DIR_B1}/default/crashes/" 2>/dev/null | grep -v "README" | wc -l | tr -d ' ')
            echo "Crashes found: ${CRASHES_B1}"
        fi
        echo ""

        echo "===== Part B.2 Results (With Seeds) ====="
        if [ -d "${OUTPUT_DIR_B2}/default" ]; then
            cat "${OUTPUT_DIR_B2}/default/fuzzer_stats" 2>/dev/null | grep -E "execs_done|corpus_count|saved_crashes|saved_hangs" || true
            CRASHES_B2=$(ls -1 "${OUTPUT_DIR_B2}/default/crashes/" 2>/dev/null | grep -v "README" | wc -l | tr -d ' ')
            echo "Crashes found: ${CRASHES_B2}"
        fi
        echo ""

        echo "===== Part C Results (ASAN/UBSAN) ====="
        if [ -d "${OUTPUT_DIR_C}/default" ]; then
            cat "${OUTPUT_DIR_C}/default/fuzzer_stats" 2>/dev/null | grep -E "execs_done|corpus_count|saved_crashes|saved_hangs" || true
            CRASHES_C=$(ls -1 "${OUTPUT_DIR_C}/default/crashes/" 2>/dev/null | grep -v "README" | wc -l | tr -d ' ')
            echo "Crashes found: ${CRASHES_C}"
        fi
        echo ""

        echo "Results saved to:"
        echo "  ${OUTPUT_DIR_B1}"
        echo "  ${OUTPUT_DIR_B2}"
        echo "  ${OUTPUT_DIR_C}"
        ;;

    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

# Show results (for single experiment runs)
if [ "$choice" != "4" ] && [ -d "${OUTPUT_DIR}/default" ]; then
    echo ""
    echo "===== Results ====="
    echo ""
    echo "Statistics:"
    cat "${OUTPUT_DIR}/default/fuzzer_stats" 2>/dev/null | grep -E "execs_done|corpus_count|saved_crashes|saved_hangs" || true
    echo ""

    CRASHES=$(ls -1 "${OUTPUT_DIR}/default/crashes/" 2>/dev/null | grep -v "README" | wc -l | tr -d ' ')
    echo "Crashes found: ${CRASHES}"

    if [ "${CRASHES}" -gt 0 ]; then
        echo ""
        echo "Crash files:"
        ls -lh "${OUTPUT_DIR}/default/crashes/" | grep -v "README"
    fi
fi
