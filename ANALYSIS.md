# LibPNG Fuzzing Analysis - ECS160 HW3

## Machine Specifications

### Machine 1: macOS (Parts B.1, B.2, and D)
- **CPU:** Apple M2 Pro
- **RAM:** 16 GB
- **OS:** macOS 15.6.1

### Machine 2: CSIF VM (Part c)
- **CPU:** Intel(R) Core(TM) i7-10700 CPU @ 2.90GHz
- **RAM:** 32 GB
- **OS:** Linux

## Part B: AFL++ Fuzzing (Without Sanitizers)

### Part B.1: Fuzzing Without Seeds (1 hour)

**Results:**

| Metric | Value |
|--------|-------|
| **Total Crashes** | 0 |
| **Unique Crashes** | 0 |
| **Total Coverage (edges)** | 4 |
| **Map Coverage** | 8.00% |
| **Total Executions** | 7,698,482 |
| **Executions per second** | 2,132.91 |

**Observations:**
- Without seed inputs, AFL++ had to start from scratch and generate valid PNG files
- The fuzzer achieved very low coverage
- No crashes were found, likely because most inputs were rejected before reaching complex parsing logic

### Part B.2: Fuzzing With Seeds (1 hour)

**Seed Files Used:**
1. basn0g01.png - 1-bit grayscale (164 bytes)
2. basn0g02.png - 2-bit grayscale (104 bytes)
3. basn0g04.png - 4-bit grayscale (145 bytes)
4. basn0g08.png - 8-bit grayscale (138 bytes)
5. basn2c08.png - 8-bit RGB (145 bytes)
6. basn3p02.png - 2-bit palette (146 bytes)
7. basn3p04.png - 4-bit palette (216 bytes)
8. basn4a08.png - 8-bit grayscale + alpha (126 bytes)
9. basn6a08.png - 8-bit RGBA (184 bytes)
10. basn6a16.png - 16-bit RGBA (3.4 KB)

**Results:**

| Metric | Value |
|--------|-------|
| **Total Crashes** | 0 |
| **Unique Crashes** | 0 |
| **Total Coverage (edges)** | 25 |
| **Map Coverage** | 50.00% |
| **Total Executions** | 7,442,284 |
| **Executions per second** | 2,067.30 |

**Comparison with Part B.1:**
- Coverage increased dramatically
- Execution speed slightly decreased
- Despite better coverage, still no crashes found (LibPNG appears robust against basic mutations without sanitizers)

## Part C: AFL++ with ASAN and UBSAN (1 hour)

**Results:**

| Metric | Value |
|--------|-------|
| **Total Crashes** | 1 |
| **Unique Crashes** | 1 |
| **Total Coverage (edges)** | 26 |
| **Map Coverage** | 36.62% |
| **Total Executions** | 200,130 |
| **Executions per second** | 54.43 |

**Comparison with Part B.2:**
- Execution speed decreased due to sanitizer overhead
- Sanitizers successfully detected a bug
- Coverage slightly increased
- Map coverage decreased, likely due to different execution paths with instrumentation

**Crash Analysis:**
- Signal 6 (SIGABRT) - triggered by sanitizer detection
  - **File:** `id:000000,sig:06,src:000004,time:2893593,execs:161718,op:havoc,rep:13`
  - **Type:** Memory safety violation
  - **Severity:** High
  - **Details:** The crash was found after 161,718 executions using the havoc mutation strategy
  - **Source:** Derived from mutation of seed file #4

## Part D: Custom Mutator (1 hour)

**Custom Mutator Design:**

The custom mutator implements PNG format-aware mutations. The mutation strategies include:

1. Intentionally corrupts CRC checksums in random chunks to test error detection and handling

2. Modifies the length field of chunks to create malformed inputs:
   - Increases/decreases by random values
   - Sets to extreme values (0x00000000, 0xFFFFFFFF)

3. Targets the critical IHDR chunk by flipping random bits in the header data

4. Duplicates random chunks to test handling of repeated data

5. Changes chunk type identifiers to create unknown or invalid chunk types

6. Modifies compressed image data to test decompression error handling

7. Removes non-critical chunks to test handling of incomplete PNG files

8. Falls back to random byte flips for exploration

**Results:**

| Metric | Value |
|--------|-------|
| **Total Crashes** | 0 |
| **Unique Crashes** | 0 |
| **Total Coverage (edges)** | 25 |
| **Map Coverage** | 50.00% |
| **Total Executions** | 7,087,541 |
| **Executions per second** | 2,605.20 |

**Effectiveness Analysis:**
- Performance: The custom mutator was the fastest configuration tested
- Coverage: Did not improve coverage over standard AFL++ mutations
- Bug Finding: Without sanitizers, no crashes were found
- PNG-Aware Mutations: The format-aware mutations maintained efficiency but didn't unlock new code paths
- Potential Improvements:
  - Combine custom mutator with sanitizers
  - Add more sophisticated mutations targeting specific PNG vulnerabilities
  - Implement mutations that focus on chunk ordering and dependencies
  - Add fuzzing dictionary with PNG-specific magic values