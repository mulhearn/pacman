#
# A long tcl script to automatically generate a 32-channel uart array block (instead of wiring
# all of the signals by hand, which would take the better part of a day)
#
# Requires a "larpix_uart_channel_1" block existing either within the top level of the zsys
# block diagram or within an existing larpix_uart_array
#
# This will generate a new larpix_uart_array hierarchy complete with axi interconnects and
# 32 larpix_uart_channel subhierarchies (copied from the source larpix_uart_channel_1) but
# with the channel parameters updated
#
# Note: this does take a while (~30min on my machine), so test your small changes using
# fewer channels before generating all 32
#
# Usage:
#   vivado -mode batch -source tcl/gen_uart_bd.tcl
#

set n_channels 32

# open up project
open_project ./pacman-fw/pacman-fw.xpr
update_compile_order -fileset sources_1

# open up block design
open_bd_design {./pacman-fw/pacman-fw.srcs/sources_1/bd/zsys/zsys.bd}

# create uart array hierarchy
set uart_array_hier "[get_bd_cell larpix_uart_array]"
if { $uart_array_hier != "" } {
    puts "delete existing larpix uart array"
    delete_bd_objs $uart_array_hier
}
save_bd_design

set larpix_uart_array [create_bd_cell -type hier larpix_uart_array]
set ACLK [create_bd_pin -dir I larpix_uart_array/ACLK -type clk]
set ARESETN [create_bd_pin -dir I larpix_uart_array/ARESETN -type rst]
set MCLK [create_bd_pin -dir I larpix_uart_array/MCLK -type clk]
set PACMAN_TS [create_bd_pin -dir I -from 31 -to 0 larpix_uart_array/PACMAN_TS]
set S_AXIMM [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 larpix_uart_array/S_AXIMM]

# create axi interface interconnect
connect_bd_intf_net $S_AXIMM [get_bd_intf_pins ps7_0_axi_periph/M04_AXI]
create_bd_cell -type hier larpix_uart_array/aximm
set aximm_interconnect larpix_uart_array/aximm/aximm_interconnect_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 $aximm_interconnect
set_property -dict [list CONFIG.NUM_MI {32}] [get_bd_cells $aximm_interconnect]
set_property -dict [list CONFIG.STRATEGY {2} CONFIG.S00_HAS_REGSLICE {3}] [get_bd_cells $aximm_interconnect]
set_property -dict [list CONFIG.M00_HAS_REGSLICE {3} CONFIG.M01_HAS_REGSLICE {3} CONFIG.M02_HAS_REGSLICE {3} CONFIG.M03_HAS_REGSLICE {3} CONFIG.M04_HAS_REGSLICE {3} CONFIG.M05_HAS_REGSLICE {3} CONFIG.M06_HAS_REGSLICE {3} CONFIG.M07_HAS_REGSLICE {3} CONFIG.M08_HAS_REGSLICE {3} CONFIG.M09_HAS_REGSLICE {3} CONFIG.M10_HAS_REGSLICE {3} CONFIG.M11_HAS_REGSLICE {3} CONFIG.M12_HAS_REGSLICE {3} CONFIG.M13_HAS_REGSLICE {3} CONFIG.M14_HAS_REGSLICE {3} CONFIG.M15_HAS_REGSLICE {3} CONFIG.M16_HAS_REGSLICE {3} CONFIG.M17_HAS_REGSLICE {3} CONFIG.M18_HAS_REGSLICE {3} CONFIG.M19_HAS_REGSLICE {3} CONFIG.M20_HAS_REGSLICE {3} CONFIG.M21_HAS_REGSLICE {3} CONFIG.M22_HAS_REGSLICE {3} CONFIG.M23_HAS_REGSLICE {3} CONFIG.M24_HAS_REGSLICE {3} CONFIG.M25_HAS_REGSLICE {3} CONFIG.M26_HAS_REGSLICE {3} CONFIG.M27_HAS_REGSLICE {3} CONFIG.M28_HAS_REGSLICE {3} CONFIG.M29_HAS_REGSLICE {3} CONFIG.M30_HAS_REGSLICE {3} CONFIG.M31_HAS_REGSLICE {3}] [get_bd_cells $aximm_interconnect]
connect_bd_intf_net $S_AXIMM [get_bd_intf_pins $aximm_interconnect/S00_AXI]
connect_bd_net $ACLK [get_bd_pins $aximm_interconnect/ACLK]
connect_bd_net $ACLK [get_bd_pins $aximm_interconnect/S00_ACLK]
connect_bd_net $ARESETN [get_bd_pins $aximm_interconnect/ARESETN]
connect_bd_net $ARESETN [get_bd_pins $aximm_interconnect/S00_ARESETN]
save_bd_design
#

# create axi-stream broadcaster(s)
set axis_broadcast larpix_uart_array/axis_broadcast
create_bd_cell -type hier $axis_broadcast
set axis_broadcaster $axis_broadcast/axis_broadcaster
for {set i 0} {$i < 8} {incr i} {
    set n_interfaces 4
    
    create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 ${axis_broadcaster}_$i
    
    # axi broadcast settings
    set_property -dict [list CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC USER CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER CONFIG.HAS_TREADY.VALUE_SRC USER CONFIG.HAS_TSTRB.VALUE_SRC USER CONFIG.HAS_TKEEP.VALUE_SRC USER CONFIG.HAS_TLAST.VALUE_SRC USER] [get_bd_cells ${axis_broadcaster}_$i]
    set_property -dict [list CONFIG.NUM_MI $n_interfaces CONFIG.M_TDATA_NUM_BYTES {16} CONFIG.S_TDATA_NUM_BYTES {16} CONFIG.M00_TDATA_REMAP {tdata[127:0]} CONFIG.M01_TDATA_REMAP {tdata[127:0]} CONFIG.M02_TDATA_REMAP {tdata[127:0]} CONFIG.M03_TDATA_REMAP {tdata[127:0]}] [get_bd_cells ${axis_broadcaster}_$i]

    # create/connect pins
    set S_AXIS [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 larpix_uart_array/S${i}_AXIS]
    connect_bd_intf_net $S_AXIS [get_bd_intf_pins ${axis_broadcaster}_$i/S_AXIS]
    connect_bd_intf_net $S_AXIS [get_bd_intf_pins data_tx/M0${i}_AXIS]
    connect_bd_net $ACLK [get_bd_pins ${axis_broadcaster}_$i/aclk]
    connect_bd_net $ARESETN [get_bd_pins ${axis_broadcaster}_$i/aresetn]

}
save_bd_design
#

# create axi-stream interconnect(s)
set axis_merge larpix_uart_array/axis_merge
create_bd_cell -type hier $axis_merge
set axis_interconnect $axis_merge/axis_interconnect
for {set i 0} {$i < 8} {incr i} {
    set n_interfaces 4

    create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 ${axis_interconnect}_$i
    
    # axi interconnect settings
    set_property -dict [list CONFIG.NUM_SI $n_interfaces CONFIG.NUM_MI {1} CONFIG.M00_FIFO_DEPTH {1024} CONFIG.S00_FIFO_DEPTH {0} CONFIG.S01_FIFO_DEPTH {0} CONFIG.S02_FIFO_DEPTH {0} CONFIG.S03_FIFO_DEPTH {0}] [get_bd_cells ${axis_interconnect}_${i}]
    set_property -dict [list CONFIG.M00_HAS_REGSLICE {1} CONFIG.S00_HAS_REGSLICE {0} CONFIG.S01_HAS_REGSLICE {0} CONFIG.S02_HAS_REGSLICE {0} CONFIG.S03_HAS_REGSLICE {0}] [get_bd_cells ${axis_interconnect}_${i}]

    # create/connect pins
    set M_AXIS [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 larpix_uart_array/M${i}_AXIS]
    connect_bd_intf_net $M_AXIS [get_bd_intf_pins ${axis_interconnect}_${i}/M00_AXIS]
    connect_bd_intf_net $M_AXIS [get_bd_intf_pins data_rx/S0${i}_AXIS]
    connect_bd_net $ACLK [get_bd_pins ${axis_interconnect}_$i/ACLK]
    connect_bd_net [get_bd_pins ${axis_merge}/ACLK] [get_bd_pins ${axis_interconnect}_${i}/M00_AXIS_ACLK]
    connect_bd_net $ARESETN [get_bd_pins ${axis_interconnect}_${i}/ARESETN]
    connect_bd_net [get_bd_pins ${axis_merge}/ARESETN] [get_bd_pins ${axis_interconnect}_${i}/M00_AXIS_ARESETN]
    for {set j 0} {$j < $n_interfaces} {incr j} {
        connect_bd_net [get_bd_pins ${axis_merge}/ACLK] [get_bd_pins ${axis_interconnect}_${i}/S0${j}_AXIS_ACLK]
        connect_bd_net [get_bd_pins ${axis_merge}/ARESETN] [get_bd_pins ${axis_interconnect}_${i}/S0${j}_AXIS_ARESETN]
    }
}
save_bd_design
#    

# create uart channels from existing block
set uart_channels larpix_uart_array/uart_channels
create_bd_cell -type hier $uart_channels
for {set channel 1} {$channel < [expr { $n_channels + 1 }]} {incr channel} {
    puts "Generating channel ${channel}..."
    set channel_hex [format %02X $channel]
    set channel_major [expr { int(($channel - 1) / 4) }]
    set channel_minor [expr { ($channel - 1) % 4 }]
    set channel_minor_padded [format %02d $channel_minor]
    set channel_padded [format %02d [expr {$channel - 1}]]
    puts "Channel refs x$channel_hex, M$channel_major, m$channel_minor, mp$channel_minor_padded, cp$channel_padded..."

    # create new uart channel
    #copy_bd_objs larpix_uart_array [get_bd_cells {larpix_uart_channel_1}]
    set larpix_uart_channel $uart_channels/larpix_uart_channel_$channel
    create_bd_cell -type ip -vlnv user.org:user:uart_channel:1.0 $larpix_uart_channel

    set channel_s_axis ${axis_interconnect}_${channel_major}/S$channel_minor_padded
    #set channel_m_axis ${axis_broadcaster}_reg_${channel_major}_${channel_minor}/M
    set channel_m_axis ${axis_broadcaster}_${channel_major}/M${channel_minor_padded}
    set channel_m_aximm ${aximm_interconnect}/M$channel_padded

    # set channel property
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 ${larpix_uart_channel}_id
    set_property -dict [list CONFIG.CONST_WIDTH 8 CONFIG.CONST_VAL 0x$channel_hex] [get_bd_cells ${larpix_uart_channel}_id]
    connect_bd_net [get_bd_pins ${larpix_uart_channel}_id/dout] [get_bd_pins $larpix_uart_channel/C_CHANNEL]

    # make connections
    # axi-stream master
    connect_bd_intf_net [get_bd_intf_pins ${channel_s_axis}_AXIS] [get_bd_intf_pins $larpix_uart_channel/M_AXIS]
    # axi-stream slave
    connect_bd_intf_net [get_bd_intf_pins ${channel_m_axis}_AXIS] [get_bd_intf_pins $larpix_uart_channel/S_AXIS]
    # axi-lite mm
    connect_bd_intf_net [get_bd_intf_pins ${channel_m_aximm}_AXI] [get_bd_intf_pins $larpix_uart_channel/S00_AXI]
    connect_bd_net [get_bd_pins ${channel_m_aximm}_ACLK] $ACLK
    connect_bd_net [get_bd_pins ${channel_m_aximm}_ARESETN] $ARESETN

    # other pins
    connect_bd_net [get_bd_pins $larpix_uart_channel/ACLK] $ACLK
    connect_bd_net [get_bd_pins $larpix_uart_channel/ARESETN] $ARESETN
    connect_bd_net [get_bd_pins $larpix_uart_channel/MCLK] $MCLK
    connect_bd_net [get_bd_pins $larpix_uart_channel/PACMAN_TS] $PACMAN_TS

    # external uart pins
    #create_bd_pin -dir I larpix_uart_array/UART_RX_$channel
    #create_bd_pin -dir O larpix_uart_array/UART_TX_$channel
    #connect_bd_net [get_bd_pins $larpix_uart_channel/UART_RX] [get_bd_pins larpix_uart_array/UART_RX_$channel]
    #connect_bd_net [get_bd_pins $larpix_uart_channel/UART_TX] [get_bd_pins larpix_uart_array/UART_TX_$channel]
    # loop back (comment out if not)
    connect_bd_net [get_bd_pins $larpix_uart_channel/UART_RX] [get_bd_pins $larpix_uart_channel/UART_TX]

    # setup reserved addresses
    set seg_ro [get_bd_addr_segs $larpix_uart_channel/S00_AXI/Reg0]
    set seg_rw [get_bd_addr_segs $larpix_uart_channel/S00_AXI/Reg1]
    create_bd_addr_seg -range 4K -offset 0x50${channel_hex}0000 [get_bd_addr_spaces processing_system7_0/Data] $seg_ro seg_uart_ro_$channel
    create_bd_addr_seg -range 4K -offset 0x50${channel_hex}1000 [get_bd_addr_spaces processing_system7_0/Data] $seg_rw seg_uart_rw_$channel
    
    save_bd_design
}

close_bd_design [ get_bd_designs zsys ]

update_compile_order -fileset sources_1

puts "Done!"
