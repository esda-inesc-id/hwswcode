#include <stdio.h>
#include <stdlib.h>

#include "axil_mat_prod1.h"

#define N1 4
#define N2 4
#define N3 4

static int matA[N1*N2];
static int matB[N2*N3];
static int matC[N1*N3];
static int matChw[N1*N3];

void axil_mat_prod1(int m1[MAX_MEM_SIZE], int m2[MAX_MEM_SIZE], int m3[MAX_MEM_SIZE], int rowsA, int rowsB, int rowsC);

void init_vecs()
{
	int i;

	for (i=0; i<(N1*N2); i++) {
		// Init vectors with 8-bit integer values
		matA[i] = ((rand() % 0xFF) - 0x80);
	}
	for (i=0; i<(N2*N3); i++) {
		// Init vectors with 8-bit integer values
		matB[i] = ((rand() % 0xFF) - 0x80);
	}
}

void read_vecs_from_file()
{
  FILE *fmats;

  // Open matrices file
  if ((fmats = fopen("m4.bin", "rb")) == NULL) {
    fprintf(stderr, "unable to open file <.bin>\n");
    exit(1);
  }
  // read matrices
  fread(matA, N1*N2, 4, fmats);
  fread(matB, N2*N3, 4, fmats);
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

void SW_dot_product()
{
	int i, j, k;
	for (i=0; i<N1; i++) {
		for (j=0; j<N3; j++) {
			for (k=0; k<N2; k++) {
				int mul = matA[i*N2+k] * matB[k*N3+j];
				if (k==0) matC[i*N3+j] = mul;
				else matC[i*N3+j] += mul;
			}
		}
	}
	printf("   sw dot product: %d\n", matC[7]);
}

void simul_HW_SW_dot_product()
{
	int i;

	axil_mat_prod1(matA, matB, matChw, N1, N2, N3);
	printf("sw/hw dot product: %d\n", matChw[7]);
}

int check_matC()
{
	int i, nerrors=0;

	for (i=0; i<(N1*N3); i++) {
		if (matC[i] != matChw[i]) nerrors++;
	}
	return nerrors;
}
int main()
{
//	init_vecs();
	read_vecs_from_file();

	print_mat(matA, N1, N2);
	print_mat(matB, N2, N3);

	SW_dot_product();
	simul_HW_SW_dot_product();

	print_mat(matC, N1, N3);
	print_mat(matChw, N1, N3);

	return (check_matC());
}
