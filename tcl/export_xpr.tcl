#
# vivado -mode batch -source tcl/export_xpr.tcl  
#
# Export the Xilinx Project into tcl/recreate_xpr.tcl
#
open_project ./pacman-fw/pacman-fw.xpr
write_project_tcl -force recreate_xpr.tcl
file rename -force tcl/recreate_xpr.tcl tcl/recreate_xpr.tcl.old
file rename recreate_xpr.tcl tcl/recreate_xpr.tcl

