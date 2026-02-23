# Makefile for HLS project and Vitis application
# Source the Vitis environment before running this Makefile
# Example: source /opt/Xilinx/Vitis/2024.2/settings64.sh
# Run the different targets as needed
# The cosim target will run synthesis, cosimulation, and export the IP
# The Vivado flow must be run separately: cetate a Vivado project and export the XSA file
# The app target will create the application and run it on the hardware

PDIR ?= exercises/iir
include $(PDIR)/init.mk

XSA=$(PDIR)/project_1/design_1_wrapper.xsa
IPZIP=hls_project/solution1/impl/export.zip
ELF=hwsw/Debug/hwsw.elf

all: run

#hls c simulation
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

#hls c implementation
impl: hls_project/solution1/syn/report/csynth.rpt
	HLS_TOP=$(HLS_TOP) PART=$(PART) HLS_SRC=$(HLS_SRC) vitis-run --mode hls --tcl scripts/impl.tcl

#hwsw app 
hwsw: $(ELF)

$(ELF): $(APP_SRC) $(XSA)
	make clean-sw && xsct scripts/hwsw.tcl $(XSA) $(APP_SRC)

#open picocom in another terminal to see the output:
picocom:
	picocom -b 115200 /dev/ttyUSB1 --imap lfcrlf

run: $(ELF)
	xsct scripts/run.tcl $(DEBUG)

$(XSA): $(IPZIP)
	PDIR=$(PDIR) PART=$(PART) vivado -mode batch -source scripts/uphw.tcl && \
	xsct scripts/ldhw.tcl $(PDIR)

clean-sw:
	@rm -rf platform hwsw *.log *.jou logs hwsw_* .analytics .metadata .Xil
	@find . -name \*~ -delete

clean: clean-sw
	@rm -rf hls_project $(PDIR)/hls/*.log $(PDIR)/hls/*.jou $(PDIR)/hls/solution* hls_project/solution1/syn/report/csynth.rpt hls_project/solution1/impl/export.zip $(PDIR)/project_1 ./app*
	@rm -f docs/lab_guides/*.aux docs/lab_guides/*.log docs/lab_guides/*.lof docs/lab_guides/*.lot docs/lab_guides/*.toc docs/lab_guides/*.bbl docs/lab_guides/*.blg

.PHONY: all csim csynth cosim ip impl run clean clean-sw picocom
