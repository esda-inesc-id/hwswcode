# Makefile for HLS project and Vitis application
# Source the Vitis environment before running this Makefile
# Example: source /opt/Xilinx/Vitis/2024.2/settings64.sh
# Run the different targets as needed
# The cosim target will run synthesis, cosimulation, and export the IP
# The Vivado flow must be run separately: cetate a Vivado project and export the XSA file
# The app target will create the application and run it on the hardware

PDIR ?= exercises/iir
#PDIR ?= labs/lab1
include $(PDIR)/init.mk

PC_DIR  := $(if $(wildcard $(PDIR)/pc),$(PDIR)/pc,$(PDIR)/sw)
PC_SRCS := $(wildcard $(PC_DIR)/*.c)

SW_XSA  := design_1_wrapper.xsa
HWSW_XSA  := $(PDIR)/project_1/design_1_wrapper.xsa

SW_SRCS   := $(wildcard $(PDIR)/sw/lscript.ld $(PDIR)/sw/*.c)
HWSW_SRCS := $(wildcard $(PDIR)/hwsw/lscript.ld $(PDIR)/hwsw/*.c)

ifeq ($(APP),hwsw)
	SRCS := $(HWSW_SRCS)
	XSA  := $(HWSW_XSA)
else
	SRCS := $(SW_SRCS)
	XSA  := $(SW_XSA)
endif

IPZIP=hls_project/solution1/impl/export.zip
ELF  = app/Debug/app.elf

USB ?= 2

all: run-hwsw

#desktop application (uses pc/ if present, otherwise sw/)
pc_app: $(PC_SRCS)
	gcc -o pc_app $^
	./pc_app


csim:
	HLS_TOP=$(HLS_TOP) PART=$(PART) HLS_TB=$(HLS_TB) HLS_SRC=$(HLS_SRC) vitis-run --mode hls --tcl scripts/csim.tcl
# Run csim in gdb with the following command:
# > gdb ./hls_project/solution1/csim/build/csim.exe

#hls c synthesis
csynth: hls_project/solution1/syn/report/csynth.rpt

hls_project/solution1/syn/report/csynth.rpt: $(HLS_SRC)
	 HLS_TOP=$(HLS_TOP) PART=$(PART) HLS_SRC=$(HLS_SRC) vitis-run --mode hls --tcl scripts/csynth.tcl

#hls c cosimulation
cosim:
	HLS_TOP=$(HLS_TOP) PART=$(PART) HLS_TB=$(HLS_TB) HLS_SRC=$(HLS_SRC) vitis-run --mode hls --tcl scripts/cosim.tcl

#hls c export ip
ip: $(IPZIP)
$(IPZIP): hls_project/solution1/syn/report/csynth.rpt
	HLS_TOP=$(HLS_TOP) PART=$(PART) HLS_SRC=$(HLS_SRC) vitis-run --mode hls --tcl scripts/ip.tcl

#hls ip implementation
impl: hls_project/solution1/syn/report/csynth.rpt
	HLS_TOP=$(HLS_TOP) PART=$(PART) HLS_SRC=$(HLS_SRC) vitis-run --mode hls --tcl scripts/impl.tcl

#vivado export xsa
hwsw_xsa: $(HWSW_XSA)
$(HWSW_XSA): $(IPZIP)
	PDIR=$(PDIR) PART=$(PART) vivado -mode batch -source scripts/hwsw_xsa.tcl

#sw-only embedded app (no IP, uses pre-built XSA at root)
elf: $(ELF)
$(ELF): $(SRCS) $(XSA)
	xsct scripts/app.tcl $(XSA) $(SRCS)

ld-hw: $(XSA) $(ELF)
	xsct scripts/ld_hw.tcl

#open picocom in another terminal to see the output:
picocom:
	picocom -b 115200 /dev/ttyUSB$(USB) --imap lfcrlf

run: ld-hw
	sleep 2 && xsct scripts/run.tcl $(DEBUG)

clean-sw:
	@rm -rf platform app app_system *.log *.jou logs .analytics .metadata .Xil
	@find . -name \*~ -delete

clean: clean-sw
	@rm -rf hls_project $(PDIR)/hls/*.log $(PDIR)/hls/*.jou $(PDIR)/hls/solution* hls_project/solution1/syn/report/csynth.rpt hls_project/solution1/impl/export.zip $(PDIR)/project_1 ./app*
	@rm -f docs/lab_guides/*.aux docs/lab_guides/*.log docs/lab_guides/*.lof docs/lab_guides/*.lot docs/lab_guides/*.toc docs/lab_guides/*.bbl docs/lab_guides/*.blg

board-power-off:
	sudo uhubctl -l 1-13 -p 3 -a off

board-power-on:
	sudo uhubctl -l 1-13 -p 3 -a on

board-power-cycle:
	sudo uhubctl -l 1-13 -p 3 -a cycle

.PHONY: all csim csynth cosim impl run clean clean-sw picocom pc_app ld-hw board-power-off board-power-on board-power-cycle
