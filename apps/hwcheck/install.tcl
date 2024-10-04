if {[file exists "hwcheck"] == 1} {
    if {[file exists "hwcheck.old"] == 1} {
	file delete -force hwcheck.old
    }
    file rename hwcheck/ hwcheck.old/
}
# Set SDK workspace
setws hwcheck

app create -name hwcheck -hw products/pacman.xsa -os standalone -proc ps7_cortexa9_0 -lang C -template {Hello World}

# rename hello world app to hardware check:
file rename hwcheck/hwcheck/src/helloworld.c hwcheck/hwcheck/src/hwcheck.c

file copy apps/hwcheck/run.tcl hwcheck/
file copy apps/hwcheck/build.tcl hwcheck/

# Copy the application file over the hello world stub:
file copy -force apps/hwcheck/hwcheck.c hwcheck/hwcheck/src/hwcheck.c

# Run the application:
cd hwcheck

app build hwcheck

#source run.tcl

#cd ..
