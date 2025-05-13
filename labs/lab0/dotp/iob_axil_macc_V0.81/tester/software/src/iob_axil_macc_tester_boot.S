# SPDX-FileCopyrightText: 2025 IObundle
#
# SPDX-License-Identifier: MIT

#include "iob_axil_macc_tester_conf.h"
#include "iob_axil_macc_tester_mmap.h"

.section .init
.globl main

  //set stack pointer
  lui sp, %hi(1 << IOB_AXIL_MACC_TESTER_FW_ADDR_W)
  addi sp, sp, %lo(1 << IOB_AXIL_MACC_TESTER_FW_ADDR_W)

  //call main
  jal ra, main

  // Jump to the firmware
  li x5, IOB_AXIL_MACC_TESTER_FW_BASEADDR
  jalr x0, 0(x5)
