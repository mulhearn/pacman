#
# hardware.tcl  run synthesis,implementation,annd write bitstream, then export.
#

set proj_name "pacman-fw"

set origin_dir [file dirname [info script]]/..

open_project $origin_dir/$proj_name/$proj_name.xpr

source $origin_dir/tcl/version_info.tcl
import_files -force gen/hdl/version_info_pkg.vhd

update_compile_order -fileset sources_1
reset_run synth_1
reset_run impl_1

launch_runs synth_1 -jobs 1
wait_on_run synth_1
launch_runs impl_1 -jobs 2
wait_on_run impl_1
open_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1

report_utilization -file ../reports/summary.txt
report_utilization -hierarchical -hierarchical_depth 5 -file ../reports/utilization.txt
report_control_sets -hierarchical -hierarchical_depth 5 -file ../reports/control_sets.txt
report_timing_summary -file ../reports/timing_summary.txt
report_timing -max_paths 10 -sort_by slack -delay_type max -nworst 10 -input_pins -significant_digits 3 -file ../reports/worst_timing_max.txt
report_timing -max_paths 10 -sort_by slack -delay_type min -nworst 10 -input_pins -significant_digits 3 -file ../reports/worst_timing_min.txt

write_hw_platform -fixed -include_bit -force -file ${origin_dir}/../products/pacman.xsa
