NAME=iob_axil_macc
CSR_IF ?=iob
BUILD_DIR_NAME=iob_axil_macc_V0.81
IS_FPGA=0

CONFIG_BUILD_DIR = $(dir $(lastword $(MAKEFILE_LIST)))
ifneq ($(wildcard $(CONFIG_BUILD_DIR)/custom_config_build.mk),)
include $(CONFIG_BUILD_DIR)/custom_config_build.mk
endif
