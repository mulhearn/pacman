#! /bin/bash
petalinux-package --boot --force --fsbl ../products/flash_fsbl.elf --fpga images/linux/system.bit --u-boot
