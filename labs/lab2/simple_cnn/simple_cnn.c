/**
 * @file simple_cnn.c
 * @date May, 2022
 *
 * Support file for lab2 of Hardware-Software Co-Design 2022
 *
 * Contains the variables, constants, and routines related to the CNN model, as well as the main routine.
 *
 * NOTES:
 * 1) With the default memory management scheme, images.bin and weights.bin should
 *    be stored in the following memory locations:
 *    images.bin  -> 0x10000000
 *    weights.bin -> 0x11000000
 * 2) When generating the linker script, define heap and stack size at least:
 *    Heap Size  -> 10 kB
 *    Stack Size -> 10 kB
 */

#include <stdio.h>

#include "simple_cnn.h"
#include "image.h"

volatile unsigned char *ch_images; /* images data region */
volatile float *fp_params;         /* network parameters data region */
volatile float *fp_image;          /* scaled floating-point image to be processed */
volatile float *matA;              /* auxiliary matrix A to implement 3D convolution as a matrix multiplication */
volatile float *matCv;             /* output of convolutional layer before adding bias */
volatile float *matCbias;          /* output of convolutional layer after adding bias */
volatile float *matCrelu;          /* output of ReLU */
volatile float *matCpool;          /* output of pooling layer */
volatile float *matConn;           /* output of fully connected layer before adding bias */
volatile float *matConnB;          /* output of fully connected layer after adding bias */
volatile float *matSoftM;          /* output of softmax layer */

void init_memory() {
    /* Check if memory reserved for loading files is enough */
    assert(MEM_BIN_IMAGES >= MEM_CH_IMAGES);
    assert(MEM_BIN_PARAMS >= MEM_FP_PARAMS);

    /* Assign memory regions */
    ch_images = (unsigned char *) MEM_BASE_ADDR;
    fp_params = (float *) ((unsigned char *) ch_images + MEM_BIN_IMAGES);
    fp_image = (float *) ((unsigned char *) fp_params + MEM_BIN_PARAMS);
    matA = (float *) ((unsigned char *) fp_image + MEM_FP_IMAGE);
    matCv = (float *) ((unsigned char *) matA + MEM_MAT_A);
    matCbias = (float *) ((unsigned char *) matCv + MEM_MAT_C_V);
    matCrelu = (float *) ((unsigned char *) matCbias + MEM_MAT_C_BIAS);
    matCpool = (float *) ((unsigned char *) matCrelu + MEM_MAT_C_RELU);
    matConn = (float *) ((unsigned char *) matCpool + MEM_MAT_C_POOL);
    matConnB = (float *) ((unsigned char *) matConn + MEM_MAT_CONN);
    matSoftM = (float *) ((unsigned char *) matConnB + MEM_MAT_CONN_B);

    /* Load images and weights from files if running in PC */
#ifndef EMBEDDED
    FILE *weights_file = fopen(WEIGHTS_FILENAME, "rb");
    assert(weights_file);
    fread((float *) fp_params,
          TOTAL_PARAMS,
          sizeof(float),
          weights_file);
    fclose(weights_file);

    FILE *images_file = fopen(IMAGES_FILENAME, "rb");
    assert(images_file);
    fread((float *) ch_images,
          N_IMAGES * IMAGE_SIZE,
          sizeof(unsigned char),
          images_file);
    fclose(images_file);
#endif // EMBEDDED
}

int predict_class() {
#if defined(EMBEDDED) && defined(PRINT_TIME_PER_LAYER)
    double t_start = xilGetMilliseconds();
#endif
    forward_convolutional_layer();
#if defined(EMBEDDED) && defined(PRINT_TIME_PER_LAYER)
    double t_conv = xilGetMilliseconds();
#endif
    forward_max_pool_layer();
#if defined(EMBEDDED) && defined(PRINT_TIME_PER_LAYER)
    double t_pool = xilGetMilliseconds();
#endif
    forward_connected_layer();
#if defined(EMBEDDED) && defined(PRINT_TIME_PER_LAYER)
    double t_conn = xilGetMilliseconds();
#endif
    int predicted_class = forward_softmax_layer();
#if defined(EMBEDDED) && defined(PRINT_TIME_PER_LAYER)
    double t_end = xilGetMilliseconds();
#endif

#if defined(EMBEDDED) && defined(PRINT_TIME_PER_LAYER)
    printf("Layer 1 (Convolutional) took %.0f ms.\n\r", t_conv - t_start);
    printf("Layer 2 (Pooling) took %.0f ms.\n\r", t_pool - t_conv);
    printf("Layer 3 (Fully-Connected) took %.0f ms.\n\r", t_conn - t_pool);
    printf("Layer 4 (Soft-max) took %.3f ms.\n\r", t_end - t_conn);
#endif // PRINT_TIME_PER_LAYER
    return predicted_class;
}

void compute_matrixA() {
    for (int i = 0; i < CONV_OUTPUT_HEIGHT; i++)
        for (int j = 0; j < CONV_OUTPUT_WIDTH; j++)
            for (int k = 0; k < IMAGE_CHANNELS; k++)
                for (int x = 0; x < CONV_KERNEL_SIZE; x++)
                    for (int y = 0; y < CONV_KERNEL_SIZE; y++) {
                        /* Auxiliary matrix index */
                        int matA_1d_idx =
                                (i * CONV_OUTPUT_WIDTH + j) *               /* planar coordinate */
                                CONV_KERNEL_SIZE * CONV_KERNEL_SIZE * IMAGE_CHANNELS +
                                k * (CONV_KERNEL_SIZE * CONV_KERNEL_SIZE) + /* OFM */
                                x * CONV_KERNEL_SIZE + y;                   /* kernel element */

                        /* Input image index */
                        int image_1d_idx =
                                k * (IMAGE_HEIGHT * IMAGE_WIDTH) +  /* OFM */
                                (x + i) * IMAGE_HEIGHT + (y + j);   /* pixel */

                        matA[matA_1d_idx] = fp_image[image_1d_idx];
                    }
}

void sw_convolution_3D(const float *image_in, const float *weights, float bias, float *image_out) {
    for (int i = 0; i < CONV_OUTPUT_HEIGHT; i++) {
        for (int j = 0; j < CONV_OUTPUT_WIDTH; j++) {
            float accum = 0;
            for (int k = 0; k < IMAGE_CHANNELS; k++) {
                for (int x = 0; x < CONV_KERNEL_SIZE; x++) {
                    for (int y = 0; y < CONV_KERNEL_SIZE; y++) {
                        /* Weights matrix index */
                        int weight_1d_idx =
                                k * (CONV_KERNEL_SIZE * CONV_KERNEL_SIZE) + /* OFM */
                                x * CONV_KERNEL_SIZE + y;                   /* planar coordinate */

                        /* Input image index */
                        int image_1d_idx =
                                k * (IMAGE_HEIGHT * IMAGE_WIDTH) +          /* OFM */
                                (x + i) * IMAGE_HEIGHT + (y + j);           /* pixel */

                        accum += weights[weight_1d_idx] * image_in[image_1d_idx];
                    }
                }
            }
            image_out[i * CONV_OUTPUT_WIDTH + j] = accum + bias;
        }
    }
}

void add_bias(const float *C, int rows, int cols, const float *bias, float *Cbias) {
    for (int i = 0; i < rows; i++)
        for (int j = 0; j < cols; j++)
            Cbias[i * cols + j] = C[i * cols + j] + bias[i];
}

void ReLU(const float *C, int size, float *Crl) {
    for (int i = 0; i < size; i++)
        Crl[i] = C[i] < 0 ? 0 : C[i];
}

void forward_convolutional_layer() {
#ifdef USE_GEMM
    compute_matrixA();

    float *matW = (float *) fp_params + CONV_OFM_NUMBER;

    gemmBTCT((float *) matA,
             (float *) matW,
             (float *) matCv,
             CONV_OUTPUT_HEIGHT * CONV_OUTPUT_WIDTH,
             CONV_KERNEL_SIZE * CONV_KERNEL_SIZE * IMAGE_CHANNELS,
             CONV_OFM_NUMBER);

    add_bias((float *) matCv,
             CONV_OFM_NUMBER,
             CONV_OUTPUT_HEIGHT * CONV_OUTPUT_WIDTH,
             (float *) fp_params,
             (float *) matCbias);
#else
    for (int i = 0; i < CONV_OFM_NUMBER; i++) {
        float bias = fp_params[i];

        /* Address where the convolutional weights are stored */
        float *fp_weights =
                (float *) fp_params +                                       /* start address of params */
                CONV_OFM_NUMBER +                                           /* offset (biases) */
                i * (IMAGE_CHANNELS * CONV_KERNEL_SIZE * CONV_KERNEL_SIZE); /* kernel of OFM(i) */

        float *image_out =
                (float *) matCbias +                                        /* base address */
                i * (CONV_OUTPUT_HEIGHT * CONV_OUTPUT_WIDTH);               /* offset (number of images) */

        sw_convolution_3D((float *) fp_image, fp_weights, bias, image_out);
    }
#endif // USE_GEMM
    ReLU((float *) matCbias,
         CONV_OFM_NUMBER * CONV_OUTPUT_HEIGHT * CONV_OUTPUT_WIDTH,
         (float *) matCrelu);
}

void forward_max_pool_layer() {
    for (int i = 0; i < POOL_OUTPUT_HEIGHT; i++)
        for (int j = 0; j < POOL_OUTPUT_WIDTH; j++)
            for (int k = 0; k < CONV_OFM_NUMBER; k++) {
                float max = -FLT_MAX;
                for (int x = 0; x < POOL_KERNEL_SIZE; x++) {
                    for (int y = 0; y < POOL_KERNEL_SIZE; y++) {
                        /* Index of element of convolution output */
                        int conv_out_1d_idx =
                                k * (CONV_OUTPUT_HEIGHT * CONV_OUTPUT_WIDTH) + /* OFM */
                                (i * POOL_STRIDE + x) * CONV_OUTPUT_WIDTH +    /* Row */
                                j * POOL_STRIDE + y;                           /* Column */

                        max = (matCrelu[conv_out_1d_idx] > max) ? matCrelu[conv_out_1d_idx] : max;
                    }
                }
                /* Index of element of the pooling output */
                int pool_out_1d_idx =
                        k * (POOL_OUTPUT_HEIGHT * POOL_OUTPUT_WIDTH) + /* OFM */
                        i * POOL_OUTPUT_WIDTH +                        /* Row */
                        j;                                             /* Column */

                matCpool[pool_out_1d_idx] = max;
            }
}

void forward_connected_layer() {
    float *mbias =
            (float *) fp_params +
            CONV_OFM_NUMBER +
            IMAGE_CHANNELS * CONV_OFM_NUMBER * CONV_KERNEL_SIZE * CONV_KERNEL_SIZE;

    float *matW =
            (float *) mbias +
            N_CLASSES;

    gemm(matW,
         (float *) matCpool,
         (float *) matConn,
         N_CLASSES,
         POOL_OUTPUT_HEIGHT * POOL_OUTPUT_WIDTH * CONV_OFM_NUMBER,
         1);

    add_bias((float *) matConn,
             N_CLASSES,
             1,
             mbias,
             (float *) matConnB);
}

int forward_softmax_layer() {
    int best = 0;
    float sum = 0;

    /* Determine the most likely class */
    for (int i = 0; i < N_CLASSES; i++)
        if (matConnB[i] > matConnB[best])
            best = i;

    /* Exponential */
    for (int i = 0; i < N_CLASSES; i++) {
        matSoftM[i] = exp(matConnB[i] - matConnB[best]);
        sum += matSoftM[i];
    }

    /* Normalize */
    for (int i = 0; i < N_CLASSES; i++)
        matSoftM[i] /= sum;

    return best;
}

void print_fp(float *matrix, int n, char *description) {
    printf("%s\n\r", description);
    for (int i = 0; i < n; i++) {
        if ((i % N_CLASSES) == 0)
            printf("%03d: ", i);
        printf("%f ", matrix[i]);

        if ((i % N_CLASSES) == 9)
            printf("\n\r");
    }
    printf("\n\r");
}

void print_fp_mat(float *matrix, int rows, int cols) {
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++)
            printf("%f ", matrix[i * cols + j]);
        printf("\n\r");
    }
}

#ifdef EMBEDDED
double xilGetMilliseconds() {
    XTime time;
    XTime_GetTime(&time);
    return (double) time * 1000 / COUNTS_PER_SECOND;
}
#endif // EMBEDDED

int main(int argc, char **argv) {
    /* Performs memory assignment */
    init_memory();

    /* Classify first NUMBER_OF_IMAGES_TO_CLASSIFY from the dataset */
    for (int i = FIRST_IMAGE_TO_CLASSIFY - 1; i < FIRST_IMAGE_TO_CLASSIFY + NUMBER_OF_IMAGES_TO_CLASSIFY - 1; i++) {
        unsigned char *image_in = (unsigned char *) ch_images + i * IMAGE_SIZE;

        /* normalize to [-1, 1] */
        normalize_image((unsigned char *) image_in, (float *) fp_image);

#ifdef PRINT_IMAGE
        print_ppm(image_in);
#endif // PRINT_IMAGE

        int prediction = predict_class();

        printf("# Image %03d -> Class=%d (%8s) %3.0f%% [ ",
               i + 1, prediction,
               image_class[prediction],
               matSoftM[prediction] * 100);

        for (int i = 0; i < N_CLASSES; i++)
            printf("%3.0f%% ", matSoftM[i] * 100);

        printf(prediction == i % N_CLASSES ? "] OK\n\r" : "] Prediction Error\n\r");
    }
}
