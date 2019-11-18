open_project ./pacman/pacman.xpr
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
file copy -force /space/home/benchtop/projects/pacman/pacman/pacman.runs/impl_1/zsys_wrapper.sysdef /space/home/benchtop/projects/pacman/products/zsys_wrapper.hdf
