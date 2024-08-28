# Set SDK workspace
setws .
# Build 
# app build bareapp
# Connect to a remote hw_server
connect
# Select a target
targets -set -nocase -filter {name =~ "ARM*#0"}

# From petatlinux config file:
# CONFIG_SUBSYSTEM_UBOOT_DEVICETREE_OFFSET="0x100000"

set DEVICETREE_OFFSET 0x100000
dow -data "../petalinux/trenz/images/linux/system.dtb" ${DEVICETREE_OFFSET}

dow "../petalinux/trenz/images/linux/u-boot.elf"

dow -data  "../petalinux/trenz/images/linux/image.ub" 0x10000000

con

# stop autoboot and then do:
# zynq> bootm 0x10000000
