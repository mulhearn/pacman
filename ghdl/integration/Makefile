all: modules-a modules-e testbenches

modules-a:
	ghdl -a common.vhd
	ghdl -a register_map.vhd
	ghdl -a uart_rx.vhd
	ghdl -a uart_tx.vhd
	ghdl -a rx_buffer.vhd
	ghdl -a rx_registers.vhd
	ghdl -a rx_unit.vhd
	ghdl -a tx_buffer.vhd
	ghdl -a tx_registers.vhd
	ghdl -a tx_chan.vhd
	ghdl -a tx_unit.vhd
modules-e:
	ghdl -e uart_rx
	ghdl -e uart_tx
	ghdl -e rx_buffer
	ghdl -e rx_registers
	ghdl -e rx_unit
	ghdl -e tx_buffer
	ghdl -e tx_registers
	ghdl -e tx_chan
	ghdl -e tx_unit
testbenches:
	ghdl -a -fsynopsys tb/uart_rx_tb.vhd
	ghdl -a -fsynopsys tb/rx_buffer_tb.vhd
	ghdl -a -fsynopsys tb/rx_registers_tb.vhd
	ghdl -a -fsynopsys tb/rx_unit_tb.vhd
	ghdl -a -fsynopsys tb/tx_buffer_tb.vhd
	ghdl -a -fsynopsys tb/tx_registers_tb.vhd
	ghdl -a -fsynopsys tb/tx_chan_tb.vhd
	ghdl -a -fsynopsys tb/tx_unit_tb.vhd
	ghdl -a -fsynopsys tb/uart_loopback_tb.vhd
	ghdl -a -fsynopsys tb/single_shot_tb.vhd
	ghdl -e -fsynopsys uart_rx_tb 
	ghdl -e -fsynopsys rx_buffer_tb 
	ghdl -e -fsynopsys rx_registers_tb 
	ghdl -e -fsynopsys rx_unit_tb 
	ghdl -e -fsynopsys tx_buffer_tb 
	ghdl -e -fsynopsys tx_registers_tb 
	ghdl -e -fsynopsys tx_chan_tb
	ghdl -e -fsynopsys tx_unit_tb
	ghdl -e -fsynopsys uart_loopback_tb 
	ghdl -e -fsynopsys single_shot_tb
run:
	ghdl -r -fsynopsys uart_rx_tb --stop-time=7600ns
	ghdl -r -fsynopsys rx_buffer_tb --stop-time=7600ns
	ghdl -r -fsynopsys rx_buffer_tb --stop-time=15450ns
	ghdl -r -fsynopsys rx_registers_tb --stop-time=300ns
	ghdl -r -fsynopsys rx_unit_tb --stop-time=300ns
	ghdl -r -fsynopsys tx_buffer_tb --stop-time=7000ns
	ghdl -r -fsynopsys tx_registers_tb --stop-time=300ns
	ghdl -r -fsynopsys tx_unit_tb --stop-time=300ns
	ghdl -r -fsynopsys uart_loopback_tb --stop-time=7000ns
focus: all
	ghdl -r -fsynopsys single_shot_tb --stop-time=30000ns
