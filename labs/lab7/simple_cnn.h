#ifndef __SIMPLE_CNN__
#define __SIMPLE_CNN__

#include <stdio.h>
#include <math.h>
#include <assert.h>
#include "image.h"
#include "gemm.h"

/* ============================= START OF RUN CONFIGURATION ============================ */
//#define EMBEDDED                         /* uncomment to run in Zynq */
//#define USE_GEMM                         /* uncomment to use GEMM */
//#define PRINT_IMAGE                      /* uncomment to print input images to console */
//#define PRINT_TIME_PER_LAYER             /* uncomment to print elapsed time per layer on zynq */
#define FIRST_IMAGE_TO_CLASSIFY 1        /* first image of the test set to classify */
#define NUMBER_OF_IMAGES_TO_CLASSIFY 10  /* number of images to classify sequentially */
/* ============================== END OF RUN CONFIGURATION ============================= */

/* ============================ START OF MODEL CONFIGURATION =========================== */
#define WEIGHTS_FILENAME "weights.bin"   /* file where the weights are stored */
#define CONV_KERNEL_SIZE 3               /* size of the convolution kernel */
#define CONV_OFM_NUMBER 16               /* number of OFMs of convolutional layer */
#define POOL_KERNEL_SIZE 2               /* size of pooling kernel */
#define POOL_STRIDE 2                    /* stride of pooling operation */
/* ============================== END OF RUN CONFIGURATION ============================= */

/* =====================================================================================
 * ================ PARAMETERS AUTOMATICALLY GENERATED BELOW THIS LINE! ================
 * ===================================================================================== */

#define CONV_OUTPUT_HEIGHT (IMAGE_HEIGHT - CONV_KERNEL_SIZE + 1)
#define CONV_OUTPUT_WIDTH (IMAGE_WIDTH - CONV_KERNEL_SIZE + 1)
#define POOL_OUTPUT_HEIGHT CONV_OUTPUT_HEIGHT / POOL_KERNEL_SIZE
#define POOL_OUTPUT_WIDTH CONV_OUTPUT_WIDTH / POOL_KERNEL_SIZE
#define CONV_LAYER_WEIGHTS CONV_KERNEL_SIZE * CONV_KERNEL_SIZE * CONV_OFM_NUMBER * IMAGE_CHANNELS
#define CONV_LAYER_BIASES CONV_OFM_NUMBER
#define FC_LAYER_WEIGHTS POOL_OUTPUT_WIDTH * POOL_OUTPUT_HEIGHT * CONV_OFM_NUMBER * N_CLASSES
#define FC_LAYER_BIASES N_CLASSES
#define TOTAL_PARAMS (CONV_LAYER_WEIGHTS + CONV_LAYER_BIASES + FC_LAYER_WEIGHTS + FC_LAYER_BIASES)

/* ============================= START OF MEMORY ASSIGNMENT ============================ */
/* Align memory regions for PS-PL data transference purposes */
#define ALIGN_CONSTANT 0x1000                          /* ALIGN_CONSTANT = 4 kB */
#define ALIGN(MEM_REGION) (                            /* aligns memory region to ALIGN_CONSTANT if not aligned */ \
    MEM_REGION % ALIGN_CONSTANT == 0 ?                 /* if memory region is aligned */ \
    MEM_REGION :                                       /* does nothing else */ \
    (MEM_REGION / ALIGN_CONSTANT + 1) * ALIGN_CONSTANT /* aligns memory region to next ALIGN_CONSTANT */ \
    )

/* Size in bytes of reserved memory regions */
#define MEM_BIN_IMAGES 0x01000000
#define MEM_BIN_PARAMS 0x01000000
#define MEM_CH_IMAGES ALIGN(  \
    N_IMAGES *                \
    IMAGE_SIZE *              \
    sizeof(unsigned char)     \
    )
#define MEM_FP_PARAMS ALIGN(  \
    TOTAL_PARAMS *            \
    sizeof(float)             \
    )
#define MEM_FP_IMAGE ALIGN(   \
    IMAGE_SIZE *              \
    sizeof(float)             \
    )
#define MEM_MAT_A ALIGN(      \
    CONV_OUTPUT_WIDTH *       \
    CONV_OUTPUT_HEIGHT *      \
    CONV_KERNEL_SIZE *        \
    CONV_KERNEL_SIZE *        \
    IMAGE_CHANNELS *          \
    sizeof(float)             \
    )
#define MEM_MAT_C_V ALIGN(    \
    CONV_OUTPUT_WIDTH *       \
    CONV_OUTPUT_HEIGHT *      \
    CONV_OFM_NUMBER *         \
    sizeof(float)             \
    )
#define MEM_MAT_C_BIAS MEM_MAT_C_V
#define MEM_MAT_C_RELU MEM_MAT_C_V
#define MEM_MAT_C_POOL ALIGN( \
    POOL_OUTPUT_WIDTH *       \
    POOL_OUTPUT_HEIGHT *      \
    CONV_OFM_NUMBER *         \
    sizeof(float)             \
    )
#define MEM_MAT_CONN ALIGN(   \
    N_CLASSES *               \
    sizeof(float)             \
    )
#define MEM_MAT_CONN_B MEM_MAT_CONN
#define MEM_MAT_SOFT_M MEM_MAT_CONN

#define MEM_TOTAL_RESERVED    \
    MEM_BIN_IMAGES +          \
    MEM_BIN_PARAMS +          \
    MEM_FP_IMAGE +            \
    MEM_MAT_A +               \
    MEM_MAT_C_V +             \
    MEM_MAT_C_BIAS +          \
    MEM_MAT_C_RELU +          \
    MEM_MAT_C_POOL +          \
    MEM_MAT_CONN +            \
    MEM_MAT_CONN_B +          \
    MEM_MAT_SOFT_M

#ifdef EMBEDDED
#include "xtime_l.h"
#define MEM_BASE_ADDR 0x10000000
#else
static unsigned char mem_array[MEM_TOTAL_RESERVED];
#define MEM_BASE_ADDR mem_array
#endif // EMBEDDED
/* ============================== END OF MEMORY ASSIGNMENT ============================= */

#define FLT_MAX 3.402823466e+38F

/**
 * Assigns memory regions to required data.
 */
void init_memory();

/**
 * Executes all layers of the CNN sequentially and returns the predicted class for a given sample.
 * @return Predicted class for a given sample
 */
int predict_class();

/**
 * Computes auxiliary matrix to perform convolution as matrix multiplication using GEMM kernel.
 * Matrix A has 4 dimensions:
 * (I, J): Planar coordinates of one OFM
 *      K: OFM
 *     XY: Combination of Planar coordinate of OFM with kernel element
 */
void compute_matrixA();

/**
 * Performs matrix convolution without using GEMM.
 * @param image_in Matrix containing normalized values of the pixels
 * @param weights Matrix containing elements of the kernel
 * @param bias Bias
 * @param image_out Matrix containing resulting convolution OFMs
 */
void sw_convolution_3D(const float *image_in, const float *weights, float bias, float *image_out);

/**
 * Adds bias to all elements of the input matrix.
 * @param C Input matrix
 * @param rows Rows of input matrix
 * @param cols Columns of input matrix
 * @param bias Bias
 * @param Cbias Output matrix
 */
void add_bias(const float *C, int rows, int cols, const float *bias, float *Cbias);

/**
 * Applies ReLU to elements of input matrix.
 * @param C Input matrix
 * @param size Size of input matrix
 * @param Crl Output matrix
 */
void ReLU(const float *C, int size, float *Crl);

/**
 * Executes convolution layer on input either using GEMM or plain convolution.
 */
void forward_convolutional_layer();

/**
 * Executes pooling layer on output of convolutional layer.
 */
void forward_max_pool_layer();

/**
 * Executes fully-connected layer on output of max pooling layer.
 */
void forward_connected_layer();

/**
 * Executes softmax operation on output of fully-connected layer to normalize it to a probability distribution
 * and returns most likely class which corresponds to position of the largest value.
 * @return Position of the largest value in matConnB
 */
int forward_softmax_layer();

/**
 * Prints first n elements of floating-point matrix for debug purposes.
 * @param matrix Input flattened floating-point matrix
 * @param n Size to print
 * @param description Description string
 */
void print_fp(float *matrix, int n, char *description);

/**
 * Prints entire floating-point matrix for debug purposes.
 * @param matrix Input flattened floating-point matrix
 * @param rows Number of rows
 * @param cols Number of columns
 */
void print_fp_mat(float *matrix, int rows, int cols);

#ifdef EMBEDDED
/**
 * Gets elapsed time in milliseconds in zynq device.
 */
double xilGetMilliseconds();
#endif // EMBEDDED

#endif // __SIMPLE_CNN__
