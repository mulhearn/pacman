#
# vivado -mode batch -source tcl/build_xpr.tcl 
#
# Builds the PACMAN firware project and exports the hardware to
#
#     products/zsys_wrapper.hdf
#
open_project ./pacman-fw/pacman-fw.xpr
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
file copy -force ./pacman-fw/pacman-fw.runs/impl_1/zsys_wrapper.sysdef ./products/zsys_wrapper.hdf
