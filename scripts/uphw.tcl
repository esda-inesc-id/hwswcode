# Extract the project name and directory from the environment variables
set proj_name "project_1"
set proj_dir [file join $::env(PDIR) $proj_name]
puts [concat "Project directory: " $proj_dir]
set bd_name "design_1"

# Open the project
puts [file join $proj_dir "$proj_name.xpr"]
open_project [file join $proj_dir "$proj_name.xpr"]

# Regenerate output products for all IPs
report_ip_status
upgrade_ip [get_ips *]
generate_target all [get_files $proj_dir/$proj_name.srcs/sources_1/bd/$bd_name/$bd_name.bd]

# Launch synthesis
#reset_run synth_1
#launch_runs synth_1 -jobs 4
#wait_on_run synth_1

# Launch implementation
#launch_runs impl_1 -to_step write_bitstream -jobs 4
#wait_on_run impl_1

# Export the hardware platform (XSA)
write_hw_platform -fixed -include_bit -force -file [file join $proj_dir "${bd_name}\_wrapper.xsa"]
