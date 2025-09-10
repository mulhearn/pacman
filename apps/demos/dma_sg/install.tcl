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
file copy apps/demos/src/dma.c    demo/demo/src/
file copy apps/demos/src/dma.h    demo/demo/src/

# Run the application:
cd demo

app build demo

#source run.tcl

#cd ..

