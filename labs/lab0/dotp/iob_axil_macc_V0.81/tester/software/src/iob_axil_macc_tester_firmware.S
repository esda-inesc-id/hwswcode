# SPDX-FileCopyrightText: 2025 IObundle
#
# SPDX-License-Identifier: MIT

#include "iob_axil_macc_tester_conf.h"
#include "iob_axil_macc_tester_mmap.h"

#define STACK_ADDR (IOB_AXIL_MACC_TESTER_FW_BASEADDR + (1 << IOB_AXIL_MACC_TESTER_FW_ADDR_W))

.section .init
.globl main

  //set stack pointer
  lui sp, %hi(STACK_ADDR)
  addi sp, sp, %lo(STACK_ADDR)

  //call main
  jal ra, main

  // Stop the processor
  ebreak
