#get the project directory from the command line argument
set proj_dir [lindex $argv 0]

connect
targets 1
fpga -f $proj_dir/project_1/project_1.runs/impl_1/design_1_wrapper.bit
