/**
 * @file gemm.c
 * @date May, 2022
 *
 * Support file for lab2 of Hardware-Software Co-Design 2022
 *
 * Contains routines related with General Matrix Multiplication kernel.
 */

void gemm(const float *A, const float *B, float *C, int rowsA, int colsA, int colsB) {
    for (int i = 0; i < rowsA; i++)
        for (int j = 0; j < colsB; j++) {
            C[i * colsB + j] = 0;
            for (int k = 0; k < colsA; k++)
                C[i * colsB + j] += A[i * colsA + k] * B[k * colsB + j];
        }
}

void gemmBT(const float *A, const float *BT, float *C, int rowsA, int colsA, int rowsBT) {
    for (int i = 0; i < rowsA; i++)
        for (int j = 0; j < rowsBT; j++) {
            C[i * rowsBT + j] = 0;
            for (int k = 0; k < colsA; k++)
                C[i * rowsBT + j] += A[i * colsA + k] * BT[j * colsA + k];
        }
}

void gemmBTCT(const float *A, const float *BT, float *CT, int rowsA, int colsA, int rowsBT) {
    for (int i = 0; i < rowsBT; i++)
        /*
         *          address         size
         * dma_send(BT + i * colsA, colsA);         dma_wait_for_complete();
         * dma_send(A,              rowsA * colsA); dma_wait_for_complete();
         * dma_recv(CT + i * rowsA, colsA);         dma_wait_for_complete();
         */
        for (int j = 0; j < rowsA; j++) {
            CT[i * rowsA + j] = 0;
            for (int k = 0; k < colsA; k++)
                CT[i * rowsA + j] += A[j * colsA + k] * BT[i * colsA + k];
        }
}

void transpose(const float *C, int rows, int cols, float *CT) {
    for (int i = 0; i < rows; i++)
        for (int j = 0; j < cols; j++)
            CT[j * rows + i] = C[i * cols + j];
}
