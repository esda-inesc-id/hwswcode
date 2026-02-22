#include <stdio.h>
#include <stdlib.h>

#define VEC_SIZE 10

static int v1[VEC_SIZE];
static int v2[VEC_SIZE];
static int vdotp1, vdotp2;

void axil_macc(int *a, int *b, int *c, int *instr);

void init_vecs()
{
	int i;

	for (i=0; i<VEC_SIZE; i++) {
		// Init vectors with 8-bit integer values
		v1[i] = ((rand() % 0xFF) - 0x80);
		v2[i] = ((rand() % 0xFF) - 0x80);
	}
}

void print_vec(int *x)
{
	int i;
	for (i=0; i<VEC_SIZE; i++) {
    	printf("%5d ", x[i]);
	}
	printf("\n");
}

void SW_dot_product()
{
	int i;
	for (vdotp1=0, i=0; i<VEC_SIZE; i++) {
		vdotp1 += v1[i]*v2[i];
	}
	printf("   sw dot product: %d\n", vdotp1);
}

void simul_HW_SW_dot_product()
{
	int i;
	int a, b, c, instr;

	for (i=0; i<VEC_SIZE; i++) {
		a = v1[i];
		b = v2[i];
		instr = i;
		axil_macc(&a, &b, &c, &instr);
	}
	vdotp2 = c;
	printf("sw/hw dot product: %d\n", vdotp2);
}

int main()
{
	init_vecs();
	print_vec(v1);
	print_vec(v2);

	SW_dot_product();
	simul_HW_SW_dot_product();
	return (vdotp1 != vdotp2);
}
