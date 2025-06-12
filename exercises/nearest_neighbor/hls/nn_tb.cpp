#include <iostream>
#include <cmath>

int nearest_neighbor(volatile float* A, int size);


// Function to calculate the Euclidean distance between two points
float euclidean_distance(float *point1, float *point2, int dimensions) {
  float sum = 0.0;
  for (int i = 0; i < dimensions; i++) {
    sum += (point1[i] - point2[i]) * (point1[i] - point2[i]);
  }
  return sqrt(sum);
  //return sum;
}

// Function to find the nearest neighbor of a given point in a dataset
int find_nearest_neighbor(float *dataset, int size,  float *nearest_distance) {
  int nearest_index = -1;
  *nearest_distance = 1e38; // Initialize to a large value (infinity)

  for (int i = 0; i < size; i+= 2) {
    float distance = euclidean_distance(&dataset[size], &dataset[i], 2);
    if (distance < *nearest_distance) {
      *nearest_distance = distance;
      nearest_index = i;
    }
  }
  return nearest_index;
}

#define SIZE 4  // Must be even, since each 2D point takes 2 ints

int main() {
  
  int num_points = 50;
  int dimensions = 2;
  int size = num_points * dimensions; // +2 for the point to find and the nearest distance

  // Example dataset of points
  float *dataset = (float *) malloc((size + 3)* sizeof(float));
  for (int i = 0; i < num_points; i++) {
    dataset[i] = round(((float)rand() / (float)RAND_MAX * 32) * 8);// x-coordinate
    dataset[i+1] = round(((float)rand() / (float)RAND_MAX * 32) * 8);// y-coordinate
    printf("Point %d: (%f, %f)\n", i, dataset[i]/8.0, dataset[i+1]/8.0);
  }

  // Point to find the nearest neighbor for
  dataset[size] = round(((float)rand() / (float)RAND_MAX * 32) * 8); // x-coordinate
  dataset[size + 1] = round(((float)rand() / (float)RAND_MAX * 32) * 8); // y-coordinate
  printf("Searching for nearest neighbor of point: (%f, %f)\n", dataset[size]/8.0, dataset[size + 1]/8.0);

  // call the software function
  float nearest_distance_sw;
  int nearest_index_sw = find_nearest_neighbor(dataset, size, &nearest_distance_sw);
  
  // Call the hardware function
  int nearest_index_hw = nearest_neighbor(dataset, size);
  float nearest_distance_hw = dataset[size + 2]; // Get the nearest distance from the hardware function

  printf("Software Nearest Neighbor Index: %d, Distance: %f\n", nearest_index_sw, nearest_distance_sw);
  printf("Hardware Nearest Neighbor Index: %d, Distance: %f\n", nearest_index_hw, nearest_distance_hw);
}
