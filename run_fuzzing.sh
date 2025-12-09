#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
AFLPLUSPLUS_DIR="${BUILD_DIR}/AFLplusplus"

# Set up AFL++ in path
export PATH="${AFLPLUSPLUS_DIR}:${PATH}"

# ==================== Configuration ====================
FUZZING_TIME="1h"  # 1 hour for each experiment

echo "===== ECS160 HW3: LibPNG Fuzzing Experiments ====="
echo ""
echo "This script will run the fuzzing experiments for Parts B and C"
echo "Each experiment runs for ${FUZZING_TIME}"
echo ""

# ==================== Part B.1: AFL++ without seeds ====================
echo "=========================================="
echo "Part B.1: Fuzzing with AFL++ (no seeds)"
echo "=========================================="
echo ""

OUTPUT_DIR_B1="${BUILD_DIR}/output-b1-no-seeds"
mkdir -p "${OUTPUT_DIR_B1}"

echo "Running AFL++ fuzzer (no seeds) for ${FUZZING_TIME}..."
echo "Output directory: ${OUTPUT_DIR_B1}"
echo ""
echo "Command: afl-fuzz -i ${BUILD_DIR}/empty-seeds -o ${OUTPUT_DIR_B1} -V ${FUZZING_TIME} -- ${BUILD_DIR}/harness-b @@"
echo ""
echo "Press Enter to start Part B.1, or Ctrl+C to skip..."
read

timeout ${FUZZING_TIME} "${AFLPLUSPLUS_DIR}/afl-fuzz" \
    -i "${BUILD_DIR}/empty-seeds" \
    -o "${OUTPUT_DIR_B1}" \
    -V "${FUZZING_TIME}" \
    -- "${BUILD_DIR}/harness-b" @@ || true

echo ""
echo "Part B.1 complete. Results saved to: ${OUTPUT_DIR_B1}"
echo ""
echo "Summary:"
afl-whatsup "${OUTPUT_DIR_B1}"
echo ""

# ==================== Part B.2: AFL++ with seeds ====================
echo "=========================================="
echo "Part B.2: Fuzzing with AFL++ (with seeds)"
echo "=========================================="
echo ""

OUTPUT_DIR_B2="${BUILD_DIR}/output-b2-with-seeds"
mkdir -p "${OUTPUT_DIR_B2}"

if [ -z "$(ls -A ${BUILD_DIR}/seeds 2>/dev/null)" ]; then
    echo "WARNING: No seed files found in ${BUILD_DIR}/seeds/"
    echo "Please add 10 PNG files to the seeds directory before running this experiment."
    echo "Skipping Part B.2..."
else
    echo "Running AFL++ fuzzer (with seeds) for ${FUZZING_TIME}..."
    echo "Output directory: ${OUTPUT_DIR_B2}"
    echo ""
    echo "Command: afl-fuzz -i ${BUILD_DIR}/seeds -o ${OUTPUT_DIR_B2} -V ${FUZZING_TIME} -- ${BUILD_DIR}/harness-b @@"
    echo ""
    echo "Press Enter to start Part B.2, or Ctrl+C to skip..."
    read

    timeout ${FUZZING_TIME} "${AFLPLUSPLUS_DIR}/afl-fuzz" \
        -i "${BUILD_DIR}/seeds" \
        -o "${OUTPUT_DIR_B2}" \
        -V "${FUZZING_TIME}" \
        -- "${BUILD_DIR}/harness-b" @@ || true

    echo ""
    echo "Part B.2 complete. Results saved to: ${OUTPUT_DIR_B2}"
    echo ""
    echo "Summary:"
    afl-whatsup "${OUTPUT_DIR_B2}"
    echo ""
fi

# ==================== Part C: AFL++ with ASAN/UBSAN and seeds ====================
echo "=========================================="
echo "Part C: Fuzzing with AFL++ + ASAN/UBSAN"
echo "=========================================="
echo ""

OUTPUT_DIR_C="${BUILD_DIR}/output-c-sanitizers"
mkdir -p "${OUTPUT_DIR_C}"

if [ -z "$(ls -A ${BUILD_DIR}/seeds 2>/dev/null)" ]; then
    echo "WARNING: No seed files found in ${BUILD_DIR}/seeds/"
    echo "Please add 10 PNG files to the seeds directory before running this experiment."
    echo "Skipping Part C..."
else
    echo "Running AFL++ fuzzer with ASAN/UBSAN for ${FUZZING_TIME}..."
    echo "Output directory: ${OUTPUT_DIR_C}"
    echo ""
    echo "Command: AFL_USE_ASAN=1 AFL_USE_UBSAN=1 afl-fuzz -i ${BUILD_DIR}/seeds -o ${OUTPUT_DIR_C} -V ${FUZZING_TIME} -- ${BUILD_DIR}/harness-c @@"
    echo ""
    echo "Press Enter to start Part C, or Ctrl+C to skip..."
    read

    timeout ${FUZZING_TIME} \
        env AFL_USE_ASAN=1 AFL_USE_UBSAN=1 \
        "${AFLPLUSPLUS_DIR}/afl-fuzz" \
        -i "${BUILD_DIR}/seeds" \
        -o "${OUTPUT_DIR_C}" \
        -V "${FUZZING_TIME}" \
        -m none \
        -- "${BUILD_DIR}/harness-c" @@ || true

    echo ""
    echo "Part C complete. Results saved to: ${OUTPUT_DIR_C}"
    echo ""
    echo "Summary:"
    afl-whatsup "${OUTPUT_DIR_C}"
    echo ""
fi

# ==================== Part D: AFL++ with custom mutator (Extra Credit) ====================
echo "=========================================="
echo "Part D: Fuzzing with custom mutator (EC)"
echo "=========================================="
echo ""

if [ -f "${BUILD_DIR}/png_mutator.so" ]; then
    OUTPUT_DIR_D="${BUILD_DIR}/output-d-custom-mutator"
    mkdir -p "${OUTPUT_DIR_D}"

    if [ -z "$(ls -A ${BUILD_DIR}/seeds 2>/dev/null)" ]; then
        echo "WARNING: No seed files found in ${BUILD_DIR}/seeds/"
        echo "Skipping Part D..."
    else
        echo "Running AFL++ fuzzer with custom mutator for ${FUZZING_TIME}..."
        echo "Output directory: ${OUTPUT_DIR_D}"
        echo ""
        echo "Command: AFL_USE_ASAN=1 AFL_USE_UBSAN=1 AFL_CUSTOM_MUTATOR_LIBRARY=${BUILD_DIR}/png_mutator.so afl-fuzz -i ${BUILD_DIR}/seeds -o ${OUTPUT_DIR_D} -V ${FUZZING_TIME} -- ${BUILD_DIR}/harness-c @@"
        echo ""
        echo "Press Enter to start Part D, or Ctrl+C to skip..."
        read

        timeout ${FUZZING_TIME} \
            env AFL_USE_ASAN=1 AFL_USE_UBSAN=1 \
            AFL_CUSTOM_MUTATOR_LIBRARY="${BUILD_DIR}/png_mutator.so" \
            "${AFLPLUSPLUS_DIR}/afl-fuzz" \
            -i "${BUILD_DIR}/seeds" \
            -o "${OUTPUT_DIR_D}" \
            -V "${FUZZING_TIME}" \
            -m none \
            -- "${BUILD_DIR}/harness-c" @@ || true

        echo ""
        echo "Part D complete. Results saved to: ${OUTPUT_DIR_D}"
        echo ""
        echo "Summary:"
        afl-whatsup "${OUTPUT_DIR_D}"
        echo ""
    fi
else
    echo "Custom mutator not found. Build it first with build_custom_mutator.sh"
    echo "Skipping Part D..."
fi

echo "===== All Experiments Complete ====="
echo ""
echo "Results directories:"
echo "  Part B.1 (no seeds):        ${OUTPUT_DIR_B1}"
echo "  Part B.2 (with seeds):      ${OUTPUT_DIR_B2}"
echo "  Part C (sanitizers):        ${OUTPUT_DIR_C}"
echo "  Part D (custom mutator):    ${OUTPUT_DIR_D}"
echo ""
echo "Use 'afl-whatsup <output_dir>' to view detailed statistics"
echo "Crashes can be found in <output_dir>/default/crashes/"
echo ""
