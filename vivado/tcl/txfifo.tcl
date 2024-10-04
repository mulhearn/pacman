##################################################################
# CHECK IPs
##################################################################

set bCheckIPs 1
set bCheckIPsPassed 1
if { $bCheckIPs == 1 } {
  set list_check_ips { xilinx.com:ip:fifo_generator:* }
  set list_ips_missing ""
  common::send_msg_id "IPS_TCL-1001" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

  foreach ip_vlnv $list_check_ips {
  set ip_obj [get_ipdefs -all $ip_vlnv]
  if { $ip_obj eq "" } {
    lappend list_ips_missing $ip_vlnv
    }
  }

  if { $list_ips_missing ne "" } {
    catch {common::send_msg_id "IPS_TCL-105" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
    set bCheckIPsPassed 0
  }
}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "IPS_TCL-102" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 1
}

##################################################################
# CREATE IP txfifo
##################################################################

set txfifo [create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name txfifo]

set_property -dict { 
  CONFIG.Input_Data_Width {32}
  CONFIG.Input_Depth {64}
  CONFIG.Output_Data_Width {64}
  CONFIG.Output_Depth {32}
  CONFIG.Almost_Full_Flag {true}
  CONFIG.Use_Extra_Logic {true}
  CONFIG.Data_Count_Width {6}
  CONFIG.Write_Data_Count_Width {7}
  CONFIG.Read_Data_Count_Width {6}
  CONFIG.Full_Threshold_Assert_Value {61}
  CONFIG.Full_Threshold_Negate_Value {60}
} [get_ips txfifo]

set_property -dict { 
  GENERATE_SYNTH_CHECKPOINT {1}
} $txfifo

##################################################################

