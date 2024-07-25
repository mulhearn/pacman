#
# xsct apps/fsbl/install.tcl
#
# Builds various first stage boot loaders:
#
#
if {[file exists "fsbl"] == 1} {
    if {[file exists "fsbl.old"] == 1} {
	file delete -force fsbl.old
    }
    file rename fsbl/ fsbl.old/
}
exec mkdir fsbl

# Set SDK workspace
cd fsbl
setws .

# Create a HW project
#createhw -name hw1 -hwspec ../products/zsys_wrapper.hdf

# Create a BSP project
#createbsp -name bsp1 -hwproject hw1 -proc ps7_cortexa9_0 -os standalone
#setlib -bsp bsp1 -lib xilffs
#setlib -bsp bsp1 -lib xilrsa
#updatemss -mss bsp1/system.mss
#regenbsp -bsp bsp1

# Create pacman, trenz, flash

app create -name pacman_fsbl -hw ../products/zsys_wrapper.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Zynq FSBL}
importsources -name pacman_fsbl -path ../apps/fsbl/pacman/

app create -name trenz_fsbl -hw ../products/zsys_wrapper.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Zynq FSBL}
importsources -name trenz_fsbl -path ../apps/fsbl/trenz/

app create -name flash_fsbl -hw ../products/zsys_wrapper.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Zynq FSBL}
importsources -name flash_fsbl -path ../apps/fsbl/flash/

app create -name zynq_fsbl -hw ../products/zsys_wrapper.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Zynq FSBL}

file copy ../apps/fsbl/run.tcl ./

#build:
app build pacman_fsbl
app build trenz_fsbl
app build flash_fsbl
app build zynq_fsbl

# copy the custom FSBL into products for use by peta-linux:
file copy -force pacman_fsbl/Debug/pacman_fsbl.elf ../products
file copy -force trenz_fsbl/Debug/trenz_fsbl.elf ../products
file copy -force flash_fsbl/Debug/flash_fsbl.elf ../products
file copy -force zynq_fsbl/Debug/zynq_fsbl.elf ../products
