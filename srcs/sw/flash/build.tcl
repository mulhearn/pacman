# Set SDK workspace
setws .
# Build all projects
projects -build
exec bootgen -arch zynq -image all.bif -w -o BOOT.bin

