#!/bin/bash

# Simplified Linux build - uses regular clang with ASAN for the libraries
# and only AFL instrumentation for the harness

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
AFLPLUSPLUS_DIR="${BUILD_DIR}/AFLplusplus"

echo "===== Simplified Linux Build ====="

mkdir -p "${BUILD_DIR}"

# ==================== Build AFL++ ====================
echo "Building AFL++..."
if [ ! -d "${AFLPLUSPLUS_DIR}" ]; then
    cd "${BUILD_DIR}"
    git clone https://github.com/AFLplusplus/AFLplusplus.git
    cd AFLplusplus
    git checkout stable
else
    cd "${AFLPLUSPLUS_DIR}"
fi

make -j$(nproc)
cd "${SCRIPT_DIR}"

export PATH="${AFLPLUSPLUS_DIR}:${PATH}"

# ==================== Download zlib ====================
echo "Downloading zlib..."
cd "${BUILD_DIR}"
if [ ! -d "zlib" ]; then
    if command -v wget &> /dev/null; then
        wget https://zlib.net/zlib-1.3.1.tar.gz
    else
        curl -L -O https://zlib.net/zlib-1.3.1.tar.gz
    fi
    tar xzf zlib-1.3.1.tar.gz
    mv zlib-1.3.1 zlib
    rm zlib-1.3.1.tar.gz
fi

# Build zlib (no instrumentation, no sanitizers - static library)
cd zlib
make distclean 2>/dev/null || true
./configure --prefix="${BUILD_DIR}/zlib-install" --static
make -j$(nproc)
make install

# ==================== Clone LibPNG ====================
echo "Cloning LibPNG..."
cd "${BUILD_DIR}"
if [ ! -d "libpng" ]; then
    git clone https://github.com/pnggroup/libpng.git
    cd libpng
    git checkout v1.6.43
fi

# Build libpng (no instrumentation, no sanitizers - static library)
cd "${BUILD_DIR}/libpng"
make distclean 2>/dev/null || true
./configure \
    CFLAGS="-O2" \
    --prefix="${BUILD_DIR}/libpng-install" \
    --with-zlib-prefix="${BUILD_DIR}/zlib-install"
make -j$(nproc)
make install

# ==================== Build Part B harness (AFL only) ====================
echo "Building Part B harness (AFL instrumentation only)..."
"${AFLPLUSPLUS_DIR}/afl-clang-fast" \
    -O3 \
    -I"${BUILD_DIR}/libpng-install/include" \
    -L"${BUILD_DIR}/libpng-install/lib" \
    -L"${BUILD_DIR}/zlib-install/lib" \
    "${SCRIPT_DIR}/harness.c" \
    -lpng -lz \
    -o "${BUILD_DIR}/harness-b"

echo "✓ Part B harness created: ${BUILD_DIR}/harness-b"

# ==================== Build Part C harness (AFL + ASAN) ====================
echo "Building Part C harness (AFL + ASAN + UBSAN)..."

# Detect available compiler (prefer clang, fallback to gcc)
if command -v clang &> /dev/null; then
    CC_ASAN=clang
    echo "Using clang for ASAN build"
elif command -v gcc &> /dev/null; then
    CC_ASAN=gcc
    echo "Using gcc for ASAN build"
else
    echo "ERROR: No C compiler found"
    exit 1
fi

# Compile with sanitizers
$CC_ASAN \
    -fsanitize=address,undefined \
    -fno-omit-frame-pointer \
    -fno-sanitize-recover=all \
    -g -O1 \
    -I"${BUILD_DIR}/libpng-install/include" \
    -L"${BUILD_DIR}/libpng-install/lib" \
    -L"${BUILD_DIR}/zlib-install/lib" \
    -c "${SCRIPT_DIR}/harness.c" \
    -o "${BUILD_DIR}/harness-asan.o"

# Link with AFL runtime - use afl-clang-fast if available, otherwise afl-gcc
AFL_LINKER="${AFLPLUSPLUS_DIR}/afl-clang-fast"
if [ ! -f "$AFL_LINKER" ]; then
    AFL_LINKER="${AFLPLUSPLUS_DIR}/afl-gcc"
fi

"$AFL_LINKER" \
    -fsanitize=address,undefined \
    -fno-omit-frame-pointer \
    -g -O1 \
    "${BUILD_DIR}/harness-asan.o" \
    -L"${BUILD_DIR}/libpng-install/lib" \
    -L"${BUILD_DIR}/zlib-install/lib" \
    -lpng -lz \
    -o "${BUILD_DIR}/harness-c-linux"

rm "${BUILD_DIR}/harness-asan.o"

echo "✓ Part C harness created: ${BUILD_DIR}/harness-c-linux"

# Test the harnesses
echo ""
echo "Testing harnesses..."

if [ ! -d "${BUILD_DIR}/seeds" ] || [ -z "$(ls -A ${BUILD_DIR}/seeds)" ]; then
    echo "⚠️  No seeds found. Run ./download_seeds.sh first"
else
    "${BUILD_DIR}/harness-b" "${BUILD_DIR}/seeds/basn0g01.png" /tmp/test-b.png && \
        echo "✓ Part B harness works"

    "${BUILD_DIR}/harness-c-linux" "${BUILD_DIR}/seeds/basn0g01.png" /tmp/test-c.png 2>&1 | \
        grep -q "ERROR:" || echo "✓ Part C harness works"
fi

echo ""
echo "===== Build Complete ====="
echo ""
echo "Binaries:"
echo "  ${BUILD_DIR}/harness-b (AFL only)"
echo "  ${BUILD_DIR}/harness-c-linux (AFL + ASAN + UBSAN)"
echo ""
echo "Next steps:"
echo "  1. ./download_seeds.sh"
echo "  2. ./build_custom_mutator.sh"
echo "  3. ./run_all_parallel_linux.sh"
