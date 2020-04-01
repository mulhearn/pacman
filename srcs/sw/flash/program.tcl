# Set SDK workspace
setws .

# Just hard-coded for now:
exec program_flash -f BOOT.bin -fsbl flash_fsbl/Debug/flash_fsbl.elf -flash_type qspi-x4-single -blank_check -verify -target_name jsn-JTAG-ONB4-251633059683A-4ba00477-0
