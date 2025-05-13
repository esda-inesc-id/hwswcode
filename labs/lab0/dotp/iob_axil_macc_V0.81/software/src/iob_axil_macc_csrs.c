#include "iob_axil_macc_csrs.h"

// Base Address
static uint32_t base;
void iob_axil_macc_csrs_init_baseaddr(uint32_t addr) { base = addr; }

// Core Setters and Getters
void iob_axil_macc_csrs_set_en(uint8_t value) {
  iob_write(base + IOB_AXIL_MACC_CSRS_EN_ADDR, IOB_AXIL_MACC_CSRS_EN_W, value);
}

uint8_t iob_axil_macc_csrs_get_done() {
  return iob_read(base + IOB_AXIL_MACC_CSRS_DONE_ADDR,
                  IOB_AXIL_MACC_CSRS_DONE_W);
}

void iob_axil_macc_csrs_set_load(uint8_t value) {
  iob_write(base + IOB_AXIL_MACC_CSRS_LOAD_ADDR, IOB_AXIL_MACC_CSRS_LOAD_W,
            value);
}

void iob_axil_macc_csrs_set_a(uint8_t value) {
  iob_write(base + IOB_AXIL_MACC_CSRS_A_ADDR, IOB_AXIL_MACC_CSRS_A_W, value);
}

void iob_axil_macc_csrs_set_b(uint8_t value) {
  iob_write(base + IOB_AXIL_MACC_CSRS_B_ADDR, IOB_AXIL_MACC_CSRS_B_W, value);
}

uint16_t iob_axil_macc_csrs_get_c() {
  return iob_read(base + IOB_AXIL_MACC_CSRS_C_ADDR, IOB_AXIL_MACC_CSRS_C_W);
}

uint16_t iob_axil_macc_csrs_get_version() {
  return iob_read(base + IOB_AXIL_MACC_CSRS_VERSION_ADDR,
                  IOB_AXIL_MACC_CSRS_VERSION_W);
}
