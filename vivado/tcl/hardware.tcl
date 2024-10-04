#
# hardware.tcl  run synthesis,implementation,annd write bitstream, then export.
#

set proj_name "pacman-fw"

set origin_dir [file dirname [info script]]/..

open_project $origin_dir/$proj_name/$proj_name.xpr

write_hw_platform -fixed -include_bit -force -file ${origin_dir}/../products/pacman.xsa
