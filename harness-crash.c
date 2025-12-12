#include <png.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// AGGRESSIVE harness - removes most error handling to expose crashes
int main(int argc, char **argv) {
    if (argc < 2) {
        return 0;
    }

    const char *input_file = argv[1];

    FILE *fp = fopen(input_file, "rb");
    if (!fp) {
        return 0;
    }

    // Verify PNG signature to avoid crashing on completely invalid files
    unsigned char header[8];
    if (fread(header, 1, 8, fp) != 8) {
        fclose(fp);
        return 0;
    }

    if (png_sig_cmp(header, 0, 8)) {
        fclose(fp);
        return 0;
    }

    // Create read struct
    png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (!png) {
        fclose(fp);
        return 0;
    }

    png_infop info = png_create_info_struct(png);
    if (!info) {
        png_destroy_read_struct(&png, NULL, NULL);
        fclose(fp);
        return 0;
    }

    // REDUCED error handling - catch libpng errors but let memory bugs crash
    // This is more aggressive than the safe harness but doesn't crash on every invalid PNG
    if (setjmp(png_jmpbuf(png))) {
        png_destroy_read_struct(&png, &info, NULL);
        fclose(fp);
        return 0;
    }

    png_init_io(png, fp);
    png_set_sig_bytes(png, 8);

    // Read PNG info
    png_read_info(png, info);

    int width = png_get_image_width(png, info);
    int height = png_get_image_height(png, info);
    png_byte color_type = png_get_color_type(png, info);
    png_byte bit_depth = png_get_bit_depth(png, info);

    // Apply transformations to exercise more code paths
    if (color_type == PNG_COLOR_TYPE_PALETTE)
        png_set_palette_to_rgb(png);

    if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8)
        png_set_expand_gray_1_2_4_to_8(png);

    if (png_get_valid(png, info, PNG_INFO_tRNS))
        png_set_tRNS_to_alpha(png);

    if (color_type == PNG_COLOR_TYPE_GRAY ||
        color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
        png_set_gray_to_rgb(png);

    if (color_type == PNG_COLOR_TYPE_RGB ||
        color_type == PNG_COLOR_TYPE_GRAY)
        png_set_filler(png, 0xFF, PNG_FILLER_AFTER);

    if (bit_depth == 16)
        png_set_scale_16(png);

    png_read_update_info(png, info);

    int rowbytes = png_get_rowbytes(png, info);

    // Allocate without bounds checking - will crash on extreme values
    png_bytep *row_pointers = (png_bytep *)malloc(sizeof(png_bytep) * height);

    for (int y = 0; y < height; y++) {
        row_pointers[y] = (png_byte *)malloc(rowbytes);
    }

    // Read image - crashes on malformed data
    png_read_image(png, row_pointers);
    png_read_end(png, info);

    // Cleanup
    for (int y = 0; y < height; y++)
        free(row_pointers[y]);
    free(row_pointers);

    png_destroy_read_struct(&png, &info, NULL);
    fclose(fp);

    return 0;
}
