all: modules-a modules-e testbenches

modules-a:
	echo "*** modules analysis ***"
	ghdl -a ../integration/common.vhd
	ghdl -a ../integration/register_map.vhd
	ghdl -a atc_registers.vhd
	ghdl -a timestamp_slow.vhd
	ghdl -a timestamp_fast_sync.vhd
	ghdl -a update_request.vhd
	ghdl -a update_reply.vhd
	ghdl -a slow_poke.vhd
	ghdl -a slow_config.vhd
	ghdl -a async_input.vhd
	ghdl -a atc_unit.vhd
#	ghdl -a external_update.vhd
#	ghdl -a atc_mux.vhd
#	ghdl -a atc_mux_single.vhd


modules-e:
	echo "*** module elaboration ***"
	ghdl -e atc_registers
	ghdl -e timestamp_slow
	ghdl -e timestamp_fast_sync
	ghdl -e update_request
	ghdl -e update_reply
	ghdl -e slow_poke
	ghdl -e slow_config
	ghdl -a async_input.vhd
	ghdl -e atc_unit
#	ghdl -e atc_mux
#	ghdl -e slow_pulse
#	ghdl -e timestamp
#	ghdl -e external_update

testbenches:
	echo "*** testbench analysis and elaboration ***"
	ghdl -a -fsynopsys tb/atc_registers_tb.vhd
	ghdl -e -fsynopsys atc_registers_tb
	ghdl -a -fsynopsys tb/atc_unit_tb.vhd
	ghdl -e -fsynopsys atc_unit_tb
	ghdl -a -fsynopsys tb/timestamp_tb.vhd
	ghdl -e -fsynopsys timestamp_tb
	ghdl -a -fsynopsys tb/update_tb.vhd
	ghdl -e -fsynopsys update_tb
	ghdl -a -fsynopsys tb/slow_poke_tb.vhd
	ghdl -e -fsynopsys slow_poke_tb
	ghdl -a -fsynopsys tb/slow_config_tb.vhd
	ghdl -e -fsynopsys slow_config_tb
#	ghdl -a -fsynopsys tb/atc_mux_tb.vhd
#	ghdl -e -fsynopsys atc_mux_tb
#	ghdl -a -fsynopsys tb/slow_pulse_tb.vhd
#	ghdl -e -fsynopsys slow_pulse_tb
#	ghdl -e -fsynopsys timestamp_tb
#	ghdl -a -fsynopsys tb/external_update_tb.vhd
#	ghdl -e -fsynopsys external_update_tb

run-testbenches: all
	ghdl -r -fsynopsys atc_registers_tb --stop-time=500ns
	ghdl -r -fsynopsys timestamp_tb --stop-time=500ns
	ghdl -r -fsynopsys update_tb --stop-time=1000ns
	ghdl -r -fsynopsys slow_poke_tb --stop-time=1000ns
	ghdl -r -fsynopsys slow_config_tb --stop-time=1000ns
#	ghdl -r -fsynopsys timestamp_tb --stop-time=3500ns
#	ghdl -r -fsynopsys atc_unit_tb --stop-time=3500ns
#	ghdl -r -fsynopsys external_update_tb --stop-time=3500ns
	ghdl -r -fsynopsys atc_unit_tb --stop-time=3500ns

run-dev: all
	ghdl -r -fsynopsys slow_config_tb --stop-time=1000ns
