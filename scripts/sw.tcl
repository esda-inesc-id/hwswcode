# Generate a PS-only XSA using the root design_1.tcl (no PL IP)

set proj_name "project_1"
set proj_dir  "sw_project"

create_project $proj_name $proj_dir -part xc7z010clg400-1 -force

source design_1.tcl

set bd_name "design_1"
generate_target all [get_files $proj_dir/$proj_name.srcs/sources_1/bd/$bd_name/$bd_name.bd]
make_wrapper -files [get_files $proj_dir/$proj_name.srcs/sources_1/bd/$bd_name/$bd_name.bd] -top
add_files -norecurse $proj_dir/$proj_name.gen/sources_1/bd/$bd_name/hdl/${bd_name}_wrapper.v

# Export SW-only platform (no bitstream)
write_hw_platform -fixed -force -file $proj_dir/${bd_name}_wrapper.xsa
