#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
AFLPLUSPLUS_DIR="${BUILD_DIR}/AFLplusplus"
LIBPNG_DIR="${BUILD_DIR}/libpng"
ZLIB_DIR="${BUILD_DIR}/zlib"

echo "===== ECS160 HW3: LibPNG Fuzzing Setup ====="

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
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
cd "${SCRIPT_DIR}"

# Set up AFL++ environment variables
export PATH="${AFLPLUSPLUS_DIR}:${PATH}"
export AFL_CC="${AFLPLUSPLUS_DIR}/afl-cc"
export AFL_CXX="${AFLPLUSPLUS_DIR}/afl-c++"

# ==================== Part 2: Download and Build zlib (dependency) ====================
echo ""
echo "Step 2: Building zlib dependency"
if [ ! -d "${ZLIB_DIR}" ]; then
    cd "${BUILD_DIR}"
    wget https://zlib.net/zlib-1.3.1.tar.gz
    tar xzf zlib-1.3.1.tar.gz
    mv zlib-1.3.1 zlib
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
    # Use a stable version
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
make clean || true
CC="${AFL_CC}" ./configure --prefix="${BUILD_DIR}/zlib-b"
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
make install

# Build LibPNG for Part B
cd "${LIBPNG_DIR}"
make clean || true
./configure \
    CC="${AFL_CC}" \
    CFLAGS="-O3" \
    --prefix="${BUILD_DIR}/libpng-b" \
    --with-zlib-prefix="${BUILD_DIR}/zlib-b"
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
make install

# Build harness for Part B
echo "Building harness for Part B..."
"${AFL_CC}" -O3 \
    -I"${BUILD_DIR}/libpng-b/include" \
    -L"${BUILD_DIR}/libpng-b/lib" \
    -L"${BUILD_DIR}/zlib-b/lib" \
    "${SCRIPT_DIR}/harness.c" \
    -lpng -lz \
    -o "${BUILD_DIR}/harness-b"

echo "Part B binary created: ${BUILD_DIR}/harness-b"

# ==================== Part 5: Build Configuration C (AFL++ with ASAN/UBSAN) ====================
echo ""
echo "Step 5: Building Part C - AFL++ with ASAN and UBSAN"

# Build zlib for Part C
cd "${ZLIB_DIR}"
make clean || true
CC="${AFL_CC}" \
CFLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer -g" \
./configure --prefix="${BUILD_DIR}/zlib-c"
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
make install

# Build LibPNG for Part C
cd "${LIBPNG_DIR}"
make clean || true
./configure \
    CC="${AFL_CC}" \
    CFLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer -g -O1" \
    LDFLAGS="-fsanitize=address,undefined" \
    --prefix="${BUILD_DIR}/libpng-c" \
    --with-zlib-prefix="${BUILD_DIR}/zlib-c"
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
make install

# Build harness for Part C
echo "Building harness for Part C..."
"${AFL_CC}" \
    -fsanitize=address,undefined \
    -fno-omit-frame-pointer \
    -g -O1 \
    -I"${BUILD_DIR}/libpng-c/include" \
    -L"${BUILD_DIR}/libpng-c/lib" \
    -L"${BUILD_DIR}/zlib-c/lib" \
    "${SCRIPT_DIR}/harness.c" \
    -lpng -lz \
    -o "${BUILD_DIR}/harness-c"

echo "Part C binary created: ${BUILD_DIR}/harness-c"

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
echo "  Part C (AFL++ + ASAN/UBSAN):   ${BUILD_DIR}/harness-c"
echo ""
echo "Directories:"
echo "  AFL++:        ${AFLPLUSPLUS_DIR}"
echo "  LibPNG:       ${LIBPNG_DIR}"
echo "  Seeds:        ${BUILD_DIR}/seeds (place your 10 PNG files here)"
echo "  Empty seeds:  ${BUILD_DIR}/empty-seeds (for no-seed fuzzing)"
echo ""
echo "Next steps:"
echo "1. Download 10 PNG files and place them in ${BUILD_DIR}/seeds/"
echo "2. Run fuzzing commands (see run_fuzzing.sh)"
echo ""
