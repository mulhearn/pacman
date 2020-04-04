#! /bin/bash

# reset the board
xsct reset.tcl

# not working...
# boot linux kernel over JTAG 
# prebuild directory has FSBL that forces board to JTAG boot mode
#petalinux-boot --jtag --prebuilt 3

petalinux-boot --jtag --fpga --kernel
