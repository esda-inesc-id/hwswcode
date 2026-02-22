#include "axil_mat_prod1.h"

void axil_mat_prod1(int m1[MAX_MEM_SIZE], int m2[MAX_MEM_SIZE], int m3[MAX_MEM_SIZE], int N1, int N2, int N3)
{
#pragma HLS INTERFACE s_axilite port=return bundle=BUS1
#pragma HLS INTERFACE s_axilite port=m1 bundle=BUS1
#pragma HLS INTERFACE s_axilite port=m2 bundle=BUS1
#pragma HLS INTERFACE s_axilite port=m3 bundle=BUS1
#pragma HLS INTERFACE s_axilite port=N1 bundle=BUS1
#pragma HLS INTERFACE s_axilite port=N2 bundle=BUS1
#pragma HLS INTERFACE s_axilite port=N3 bundle=BUS1

	static int regc=0;
	int i, j, k;

	for (i=0, j=0, k=0; i<N1; ) {
#pragma HLS LOOP_TRIPCOUNT max=1000
#pragma HLS PIPELINE
		int mul = m1[i*N2+k] * m2[k*N3+j];
		if (k == 0) regc = mul;
		else regc += mul;
		k++;
		if (k == N2) {
			k = 0;
			m3[i*N3+j] = regc;
			j++;
			if (j == N3) { j = 0; i++; }
		}
	}
}
