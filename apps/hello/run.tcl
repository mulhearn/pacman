# Set SDK workspace
setws .
# Build 
# app build bareapp
# Connect to a remote hw_server
connect
# Select a target
targets -set -nocase -filter {name =~ "ARM*#0"}
# System Reset
rst -system
# Configure the FPGA
fpga  zsys_wrapper/hw/zsys_wrapper.bit

# PS7 initialization
source pacman/hw/ps7_init.tcl
ps7_init
ps7_post_config
dow bareapp/Debug/bareapp.elf
con

