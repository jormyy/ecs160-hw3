#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEEDS_DIR="${SCRIPT_DIR}/build/seeds"
mkdir -p "${SEEDS_DIR}"

echo "Downloading sample PNG files for fuzzing seeds..."

# Download various PNG test files from libpng's test suite
curl -L -o "${SEEDS_DIR}/basn0g01.png" "http://www.schaik.com/pngsuite/basn0g01.png"
curl -L -o "${SEEDS_DIR}/basn0g02.png" "http://www.schaik.com/pngsuite/basn0g02.png"
curl -L -o "${SEEDS_DIR}/basn0g04.png" "http://www.schaik.com/pngsuite/basn0g04.png"
curl -L -o "${SEEDS_DIR}/basn0g08.png" "http://www.schaik.com/pngsuite/basn0g08.png"
curl -L -o "${SEEDS_DIR}/basn2c08.png" "http://www.schaik.com/pngsuite/basn2c08.png"
curl -L -o "${SEEDS_DIR}/basn3p02.png" "http://www.schaik.com/pngsuite/basn3p02.png"
curl -L -o "${SEEDS_DIR}/basn3p04.png" "http://www.schaik.com/pngsuite/basn3p04.png"
curl -L -o "${SEEDS_DIR}/basn4a08.png" "http://www.schaik.com/pngsuite/basn4a08.png"
curl -L -o "${SEEDS_DIR}/basn6a08.png" "http://www.schaik.com/pngsuite/basn6a08.png"
curl -L -o "${SEEDS_DIR}/basn6a16.png" "http://www.schaik.com/pngsuite/basn6a16.png"

echo ""
echo "Downloaded PNG seed files:"
ls -lh "${SEEDS_DIR}"
echo ""
echo "Seed files are ready in ${SEEDS_DIR}"
