if {[file exists "hwcheck"] == 1} {
    if {[file exists "hwcheck.old"] == 1} {
	file delete -force hwcheck.old
    }
    file rename hwcheck/ hwcheck.old/
}
# Set SDK workspace
setws hwcheck

app create -name hwcheck -hw products/zsys_wrapper.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Hello World}

# Create a HW project
#createhw -name hw1 -hwspec products/zsys_wrapper.hdf
# Create a BSP project
#createbsp -name bsp1 -hwproject hw1 -proc ps7_cortexa9_0 -os standalone
# Create application project
#createapp -name hwcheck -hwproject hw1 -bsp bsp1 -proc ps7_cortexa9_0 -os standalone -lang C -app {Hello World}

# rename hello world so that it may be used for bare metal application development:
file rename hwcheck/hwcheck/src/helloworld.c hwcheck/hwcheck/src/hwcheck.c
# Copy the build tcl file into the working space:
#file copy srcs/sw/hwcheck/tcl/build.tcl hwcheck/
# Copy the run tcl file into the working space:
file copy srcs/sw/hwcheck/tcl/run.tcl hwcheck/
# Copy the application file over the hello world stub:
file copy -force srcs/sw/hwcheck/hwcheck.c hwcheck/hwcheck/src/hwcheck.c
# Run the application:
cd hwcheck

app build hwcheck

source run.tcl

cd ..
