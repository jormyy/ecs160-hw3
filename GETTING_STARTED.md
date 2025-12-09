# Quick Start Guide - ECS160 HW3

## What You Have

Your homework directory now contains everything needed to complete ECS160 HW3:

1. **harness.c** - Complete LibPNG fuzzing harness
2. **build.sh** - Automated build script for all parts
3. **run_fuzzing.sh** - Script to run all experiments
4. **png_mutator.c** - Custom PNG mutator for extra credit
5. **build_custom_mutator.sh** - Build script for the mutator
6. **ANALYSIS.md** - Template for your results report
7. **README.md** - Detailed documentation

## Next Steps (In Order)

### Step 1: Build Everything (~15-20 minutes)

```bash
./build.sh
```

This will:
- Clone and compile AFL++ from GitHub
- Download and build zlib and LibPNG
- Create fuzzing binaries for Parts B and C
- Set up required directories

**What to watch for:**
- The build process will take 10-20 minutes
- You'll see compilation output - this is normal
- At the end, you should see "Build Complete" message

### Step 2: Get PNG Seed Files (~5 minutes)

You need 10 PNG files for fuzzing. Easy option:

```bash
mkdir -p build/seeds
cd build/seeds

# Download from PNG test suite
wget http://www.schaik.com/pngsuite/basn0g01.png
wget http://www.schaik.com/pngsuite/basn0g02.png
wget http://www.schaik.com/pngsuite/basn0g04.png
wget http://www.schaik.com/pngsuite/basn0g08.png
wget http://www.schaik.com/pngsuite/basn2c08.png
wget http://www.schaik.com/pngsuite/basn2c16.png
wget http://www.schaik.com/pngsuite/basn3p01.png
wget http://www.schaik.com/pngsuite/basn3p04.png
wget http://www.schaik.com/pngsuite/basn4a08.png
wget http://www.schaik.com/pngsuite/basn6a08.png

cd ../..
```

Alternatively, you can copy any 10 PNG files you have into `build/seeds/`

### Step 3: Build Custom Mutator (Optional - Extra Credit)

```bash
./build_custom_mutator.sh
```

This builds the PNG-aware mutator for Part D (extra credit).

### Step 4: Run Experiments (~3-4 hours total)

**Option A: Run All Automatically**
```bash
./run_fuzzing.sh
```
This will run all parts sequentially. Each part takes 1 hour.

**Option B: Run Parts Individually**

For Part B.1 (no seeds):
```bash
build/AFLplusplus/afl-fuzz -i build/empty-seeds -o build/output-b1-no-seeds -V 1h -- build/harness-b @@
```

For Part B.2 (with seeds):
```bash
build/AFLplusplus/afl-fuzz -i build/seeds -o build/output-b2-with-seeds -V 1h -- build/harness-b @@
```

For Part C (sanitizers):
```bash
AFL_USE_ASAN=1 AFL_USE_UBSAN=1 build/AFLplusplus/afl-fuzz -i build/seeds -o build/output-c-sanitizers -V 1h -m none -- build/harness-c @@
```

For Part D (custom mutator - extra credit):
```bash
AFL_USE_ASAN=1 AFL_USE_UBSAN=1 AFL_CUSTOM_MUTATOR_LIBRARY=build/png_mutator.so build/AFLplusplus/afl-fuzz -i build/seeds -o build/output-d-custom-mutator -V 1h -m none -- build/harness-c @@
```

### Step 5: Collect Results

After each experiment finishes, check results:

```bash
# View statistics summary
build/AFLplusplus/afl-whatsup build/output-b1-no-seeds
build/AFLplusplus/afl-whatsup build/output-b2-with-seeds
build/AFLplusplus/afl-whatsup build/output-c-sanitizers
build/AFLplusplus/afl-whatsup build/output-d-custom-mutator  # if you ran Part D
```

**Important metrics to record:**
- Total executions
- Executions per second
- Paths found (coverage)
- Unique crashes
- Total crashes

**Where to find crashes:**
- `build/output-*/default/crashes/`

### Step 6: Fill Out ANALYSIS.md

Open `ANALYSIS.md` and fill in:

1. **Machine Specifications** - Use `lscpu` (Linux) or `sysctl -a | grep cpu` (Mac)
2. **Results Tables** - Copy data from afl-whatsup output
3. **Observations** - Your analysis of what happened
4. **Crash Analysis** - Details about any crashes found

**Grading Tip:** Be thorough in your analysis. Compare results between configurations and explain why differences occurred.

## Common Issues and Solutions

### "Command not found" for afl-fuzz
**Problem:** AFL++ not in PATH
**Solution:** Use full path: `build/AFLplusplus/afl-fuzz` instead of just `afl-fuzz`

### Build fails on macOS
**Problem:** Missing Xcode command line tools
**Solution:** Run `xcode-select --install`

### Fuzzing exits immediately
**Problem:** No seed files or wrong directory
**Solution:** Make sure `build/seeds/` has 10 PNG files (for B.2, C, D) or use `build/empty-seeds/` (for B.1)

### Very slow execution with sanitizers
**Expected behavior:** ASAN/UBSAN add 2-5x overhead. This is normal.

### No crashes found
**This is OK:** LibPNG is a mature library. Finding 0-3 crashes is normal for a 1-hour run. Focus on documenting coverage and execution stats.

## Time Management

- **Build:** 20 minutes
- **Get seeds:** 5 minutes
- **Part B.1:** 1 hour (can run overnight)
- **Part B.2:** 1 hour (can run overnight)
- **Part C:** 1 hour (can run overnight)
- **Part D:** 1 hour (optional, can run overnight)
- **Analysis:** 1-2 hours

**Total:** ~7-8 hours (mostly unattended fuzzing)

**Recommendation:** Start builds today, run experiments overnight, analyze tomorrow.

## Submission Requirements

Submit these files:
1. `harness.c` - Your test harness
2. `build.sh` - Build automation script
3. `ANALYSIS.md` - Completed analysis with results
4. `png_mutator.c` - Custom mutator (if doing Part D)
5. `build_custom_mutator.sh` - Mutator build script (if doing Part D)

**Do NOT submit:**
- The `build/` directory (too large)
- AFL++ source code
- LibPNG source code
- Output directories

## Tips for Success

1. **Start Early:** Build process can have unexpected issues
2. **Run Overnight:** Fuzzing takes 3-4 hours total
3. **Document as You Go:** Take notes while experiments run
4. **Compare Results:** The comparison between configurations is important
5. **Explain Differences:** Why did seeds help? Why did sanitizers slow things down?

## Need Help?

- Check [README.md](README.md) for detailed documentation
- Review AFL++ docs: https://github.com/AFLplusplus/AFLplusplus/tree/stable/docs
- Check LibPNG manual: http://www.libpng.org/pub/png/libpng-manual.txt

Good luck!
