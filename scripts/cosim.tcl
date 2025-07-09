open_project hls_project
set_top iir_filter
add_files src/HLS/iir.cpp
add_files -tb src/HLS/iir_tb.cpp
open_solution "solution1"
set_part {xc7z010clg400-1} 
create_clock -period 10 -name default

csynth_design
#cosim_design -wave_debug -trace_level all
#export_design -format ip_catalog -flow impl 

close_project
exit
