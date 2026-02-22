PART=xc7z010clg400-1
HLS_TOP=iir_filter
HLS_SRC=$(PDIR)/hls/iir.cpp
HLS_TB=$(PDIR)/hls/iir_tb.cpp
APP_SRC=$(PDIR)/hwsw/lscript.ld $(PDIR)/hwsw/iir.c
