#
# xsct apps/jtag_boot/install.tcl
#

if {[file exists "jtag_boot"] == 1} {
    if {[file exists "jtag_boot.old"] == 1} {
	file delete -force jtag_boot.old
    }
    file rename jtag_boot/ jtag_boot.old/
}
exec mkdir jtag_boot

# Copy project TCL files:
file copy apps/jtag_boot/run.tcl jtag_boot/
file copy apps/jtag_boot/boot.tcl jtag_boot/

# Set SDK workspace
cd jtag_boot
setws .


# Create hello world and fsbl apps:

app create -name hello -hw ../products/pacman.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Hello World}

app create -name fsbl_zynq -hw ../products/pacman.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Zynq FSBL}

app create -name fsbl_jtag -hw ../products/pacman.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Zynq FSBL}
importsources -name fsbl_jtag -path ../apps/jtag_boot/jtag/

#build:
app build hello
app build fsbl_zynq
app build fsbl_jtag


