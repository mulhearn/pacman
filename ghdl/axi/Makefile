all: modules-a modules-e testbenches hardware

modules-a:
	echo "*** modules analysis ***"
	ghdl -a ../integration/common.vhd
	ghdl -a axil_to_regbus.vhd
	ghdl -a axis_write.vhd
modules-e:
	echo "*** module elaboration ***"
	ghdl -e axil_to_regbus
	ghdl -e axis_write
testbenches:
	echo "*** testbench analysis and elaboration ***"
	ghdl -a -fsynopsys tb/axil_to_regbus_tb.vhd
	ghdl -a -fsynopsys tb/axis_write_tb.vhd
	ghdl -e -fsynopsys axil_to_regbus_tb
	ghdl -e -fsynopsys axis_write_tb
hardware:
	echo "*** HW demos ***"
	ghdl -a hw/regbus_demo.vhd
	ghdl -e regbus_demo
	ghdl -a -fsynopsys hw/regbus_demo_tb.vhd
	ghdl -e -fsynopsys regbus_demo_tb
	ghdl -a hw/axis_demo.vhd
	ghdl -e axis_demo
	ghdl -a -fsynopsys hw/axis_demo_tb.vhd
	ghdl -e -fsynopsys axis_demo_tb

run-units:
	ghdl -r -fsynopsys axil_to_regbus_tb --stop-time=350ns
	ghdl -r -fsynopsys axis_write_tb --stop-time=300ns
run-demos:
#	ghdl -r -fsynopsys regbus_demo_tb --stop-time=350ns
	ghdl -r -fsynopsys axis_demo_tb --stop-time=350ns
