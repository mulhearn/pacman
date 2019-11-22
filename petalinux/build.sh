#! /bin/bash
cd petalinux
petalinux-config --get-hw-description=../products/ --oldconfig
petalinux-build
petalinux-package --boot --force --fsbl ../products/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot
# if you want to append local files to rootfs, just add them to local/root:
source local/update.sh
cd ..
