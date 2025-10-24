all: modules-a modules-e testbenches

modules-a:
	echo "*** modules analysis ***"
	ghdl -a ../integration/common.vhd
	ghdl -a ../integration/register_map.vhd
	ghdl -a ../cdc/rst_sync.vhd
	ghdl -a ../cdc/rising_edge_sync.vhd
	ghdl -a ../cdc/toggle_only_sync.vhd
	ghdl -a ../cdc/update_request.vhd
	ghdl -a ../cdc/update_reply.vhd
	ghdl -a ../cdc/poke_sync.vhd
	ghdl -a ../cdc/payload_sync.vhd
	ghdl -a atc_pkg.vhd
	ghdl -a counter.vhd
	ghdl -a nchan_inverter.vhd
	ghdl -a atc_registers.vhd
	ghdl -a config_sync.vhd
	ghdl -a timestamp_simple.vhd
	ghdl -a timestamp_sync.vhd
	ghdl -a atc_bridge.vhd
	ghdl -a atc_mux.vhd
	ghdl -a atc_counter.vhd
	ghdl -a atc_unit.vhd

modules-e:
	echo "*** module elaboration ***"
	ghdl -e rst_sync
	ghdl -e rising_edge_sync
	ghdl -e toggle_only_sync
	ghdl -e update_request
	ghdl -e update_reply
	ghdl -e poke_sync
	ghdl -e payload_sync
	ghdl -e counter
	ghdl -e nchan_inverter
	ghdl -e atc_registers
	ghdl -e config_sync
	ghdl -e timestamp_simple
	ghdl -e timestamp_sync
	ghdl -e atc_bridge
	ghdl -e atc_mux
	ghdl -e atc_counter
	ghdl -e atc_unit

testbenches:
	echo "*** testbench analysis and elaboration ***"
	ghdl -a -fsynopsys tb/counter_tb.vhd
	ghdl -e -fsynopsys counter_tb
	ghdl -a -fsynopsys tb/nchan_inverter_tb.vhd
	ghdl -e -fsynopsys nchan_inverter_tb
	ghdl -a -fsynopsys tb/atc_registers_tb.vhd
	ghdl -e -fsynopsys atc_registers_tb
	ghdl -a -fsynopsys tb/atc_registers_tb.vhd
	ghdl -e -fsynopsys atc_registers_tb
	ghdl -a -fsynopsys tb/config_sync_tb.vhd
	ghdl -e -fsynopsys config_sync_tb
	ghdl -a -fsynopsys tb/timestamp_tb.vhd
	ghdl -e -fsynopsys timestamp_tb
	ghdl -a -fsynopsys tb/atc_bridge_tb.vhd
	ghdl -e -fsynopsys atc_bridge_tb
	ghdl -a -fsynopsys tb/atc_mux_tb.vhd
	ghdl -e -fsynopsys atc_mux_tb
	ghdl -a -fsynopsys tb/atc_counter_tb.vhd
	ghdl -e -fsynopsys atc_counter_tb
	ghdl -a -fsynopsys tb/atc_unit_tb.vhd
	ghdl -e -fsynopsys atc_unit_tb


run-testbenches: all
	ghdl -r -fsynopsys counter_tb --stop-time=1000ns
	ghdl -r -fsynopsys nchan_inverter_tb --stop-time=3500ns
	ghdl -r -fsynopsys atc_registers_tb --stop-time=500ns
	ghdl -r -fsynopsys atc_mux_tb --stop-time=1000ns
	ghdl -r -fsynopsys config_sync_tb --stop-time=1000ns
	ghdl -r -fsynopsys timestamp_tb --stop-time=1000ns
	ghdl -r -fsynopsys atc_bridge_tb --stop-time=1000ns
	ghdl -r -fsynopsys atc_counter_tb --stop-time=5us

run-unit-testbench: all
	ghdl -r -fsynopsys atc_unit_tb --stop-time=3500ns

run-dev: all
	ghdl -r -fsynopsys atc_unit_tb --stop-time=3500ns




