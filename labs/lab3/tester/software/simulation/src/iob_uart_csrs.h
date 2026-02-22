#ifndef H_IOB_UART_CSRS_CSRS_H
#define H_IOB_UART_CSRS_CSRS_H

#include <stdint.h>

// used address space width
#define IOB_UART_CSRS_CSRS_ADDR_W 3

// Addresses
#define IOB_UART_CSRS_SOFTRESET_ADDR 0
#define IOB_UART_CSRS_DIV_ADDR 2
#define IOB_UART_CSRS_TXDATA_ADDR 4
#define IOB_UART_CSRS_TXEN_ADDR 5
#define IOB_UART_CSRS_RXEN_ADDR 6
#define IOB_UART_CSRS_TXREADY_ADDR 0
#define IOB_UART_CSRS_RXREADY_ADDR 1
#define IOB_UART_CSRS_RXDATA_ADDR 4
#define IOB_UART_CSRS_VERSION_ADDR 6

// Data widths (bit)
#define IOB_UART_CSRS_SOFTRESET_W 8
#define IOB_UART_CSRS_DIV_W 16
#define IOB_UART_CSRS_TXDATA_W 8
#define IOB_UART_CSRS_TXEN_W 8
#define IOB_UART_CSRS_RXEN_W 8
#define IOB_UART_CSRS_TXREADY_W 8
#define IOB_UART_CSRS_RXREADY_W 8
#define IOB_UART_CSRS_RXDATA_W 8
#define IOB_UART_CSRS_VERSION_W 16

// Base Address
void iob_uart_csrs_init_baseaddr(uint32_t addr);

// IO read and write function prototypes
void iob_write(uint32_t addr, uint32_t data_w, uint32_t value);
uint32_t iob_read(uint32_t addr, uint32_t data_w);

// Core Setters and Getters
void iob_uart_csrs_set_softreset(uint8_t value);
void iob_uart_csrs_set_div(uint16_t value);
void iob_uart_csrs_set_txdata(uint8_t value);
void iob_uart_csrs_set_txen(uint8_t value);
void iob_uart_csrs_set_rxen(uint8_t value);
uint8_t iob_uart_csrs_get_txready();
uint8_t iob_uart_csrs_get_rxready();
uint8_t iob_uart_csrs_get_rxdata();
uint16_t iob_uart_csrs_get_version();

#endif // H_IOB_UART_CSRS__CSRS_H
