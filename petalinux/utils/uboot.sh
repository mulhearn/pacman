#! /bin/bash

# RESET and boot linux kernel over JTAG 

xsct reset.tcl
petalinux-boot --jtag --fpga --u-boot
