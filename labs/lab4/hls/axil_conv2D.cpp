/**
 * @file axil_conv2D.cpp
 * @date May, 2023
 *
 * Support file for lab1 of Hardware-Software Co-Design 2023
 *
 * Contains the HLS implementation of a simple matrix convolution IP.
 */

#include "axil_conv2D.h"

void axil_conv2D(input_image_t image_in[IMAGE_HEIGHT * IMAGE_WIDTH],
                 output_image_t image_out[OUTPUT_HEIGHT * OUTPUT_WIDTH],
                 weight_t weights[KERNEL_SIZE * KERNEL_SIZE],
                 bias_t bias) {

#pragma HLS INTERFACE s_axilite port=return bundle=BUS1
#pragma HLS INTERFACE s_axilite port=image_in bundle=BUS1
#pragma HLS INTERFACE s_axilite port=image_out bundle=BUS1
#pragma HLS INTERFACE s_axilite port=weights bundle=BUS1
#pragma HLS INTERFACE s_axilite port=bias bundle=BUS1

    loop_i:
    for (count_t i = 0; i < OUTPUT_HEIGHT; i++) {
        loop_j:
        for (count_t j = 0; j < OUTPUT_WIDTH; j++) {
            accum_t acc = (accum_t) bias;
            output_image_t acc_sat;

            loop_k:
            for (count_t k = 0; k < KERNEL_SIZE; k++) {
#pragma HLS PIPELINE
            	// Indices are initialized here to highlight
            	// the incremental counting in the inner loop
            	count_t kernel_1d_idx = k * KERNEL_SIZE ; /* start of kernel row */
            	count_t image_1d_idx = (i + k) * IMAGE_WIDTH + j ; /* start of input row */
                loop_x:
                for (count_t x = 0; x < KERNEL_SIZE; x++, kernel_1d_idx++, image_1d_idx++) {
                    acc += weights[kernel_1d_idx] * image_in[image_1d_idx];
                }
            }

            /* Normalize */
            if (acc > 255)
                acc_sat = 255;
            else if (acc < 0)
                acc_sat = 0;
            else
                acc_sat = acc;

            image_out[i * OUTPUT_WIDTH + j] = acc_sat;
        }
    }
}
