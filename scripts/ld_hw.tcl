# Loads an ELF onto the PS7. Initializes PS7, resets processor, and downloads ELF without running.
set app [lindex $argv 0]

connect

targets

targets 1

source ./app/_ide/psinit/ps7_init.tcl
if {[catch {ps7_init; ps7_post_config} err]} {
    puts "ERROR: ps7_init failed: $err"
    puts ">>> Try power cycling the board and re-running."
    exit 1
}

if {$app == "hwsw"} {
    puts "Programming FPGA with platform.bit..."
    targets -set -filter {name =~ "PL*"}
    fpga -file ./platform/hw/design_1_wrapper.bit
}

targets 2

rst -processor
dow ./app/Debug/app.elf

disconnect
