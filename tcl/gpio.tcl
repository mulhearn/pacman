if {[file exists "gpio"] == 1} {
    if {[file exists "gpio.old"] == 1} {
	file delete -force gpio.old
    }
    file rename gpio/ gpio.old/
}
# Set SDK workspace
setws gpio
# Create a HW project
createhw -name hw1 -hwspec products/zsys_wrapper.hdf
# Create a BSP project
createbsp -name bsp1 -hwproject hw1 -proc ps7_cortexa9_0 -os standalone
# Create application project
createapp -name gpio -hwproject hw1 -bsp bsp1 -proc ps7_cortexa9_0 -os standalone -lang C -app {Hello World}
# rename hello world so that it may be used for bare metal application development:
file rename gpio/gpio/src/helloworld.c gpio/gpio/src/gpio.c
# Copy the build tcl file into the working space:
file copy srcs/sw/gpio/tcl/build.tcl gpio/
# Copy the run tcl file into the working space:
file copy srcs/sw/gpio/tcl/run.tcl gpio/
# Copy the application file over the hello world stub:
file copy -force srcs/sw/gpio/gpio.c gpio/gpio/src/gpio.c
# Run the application:
cd gpio
source build.tcl
source run.tcl
cd ..
