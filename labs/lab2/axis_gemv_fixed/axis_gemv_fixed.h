#include <ap_int.h>
#include <ap_fixed.h>
#include <hls_stream.h>
#include "ap_axi_sdata.h"

// Defined signal representations in terms of inputs
// then varied input precision to evaluate precision loss
#define IIN 7
#define FIN 18
#define WIN FIN+IIN

typedef ap_fixed<WIN,IIN> datai_t;
typedef ap_fixed<WIN,IIN> op_t;
typedef ap_fixed<WIN+WIN,IIN+IIN> mul_t;
typedef ap_fixed<WIN+WIN+9,IIN+IIN+9> acc_t;

typedef ap_fixed<32,16> datao_t;
typedef ap_uint<10> count_t;

typedef hls::axis<datai_t, 0, 0, 0> strmin_t;
typedef hls::axis<datao_t, 0, 0, 0> strmout_t;
