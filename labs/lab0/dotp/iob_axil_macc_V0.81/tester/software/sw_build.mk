# SPDX-FileCopyrightText: 2025 IObundle
#
# SPDX-License-Identifier: MIT

#########################################
#            Embedded targets           #
#########################################
ROOT_DIR ?=..

include $(ROOT_DIR)/software/auto_sw_build.mk

# Local embedded makefile settings for custom bootloader and firmware targets.

#Function to obtain parameter named $(1) in verilog header file located in $(2)
#Usage: $(call GET_MACRO,<param_name>,<vh_path>)
GET_MACRO = $(shell grep "define $(1)" $(2) | rev | cut -d" " -f1 | rev)

#Function to obtain parameter named $(1) from iob_axil_macc_tester_conf.vh
GET_IOB_AXIL_MACC_TESTER_CONF_MACRO = $(call GET_MACRO,IOB_AXIL_MACC_TESTER_$(1),../src/iob_axil_macc_tester_conf.vh)

iob_axil_macc_tester_bootrom.hex: ../../software/iob_axil_macc_tester_preboot.bin ../../software/iob_axil_macc_tester_boot.bin
	../../scripts/makehex.py $^ 00000080 $(call GET_IOB_AXIL_MACC_TESTER_CONF_MACRO,BOOTROM_ADDR_W) $@

iob_axil_macc_tester_firmware.hex: iob_axil_macc_tester_firmware.bin
	../../scripts/makehex.py $< $(call GET_IOB_AXIL_MACC_TESTER_CONF_MACRO,MEM_ADDR_W) $@
	../../scripts/makehex.py --split $< $(call GET_IOB_AXIL_MACC_TESTER_CONF_MACRO,MEM_ADDR_W) $@

iob_axil_macc_tester_firmware.bin: ../../software/iob_axil_macc_tester_firmware.bin
	cp $< $@

../../software/%.bin:
	make -C ../../ sw-build

UTARGETS+=build_iob_axil_macc_tester_software tb
CSRS=./src/iob_uart_csrs.c

TEMPLATE_LDS=src/$@.lds

IOB_AXIL_MACC_TESTER_INCLUDES=-Isrc

IOB_AXIL_MACC_TESTER_LFLAGS=-Wl,-L,src,-Bstatic,-T,$(TEMPLATE_LDS),--strip-debug

# FIRMWARE SOURCES
IOB_AXIL_MACC_TESTER_FW_SRC=src/iob_axil_macc_tester_firmware.S
IOB_AXIL_MACC_TESTER_FW_SRC+=src/iob_axil_macc_tester_firmware.c
IOB_AXIL_MACC_TESTER_FW_SRC+=src/iob_printf.c
# PERIPHERAL SOURCES
DRIVERS=$(addprefix src/,$(addsuffix .c,$(PERIPHERALS)))
# Only add driver files if they exist
IOB_AXIL_MACC_TESTER_FW_SRC+=$(foreach file,$(DRIVERS),$(wildcard $(file)*))
IOB_AXIL_MACC_TESTER_FW_SRC+=$(addprefix src/,$(addsuffix _csrs.c,$(PERIPHERALS)))

# BOOTLOADER SOURCES
IOB_AXIL_MACC_TESTER_BOOT_SRC+=src/iob_axil_macc_tester_boot.S
IOB_AXIL_MACC_TESTER_BOOT_SRC+=src/iob_axil_macc_tester_boot.c
IOB_AXIL_MACC_TESTER_BOOT_SRC+=src/iob_uart.c
IOB_AXIL_MACC_TESTER_BOOT_SRC+=src/iob_uart_csrs.c

# PREBOOT SOURCES
IOB_AXIL_MACC_TESTER_PREBOOT_SRC=src/iob_axil_macc_tester_preboot.S

build_iob_axil_macc_tester_software: iob_axil_macc_tester_firmware iob_axil_macc_tester_boot iob_axil_macc_tester_preboot

ifneq ($(USE_FPGA),)
WRAPPER_CONFS_PREFIX=iob_axil_macc_tester_$(BOARD)
else
WRAPPER_CONFS_PREFIX=iob_uut
endif

iob_bsp:
	sed 's/$(WRAPPER_CONFS_PREFIX)/IOB_BSP/Ig' src/$(WRAPPER_CONFS_PREFIX)_conf.h > src/iob_bsp.h

iob_axil_macc_tester_firmware: iob_bsp
	make $@.elf INCLUDES="$(IOB_AXIL_MACC_TESTER_INCLUDES)" LFLAGS="$(IOB_AXIL_MACC_TESTER_LFLAGS) -Wl,-Map,$@.map" SRC="$(IOB_AXIL_MACC_TESTER_FW_SRC)" TEMPLATE_LDS="$(TEMPLATE_LDS)"

iob_axil_macc_tester_boot: iob_bsp
	make $@.elf INCLUDES="$(IOB_AXIL_MACC_TESTER_INCLUDES)" LFLAGS="$(IOB_AXIL_MACC_TESTER_LFLAGS) -Wl,-Map,$@.map" SRC="$(IOB_AXIL_MACC_TESTER_BOOT_SRC)" TEMPLATE_LDS="$(TEMPLATE_LDS)"

iob_axil_macc_tester_preboot:
	make $@.elf INCLUDES="$(IOB_AXIL_MACC_TESTER_INCLUDES)" LFLAGS="$(IOB_AXIL_MACC_TESTER_LFLAGS) -Wl,-Map,$@.map" SRC="$(IOB_AXIL_MACC_TESTER_PREBOOT_SRC)" TEMPLATE_LDS="$(TEMPLATE_LDS)" NO_HW_DRIVER=1


.PHONY: build_iob_axil_macc_tester_software iob_bsp iob_axil_macc_tester_firmware iob_axil_macc_tester_boot iob_axil_macc_tester_preboot

#########################################
#         PC emulation targets          #
#########################################
# Local pc-emul makefile settings for custom pc emulation targets.
EMUL_HDR+=iob_bsp

# SOURCES
EMUL_SRC+=src/iob_axil_macc_tester_firmware.c
EMUL_SRC+=src/iob_printf.c

# PERIPHERAL SOURCES
EMUL_SRC+=$(addprefix src/,$(addsuffix .c,$(PERIPHERALS)))
EMUL_SRC+=$(addprefix src/,$(addsuffix _csrs_pc_emul.c,$(PERIPHERALS)))

