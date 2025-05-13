#ifndef H_IOB_AXIL_MACC_CSRS_CSRS_H
#define H_IOB_AXIL_MACC_CSRS_CSRS_H

#include <stdint.h>

// used address space width
#define IOB_AXIL_MACC_CSRS_CSRS_ADDR_W 4

// Addresses
#define IOB_AXIL_MACC_CSRS_EN_ADDR 0
#define IOB_AXIL_MACC_CSRS_DONE_ADDR 1
#define IOB_AXIL_MACC_CSRS_LOAD_ADDR 2
#define IOB_AXIL_MACC_CSRS_A_ADDR 3
#define IOB_AXIL_MACC_CSRS_B_ADDR 4
#define IOB_AXIL_MACC_CSRS_C_ADDR 6
#define IOB_AXIL_MACC_CSRS_VERSION_ADDR 8

// Data widths (bit)
#define IOB_AXIL_MACC_CSRS_EN_W 8
#define IOB_AXIL_MACC_CSRS_DONE_W 8
#define IOB_AXIL_MACC_CSRS_LOAD_W 8
#define IOB_AXIL_MACC_CSRS_A_W 8
#define IOB_AXIL_MACC_CSRS_B_W 8
#define IOB_AXIL_MACC_CSRS_C_W 16
#define IOB_AXIL_MACC_CSRS_VERSION_W 16

// Base Address
void iob_axil_macc_csrs_init_baseaddr(uint32_t addr);

// IO read and write function prototypes
void iob_write(uint32_t addr, uint32_t data_w, uint32_t value);
uint32_t iob_read(uint32_t addr, uint32_t data_w);

// Core Setters and Getters
void iob_axil_macc_csrs_set_en(uint8_t value);
uint8_t iob_axil_macc_csrs_get_done();
void iob_axil_macc_csrs_set_load(uint8_t value);
void iob_axil_macc_csrs_set_a(uint8_t value);
void iob_axil_macc_csrs_set_b(uint8_t value);
uint16_t iob_axil_macc_csrs_get_c();
uint16_t iob_axil_macc_csrs_get_version();

#endif // H_IOB_AXIL_MACC_CSRS__CSRS_H
