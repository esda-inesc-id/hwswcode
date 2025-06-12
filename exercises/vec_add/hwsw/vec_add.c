#include "xvector_add_hw.h"

#include "xil_cache.h"
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <xiltimer.h>
#include <xtimer_config.h>

#define DATA_SIZE 1024

#define A_BASE_ADDR  0x10000000
#define B_BASE_ADDR  0x10001000
#define C_BASE_ADDR  0x10002000

int main() {
  XTime tStart, tEnd;

  sleep(1);
  
  XVector_add_hw myAccel;
  XVector_add_hw_Config *cfg;

    // Lookup config and initialize
    cfg = XVector_add_hw_LookupConfig(0x40000000);
    if (!cfg) {
        printf("Error loading config\n");
        return -1;
    }

    if (XVector_add_hw_CfgInitialize(&myAccel, cfg) != XST_SUCCESS) {
        printf("Error initializing\n");
        return -1;
    }

    printf("Starting\n\n");

    // Initialize input arrays in DDR
    int *A = (int *)A_BASE_ADDR;
    int *B = (int *)B_BASE_ADDR;
    volatile int *C = (int *)C_BASE_ADDR;

    for (int i = 0; i < DATA_SIZE; i++) {
        A[i] = i;
        B[i] = 2 * i;
    }

    //Flush caches (if enabled)
    Xil_DCacheFlushRange((UINTPTR)A, DATA_SIZE * sizeof(int));
    Xil_DCacheFlushRange((UINTPTR)B, DATA_SIZE * sizeof(int));

    //start timer
    XTime_GetTime(&tStart);


    int Cref[DATA_SIZE];
    //compute vector addition in software
    for (int i = 0; i < DATA_SIZE; i++) {
      Cref[i] = A[i] + B[i];
    }
    
    //stop timer
    XTime_GetTime(&tEnd);
    
    // Calculate elapsed time in microseconds
    double elapsedTime = ((double)(tStart - tEnd)) * 1000000.0 / (COUNTS_PER_SECOND);

    printf("Software vector addition took %0.2f microseconds\n", elapsedTime);
   
    XTime_GetTime(&tStart);

    // Set parameters
    XVector_add_hw_Set_A(&myAccel, (u32)A_BASE_ADDR);  
    XVector_add_hw_Set_B(&myAccel, (u32)B_BASE_ADDR);
    XVector_add_hw_Set_C(&myAccel, (u32)C_BASE_ADDR);    
    XVector_add_hw_Set_size(&myAccel, DATA_SIZE);

    // Start accelerator
    XVector_add_hw_Start(&myAccel);

    // Wait for completion
    while (!XVector_add_hw_IsDone(&myAccel));
    
    XTime_GetTime(&tEnd);

    elapsedTime = ((double)(tStart - tEnd)) * 1000000.0 / (COUNTS_PER_SECOND);

    printf("Hardware vector addition took %0.2f microseconds\n", elapsedTime);

    
    // Invalidate output cache before reading
    //Xil_DCacheInvalidateRange((UINTPTR)C, DATA_SIZE * sizeof(int));

    // Check result
    int count = 0;    
    for (int i = 0; i < DATA_SIZE; i++) {
      if (C[i] != A[i]+B[i]) {
            printf("i=%d, %d %d %d\n", i, A[i], B[i], C[i]);       
            count++;
      }
    }
    
    for (int i = 0; i < 8; i++) {
        printf("A:%d/%d; B:%d/%d; C:%d/%d\n", A[i], i, B[i], 2*i, C[i], 3*i);
    }

    if (count != 0)   
        printf("Not good! Error = %d\n\n", count);
    else
        printf("Good!\n\n");
    
    int sz = XVector_add_hw_Get_size(&myAccel);
    printf("size %d\n\n", sz);

    XTime_GetTime(&tStart);
    sleep(1);
    XTime_GetTime(&tEnd);
    elapsedTime = ((double)(tEnd - tStart)) / ((COUNTS_PER_SECOND));

    printf("Final sleep took %0.4f seconds\n", elapsedTime);
    printf("count %d\n", (tEnd-tStart)) ;
    printf("counti %d\n", (tStart-tEnd)) ;

    printf("counts per second %d\n", COUNTS_PER_SECOND) ;       
    while(1);
}
