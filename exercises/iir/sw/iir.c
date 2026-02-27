#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include <xtime_l.h>

#define DMA_DEV_ID        0

#define INPUT_SIZE        1024
#define FS 48000.0f   // Sampling frequency
#define F_SQUARE 5000.0f  // Square wave frequency

#define TIMEOUT           100000

float input_float[INPUT_SIZE];
float output_float[INPUT_SIZE];
int16_t input_fixed[INPUT_SIZE];
int16_t output_fixed[INPUT_SIZE];
#define FLOAT_TO_FIXED(x)  ((int16_t)((x) * 4096.0f))
#define FIXED_TO_FLOAT(x)  ((float)(x) / 4096.0f)

void iir_filter_sw(float *x, float *y, int N) {
    // Example Iir filter coefficients (low-pass, 2nd order)
    const float b0 = 0.0625f;
    const float b1 = 0.125f;
    const float b2 = 0.0625f;
    const float a1 = -1.125f;
    const float a2 = 0.5f;

    //iteration 0
    float xd0 = x[0];
    float yd0 = b0 * xd0;
    //store results
    y[0] = yd0;

    // Prepare for next iteration
    float xd1 = xd0;
    float yd1 = yd0;

    //iteration 1
    xd0 = x[1];
    yd0 = b0 * xd0 + b1 * xd1 - a1 * yd1;
    //store results
    y[1] = yd0;

    // Prepare for next iteration
    float xd2 = xd1;
    float yd2 = yd1;
    xd1 = xd0;
    yd1 = yd0;
        
    for (int i = 2; i < N; i+=1) {
      xd0 = x[i];
      // Direct Form I computation
      yd0 = b0 * xd0 + b1 * xd1 + b2 * xd2 - a1 * yd1 - a2 * yd2;
      // Store results
      y[i] = yd0;
      // Prepare for next iteration
      xd2 = xd1;
      yd2 = yd1;
      xd1 = xd0;
      yd1 = yd0;
    }
}


int main()
{
    // Generate square wave input
    for (int i = 0; i < INPUT_SIZE; i++){
      input_float[i] = sinf(2.0f * M_PI * F_SQUARE * (float)i / FS) >= 0.0f ? 1.0f : -1.0f;
      input_fixed[i] = FLOAT_TO_FIXED(input_float[i]);
    }
    
    //
    XTime tStart, tEnd;
    sleep(1);
    XTime_GetTime(&tStart); 

    // Run software filter for comparison
    iir_filter_sw(input_float, output_float, INPUT_SIZE);

    XTime_GetTime(&tEnd);
    float elapsedTime = ((float)((tEnd - tStart))) * 1000000.0 / COUNTS_PER_SECOND;
    printf("Software elapsed time: %f us\n", elapsedTime);
    
    printf("Done.\n");
    return 0;
}
