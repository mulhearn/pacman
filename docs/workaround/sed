#!/bin/sh

# Remove newlines if called by the silly Xilinx PetaLinux 2018.1 installer
if [ "$2" = "s/^.*minimal-\(.*\)-toolchain.*/\1/" ] ; then
	/bin/sed "$@" | tr '\n' ' '
else
	/bin/sed "$@"
fi
