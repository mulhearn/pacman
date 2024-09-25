all: modules-a modules-e testbenches

modules-a:
	ghdl -a ../integration/version.vhd
	ghdl -a ../integration/common.vhd
	ghdl -a ../integration/register_map.vhd
	ghdl -a global_registers.vhd
modules-e:
	ghdl -e global_registers

testbenches:
	ghdl -a -fsynopsys tb/global_registers_tb.vhd
	ghdl -e -fsynopsys global_registers_tb

run-units: all
	ghdl -r -fsynopsys global_registers_tb --stop-time=350ns

run-demos: all
	ghdl -r -fsynopsys global_registers_tb --stop-time=350ns
