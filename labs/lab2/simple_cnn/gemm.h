#ifndef __GEMM_H__
#define __GEMM_H__

/**
 * Computes matrix multiplication using the GEMM kernel.
 * @param A Gathered matrix A
 * @param B Matrix B
 * @param C Output matrix
 * @param rowsA Rows of matrix A
 * @param colsA Columns of matrix A
 * @param colsB Columns of matrix B
 */
void gemm(const float *A, const float *B, float *C, int rowsA, int colsA, int colsB);

/**
 * Computes matrix multiplication using the GEMM kernel with second matrix transposed.
 * @param A Gathered matrix A
 * @param BT Matrix B transposed
 * @param C Output matrix
 * @param rowsA Rows of matrix A
 * @param colsA Columns of matrix A
 * @param rowsBT Rows of matrix B transposed (columns of matrix B)
 */
void gemmBT(const float *A, const float *BT, float *C, int rowsA, int colsA, int rowsBT);

/**
 * Computes matrix multiplication using the GEMM kernel with second matrix transposed.
 * and transposes the result.
 * @param A Gathered matrix A
 * @param BT Matrix B transposed
 * @param CT Output matrix (transposed)
 * @param rowsA Rows of matrix A
 * @param colsA Columns of matrix A
 * @param rowsBT Rows of matrix B transposed (columns of matrix B)
 */
void gemmBTCT(const float *A, const float *BT, float *CT, int rowsA, int colsA, int rowsBT);

/**
 * Transposes matrix.
 * @param C Input matrix
 * @param rows Rows of input matrix
 * @param cols Columns of input matrix
 * @param CT Output matrix (transposed input matrix)
 */
void transpose(const float *C, int rows, int cols, float *CT);

#endif // __GEMM_H__
