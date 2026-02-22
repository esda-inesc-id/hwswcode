# This script is used to run the application on the target hardware. It connects to the target, loads the
# application, and optionally waits for a GDB connection if the "-g" flag is provided in the command line arguments.


#real command line arguments
set args [lrange $argv 0 end]

#check if "gdb" is in the arguments
if {[lsearch -exact $args "-g"] != -1} {
    set gdb 1
} else {
    set gdb 0
}

connect

targets 1
source ./hwsw/_ide/psinit/ps7_init.tcl
ps7_init
ps7_post_config
#after 500

targets 2
rst -processor
dow ./hwsw/Debug/hwsw.elf

if {$gdb == 0} {
    con
} else {
    puts "GDB enabled. Waiting for GDB connection..."
    puts "Run 'arm-none-eabi-gdb ./hwsw/Debug/hwsw.elf' after this script exits."
    puts "Then connect to the target using 'target remote localhost:3000'."
    puts "Load the application with 'load'."
    puts "After loading, you list the code with 'list main'."
    puts "You can set breakpoints with 'break <line_number>' or 'break <function_name>'."
    puts "Press 'c' to continue execution, and explore other GDB commands as needed."
}


# If gdb is enabled, Open another terminal and run:
# > source /path/to/Vitis/settings64.sh
# > arm-none-eabi-gdb ./app/Debug/app.elf
