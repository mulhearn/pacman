#
# vivado -mode batch -source tcl/build_xpr.tcl 
#
# Builds the PACMAN firware project and exports the hardware to
#
#     products/zsys_wrapper.hdf
#

# open the project:
open_project ./pacman-fw/pacman-fw.xpr

# delete the top-level wrapper if it already exists:
set file "[get_files -quiet "zsys_wrapper.vhd"]"
if { $file != "" } { 
    puts "deleting top-level wrapper"
    remove_files  $file
    file delete -force $file
}

# recrete the top-level wrapper
puts "recreating top-level wrapper"
make_wrapper -files [get_files zsys.bd] -top
add_files -norecurse pacman-fw/pacman-fw.srcs/sources_1/bd/zsys/hdl/zsys_wrapper.vhd

update_compile_order -fileset sources_1
reset_run synth_1
reset_run impl_1
launch_runs synth_1 -jobs 2
wait_on_run synth_1
launch_runs impl_1 -jobs 2
wait_on_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1
update_compile_order -fileset sources_1
#file copy -force ./pacman-fw/pacman-fw.runs/impl_1/zsys_wrapper.sysdef ./products/zsys_wrapper.hdf
write_hw_platform -fixed -force -file ./products/zsys_wrapper.xsa
write_hw_platform -fixed -include_bit -force -file ./products/zsys_wrapper.xsa
