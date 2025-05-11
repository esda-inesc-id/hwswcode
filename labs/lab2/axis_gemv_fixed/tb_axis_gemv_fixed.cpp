#include <stdio.h>
#include <stdlib.h>

#define MAT_COL_SIZE 6
#define MAT_ROW_SIZE 2
#define VEC_SIZE MAT_ROW_SIZE
#define VEC_OUT_SIZE MAT_COL_SIZE

static double mA[MAT_COL_SIZE*MAT_ROW_SIZE];
static double vB[VEC_SIZE];
static double hw_vC[VEC_OUT_SIZE];
static double sw_vC[VEC_OUT_SIZE];

#include "axis_gemv_fixed.h"

void init_vecs()
{
	int i;

	for (i=0; i<(MAT_COL_SIZE*MAT_ROW_SIZE); i++) {
		// Init vectors with 4 digit float values
		mA[i] = (double)((rand() % 9999) - 4999)/100.0F;
	}
	for (i=0; i<(VEC_SIZE); i++) {
		// Init vectors with 4 digit float values
		vB[i] = (double)((rand() % 9999) - 4999)/100.0F;
	}
}

void print_mat(double *x, int rows, int cols)
{
	int i;
	for (i=0; i<rows; i++) {
		for (int j=0; j<cols; j++) {
			printf("%6.2f ", x[i*cols+j]);
			double err = fabs(x[i*cols+j] - (double)((datai_t)x[i*cols+j]));
			printf("(%.2e) ", err);
		}
		printf("\n");
	}
	printf("\n");
}

void sw_gemv()
{
	int i, k;

	for (i=0; i<VEC_OUT_SIZE; i++) {
		sw_vC[i] = 0;
		for (k=0; k<MAT_ROW_SIZE; k++) {
			sw_vC[i] += mA[i*MAT_ROW_SIZE+k]*vB[k];
		}
	}
}

// The top-level function
void axis_gemv_fixed( hls::stream<strmin_t> &strm_in, hls::stream<strmout_t> &strm_out );

int main()
{
	int i, err_cnt = 0;
	hls::stream<strmin_t> str_in; //("sinp");
	hls::stream<strmout_t> str_out; //("sout");
	strmin_t tmpi;
	strmout_t tmpo;

	init_vecs();

	// Write vector B to str_in
	for (i=0; i<VEC_SIZE; i++) {
		tmpi.data = (datai_t)vB[i];
		if (i==(VEC_SIZE-1)) tmpi.last = (ap_int<1>)1;
		else tmpi.last = (ap_int<1>)0;

		str_in.write(tmpi);
	}

	// Write (append) matrix A to str_in
	for (i=0; i<(MAT_COL_SIZE*MAT_ROW_SIZE); i++) {
		tmpi.data = (datai_t)mA[i];
		if (i==(MAT_COL_SIZE*MAT_ROW_SIZE-1)) tmpi.last = (ap_int<1>)1;
		else tmpi.last = (ap_int<1>)0;

		str_in.write(tmpi);
	}

	// Simulates one execution of gemv IP
	// one execution = one vector B + matrix A
	axis_gemv_fixed(str_in, str_out);

	// Read vector C from str_out
	for (i=0; i<VEC_OUT_SIZE; i++) {
		tmpo = str_out.read();
		printf("hw: %21s %12.6f (%d)\n", tmpo.data.to_string(10).c_str(), (double)tmpo.data, (int)tmpo.last);
		hw_vC[i] = (double)tmpo.data;
	}

	sw_gemv();

	print_mat(mA, MAT_COL_SIZE, MAT_ROW_SIZE);
	print_mat(vB, VEC_SIZE, 1);
	print_mat(sw_vC, VEC_OUT_SIZE, 1);

	// Compare results with software implementation
	double err_max = 0.0;
	for (err_cnt = 0, i=0; i<VEC_OUT_SIZE; i++) {
		  double err = fabs(hw_vC[i] - sw_vC[i]);
		  double maximum_tolerable_error = (double)1.0e-03;
		  if (err > maximum_tolerable_error) err_cnt++;
		  if (err > err_max) err_max = err;
	}
	printf("max_err = %.2e\n", err_max);
	return err_cnt;
}
