# Makefile for HLS project and Vitis application
# Source the Vitis environment before running this Makefile
# Example: source /opt/Xilinx/Vitis/2024.2/settings64.sh
# Run the different targets as needed
# The cosim target will run synthesis, cosimulation, and export the IP
# The Vivado flow must be run separately: cetate a Vivado project and export the XSA file
# The app target will create the application and run it on the hardware

PDIR ?= exercises/iir
include $(PDIR)/init.mk

all: run

#hls c simulation
csim:
	HLS_TOP=$(HLS_TOP) PART=$(PART) HLS_TB=$(HLS_TB) HLS_SRC=$(HLS_SRC) vitis-run --mode hls --tcl scripts/csim.tcl
# Run csim in gdb with the following command:
# > gdb ./hls_project/solution1/csim/build/csim.exe

#hls c synthesis
syn: hls_project/solution1/syn/report$/csynth.rpt

hls_project/solution1/syn/report$/csynth.rpt: $(HLS_SRC)
	 HLS_TOP=$(HLS_TOP) PART=$(PART) HLS_SRC=$(HLS_SRC) vitis-run --mode hls --tcl scripts/csynth.tcl

#hls c cosimulation
cosim:
	HLS_TOP=$(HLS_TOP) PART=$(PART) HLS_TB=$(HLS_TB) HLS_SRC=$(HLS_SRC) vitis-run --mode hls --tcl scripts/cosim.tcl

#hls c export ip
hls_project/solution1/impl/export.zip: hls_project/solution1/syn/report$/csynth.rpt
	HLS_TOP=$(HLS_TOP) PART=$(PART) HLS_SRC=$(HLS_SRC) vitis-run --mode hls --tcl scripts/ip.tcl

#hls c implementation
impl: hls_project/solution1/syn/report$/csynth.rpt
	HLS_TOP=$(HLS_TOP) PART=$(PART) HLS_SRC=$(HLS_SRC) vitis-run --mode hls --tcl scripts/impl.tcl

#app 
app: $(APP_SRC) $(XSA)
	make clean-sw && xsct scripts/app.tcl $(XSA) $(APP_SRC)

#open picocom in another terminal to see the output:
#picocom -b 115200 /dev/ttyUSB1 --imap lfcrlf

run: app
	xsct scripts/run.tcl $(DEBUG)

$(XSA): hls_project/solution1/impl/export.zip 
	PDIR=$(PDIR) vivado -mode batch -source scripts/uphw.tcl && \
	xsct scripts/ldhw.tcl $(PDIR)

clean-sw:
	@rm -rf platform app *.log *.jou logs app_* .analytics .metadata .Xil
	@find . -name \*~ -delete

clean: clean-sw
	@rm -rf hls_project
	@cd $(PDIR)/project_1 && find . -mindepth 1 ! -name 'project_1.xpr' ! -name 'project_1.srcs' ! -path 'project_1.srcs' -exec rm -rf {} +

.PHONY: all csim csynth cosim ip impl app run clean clean-sw
