# Final Instructions - Complete Your Homework

## You Have Everything Ready!

Your homework is **95% complete**. You just need to:
1. Run the fuzzing experiments (1 hour)
2. Fill in ANALYSIS.md with results (~30 minutes)

## Two Options for Running Experiments

### Option 1: Run on Linux VM (RECOMMENDED - Full ASAN+UBSAN)

**Advantages:**
- ✅ Full ASAN+UBSAN support (catches memory errors + undefined behavior)
- ✅ Better performance (10-30% faster)
- ✅ No compatibility issues
- ✅ More crashes likely to be found

**Steps:**
1. Set up Ubuntu VM (see [LINUX_VM_INSTRUCTIONS.md](LINUX_VM_INSTRUCTIONS.md:1-240))
2. Transfer files to VM
3. Run on Linux:
   ```bash
   ./build_linux.sh
   ./download_seeds.sh
   ./build_custom_mutator.sh
   ./run_all_parallel_linux.sh  # 1 hour
   ./extract_results.sh
   ```
4. Copy results back to Mac
5. Fill in ANALYSIS.md

**Time: ~2 hours** (including VM setup)

### Option 2: Run on macOS (UBSAN only)

**Advantages:**
- ✅ No VM setup needed
- ✅ Can start immediately
- ✅ Still gets partial credit for Part C

**Disadvantages:**
- ⚠️ UBSAN only (no ASAN - misses memory errors)
- ⚠️ Need to document the limitation

**Steps:**
1. Run on Mac:
   ```bash
   ./run_all_parallel.sh  # 1 hour
   ./extract_results.sh
   ```
2. Fill in ANALYSIS.md
3. Note in Part C that you used UBSAN only due to macOS limitations

**Time: ~1.5 hours**

## Files Ready for Submission

### Required Files (Part A):
1. ✅ **harness.c** - Your test harness
2. ✅ **build.sh** (macOS) or **build_linux.sh** (Linux) - Build automation
3. ⏳ **ANALYSIS.md** - Fill in with your results

### Extra Credit (Part D):
4. ✅ **png_mutator.c** - Custom mutator
5. ✅ **build_custom_mutator.sh** - Mutator build script

### Helper Scripts (optional to submit):
- `run_all_parallel.sh` or `run_all_parallel_linux.sh`
- `extract_results.sh`
- `download_seeds.sh`

## Filling in ANALYSIS.md

### Step 1: Machine Specs (Lines 10-13)

Already extracted for you:
```markdown
**Machine 1 (Used for All Parts):**
- **CPU:** Apple M2 Pro (if macOS) OR [Your Linux VM CPU]
- **RAM:** 16 GB
- **OS:** macOS 15.6.1 OR Ubuntu 22.04 LTS
- **Disk:** SSD
```

### Step 2: Seed Files (Lines 67-71)

List your 10 seed files from `build/seeds/`:
```markdown
1. basn0g01.png - 1-bit grayscale (164 bytes)
2. basn0g02.png - 2-bit grayscale (104 bytes)
3. basn0g04.png - 4-bit grayscale (145 bytes)
4. basn0g08.png - 8-bit grayscale (138 bytes)
5. basn2c08.png - 8-bit RGB (145 bytes)
6. basn3p02.png - 2-bit palette (146 bytes)
7. basn3p04.png - 4-bit palette (216 bytes)
8. basn4a08.png - 8-bit grayscale+alpha (126 bytes)
9. basn6a08.png - 8-bit RGBA (184 bytes)
10. basn6a16.png - 16-bit RGBA (3.4 KB)
```

### Step 3: Extract Results

After fuzzing completes:
```bash
./extract_results.sh
```

This gives you values for:
- Total Crashes
- Unique Crashes
- Total Coverage (edges)
- Total Executions
- Executions per second
- Paths Found

### Step 4: Fill in Tables

For each part (B.1, B.2, C, D), fill in the table with values from `extract_results.sh`.

Example from a typical run:
```markdown
| Metric | Value |
|--------|-------|
| **Total Crashes** | 0 |
| **Unique Crashes** | 0 |
| **Total Coverage (edges)** | 25 |
| **Total Executions** | 2,300,000 |
| **Executions per second** | 640 |
| **Paths Found** | 13 |
```

### Step 5: Write Observations

Compare results:
- Did seeds help? (B.2 vs B.1)
- Did sanitizers find more bugs? (C vs B.2)
- Did custom mutator work better? (D vs B.2)

Example:
```markdown
**Observations:**
- With seed corpus, coverage increased from X to Y edges (Z% improvement)
- Execution speed decreased slightly due to larger initial corpus
- No crashes were found, indicating LibPNG is well-tested and robust
- The fuzzer explored 13 unique paths through the code
```

## Expected Results (Typical)

Based on LibPNG being a mature, well-tested library:
- **Crashes:** Likely 0 (LibPNG is very stable)
- **Coverage:** 20-50 edges (small harness, focused API testing)
- **Exec/sec:** 600-3000 depending on platform
- **Paths:** 10-30 unique paths

**Don't worry if you don't find crashes!** LibPNG is extremely well-tested. Document:
- The fuzzing process
- Coverage achieved
- Performance metrics
- Why you think no crashes were found (mature codebase, extensive testing)

## Grading Rubric Reminder

- **Part A (5 pts):** ✅ COMPLETE - harness.c + build scripts
- **Part B (5 pts):** ⏳ Run experiments + document results
- **Part C (5 pts):** ⏳ Run experiments + document (UBSAN or ASAN+UBSAN)
- **Part D (5 pts EC):** ⏳ Run experiments + document custom mutator

**Current progress: 5/15 pts (33%)**
**After fuzzing: 15-20/15 pts (100-133%)**

## Quick Start Commands

### On macOS:
```bash
./run_all_parallel.sh  # Press Enter when prompted
# Wait 1 hour
./extract_results.sh > my_results.txt
# Fill in ANALYSIS.md
```

### On Linux VM:
```bash
./build_linux.sh
./download_seeds.sh
./build_custom_mutator.sh
./run_all_parallel_linux.sh  # Press Enter when prompted
# Wait 1 hour
./extract_results.sh > my_results.txt
# Transfer results back to Mac
# Fill in ANALYSIS.md
```

## Need Help?

Check these files:
- [LINUX_VM_INSTRUCTIONS.md](LINUX_VM_INSTRUCTIONS.md:1-240) - VM setup guide
- [PART_C_NOTE.md](PART_C_NOTE.md:1-59) - Part C ASAN issues explained
- [COMPLETION_GUIDE.md](COMPLETION_GUIDE.md:1-124) - General completion guide

## You're Almost Done! 🎉

Just run the experiments and fill in ANALYSIS.md. Good luck!
