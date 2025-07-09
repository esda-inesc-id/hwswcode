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
csim: clean
	vitis_hls -f scripts/csim.tl $(HLS_TOP) $(HLS_TB) $(PART) $(HLS_SRC)
# Run csim in gdb with the following command:
# > gdb ./hls_project/solution1/csim/build/csim.exe

#hls c synthesis
csynth: clean
	vitis_hls -f scripts/csynth.tcl $(HLS_TOP) $(PART) $(HLS_SRC)

#hls c cosimulation
cosim:
	vitis_hls -f scripts/cosim.tcl $(HLS_TOP) $(HLS_TB) $(PART) $(HLS_SRC)

#hls c export ip
ip: csynth
	vitis_hls -f scripts/ip.tcl $(HLS_TOP) $(PART) $(HLS_SRC)

#hls c implementation
impl: csynth
	vitis_hls -f scripts/impl.tcl $(HLS_TOP) $(PART) $(HLS_SRC)

#app 
app: $(APP_SRC) $(XSA)
	make clean-sw && xsct scripts/app.tcl $(XSA) $(APP_SRC)

#open picocom in another terminal to see the output:
#picocom -b 115200 /dev/ttyUSB1 --imap lfcrlf

run: app
	xsct scripts/run.tcl $(DEBUG)

$(XSA): hls_project/solution1/solution1.log
	PDIR=$(PDIR) vivado -mode batch -source scripts/uphw.tcl && \
	xsct scripts/ldhw.tcl $(PDIR)

clean-sw:
	@rm -rf platform app *.log *.jou logs app_* .analytics .metadata .Xil
	@find . -name \*~ -delete

clean: clean-sw
	@rm -rf hls_project
