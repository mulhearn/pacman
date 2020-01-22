#! /bin/bash
cd petalinux
petalinux-config --get-hw-description=../products/ --oldconfig
petalinux-build
# the TE customized version is no longer working for me... reverting to petalinux version for now
#petalinux-package --boot --force --fsbl ../products/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot
petalinux-package --boot --force --fsbl build/tmp/sysroots-components/plnx_zynq7/fsbl/boot/fsbl.elf --fpga images/linux/system.bit --u-boot
# if you want to append local files to rootfs, just add them to local/root:
source local/update.sh
cd ..
