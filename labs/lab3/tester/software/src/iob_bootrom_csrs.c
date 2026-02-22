#include "iob_bootrom_csrs.h"

// Base Address
static uint32_t base;
void iob_bootrom_csrs_init_baseaddr(uint32_t addr) { base = addr; }

// Core Setters and Getters
uint32_t iob_bootrom_csrs_get_rom() {
  return iob_read(base + IOB_BOOTROM_CSRS_ROM_ADDR, IOB_BOOTROM_CSRS_ROM_W);
}

uint16_t iob_bootrom_csrs_get_version() {
  return iob_read(base + IOB_BOOTROM_CSRS_VERSION_ADDR,
                  IOB_BOOTROM_CSRS_VERSION_W);
}
