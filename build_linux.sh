#!/bin/bash

# Linux-specific build script with full ASAN+UBSAN support
# Use this on Ubuntu/Debian/any Linux VM

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
AFLPLUSPLUS_DIR="${BUILD_DIR}/AFLplusplus"
LIBPNG_DIR="${BUILD_DIR}/libpng"
ZLIB_DIR="${BUILD_DIR}/zlib"

echo "===== ECS160 HW3: Linux Build with Full ASAN+UBSAN ====="

# Create build directory
mkdir -p "${BUILD_DIR}"

# ==================== Part 1: Clone and Build AFL++ ====================
echo ""
echo "Step 1: Cloning and building AFL++"
if [ ! -d "${AFLPLUSPLUS_DIR}" ]; then
    cd "${BUILD_DIR}"
    git clone https://github.com/AFLplusplus/AFLplusplus.git
    cd AFLplusplus
    git checkout stable
else
    echo "AFL++ directory already exists, using existing installation"
    cd "${AFLPLUSPLUS_DIR}"
fi

echo "Building AFL++..."
make clean || true
make -j$(nproc)
cd "${SCRIPT_DIR}"

# Set up AFL++ environment variables
export PATH="${AFLPLUSPLUS_DIR}:${PATH}"
export AFL_CC="${AFLPLUSPLUS_DIR}/afl-clang-fast"
export AFL_CXX="${AFLPLUSPLUS_DIR}/afl-clang-fast++"

# ==================== Part 2: Download and Build zlib (dependency) ====================
echo ""
echo "Step 2: Building zlib dependency"
if [ ! -d "${ZLIB_DIR}" ]; then
    cd "${BUILD_DIR}"
    if command -v wget &> /dev/null; then
        wget https://zlib.net/zlib-1.3.1.tar.gz
    else
        curl -L -O https://zlib.net/zlib-1.3.1.tar.gz
    fi
    tar xzf zlib-1.3.1.tar.gz
    mv zlib-1.3.1 zlib
    rm zlib-1.3.1.tar.gz
else
    echo "zlib directory already exists, using existing installation"
fi

# ==================== Part 3: Clone LibPNG ====================
echo ""
echo "Step 3: Cloning LibPNG"
if [ ! -d "${LIBPNG_DIR}" ]; then
    cd "${BUILD_DIR}"
    git clone https://github.com/pnggroup/libpng.git
    cd libpng
    git checkout v1.6.43
else
    echo "LibPNG directory already exists, using existing installation"
    cd "${LIBPNG_DIR}"
fi

# ==================== Part 4: Build Configuration B (AFL++ only) ====================
echo ""
echo "Step 4: Building Part B - AFL++ without sanitizers"

# Build zlib for Part B
cd "${ZLIB_DIR}"
make distclean 2>/dev/null || make clean 2>/dev/null || rm -f Makefile || true
./configure --prefix="${BUILD_DIR}/zlib-b" --static
make -j$(nproc)
make install

# Build LibPNG for Part B
cd "${LIBPNG_DIR}"
make distclean 2>/dev/null || make clean 2>/dev/null || rm -f Makefile || true
./configure \
    CFLAGS="-O3" \
    --prefix="${BUILD_DIR}/libpng-b" \
    --with-zlib-prefix="${BUILD_DIR}/zlib-b"
make -j$(nproc)
make install

# Build harness for Part B
echo "Building harness for Part B..."
"${AFLPLUSPLUS_DIR}/afl-clang-fast" -O3 \
    -I"${BUILD_DIR}/libpng-b/include" \
    -L"${BUILD_DIR}/libpng-b/lib" \
    -L"${BUILD_DIR}/zlib-b/lib" \
    "${SCRIPT_DIR}/harness.c" \
    -lpng -lz \
    -o "${BUILD_DIR}/harness-b"

echo "Part B binary created: ${BUILD_DIR}/harness-b"

# ==================== Part 5: Build Configuration C (AFL++ with ASAN/UBSAN) ====================
echo ""
echo "Step 5: Building Part C - AFL++ with FULL ASAN and UBSAN (Linux)"

# Build zlib for Part C with sanitizers
cd "${ZLIB_DIR}"
make distclean 2>/dev/null || make clean 2>/dev/null || rm -f Makefile || true
CC=clang CFLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer -g" \
./configure --prefix="${BUILD_DIR}/zlib-c" --static
make -j$(nproc)
make install

# Build LibPNG for Part C with sanitizers
cd "${LIBPNG_DIR}"
make distclean 2>/dev/null || make clean 2>/dev/null || rm -f Makefile || true
./configure \
    CC=clang \
    CFLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer -g -O1" \
    LDFLAGS="-fsanitize=address,undefined" \
    --prefix="${BUILD_DIR}/libpng-c" \
    --with-zlib-prefix="${BUILD_DIR}/zlib-c"
make -j$(nproc)
make install

# Build harness for Part C with FULL ASAN+UBSAN
echo "Building harness for Part C with ASAN+UBSAN..."
export AFL_USE_ASAN=1
export AFL_USE_UBSAN=1
"${AFLPLUSPLUS_DIR}/afl-clang-fast" \
    -fsanitize=address,undefined \
    -fno-omit-frame-pointer \
    -g -O1 \
    -I"${BUILD_DIR}/libpng-c/include" \
    -L"${BUILD_DIR}/libpng-c/lib" \
    -L"${BUILD_DIR}/zlib-c/lib" \
    "${SCRIPT_DIR}/harness.c" \
    -lpng -lz \
    -o "${BUILD_DIR}/harness-c-linux"
unset AFL_USE_ASAN
unset AFL_USE_UBSAN

echo "Part C binary created: ${BUILD_DIR}/harness-c-linux (with ASAN+UBSAN)"

# Test the binary
echo ""
echo "Testing harness-c-linux..."
if "${BUILD_DIR}/harness-c-linux" "${BUILD_DIR}/seeds/basn0g01.png" /tmp/test-asan.png 2>&1 | grep -q "ERROR:"; then
    echo "⚠️  ASAN detected an error (this is expected if testing)"
else
    echo "✓ Harness runs successfully with ASAN+UBSAN"
fi

# ==================== Part 6: Create seed directory ====================
echo ""
echo "Step 6: Creating seed directory"
mkdir -p "${BUILD_DIR}/seeds"
mkdir -p "${BUILD_DIR}/empty-seeds"

echo ""
echo "===== Build Complete ====="
echo ""
echo "Binaries created:"
echo "  Part B (AFL++ only):           ${BUILD_DIR}/harness-b"
echo "  Part C (AFL++ + ASAN/UBSAN):   ${BUILD_DIR}/harness-c-linux"
echo ""
echo "Next steps:"
echo "1. Download seeds: ./download_seeds.sh"
echo "2. Build custom mutator: ./build_custom_mutator.sh"
echo "3. Run fuzzing: ./run_all_parallel_linux.sh"
echo ""
