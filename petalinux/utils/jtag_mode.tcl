# Set SDK workspace
setws .
# Build all projects
#projects -build
# Connect to a remote hw_server
connect
# Select a target
targets -set -nocase -filter {name =~ "ARM*#0"}
# System Reset
rst -system
# Configure the FPGA
fpga ./images/linux/system.bit
# PS7 initialization
#namespace eval xsdb {source hw1/ps7_init.tcl; ps7_init}
# Download the elf
dow ../products/flash_fsbl.elf
# Resume the target
con
