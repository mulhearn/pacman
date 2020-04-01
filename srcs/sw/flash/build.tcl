# Set SDK workspace
setws .
# Build all projects
projects -build
exec bootgen -arch zynq -image all.bif -w -o BOOT.bin
#exec program_flash -f BOOT.bin -flash_type qspi_single -blank_check -verify -target_name jsn-JTAG-ONB4-251633059683A-4ba00477-0
#exec bootgen -arch zynq -image output.bif -w -o BOOT.bin
