all:
	ghdl -a ../integration/common.vhd
	ghdl -a axil_to_regbus.vhd
	ghdl -a regbus_mux.vhd
	ghdl -a registers_scratch.vhd
	ghdl -a -fsynopsys tb/axil_to_regbus_tb.vhd
	ghdl -a -fsynopsys tb/regbus_mux_tb.vhd
	ghdl -a -fsynopsys tb/registers_scratch_tb.vhd
	ghdl -a -fsynopsys tb/integration_tb.vhd
run:
	ghdl -r -fsynopsys axil_to_regbus_tb --stop-time=350ns
	ghdl -r -fsynopsys regbus_mux_tb --stop-time=350ns
	ghdl -r -fsynopsys registers_scratch_tb --stop-time=350ns
	ghdl -r -fsynopsys integration_tb --stop-time=350ns 

