all:
	ghdl -a uart_tx.vhd
	ghdl -a uart_rx.vhd
	ghdl -a -fsynopsys uart_loopback_tb.vhd
	ghdl -a axis_double.vhd
	ghdl -a -fsynopsys axis_double_tb.vhd
run:
	#ghdl -r -fsynopsys uart_loopback_tb --stop-time=7500ns
	ghdl -r -fsynopsys axis_double_tb --stop-time=250ns 

