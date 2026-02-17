all: modules-a modules-e testbenches

modules-a:
	ghdl -a --warn-all ../hardware/hw1v5/hardware_version.vhd
	ghdl -a --warn-all ../integration/firmware_version.vhd
	ghdl -a --warn-all ../integration/common.vhd
	ghdl -a --warn-all ../integration/register_map.vhd
	ghdl -a --warn-all ../integration/gen/version_info_pkg.vhd
	ghdl -a --warn-all global_registers.vhd
	ghdl -a --warn-all global_status.vhd
	ghdl -a --warn-all global_unit.vhd
modules-e:
	ghdl -e --warn-all global_registers
	ghdl -e --warn-all global_status
	ghdl -e --warn-all global_unit
testbenches:
	ghdl -a -fsynopsys tb/global_registers_tb.vhd 
	ghdl -e -fsynopsys global_registers_tb
	ghdl -a -fsynopsys tb/global_status_tb.vhd
	ghdl -e -fsynopsys global_status_tb
	ghdl -a -fsynopsys tb/global_unit_tb.vhd
	ghdl -e -fsynopsys global_unit_tb
run-testbenches: all
	ghdl -r --warn-all -fsynopsys global_registers_tb --stop-time=220ns --vcd=../diagrams/global_registers_tb.vcd 
	ghdl -r --warn-all -fsynopsys global_status_tb --stop-time=150ns
run-unit-testbench: all
	ghdl -r --warn-all -fsynopsys global_unit_tb --stop-time=150ns
