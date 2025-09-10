if {[file exists "demo"] == 1} {
    if {[file exists "demo.old"] == 1} {
	file delete -force demo.old
    }
    file rename demo/ demo.old/
}
# Set SDK workspace
setws demo

app create -name demo -hw products/pacman.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Hello World}

# rename hello world app to hardware check:
file rename demo/demo/src/helloworld.c demo/demo/src/demo.c

file copy apps/demos/run.tcl demo/
file copy apps/demos/build.tcl demo/

# Copy the application file over the hello world stub:
file copy -force apps/demos/src/demo.c demo/demo/src/demo.c

# Copy the include and src files used by the main application:

file copy apps/demos/src/adc.h       demo/demo/src/
file copy apps/demos/src/dma.h       demo/demo/src/
file copy apps/demos/src/global.h    demo/demo/src/
file copy apps/demos/src/gpiops.h    demo/demo/src/
file copy apps/demos/src/hw_access.h demo/demo/src/
file copy apps/demos/src/iic.h       demo/demo/src/
file copy apps/demos/src/rxtx.h      demo/demo/src/
file copy apps/demos/src/timing.h    demo/demo/src/

file copy apps/demos/src/adc.c       demo/demo/src/
file copy apps/demos/src/dma.c       demo/demo/src/
file copy apps/demos/src/global.c    demo/demo/src/
file copy apps/demos/src/gpiops.c    demo/demo/src/
file copy apps/demos/src/hw_access.c demo/demo/src/
file copy apps/demos/src/iic.c       demo/demo/src/
file copy apps/demos/src/rxtx.c      demo/demo/src/
file copy apps/demos/src/timing.c    demo/demo/src/

# Run the application:
cd demo

app build demo

#source run.tcl

#cd ..

