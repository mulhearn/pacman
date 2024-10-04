
# list targets:
program_flash -jtagtargets -url TCP:localhost:3121 

# this version flashes the first target:
program_flash -f BOOT.bin -fsbl fsbl_jtag/Debug/fsbl_jtag.elf -flash_type qspi-x4-single -blank_check -verify -url TCP:localhost:3121

# this version allows for explicit target selection (see targets from first command)
#program_flash -f BOOT.bin -fsbl ../products/flash_fsbl.elf -flash_type qspi-x4-single -blank_check -verify -target_name jsn-JTAG-ONB4-251633059683A-4ba00477-0




