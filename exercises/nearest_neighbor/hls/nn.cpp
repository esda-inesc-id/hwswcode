#include <string.h>
int nearest_neighbor(volatile float* A, int size) {
#pragma HLS INTERFACE m_axi port=A offset=slave depth=1024 max_read_burst_length=32 bundle=gmem
#pragma HLS INTERFACE s_axilite port=size bundle=control
#pragma HLS INTERFACE s_axilite port=return bundle=control

  float local_A[1024];
  memcpy(local_A, (const float*)A, (size+3) * sizeof(float));

  float diff0;
  float diff1;

  float dist;

  float pt0 = local_A[size];
  float pt1 = local_A[size + 1];
  float min_dist = 1e38; // Initialize to a large value (infinity)
    
  int nearest_index = -1;
  
  for (int i = 0; i < size; i+=2) {
    diff0 = local_A[i] - pt0;
    diff1 = local_A[i+1] - pt1;

    dist = diff0 * diff0 + diff1 * diff1;
    if (dist < min_dist) {
      min_dist = dist;
      nearest_index = i;
    }
  }
  A[size + 2] = min_dist; // Store the minimum distance back to the array
  return nearest_index;
}
