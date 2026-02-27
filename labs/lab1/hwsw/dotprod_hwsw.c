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
}

void HW_SW_dot_product()
{
        int i;
        
        XAxil_macc Instance;
        XAxil_macc_Config *ConfigPtr;

        int status;

        printf("HW/SW dot product:\n");
        
        ConfigPtr = XAxil_macc_LookupConfig(XPAR_AXIL_MACC_0_DEVICE_ID);
        if (ConfigPtr == NULL) {
          printf("LookupConfig failed\n");
          return;
        }

        status = XAxil_macc_CfgInitialize(&Instance, ConfigPtr);
        if (status != XST_SUCCESS) {
          printf("CfgInitialize failed\n");
          return;
        }



        // intitialize (for i=0)
        XAxil_macc_Set_a(&Instance, v1[0]);
        XAxil_macc_Set_b(&Instance, v2[0]);
        XAxil_macc_Set_instr(&Instance, 0);
        XAxil_macc_Start(&Instance);

        XAxil_macc_Set_instr(&Instance, 1);
        for (i=1; i<VEC_SIZE; i++) {
          XAxil_macc_Set_a(&Instance, v1[i]);
          XAxil_macc_Set_b(&Instance, v2[i]);
          XAxil_macc_Start(&Instance);
        }
        vdotp2 = XAxil_macc_Get_c(&Instance);
        printf("sw/hw dot product: %d (%d)\n", vdotp2, XAxil_macc_Get_c_vld(&Instance));
}

int main()
{
	printf("   sw dot product: %d\n", vdotp1);

    /*
	init_vecs();
	print_vec(v1);
	print_vec(v2);

	SW_dot_product();
	HW_SW_dot_product();
    */
	return 0;
}
