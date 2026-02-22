#include <stdio.h>
#include <stdlib.h>

#include "xparameters.h"
#include "xaxil_macc.h"

#define VEC_SIZE 10

static int v1[VEC_SIZE];
static int v2[VEC_SIZE];
static int vdotp1, vdotp2;

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

void HW_SW_dot_product()
{
        int i;
        int MACC_BASEADDR = 0x40000000;
        
        XAxil_macc Instance;
        XAxil_macc_Config *ConfigPtr;

        int status;

        // Lookup the config based on the device ID (usually 0 if only one instance)
        ConfigPtr = XAxil_macc_LookupConfig(MACC_BASEADDR);
        if (ConfigPtr == NULL) {
          return XST_FAILURE;
        }

        XAxil_macc_CfgInitialize(&Instance, ConfigPtr);
        if (status != XST_SUCCESS) {
          return XST_FAILURE;
        }


        
        volatile int *a = (int *)(MACC_BASEADDR + XAXIL_MACC_BUS1_ADDR_A_DATA);
        volatile int *b = (int *)(MACC_BASEADDR + XAXIL_MACC_BUS1_ADDR_B_DATA);
        volatile int *c = (int *)(MACC_BASEADDR + XAXIL_MACC_BUS1_ADDR_C_DATA);
        volatile int *c_vld = (int *)(MACC_BASEADDR + XAXIL_MACC_BUS1_ADDR_C_CTRL);
        volatile int *instr = (int *)(MACC_BASEADDR + XAXIL_MACC_BUS1_ADDR_INSTR_DATA);
        volatile int *do_macc = (int *)(MACC_BASEADDR + XAXIL_MACC_BUS1_ADDR_AP_CTRL);

        // intitialize (for i=0)
        *a = v1[0];  *b = v2[0];  *instr= 0;
        *do_macc = 1;

        *instr= 1;
        for (i=1; i<VEC_SIZE; i++) {
          XAxil_macc_Set_a(&Instance, v1[i]);
          // *a = v1[i];
          XAxil_macc_Set_b(&Instance, v2[i]);
          //*b = v2[i];
          XAxil_macc_Start(&Instance);
          //*do_macc = 1;
        }
        vdotp2 = *c;  // Here you could wait for *c_vld=1, in case of longer IP computations
        printf("sw/hw dot product: %d (%d)\n", vdotp2, *c_vld);
}

int main()
{
	init_vecs();
	print_vec(v1);
	print_vec(v2);

	SW_dot_product();
	HW_SW_dot_product();

	return 0;
}
