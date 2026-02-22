#include "axis_gemv_fixed.h"

#define MEM_SIZE 512

// The top-level function
void axis_gemv_fixed(
      hls::stream<strmin_t> &strm_in,
      hls::stream<strmout_t> &strm_out
      )
{
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS interface axis port=strm_in
#pragma HLS INTERFACE axis port=strm_out

	strmin_t tmpi;
	strmout_t tmpo;

	static op_t op1, op2;
	static mul_t mult;
	static acc_t acc;
	static count_t last_velem;
	static datai_t localmem[MEM_SIZE];
	count_t i;

   for (i=0 ; i<MEM_SIZE; i++) {
	   tmpi = strm_in.read();
	   localmem[i] = tmpi.data;
	   if (tmpi.last == 1) break ;
   }
   last_velem = i;

   for (i = 0; ; ) {
#pragma HLS LOOP_TRIPCOUNT max=512*512
	   //#pragma HLS pipeline off
	   tmpi = strm_in.read();

	   op1 = (op_t)localmem[i];
	   op2 = (op_t)(tmpi.data);
	   mult = op1 * op2;

	   if (i == 0) acc = mult;
	   else acc += mult;

	   if (i == last_velem) {
		   i = 0;
		   tmpo.last = tmpi.last;
		   tmpo.data = (datao_t)acc;
		   tmpo.keep = 0xF;
		   tmpo.strb = 0xF;
		   strm_out.write(tmpo);
		   if (tmpi.last == 1) break ;
	   }
	   else i++;
   }
}
