#include <stdio.h>
#include <math.h>

// Use float for clarity; replace with fixed-point if needed
void iir_filter_sw(float *x, float *y, int N) {
    // Example Iir filter coefficients (low-pass, 2nd order)
    const float b0 = 0.0625f;
    const float b1 = 0.125f;
    const float b2 = 0.0625f;
    const float a1 = -1.125f;
    const float a2 = 0.5f;

    // Delay elements (initialized to zero)
    float x1 = 0.0f, x2 = 0.0f;
    float y1 = 0.0f, y2 = 0.0f;

    for (int i = 0; i < N; ++i) {
        float x0 = x[i];

        // Direct Form I computation
        float y0 = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;

        // Update delay elements
        x2 = x1;
        x1 = x0;
        y2 = y1;
        y1 = y0;

        // Output sample
        y[i] = y0;
    }
}


int main() {
    const int N = 480;
    float x[N], y[N];

    // Sampling rate and square wave frequency
    float fs = 48000.0f;   // 1000 Hz sampling rate
    float f_square = 5000.0f; // 10 Hz square wave (well below LPF cutoff)

    // Generate square wave
    for (int i = 0; i < N; ++i) {
        float t = (float)i / fs;
        x[i] = (sinf(2.0f * M_PI * f_square * t) >= 0.0f) ? 4.0f : -4.0f;
    }

    // Filter the square wave
    iir_filter_sw(x, y, N);

    // Print filtered output
    for (int i = 0; i < N; ++i) {
        printf("%f\n", y[i]);
    }

    return 0;
}
