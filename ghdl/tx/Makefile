all: modules-a modules-e testbenches

modules-a:
	ghdl -a ../integration/common.vhd
	ghdl -a ../integration/register_map.vhd
	ghdl -a ../axi/axis_read.vhd
	ghdl -a uart_tx.vhd
	ghdl -a tx_chan.vhd
	ghdl -a tx_registers.vhd
	ghdl -a tx_buffer.vhd
	ghdl -a tx_unit.vhd
modules-e:
	ghdl -e axis_read
	ghdl -e uart_tx
	ghdl -e tx_chan
	ghdl -e tx_registers
	ghdl -e tx_buffer
	ghdl -e tx_unit
testbenches:
	ghdl -a -fsynopsys tb/tx_chan_tb.vhd
	ghdl -e -fsynopsys tx_chan_tb
	ghdl -a -fsynopsys tb/tx_registers_tb.vhd
	ghdl -e -fsynopsys tx_registers_tb
	ghdl -a -fsynopsys tb/tx_buffer_tb.vhd
	ghdl -e -fsynopsys tx_buffer_tb
	ghdl -a -fsynopsys tb/tx_unit_tb.vhd
	ghdl -e -fsynopsys tx_unit_tb

run-units:
	ghdl -r -fsynopsys tx_chan_tb --stop-time=30000ns
	ghdl -r -fsynopsys tx_registers_tb --stop-time=350ns
	ghdl -r -fsynopsys tx_buffer_tb --stop-time=3500ns

run-demos:
	ghdl -r -fsynopsys tx_unit_tb --stop-time=20us
