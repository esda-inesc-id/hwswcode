/**
 * @file tb_axil_conv2D.cpp
 * @date May, 2022
 *
 * Support file for lab1 of Hardware-Software Co-Design 2022
 *
 * Contains the HLS test bench for a simple matrix convolution IP.
 */

#include "axil_conv2D.h"

#define HW_IP

static unsigned char image_in[IMAGE_HEIGHT * IMAGE_WIDTH];
static signed char kernel[KERNEL_SIZE * KERNEL_SIZE] = {-2, -1, 0,
                                                        -1, 1, 1,
                                                        0, 1, 2};
static int bias = 5;

static unsigned char hw_image_out[OUTPUT_HEIGHT * OUTPUT_WIDTH];
static unsigned char sw_image_out[OUTPUT_HEIGHT * OUTPUT_WIDTH];

/**
 * Performs software-only matrix convolution.
 * @param matrix_in Input matrix
 * @param matrix_out Output matrix after convolution
 */
void sw_convolution_2D(const unsigned char *matrix_in, unsigned char *matrix_out) {
    for (int i = 0; i < OUTPUT_HEIGHT; i++)
        for (int j = 0; j < OUTPUT_WIDTH; j++) {
            int accum = bias;                       /* initialize result with bias */

            for (int k = 0; k < KERNEL_SIZE; k++)
                for (int x = 0; x < KERNEL_SIZE; x++) {
                    /* Kernel index */
                    int kernel_1d_idx =
                            k * KERNEL_SIZE +       /* kernel row */
                            x;                      /* kernel column */

                    /* Input matrix index */
                    int input_1d_idx =
                            (i + k) * IMAGE_WIDTH + /* input row */
                            j + x;                  /* input column */

                    accum += kernel[kernel_1d_idx] * matrix_in[input_1d_idx];
                }

            /* Normalize result */
            if (accum > 255)
                accum = 255;
            else if (accum < 0)
                accum = 0;

            matrix_out[i * OUTPUT_WIDTH + j] = accum;
        }
}

int main() {
    printf("Input Image\n\r");
    for (int i = 0; i < IMAGE_HEIGHT; i++) {
        for (int j = 0; j < IMAGE_WIDTH; j++) {
            image_in[i * IMAGE_WIDTH + j] = (i + 1) * 10 + (j + 1);
            printf("%d ", image_in[i * IMAGE_WIDTH + j]);
        }
        printf("\n\r");
    }

#ifdef HW_IP
    axil_conv2D((input_image_t *) image_in,
                (output_image_t *) hw_image_out,
                (weight_t *) kernel,
                (bias_t) bias);
#endif

    sw_convolution_2D(image_in, sw_image_out);

    printf("Output Image\n\r");
    for (int i = 0; i < OUTPUT_HEIGHT; i++) {
        for (int j = 0; j < OUTPUT_WIDTH; j++) {
            printf("%4d ", sw_image_out[i * OUTPUT_WIDTH + j]);
        }
        printf("\n\r");
    }

#ifdef HW_IP
    int err_cnt = 0;
    for (int i = 0; i < OUTPUT_HEIGHT; i++)
        for (int j = 0; j < OUTPUT_WIDTH; j++)
            if (hw_image_out[i * OUTPUT_WIDTH + j] != sw_image_out[i * OUTPUT_WIDTH + j]) {
                err_cnt++;
                printf("%d,%d: %d != %d\n\r",
                       i, j, hw_image_out[i * OUTPUT_WIDTH + j], sw_image_out[i * OUTPUT_WIDTH + j]);
            }

    return err_cnt;
#else
    return 0;
#endif
}
