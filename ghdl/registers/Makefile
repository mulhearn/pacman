all: modules-a modules-e testbenches hardware

modules-a:
	echo "*** modules analysis ***"
	ghdl -a ../integration/common.vhd
	ghdl -a regbus_mux.vhd
	ghdl -a registers_scratch.vhd
modules-e:
	echo "*** module elaboration ***"
	ghdl -e regbus_mux
	ghdl -e registers_scratch
testbenches:
	echo "*** testbench analysis and elaboration ***"
	ghdl -a -fsynopsys tb/regbus_mux_tb.vhd
	ghdl -a -fsynopsys tb/registers_scratch_tb.vhd
	ghdl -e -fsynopsys regbus_mux_tb
	ghdl -e -fsynopsys registers_scratch_tb
hardware:
	echo "*** HW demos ***"
	ghdl -a -fsynopsys hw/registers_demo.vhd
	ghdl -e -fsynopsys registers_demo
	ghdl -a -fsynopsys hw/registers_demo_tb.vhd
	ghdl -e -fsynopsys registers_demo_tb
run-units:
	ghdl -r -fsynopsys regbus_mux_tb --stop-time=350ns
	ghdl -r -fsynopsys registers_scratch_tb --stop-time=350ns
run-demos:
	ghdl -r -fsynopsys registers_demo_tb --stop-time=350ns 

