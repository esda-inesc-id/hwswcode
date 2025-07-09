#include <hls_stream.h>
#include <ap_fixed.h>
#include <ap_axi_sdata.h>


typedef ap_fixed<16, 2> data_t;
//typedef float data_t;
typedef hls::axis<ap_uint<16>, 0, 0, 0> strmio_t;  // 16-bit fixed-point AXI stream word


#define N 1024  // Number of samples to process
void iir_filter(hls::stream<strmio_t>& x, hls::stream<strmio_t>& y) {

#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE axis port=x
#pragma HLS INTERFACE axis port=y

    data_t x_n1 = 0;
    data_t x_n2 = 0;
    data_t y_n1 = 0;
    data_t y_n2 = 0;
    data_t yn = 0;


    const data_t b0 = 0.0625f;
    const data_t b1 = 0.125f;
    const data_t b2 = 0.0625f;
    const data_t a1 = -1.125f;
    const data_t a2 = 0.5f;

    for (int i = 0; i < N; i++) {
        //#pragma HLS PIPELINE II=1
        strmio_t xi = x.read();
        data_t xn;
        xn.range(15, 0) = xi.data;
        
        yn = b0 * xn + b1 * x_n1 + b2 * x_n2 - a1 * y_n1 - a2 * y_n2;

        y_n2 = y_n1;
        y_n1 = yn;

        x_n2 = x_n1;
        x_n1 = xn;

        strmio_t yi;
        yi.data = yn.range(15, 0);
        yi.keep = xi.keep;
        yi.strb = xi.strb;
        yi.last = xi.last;

        y.write(yi);
    }
}
