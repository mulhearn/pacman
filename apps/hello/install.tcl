if {[file exists "hello"] == 1} {
    if {[file exists "hello.old"] == 1} {
	file delete -force hello.old
    }
    file rename hello/ hello.old/
}
# Set SDK workspace
setws hello

app create -name bareapp -hw products/trenz.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Hello World}
# this version builds from prebuilt:
#app create -name bareapp -hw products_prebuilt/test_board_1cf_1gb.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Hello World}


# rename hello world so that it may be used for bare metal application development:
file rename hello/bareapp/src/helloworld.c hello/bareapp/src/bareapp.c

# Copy the run tcl file into the working space:
file copy apps/hello/run.tcl hello/
file copy apps/hello/build.tcl hello/

# Run the application:
cd hello

app build bareapp

#source run.tcl
#cd ..
