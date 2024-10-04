
all:
	ghdl -a axil_demo_ro.vhd
	ghdl -a axil_demo_rw.vhd
	ghdl -a -fsynopsys axil_demo_ro_tb.vhd
	ghdl -a -fsynopsys axil_demo_rw_tb.vhd

run:
	ghdl -r -fsynopsys axil_demo_rw_tb --stop-time=350ns 

