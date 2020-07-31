#
# A long tcl script to automatically generate a 32-channel uart array block (instead of wiring
# all of the signals by hand, which would take the better part of a day)
#
# This will generate a new larpix_uart_array hierarchy complete with axi interconnects and
# larpix_uart_channel modules. It doesn't connect a few signals (MOSI/MISO BUSY), but that's easy
# to do by hand. Also please inspect the block diagram before building!
#
# Usage:
#   vivado -mode batch -source tcl/gen_uart_bd.tcl
#

# Number of UART RTL modules to instantiate
set n_channels 4
# If loopback is set, channels are only routed internally and in a loopback fashion
# comment out for production use
#set loopback "True"
set loopback ""

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

set larpix_uart_array [create_bd_cell -type hier larpix_uart_array]
set ACLK [create_bd_pin -dir I larpix_uart_array/ACLK -type clk]
connect_bd_net $ACLK [get_bd_pins processing_system7_0/FCLK_CLK0]
set ARESETN [create_bd_pin -dir I larpix_uart_array/ARESETN -type rst]
connect_bd_net $ARESETN [get_bd_pins rst_ps7_0_100M/peripheral_aresetn]
set MCLK [create_bd_pin -dir I larpix_uart_array/MCLK -type clk]
connect_bd_net $MCLK [get_bd_pins larpix_clk/MCLK]
set PACMAN_TS [create_bd_pin -dir I -from 31 -to 0 larpix_uart_array/PACMAN_TS]
connect_bd_net $PACMAN_TS [get_bd_pins larpix_clk/TIMESTAMP]
set S_AXIMM [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 larpix_uart_array/S_AXIMM]
set UART_RX_BUSY [create_bd_pin -dir O larpix_uart_array/UART_RX_BUSY]
set UART_TX_BUSY [create_bd_pin -dir O larpix_uart_array/UART_TX_BUSY]
save_bd_design

# create axi interface interconnect
connect_bd_intf_net $S_AXIMM [get_bd_intf_pins ps7_0_axi_periph/M04_AXI]
create_bd_cell -type hier larpix_uart_array/aximm
set aximm_interconnect larpix_uart_array/aximm/aximm_interconnect_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 $aximm_interconnect
set_property -dict [list CONFIG.NUM_MI $n_channels] [get_bd_cells $aximm_interconnect]
set_property -dict [list CONFIG.STRATEGY {1} CONFIG.S00_HAS_REGSLICE {0} CONFIG.S00_HAS_DATA_FIFO {0}] [get_bd_cells $aximm_interconnect]
connect_bd_intf_net $S_AXIMM [get_bd_intf_pins $aximm_interconnect/S00_AXI]
connect_bd_net $ACLK [get_bd_pins $aximm_interconnect/ACLK]
connect_bd_net $ACLK [get_bd_pins $aximm_interconnect/S00_ACLK]
connect_bd_net $ARESETN [get_bd_pins $aximm_interconnect/ARESETN]
connect_bd_net $ARESETN [get_bd_pins $aximm_interconnect/S00_ARESETN]
for {set i 0} {$i < $n_channels} {incr i} {
    set i_padded [format %02d $i]
    set_property -dict [list CONFIG.M${i_padded}_HAS_REGSLICE {1}] [get_bd_cells $aximm_interconnect]
    connect_bd_net [get_bd_pins $aximm_interconnect/M${i_padded}_ACLK] $ACLK
    connect_bd_net [get_bd_pins $aximm_interconnect/M${i_padded}_ARESETN] $ARESETN
}
save_bd_design
#

# create axi-stream broadcaster(s)
set axis_broadcast larpix_uart_array/axis_broadcast
create_bd_cell -type hier $axis_broadcast
set axis_broadcaster $axis_broadcast/axis_broadcaster
set n_interfaces 4
set n_broadcasters [expr $n_channels / $n_interfaces]
for {set i 0} {$i < $n_broadcasters} {incr i} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 ${axis_broadcaster}_$i
    
    # axi broadcast settings
    set_property -dict [list CONFIG.M_TDATA_NUM_BYTES.VALUE_SRC USER CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER CONFIG.HAS_TREADY.VALUE_SRC USER CONFIG.HAS_TSTRB.VALUE_SRC USER CONFIG.HAS_TKEEP.VALUE_SRC USER CONFIG.HAS_TLAST.VALUE_SRC USER] [get_bd_cells ${axis_broadcaster}_$i]
    set_property -dict [list CONFIG.NUM_MI $n_interfaces CONFIG.M_TDATA_NUM_BYTES {16} CONFIG.S_TDATA_NUM_BYTES {16}] [get_bd_cells ${axis_broadcaster}_$i]
    set_property -dict [list CONFIG.HAS_TREADY {1} CONFIG.HAS_TKEEP {1} CONFIG.HAS_TLAST {1} CONFIG.HAS_TSTRB {1}] [get_bd_cells ${axis_broadcaster}_$i]
    for {set j 0} {$j < $n_interfaces} {incr j} {
        set j_padded [format %02d $j]
        set_property -dict [list CONFIG.M${j_padded}_TDATA_REMAP {tdata[127:0]}] [get_bd_cells ${axis_broadcaster}_$i]
    }

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
set n_interfaces 4
set n_interconnects [expr $n_channels / $n_interfaces]
for {set i 0} {$i < $n_interconnects} {incr i} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 ${axis_interconnect}_$i
    
    # axi interconnect settings
    set_property -dict [list CONFIG.NUM_SI $n_interfaces CONFIG.NUM_MI {1} CONFIG.M00_FIFO_DEPTH {1024}] [get_bd_cells ${axis_interconnect}_${i}]
    set_property -dict [list CONFIG.M00_HAS_REGSLICE {1}] [get_bd_cells ${axis_interconnect}_${i}]
    set_property -dict [list CONFIG.ARB_ON_NUM_CYCLES {1} CONFIG.ARB_ON_TLAST {1}] [get_bd_cells ${axis_interconnect}_${i}]
    
    # create/connect pins
    set M_AXIS [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 larpix_uart_array/M${i}_AXIS]
    connect_bd_intf_net $M_AXIS [get_bd_intf_pins ${axis_interconnect}_${i}/M00_AXIS]
    connect_bd_intf_net $M_AXIS [get_bd_intf_pins data_rx/S0${i}_AXIS]
    connect_bd_net $ACLK [get_bd_pins ${axis_interconnect}_$i/ACLK]
    connect_bd_net [get_bd_pins ${axis_merge}/ACLK] [get_bd_pins ${axis_interconnect}_${i}/M00_AXIS_ACLK]
    connect_bd_net $ARESETN [get_bd_pins ${axis_interconnect}_${i}/ARESETN]
    connect_bd_net [get_bd_pins ${axis_merge}/ARESETN] [get_bd_pins ${axis_interconnect}_${i}/M00_AXIS_ARESETN]
    for {set j 0} {$j < $n_interfaces} {incr j} {
        set j_padded [format %02d $j]
        set_property -dict [list CONFIG.S${j_padded}_FIFO_DEPTH {0} CONFIG.S${j_padded}_HAS_REGSLICE {0}] [get_bd_cells ${axis_interconnect}_${i}]
        connect_bd_net [get_bd_pins ${axis_merge}/ACLK] [get_bd_pins ${axis_interconnect}_${i}/S${j_padded}_AXIS_ACLK]
        connect_bd_net [get_bd_pins ${axis_merge}/ARESETN] [get_bd_pins ${axis_interconnect}_${i}/S${j_padded}_AXIS_ARESETN]
    }
}
save_bd_design
#    

# create uart channels from existing block
set uart_channels larpix_uart_array/uart_channels
create_bd_cell -type hier $uart_channels
# uart busy signals
set or_uart_rx_busy $uart_channels/or_uart_rx_busy
set or_uart_tx_busy $uart_channels/or_uart_tx_busy
create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic:2.0 ${or_uart_rx_busy}_logic
create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic:2.0 ${or_uart_tx_busy}_logic
set_property -dict [list CONFIG.C_SIZE $n_channels CONFIG.C_OPERATION {or}] [get_bd_cells ${or_uart_rx_busy}_logic]
set_property -dict [list CONFIG.C_SIZE $n_channels CONFIG.C_OPERATION {or}] [get_bd_cells ${or_uart_tx_busy}_logic]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 ${or_uart_rx_busy}
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 ${or_uart_tx_busy}
set_property -dict [list CONFIG.NUM_PORTS $n_channels] [get_bd_cells $or_uart_rx_busy]
set_property -dict [list CONFIG.NUM_PORTS $n_channels] [get_bd_cells $or_uart_tx_busy]
connect_bd_net [get_bd_pins ${or_uart_rx_busy}/dout] [get_bd_pins ${or_uart_rx_busy}_logic/Op1]
connect_bd_net [get_bd_pins ${or_uart_tx_busy}/dout] [get_bd_pins ${or_uart_tx_busy}_logic/Op1]
connect_bd_net [get_bd_pins ${or_uart_rx_busy}_logic/Res] $UART_RX_BUSY
connect_bd_net [get_bd_pins ${or_uart_tx_busy}_logic/Res] $UART_TX_BUSY
for {set channel 1} {$channel < [expr { $n_channels + 1 }]} {incr channel} {
    puts "Generating channel ${channel}..."
    set channel_hex [format %02X $channel]
    set channel_major [expr { int(($channel - 1) / 4) }]
    set channel_minor [expr { ($channel - 1) % 4 }]
    set channel_minor_padded [format %02d $channel_minor]
    set channel_base0 [expr {$channel - 1}]
    set channel_padded [format %02d $channel_base0]
    puts "Channel refs x$channel_hex, M$channel_major, m$channel_minor, mp$channel_minor_padded, cp$channel_padded..."

    # create new uart channel
    set larpix_uart_channel $uart_channels/larpix_uart_channel_$channel
    create_bd_cell -type module -reference uart_channel $larpix_uart_channel

    set channel_s_axis ${axis_interconnect}_${channel_major}/S$channel_minor_padded
    set channel_m_axis ${axis_broadcaster}_${channel_major}/M${channel_minor_padded}
    set channel_m_aximm ${aximm_interconnect}/M$channel_padded

    # set channel property
     set_property -dict [list CONFIG.C_CHANNEL 0x$channel_hex] [get_bd_cells $larpix_uart_channel]

    # make connections
    # axi-stream master
    connect_bd_intf_net [get_bd_intf_pins ${channel_s_axis}_AXIS] [get_bd_intf_pins $larpix_uart_channel/M_AXIS]
    # axi-stream slave
    connect_bd_intf_net [get_bd_intf_pins ${channel_m_axis}_AXIS] [get_bd_intf_pins $larpix_uart_channel/S_AXIS]
    # axi-lite mm
    connect_bd_intf_net [get_bd_intf_pins ${channel_m_aximm}_AXI] [get_bd_intf_pins $larpix_uart_channel/S_AXI_LITE]

    # other pins
    connect_bd_net [get_bd_pins $larpix_uart_channel/ACLK] $ACLK
    connect_bd_net [get_bd_pins $larpix_uart_channel/ARESETN] $ARESETN
    connect_bd_net [get_bd_pins $larpix_uart_channel/MCLK] $MCLK
    connect_bd_net [get_bd_pins $larpix_uart_channel/PACMAN_TS] $PACMAN_TS
    connect_bd_net [get_bd_pins $larpix_uart_channel/UART_RX_BUSY] [get_bd_pins $or_uart_rx_busy/In$channel_base0]
    connect_bd_net [get_bd_pins $larpix_uart_channel/UART_TX_BUSY] [get_bd_pins $or_uart_tx_busy/In$channel_base0]

    # external uart pins
    set UART_RX [create_bd_pin -dir I larpix_uart_array/UART_RX_$channel]
    set UART_TX [create_bd_pin -dir O larpix_uart_array/UART_TX_$channel]
    connect_bd_net [get_bd_pins $larpix_uart_channel/UART_RX] $UART_RX
    connect_bd_net [get_bd_pins $larpix_uart_channel/UART_TX] $UART_TX
    if {$loopback != ""} {
        connect_bd_net $UART_TX $UART_RX
    } else {
        set MOSI [get_bd_pins io/I_MOSI$channel]
        set MISO [get_bd_ports MISO$channel]
        if {$MOSI != ""} {
            connect_bd_net $UART_TX $MOSI
        }
        if {$MISO != ""} {
            connect_bd_net $UART_RX $MISO
        }
    }

    # setup reserved addresses
    set seg [get_bd_addr_segs $larpix_uart_channel/S_AXI_LITE/reg0]
    set addr [expr 0x500${channel_hex}000 + 0x2000]
    create_bd_addr_seg -range 4K -offset ${addr} [get_bd_addr_spaces processing_system7_0/Data] $seg seg_uart_$channel
    
    save_bd_design
}

close_bd_design [ get_bd_designs zsys ]

update_compile_order -fileset sources_1

puts "Done!"
