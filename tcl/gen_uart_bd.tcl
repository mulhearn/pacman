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

# open up project
open_project ./pacman-fw/pacman-fw.xpr

# open up block design
open_bd_design {./pacman-fw/pacman-fw.srcs/sources_1/bd/zsys/zsys.bd}

# create uart array hierarchy
set uart_array_hier "[get_bd_cell larpix_uart_array]"
if { $uart_array_hier != "" } {
    if { [get_bd_cells {larpix_uart_array/larpix_uart_channel_1}] != "" } {
        if { [get_bd_cells {larpix_uart_channel_1}] == "" } {
            copy_bd_objs /  [get_bd_cells {larpix_uart_array/larpix_uart_channel_1}]
        }
    }

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
set M_AXIS [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 larpix_uart_array/M_AXIS]
set S_AXIS [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 larpix_uart_array/S_AXIS]

# create axi interface interconnect
connect_bd_intf_net $S_AXIMM [get_bd_intf_pins ps7_0_axi_periph/M07_AXI]
set aximm_interconnect larpix_uart_array/aximm_interconnect_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 $aximm_interconnect
set_property location {1 -20000 0} [get_bd_cells $aximm_interconnect]
set_property -dict [list CONFIG.NUM_MI {32}] [get_bd_cells $aximm_interconnect]
connect_bd_intf_net $S_AXIMM [get_bd_intf_pins $aximm_interconnect/S00_AXI]
connect_bd_net $ACLK [get_bd_pins $aximm_interconnect/ACLK]
connect_bd_net $ACLK [get_bd_pins $aximm_interconnect/S00_ACLK]
connect_bd_net $ARESETN [get_bd_pins $aximm_interconnect/ARESETN]
connect_bd_net $ARESETN [get_bd_pins $aximm_interconnect/S00_ARESETN]

# create axi-stream broadcaster(s)
set axis_broadcaster_0 larpix_uart_array/axis_broadcaster_0
set axis_broadcaster_1 larpix_uart_array/axis_broadcaster_1
set axis_broadcaster_2 larpix_uart_array/axis_broadcaster_2
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 $axis_broadcaster_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 $axis_broadcaster_1
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 $axis_broadcaster_2
set_property location {1 -20000 20000} [get_bd_cells $axis_broadcaster_0]
set_property location {1 -10000 10000} [get_bd_cells $axis_broadcaster_1]
set_property location {1 -10000 30000} [get_bd_cells $axis_broadcaster_2]
# axi broadcast 0 settings
set_property -dict [list CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC USER CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER CONFIG.HAS_TREADY.VALUE_SRC USER CONFIG.HAS_TSTRB.VALUE_SRC USER CONFIG.HAS_TKEEP.VALUE_SRC USER CONFIG.HAS_TLAST.VALUE_SRC USER] [get_bd_cells $axis_broadcaster_0]
set_property -dict [list CONFIG.NUM_MI {2} CONFIG.M_TDATA_NUM_BYTES {16} CONFIG.S_TDATA_NUM_BYTES {16} CONFIG.M00_TDATA_REMAP {tdata[127:0]} CONFIG.M01_TDATA_REMAP {tdata[127:0]} CONFIG.M02_TDATA_REMAP {tdata[127:0]} CONFIG.M03_TDATA_REMAP {tdata[127:0]} CONFIG.M04_TDATA_REMAP {tdata[127:0]} CONFIG.M05_TDATA_REMAP {tdata[127:0]} CONFIG.M06_TDATA_REMAP {tdata[127:0]} CONFIG.M07_TDATA_REMAP {tdata[127:0]} CONFIG.M08_TDATA_REMAP {tdata[127:0]} CONFIG.M09_TDATA_REMAP {tdata[127:0]} CONFIG.M10_TDATA_REMAP {tdata[127:0]} CONFIG.M11_TDATA_REMAP {tdata[127:0]} CONFIG.M12_TDATA_REMAP {tdata[127:0]} CONFIG.M13_TDATA_REMAP {tdata[127:0]} CONFIG.M14_TDATA_REMAP {tdata[127:0]} CONFIG.M15_TDATA_REMAP {tdata[127:0]}] [get_bd_cells $axis_broadcaster_0]
# axi broadcast 1 settings
set_property -dict [list CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC USER CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER CONFIG.HAS_TREADY.VALUE_SRC USER CONFIG.HAS_TSTRB.VALUE_SRC USER CONFIG.HAS_TKEEP.VALUE_SRC USER CONFIG.HAS_TLAST.VALUE_SRC USER] [get_bd_cells $axis_broadcaster_1]
set_property -dict [list CONFIG.NUM_MI {16} CONFIG.M_TDATA_NUM_BYTES {16} CONFIG.S_TDATA_NUM_BYTES {16} CONFIG.M00_TDATA_REMAP {tdata[127:0]} CONFIG.M01_TDATA_REMAP {tdata[127:0]} CONFIG.M02_TDATA_REMAP {tdata[127:0]} CONFIG.M03_TDATA_REMAP {tdata[127:0]} CONFIG.M04_TDATA_REMAP {tdata[127:0]} CONFIG.M05_TDATA_REMAP {tdata[127:0]} CONFIG.M06_TDATA_REMAP {tdata[127:0]} CONFIG.M07_TDATA_REMAP {tdata[127:0]} CONFIG.M08_TDATA_REMAP {tdata[127:0]} CONFIG.M09_TDATA_REMAP {tdata[127:0]} CONFIG.M10_TDATA_REMAP {tdata[127:0]} CONFIG.M11_TDATA_REMAP {tdata[127:0]} CONFIG.M12_TDATA_REMAP {tdata[127:0]} CONFIG.M13_TDATA_REMAP {tdata[127:0]} CONFIG.M14_TDATA_REMAP {tdata[127:0]} CONFIG.M15_TDATA_REMAP {tdata[127:0]}] [get_bd_cells $axis_broadcaster_1]
# axi broadcast 2 settings
set_property -dict [list CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC USER CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER CONFIG.HAS_TREADY.VALUE_SRC USER CONFIG.HAS_TSTRB.VALUE_SRC USER CONFIG.HAS_TKEEP.VALUE_SRC USER CONFIG.HAS_TLAST.VALUE_SRC USER] [get_bd_cells $axis_broadcaster_2]
set_property -dict [list CONFIG.NUM_MI {16} CONFIG.M_TDATA_NUM_BYTES {16} CONFIG.S_TDATA_NUM_BYTES {16} CONFIG.M00_TDATA_REMAP {tdata[127:0]} CONFIG.M01_TDATA_REMAP {tdata[127:0]} CONFIG.M02_TDATA_REMAP {tdata[127:0]} CONFIG.M03_TDATA_REMAP {tdata[127:0]} CONFIG.M04_TDATA_REMAP {tdata[127:0]} CONFIG.M05_TDATA_REMAP {tdata[127:0]} CONFIG.M06_TDATA_REMAP {tdata[127:0]} CONFIG.M07_TDATA_REMAP {tdata[127:0]} CONFIG.M08_TDATA_REMAP {tdata[127:0]} CONFIG.M09_TDATA_REMAP {tdata[127:0]} CONFIG.M10_TDATA_REMAP {tdata[127:0]} CONFIG.M11_TDATA_REMAP {tdata[127:0]} CONFIG.M12_TDATA_REMAP {tdata[127:0]} CONFIG.M13_TDATA_REMAP {tdata[127:0]} CONFIG.M14_TDATA_REMAP {tdata[127:0]} CONFIG.M15_TDATA_REMAP {tdata[127:0]}] [get_bd_cells $axis_broadcaster_2]
# Connect broadcast axi streams
connect_bd_intf_net $S_AXIS [get_bd_intf_pins $axis_broadcaster_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins $axis_broadcaster_0/M00_AXIS] [get_bd_intf_pins $axis_broadcaster_1/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins $axis_broadcaster_0/M01_AXIS] [get_bd_intf_pins $axis_broadcaster_2/S_AXIS]
# Connect clocks
connect_bd_net $ACLK [get_bd_pins $axis_broadcaster_0/aclk]
connect_bd_net $ACLK [get_bd_pins $axis_broadcaster_1/aclk]
connect_bd_net $ACLK [get_bd_pins $axis_broadcaster_2/aclk]
# Connect resets
connect_bd_net $ARESETN [get_bd_pins $axis_broadcaster_0/aresetn]
connect_bd_net $ARESETN [get_bd_pins $axis_broadcaster_1/aresetn]
connect_bd_net $ARESETN [get_bd_pins $axis_broadcaster_2/aresetn]
#

# create axi-stream interconnect(s)
set axis_interconnect_0 larpix_uart_array/axis_interconnect_0
set axis_interconnect_1 larpix_uart_array/axis_interconnect_1
set axis_interconnect_2 larpix_uart_array/axis_interconnect_2
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 $axis_interconnect_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 $axis_interconnect_1
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 $axis_interconnect_2
set_property location {1 20000 10000} [get_bd_cells $axis_interconnect_0]
set_property location {1 10000 20000} [get_bd_cells $axis_interconnect_1]
set_property location {1 10000 0} [get_bd_cells $axis_interconnect_2]
# axis interconnect 0 settings
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1} CONFIG.M00_FIFO_DEPTH {4096} CONFIG.S00_FIFO_DEPTH {16} CONFIG.S01_FIFO_DEPTH {16}] [get_bd_cells $axis_interconnect_0]
# axis interconnect 1 settings
set_property -dict [list CONFIG.NUM_SI {16} CONFIG.NUM_MI {1} CONFIG.M00_FIFO_DEPTH {1024} CONFIG.M01_FIFO_DEPTH {16} CONFIG.M02_FIFO_DEPTH {16} CONFIG.M03_FIFO_DEPTH {16} CONFIG.M04_FIFO_DEPTH {16} CONFIG.S00_FIFO_DEPTH {16} CONFIG.S01_FIFO_DEPTH {16} CONFIG.S02_FIFO_DEPTH {16} CONFIG.S03_FIFO_DEPTH {16} CONFIG.S04_FIFO_DEPTH {16} CONFIG.S05_FIFO_DEPTH {16} CONFIG.S06_FIFO_DEPTH {16} CONFIG.S07_FIFO_DEPTH {16} CONFIG.S08_FIFO_DEPTH {16} CONFIG.S09_FIFO_DEPTH {16} CONFIG.S10_FIFO_DEPTH {16} CONFIG.S11_FIFO_DEPTH {16} CONFIG.S12_FIFO_DEPTH {16} CONFIG.S13_FIFO_DEPTH {16} CONFIG.S14_FIFO_DEPTH {16} CONFIG.S15_FIFO_DEPTH {16}] [get_bd_cells $axis_interconnect_1]
# axis interconnect 2 settings
set_property -dict [list CONFIG.NUM_SI {16} CONFIG.NUM_MI {1} CONFIG.M00_FIFO_DEPTH {1024} CONFIG.M01_FIFO_DEPTH {16} CONFIG.M02_FIFO_DEPTH {16} CONFIG.M03_FIFO_DEPTH {16} CONFIG.M04_FIFO_DEPTH {16} CONFIG.S00_FIFO_DEPTH {16} CONFIG.S01_FIFO_DEPTH {16} CONFIG.S02_FIFO_DEPTH {16} CONFIG.S03_FIFO_DEPTH {16} CONFIG.S04_FIFO_DEPTH {16} CONFIG.S05_FIFO_DEPTH {16} CONFIG.S06_FIFO_DEPTH {16} CONFIG.S07_FIFO_DEPTH {16} CONFIG.S08_FIFO_DEPTH {16} CONFIG.S09_FIFO_DEPTH {16} CONFIG.S10_FIFO_DEPTH {16} CONFIG.S11_FIFO_DEPTH {16} CONFIG.S12_FIFO_DEPTH {16} CONFIG.S13_FIFO_DEPTH {16} CONFIG.S14_FIFO_DEPTH {16} CONFIG.S15_FIFO_DEPTH {16}] [get_bd_cells $axis_interconnect_2]
# Connect axi streams
connect_bd_intf_net $M_AXIS [get_bd_intf_pins $axis_interconnect_0/M00_AXIS]
connect_bd_intf_net [get_bd_intf_pins $axis_interconnect_1/M00_AXIS] [get_bd_intf_pins $axis_interconnect_0/S00_AXIS]
connect_bd_intf_net [get_bd_intf_pins $axis_interconnect_2/M00_AXIS] [get_bd_intf_pins $axis_interconnect_0/S01_AXIS]
# Connect clocks
connect_bd_net $ACLK [get_bd_pins $axis_interconnect_0/ACLK]
connect_bd_net $ACLK [get_bd_pins $axis_interconnect_0/M00_AXIS_ACLK]
connect_bd_net $ACLK [get_bd_pins $axis_interconnect_0/S00_AXIS_ACLK]
connect_bd_net $ACLK [get_bd_pins $axis_interconnect_0/S01_AXIS_ACLK]
connect_bd_net $ACLK [get_bd_pins $axis_interconnect_1/ACLK]
connect_bd_net $ACLK [get_bd_pins $axis_interconnect_1/M00_AXIS_ACLK]
connect_bd_net $ACLK [get_bd_pins $axis_interconnect_2/ACLK]
connect_bd_net $ACLK [get_bd_pins $axis_interconnect_2/M00_AXIS_ACLK]
# Connect resets
connect_bd_net $ARESETN [get_bd_pins $axis_interconnect_0/ARESETN]
connect_bd_net $ARESETN [get_bd_pins $axis_interconnect_0/M00_AXIS_ARESETN]
connect_bd_net $ARESETN [get_bd_pins $axis_interconnect_0/S00_AXIS_ARESETN]
connect_bd_net $ARESETN [get_bd_pins $axis_interconnect_0/S01_AXIS_ARESETN]
connect_bd_net $ARESETN [get_bd_pins $axis_interconnect_1/ARESETN]
connect_bd_net $ARESETN [get_bd_pins $axis_interconnect_1/M00_AXIS_ARESETN]
connect_bd_net $ARESETN [get_bd_pins $axis_interconnect_2/ARESETN]
connect_bd_net $ARESETN [get_bd_pins $axis_interconnect_2/M00_AXIS_ARESETN]
#

# create uart channels from existing block
set n_channels 32
for {set channel 1} {$channel < [expr { $n_channels + 1 }]} {incr channel} {
    puts "Generating channel ${channel}..."
    set channel_hex [format %02X $channel]
    set channel_major [expr { int(($channel - 1) / 16) + 1 }]
    set channel_minor [expr { ($channel - 1) % 16 }]
    set channel_minor_padded [format %02d $channel_minor]
    set channel_padded [format %02d [expr {$channel - 1}]]
    puts "Channel refs x$channel_hex, M$channel_major, m$channel_minor, mp$channel_minor_padded, cp$channel_padded..."
    
    copy_bd_objs larpix_uart_array [get_bd_cells {larpix_uart_channel_1}]
    set larpix_uart_channel larpix_uart_array/larpix_uart_channel_$channel
    set channel_s_axis larpix_uart_array/axis_interconnect_${channel_major}/S$channel_minor_padded
    set channel_m_axis larpix_uart_array/axis_broadcaster_${channel_major}/M$channel_minor_padded
    set channel_m_aximm larpix_uart_array/aximm_interconnect_0/M$channel_padded
    set_property location {1 0 ${channel}0000} [get_bd_cells $larpix_uart_channel]

    # set channel property
    set_property -dict [list CONFIG.C_CHANNEL 0x$channel_hex] [get_bd_cells $larpix_uart_channel/larpix_uart_rx_0]
    set_property -dict [list CONFIG.C_CHANNEL 0x$channel_hex] [get_bd_cells $larpix_uart_channel/larpix_uart_tx_0]

    # make connections
    # axi-stream master
    connect_bd_intf_net [get_bd_intf_pins ${channel_s_axis}_AXIS] [get_bd_intf_pins $larpix_uart_channel/M_AXIS]
    connect_bd_net [get_bd_pins ${channel_s_axis}_AXIS_ACLK] $ACLK
    connect_bd_net [get_bd_pins ${channel_s_axis}_AXIS_ARESETN] $ARESETN
    # axi-stream slave
    connect_bd_intf_net [get_bd_intf_pins ${channel_m_axis}_AXIS] [get_bd_intf_pins $larpix_uart_channel/S_AXIS]
    # axi-lite mm
    connect_bd_intf_net [get_bd_intf_pins ${channel_m_aximm}_AXI] [get_bd_intf_pins $larpix_uart_channel/S00_AXI]
    connect_bd_net [get_bd_pins ${channel_m_aximm}_ACLK] $ACLK
    connect_bd_net [get_bd_pins ${channel_m_aximm}_ARESETN] $ARESETN

    # other pins
    connect_bd_net [get_bd_pins larpix_uart_array/larpix_uart_channel_$channel/ACLK] $ACLK
    connect_bd_net [get_bd_pins larpix_uart_array/larpix_uart_channel_$channel/ARESETN] $ARESETN
    connect_bd_net [get_bd_pins larpix_uart_array/larpix_uart_channel_$channel/MCLK] $MCLK
    connect_bd_net [get_bd_pins larpix_uart_array/larpix_uart_channel_$channel/PACMAN_TS] $PACMAN_TS

    # external pins
    set UART_RX [create_bd_pin -dir I larpix_uart_array/UART_RX_$channel]
    set UART_TX [create_bd_pin -dir O larpix_uart_array/UART_TX_$channel]
    connect_bd_net [get_bd_pins larpix_uart_array/larpix_uart_channel_$channel/UART_RX] $UART_RX
    connect_bd_net [get_bd_pins larpix_uart_array/larpix_uart_channel_$channel/UART_TX] $UART_TX
    # loop back (comment out if not)
    connect_bd_net $UART_TX $UART_RX

    # setup reserved addresses
    set seg_ro [get_bd_addr_segs larpix_uart_array/larpix_uart_channel_$channel/axi_lite_reg_space/axi_lite_read_only*]
    set seg_rw [get_bd_addr_segs larpix_uart_array/larpix_uart_channel_$channel/axi_lite_reg_space/axi_lite_read_write*]
    create_bd_addr_seg -range 4K -offset 0x50${channel_hex}0000 [get_bd_addr_spaces processing_system7_0/Data] $seg_ro seg_uart_ro_$channel
    create_bd_addr_seg -range 4K -offset 0x50${channel_hex}1000 [get_bd_addr_spaces processing_system7_0/Data] $seg_rw seg_uart_rw_$channel
    
    save_bd_design
}

close_bd_design [ get_bd_designs zsys ]

update_compile_order -fileset sources_1

puts "Done!"
