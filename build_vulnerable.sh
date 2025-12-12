#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
ZLIB_DIR="${BUILD_DIR}/zlib-1.3.1"
LIBPNG_VULN_DIR="${BUILD_DIR}/libpng-1.6.15"

echo "===== Building VULNERABLE LibPNG 1.6.15 for Better Fuzzing Results ====="
echo ""
echo "LibPNG 1.6.15 (2014) has known vulnerabilities including:"
echo "  - CVE-2015-8472: Buffer overflow in png_set_PLTE"
echo "  - CVE-2015-8540: Underflow and overflow in png_check_keyword"
echo "  - And others that should be findable with fuzzing"
echo ""

# Download vulnerable LibPNG 1.6.15
cd "${BUILD_DIR}"
if [ ! -d "${LIBPNG_VULN_DIR}" ]; then
    echo "Downloading LibPNG 1.6.15 (vulnerable version)..."
    curl -L -O https://sourceforge.net/projects/libpng/files/libpng16/older-releases/1.6.15/libpng-1.6.15.tar.gz/download
    mv download libpng-1.6.15.tar.gz
    tar xzf libpng-1.6.15.tar.gz
fi

# Build vulnerable version for Part B
echo ""
echo "Building vulnerable LibPNG for Part B..."

# Download and build zlib if needed
if [ ! -d "${ZLIB_DIR}" ]; then
    echo "Downloading zlib..."
    cd "${BUILD_DIR}"
    # Try GitHub mirror if zlib.net is down
    curl -L -O https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz || \
    curl -L -O https://zlib.net/zlib-1.3.1.tar.gz
    tar xzf zlib-1.3.1.tar.gz
fi

cd "${ZLIB_DIR}"
make distclean 2>/dev/null || make clean 2>/dev/null || rm -f Makefile || true
./configure --prefix="${BUILD_DIR}/zlib-vuln-b" --static
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
make install

cd "${LIBPNG_VULN_DIR}"
make distclean 2>/dev/null || make clean 2>/dev/null || rm -f Makefile || true
./configure \
    CFLAGS="-O3" \
    --prefix="${BUILD_DIR}/libpng-vuln-b" \
    --with-zlib-prefix="${BUILD_DIR}/zlib-vuln-b"
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
make install

# Build harness for vulnerable version
echo "Building harness with vulnerable LibPNG..."
clang -O3 \
    -I"${BUILD_DIR}/libpng-vuln-b/include" \
    -L"${BUILD_DIR}/libpng-vuln-b/lib" \
    -L"${BUILD_DIR}/zlib-vuln-b/lib" \
    "${SCRIPT_DIR}/harness.c" \
    -lpng -lz \
    -o "${BUILD_DIR}/harness-vuln-b"

# Build vulnerable version for Part C (with sanitizers)
echo ""
echo "Building vulnerable LibPNG for Part C (with sanitizers)..."
cd "${ZLIB_DIR}"
make distclean 2>/dev/null || make clean 2>/dev/null || rm -f Makefile || true
CFLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer -g" \
./configure --prefix="${BUILD_DIR}/zlib-vuln-c" --static
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
make install

cd "${LIBPNG_VULN_DIR}"
make distclean 2>/dev/null || make clean 2>/dev/null || rm -f Makefile || true
./configure \
    CFLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer -g -O1" \
    LDFLAGS="-fsanitize=address,undefined" \
    --prefix="${BUILD_DIR}/libpng-vuln-c" \
    --with-zlib-prefix="${BUILD_DIR}/zlib-vuln-c"
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
make install

echo "Building harness with sanitizers and vulnerable LibPNG..."
clang \
    -fsanitize=address,undefined \
    -fno-omit-frame-pointer \
    -g -O1 \
    -I"${BUILD_DIR}/libpng-vuln-c/include" \
    -L"${BUILD_DIR}/libpng-vuln-c/lib" \
    -L"${BUILD_DIR}/zlib-vuln-c/lib" \
    "${SCRIPT_DIR}/harness.c" \
    -lpng -lz \
    -o "${BUILD_DIR}/harness-vuln-c"

echo ""
echo "===== Build Complete ====="
echo ""
echo "Vulnerable binaries created:"
echo "  ${BUILD_DIR}/harness-vuln-b (for Parts B.1 and B.2)"
echo "  ${BUILD_DIR}/harness-vuln-c (for Part C with ASAN/UBSAN)"
echo ""
echo "Now run fuzzing with these vulnerable binaries!"
echo "Edit run_timed_fuzzing.sh to use harness-vuln-b and harness-vuln-c instead"
