# Extract the project name and directory from the environment variables
set proj_name "project_1"
set proj_dir [file join $::env(PDIR) $proj_name]
puts [concat "Project directory: " $proj_dir]
set bd_name "design_1"

# Create the project and source the block design
create_project $proj_name $proj_dir -part $::env(PART) -force
set_property ip_repo_paths [file normalize hls_project/solution1/impl/ip] [current_project]
update_ip_catalog
source [file join $::env(PDIR) "design_1.tcl"]

# Regenerate output products for all IPs
report_ip_status
set ips [get_ips *]
if {[llength $ips] > 0} { upgrade_ip $ips }
generate_target all [get_files $proj_dir/$proj_name.srcs/sources_1/bd/$bd_name/$bd_name.bd]

#generate hdl wrapper in verilog
make_wrapper -files [get_files $proj_dir/$proj_name.srcs/sources_1/bd/$bd_name/$bd_name.bd] -top
add_files -norecurse $proj_dir/$proj_name.gen/sources_1/bd/$bd_name/hdl/${bd_name}_wrapper.v

# Launch synthesis
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Launch implementation
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Export the hardware platform (XSA)
write_hw_platform -fixed -include_bit -force -file [file join $proj_dir "${bd_name}\_wrapper.xsa"]
