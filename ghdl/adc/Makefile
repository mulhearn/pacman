all: modules-a modules-e testbenches run-units

modules-a:
	echo "*** modules analysis ***"
	ghdl -a ../integration/common.vhd
	ghdl -a adc_daq.vhd
	ghdl -a adc_reg.vhd
	ghdl -a ADC_CLK_DIV.vhd
	ghdl -a adc_unit.vhd
	ghdl -a const_bram.vhd
modules-e:
	echo "*** module elaboration ***"
	ghdl -e adc_daq
	ghdl -e adc_reg
	ghdl -e ADC_CLK_DIV
	ghdl -e adc_unit
	ghdl -e const_bram
testbenches:
	echo "*** testbench analysis and elaboration ***"
	ghdl -a -fsynopsys tb/ADC_CLK_DIV_tb.vhd
	ghdl -a -fsynopsys tb/adc_daq_tb.vhd
	ghdl -a -fsynopsys tb/adc_reg_tb.vhd
	ghdl -a -fsynopsys tb/adc_unit_tb.vhd
	ghdl -e -fsynopsys ADC_CLK_DIV_tb
	ghdl -e -fsynopsys adc_daq_tb
	ghdl -e -fsynopsys adc_reg_tb
	ghdl -e -fsynopsys adc_unit_tb

run-units:
	echo "*** running ***"
	ghdl -r -fsynopsys ADC_CLK_DIV_tb --stop-time=1ms --vcd=bl.vcd 
	ghdl -r -fsynopsys adc_daq_tb --stop-time=1ms --vcd=bl.vcd 
	ghdl -r -fsynopsys adc_reg_tb --stop-time=1ms --vcd=bl.vcd 
	ghdl -r -fsynopsys adc_unit_tb --stop-time=1ms --vcd=bl.vcd 

