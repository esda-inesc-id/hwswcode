#include <ap_fixed.h>
#include <hls_stream.h>
#include <ap_axi_sdata.h>

#include <math.h>
#include <stdlib.h>
#include <iostream>
// Customize the data type: use fixed point for synthesis efficiency
typedef ap_fixed<16, 2> data_t;
typedef hls::axis<ap_uint<16>, 0, 0, 0> strmio_t;  // 16-bit fixed-point AXI stream word

// Include your HLS function header

void iir_filter(hls::stream<strmio_t>& x, hls::stream<strmio_t>& y);

// Sampling parameters
#define N  1024
#define FS 48000.0f   // Sampling frequency
#define F_SQUARE 5000.0f  // Square wave frequency
float strmio_data_to_float(ap_uint<16> raw_bits) {
    data_t fixed_val;
    fixed_val.range(15, 0) = raw_bits;  // assign bits to fixed-point variable
    return fixed_val.to_float();
}
strmio_t float_to_strmio(float f, bool last = false) {
    data_t fixed_val = (data_t)f;
    strmio_t s;
    s.data = fixed_val.range(15, 0);
    s.keep = -1;
    s.strb = -1;
    s.last = last;
    return s;
}

int main() {
    
    hls::stream<strmio_t> in_stream;
    hls::stream<strmio_t> out_stream;

    strmio_t input[N], output[N];

    // Generate square wave input
    for (int i = 0; i < N; ++i) {
        float t = i / FS;
        float f = sinf(2.0f * M_PI * F_SQUARE * t) >= 0.0f ? 1.0f : -1.0f;
        //std::cout << "Sample " << i << ": " << f << std::endl;
        input[i] = float_to_strmio( f, (i == N - 1));
        in_stream.write(input[i]);
    }

    // Call the HLS filter function
    iir_filter(in_stream, out_stream);

    // Read and display the output
    for (int i = 0; i < N; ++i) {
        output[i] = out_stream.read();
        std::cout << i << "\t" << strmio_data_to_float(input[i].data) << "\t" << strmio_data_to_float(output[i].data) << std::endl;
        if (output[i].last && i != N - 1) {
            std::cerr << "Error: TLAST occurred early at i = " << i << std::endl;
        }
    }

    return 0;
}
