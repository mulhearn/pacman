all: modules-a modules-e testbenches

modules-a:
	ghdl -a ../integration/common.vhd
	ghdl -a ../integration/register_map.vhd
	ghdl -a ../axi/axis_write.vhd
	ghdl -a uart_rx.vhd
	ghdl -a rx_registers.vhd
	ghdl -a rx_chan.vhd
	ghdl -a heartbeat.vhd
	ghdl -a rollover.vhd
	ghdl -a rx_buffer.vhd
	ghdl -a rx_unit.vhd
modules-e:
	ghdl -e uart_rx
	ghdl -e rx_registers
	ghdl -e rx_chan
	ghdl -e heartbeat
	ghdl -e rollover
	ghdl -e rx_buffer
	ghdl -e rx_unit
testbenches:
	ghdl -a -fsynopsys tb/rx_registers_tb.vhd
	ghdl -e -fsynopsys rx_registers_tb
	ghdl -a -fsynopsys tb/rx_chan_tb.vhd
	ghdl -a -fsynopsys tb/heartbeat_tb.vhd
	ghdl -a -fsynopsys tb/rollover_tb.vhd
	ghdl -e -fsynopsys rx_chan_tb
	ghdl -a -fsynopsys tb/rx_buffer_tb.vhd
	ghdl -e -fsynopsys rx_buffer_tb
	ghdl -a -fsynopsys tb/rx_unit_tb.vhd
	ghdl -e -fsynopsys rx_unit_tb

run-units: all
	ghdl -r -fsynopsys rx_registers_tb --stop-time=350ns
	ghdl -r -fsynopsys rx_chan_tb --stop-time=30us
	ghdl -r -fsynopsys heartbeat_tb --stop-time=30us
	ghdl -r -fsynopsys rollover_tb --stop-time=30us
	ghdl -r -fsynopsys rx_buffer_tb --stop-time=5us
run-demos: all
	ghdl -r -fsynopsys rx_unit_tb --stop-time=30us
