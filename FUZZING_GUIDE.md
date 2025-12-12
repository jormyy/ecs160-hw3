# LibPNG Fuzzing Guide

## macOS Setup (Required Before Fuzzing)

On macOS, you need to disable crash reporting to avoid AFL timeouts:

```bash
SL=/System/Library; PL=com.apple.ReportCrash
sudo launchctl unload -w ${SL}/LaunchAgents/${PL}.plist
sudo launchctl unload -w ${SL}/LaunchDaemons/${PL}.Root.plist
```

## Quick Start

### 1. Download seed files (already done if you ran it):
```bash
./download_seeds.sh
```

### 2. Run fuzzing manually:

#### Part B.1: AFL++ without seeds (1 hour)
```bash
timeout 1h build/AFLplusplus/afl-fuzz \
    -i build/empty-seeds \
    -o build/output-b1-no-seeds \
    -Q \
    -- build/harness-b @@
```

#### Part B.2: AFL++ with seeds (1 hour)
```bash
timeout 1h build/AFLplusplus/afl-fuzz \
    -i build/seeds \
    -o build/output-b2-with-seeds \
    -Q \
    -- build/harness-b @@
```

#### Part C: AFL++ with ASAN/UBSAN (1 hour)
```bash
timeout 1h build/AFLplusplus/afl-fuzz \
    -i build/seeds \
    -o build/output-c-sanitizers \
    -m none \
    -Q \
    -- build/harness-c @@
```

## Quick Test (10 seconds)

To quickly test if everything works:

```bash
# Test for 10 seconds
timeout 10s build/AFLplusplus/afl-fuzz \
    -i build/seeds \
    -o build/test-output \
    -Q \
    -- build/harness-b @@
```

Then check the results:
```bash
ls -la build/test-output/default/
```

## Viewing Results

After fuzzing completes, view statistics:
```bash
build/AFLplusplus/afl-whatsup build/output-b1-no-seeds
```

Check for crashes:
```bash
ls -la build/output-b1-no-seeds/default/crashes/
```

Replay a crash:
```bash
build/harness-b build/output-b1-no-seeds/default/crashes/id:000000*
```

## Understanding the Output

- **queue/**: Test cases generated during fuzzing
- **crashes/**: Inputs that caused crashes
- **hangs/**: Inputs that caused timeouts
- **fuzzer_stats**: Detailed fuzzing statistics

## Notes

- The `-Q` flag enables QEMU mode (for binaries without compile-time instrumentation)
- The `@@` is replaced by AFL with the path to each test input file
- For Part C, `-m none` disables memory limit (needed for ASAN)
- Press Ctrl+C to stop fuzzing early

## Troubleshooting

**Error: "Hmm, your system is configured to forward crash notifications"**
→ Run the macOS setup commands above

**Error: "No instrumentation detected"**
→ This is expected, that's why we use `-Q` (QEMU mode)

**Fuzzing is very slow on macOS**
→ This is normal. macOS has high fork() overhead. Consider using Linux VM for better performance.
