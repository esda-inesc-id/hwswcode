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

csim: clean
	vitis_hls -f scripts/csim.tcl $(HLS_TOP) $(HLS_TB) $(PART) $(HLS_SRC)
# Run csim in gdb with the following command:
# > gdb ./hls_project/solution1/csim/build/csim.exe

csynth: clean
	vitis_hls -f scripts/csynth.tcl $(HLS_TOP) $(PART) $(HLS_SRC)

cosim:
	vitis_hls -f scripts/cosim.tcl

#app 
app: ./src/APP/iir.c
	make clean && xsct scripts/app.tcl

#open picocom in another terminal to see the output:
#picocom -b 115200 /dev/ttyUSB1 --imap lfcrlf

run: app
	xsct scripts/run.tcl gdb=$(GDB)

impl: cosim
	vitis_hls -nolog -run vivado -work_dir hls_component/hls_project

clean:
	@rm -rf platform app *.log *.jou logs app_* .analytics .metadata .Xil hls_project
	@find . -name \*~ -delete

