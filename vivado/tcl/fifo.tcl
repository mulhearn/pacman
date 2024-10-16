
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
# CREATE IP fifo_64x512
##################################################################

set fifo_64x512 [create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name fifo_64x512]

set_property -dict { 
  CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM}
  CONFIG.Input_Data_Width {64}
  CONFIG.Input_Depth {16}
  CONFIG.Output_Data_Width {64}
  CONFIG.Output_Depth {16}
  CONFIG.Use_Embedded_Registers {false}
  CONFIG.Reset_Type {Asynchronous_Reset}
  CONFIG.Full_Flags_Reset_Value {1}
  CONFIG.Almost_Full_Flag {true}
  CONFIG.Valid_Flag {true}
  CONFIG.Write_Acknowledge_Flag {true}
  CONFIG.Data_Count_Width {4}
  CONFIG.Write_Data_Count {true}
  CONFIG.Write_Data_Count_Width {4}
  CONFIG.Read_Data_Count_Width {4}
  CONFIG.Full_Threshold_Assert_Value {14}
  CONFIG.Full_Threshold_Negate_Value {13}
  CONFIG.Enable_Safety_Circuit {false}
} [get_ips fifo_64x512]

set_property -dict { 
  GENERATE_SYNTH_CHECKPOINT {0}
} $fifo_64x512

##################################################################
