#!/bin/bash

# Extract results from fuzzing runs to help fill in ANALYSIS.md

echo "======================================"
echo "Machine Specifications"
echo "======================================"
echo "CPU: $(sysctl -n machdep.cpu.brand_string)"
echo "RAM: $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024)) GB"
echo "OS: $(sw_vers -productName) $(sw_vers -productVersion)"
echo "Architecture: $(uname -m)"
echo ""

echo "======================================"
echo "Part B.1: No Seeds"
echo "======================================"
if [ -f build/output-b1-no-seeds/default/plot_data ]; then
    LAST_LINE=$(tail -1 build/output-b1-no-seeds/default/plot_data)
    echo "Raw data: $LAST_LINE"
    echo ""

    # Parse the CSV line
    IFS=',' read -ra FIELDS <<< "$LAST_LINE"
    echo "Duration: ${FIELDS[0]} seconds"
    echo "Cycles: ${FIELDS[1]}"
    echo "Corpus count: ${FIELDS[3]}"
    echo "Map size: ${FIELDS[6]}"
    echo "Saved crashes: ${FIELDS[7]}"
    echo "Max depth: ${FIELDS[9]}"
    echo "Exec/sec: ${FIELDS[10]}"
    echo "Total execs: ${FIELDS[11]}"
    echo "Edges found: ${FIELDS[12]}"
    echo "Total crashes: ${FIELDS[13]}"
    echo ""
    echo "Crashes found:"
    ls -la build/output-b1-no-seeds/default/crashes/ 2>/dev/null || echo "No crashes directory"
else
    echo "NOT RUN YET"
fi
echo ""

echo "======================================"
echo "Part B.2: With Seeds"
echo "======================================"
if [ -f build/output-b2-with-seeds/default/plot_data ]; then
    LAST_LINE=$(tail -1 build/output-b2-with-seeds/default/plot_data)
    echo "Raw data: $LAST_LINE"
    echo ""

    IFS=',' read -ra FIELDS <<< "$LAST_LINE"
    echo "Duration: ${FIELDS[0]} seconds"
    echo "Cycles: ${FIELDS[1]}"
    echo "Corpus count: ${FIELDS[3]}"
    echo "Map size: ${FIELDS[6]}"
    echo "Saved crashes: ${FIELDS[7]}"
    echo "Max depth: ${FIELDS[9]}"
    echo "Exec/sec: ${FIELDS[10]}"
    echo "Total execs: ${FIELDS[11]}"
    echo "Edges found: ${FIELDS[12]}"
    echo "Total crashes: ${FIELDS[13]}"
    echo ""
    echo "Crashes found:"
    ls -la build/output-b2-with-seeds/default/crashes/ 2>/dev/null || echo "No crashes directory"
else
    echo "NOT RUN YET"
fi
echo ""

echo "======================================"
echo "Part C: Sanitizers"
echo "======================================"
if [ -f build/output-c-sanitizers/default/plot_data ]; then
    LAST_LINE=$(tail -1 build/output-c-sanitizers/default/plot_data)
    echo "Raw data: $LAST_LINE"
    echo ""

    IFS=',' read -ra FIELDS <<< "$LAST_LINE"
    echo "Duration: ${FIELDS[0]} seconds"
    echo "Cycles: ${FIELDS[1]}"
    echo "Corpus count: ${FIELDS[3]}"
    echo "Map size: ${FIELDS[6]}"
    echo "Saved crashes: ${FIELDS[7]}"
    echo "Max depth: ${FIELDS[9]}"
    echo "Exec/sec: ${FIELDS[10]}"
    echo "Total execs: ${FIELDS[11]}"
    echo "Edges found: ${FIELDS[12]}"
    echo "Total crashes: ${FIELDS[13]}"
    echo ""
    echo "Crashes found:"
    ls -la build/output-c-sanitizers/default/crashes/ 2>/dev/null || echo "No crashes directory"
else
    echo "SKIPPED (macOS ASAN issues)"
fi
echo ""

echo "======================================"
echo "Part D: Custom Mutator"
echo "======================================"
if [ -f build/output-d-custom-mutator/default/plot_data ]; then
    LAST_LINE=$(tail -1 build/output-d-custom-mutator/default/plot_data)
    echo "Raw data: $LAST_LINE"
    echo ""

    IFS=',' read -ra FIELDS <<< "$LAST_LINE"
    echo "Duration: ${FIELDS[0]} seconds"
    echo "Cycles: ${FIELDS[1]}"
    echo "Corpus count: ${FIELDS[3]}"
    echo "Map size: ${FIELDS[6]}"
    echo "Saved crashes: ${FIELDS[7]}"
    echo "Max depth: ${FIELDS[9]}"
    echo "Exec/sec: ${FIELDS[10]}"
    echo "Total execs: ${FIELDS[11]}"
    echo "Edges found: ${FIELDS[12]}"
    echo "Total crashes: ${FIELDS[13]}"
    echo ""
    echo "Crashes found:"
    ls -la build/output-d-custom-mutator/default/crashes/ 2>/dev/null || echo "No crashes directory"
else
    echo "NOT RUN YET"
fi
echo ""

echo "======================================"
echo "Seed Files Used"
echo "======================================"
ls -lh build/seeds/
echo ""

echo "======================================"
echo "Summary"
echo "======================================"
echo "Use the above data to fill in ANALYSIS.md"
echo ""
echo "To run the experiments:"
echo "  ./run_part_b1.sh  # 1 hour"
echo "  ./run_part_b2.sh  # 1 hour"
echo "  ./run_part_d.sh   # 1 hour"
