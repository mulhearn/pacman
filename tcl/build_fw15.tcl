#
# vivado -mode batch -source tcl/build_fw15.tcl -tclargs <xpr>   (called by tcl/build_fw15.sh)
#
# Adds the top-level wrapper (the export has none) and builds through write_bitstream.
#

set jobs 8
open_project [lindex $argv 0]

# create the top-level wrapper:
set w [make_wrapper -files [get_files zsys.bd] -top]
add_files -norecurse $w
set_property top zsys_wrapper [current_fileset]
update_compile_order -fileset sources_1

# build, launching impl_1 a second time if the first launch fails (2021.1 IP generate):
foreach r [get_runs] { reset_run $r }
if {[catch {launch_runs impl_1 -to_step write_bitstream -jobs $jobs} e]} {
    puts "impl_1 launch 1 failed:  $e"
} else { wait_on_run impl_1 }
if {![string match "*write_bitstream Complete*" [get_property STATUS [get_runs impl_1]]]} {
    launch_runs impl_1 -to_step write_bitstream -jobs $jobs
    wait_on_run impl_1
}
puts "impl_1 status:  [get_property STATUS [get_runs impl_1]]"
close_project
