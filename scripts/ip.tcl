
#extract env variables
set hls_top $env(HLS_TOP)
set part $env(PART)
set hls_srcs [split $env(HLS_SRC) " "]

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
export_design -format ip_catalog

close_project
exit

