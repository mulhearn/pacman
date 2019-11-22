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
# PS7 initialization
namespace eval xsdb {source hw1/ps7_init.tcl; ps7_init}
# Download the elf
dow bareapp/Debug/bareapp.elf
# Insert a breakpoint @ main
bpadd -addr &main
# Continue execution until the target is suspended
con -block -timeout 500
# Print the target registers
puts [rrd]
# Resume the target
con
