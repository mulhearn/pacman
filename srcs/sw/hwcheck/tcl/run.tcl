# Set SDK workspace
setws .
# Build all projects
projects -build
# Connect to a remote hw_server
connect
# Select a target
targets -set -nocase -filter {name =~ "ARM*#0"}
# System Reset
rst -system
# Configure the FPGA
fpga hw1/zsys_wrapper.bit

source hw1/ps7_init.tcl
ps7_init
ps7_post_config
dow hwcheck/Debug/hwcheck.elf
con
