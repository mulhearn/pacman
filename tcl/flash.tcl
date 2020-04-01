if {[file exists "flash"] == 1} {
    if {[file exists "flash.old"] == 1} {
	file delete -force flash.old
    }
    file rename flash/ flash.old/
}
# Set SDK workspace
setws flash
# Create a HW project
createhw -name hw1 -hwspec products/zsys_wrapper.hdf

# Create a BSP project
createbsp -name bsp1 -hwproject hw1 -proc ps7_cortexa9_0 -os standalone
setlib -bsp bsp1 -lib xilffs
setlib -bsp bsp1 -lib xilrsa
updatemss -mss build/bsp1/system.mss
regenbsp -bsp bsp1

# Pac-Man specific FSBL:
createapp -name pacman_fsbl -hwproject hw1 -bsp bsp1 -proc ps7_cortexa9_0 -os standalone -app {Empty Application}
importsources -name pacman_fsbl -path srcs/sw/fsbl

# Vanilla FSBL:
createapp -name fsbl -app {Zynq FSBL} -proc ps7_cortexa9_0 -hwproject hw1 -bsp bsp1 -os standalone

# Hello World app:
createapp -name hello -app {Hello World} -proc ps7_cortexa9_0 -hwproject hw1  -bsp bsp1 -os standalone

file copy srcs/sw/flash/build.tcl flash/
file copy srcs/sw/flash/all.bif flash/

cd flash
source build.tcl

