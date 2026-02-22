#ifndef __IMAGE_CONV2D_H__
#define __IMAGE_CONV2D_H__

/* =========================== START OF DATASET CONFIGURATION ========================== */

#define IMAGES_FILENAME "images.bin" /* file where the images are stored */
#define N_IMAGES 200                 /* number of images in the binary file */
#define IMAGE_HEIGHT 88              /* width of the images */
#define IMAGE_WIDTH IMAGE_HEIGHT     /* height of the images */
#define IMAGE_CHANNELS 3             /* number of channels (red + green + blue) */

/* ============================ END OF DATASET CONFIGURATION =========================== */

/* =========================== START OF KERNEL CONFIGURATION =========================== */

/**
 * Pick one of the available 5 kernels
 * 0: Identity kernel
 * 1: Emboss 5x5 filter
 * 2: Custom filter
 * 3: Laplacian of Gaussian
 * 4: Emboss 3x3 filter
 */
#define KERNEL 2

/* ============================ END OF KERNEL CONFIGURATION ============================ */

/* ============================= START OF RUN CONFIGURATION ============================ */

//#define HLS_SIMULATION               /* uncomment to enable HLS simulation */
//#define EMBEDDED                     /* uncomment to run in Zynq */
//#define USE_HW_IP                    /* uncomment to accelerate convolution with hardware IP */
//#define PRINT_IMAGE_IN               /* uncomment print input image to file */
#define PRINT_IMAGE_OUT              /* print output image to file */
#define IMAGE_TO_CONVOLVE 1          /* selected input image */

/* ============================== END OF RUN CONFIGURATION ============================= */

/* =====================================================================================
 * ================ PARAMETERS AUTOMATICALLY GENERATED BELOW THIS LINE! ================
 * ===================================================================================== */

#define KERNEL_SIZE 3

/* ================================ START OF KERNEL LIST =============================== */

#if KERNEL == 0
/* Identity filter */
static signed char kernel[KERNEL_SIZE * KERNEL_SIZE] = {
        0,  0,  0,
        0,  1,  0,
        0,  0,  0 };
static int bias = 0;
#elif KERNEL == 1
/* edge detector */
static signed char kernel[KERNEL_SIZE * KERNEL_SIZE] = {
        -1, -1, -1,
        -1,  8, -1,
        -1, -1, -1 };
static int bias = 0;
#elif KERNEL == 2
/* sharpen */
static signed char kernel[KERNEL_SIZE * KERNEL_SIZE] = {
        0, -1,  0,
       -1,  5, -1,
        0, -1,  0 };
static int bias = 0 ;
#elif KERNEL == 3
/* Emboss 3x3 filter */
static signed char kernel[KERNEL_SIZE * KERNEL_SIZE] = {
       -2, -1,  0,
       -1,  1,  1,
        0,  1,  2 };
static int bias = 0;
#endif

/* ================================= END OF KERNEL LIST ================================ */

#define IMAGE_SIZE (IMAGE_HEIGHT * IMAGE_WIDTH * IMAGE_CHANNELS)
#define OUTPUT_HEIGHT (IMAGE_HEIGHT - KERNEL_SIZE + 1)
#define OUTPUT_WIDTH (IMAGE_WIDTH - KERNEL_SIZE + 1)

#define IMAGE_R(IMG, HEIGHT, WIDTH, I, J) ((IMG)[(I) * (WIDTH) + (J)])
#define IMAGE_G(IMG, HEIGHT, WIDTH, I, J) ((IMG)[(WIDTH) * (HEIGHT) + (I) * (WIDTH) + (J)])
#define IMAGE_B(IMG, HEIGHT, WIDTH, I, J) ((IMG)[2 * (WIDTH) * (HEIGHT) + (I) * (WIDTH) + (J)])

#define STRING_LENGTH 100

#ifdef EMBEDDED

#include "xtime_l.h"

// DDR pre-defined data regions
#define MEM_IMAGES_BASE_ADDRESS 0x10000000
#define MEM_DATA_BASE_ADDRESS 0x11000000
#else
static unsigned char memory_images[N_IMAGES * IMAGE_SIZE];
static unsigned char memory_data[OUTPUT_HEIGHT * OUTPUT_WIDTH * 3];

#define MEM_IMAGES_BASE_ADDRESS memory_images
#define MEM_DATA_BASE_ADDRESS memory_data
#endif

/**
 * Performs software-only matrix convolution.
 * @param matrix_in Input matrix
 * @param matrix_out Output matrix after convolution
 */
void sw_convolution_2D(const unsigned char *matrix_in, unsigned char *matrix_out);

/**
 * Prints the image in PPM format
 * @param image Image to print
 * @param height Number of rows
 * @param width Number of columns
 * @param prefix "input" or "output"
 * @param suffix Image number
 */
void print_ppm(unsigned char *image, int height, int width, const char *prefix, int suffix);

/**
 * Performs hardware accelerated matrix convolution (can be used for HLS simulation).
 * @param matrix_in Input matrix
 * @param matrix_out Output matrix after convolution
 *
 * =====================================================================================
 * ================= YOU WILL HAVE TO IMPLEMENT THIS ROUTINE YOURSELF! =================
 * =====================================================================================
 */
void HWSW_conv2D(const unsigned char *matrix_in, unsigned char *matrix_out);

/**
 * Checks every pixel calculated by the hardware implementation for errors.
 * @return Number of pixels wrongly calculated
 */
int check_hw_errors();

#endif //__IMAGE_CONV2D_H__
