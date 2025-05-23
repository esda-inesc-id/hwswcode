# SPDX-FileCopyrightText: 2025 IObundle
#
# SPDX-License-Identifier: MIT

#include "iob_axil_macc_tester_conf.h"
#include "iob_axil_macc_tester_mmap.h"

// Can't include iob_bootrom_swreg.h because the assembler doesn't recognize stdint.h,
// so define the constants here instead (these are address offsets).
#define IOB_BOOTROM_ROM_ADDR 0x80

#define LENGTH ((1 << IOB_AXIL_MACC_TESTER_BOOTROM_ADDR_W) - IOB_BOOTROM_ROM_ADDR)
#define BOOTROM (BOOTROM_BASE + IOB_BOOTROM_ROM_ADDR)
#define BOOTLDR_ADDR ((1 << IOB_AXIL_MACC_TESTER_FW_ADDR_W) - (1 << IOB_AXIL_MACC_TESTER_BOOTROM_ADDR_W))

.section .init
.globl _start

_start:
  li x1, LENGTH
  li x2, BOOTROM
  li x3, BOOTLDR_ADDR

copy_loop:
  lw x4, 0(x2)
  sw x4, 0(x3)
  addi x2, x2, 4
  addi x3, x3, 4
  addi x1, x1, -4
  bne x1, x0, copy_loop

  // Jump to the bootloader
  li x5, BOOTLDR_ADDR
  jalr x0, 0(x5)
