all: modules-a modules-e testbenches

modules-a:
	echo "*** modules analysis ***"
	ghdl -a ../integration/common.vhd
	ghdl -a rising_edge_sync.vhd
	ghdl -a toggle_only_sync.vhd
	ghdl -a update_request.vhd
	ghdl -a update_reply.vhd
	ghdl -a poke_sync.vhd

modules-e:
	echo "*** module elaboration ***"
	ghdl -e rising_edge_sync
	ghdl -e update_request
	ghdl -e update_reply
	ghdl -e poke_sync
testbenches:
	echo "*** testbench analysis and elaboration ***"
	ghdl -a -fsynopsys tb/rising_edge_sync_tb.vhd
	ghdl -e -fsynopsys rising_edge_sync_tb
	ghdl -a -fsynopsys tb/toggle_only_sync_tb.vhd
	ghdl -e -fsynopsys toggle_only_sync_tb
	ghdl -a -fsynopsys tb/update_tb.vhd
	ghdl -e -fsynopsys update_tb
	ghdl -a -fsynopsys tb/poke_sync_tb.vhd
	ghdl -e -fsynopsys poke_sync_tb




run-testbenches: all
	ghdl -r -fsynopsys rising_edge_sync_tb --stop-time=2000ns
	ghdl -r -fsynopsys toggle_only_sync_tb --stop-time=1000ns
	ghdl -r -fsynopsys update_tb --stop-time=1000ns
	ghdl -r -fsynopsys poke_sync_tb --stop-time=1000ns

run-dev: all
	ghdl -r -fsynopsys poke_sync_tb --stop-time=1000ns
