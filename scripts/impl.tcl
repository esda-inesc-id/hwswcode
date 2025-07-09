
#extract hls src files, tb and part from command line arguments
set hls_top [lindex $argv 2]
set part [lindex $argv 4]
set hls_srcs [lrange $argv 5 end]

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

# implement and export the design
export_design -format ip_catalog -flow impl 

close_project
exit

