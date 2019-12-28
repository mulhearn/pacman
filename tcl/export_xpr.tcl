#
# vivado -mode batch -source tcl/export_xpr.tcl  
#
# Export the Xilinx Project into tcl/recreate_xpr.tcl
#
open_project ./pacman-fw/pacman-fw.xpr

# delete the top-level wrapper if it already exists:
set file "[get_files -quiet "zsys_wrapper.vhd"]"
if { $file != "" } { 
    puts "deleting top-level wrapper"
    remove_files  $file
    file delete -force $file
}
write_project_tcl -force recreate_xpr.tcl
file rename -force tcl/recreate_xpr.tcl tcl/recreate_xpr.tcl.old
file rename recreate_xpr.tcl tcl/recreate_xpr.tcl

# recrete the top-level wrapper
puts "recreating top-level wrapper"
make_wrapper -files [get_files zsys.bd] -top
add_files -norecurse pacman-fw/pacman-fw.srcs/sources_1/bd/zsys/hdl/zsys_wrapper.vhd
