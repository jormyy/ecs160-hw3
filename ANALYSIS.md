# LibPNG Fuzzing Analysis - ECS160 HW3

**Student Name:** [Your Name]
**Student ID:** [Your ID]
**Date:** [Date]

## Machine Specifications

### Machine 1 (Used for Parts B and C)
- **CPU:** [e.g., Intel Core i7-9750H @ 2.60GHz, 6 cores, 12 threads]
- **RAM:** [e.g., 16 GB DDR4]
- **OS:** [e.g., Ubuntu 22.04 LTS / macOS 14.0]
- **Disk:** [e.g., SSD]

### Machine 2 (If different machine used for Part D)
- **CPU:** [Specify if different]
- **RAM:** [Specify if different]
- **OS:** [Specify if different]
- **Disk:** [Specify if different]

---

## Part B: AFL++ Fuzzing (Without Sanitizers)

### Part B.1: Fuzzing Without Seeds (1 hour)

**Configuration:**
- Fuzzer: AFL++
- Sanitizers: None
- Seeds: None (empty seed directory)
- Duration: 1 hour

**Results:**

| Metric | Value |
|--------|-------|
| **Total Crashes** | [e.g., 0] |
| **Unique Crashes** | [e.g., 0] |
| **Total Coverage (edges)** | [e.g., 1,234] |
| **Total Executions** | [e.g., 1,500,000] |
| **Executions per second** | [e.g., 416.67] |
| **Paths Found** | [e.g., 50] |

**Observations:**
[Write your observations here. For example:]
- Without seed inputs, AFL++ had to start from scratch generating valid PNG files
- The fuzzer struggled to pass the PNG signature validation initially
- Coverage increased slowly as the fuzzer learned the PNG format
- [Any other notable observations]

**Sample Command Used:**
```bash
afl-fuzz -i build/empty-seeds -o build/output-b1-no-seeds -V 1h -- build/harness-b @@
```

---

### Part B.2: Fuzzing With Seeds (1 hour)

**Configuration:**
- Fuzzer: AFL++
- Sanitizers: None
- Seeds: 10 PNG files
- Duration: 1 hour

**Seed Files Used:**
1. [e.g., sample1.png - 1024x768 RGB]
2. [e.g., sample2.png - 256x256 grayscale]
3. [Continue listing all 10 seed files with brief descriptions]
4. ...
10. [Last seed file]

**Results:**

| Metric | Value |
|--------|-------|
| **Total Crashes** | [e.g., 3] |
| **Unique Crashes** | [e.g., 2] |
| **Total Coverage (edges)** | [e.g., 2,456] |
| **Total Executions** | [e.g., 3,200,000] |
| **Executions per second** | [e.g., 888.89] |
| **Paths Found** | [e.g., 450] |

**Comparison with Part B.1:**
[Compare the results. For example:]
- Coverage increased by [X%] compared to no-seed fuzzing
- Execution speed was [faster/slower] by [X%]
- [Number] crashes were found, compared to [number] in Part B.1
- The seed corpus allowed AFL++ to start with valid PNG structure knowledge

**Crash Analysis:**
[If crashes were found, analyze them:]
- **Crash 1:** [Brief description - e.g., "Segmentation fault in png_read_image()"]
- **Crash 2:** [Brief description]
- [Include stack traces or error messages if relevant]

**Sample Command Used:**
```bash
afl-fuzz -i build/seeds -o build/output-b2-with-seeds -V 1h -- build/harness-b @@
```

---

## Part C: AFL++ with ASAN and UBSAN (1 hour)

**Configuration:**
- Fuzzer: AFL++
- Sanitizers: AddressSanitizer (ASAN) + UndefinedBehaviorSanitizer (UBSAN)
- Seeds: 10 PNG files (same as Part B.2)
- Duration: 1 hour

**Results:**

| Metric | Value |
|--------|-------|
| **Total Crashes** | [e.g., 5] |
| **Unique Crashes** | [e.g., 4] |
| **Total Coverage (edges)** | [e.g., 2,400] |
| **Total Executions** | [e.g., 800,000] |
| **Executions per second** | [e.g., 222.22] |
| **Paths Found** | [e.g., 420] |

**Comparison with Part B.2:**
[Compare the results. For example:]
- Execution speed decreased by approximately [X%] due to sanitizer overhead
- [More/Fewer/Same number of] crashes found compared to Part B.2
- Coverage was [similar/different] - [provide explanation]
- Sanitizers detected [number] additional bugs not caught without instrumentation

**Crash Analysis:**
[Analyze crashes found by sanitizers:]
- **Crash 1:** [e.g., "Heap-buffer-overflow in png_set_IHDR() - ASAN detected"]
  - **Type:** [e.g., Memory corruption]
  - **Severity:** [High/Medium/Low]
  - **Details:** [Stack trace snippet or error message]

- **Crash 2:** [Similar analysis]
- ...

**Sanitizer-Specific Findings:**
[Describe bugs found only with sanitizers:]
- ASAN detected [number] memory errors
- UBSAN detected [number] undefined behavior instances
- [Specific examples of bugs that wouldn't crash without sanitizers]

**Sample Command Used:**
```bash
AFL_USE_ASAN=1 AFL_USE_UBSAN=1 afl-fuzz -i build/seeds -o build/output-c-sanitizers -V 1h -m none -- build/harness-c @@
```

---

## Part D: Custom Mutator (Extra Credit - 1 hour)

**Configuration:**
- Fuzzer: AFL++
- Sanitizers: AddressSanitizer (ASAN) + UndefinedBehaviorSanitizer (UBSAN)
- Seeds: 10 PNG files (same as Parts B.2 and C)
- Custom Mutator: PNG-aware mutator
- Duration: 1 hour

**Custom Mutator Design:**

The custom mutator implements PNG format-aware mutations to generate more effective test cases. The mutation strategies include:

1. **CRC Corruption (20% probability):** Intentionally corrupts CRC checksums in random chunks to test error detection and handling.

2. **Chunk Length Manipulation (20% probability):** Modifies the length field of chunks to create malformed inputs:
   - Increases/decreases by random values
   - Sets to extreme values (0x00000000, 0xFFFFFFFF)

3. **IHDR Mutations (10% probability):** Targets the critical IHDR chunk by flipping random bits in the header data (width, height, bit depth, color type, etc.)

4. **Chunk Duplication (10% probability):** Duplicates random chunks to test handling of repeated data.

5. **Chunk Type Modification (10% probability):** Changes chunk type identifiers to create unknown or invalid chunk types.

6. **IDAT Corruption (10% probability):** Modifies compressed image data to test decompression error handling.

7. **Chunk Removal (10% probability):** Removes non-critical chunks to test handling of incomplete PNG files.

8. **Random Mutations (10% probability):** Falls back to random byte flips for exploration.

**Rationale:**
The custom mutator leverages knowledge of PNG file structure to generate more meaningful test cases than purely random mutations. By targeting specific chunks and fields, it can more efficiently explore edge cases and error handling paths in LibPNG.

**Results:**

| Metric | Value |
|--------|-------|
| **Total Crashes** | [e.g., 7] |
| **Unique Crashes** | [e.g., 5] |
| **Total Coverage (edges)** | [e.g., 2,550] |
| **Total Executions** | [e.g., 750,000] |
| **Executions per second** | [e.g., 208.33] |
| **Paths Found** | [e.g., 480] |

**Comparison with Part C:**
[Compare results with standard AFL++ mutations:]
- [More/Fewer] unique crashes found
- Coverage [increased/decreased] by [X edges/X%]
- Execution speed was [similar/different]
- The custom mutator was [more/less] effective at finding bugs

**Effectiveness Analysis:**
[Analyze the effectiveness of the custom mutator:]
- Did the PNG-aware mutations lead to better coverage?
- Were the crashes found different from those in Part C?
- Which mutation strategies were most effective?
- What could be improved in the custom mutator?

**Sample Command Used:**
```bash
AFL_USE_ASAN=1 AFL_USE_UBSAN=1 AFL_CUSTOM_MUTATOR_LIBRARY=build/png_mutator.so \
  afl-fuzz -i build/seeds -o build/output-d-custom-mutator -V 1h -m none -- build/harness-c @@
```

---

## Summary and Conclusions

### Overall Findings

**Fuzzing Effectiveness:**
[Summarize the overall effectiveness of fuzzing LibPNG:]
- Total unique bugs found across all experiments: [number]
- Most effective configuration: [Part B.2/C/D]
- Impact of seed corpus: [significant/moderate/minimal]
- Impact of sanitizers: [significant/moderate/minimal]
- Impact of custom mutator: [significant/moderate/minimal]

### Coverage Comparison

| Configuration | Coverage (edges) | Relative to B.1 |
|---------------|------------------|-----------------|
| B.1 (No seeds) | [value] | 100% |
| B.2 (With seeds) | [value] | [X%] |
| C (Sanitizers) | [value] | [X%] |
| D (Custom mutator) | [value] | [X%] |

### Performance Comparison

| Configuration | Exec/sec | Relative to B.1 |
|---------------|----------|-----------------|
| B.1 (No seeds) | [value] | 100% |
| B.2 (With seeds) | [value] | [X%] |
| C (Sanitizers) | [value] | [X%] |
| D (Custom mutator) | [value] | [X%] |

### Key Insights

1. **Seed Corpus Impact:**
   [Discuss how seeds affected fuzzing effectiveness]

2. **Sanitizer Overhead vs. Bug Detection:**
   [Discuss the trade-off between execution speed and bug detection capability]

3. **Custom Mutator Value:**
   [Discuss whether format-aware mutations provided advantages]

4. **LibPNG Robustness:**
   [Comment on the overall robustness of LibPNG based on findings]

### Recommendations

[Provide recommendations based on your findings:]
- For future fuzzing campaigns on LibPNG or similar libraries
- Optimal configuration choices
- Improvements to the test harness or mutator

---

## Appendix

### Example Crash Details

[Include detailed information about 1-2 interesting crashes, such as:]

**Crash Example 1:**
```
File: crash-id-000001
ASAN Error:
==12345==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x...
[Include relevant stack trace]
```

**Minimized Input:** [Describe or show hex dump of minimized crashing input]

### AFL++ Statistics Screenshots

[Optional: Include screenshots or detailed output from afl-whatsup for each experiment]

### References

1. AFL++ Documentation: https://github.com/AFLplusplus/AFLplusplus
2. LibPNG Specification: http://www.libpng.org/pub/png/spec/1.2/PNG-Contents.html
3. PNG Specification (Wikipedia): https://en.wikipedia.org/wiki/PNG
