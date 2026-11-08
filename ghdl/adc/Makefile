all: modules-a modules-e testbenches

modules-a:
	echo "*** modules analysis ***"
	ghdl -a ../integration/common.vhd
	ghdl -a ../integration/register_map.vhd
	ghdl -a adc_registers.vhd
	ghdl -a adc_unit.vhd

modules-e:
	echo "*** module elaboration ***"
	ghdl -e adc_registers
	ghdl -e adc_unit

testbenches:
	echo "*** testbench analysis and elaboration ***"
	ghdl -a -fsynopsys tb/adc_registers_tb.vhd
	ghdl -a -fsynopsys tb/adc_unit_tb.vhd
	ghdl -e -fsynopsys adc_registers_tb
	ghdl -e -fsynopsys adc_unit_tb

run-testbenches:
	echo "*** running ***"
	ghdl -r -fsynopsys adc_registers_tb --stop-time=1us
	ghdl -r -fsynopsys adc_unit_tb --stop-time=1us 


