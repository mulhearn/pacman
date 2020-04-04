# Set SDK workspace
setws .
# Build all projects
projects -build
exec bootgen -arch zynq -image hello.bif -w -o BOOT.bin

