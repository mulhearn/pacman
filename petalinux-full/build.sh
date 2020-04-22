#! /bin/bash

petalinux-config --get-hw-description=../products/ --oldconfig
petalinux-build
# For reliable JTAG booting, this version uses flash-writing FSBL which selects JTAG mode:
petalinux-package --boot --force --fsbl ../products/flash_fsbl.elf --fpga images/linux/system.bit --u-boot
petalinux-package --prebuilt --force

# next build the standard version:
petalinux-package --boot --force --fsbl ../products/pacman_fsbl.elf --fpga images/linux/system.bit --u-boot

# this unused version uses the vanilla Zynq FSBL:
#petalinux-package --boot --force --fsbl build/tmp/sysroots-components/plnx_zynq7/fsbl/boot/fsbl.elf --fpga images/linux/system.bit --u-boot

