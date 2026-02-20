
#extract env variables
set hls_top $env(HLS_TOP)
set hls_tb $env(HLS_TB)
set part $env(PART)
set hls_srcs [split $env(HLS_SRC) " "]

open_project hls_project
set_top $hls_top

#add each source file to the project
foreach src $hls_srcs {
    add_files $src
}
#add the testbench file
add_files -tb $hls_tb

#add the part to the project
open_solution "solution1"
set_part $part

#set the target clock period
create_clock -period 10 -name default

#simulate the design
csim_design
close_project
exit

