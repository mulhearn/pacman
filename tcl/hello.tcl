if {[file exists "hello"] == 1} {
    if {[file exists "hello.old"] == 1} {
	file delete -force hello.old
    }
    file rename hello/ hello.old/
}
# Set SDK workspace
setws hello
# Create a HW project
createhw -name hw1 -hwspec products/zsys_wrapper.hdf
# Create a BSP project
createbsp -name bsp1 -hwproject hw1 -proc ps7_cortexa9_0 -os standalone
# Create application project
createapp -name bareapp -hwproject hw1 -bsp bsp1 -proc ps7_cortexa9_0 -os standalone -lang C -app {Hello World}
# rename hello world so that it may be used for bare metal application development:
file rename hello/bareapp/src/helloworld.c hello/bareapp/src/bareapp.c
# Build all projects
projects -build
# Copy the run tcl file into the working space:
file copy srcs/sw/bareapp/tcl/run.tcl hello/
# Run the application:
cd hello
source run.tcl
cd ..
