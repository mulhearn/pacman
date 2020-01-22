#
# xsct tcl/build_sw.tcl
#
# Builds the application software from sources and saves the products:
#
#    products/zynq_fsbl.elf
#
if {[file exists "build"] == 1} {
    if {[file exists "build.old"] == 1} {
	file delete -force build.old
    }
    file rename build/ build.old/
}

# Set SDK workspace
setws build

# Create a HW project
createhw -name hw1 -hwspec products/zsys_wrapper.hdf

# Create a BSP project
createbsp -name bsp1 -hwproject hw1 -proc ps7_cortexa9_0 -os standalone
setlib -bsp bsp1 -lib xilffs
setlib -bsp bsp1 -lib xilrsa
updatemss -mss build/bsp1/system.mss
regenbsp -bsp bsp1

# Create application project
createapp -name zynq_fsbl -hwproject hw1 -bsp bsp1 -proc ps7_cortexa9_0 -os standalone -app {Empty Application}
importsources -name zynq_fsbl -path srcs/sw/zynq_fsbl

#build:
projects -build

# copy the custom FSBL into products for use by peta-linux:
file copy build/zynq_fsbl/Debug/zynq_fsbl.elf products
