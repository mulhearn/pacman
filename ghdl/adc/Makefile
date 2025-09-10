all: modules-a modules-e testbenches

modules-a:
	echo "*** modules analysis ***"
	ghdl -a ../integration/common.vhd
	ghdl -a const_bram.vhd
	ghdl -a adc_clk_div.vhd
	ghdl -a adc_reg.vhd
	ghdl -a adc_daq.vhd
	ghdl -a adc_unit.vhd

modules-e:
	echo "*** module elaboration ***"
	ghdl -e const_bram
	ghdl -e adc_clk_div
	ghdl -e adc_reg
	ghdl -e adc_daq
	ghdl -e adc_unit


testbenches:
	echo "*** testbench analysis and elaboration ***"
	ghdl -a -fsynopsys tb/adc_reg_tb.vhd
	ghdl -a -fsynopsys tb/adc_daq_tb.vhd
	ghdl -a -fsynopsys tb/adc_unit_tb.vhd
	ghdl -e -fsynopsys adc_reg_tb
	ghdl -e -fsynopsys adc_daq_tb
	ghdl -e -fsynopsys adc_unit_tb

run-testbenches:
	echo "*** running ***"
	ghdl -r -fsynopsys adc_reg_tb --stop-time=1ms
	ghdl -r -fsynopsys adc_daq_tb --stop-time=1ms
	ghdl -r -fsynopsys adc_unit_tb --stop-time=1ms --vcd=bl.vcd 
	#ghdl -r -fsynopsys adc_reg_tb --stop-time=1ms --vcd=bl.vcd 
	#ghdl -r -fsynopsys adc_daq_tb --stop-time=1ms --vcd=bl.vcd 
	#ghdl -r -fsynopsys adc_unit_tb --stop-time=1ms --vcd=bl.vcd 

