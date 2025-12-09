# ECS160 HW3: Fuzzing LibPNG with AFL++

This repository contains a complete implementation for fuzzing the LibPNG library using AFL++ with various configurations.

## Contents

- `harness.c` - Test harness for LibPNG fuzzing
- `build.sh` - Automated build script for AFL++, LibPNG, and all configurations
- `run_fuzzing.sh` - Script to run all fuzzing experiments
- `png_mutator.c` - Custom PNG-aware mutator for AFL++ (Extra Credit)
- `build_custom_mutator.sh` - Build script for the custom mutator
- `ANALYSIS.md` - Template for reporting experimental results

## Quick Start

### Prerequisites

- GCC or Clang compiler
- Make
- Git
- wget or curl
- Standard build tools (libtool, autoconf, automake)

On Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install build-essential git wget libtool automake autoconf
```

On macOS:
```bash
xcode-select --install
brew install wget
```

### Step 1: Build Everything

Run the build script to clone and compile AFL++, LibPNG, and create all fuzzing targets:

```bash
chmod +x build.sh
./build.sh
```

This will:
1. Clone and build AFL++
2. Download and build zlib (LibPNG dependency)
3. Clone LibPNG
4. Build Part B configuration (AFL++ without sanitizers)
5. Build Part C configuration (AFL++ with ASAN/UBSAN)
6. Create necessary directories

**Expected build time:** 10-20 minutes depending on your system

### Step 2: Download Seed PNG Files

Download 10 sample PNG files and place them in the `build/seeds/` directory:

```bash
# Example: Download some PNG files
mkdir -p build/seeds
cd build/seeds

# Download sample PNGs (you can use any PNG files)
# Here are some suggestions:
wget http://www.schaik.com/pngsuite/basn0g01.png  # 1-bit grayscale
wget http://www.schaik.com/pngsuite/basn0g02.png  # 2-bit grayscale
wget http://www.schaik.com/pngsuite/basn0g04.png  # 4-bit grayscale
wget http://www.schaik.com/pngsuite/basn0g08.png  # 8-bit grayscale
wget http://www.schaik.com/pngsuite/basn2c08.png  # 8-bit RGB
wget http://www.schaik.com/pngsuite/basn2c16.png  # 16-bit RGB
wget http://www.schaik.com/pngsuite/basn3p01.png  # 1-bit palette
wget http://www.schaik.com/pngsuite/basn3p04.png  # 4-bit palette
wget http://www.schaik.com/pngsuite/basn4a08.png  # 8-bit grayscale + alpha
wget http://www.schaik.com/pngsuite/basn6a08.png  # 8-bit RGBA

cd ../..
```

Alternatively, you can use your own PNG files or download from any source.

### Step 3: Build Custom Mutator (Optional - Extra Credit)

If you want to complete Part D (Extra Credit), build the custom mutator:

```bash
chmod +x build_custom_mutator.sh
./build_custom_mutator.sh
```

### Step 4: Run Fuzzing Experiments

Run the fuzzing script:

```bash
chmod +x run_fuzzing.sh
./run_fuzzing.sh
```

This will sequentially run:
- Part B.1: Fuzzing without seeds (1 hour)
- Part B.2: Fuzzing with seeds (1 hour)
- Part C: Fuzzing with ASAN/UBSAN (1 hour)
- Part D: Fuzzing with custom mutator (1 hour, if mutator built)

**Total time:** 3-4 hours

You can also run individual experiments manually (see "Manual Execution" section below).

### Step 5: Collect Results

After fuzzing completes, check the results:

```bash
# View summary statistics for each experiment
build/AFLplusplus/afl-whatsup build/output-b1-no-seeds
build/AFLplusplus/afl-whatsup build/output-b2-with-seeds
build/AFLplusplus/afl-whatsup build/output-c-sanitizers
build/AFLplusplus/afl-whatsup build/output-d-custom-mutator  # If Part D was run
```

Crashes will be in:
- `build/output-b1-no-seeds/default/crashes/`
- `build/output-b2-with-seeds/default/crashes/`
- `build/output-c-sanitizers/default/crashes/`
- `build/output-d-custom-mutator/default/crashes/`

### Step 6: Fill Out ANALYSIS.md

Use the template in [ANALYSIS.md](ANALYSIS.md) to document your results. Fill in:
- Machine specifications
- Results tables (crashes, coverage, exec/sec)
- Observations and analysis
- Crash details

## Manual Execution

If you want to run experiments individually or with custom parameters:

### Part B.1: No Seeds

```bash
build/AFLplusplus/afl-fuzz \
  -i build/empty-seeds \
  -o build/output-b1-no-seeds \
  -V 1h \
  -- build/harness-b @@
```

### Part B.2: With Seeds

```bash
build/AFLplusplus/afl-fuzz \
  -i build/seeds \
  -o build/output-b2-with-seeds \
  -V 1h \
  -- build/harness-b @@
```

### Part C: With Sanitizers

```bash
AFL_USE_ASAN=1 AFL_USE_UBSAN=1 \
build/AFLplusplus/afl-fuzz \
  -i build/seeds \
  -o build/output-c-sanitizers \
  -V 1h \
  -m none \
  -- build/harness-c @@
```

### Part D: Custom Mutator (Extra Credit)

```bash
AFL_USE_ASAN=1 AFL_USE_UBSAN=1 \
AFL_CUSTOM_MUTATOR_LIBRARY=build/png_mutator.so \
build/AFLplusplus/afl-fuzz \
  -i build/seeds \
  -o build/output-d-custom-mutator \
  -V 1h \
  -m none \
  -- build/harness-c @@
```

## Project Structure

```
ecs160-hw3/
├── harness.c                    # LibPNG test harness
├── png_mutator.c                # Custom PNG mutator (Part D)
├── build.sh                     # Main build script
├── build_custom_mutator.sh      # Mutator build script
├── run_fuzzing.sh              # Fuzzing automation script
├── ANALYSIS.md                  # Results template
├── README.md                    # This file
└── build/                       # Created by build.sh
    ├── AFLplusplus/            # AFL++ installation
    ├── libpng/                 # LibPNG source
    ├── zlib/                   # zlib source
    ├── libpng-b/               # Part B LibPNG build
    ├── libpng-c/               # Part C LibPNG build
    ├── zlib-b/                 # Part B zlib build
    ├── zlib-c/                 # Part C zlib build
    ├── harness-b               # Part B binary
    ├── harness-c               # Part C binary
    ├── png_mutator.so          # Custom mutator library
    ├── seeds/                  # Seed PNG files
    ├── empty-seeds/            # Empty directory for no-seed fuzzing
    ├── output-b1-no-seeds/     # Part B.1 results
    ├── output-b2-with-seeds/   # Part B.2 results
    ├── output-c-sanitizers/    # Part C results
    └── output-d-custom-mutator/# Part D results
```

## Test Harness Details

The test harness ([harness.c](harness.c)) exercises the following LibPNG APIs:

**Core Functions:**
- `png_create_read_struct()` - Create read structure
- `png_create_info_struct()` - Create info structure
- `png_init_io()` - Initialize I/O
- `png_read_info()` - Read PNG info
- `png_read_image()` - Read image data
- `png_read_end()` - Complete reading

**Transformation Functions:**
- `png_set_palette_to_rgb()` - Expand palette to RGB
- `png_set_expand_gray_1_2_4_to_8()` - Expand grayscale
- `png_set_tRNS_to_alpha()` - Expand transparency
- `png_set_gray_to_rgb()` - Convert grayscale to RGB
- `png_set_filler()` - Add alpha channel
- `png_set_scale_16()` - Scale 16-bit to 8-bit

**Query Functions:**
- `png_get_image_width()`, `png_get_image_height()`
- `png_get_color_type()`, `png_get_bit_depth()`
- `png_get_channels()`, `png_get_rowbytes()`

**Write Functions (Optional):**
- `png_create_write_struct()` - Create write structure
- `png_set_IHDR()` - Set image header
- `png_write_info()`, `png_write_image()`, `png_write_end()`

## Custom Mutator Details

The custom PNG mutator implements format-aware mutations:

1. **CRC Corruption** - Flip bits in chunk CRC checksums
2. **Length Field Mutations** - Modify chunk length values
3. **IHDR Mutations** - Corrupt critical header data
4. **Chunk Duplication** - Duplicate random chunks
5. **Chunk Type Modification** - Change chunk type codes
6. **IDAT Corruption** - Modify compressed image data
7. **Chunk Removal** - Delete non-critical chunks
8. **Random Mutations** - Random byte flips as fallback

## Troubleshooting

### Build Issues

**Problem:** AFL++ build fails with compiler errors
**Solution:** Ensure you have a recent GCC or Clang version. Try `export CC=gcc` or `export CC=clang` before building.

**Problem:** LibPNG configure fails to find zlib
**Solution:** Make sure zlib is built first and the path is correct in build.sh

**Problem:** "Cannot find -lpng" when building harness
**Solution:** Check that LibPNG was installed to the correct prefix directory

### Fuzzing Issues

**Problem:** AFL++ complains about CPU frequency scaling
**Solution:** This is a performance warning. You can ignore it or follow AFL++'s suggestions to fix.

**Problem:** "No instrumentation detected" error
**Solution:** Ensure the binary was compiled with afl-cc/afl-c++. Check that AFL_CC is set correctly.

**Problem:** Fuzzing is very slow with sanitizers
**Solution:** This is expected. ASAN/UBSAN add significant overhead (~2-5x slower). Consider using `-m none` flag.

**Problem:** AFL++ exits immediately
**Solution:** Check that seed directory exists and contains valid files (for seed-based fuzzing) or is empty (for no-seed fuzzing).

### Runtime Issues

**Problem:** "Crashing test case found" but crash doesn't reproduce
**Solution:** Ensure you're using the same binary and environment. Sanitizer crashes may not reproduce without sanitizers.

**Problem:** Out of memory errors
**Solution:** Use `-m none` flag for sanitizer builds, or increase memory limits.

## Tips for Better Results

1. **Use diverse seed corpus:** Include PNGs with different color types, bit depths, and sizes
2. **Run longer:** 1 hour is the minimum, but longer runs (24h+) find more bugs
3. **Use multiple cores:** AFL++ supports parallel fuzzing with `-M` and `-S` flags
4. **Monitor progress:** Use `afl-whatsup` and watch the coverage growth
5. **Triage crashes:** Use `afl-tmin` to minimize crashing inputs and `afl-cmin` for corpus minimization

## Submission Checklist

- [ ] `harness.c` - Test harness implementation
- [ ] `build.sh` - Complete build automation script
- [ ] `png_mutator.c` - Custom mutator (if doing Part D)
- [ ] `build_custom_mutator.sh` - Mutator build script (if doing Part D)
- [ ] `ANALYSIS.md` - Completed analysis with all results
- [ ] All scripts are executable (`chmod +x *.sh`)

## References

- [AFL++ Documentation](https://github.com/AFLplusplus/AFLplusplus/tree/stable/docs)
- [LibPNG Manual](http://www.libpng.org/pub/png/libpng-manual.txt)
- [PNG Specification](http://www.libpng.org/pub/png/spec/1.2/PNG-Contents.html)
- [AFL++ Custom Mutators](https://aflplus.plus/docs/custom_mutators/)

## License

This is educational code for ECS160. Use at your own risk.
