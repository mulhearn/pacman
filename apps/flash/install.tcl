#
# xsct apps/flash/install.tcl
#
# Load hello world (or something else) into flash for boot
#
#
if {[file exists "flash"] == 1} {
    if {[file exists "flash.old"] == 1} {
	file delete -force flash.old
    }
    file rename flash/ flash.old/
}
exec mkdir flash

# Set SDK workspace
cd flash
setws .

# Create a HW project
#createhw -name hw1 -hwspec ../products/zsys_wrapper.hdf

# Create a BSP project
#createbsp -name bsp1 -hwproject hw1 -proc ps7_cortexa9_0 -os standalone
#setlib -bsp bsp1 -lib xilffs
#setlib -bsp bsp1 -lib xilrsa
#updatemss -mss bsp1/system.mss
#regenbsp -bsp bsp1

# Create hello world and flash_fsbl apps:

app create -name hello -hw ../products/trenz.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Hello World}

app create -name fsbl_zynq -hw ../products/trenz.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Zynq FSBL}

app create -name fsbl_jtag -hw ../products/trenz.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Zynq FSBL}
importsources -name fsbl_jtag -path ../apps/flash/jtag/

#build:
app build hello
app build fsbl_zynq
app build fsbl_jtag

foreach f [glob -directory ../apps/flash/src/ -nocomplain *] {
    file copy -force $f ./
}

source build.tcl

