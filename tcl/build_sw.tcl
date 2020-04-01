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

# Create application projects

createapp -name pacman_fsbl -app {Zynq FSBL} -proc ps7_cortexa9_0 -hwproject hw1 -bsp bsp1 -os standalone
importsources -name pacman_fsbl -path srcs/sw/pacman_fsbl/src

createapp -name flash_fsbl -app {Zynq FSBL} -proc ps7_cortexa9_0 -hwproject hw1 -bsp bsp1 -os standalone
importsources -name flash_fsbl -path srcs/sw/flash_fsbl/src

#build:
projects -build

# copy the custom FSBL into products for use by peta-linux:
file copy -force build/pacman_fsbl/Debug/pacman_fsbl.elf products
file copy -force build/flash_fsbl/Debug/flash_fsbl.elf products
