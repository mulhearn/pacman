Getting started:

git clone <>
cd pacman


#
# Firmware:
#

# create the project:
# (first setup your vivado environment)
vivado -mode batch -source tcl/recreate.tcl

# sythesize, implement, write bitstream, and export hardware:
vivado -mode batch -source tcl/build.tcl

#
# Peta-Linux:
#
cd petalinux
petalinux-config --get-hw-description=../products/ --oldconfig
petalinux-build
petalinux-package --boot --force --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot

#
# Install:
#
From the petalinux/images/linux directory copy BOOT.bin and image.ub to the boot directory of TE0720



