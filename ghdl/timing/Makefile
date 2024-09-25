all: modules-a modules-e testbenches

modules-a:
	echo "*** modules analysis ***"
	ghdl -a ../integration/common.vhd
	ghdl -a ../integration/register_map.vhd
	ghdl -a slow_broadcast.vhd
	ghdl -a timing_registers.vhd
	ghdl -a timing_unit.vhd
modules-e:
	echo "*** module elaboration ***"
	ghdl -e slow_broadcast
	ghdl -e timing_registers
	ghdl -e timing_unit
testbenches:
	echo "*** testbench analysis and elaboration ***"
	ghdl -a -fsynopsys tb/slow_broadcast_tb.vhd
	ghdl -e -fsynopsys slow_broadcast_tb
	ghdl -a -fsynopsys tb/timing_registers_tb.vhd
	ghdl -e -fsynopsys timing_registers_tb
	ghdl -a -fsynopsys tb/timing_unit_tb.vhd
	ghdl -e -fsynopsys timing_unit_tb

run-units:
	ghdl -r -fsynopsys slow_broadcast_tb --stop-time=3500ns
	ghdl -r -fsynopsys timing_registers_tb --stop-time=3500ns
	ghdl -r -fsynopsys timing_unit_tb --stop-time=3500ns


