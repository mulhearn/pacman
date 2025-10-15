all: modules-a modules-e testbenches

modules-a:
	echo "*** modules analysis ***"
	ghdl -a ../integration/common.vhd
	ghdl -a ../integration/register_map.vhd
	ghdl -a ../cdc/rising_edge_sync.vhd
	ghdl -a ../cdc/toggle_only_sync.vhd
	ghdl -a ../cdc/update_request.vhd
	ghdl -a ../cdc/update_reply.vhd
	ghdl -a ../cdc/poke_sync.vhd
	ghdl -a atc_pkg.vhd
	ghdl -a atc_registers.vhd
	ghdl -a config_sync.vhd
	ghdl -a timestamp_simple.vhd
	ghdl -a timestamp_sync.vhd
	ghdl -a atc_bridge.vhd
	ghdl -a atc_unit.vhd

modules-e:
	echo "*** module elaboration ***"
	ghdl -e rising_edge_sync
	ghdl -e toggle_only_sync
	ghdl -e update_request
	ghdl -e update_reply
	ghdl -e poke_sync
	ghdl -e atc_registers
	ghdl -e config_sync
	ghdl -e timestamp_simple
	ghdl -e timestamp_sync
	ghdl -e atc_bridge
	ghdl -e atc_unit

testbenches:
	echo "*** testbench analysis and elaboration ***"
	ghdl -a -fsynopsys tb/atc_registers_tb.vhd
	ghdl -e -fsynopsys atc_registers_tb
	ghdl -a -fsynopsys tb/config_sync_tb.vhd
	ghdl -e -fsynopsys config_sync_tb
	ghdl -a -fsynopsys tb/timestamp_tb.vhd
	ghdl -e -fsynopsys timestamp_tb
	ghdl -a -fsynopsys tb/atc_bridge_tb.vhd
	ghdl -e -fsynopsys atc_bridge_tb
	ghdl -a -fsynopsys tb/atc_unit_tb.vhd
	ghdl -e -fsynopsys atc_unit_tb


run-testbenches: all
	ghdl -r -fsynopsys atc_registers_tb --stop-time=500ns
	ghdl -r -fsynopsys config_sync_tb --stop-time=1000ns
	ghdl -r -fsynopsys timestamp_tb --stop-time=1000ns
	ghdl -r -fsynopsys atc_unit_tb --stop-time=3500ns

run-dev: all
	ghdl -r -fsynopsys atc_bridge_tb --stop-time=1000ns
