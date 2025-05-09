#
# xsct apps/fsbl/install.tcl
#
# Builds various first stage boot loaders:
#
#
if {[file exists "pacman_fsbl"] == 1} {
    if {[file exists "pacman_fsbl.old"] == 1} {
	file delete -force pacman_fsbl.old
    }
    file rename pacman_fsbl/ pacman_fsbl.old/
}
exec mkdir pacman_fsbl

# Set SDK workspace
cd pacman_fsbl
setws .

app create -name pacman_fsbl -hw ../products/pacman.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Zynq FSBL}
importsources -name pacman_fsbl -path ../apps/pacman_fsbl/src/

file copy ../apps/pacman_fsbl/build.tcl ./
file copy ../apps/pacman_fsbl/run.tcl ./

app build pacman_fsbl

file copy -force pacman_fsbl/Debug/pacman_fsbl.elf ../products
