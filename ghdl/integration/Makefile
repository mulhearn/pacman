all: modules-a modules-e testbenches

modules-a:
	ghdl -a common.vhd
	ghdl -a register_map.vhd
	ghdl -a gen/version_info_pkg.vhd
	ghdl -a ../tx/uart_tx.vhd
	ghdl -a ../rx/uart_rx.vhd
modules-e:
	ghdl -e uart_rx
	ghdl -e uart_tx
testbenches:
	ghdl -a -fsynopsys tb/uart_loopback_tb.vhd
	ghdl -e -fsynopsys uart_loopback_tb

run-testbenches:
	ghdl -r -fsynopsys uart_loopback_tb --stop-time=30000ns


