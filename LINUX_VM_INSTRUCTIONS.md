# Running Homework on Linux VM (Full ASAN+UBSAN Support)

## Why Use a Linux VM?

macOS has ASAN compatibility issues that prevent Part C from working properly. On Linux, you can use **full ASAN+UBSAN** to detect:
- ✅ Memory errors (buffer overflows, use-after-free, etc.) - **ASAN**
- ✅ Undefined behavior (integer overflow, null deref, etc.) - **UBSAN**

## Option 1: Ubuntu VM (Recommended)

### Setup Ubuntu VM (if you don't have one):

**Using UTM (Mac M1/M2):**
1. Download UTM: https://mac.getutm.app/
2. Download Ubuntu Server 22.04 ARM: https://ubuntu.com/download/server/arm
3. Create new VM in UTM with 4+ CPU cores, 8+ GB RAM
4. Install Ubuntu

**Using VirtualBox (Intel Mac/Windows):**
1. Download VirtualBox
2. Download Ubuntu Desktop 22.04: https://ubuntu.com/download/desktop
3. Create VM with 4+ CPU cores, 8+ GB RAM

**Using WSL2 (Windows):**
```bash
wsl --install Ubuntu-22.04
```

### Transfer Files to VM:

**Method 1: GitHub (recommended)**
```bash
# On your Mac
cd /Users/jorm/Documents/ecs160-hw3
git init
git add .
git commit -m "Initial commit"
git branch -M main
gh repo create ecs160-hw3 --private --source=. --push

# On Linux VM
git clone https://github.com/YOUR_USERNAME/ecs160-hw3
cd ecs160-hw3
```

**Method 2: SCP**
```bash
# On Linux VM, get IP address
ip addr show

# On Mac
scp -r /Users/jorm/Documents/ecs160-hw3 user@VM_IP:~/
```

**Method 3: Shared folder (UTM/VirtualBox)**
- Configure shared folder in VM settings
- Mount it in Linux

## Running on Linux

### Step 1: Install Dependencies

```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Install build tools
sudo apt install -y build-essential git wget curl clang llvm

# Install additional dependencies
sudo apt install -y libpng-dev zlib1g-dev
```

### Step 2: Build Everything

```bash
cd ~/ecs160-hw3

# Build AFL++ and harnesses with FULL ASAN+UBSAN
./build_linux.sh

# Download seeds
./download_seeds.sh

# Build custom mutator
./build_custom_mutator.sh
```

### Step 3: Run All Experiments in Parallel (1 hour)

```bash
# This runs all 4 parts in parallel with FULL ASAN+UBSAN for Part C
./run_all_parallel_linux.sh
```

**This will create:**
- `build/output-b1-no-seeds/` - Part B.1 results
- `build/output-b2-with-seeds/` - Part B.2 results
- `build/output-c-sanitizers/` - Part C results (ASAN+UBSAN)
- `build/output-d-custom-mutator/` - Part D results

### Step 4: Extract Results

```bash
./extract_results.sh > results.txt
cat results.txt
```

### Step 5: Copy Results Back to Mac

**Method 1: SCP**
```bash
# On Linux VM
tar czf results.tar.gz build/output-* results.txt

# On Mac
scp user@VM_IP:~/ecs160-hw3/results.tar.gz .
tar xzf results.tar.gz
```

**Method 2: GitHub**
```bash
# On Linux VM
git add build/output-*/default/plot_data
git add results.txt
git commit -m "Fuzzing results"
git push

# On Mac
git pull
```

## Option 2: Remote Linux Server

If you have access to a Linux server (e.g., university cluster, AWS, DigitalOcean):

```bash
# SSH to server
ssh user@server.edu

# Transfer files
scp -r /Users/jorm/Documents/ecs160-hw3 user@server.edu:~/

# Run on server
cd ecs160-hw3
./build_linux.sh
./download_seeds.sh
./build_custom_mutator.sh
./run_all_parallel_linux.sh

# Copy results back
scp -r user@server.edu:~/ecs160-hw3/build/output-* .
```

## Expected Differences: Linux vs macOS

### Part C: ASAN Detection

On Linux with FULL ASAN, you should see:
- Potentially MORE crashes detected
- Crashes with detailed ASAN reports like:
  ```
  ==12345==ERROR: AddressSanitizer: heap-buffer-overflow
  READ of size 1 at 0x... thread T0
  ```

### Performance

Linux typically shows:
- **Higher exec/sec** (10-30% faster)
- **Better sanitizer performance** (ASAN overhead is lower on Linux)
- **More stable fuzzing** (no shared memory issues)

## Troubleshooting

### "shmget() failed" Error
```bash
# Increase shared memory limits
sudo sysctl -w kernel.shmmax=268435456
sudo sysctl -w kernel.shmall=268435456
```

### ASAN Out of Memory
```bash
# The script already sets this, but if needed:
sudo sysctl -w vm.mmap_rnd_bits=28
```

### Slow Performance
```bash
# Disable CPU frequency scaling
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

## What to Document in ANALYSIS.md

For Part C on Linux, use:

```markdown
## Part C: AFL++ with ASAN and UBSAN

**Configuration:**
- Fuzzer: AFL++
- Sanitizers: AddressSanitizer (ASAN) + UndefinedBehaviorSanitizer (UBSAN)
- Seeds: 10 PNG files
- Duration: 1 hour
- Platform: Ubuntu 22.04 LTS (Linux VM)

**Results:**
[Your actual results from Linux]

**ASAN-Specific Findings:**
[List any ASAN-detected crashes with descriptions]
```

## Quick Reference

**Linux-specific files:**
- `build_linux.sh` - Build script for Linux
- `run_all_parallel_linux.sh` - Run all experiments (Linux)
- `run_part_c_linux.sh` - Run Part C only (Linux)
- `harness-c-linux` - Binary with FULL ASAN+UBSAN

**Shared files (work on both):**
- `harness.c` - Test harness source
- `png_mutator.c` - Custom mutator
- `download_seeds.sh` - Download PNG seeds
- `build_custom_mutator.sh` - Build mutator
- `extract_results.sh` - Extract results

## Time Estimate

- VM setup: 30 minutes (if needed)
- File transfer: 5 minutes
- Build on Linux: 10 minutes
- Fuzzing (parallel): 1 hour
- Extract results: 5 minutes
- **Total: ~2 hours** (including VM setup)
