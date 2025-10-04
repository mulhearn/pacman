#
# hardware.tcl  run synthesis,implementation,annd write bitstream, then export.
#

set proj_name "pacman-fw"

set origin_dir [file dirname [info script]]/..

open_project $origin_dir/$proj_name/$proj_name.xpr

open_run synth_1
open_run impl_1

