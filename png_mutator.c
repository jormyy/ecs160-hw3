/*
 * Custom PNG Mutator for AFL++
 *
 * This mutator implements PNG-aware mutations that respect the file format structure
 * while introducing meaningful variations to find bugs in LibPNG.
 *
 * Mutation strategies:
 * 1. Chunk manipulation: Modify, duplicate, reorder, or corrupt PNG chunks
 * 2. CRC corruption: Intentionally corrupt CRC values to test error handling
 * 3. Length field mutations: Modify chunk length fields
 * 4. Critical chunk mutations: Focus on IHDR, PLTE, IDAT chunks
 * 5. Compression mutations: Modify compressed IDAT data
 */

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* PNG Signature */
static const uint8_t PNG_SIGNATURE[8] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};

/* Chunk types */
#define CHUNK_IHDR 0x49484452
#define CHUNK_PLTE 0x504C5445
#define CHUNK_IDAT 0x49444154
#define CHUNK_IEND 0x49454E44

typedef struct {
    uint32_t length;
    uint32_t type;
    uint8_t *data;
    uint32_t crc;
} png_chunk_t;

/* AFL++ custom mutator interface */
typedef struct {
    uint8_t *mutated_data;
    size_t mutated_size;
} afl_state_t;

/**
 * Read a 32-bit big-endian integer
 */
static uint32_t read_be32(const uint8_t *data) {
    return ((uint32_t)data[0] << 24) |
           ((uint32_t)data[1] << 16) |
           ((uint32_t)data[2] << 8) |
           ((uint32_t)data[3]);
}

/**
 * Write a 32-bit big-endian integer
 */
static void write_be32(uint8_t *data, uint32_t value) {
    data[0] = (value >> 24) & 0xFF;
    data[1] = (value >> 16) & 0xFF;
    data[2] = (value >> 8) & 0xFF;
    data[3] = value & 0xFF;
}

/**
 * Check if data starts with PNG signature
 */
static int is_png(const uint8_t *data, size_t size) {
    if (size < 8) return 0;
    return memcmp(data, PNG_SIGNATURE, 8) == 0;
}

/**
 * Initialize custom mutator
 */
void *afl_custom_init(void *afl, unsigned int seed) {
    srand(seed);
    afl_state_t *state = (afl_state_t *)calloc(1, sizeof(afl_state_t));
    return state;
}

/**
 * Perform custom mutation
 */
size_t afl_custom_fuzz(void *data, uint8_t *buf, size_t buf_size,
                       uint8_t **out_buf, uint8_t *add_buf,
                       size_t add_buf_size, size_t max_size) {

    afl_state_t *state = (afl_state_t *)data;

    /* If not a valid PNG, use default mutations */
    if (!is_png(buf, buf_size)) {
        *out_buf = buf;
        return buf_size;
    }

    /* Allocate buffer for mutated data */
    size_t new_size = buf_size + 4096; /* Extra space for mutations */
    if (new_size > max_size) new_size = max_size;

    if (state->mutated_data) free(state->mutated_data);
    state->mutated_data = (uint8_t *)malloc(new_size);
    if (!state->mutated_data) {
        *out_buf = buf;
        return buf_size;
    }

    /* Copy original data */
    memcpy(state->mutated_data, buf, buf_size);
    size_t out_size = buf_size;

    /* Choose mutation strategy */
    int strategy = rand() % 10;

    if (buf_size < 20) {
        *out_buf = state->mutated_data;
        return out_size;
    }

    switch (strategy) {
        case 0:
        case 1: {
            /* Corrupt CRC of a random chunk */
            size_t offset = 8; /* Skip PNG signature */
            int chunk_count = 0;

            /* Count chunks */
            while (offset + 12 <= buf_size) {
                uint32_t length = read_be32(state->mutated_data + offset);
                if (offset + 12 + length > buf_size) break;
                chunk_count++;
                offset += 12 + length;
            }

            if (chunk_count > 0) {
                int target_chunk = rand() % chunk_count;
                offset = 8;

                /* Find target chunk */
                for (int i = 0; i < target_chunk; i++) {
                    uint32_t length = read_be32(state->mutated_data + offset);
                    offset += 12 + length;
                }

                uint32_t length = read_be32(state->mutated_data + offset);
                if (offset + 12 + length <= buf_size) {
                    /* Corrupt CRC */
                    uint32_t crc = read_be32(state->mutated_data + offset + 8 + length);
                    crc ^= (1 << (rand() % 32));
                    write_be32(state->mutated_data + offset + 8 + length, crc);
                }
            }
            break;
        }

        case 2:
        case 3: {
            /* Modify chunk length field */
            size_t offset = 8 + (rand() % (buf_size - 8));
            if (offset + 4 <= buf_size) {
                uint32_t length = read_be32(state->mutated_data + offset);

                /* Try different length mutations */
                int mutation = rand() % 4;
                switch (mutation) {
                    case 0: length += rand() % 256; break;
                    case 1: length -= rand() % 256; break;
                    case 2: length = 0xFFFFFFFF; break;
                    case 3: length = 0; break;
                }

                write_be32(state->mutated_data + offset, length);
            }
            break;
        }

        case 4: {
            /* Flip bits in IHDR chunk (critical header) */
            size_t offset = 8; /* First chunk after signature */
            if (offset + 12 <= buf_size) {
                uint32_t length = read_be32(state->mutated_data + offset);
                uint32_t type = read_be32(state->mutated_data + offset + 4);

                if (type == CHUNK_IHDR && offset + 12 + length <= buf_size) {
                    /* Flip random bits in IHDR data */
                    int byte_offset = rand() % length;
                    int bit_offset = rand() % 8;
                    state->mutated_data[offset + 8 + byte_offset] ^= (1 << bit_offset);
                }
            }
            break;
        }

        case 5: {
            /* Duplicate a chunk */
            size_t offset = 8;
            int chunk_count = 0;

            while (offset + 12 <= buf_size) {
                uint32_t length = read_be32(state->mutated_data + offset);
                if (offset + 12 + length > buf_size) break;
                chunk_count++;
                offset += 12 + length;
            }

            if (chunk_count > 0) {
                int target_chunk = rand() % chunk_count;
                offset = 8;

                for (int i = 0; i < target_chunk; i++) {
                    uint32_t length = read_be32(state->mutated_data + offset);
                    offset += 12 + length;
                }

                uint32_t length = read_be32(state->mutated_data + offset);
                size_t chunk_size = 12 + length;

                if (out_size + chunk_size <= new_size) {
                    /* Insert duplicate after current chunk */
                    memmove(state->mutated_data + offset + chunk_size * 2,
                           state->mutated_data + offset + chunk_size,
                           out_size - offset - chunk_size);
                    memcpy(state->mutated_data + offset + chunk_size,
                          state->mutated_data + offset,
                          chunk_size);
                    out_size += chunk_size;
                }
            }
            break;
        }

        case 6: {
            /* Modify chunk type */
            size_t offset = 8 + (rand() % (buf_size - 20));
            if (offset + 8 <= buf_size) {
                /* Change one byte of chunk type */
                state->mutated_data[offset + 4 + (rand() % 4)] = rand() % 256;
            }
            break;
        }

        case 7: {
            /* Corrupt IDAT (compressed image data) */
            size_t offset = 8;

            while (offset + 12 <= buf_size) {
                uint32_t length = read_be32(state->mutated_data + offset);
                uint32_t type = read_be32(state->mutated_data + offset + 4);

                if (type == CHUNK_IDAT && offset + 12 + length <= buf_size) {
                    /* Flip random byte in compressed data */
                    if (length > 0) {
                        int byte_offset = rand() % length;
                        state->mutated_data[offset + 8 + byte_offset] = rand() % 256;
                    }
                    break;
                }

                if (offset + 12 + length > buf_size) break;
                offset += 12 + length;
            }
            break;
        }

        case 8: {
            /* Remove a chunk (except IHDR and IEND) */
            size_t offset = 8;

            while (offset + 12 <= buf_size) {
                uint32_t length = read_be32(state->mutated_data + offset);
                uint32_t type = read_be32(state->mutated_data + offset + 4);

                if (type != CHUNK_IHDR && type != CHUNK_IEND &&
                    offset + 12 + length <= buf_size) {
                    size_t chunk_size = 12 + length;
                    memmove(state->mutated_data + offset,
                           state->mutated_data + offset + chunk_size,
                           out_size - offset - chunk_size);
                    out_size -= chunk_size;
                    break;
                }

                if (offset + 12 + length > buf_size) break;
                offset += 12 + length;
            }
            break;
        }

        default: {
            /* Random byte flip */
            if (buf_size > 8) {
                size_t pos = 8 + (rand() % (buf_size - 8));
                state->mutated_data[pos] = rand() % 256;
            }
            break;
        }
    }

    *out_buf = state->mutated_data;
    state->mutated_size = out_size;
    return out_size;
}

/**
 * Cleanup
 */
void afl_custom_deinit(void *data) {
    afl_state_t *state = (afl_state_t *)data;
    if (state) {
        if (state->mutated_data) free(state->mutated_data);
        free(state);
    }
}
