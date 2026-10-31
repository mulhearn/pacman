#
# vivado -mode batch -source tcl/recreate_resethack1.8.tcl -tclargs <repo> <stage>   (called by build_resethack1.8.sh)
#
# Stages the files tcl/pacman_resethack1.8.tcl requires in the layout it expects, then sources it.
#
set repo [lindex $argv 0]; set stage [lindex $argv 1]
set src $stage/src; set p $src/pacman_resethack1.8/pacman_resethack1.8.srcs
proc put {src dst} { file mkdir [file dirname $dst]; file copy -force $src $dst }
foreach f {iobuf_out axi_lite_reg_space larpix_clk_to_axi_stream larpix_counter larpix_mclk_sel larpix_reset_gen
           larpix_periodic_trig_gen larpix_trig_gen larpix_trig_to_axi_stream obuft_out axi_stream_to_larpix
           larpix_to_axi_stream larpix_uart_rx larpix_uart_tx uart_rx uart_tx uart_channel clk_ddr_en clk_ddr_out
           obuftds_out} {
    put $repo/srcs/fw/$f.vhd $p/sources_1/imports/fw/$f.vhd
}
put $repo/srcs/fw/tristate_out.vhd $p/sources_1/new/tristate_out.vhd
put $repo/srcs/fw/uart_en.vhd      $p/sources_1/new/uart_en.vhd
put $repo/srcs/fw/zsys_wrapper.vhd $p/sources_1/imports/zsys_wrapper.vhd
put $repo/srcs/ip/fifo_64x512/fifo_64x512.xci $p/sources_1/ip/fifo_64x512/fifo_64x512.xci
set c $p/constrs_1/imports/Pacman_fw
foreach f {clk gpio pacman} { put $repo/constraints/$f.xdc $c/pacman-pacman-v1.5S/pacman-pacman-v1.5S/constraints/$f.xdc }
put $repo/constraints/pacman_r4.xdc $c/constraints/pacman_r4.xdc
foreach f [glob -directory $repo/srcs/fw/tb *.vhd] { put $f $p/sim_1/imports/fw/tb/[file tail $f] }
put $repo/srcs/fw/larpix_uart_tx.vhd $p/sim_1/imports/fw/larpix_uart_tx.vhd
file mkdir $stage/pacman-pacman-v1.5S/pacman-pacman-v1.5S/srcs
file copy -force $repo/srcs/ip $stage/pacman-pacman-v1.5S/pacman-pacman-v1.5S/srcs/ip
set w $stage/proj/C:/Users/karcher/Documents/DUNE/Pacman_fw/pacman_resethack
file mkdir $w
file link -symbolic $w/pacman_resethack1.8 $src/pacman_resethack1.8
cd $stage/proj
set ::origin_dir_loc $src
# One edit, in a copy under <stage>:  2021.1's import_files puts the constraints in constrs_1/imports/constraints/,
# not imports/Pacman_fw/constraints/, so the script's target_constrs_file and target_ucf name a file that is not
# there ("Invalid constraints filename specified", 2026-10-23) and the script stops before the block design.
set f [open $repo/tcl/pacman_resethack1.8.tcl]; set t [read $f]; close $f
set n [regsub -all {constrs_1/imports/Pacman_fw/constraints/pacman_r4\.xdc" -objects} $t \
           {constrs_1/imports/constraints/pacman_r4.xdc" -objects} t]
puts "recreate_resethack1.8:  target constraints path edited ($n places)"
set f [open $stage/pacman_resethack1.8.tcl w]; puts -nonewline $f $t; close $f
source $stage/pacman_resethack1.8.tcl
