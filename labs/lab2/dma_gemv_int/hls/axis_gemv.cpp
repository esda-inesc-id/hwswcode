#include <ap_int.h>
#include <hls_stream.h>
#include "ap_axi_sdata.h"

#define MEM_SIZE 512

// typedef ap_axis<32, 0, 0, 0> strmio_t;
typedef hls::axis<ap_int<32>, 0, 0, 0> strmio_t;

// The top-level function
void axis_gemv(
      hls::stream<strmio_t> &strm_in,
      hls::stream<strmio_t> &strm_out
      )
{
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS interface axis port=strm_in
#pragma HLS INTERFACE axis port=strm_out

	strmio_t tmp, tmpa;
	static ap_int<64> mult;
	static ap_int<73> acc;
	static ap_uint<9> last_velem;
	static ap_int<32> localmem[MEM_SIZE];
	ap_uint<10> i;

   for (i=0 ; i<MEM_SIZE; i++) {
	   tmp = strm_in.read();
	   localmem[i] = tmp.data;
	   if (tmp.last == 1) break ;
   }
   last_velem = i;

   for (i = 0; ; ) {
#pragma HLS LOOP_TRIPCOUNT max=512*512
	   //#pragma HLS pipeline off
	   tmp = strm_in.read();
	   mult = tmp.data * localmem[i];

	   if (i == 0) acc = mult;
	   else acc += mult;

	   if (i == last_velem) {
		   i = 0;
		   tmpa.last = tmp.last;
		   tmpa.data = (ap_int<32>)acc;
		   tmpa.keep = 0xF;
		   tmpa.strb = 0xF;
		   strm_out.write(tmpa);
		   if (tmp.last == 1) break ;
	   }
	   else i++;
   }
}
