/*
 * dma_int_gemv.c
 *
 *  Created on: 12/04/2018
 *      Author: hcn
 */

/******************************************************************************
 * Matrix-Vector Multiplication DMA Example
 *
 * Based on Xilinx xaxidma_example_simple_poll.c example,
 * which demonstrates how to use the xaxidma driver on the Xilinx AXI
 * DMA core (AXIDMA) to transfer packets in polling mode when the AXI DMA core
 * is configured in simple mode.
 * ***************************************************************************
 */
/***************************** Include Files *********************************/
#include "xaxidma.h"
#include "xparameters.h"

#include <stdio.h>
#include "xtime_l.h"
//#include "xil_mmu.h"
#include "xil_cache.h"
//#include "xil_cache_l.h"

/******************** Constant Definitions **********************************/

/* Device hardware build related constants. */
#define DMA_DEV_ID		XPAR_AXIDMA_0_DEVICE_ID

/* Program constants */
#define MAT_SIZE 25

#define N1 MAT_SIZE
#define N2 MAT_SIZE
#define N3 1

volatile int *memA;   // matA N1xN2
volatile int *memB;   // matB N2xN3
volatile int *memC;   // matChw N1xN3
volatile int *memCsw; // matCsw N1xN3

#define MEMA(I,J) (memA[(I)*N2+(J)])
#define MEMB(I)   (memB[(I)])
#define MEMC(I)   (memC[(I)])
#define MEMCSW(I) (memCsw[(I)])

#define MATA_START_ADD 0x10000000
#define MATB_START_ADD (MATA_START_ADD+4*N1*N2)
#define MATC_START_ADD (MATA_START_ADD+4*N1*N2+4*N2)
#define SW_MATC_START_ADD (MATA_START_ADD+4*N1*N2+4*N2+4*N2)

#define MATA_SIZE_IN_BYTES (N1*N2*4)
#define VECB_SIZE_IN_BYTES (N2*4)
#define VECC_SIZE_IN_BYTES (N1*4)

#define CHECK_RESULT 1
#define DO_SW 1

/************************** Function Prototypes ******************************/

int XAxiDma_Simple_GEMV(u16 DeviceId);
int init_XAxiDma_SimplePollMode(u16 DeviceId);


/************************** Variable Definitions *****************************/
/*
 * Device instance definitions
 */
XAxiDma AxiDma;


/*****************************************************************************/
/*
* The entry point for this example. It invokes the example function,
* and reports the execution status.
*
* @param	None.
*
* @return
*		- XST_SUCCESS if example finishes successfully
*		- XST_FAILURE if example fails.
*
* @note		None.
*
******************************************************************************/
int main()
{
  int Status;

  // Xil_DCacheDisable();

  /* Init DMA in poll mode for simple transfer */
  Status = init_XAxiDma_SimplePollMode(DMA_DEV_ID);
  if (Status != XST_SUCCESS) {
    printf("init_XAxiDma_SimplePollMode: Failed\r\n");
    return XST_FAILURE;
  }

  Status = XAxiDma_Simple_GEMV(DMA_DEV_ID);
  if (Status != XST_SUCCESS) {
    printf("XAxiDma_Simple_GEMV: Failed\r\n");
    return XST_FAILURE;
  }

  return XST_SUCCESS;
}

void print_mat(int *x, int colsize, int rowsize, int firstrow)
{
  int i, j;

  for (i=firstrow-1; i<colsize; i++) {
    for (j=0; j<rowsize; j++) {
      printf("%d ", x[i*rowsize+j]);
    }
    printf("\n");
  }
  printf("\n");
}


void sw_gemv()
{
	memCsw = (int *)(SW_MATC_START_ADD);
	for (int i=0; i<N1; i++) {
		MEMCSW(i) = 0;
		for (int k=0; k<N2; k++) {
			MEMCSW(i) += MEMA(i,k)*MEMB(k);
		}
	}
}

// Verifies for HW errors
int check_hw_errors()
{
	int err_cnt = 0;
	for (int i=0; i < N1*N3; i++) {
		if (MEMC(i) != MEMCSW(i)) {
			err_cnt++;
			printf("%d: %d != %d\n", i, MEMC(i), MEMCSW(i));
		}
		if (err_cnt > 20) { printf("more than 10 errors, finishing check\n"); break; }
	}
	return err_cnt;
}


int init_XAxiDma_SimplePollMode(u16 DeviceId)
{
  XAxiDma_Config *CfgPtr;
  int Status;

  /* Initialize the XAxiDma device.	 */
  CfgPtr = XAxiDma_LookupConfig(DeviceId);
  if (!CfgPtr) {
    printf("No config found for %d\r\n", DeviceId);
    return XST_FAILURE;
  }

  Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);
  if (Status != XST_SUCCESS) {
    printf("Initialization failed %d\r\n", Status);
    return XST_FAILURE;
  }

  if(XAxiDma_HasSg(&AxiDma)){
    printf("Device configured as SG mode \r\n");
    return XST_FAILURE;
  }

  /* Disable interrupts, we use polling mode	 */
  XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
  XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);

  return XST_SUCCESS;
}

int XAxiDma_Simple_GEMV(u16 DeviceId)
{
	int Status;
	int *TxBufferPtr, *RxBufferPtr;
	XTime tStart, tEnd;

	memA = (int *)(MATA_START_ADD);
	memB = (int *)(MATB_START_ADD);
	memC = (int *)(MATC_START_ADD);

	// print_mat((int *)memA,N1,N2,1);
	// print_mat((int *)memB,N2,1,1);

	// flush matrix A and vector B to external memory
	Xil_DCacheFlushRange((INTPTR)(memB), (unsigned)(4*N2*N3));
	Xil_DCacheFlushRange((INTPTR)(memA), (unsigned)(4*N2*N1));

	XTime_GetTime(&tStart);

	// program DMA to send vector B
	TxBufferPtr = (int *)memB;
	Status = XAxiDma_SimpleTransfer(&AxiDma,(UINTPTR) TxBufferPtr,
			VECB_SIZE_IN_BYTES, XAXIDMA_DMA_TO_DEVICE);
	if (Status != XST_SUCCESS) { return XST_FAILURE; }
	while (XAxiDma_Busy(&AxiDma, XAXIDMA_DMA_TO_DEVICE)) { /* Wait for Tx*/ }

	// program DMA to receive vector C
	RxBufferPtr = (int *)memC;
	Status = XAxiDma_SimpleTransfer(&AxiDma,(UINTPTR) (RxBufferPtr),
			VECC_SIZE_IN_BYTES, XAXIDMA_DEVICE_TO_DMA);
	if (Status != XST_SUCCESS) { return XST_FAILURE; }

	// program DMA to send full matrix A
	TxBufferPtr = (int *)memA;
	Status = XAxiDma_SimpleTransfer(&AxiDma,(UINTPTR) TxBufferPtr,
			MATA_SIZE_IN_BYTES, XAXIDMA_DMA_TO_DEVICE);
	if (Status != XST_SUCCESS) { return XST_FAILURE; }
	while (XAxiDma_Busy(&AxiDma,XAXIDMA_DMA_TO_DEVICE)) { /* Wait Tx */ }

	while (XAxiDma_Busy(&AxiDma,XAXIDMA_DEVICE_TO_DMA)) { /* Wait Rx*/ }

	XTime_GetTime(&tEnd);

	// Invalidate Cache Range to force reading vector C from external memory
	Xil_DCacheInvalidateRange((INTPTR)(memC), (unsigned)(4*N1));

	//	print_mat((int *)memC,N1,1,1);

	printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
	printf("Output took %.3f us.\n", 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND) * 1000000);

#if DO_SW
	XTime_GetTime(&tStart);
	sw_gemv();
	XTime_GetTime(&tEnd);
	printf("SW Output took %llu clock cycles.\n", 2*(tEnd - tStart));
	printf("SW Output took %.3f us.\n",
			1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND) * 1000000);
#endif

#if CHECK_RESULT
	printf("(%d %d %d) Number of result errors = %d\n", N1, N2, N3, check_hw_errors());
#endif

  return XST_SUCCESS;
}

