#ifndef __IMAGE_H__
#define __IMAGE_H__

#include <stdio.h>

/* ========================== START OF TEST SET CONFIGURATION ========================== */

#define IMAGES_FILENAME "images.bin" /* file where the images are stored */
#define N_IMAGES 200                 /* number of images in the binary file */
#define IMAGE_HEIGHT 88              /* width of the images */
#define IMAGE_WIDTH IMAGE_HEIGHT     /* height of the images */
#define IMAGE_CHANNELS 3             /* number of channels (red + green + blue) */
#define N_CLASSES 10                 /* number of possible classes */

static char image_class[10][9] = {"Airplane", "Bird", "Car", "Cat", "Deer", "Dog",
                                  "Horse", "Monkey", "Ship", "Truck"};

/* =========================== END OF TEST SET CONFIGURATION =========================== */

#define IMAGE_SIZE (IMAGE_HEIGHT * IMAGE_WIDTH * IMAGE_CHANNELS)
#define IMAGE_IN_R(I, J) (rgb_image[(I) * IMAGE_HEIGHT + (J)])
#define IMAGE_IN_G(I, J) (rgb_image[IMAGE_HEIGHT * IMAGE_WIDTH + (I) * IMAGE_HEIGHT + (J)])
#define IMAGE_IN_B(I, J) (rgb_image[2 * IMAGE_HEIGHT * IMAGE_WIDTH + (I) * IMAGE_HEIGHT + (J)])

/**
 * Scales image pixels from 8-bit integers to be floating-point values in range [0, 1].
 * @param rgb_image Flattened 3D matrix containing the RBG values of the pixels
 * @param norm_image Flattened 3D matrix containing the normalized values of the pixels
 */
void normalize_image(const unsigned char *rgb_image, float *norm_image);

/**
 * Prints the input image to stdout in ppm format (see http://paulbourke.net/dataformats/ppm/).
 * @param rgb_image Flattened 3D matrix containing the RGB values of the pixels
 */
void print_ppm(unsigned char *rgb_image);

/**
 * Prints the normalized values of the pixels of the input image to stdout.
 * @param norm_image Flattened 3D matrix containing the normalized values of the pixels
 */
void print_fp_image(float *norm_image);

#endif // __IMAGE_H__
