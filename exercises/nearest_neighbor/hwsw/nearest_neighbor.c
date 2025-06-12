#include "xnearest_neighbor.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <xiltimer.h>
#define INFINITY 1.0/0.0 // Define infinity for distance comparison
#define A_BASE_ADDR  0x10000000

// Function to calculate the Euclidean distance between two points
float euclidean_distance(float *point1, float *point2, int dimensions) {
  float sum = 0.0;
  for (int i = 0; i < dimensions; i++) {
    sum += (point1[i] - point2[i]) * (point1[i] - point2[i]);
  }
  return sqrt(sum);
}

// Function to find the nearest neighbor of a given point in a dataset
int find_nearest_neighbor(float *point, float *A, int num_points, int dimensions, float *nearest_distance) {
  int nearest_index = -1;
  *nearest_distance = INFINITY;
  for (int i = 0; i < (num_points * dimensions); i+=2) {
    float distance = euclidean_distance(point, &A[i], dimensions);
    if (distance < *nearest_distance) {
      *nearest_distance = distance;
      nearest_index = i;
    }
  }
   return nearest_index;
}

// Main function to demonstrate the nearest neighbor search
int main() {
  XTime tStart, tEnd;
  sleep(1);

  int num_points = 50;
  int dimensions = 2;
  int size = num_points * dimensions;
  int nearest_index;
  float nearest_distance;

  //Initialize input arrays in DDR
  volatile float *A = (float *)A_BASE_ADDR;

  int i;
  for (i = 0; i < (size+2); i+=2) {
    A[i] = round(((float)rand() / (float)RAND_MAX * 32.0) * 8.0); // x-coordinate
    A[i+1] = round(((float)rand() / (float)RAND_MAX * 32.0) * 8.0); // y-coordinate
    printf("Point %d: (%f, %f)\n", i, A[i]/8.0, A[i + 1]/8.0);
  }

  A[i] = INFINITY; // Initialize to a large value

  float point[2] = {A[i-2], A[i-1]};
  printf("Searching for nearest neighbor of point: (%f, %f)\n", point[0]/8.0, point[1]/8.0);

  XTime_GetTime(&tStart);

  nearest_index = find_nearest_neighbor(point, A, num_points, dimensions, &nearest_distance);

  XTime_GetTime(&tEnd);

  float elapsedTime = ((float)((tEnd - tStart)*-1)) * 1000000.0 / COUNTS_PER_SECOND;
  printf("Nearest neighbor search took %0.4f microseconds\n", elapsedTime);
  
  printf("Nearest neighbor: %d: (%f, %f) at %f\n", nearest_index/2, A[nearest_index]/8.0, A[nearest_index + 1]/8.0, nearest_distance/8.0);
  
  //flush the data cache
  Xil_DCacheFlushRange((u32)A, (size + 2) * sizeof(float));
  

  XNearest_neighbor myAccel;
  XNearest_neighbor_Config *cfg;
  // Lookup config and initialize
  cfg = XNearest_neighbor_LookupConfig(0x40000000);
  if (!cfg) {
    printf("Error loading config\n");
    return -1;
  }
  
  if (XNearest_neighbor_CfgInitialize(&myAccel, cfg) != XST_SUCCESS) {
    printf("Error initializing\n");
    return -1;
  }
  printf("Starting\n\n");


  XTime_GetTime(&tStart);

  XNearest_neighbor_Set_A(&myAccel, A_BASE_ADDR);  
  XNearest_neighbor_Set_size(&myAccel, size);


  // Start the accelerator
  XNearest_neighbor_Start(&myAccel);

  // Wait for the accelerator to finish
  while (!XNearest_neighbor_IsDone(&myAccel));

  nearest_index = XNearest_neighbor_Get_return(&myAccel)/2;
  nearest_distance = A[i];

  XTime_GetTime(&tEnd);

  elapsedTime = ((float)((tEnd - tStart)*-1)) * 1000000.0 / COUNTS_PER_SECOND;
  printf("Nearest neighbor search took %0.4f microseconds\n", elapsedTime);
  
  printf("Nearest neighbor index hw: %d\n", nearest_index);
  printf("Nearest neighbor distance hw: %f\n", sqrt(nearest_distance)/8.0);

  return 0;
}
