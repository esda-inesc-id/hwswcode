#include <stdio.h>
#include <stdlib.h>

#define MAT_COL_SIZE 6
#define MAT_ROW_SIZE 2
#define VEC_SIZE MAT_ROW_SIZE
#define VEC_OUT_SIZE MAT_COL_SIZE

static int mA[MAT_COL_SIZE*MAT_ROW_SIZE];
static int vB[VEC_SIZE];
static int hw_vC[VEC_OUT_SIZE];
static int sw_vC[VEC_OUT_SIZE];

void init_vecs()
{
	int i;

	for (i=0; i<(MAT_COL_SIZE*MAT_ROW_SIZE); i++) {
		// Init vectors with 8-bit integer values
		mA[i] = ((rand() % 0xFF) - 0x80);
	}
	for (i=0; i<(VEC_SIZE); i++) {
		// Init vectors with 8-bit integer values
		vB[i] = ((rand() % 0xFF) - 0x80);
	}
}

void print_mat(int *x, int rows, int cols)
{
	int i;
	for (i=0; i<rows; i++) {
		for (int j=0; j<cols; j++) {
			printf("%5d ", x[i*cols+j]);
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

#include <ap_int.h>
#include <hls_stream.h>
#include "ap_axi_sdata.h"

typedef ap_axis<32, 0, 0, 0> strmio_t;

// The top-level function
void axis_gemv( hls::stream<strmio_t> &strm_in,
                hls::stream<strmio_t> &strm_out );

int main()
{
	int i, err_cnt = 0;
	hls::stream<strmio_t> str_in; //("sinp");
	hls::stream<strmio_t> str_out; //("sout");
	strmio_t tmp, tmpa;

	init_vecs();

	// Write vector B to str_in
	for (i=0; i<VEC_SIZE; i++) {
		tmp.data = (ap_int<32>)vB[i];
		if (i==(VEC_SIZE-1)) tmp.last = (ap_int<1>)1;
		else tmp.last = (ap_int<1>)0;

		str_in.write(tmp);
	}

	// Write (append) matrix A to str_in
	for (i=0; i<(MAT_COL_SIZE*MAT_ROW_SIZE); i++) {
		tmp.data = (ap_int<32>)mA[i];
		if (i==(MAT_COL_SIZE*MAT_ROW_SIZE-1)) tmp.last = (ap_int<1>)1;
		else tmp.last = (ap_int<1>)0;

		str_in.write(tmp);
	}

	// Simulates one execution of gemv IP
	// one execution = one vector B + matrix A
	axis_gemv(str_in, str_out);

	// Read vector C from str_out
	for (i=0; i<VEC_OUT_SIZE; i++) {
		tmpa = str_out.read();
		printf("hw: %d (%d)\n", (int)tmpa.data, (int)tmpa.last);
		hw_vC[i] = (int)tmpa.data;
	}

	sw_gemv();

	print_mat(mA, MAT_COL_SIZE, MAT_ROW_SIZE);
	print_mat(vB, VEC_SIZE, 1);
	print_mat(sw_vC, VEC_OUT_SIZE, 1);

	// Compare results with software implementation
	for (err_cnt = 0, i=0; i<VEC_OUT_SIZE; i++) {
		if (hw_vC[i] != sw_vC[i]) err_cnt++;
	}
	return err_cnt;
}
