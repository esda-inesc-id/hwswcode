#ifndef H_IOB_BOOTROM_CSRS_CSRS_H
#define H_IOB_BOOTROM_CSRS_CSRS_H

#include <stdint.h>

// used address space width
#define IOB_BOOTROM_CSRS_CSRS_ADDR_W 13

// Addresses
#define IOB_BOOTROM_CSRS_ROM_ADDR 0
#define IOB_BOOTROM_CSRS_VERSION_ADDR 4096

// Data widths (bit)
#define IOB_BOOTROM_CSRS_ROM_W 32
#define IOB_BOOTROM_CSRS_VERSION_W 16

// Base Address
void iob_bootrom_csrs_init_baseaddr(uint32_t addr);

// IO read and write function prototypes
void iob_write(uint32_t addr, uint32_t data_w, uint32_t value);
uint32_t iob_read(uint32_t addr, uint32_t data_w);

// Core Setters and Getters
uint32_t iob_bootrom_csrs_get_rom(int addr);
uint16_t iob_bootrom_csrs_get_version();

#endif // H_IOB_BOOTROM_CSRS__CSRS_H
