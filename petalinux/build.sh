#! /bin/bash
petalinux-config --get-hw-description=../products/ --oldconfig
petalinux-build

petalinux-package --boot --force --fsbl ../products/pacman_fsbl.elf --fpga images/linux/system.bit --u-boot

# this version uses the vanilla Zynq FSBL:
#petalinux-package --boot --force --fsbl build/tmp/sysroots-components/plnx_zynq7/fsbl/boot/fsbl.elf --fpga images/linux/system.bit --u-boot

# if you want to append local files to rootfs, just add them to local/root:
source local/update.sh

echo "To test over JTAG, do:  xsct reset.tcl ; petalinux-boot --jtag --fpga --kernel"
