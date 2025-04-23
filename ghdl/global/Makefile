all: modules-a modules-e testbenches

modules-a:
	ghdl -a ../integration/version.vhd
	ghdl -a ../integration/common.vhd
	ghdl -a ../integration/register_map.vhd
	ghdl -a global_registers.vhd
	ghdl -a global_status.vhd
	ghdl -a global_unit.vhd
modules-e:
	ghdl -e global_registers
	ghdl -e global_status
	ghdl -e global_unit

testbenches:
	ghdl -a -fsynopsys tb/global_registers_tb.vhd
	ghdl -e -fsynopsys global_registers_tb
	ghdl -a -fsynopsys tb/global_status_tb.vhd
	ghdl -e -fsynopsys global_status_tb
	ghdl -a -fsynopsys tb/global_unit_tb.vhd
	ghdl -e -fsynopsys global_unit_tb

run-units: all
	ghdl -r -fsynopsys global_registers_tb --stop-time=350ns
	ghdl -r -fsynopsys global_status_tb --stop-time=350ns

run-demos: all
	ghdl -r -fsynopsys global_unit_tb --stop-time=350ns
