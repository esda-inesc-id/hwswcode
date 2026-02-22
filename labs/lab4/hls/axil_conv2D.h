#ifndef __AXIL_CONV2D_H__
#define __AXIL_CONV2D_H__

#include <ap_int.h>

#define IMAGE_HEIGHT 6
#define IMAGE_WIDTH  IMAGE_HEIGHT
#define KERNEL_SIZE 3
#define OUTPUT_HEIGHT (IMAGE_HEIGHT - KERNEL_SIZE + 1)
#define OUTPUT_WIDTH  (IMAGE_WIDTH - KERNEL_SIZE + 1)

/* Number of bits used to represent weights and pixel values */
#define WEIGHT_BIT_WIDTH 8
#define IMAGE_BIT_WIDTH 8

typedef ap_int<WEIGHT_BIT_WIDTH> weight_t;
typedef ap_uint<IMAGE_BIT_WIDTH> input_image_t;
typedef ap_uint<IMAGE_BIT_WIDTH> output_image_t;
typedef ap_int<32> bias_t;
typedef ap_uint<14> count_t;
typedef ap_int<21> accum_t; /* IMAGE_BIT_WIDTH + WEIGHT_BIT_WIDTH + 5 */

/**
 * Implements a simple IP that performs the convolution of two matrices.
 * @param image_in
 * @param image_out
 * @param weights
 * @param bias
 */
void axil_conv2D(input_image_t image_in[IMAGE_HEIGHT * IMAGE_WIDTH],
                 output_image_t image_out[OUTPUT_HEIGHT * OUTPUT_WIDTH],
                 weight_t weights[KERNEL_SIZE * KERNEL_SIZE],
                 bias_t bias);

#endif //__AXIL_CONV2D_H__
