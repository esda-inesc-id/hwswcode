
#extract hls src files, tb and part from command line arguments
set hls_top [lindex $argv 2]
set part [lindex $argv 3]
set hls_srcs [lrange $argv 4 end]

open_project hls_project
set_top $hls_top

#add each source file to the project
foreach src $hls_srcs {
    add_files $src
}

#add the part to the project
open_solution "solution1"
set_part $part

#set the target clock period
create_clock -period 10 -name default

#simulate the design
csynth_design
close_project
exit

