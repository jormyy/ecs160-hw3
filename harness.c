#include <png.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input.png> [output.png]\n", argv[0]);
        return 0;
    }

    const char *input_file = argv[1];
    const char *output_file = (argc >= 3) ? argv[2] : NULL;

    FILE *fp = fopen(input_file, "rb");
    if (!fp) {
        return 0;
    }

    /* Verify PNG signature */
    unsigned char header[8];
    if (fread(header, 1, 8, fp) != 8) {
        fclose(fp);
        return 0;
    }
    if (png_sig_cmp(header, 0, 8)) {
        fclose(fp);
        return 0;
    }

    /* Create read struct */
    png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (!png) {
        fclose(fp);
        return 0;
    }

    /* Create info struct */
    png_infop info = png_create_info_struct(png);
    if (!info) {
        png_destroy_read_struct(&png, NULL, NULL);
        fclose(fp);
        return 0;
    }

    /* Set up error handling */
    if (setjmp(png_jmpbuf(png))) {
        png_destroy_read_struct(&png, &info, NULL);
        fclose(fp);
        return 0;
    }

    /* Initialize I/O */
    png_init_io(png, fp);
    png_set_sig_bytes(png, 8);

    /* Read PNG info */
    png_read_info(png, info);

    /* Get image attributes */
    int width = png_get_image_width(png, info);
    int height = png_get_image_height(png, info);
    png_byte color_type = png_get_color_type(png, info);
    png_byte bit_depth = png_get_bit_depth(png, info);
    int channels = png_get_channels(png, info);

    /* Apply various transformations to exercise the API */

    /* Expand paletted colors into true RGB triplets */
    if (color_type == PNG_COLOR_TYPE_PALETTE)
        png_set_palette_to_rgb(png);

    /* Expand grayscale images to 8 bits from 1, 2, or 4 bits per pixel */
    if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8)
        png_set_expand_gray_1_2_4_to_8(png);

    /* Expand paletted or RGB images with transparency to full alpha */
    if (png_get_valid(png, info, PNG_INFO_tRNS))
        png_set_tRNS_to_alpha(png);

    /* Convert grayscale to RGB */
    if (color_type == PNG_COLOR_TYPE_GRAY ||
        color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
        png_set_gray_to_rgb(png);

    /* Add filler (alpha) byte to RGB */
    if (color_type == PNG_COLOR_TYPE_RGB ||
        color_type == PNG_COLOR_TYPE_GRAY)
        png_set_filler(png, 0xFF, PNG_FILLER_AFTER);

    /* Scale 16-bit depth down to 8-bit */
    if (bit_depth == 16)
        png_set_scale_16(png);

    /* Update info structure after transformations */
    png_read_update_info(png, info);

    /* Get updated values */
    int rowbytes = png_get_rowbytes(png, info);
    channels = png_get_channels(png, info);

    /* Allocate memory for image data */
    png_bytep *row_pointers = (png_bytep *)malloc(sizeof(png_bytep) * height);
    if (!row_pointers) {
        png_destroy_read_struct(&png, &info, NULL);
        fclose(fp);
        return 0;
    }

    for (int y = 0; y < height; y++) {
        row_pointers[y] = (png_byte *)malloc(rowbytes);
        if (!row_pointers[y]) {
            for (int i = 0; i < y; i++)
                free(row_pointers[i]);
            free(row_pointers);
            png_destroy_read_struct(&png, &info, NULL);
            fclose(fp);
            return 0;
        }
    }

    /* Read the image data */
    png_read_image(png, row_pointers);

    /* Read end info */
    png_read_end(png, info);

    /* Close input file */
    fclose(fp);

    /* Optionally write output file to exercise write API */
    if (output_file) {
        FILE *out = fopen(output_file, "wb");
        if (out) {
            png_structp wpng = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
            png_infop winfo = png_create_info_struct(wpng);

            if (wpng && winfo) {
                if (setjmp(png_jmpbuf(wpng))) {
                    png_destroy_write_struct(&wpng, &winfo);
                    fclose(out);
                } else {
                    png_init_io(wpng, out);

                    /* Write header with RGBA format */
                    png_set_IHDR(wpng, winfo,
                                 width, height, 8,
                                 PNG_COLOR_TYPE_RGBA,
                                 PNG_INTERLACE_NONE,
                                 PNG_COMPRESSION_TYPE_BASE,
                                 PNG_FILTER_TYPE_BASE);

                    png_write_info(wpng, winfo);
                    png_write_image(wpng, row_pointers);
                    png_write_end(wpng, winfo);

                    png_destroy_write_struct(&wpng, &winfo);
                    fclose(out);
                }
            } else {
                if (wpng) png_destroy_write_struct(&wpng, &winfo);
                fclose(out);
            }
        }
    }

    /* Cleanup */
    for (int y = 0; y < height; y++)
        free(row_pointers[y]);
    free(row_pointers);

    png_destroy_read_struct(&png, &info, NULL);

    return 0;
}
