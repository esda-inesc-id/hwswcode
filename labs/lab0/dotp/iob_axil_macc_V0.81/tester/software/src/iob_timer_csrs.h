#ifndef H_IOB_TIMER_CSRS_CSRS_H
#define H_IOB_TIMER_CSRS_CSRS_H

#include <stdint.h>

// used address space width
#define IOB_TIMER_CSRS_CSRS_ADDR_W 4

// Addresses
#define IOB_TIMER_CSRS_RESET_ADDR 0
#define IOB_TIMER_CSRS_ENABLE_ADDR 1
#define IOB_TIMER_CSRS_SAMPLE_ADDR 2
#define IOB_TIMER_CSRS_DATA_LOW_ADDR 4
#define IOB_TIMER_CSRS_DATA_HIGH_ADDR 8
#define IOB_TIMER_CSRS_VERSION_ADDR 12

// Data widths (bit)
#define IOB_TIMER_CSRS_RESET_W 8
#define IOB_TIMER_CSRS_ENABLE_W 8
#define IOB_TIMER_CSRS_SAMPLE_W 8
#define IOB_TIMER_CSRS_DATA_LOW_W 32
#define IOB_TIMER_CSRS_DATA_HIGH_W 32
#define IOB_TIMER_CSRS_VERSION_W 16

// Base Address
void iob_timer_csrs_init_baseaddr(uint32_t addr);

// IO read and write function prototypes
void iob_write(uint32_t addr, uint32_t data_w, uint32_t value);
uint32_t iob_read(uint32_t addr, uint32_t data_w);

// Core Setters and Getters
void iob_timer_csrs_set_reset(uint8_t value);
void iob_timer_csrs_set_enable(uint8_t value);
void iob_timer_csrs_set_sample(uint8_t value);
uint32_t iob_timer_csrs_get_data_low();
uint32_t iob_timer_csrs_get_data_high();
uint16_t iob_timer_csrs_get_version();

#endif // H_IOB_TIMER_CSRS__CSRS_H
