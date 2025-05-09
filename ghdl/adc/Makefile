all: modules-a modules-e testbenches run-units

modules-a:
	echo "*** modules analysis ***"
	ghdl -a ../integration/common.vhd
	ghdl -a ADC_DAQ.vhd
	ghdl -a ADC_reg.vhd
	ghdl -a ADC_CLK_DIV.vhd
	ghdl -a ADC_unit.vhd
modules-e:
	echo "*** module elaboration ***"
	ghdl -e ADC_DAQ
	ghdl -e ADC_reg
	ghdl -e ADC_CLK_DIV
	ghdl -e ADC_unit
testbenches:
	echo "*** testbench analysis and elaboration ***"
	ghdl -a -fsynopsys ADC_DAQ_tb.vhd
	ghdl -e -fsynopsys ADC_DAQ_tb
run-units:
	echo "*** running ***"
	ghdl -r -fsynopsys ADC_DAQ_tb --stop-time=1ms --vcd=bl.vcd 
