#
# hardware.tcl  run synthesis,implementation,annd write bitstream, then export.
#

set proj_name "pacman-fw"

set origin_dir [file dirname [info script]]/..

open_project $origin_dir/$proj_name/$proj_name.xpr

update_compile_order -fileset sources_1
reset_run synth_1
reset_run impl_1

launch_runs synth_1 -jobs 2
wait_on_run synth_1
launch_runs impl_1 -jobs 2
wait_on_run impl_1
open_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1

write_hw_platform -fixed -include_bit -force -file ${origin_dir}/../products/pacman.xsa
