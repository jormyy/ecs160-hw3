# Homework Completion Guide

## Current Status

### ✅ Completed
- Part A: Test harness and build scripts
- Custom mutator code (Part D)
- All binaries compiled with AFL instrumentation

### ⚠️ In Progress
- Need to run fuzzing experiments
- Need to fill in ANALYSIS.md with results

## Running the Experiments

### Option 1: Run All Experiments (4+ hours total)

```bash
# Part B.1: No seeds (1 hour)
./run_part_b1.sh

# Part B.2: With seeds (1 hour)
./run_part_b2.sh

# Part C: Sanitizers (1 hour)
# NOTE: Part C has ASAN issues on macOS - skip this or note in ANALYSIS.md
# ./run_part_c.sh

# Part D: Custom mutator (1 hour)
./run_part_d.sh
```

### Option 2: Quick Test Runs (for debugging)

```bash
# 5-minute test runs
export AFL_MAP_SIZE=65536 AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1

# Part B.1 (5 min)
./build/AFLplusplus/afl-fuzz -i build/empty-seeds -o build/output-b1-test -V 300 -- build/harness-b @@ /tmp/out.png

# Part B.2 (5 min)
./build/AFLplusplus/afl-fuzz -i build/seeds -o build/output-b2-test -V 300 -- build/harness-b @@ /tmp/out.png

# Part D (5 min)
export AFL_CUSTOM_MUTATOR_LIBRARY="${PWD}/build/png_mutator.so"
./build/AFLplusplus/afl-fuzz -i build/seeds -o build/output-d-test -V 300 -- build/harness-b @@ /tmp/out.png
```

## Extracting Results

### Get Machine Specs
```bash
echo "CPU: $(sysctl -n machdep.cpu.brand_string)"
echo "RAM: $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024)) GB"
echo "OS: $(sw_vers -productName) $(sw_vers -productVersion)"
echo "Architecture: $(uname -m)"
```

### Extract Fuzzing Statistics

For each experiment, get the last line of plot_data:

```bash
# Part B.1
tail -1 build/output-b1-no-seeds/default/plot_data

# Part B.2
tail -1 build/output-b2-with-seeds/default/plot_data

# Part D
tail -1 build/output-d-custom-mutator/default/plot_data
```

The plot_data format:
```
relative_time, cycles_done, cur_item, corpus_count, pending_total, pending_favs,
map_size, saved_crashes, saved_hangs, max_depth, execs_per_sec, total_execs,
edges_found, total_crashes, servers_count
```

### Check for Crashes
```bash
ls -la build/output-b1-no-seeds/default/crashes/
ls -la build/output-b2-with-seeds/default/crashes/
ls -la build/output-d-custom-mutator/default/crashes/
```

## Filling in ANALYSIS.md

### Machine Specifications (Lines 10-13)
Replace with your actual machine info.

### Part B.1 Results (Lines 37-42)
From `tail -1 build/output-b1-no-seeds/default/plot_data`:
- Column 8: saved_crashes → Total Crashes
- Column 14: total_crashes → Unique Crashes
- Column 13: edges_found → Total Coverage
- Column 12: total_execs → Total Executions
- Column 11: execs_per_sec → Executions per second
- Column 4: corpus_count → Paths Found

### Part B.2 Results (Lines 77-82)
Same process as B.1

### Part D Results (Lines 189-196)
Same process as B.1

### Observations
Write about what you notice:
- Did seeds help? (Compare B.1 vs B.2)
- Did the custom mutator find more bugs? (Compare B.2 vs D)
- Coverage differences
- Performance differences

## Part C Note (ASAN/UBSAN)

**macOS Issue:** ASAN has compatibility issues on macOS. You have two options:

1. **Skip Part C** - Note in ANALYSIS.md:
   ```
   Part C was not completed due to ASAN compatibility issues on macOS (Apple Silicon).
   The harness crashes immediately when run with ASAN enabled due to the
   DYLD_INSERT_LIBRARIES requirement conflicting with AFL++'s fork server.
   ```

2. **Run Part C without sanitizers** - Use harness-b but document it:
   ```
   Due to macOS ASAN limitations, Part C was run with the same harness as Part B.
   In a Linux environment, sanitizers would be functional.
   ```

## Quick Reference: Your Setup

- **Harnesses:**
  - `build/harness-b` - AFL instrumented, no sanitizers ✅
  - `build/harness-c` - AFL + ASAN/UBSAN (macOS issues) ⚠️

- **Seeds:** `build/seeds/` (10 PNG files)
- **Empty seeds:** `build/empty-seeds/` (for Part B.1)
- **Custom mutator:** `build/png_mutator.so`

## Time Estimate

- Machine specs: 2 minutes
- Running experiments: 3-4 hours (or 15 min for quick tests)
- Analyzing results: 30 minutes
- Writing ANALYSIS.md: 30-60 minutes
- **Total: 4-5 hours** (or ~1.5 hours with quick tests)

## Grading Rubric Reminder

- Part A (5 pts): ✅ Complete
- Part B (5 pts): Need to run experiments and document
- Part C (5 pts): Can skip with explanation OR run without sanitizers
- Part D (5 pts EC): Need to run experiments and document

**Potential score: 10-20 points** depending on completion
