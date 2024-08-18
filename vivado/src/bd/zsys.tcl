
################################################################
# This is a generated script based on design: zsys
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2020.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source zsys_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# axi_lite_reg_space, larpix_clk_to_axi_stream, larpix_counter, larpix_mclk_sel, larpix_reset_gen, larpix_periodic_trig_gen, larpix_trig_gen, larpix_trig_to_axi_stream, axi_lite_reg_space, axi_lite_reg_space, uart_channel, uart_channel, obuft_out, uart_channel, obuft_out, uart_channel, obuft_out, uart_channel, obuft_out, uart_channel, obuft_out, uart_channel, obuft_out, uart_channel, obuft_out, uart_channel, obuft_out, uart_channel, obuft_out, uart_channel, obuft_out, obuft_out, uart_channel, uart_channel, obuft_out, uart_channel, obuft_out, uart_channel, obuft_out, uart_channel, obuft_out, uart_channel, obuft_out, obuft_out, obuft_out, obuft_out, obuft_out, obuft_out, obuft_out, uart_channel, obuft_out, obuft_out, obuft_out, obuft_out, uart_channel, obuft_out, uart_channel, obuft_out, uart_channel, obuft_out, uart_channel, obuft_out, uart_channel, obuft_out, uart_channel, uart_channel, uart_channel, uart_channel, uart_channel, uart_channel, uart_channel, uart_channel, uart_channel, obuft_out, clk_ddr_out, clk_ddr_out, obuft_out, obuftds_out, obuft_out, obuftds_out, obuft_out, obuftds_out, clk_ddr_out, clk_ddr_out, obuft_out, obuftds_out, obuft_out, obuftds_out, obuft_out, obuftds_out, clk_ddr_out, clk_ddr_out, obuft_out, obuftds_out, obuft_out, obuftds_out, obuft_out, obuftds_out, clk_ddr_out, clk_ddr_out, obuft_out, obuftds_out, obuft_out, obuftds_out, obuft_out, obuftds_out, clk_ddr_out, clk_ddr_out, obuft_out, obuftds_out, obuft_out, obuftds_out, obuft_out, obuftds_out, clk_ddr_out, clk_ddr_out, obuft_out, obuftds_out, obuft_out, obuftds_out, obuft_out, obuftds_out, clk_ddr_out, clk_ddr_out, obuft_out, obuftds_out, obuft_out, obuftds_out, obuft_out, obuftds_out, clk_ddr_out, clk_ddr_out, obuft_out, obuftds_out, obuft_out, obuftds_out, obuft_out, obuftds_out

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z020clg484-1
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name zsys

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:processing_system7:5.5\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:xlslice:1.0\
xilinx.com:ip:axis_broadcaster:1.1\
xilinx.com:ip:axis_register_slice:1.1\
xilinx.com:ip:axis_subset_converter:1.1\
xilinx.com:ip:axi_dma:7.1\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:util_vector_logic:2.0\
xilinx.com:ip:util_reduced_logic:2.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
axi_lite_reg_space\
larpix_clk_to_axi_stream\
larpix_counter\
larpix_mclk_sel\
larpix_reset_gen\
larpix_periodic_trig_gen\
larpix_trig_gen\
larpix_trig_to_axi_stream\
axi_lite_reg_space\
axi_lite_reg_space\
uart_channel\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
obuft_out\
uart_channel\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
obuft_out\
obuft_out\
obuft_out\
obuft_out\
obuft_out\
obuft_out\
uart_channel\
obuft_out\
obuft_out\
obuft_out\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
obuft_out\
uart_channel\
uart_channel\
uart_channel\
uart_channel\
uart_channel\
uart_channel\
uart_channel\
uart_channel\
uart_channel\
obuft_out\
clk_ddr_out\
clk_ddr_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
clk_ddr_out\
clk_ddr_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
clk_ddr_out\
clk_ddr_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
clk_ddr_out\
clk_ddr_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
clk_ddr_out\
clk_ddr_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
clk_ddr_out\
clk_ddr_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
clk_ddr_out\
clk_ddr_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
clk_ddr_out\
clk_ddr_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
obuft_out\
obuftds_out\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: TRIG_OUT
proc create_hier_cell_TRIG_OUT_7 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_TRIG_OUT_7() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_TRIG] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_TRIG] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_TRIG_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_TRIG_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: RESETN_OUT
proc create_hier_cell_RESETN_OUT_7 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_RESETN_OUT_7() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_RESETN] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_RESETN] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_RESETN_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_RESETN_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: CLK_OUT
proc create_hier_cell_CLK_OUT_7 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_CLK_OUT_7() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir I TILE_EN

  # Create instance: clk_ddr_out_0, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_0
  if { [catch {set clk_ddr_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: clk_ddr_out_1, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_1
  if { [catch {set clk_ddr_out_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuft_out_0, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_0
  if { [catch {set obuft_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_0, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_0
  if { [catch {set obuftds_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins clk_ddr_out_0/i] [get_bd_pins clk_ddr_out_1/i]
  connect_bd_net -net O_MOSI_EN_P_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_0/en] [get_bd_pins obuftds_out_0/en]
  connect_bd_net -net clk_ddr_out_0_o [get_bd_pins clk_ddr_out_0/o] [get_bd_pins obuft_out_0/i]
  connect_bd_net -net clk_ddr_out_1_o [get_bd_pins clk_ddr_out_1/o] [get_bd_pins obuftds_out_0/i]
  connect_bd_net -net obuft_out_0_o [get_bd_pins O_CLK] [get_bd_pins obuft_out_0/o]
  connect_bd_net -net obuftds_out_0_o_n [get_bd_pins O_CLK_N] [get_bd_pins obuftds_out_0/o_n]
  connect_bd_net -net obuftds_out_0_o_p [get_bd_pins O_CLK_P] [get_bd_pins obuftds_out_0/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: TRIG_OUT
proc create_hier_cell_TRIG_OUT_6 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_TRIG_OUT_6() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_TRIG] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_TRIG] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_TRIG_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_TRIG_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: RESETN_OUT
proc create_hier_cell_RESETN_OUT_6 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_RESETN_OUT_6() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_RESETN] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_RESETN] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_RESETN_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_RESETN_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: CLK_OUT
proc create_hier_cell_CLK_OUT_6 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_CLK_OUT_6() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir I TILE_EN

  # Create instance: clk_ddr_out_0, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_0
  if { [catch {set clk_ddr_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: clk_ddr_out_1, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_1
  if { [catch {set clk_ddr_out_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuft_out_0, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_0
  if { [catch {set obuft_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_0, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_0
  if { [catch {set obuftds_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins clk_ddr_out_0/i] [get_bd_pins clk_ddr_out_1/i]
  connect_bd_net -net O_MOSI_EN_P_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_0/en] [get_bd_pins obuftds_out_0/en]
  connect_bd_net -net clk_ddr_out_0_o [get_bd_pins clk_ddr_out_0/o] [get_bd_pins obuft_out_0/i]
  connect_bd_net -net clk_ddr_out_1_o [get_bd_pins clk_ddr_out_1/o] [get_bd_pins obuftds_out_0/i]
  connect_bd_net -net obuft_out_0_o [get_bd_pins O_CLK] [get_bd_pins obuft_out_0/o]
  connect_bd_net -net obuftds_out_0_o_n [get_bd_pins O_CLK_N] [get_bd_pins obuftds_out_0/o_n]
  connect_bd_net -net obuftds_out_0_o_p [get_bd_pins O_CLK_P] [get_bd_pins obuftds_out_0/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: TRIG_OUT
proc create_hier_cell_TRIG_OUT_5 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_TRIG_OUT_5() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_TRIG] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_TRIG] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_TRIG_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_TRIG_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: RESETN_OUT
proc create_hier_cell_RESETN_OUT_5 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_RESETN_OUT_5() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_RESETN] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_RESETN] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_RESETN_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_RESETN_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: CLK_OUT
proc create_hier_cell_CLK_OUT_5 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_CLK_OUT_5() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir I TILE_EN

  # Create instance: clk_ddr_out_0, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_0
  if { [catch {set clk_ddr_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: clk_ddr_out_1, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_1
  if { [catch {set clk_ddr_out_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuft_out_0, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_0
  if { [catch {set obuft_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_0, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_0
  if { [catch {set obuftds_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins clk_ddr_out_0/i] [get_bd_pins clk_ddr_out_1/i]
  connect_bd_net -net O_MOSI_EN_P_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_0/en] [get_bd_pins obuftds_out_0/en]
  connect_bd_net -net clk_ddr_out_0_o [get_bd_pins clk_ddr_out_0/o] [get_bd_pins obuft_out_0/i]
  connect_bd_net -net clk_ddr_out_1_o [get_bd_pins clk_ddr_out_1/o] [get_bd_pins obuftds_out_0/i]
  connect_bd_net -net obuft_out_0_o [get_bd_pins O_CLK] [get_bd_pins obuft_out_0/o]
  connect_bd_net -net obuftds_out_0_o_n [get_bd_pins O_CLK_N] [get_bd_pins obuftds_out_0/o_n]
  connect_bd_net -net obuftds_out_0_o_p [get_bd_pins O_CLK_P] [get_bd_pins obuftds_out_0/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: TRIG_OUT
proc create_hier_cell_TRIG_OUT_4 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_TRIG_OUT_4() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_TRIG] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_TRIG] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_TRIG_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_TRIG_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: RESETN_OUT
proc create_hier_cell_RESETN_OUT_4 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_RESETN_OUT_4() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_RESETN] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_RESETN] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_RESETN_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_RESETN_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: CLK_OUT
proc create_hier_cell_CLK_OUT_4 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_CLK_OUT_4() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir I TILE_EN

  # Create instance: clk_ddr_out_0, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_0
  if { [catch {set clk_ddr_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: clk_ddr_out_1, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_1
  if { [catch {set clk_ddr_out_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuft_out_0, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_0
  if { [catch {set obuft_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_0, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_0
  if { [catch {set obuftds_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins clk_ddr_out_0/i] [get_bd_pins clk_ddr_out_1/i]
  connect_bd_net -net O_MOSI_EN_P_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_0/en] [get_bd_pins obuftds_out_0/en]
  connect_bd_net -net clk_ddr_out_0_o [get_bd_pins clk_ddr_out_0/o] [get_bd_pins obuft_out_0/i]
  connect_bd_net -net clk_ddr_out_1_o [get_bd_pins clk_ddr_out_1/o] [get_bd_pins obuftds_out_0/i]
  connect_bd_net -net obuft_out_0_o [get_bd_pins O_CLK] [get_bd_pins obuft_out_0/o]
  connect_bd_net -net obuftds_out_0_o_n [get_bd_pins O_CLK_N] [get_bd_pins obuftds_out_0/o_n]
  connect_bd_net -net obuftds_out_0_o_p [get_bd_pins O_CLK_P] [get_bd_pins obuftds_out_0/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: TRIG_OUT
proc create_hier_cell_TRIG_OUT_3 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_TRIG_OUT_3() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_TRIG] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_TRIG] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_TRIG_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_TRIG_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: RESETN_OUT
proc create_hier_cell_RESETN_OUT_3 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_RESETN_OUT_3() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_RESETN] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_RESETN] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_RESETN_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_RESETN_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: CLK_OUT
proc create_hier_cell_CLK_OUT_3 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_CLK_OUT_3() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir I TILE_EN

  # Create instance: clk_ddr_out_0, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_0
  if { [catch {set clk_ddr_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: clk_ddr_out_1, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_1
  if { [catch {set clk_ddr_out_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuft_out_0, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_0
  if { [catch {set obuft_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_0, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_0
  if { [catch {set obuftds_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins clk_ddr_out_0/i] [get_bd_pins clk_ddr_out_1/i]
  connect_bd_net -net O_MOSI_EN_P_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_0/en] [get_bd_pins obuftds_out_0/en]
  connect_bd_net -net clk_ddr_out_0_o [get_bd_pins clk_ddr_out_0/o] [get_bd_pins obuft_out_0/i]
  connect_bd_net -net clk_ddr_out_1_o [get_bd_pins clk_ddr_out_1/o] [get_bd_pins obuftds_out_0/i]
  connect_bd_net -net obuft_out_0_o [get_bd_pins O_CLK] [get_bd_pins obuft_out_0/o]
  connect_bd_net -net obuftds_out_0_o_n [get_bd_pins O_CLK_N] [get_bd_pins obuftds_out_0/o_n]
  connect_bd_net -net obuftds_out_0_o_p [get_bd_pins O_CLK_P] [get_bd_pins obuftds_out_0/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: TRIG_OUT
proc create_hier_cell_TRIG_OUT_2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_TRIG_OUT_2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_TRIG] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_TRIG] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_TRIG_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_TRIG_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: RESETN_OUT
proc create_hier_cell_RESETN_OUT_2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_RESETN_OUT_2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_RESETN] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_RESETN] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_RESETN_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_RESETN_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: CLK_OUT
proc create_hier_cell_CLK_OUT_2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_CLK_OUT_2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir I TILE_EN

  # Create instance: clk_ddr_out_0, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_0
  if { [catch {set clk_ddr_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: clk_ddr_out_1, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_1
  if { [catch {set clk_ddr_out_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuft_out_0, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_0
  if { [catch {set obuft_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_0, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_0
  if { [catch {set obuftds_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins clk_ddr_out_0/i] [get_bd_pins clk_ddr_out_1/i]
  connect_bd_net -net O_MOSI_EN_P_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_0/en] [get_bd_pins obuftds_out_0/en]
  connect_bd_net -net clk_ddr_out_0_o [get_bd_pins clk_ddr_out_0/o] [get_bd_pins obuft_out_0/i]
  connect_bd_net -net clk_ddr_out_1_o [get_bd_pins clk_ddr_out_1/o] [get_bd_pins obuftds_out_0/i]
  connect_bd_net -net obuft_out_0_o [get_bd_pins O_CLK] [get_bd_pins obuft_out_0/o]
  connect_bd_net -net obuftds_out_0_o_n [get_bd_pins O_CLK_N] [get_bd_pins obuftds_out_0/o_n]
  connect_bd_net -net obuftds_out_0_o_p [get_bd_pins O_CLK_P] [get_bd_pins obuftds_out_0/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: TRIG_OUT
proc create_hier_cell_TRIG_OUT_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_TRIG_OUT_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_TRIG] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_TRIG] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_TRIG_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_TRIG_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: RESETN_OUT
proc create_hier_cell_RESETN_OUT_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_RESETN_OUT_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_RESETN] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_RESETN] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_RESETN_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_RESETN_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: CLK_OUT
proc create_hier_cell_CLK_OUT_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_CLK_OUT_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir I TILE_EN

  # Create instance: clk_ddr_out_0, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_0
  if { [catch {set clk_ddr_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: clk_ddr_out_1, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_1
  if { [catch {set clk_ddr_out_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuft_out_0, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_0
  if { [catch {set obuft_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_0, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_0
  if { [catch {set obuftds_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins clk_ddr_out_0/i] [get_bd_pins clk_ddr_out_1/i]
  connect_bd_net -net O_MOSI_EN_P_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_0/en] [get_bd_pins obuftds_out_0/en]
  connect_bd_net -net clk_ddr_out_0_o [get_bd_pins clk_ddr_out_0/o] [get_bd_pins obuft_out_0/i]
  connect_bd_net -net clk_ddr_out_1_o [get_bd_pins clk_ddr_out_1/o] [get_bd_pins obuftds_out_0/i]
  connect_bd_net -net obuft_out_0_o [get_bd_pins O_CLK] [get_bd_pins obuft_out_0/o]
  connect_bd_net -net obuftds_out_0_o_n [get_bd_pins O_CLK_N] [get_bd_pins obuftds_out_0/o_n]
  connect_bd_net -net obuftds_out_0_o_p [get_bd_pins O_CLK_P] [get_bd_pins obuftds_out_0/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: TRIG_OUT
proc create_hier_cell_TRIG_OUT { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_TRIG_OUT() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_TRIG] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_TRIG] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_TRIG_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_TRIG_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: RESETN_OUT
proc create_hier_cell_RESETN_OUT { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_RESETN_OUT() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir I TILE_EN

  # Create instance: obuft_out_6, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_6
  if { [catch {set obuft_out_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_2, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_2
  if { [catch {set obuftds_out_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net O_TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_6/en] [get_bd_pins obuftds_out_2/en]
  connect_bd_net -net TRIG_0_SLICE_Dout [get_bd_pins I_RESETN] [get_bd_pins obuft_out_6/i] [get_bd_pins obuftds_out_2/i]
  connect_bd_net -net obuft_out_6_o [get_bd_pins O_RESETN] [get_bd_pins obuft_out_6/o]
  connect_bd_net -net obuftds_out_2_o_n [get_bd_pins O_RESETN_N] [get_bd_pins obuftds_out_2/o_n]
  connect_bd_net -net obuftds_out_2_o_p [get_bd_pins O_RESETN_P] [get_bd_pins obuftds_out_2/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: CLK_OUT
proc create_hier_cell_CLK_OUT { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_CLK_OUT() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir I TILE_EN

  # Create instance: clk_ddr_out_0, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_0
  if { [catch {set clk_ddr_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: clk_ddr_out_1, and set properties
  set block_name clk_ddr_out
  set block_cell_name clk_ddr_out_1
  if { [catch {set clk_ddr_out_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clk_ddr_out_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuft_out_0, and set properties
  set block_name obuft_out
  set block_cell_name obuft_out_0
  if { [catch {set obuft_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuft_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: obuftds_out_0, and set properties
  set block_name obuftds_out
  set block_cell_name obuftds_out_0
  if { [catch {set obuftds_out_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $obuftds_out_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins clk_ddr_out_0/i] [get_bd_pins clk_ddr_out_1/i]
  connect_bd_net -net O_MOSI_EN_P_1 [get_bd_pins TILE_EN] [get_bd_pins obuft_out_0/en] [get_bd_pins obuftds_out_0/en]
  connect_bd_net -net clk_ddr_out_0_o [get_bd_pins clk_ddr_out_0/o] [get_bd_pins obuft_out_0/i]
  connect_bd_net -net clk_ddr_out_1_o [get_bd_pins clk_ddr_out_1/o] [get_bd_pins obuftds_out_0/i]
  connect_bd_net -net obuft_out_0_o [get_bd_pins O_CLK] [get_bd_pins obuft_out_0/o]
  connect_bd_net -net obuftds_out_0_o_n [get_bd_pins O_CLK_N] [get_bd_pins obuftds_out_0/o_n]
  connect_bd_net -net obuftds_out_0_o_p [get_bd_pins O_CLK_P] [get_bd_pins obuftds_out_0/o_p]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: uart_channels
proc create_hier_cell_uart_channels { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_uart_channels() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS2

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS3

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS4

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS5

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS6

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS7

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS8

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS9

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS10

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS11

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS12

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS13

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS14

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS15

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS16

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS17

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS18

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS19

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS20

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS21

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS22

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS23

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS24

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS25

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS26

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS27

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS28

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS29

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS30

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS31

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS4

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS5

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS6

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS7

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS8

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS9

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS10

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS11

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS12

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS13

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS14

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS15

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS16

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS17

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS18

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS19

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS20

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS21

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS22

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS23

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS24

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS25

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS26

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS27

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS28

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS29

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS30

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS31

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE4

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE5

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE6

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE7

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE8

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE9

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE10

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE11

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE12

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE13

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE14

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE15

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE16

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE17

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE18

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE19

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE20

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE21

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE22

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE23

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE24

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE25

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE26

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE27

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE28

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE29

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE30

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE31


  # Create pins
  create_bd_pin -dir I -type clk ACLK
  create_bd_pin -dir I -type rst ARESETN
  create_bd_pin -dir I MCLK
  create_bd_pin -dir I -from 31 -to 0 MISO
  create_bd_pin -dir O -from 31 -to 0 MOSI
  create_bd_pin -dir I -from 31 -to 0 PACMAN_TS
  create_bd_pin -dir I -from 7 -to 0 TILE_EN
  create_bd_pin -dir O UART_RX_BUSY
  create_bd_pin -dir O UART_TX_BUSY

  # Create instance: larpix_uart_channel_1, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_1
  if { [catch {set larpix_uart_channel_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x01} \
 ] $larpix_uart_channel_1

  # Create instance: larpix_uart_channel_10, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_10
  if { [catch {set larpix_uart_channel_10 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_10 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x0A} \
 ] $larpix_uart_channel_10

  # Create instance: larpix_uart_channel_10_en_slice, and set properties
  set larpix_uart_channel_10_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_10_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_10_en_slice

  # Create instance: larpix_uart_channel_10_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_10_obuft_out
  if { [catch {set larpix_uart_channel_10_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_10_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_10_slice, and set properties
  set larpix_uart_channel_10_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_10_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {9} \
   CONFIG.DIN_TO {9} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_10_slice

  # Create instance: larpix_uart_channel_11, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_11
  if { [catch {set larpix_uart_channel_11 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_11 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x0B} \
 ] $larpix_uart_channel_11

  # Create instance: larpix_uart_channel_11_en_slice, and set properties
  set larpix_uart_channel_11_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_11_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_11_en_slice

  # Create instance: larpix_uart_channel_11_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_11_obuft_out
  if { [catch {set larpix_uart_channel_11_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_11_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_11_slice, and set properties
  set larpix_uart_channel_11_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_11_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {10} \
   CONFIG.DIN_TO {10} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_11_slice

  # Create instance: larpix_uart_channel_12, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_12
  if { [catch {set larpix_uart_channel_12 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_12 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x0C} \
 ] $larpix_uart_channel_12

  # Create instance: larpix_uart_channel_12_en_slice, and set properties
  set larpix_uart_channel_12_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_12_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_12_en_slice

  # Create instance: larpix_uart_channel_12_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_12_obuft_out
  if { [catch {set larpix_uart_channel_12_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_12_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_12_slice, and set properties
  set larpix_uart_channel_12_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_12_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {11} \
   CONFIG.DIN_TO {11} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_12_slice

  # Create instance: larpix_uart_channel_13, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_13
  if { [catch {set larpix_uart_channel_13 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_13 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x0D} \
 ] $larpix_uart_channel_13

  # Create instance: larpix_uart_channel_13_en_slice, and set properties
  set larpix_uart_channel_13_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_13_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {3} \
   CONFIG.DIN_TO {3} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_13_en_slice

  # Create instance: larpix_uart_channel_13_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_13_obuft_out
  if { [catch {set larpix_uart_channel_13_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_13_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_13_slice, and set properties
  set larpix_uart_channel_13_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_13_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {12} \
   CONFIG.DIN_TO {12} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_13_slice

  # Create instance: larpix_uart_channel_14, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_14
  if { [catch {set larpix_uart_channel_14 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_14 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x0E} \
 ] $larpix_uart_channel_14

  # Create instance: larpix_uart_channel_14_en_slice, and set properties
  set larpix_uart_channel_14_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_14_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {3} \
   CONFIG.DIN_TO {3} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_14_en_slice

  # Create instance: larpix_uart_channel_14_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_14_obuft_out
  if { [catch {set larpix_uart_channel_14_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_14_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_14_slice, and set properties
  set larpix_uart_channel_14_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_14_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {13} \
   CONFIG.DIN_TO {13} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_14_slice

  # Create instance: larpix_uart_channel_15, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_15
  if { [catch {set larpix_uart_channel_15 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_15 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x0F} \
 ] $larpix_uart_channel_15

  # Create instance: larpix_uart_channel_15_en_slice, and set properties
  set larpix_uart_channel_15_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_15_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {3} \
   CONFIG.DIN_TO {3} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_15_en_slice

  # Create instance: larpix_uart_channel_15_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_15_obuft_out
  if { [catch {set larpix_uart_channel_15_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_15_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_15_slice, and set properties
  set larpix_uart_channel_15_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_15_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {14} \
   CONFIG.DIN_TO {14} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_15_slice

  # Create instance: larpix_uart_channel_16, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_16
  if { [catch {set larpix_uart_channel_16 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_16 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x10} \
 ] $larpix_uart_channel_16

  # Create instance: larpix_uart_channel_16_en_slice, and set properties
  set larpix_uart_channel_16_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_16_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {3} \
   CONFIG.DIN_TO {3} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_16_en_slice

  # Create instance: larpix_uart_channel_16_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_16_obuft_out
  if { [catch {set larpix_uart_channel_16_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_16_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_16_slice, and set properties
  set larpix_uart_channel_16_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_16_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {15} \
   CONFIG.DIN_TO {15} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_16_slice

  # Create instance: larpix_uart_channel_17, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_17
  if { [catch {set larpix_uart_channel_17 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_17 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x11} \
 ] $larpix_uart_channel_17

  # Create instance: larpix_uart_channel_17_en_slice, and set properties
  set larpix_uart_channel_17_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_17_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {4} \
   CONFIG.DIN_TO {4} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_17_en_slice

  # Create instance: larpix_uart_channel_17_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_17_obuft_out
  if { [catch {set larpix_uart_channel_17_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_17_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_17_slice, and set properties
  set larpix_uart_channel_17_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_17_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {16} \
   CONFIG.DIN_TO {16} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_17_slice

  # Create instance: larpix_uart_channel_18, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_18
  if { [catch {set larpix_uart_channel_18 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_18 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x12} \
 ] $larpix_uart_channel_18

  # Create instance: larpix_uart_channel_18_en_slice, and set properties
  set larpix_uart_channel_18_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_18_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {4} \
   CONFIG.DIN_TO {4} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_18_en_slice

  # Create instance: larpix_uart_channel_18_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_18_obuft_out
  if { [catch {set larpix_uart_channel_18_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_18_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_18_slice, and set properties
  set larpix_uart_channel_18_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_18_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {17} \
   CONFIG.DIN_TO {17} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_18_slice

  # Create instance: larpix_uart_channel_19, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_19
  if { [catch {set larpix_uart_channel_19 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_19 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x13} \
 ] $larpix_uart_channel_19

  # Create instance: larpix_uart_channel_19_en_slice, and set properties
  set larpix_uart_channel_19_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_19_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {4} \
   CONFIG.DIN_TO {4} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_19_en_slice

  # Create instance: larpix_uart_channel_19_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_19_obuft_out
  if { [catch {set larpix_uart_channel_19_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_19_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_19_slice, and set properties
  set larpix_uart_channel_19_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_19_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {18} \
   CONFIG.DIN_TO {18} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_19_slice

  # Create instance: larpix_uart_channel_1_en_slice, and set properties
  set larpix_uart_channel_1_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_1_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_1_en_slice

  # Create instance: larpix_uart_channel_1_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_1_obuft_out
  if { [catch {set larpix_uart_channel_1_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_1_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_1_slice, and set properties
  set larpix_uart_channel_1_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_1_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_1_slice

  # Create instance: larpix_uart_channel_2, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_2
  if { [catch {set larpix_uart_channel_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x02} \
 ] $larpix_uart_channel_2

  # Create instance: larpix_uart_channel_20, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_20
  if { [catch {set larpix_uart_channel_20 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_20 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x14} \
 ] $larpix_uart_channel_20

  # Create instance: larpix_uart_channel_20_en_slice, and set properties
  set larpix_uart_channel_20_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_20_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {4} \
   CONFIG.DIN_TO {4} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_20_en_slice

  # Create instance: larpix_uart_channel_20_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_20_obuft_out
  if { [catch {set larpix_uart_channel_20_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_20_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_20_slice, and set properties
  set larpix_uart_channel_20_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_20_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {19} \
   CONFIG.DIN_TO {19} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_20_slice

  # Create instance: larpix_uart_channel_21, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_21
  if { [catch {set larpix_uart_channel_21 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_21 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x15} \
 ] $larpix_uart_channel_21

  # Create instance: larpix_uart_channel_21_en_slice, and set properties
  set larpix_uart_channel_21_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_21_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {5} \
   CONFIG.DIN_TO {5} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_21_en_slice

  # Create instance: larpix_uart_channel_21_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_21_obuft_out
  if { [catch {set larpix_uart_channel_21_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_21_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_21_slice, and set properties
  set larpix_uart_channel_21_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_21_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {20} \
   CONFIG.DIN_TO {20} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_21_slice

  # Create instance: larpix_uart_channel_22, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_22
  if { [catch {set larpix_uart_channel_22 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_22 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x16} \
 ] $larpix_uart_channel_22

  # Create instance: larpix_uart_channel_22_en_slice, and set properties
  set larpix_uart_channel_22_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_22_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {5} \
   CONFIG.DIN_TO {5} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_22_en_slice

  # Create instance: larpix_uart_channel_22_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_22_obuft_out
  if { [catch {set larpix_uart_channel_22_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_22_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_22_slice, and set properties
  set larpix_uart_channel_22_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_22_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {21} \
   CONFIG.DIN_TO {21} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_22_slice

  # Create instance: larpix_uart_channel_23, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_23
  if { [catch {set larpix_uart_channel_23 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_23 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x17} \
 ] $larpix_uart_channel_23

  # Create instance: larpix_uart_channel_23_en_slice, and set properties
  set larpix_uart_channel_23_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_23_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {5} \
   CONFIG.DIN_TO {5} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_23_en_slice

  # Create instance: larpix_uart_channel_23_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_23_obuft_out
  if { [catch {set larpix_uart_channel_23_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_23_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_23_slice, and set properties
  set larpix_uart_channel_23_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_23_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {22} \
   CONFIG.DIN_TO {22} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_23_slice

  # Create instance: larpix_uart_channel_24, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_24
  if { [catch {set larpix_uart_channel_24 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_24 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x18} \
 ] $larpix_uart_channel_24

  # Create instance: larpix_uart_channel_24_en_slice, and set properties
  set larpix_uart_channel_24_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_24_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {5} \
   CONFIG.DIN_TO {5} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_24_en_slice

  # Create instance: larpix_uart_channel_24_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_24_obuft_out
  if { [catch {set larpix_uart_channel_24_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_24_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_24_slice, and set properties
  set larpix_uart_channel_24_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_24_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {23} \
   CONFIG.DIN_TO {23} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_24_slice

  # Create instance: larpix_uart_channel_25_en_slice, and set properties
  set larpix_uart_channel_25_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_25_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {6} \
   CONFIG.DIN_TO {6} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_25_en_slice

  # Create instance: larpix_uart_channel_25_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_25_obuft_out
  if { [catch {set larpix_uart_channel_25_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_25_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_25_slice, and set properties
  set larpix_uart_channel_25_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_25_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {24} \
   CONFIG.DIN_TO {24} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_25_slice

  # Create instance: larpix_uart_channel_26_en_slice, and set properties
  set larpix_uart_channel_26_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_26_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {6} \
   CONFIG.DIN_TO {6} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_26_en_slice

  # Create instance: larpix_uart_channel_26_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_26_obuft_out
  if { [catch {set larpix_uart_channel_26_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_26_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_26_slice, and set properties
  set larpix_uart_channel_26_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_26_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {25} \
   CONFIG.DIN_TO {25} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_26_slice

  # Create instance: larpix_uart_channel_27_en_slice, and set properties
  set larpix_uart_channel_27_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_27_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {6} \
   CONFIG.DIN_TO {6} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_27_en_slice

  # Create instance: larpix_uart_channel_27_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_27_obuft_out
  if { [catch {set larpix_uart_channel_27_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_27_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_27_slice, and set properties
  set larpix_uart_channel_27_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_27_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {26} \
   CONFIG.DIN_TO {26} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_27_slice

  # Create instance: larpix_uart_channel_28_en_slice, and set properties
  set larpix_uart_channel_28_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_28_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {6} \
   CONFIG.DIN_TO {6} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_28_en_slice

  # Create instance: larpix_uart_channel_28_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_28_obuft_out
  if { [catch {set larpix_uart_channel_28_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_28_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_28_slice, and set properties
  set larpix_uart_channel_28_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_28_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {27} \
   CONFIG.DIN_TO {27} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_28_slice

  # Create instance: larpix_uart_channel_29_en_slice, and set properties
  set larpix_uart_channel_29_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_29_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {7} \
   CONFIG.DIN_TO {7} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_29_en_slice

  # Create instance: larpix_uart_channel_29_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_29_obuft_out
  if { [catch {set larpix_uart_channel_29_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_29_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_29_slice, and set properties
  set larpix_uart_channel_29_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_29_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {28} \
   CONFIG.DIN_TO {28} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_29_slice

  # Create instance: larpix_uart_channel_2_en_slice, and set properties
  set larpix_uart_channel_2_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_2_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_2_en_slice

  # Create instance: larpix_uart_channel_2_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_2_obuft_out
  if { [catch {set larpix_uart_channel_2_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_2_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_2_slice, and set properties
  set larpix_uart_channel_2_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_2_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_2_slice

  # Create instance: larpix_uart_channel_3, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_3
  if { [catch {set larpix_uart_channel_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_3 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x03} \
 ] $larpix_uart_channel_3

  # Create instance: larpix_uart_channel_30_en_slice, and set properties
  set larpix_uart_channel_30_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_30_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {7} \
   CONFIG.DIN_TO {7} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_30_en_slice

  # Create instance: larpix_uart_channel_30_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_30_obuft_out
  if { [catch {set larpix_uart_channel_30_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_30_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_30_slice, and set properties
  set larpix_uart_channel_30_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_30_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {29} \
   CONFIG.DIN_TO {29} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_30_slice

  # Create instance: larpix_uart_channel_31_en_slice, and set properties
  set larpix_uart_channel_31_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_31_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {7} \
   CONFIG.DIN_TO {7} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_31_en_slice

  # Create instance: larpix_uart_channel_31_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_31_obuft_out
  if { [catch {set larpix_uart_channel_31_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_31_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_31_slice, and set properties
  set larpix_uart_channel_31_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_31_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {30} \
   CONFIG.DIN_TO {30} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_31_slice

  # Create instance: larpix_uart_channel_32_en_slice, and set properties
  set larpix_uart_channel_32_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_32_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {7} \
   CONFIG.DIN_TO {7} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_32_en_slice

  # Create instance: larpix_uart_channel_32_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_32_obuft_out
  if { [catch {set larpix_uart_channel_32_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_32_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_32_slice, and set properties
  set larpix_uart_channel_32_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_32_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {31} \
   CONFIG.DIN_TO {31} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_32_slice

  # Create instance: larpix_uart_channel_3_en_slice, and set properties
  set larpix_uart_channel_3_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_3_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_3_en_slice

  # Create instance: larpix_uart_channel_3_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_3_obuft_out
  if { [catch {set larpix_uart_channel_3_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_3_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_3_slice, and set properties
  set larpix_uart_channel_3_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_3_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_3_slice

  # Create instance: larpix_uart_channel_4, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_4
  if { [catch {set larpix_uart_channel_4 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_4 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x04} \
 ] $larpix_uart_channel_4

  # Create instance: larpix_uart_channel_4_en_slice, and set properties
  set larpix_uart_channel_4_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_4_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_4_en_slice

  # Create instance: larpix_uart_channel_4_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_4_obuft_out
  if { [catch {set larpix_uart_channel_4_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_4_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_4_slice, and set properties
  set larpix_uart_channel_4_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_4_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {3} \
   CONFIG.DIN_TO {3} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_4_slice

  # Create instance: larpix_uart_channel_5, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_5
  if { [catch {set larpix_uart_channel_5 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_5 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x05} \
 ] $larpix_uart_channel_5

  # Create instance: larpix_uart_channel_5_en_slice, and set properties
  set larpix_uart_channel_5_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_5_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_5_en_slice

  # Create instance: larpix_uart_channel_5_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_5_obuft_out
  if { [catch {set larpix_uart_channel_5_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_5_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_5_slice, and set properties
  set larpix_uart_channel_5_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_5_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {4} \
   CONFIG.DIN_TO {4} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_5_slice

  # Create instance: larpix_uart_channel_6, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_6
  if { [catch {set larpix_uart_channel_6 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_6 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x06} \
 ] $larpix_uart_channel_6

  # Create instance: larpix_uart_channel_6_en_slice, and set properties
  set larpix_uart_channel_6_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_6_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_6_en_slice

  # Create instance: larpix_uart_channel_6_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_6_obuft_out
  if { [catch {set larpix_uart_channel_6_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_6_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_6_slice, and set properties
  set larpix_uart_channel_6_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_6_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {5} \
   CONFIG.DIN_TO {5} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_6_slice

  # Create instance: larpix_uart_channel_7, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_7
  if { [catch {set larpix_uart_channel_7 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_7 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x07} \
 ] $larpix_uart_channel_7

  # Create instance: larpix_uart_channel_7_en_slice, and set properties
  set larpix_uart_channel_7_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_7_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_7_en_slice

  # Create instance: larpix_uart_channel_7_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_7_obuft_out
  if { [catch {set larpix_uart_channel_7_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_7_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_7_slice, and set properties
  set larpix_uart_channel_7_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_7_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {6} \
   CONFIG.DIN_TO {6} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_7_slice

  # Create instance: larpix_uart_channel_8, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_8
  if { [catch {set larpix_uart_channel_8 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_8 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x08} \
 ] $larpix_uart_channel_8

  # Create instance: larpix_uart_channel_8_en_slice, and set properties
  set larpix_uart_channel_8_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_8_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_8_en_slice

  # Create instance: larpix_uart_channel_8_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_8_obuft_out
  if { [catch {set larpix_uart_channel_8_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_8_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_8_slice, and set properties
  set larpix_uart_channel_8_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_8_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {7} \
   CONFIG.DIN_TO {7} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_8_slice

  # Create instance: larpix_uart_channel_9, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_9
  if { [catch {set larpix_uart_channel_9 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_9 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x09} \
 ] $larpix_uart_channel_9

  # Create instance: larpix_uart_channel_25, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_25
  if { [catch {set larpix_uart_channel_25 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_25 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x19} \
 ] $larpix_uart_channel_25

  # Create instance: larpix_uart_channel_26, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_26
  if { [catch {set larpix_uart_channel_26 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_26 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x1A} \
 ] $larpix_uart_channel_26

  # Create instance: larpix_uart_channel_27, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_27
  if { [catch {set larpix_uart_channel_27 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_27 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x1B} \
 ] $larpix_uart_channel_27

  # Create instance: larpix_uart_channel_28, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_28
  if { [catch {set larpix_uart_channel_28 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_28 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x1C} \
 ] $larpix_uart_channel_28

  # Create instance: larpix_uart_channel_29, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_29
  if { [catch {set larpix_uart_channel_29 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_29 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x1D} \
 ] $larpix_uart_channel_29

  # Create instance: larpix_uart_channel_30, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_30
  if { [catch {set larpix_uart_channel_30 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_30 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x1E} \
 ] $larpix_uart_channel_30

  # Create instance: larpix_uart_channel_31, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_31
  if { [catch {set larpix_uart_channel_31 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_31 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x1F} \
 ] $larpix_uart_channel_31

  # Create instance: larpix_uart_channel_32, and set properties
  set block_name uart_channel
  set block_cell_name larpix_uart_channel_32
  if { [catch {set larpix_uart_channel_32 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_32 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_CHANNEL {0x20} \
 ] $larpix_uart_channel_32

  # Create instance: larpix_uart_channel_9_en_slice, and set properties
  set larpix_uart_channel_9_en_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_9_en_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {8} \
 ] $larpix_uart_channel_9_en_slice

  # Create instance: larpix_uart_channel_9_obuft_out, and set properties
  set block_name obuft_out
  set block_cell_name larpix_uart_channel_9_obuft_out
  if { [catch {set larpix_uart_channel_9_obuft_out [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_uart_channel_9_obuft_out eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_uart_channel_9_slice, and set properties
  set larpix_uart_channel_9_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 larpix_uart_channel_9_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {8} \
   CONFIG.DIN_TO {8} \
   CONFIG.DIN_WIDTH {32} \
 ] $larpix_uart_channel_9_slice

  # Create instance: mosi_merge, and set properties
  set mosi_merge [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 mosi_merge ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {32} \
 ] $mosi_merge

  # Create instance: or_uart_rx_busy, and set properties
  set or_uart_rx_busy [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 or_uart_rx_busy ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {32} \
 ] $or_uart_rx_busy

  # Create instance: or_uart_rx_busy_logic, and set properties
  set or_uart_rx_busy_logic [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic:2.0 or_uart_rx_busy_logic ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {or} \
   CONFIG.C_SIZE {32} \
 ] $or_uart_rx_busy_logic

  # Create instance: or_uart_tx_busy, and set properties
  set or_uart_tx_busy [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 or_uart_tx_busy ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {32} \
 ] $or_uart_tx_busy

  # Create instance: or_uart_tx_busy_logic, and set properties
  set or_uart_tx_busy_logic [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic:2.0 or_uart_tx_busy_logic ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {or} \
   CONFIG.C_SIZE {32} \
 ] $or_uart_tx_busy_logic

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIS10_1 [get_bd_intf_pins S_AXIS10] [get_bd_intf_pins larpix_uart_channel_11/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS11_1 [get_bd_intf_pins S_AXIS11] [get_bd_intf_pins larpix_uart_channel_12/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS12_1 [get_bd_intf_pins S_AXIS12] [get_bd_intf_pins larpix_uart_channel_13/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS13_1 [get_bd_intf_pins S_AXIS13] [get_bd_intf_pins larpix_uart_channel_14/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS14_1 [get_bd_intf_pins S_AXIS14] [get_bd_intf_pins larpix_uart_channel_15/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS15_1 [get_bd_intf_pins S_AXIS15] [get_bd_intf_pins larpix_uart_channel_16/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS16_1 [get_bd_intf_pins S_AXIS16] [get_bd_intf_pins larpix_uart_channel_17/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS17_1 [get_bd_intf_pins S_AXIS17] [get_bd_intf_pins larpix_uart_channel_18/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS18_1 [get_bd_intf_pins S_AXIS18] [get_bd_intf_pins larpix_uart_channel_19/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS19_1 [get_bd_intf_pins S_AXIS19] [get_bd_intf_pins larpix_uart_channel_20/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS1_1 [get_bd_intf_pins S_AXIS1] [get_bd_intf_pins larpix_uart_channel_2/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS20_1 [get_bd_intf_pins S_AXIS20] [get_bd_intf_pins larpix_uart_channel_21/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS21_1 [get_bd_intf_pins S_AXIS21] [get_bd_intf_pins larpix_uart_channel_22/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS22_1 [get_bd_intf_pins S_AXIS22] [get_bd_intf_pins larpix_uart_channel_23/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS23_1 [get_bd_intf_pins S_AXIS23] [get_bd_intf_pins larpix_uart_channel_24/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS24_1 [get_bd_intf_pins S_AXIS24] [get_bd_intf_pins larpix_uart_channel_25/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS25_1 [get_bd_intf_pins S_AXIS25] [get_bd_intf_pins larpix_uart_channel_26/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS26_1 [get_bd_intf_pins S_AXIS26] [get_bd_intf_pins larpix_uart_channel_27/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS27_1 [get_bd_intf_pins S_AXIS27] [get_bd_intf_pins larpix_uart_channel_28/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS28_1 [get_bd_intf_pins S_AXIS28] [get_bd_intf_pins larpix_uart_channel_29/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS29_1 [get_bd_intf_pins S_AXIS29] [get_bd_intf_pins larpix_uart_channel_30/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS2_1 [get_bd_intf_pins S_AXIS2] [get_bd_intf_pins larpix_uart_channel_3/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS30_1 [get_bd_intf_pins S_AXIS30] [get_bd_intf_pins larpix_uart_channel_31/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS31_1 [get_bd_intf_pins S_AXIS31] [get_bd_intf_pins larpix_uart_channel_32/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS3_1 [get_bd_intf_pins S_AXIS3] [get_bd_intf_pins larpix_uart_channel_4/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS4_1 [get_bd_intf_pins S_AXIS4] [get_bd_intf_pins larpix_uart_channel_5/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS5_1 [get_bd_intf_pins S_AXIS5] [get_bd_intf_pins larpix_uart_channel_6/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS6_1 [get_bd_intf_pins S_AXIS6] [get_bd_intf_pins larpix_uart_channel_7/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS7_1 [get_bd_intf_pins S_AXIS7] [get_bd_intf_pins larpix_uart_channel_8/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS8_1 [get_bd_intf_pins S_AXIS8] [get_bd_intf_pins larpix_uart_channel_9/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS9_1 [get_bd_intf_pins S_AXIS9] [get_bd_intf_pins larpix_uart_channel_10/S_AXIS]
  connect_bd_intf_net -intf_net S_AXIS_1 [get_bd_intf_pins S_AXIS] [get_bd_intf_pins larpix_uart_channel_1/S_AXIS]
  connect_bd_intf_net -intf_net S_AXI_LITE10_1 [get_bd_intf_pins S_AXI_LITE10] [get_bd_intf_pins larpix_uart_channel_11/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE11_1 [get_bd_intf_pins S_AXI_LITE11] [get_bd_intf_pins larpix_uart_channel_12/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE12_1 [get_bd_intf_pins S_AXI_LITE12] [get_bd_intf_pins larpix_uart_channel_13/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE13_1 [get_bd_intf_pins S_AXI_LITE13] [get_bd_intf_pins larpix_uart_channel_14/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE14_1 [get_bd_intf_pins S_AXI_LITE14] [get_bd_intf_pins larpix_uart_channel_15/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE15_1 [get_bd_intf_pins S_AXI_LITE15] [get_bd_intf_pins larpix_uart_channel_16/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE16_1 [get_bd_intf_pins S_AXI_LITE16] [get_bd_intf_pins larpix_uart_channel_17/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE17_1 [get_bd_intf_pins S_AXI_LITE17] [get_bd_intf_pins larpix_uart_channel_18/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE18_1 [get_bd_intf_pins S_AXI_LITE18] [get_bd_intf_pins larpix_uart_channel_19/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE19_1 [get_bd_intf_pins S_AXI_LITE19] [get_bd_intf_pins larpix_uart_channel_20/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE1_1 [get_bd_intf_pins S_AXI_LITE1] [get_bd_intf_pins larpix_uart_channel_2/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE20_1 [get_bd_intf_pins S_AXI_LITE20] [get_bd_intf_pins larpix_uart_channel_21/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE21_1 [get_bd_intf_pins S_AXI_LITE21] [get_bd_intf_pins larpix_uart_channel_22/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE22_1 [get_bd_intf_pins S_AXI_LITE22] [get_bd_intf_pins larpix_uart_channel_23/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE23_1 [get_bd_intf_pins S_AXI_LITE23] [get_bd_intf_pins larpix_uart_channel_24/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE24_1 [get_bd_intf_pins S_AXI_LITE24] [get_bd_intf_pins larpix_uart_channel_25/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE25_1 [get_bd_intf_pins S_AXI_LITE25] [get_bd_intf_pins larpix_uart_channel_26/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE26_1 [get_bd_intf_pins S_AXI_LITE26] [get_bd_intf_pins larpix_uart_channel_27/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE27_1 [get_bd_intf_pins S_AXI_LITE27] [get_bd_intf_pins larpix_uart_channel_28/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE28_1 [get_bd_intf_pins S_AXI_LITE28] [get_bd_intf_pins larpix_uart_channel_29/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE29_1 [get_bd_intf_pins S_AXI_LITE29] [get_bd_intf_pins larpix_uart_channel_30/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE2_1 [get_bd_intf_pins S_AXI_LITE2] [get_bd_intf_pins larpix_uart_channel_3/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE30_1 [get_bd_intf_pins S_AXI_LITE30] [get_bd_intf_pins larpix_uart_channel_31/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE31_1 [get_bd_intf_pins S_AXI_LITE31] [get_bd_intf_pins larpix_uart_channel_32/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE3_1 [get_bd_intf_pins S_AXI_LITE3] [get_bd_intf_pins larpix_uart_channel_4/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE4_1 [get_bd_intf_pins S_AXI_LITE4] [get_bd_intf_pins larpix_uart_channel_5/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE5_1 [get_bd_intf_pins S_AXI_LITE5] [get_bd_intf_pins larpix_uart_channel_6/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE6_1 [get_bd_intf_pins S_AXI_LITE6] [get_bd_intf_pins larpix_uart_channel_7/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE7_1 [get_bd_intf_pins S_AXI_LITE7] [get_bd_intf_pins larpix_uart_channel_8/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE8_1 [get_bd_intf_pins S_AXI_LITE8] [get_bd_intf_pins larpix_uart_channel_9/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE9_1 [get_bd_intf_pins S_AXI_LITE9] [get_bd_intf_pins larpix_uart_channel_10/S_AXI_LITE]
  connect_bd_intf_net -intf_net S_AXI_LITE_1 [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins larpix_uart_channel_1/S_AXI_LITE]
  connect_bd_intf_net -intf_net larpix_uart_channel_10_M_AXIS [get_bd_intf_pins M_AXIS9] [get_bd_intf_pins larpix_uart_channel_10/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_11_M_AXIS [get_bd_intf_pins M_AXIS10] [get_bd_intf_pins larpix_uart_channel_11/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_12_M_AXIS [get_bd_intf_pins M_AXIS11] [get_bd_intf_pins larpix_uart_channel_12/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_13_M_AXIS [get_bd_intf_pins M_AXIS12] [get_bd_intf_pins larpix_uart_channel_13/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_14_M_AXIS [get_bd_intf_pins M_AXIS13] [get_bd_intf_pins larpix_uart_channel_14/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_15_M_AXIS [get_bd_intf_pins M_AXIS14] [get_bd_intf_pins larpix_uart_channel_15/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_16_M_AXIS [get_bd_intf_pins M_AXIS15] [get_bd_intf_pins larpix_uart_channel_16/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_17_M_AXIS [get_bd_intf_pins M_AXIS16] [get_bd_intf_pins larpix_uart_channel_17/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_18_M_AXIS [get_bd_intf_pins M_AXIS17] [get_bd_intf_pins larpix_uart_channel_18/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_19_M_AXIS [get_bd_intf_pins M_AXIS18] [get_bd_intf_pins larpix_uart_channel_19/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_1_M_AXIS [get_bd_intf_pins M_AXIS] [get_bd_intf_pins larpix_uart_channel_1/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_20_M_AXIS [get_bd_intf_pins M_AXIS19] [get_bd_intf_pins larpix_uart_channel_20/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_21_M_AXIS [get_bd_intf_pins M_AXIS20] [get_bd_intf_pins larpix_uart_channel_21/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_22_M_AXIS [get_bd_intf_pins M_AXIS21] [get_bd_intf_pins larpix_uart_channel_22/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_23_M_AXIS [get_bd_intf_pins M_AXIS22] [get_bd_intf_pins larpix_uart_channel_23/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_24_M_AXIS [get_bd_intf_pins M_AXIS23] [get_bd_intf_pins larpix_uart_channel_24/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_25_M_AXIS [get_bd_intf_pins M_AXIS24] [get_bd_intf_pins larpix_uart_channel_25/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_26_M_AXIS [get_bd_intf_pins M_AXIS25] [get_bd_intf_pins larpix_uart_channel_26/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_27_M_AXIS [get_bd_intf_pins M_AXIS26] [get_bd_intf_pins larpix_uart_channel_27/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_28_M_AXIS [get_bd_intf_pins M_AXIS27] [get_bd_intf_pins larpix_uart_channel_28/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_29_M_AXIS [get_bd_intf_pins M_AXIS28] [get_bd_intf_pins larpix_uart_channel_29/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_2_M_AXIS [get_bd_intf_pins M_AXIS1] [get_bd_intf_pins larpix_uart_channel_2/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_30_M_AXIS [get_bd_intf_pins M_AXIS29] [get_bd_intf_pins larpix_uart_channel_30/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_31_M_AXIS [get_bd_intf_pins M_AXIS30] [get_bd_intf_pins larpix_uart_channel_31/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_32_M_AXIS [get_bd_intf_pins M_AXIS31] [get_bd_intf_pins larpix_uart_channel_32/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_3_M_AXIS [get_bd_intf_pins M_AXIS2] [get_bd_intf_pins larpix_uart_channel_3/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_4_M_AXIS [get_bd_intf_pins M_AXIS3] [get_bd_intf_pins larpix_uart_channel_4/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_5_M_AXIS [get_bd_intf_pins M_AXIS4] [get_bd_intf_pins larpix_uart_channel_5/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_6_M_AXIS [get_bd_intf_pins M_AXIS5] [get_bd_intf_pins larpix_uart_channel_6/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_7_M_AXIS [get_bd_intf_pins M_AXIS6] [get_bd_intf_pins larpix_uart_channel_7/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_8_M_AXIS [get_bd_intf_pins M_AXIS7] [get_bd_intf_pins larpix_uart_channel_8/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_channel_9_M_AXIS [get_bd_intf_pins M_AXIS8] [get_bd_intf_pins larpix_uart_channel_9/M_AXIS]

  # Create port connections
  connect_bd_net -net ACLK_1 [get_bd_pins ACLK] [get_bd_pins larpix_uart_channel_1/ACLK] [get_bd_pins larpix_uart_channel_10/ACLK] [get_bd_pins larpix_uart_channel_11/ACLK] [get_bd_pins larpix_uart_channel_12/ACLK] [get_bd_pins larpix_uart_channel_13/ACLK] [get_bd_pins larpix_uart_channel_14/ACLK] [get_bd_pins larpix_uart_channel_15/ACLK] [get_bd_pins larpix_uart_channel_16/ACLK] [get_bd_pins larpix_uart_channel_17/ACLK] [get_bd_pins larpix_uart_channel_18/ACLK] [get_bd_pins larpix_uart_channel_19/ACLK] [get_bd_pins larpix_uart_channel_2/ACLK] [get_bd_pins larpix_uart_channel_20/ACLK] [get_bd_pins larpix_uart_channel_21/ACLK] [get_bd_pins larpix_uart_channel_22/ACLK] [get_bd_pins larpix_uart_channel_23/ACLK] [get_bd_pins larpix_uart_channel_24/ACLK] [get_bd_pins larpix_uart_channel_25/ACLK] [get_bd_pins larpix_uart_channel_26/ACLK] [get_bd_pins larpix_uart_channel_27/ACLK] [get_bd_pins larpix_uart_channel_28/ACLK] [get_bd_pins larpix_uart_channel_29/ACLK] [get_bd_pins larpix_uart_channel_3/ACLK] [get_bd_pins larpix_uart_channel_30/ACLK] [get_bd_pins larpix_uart_channel_31/ACLK] [get_bd_pins larpix_uart_channel_32/ACLK] [get_bd_pins larpix_uart_channel_4/ACLK] [get_bd_pins larpix_uart_channel_5/ACLK] [get_bd_pins larpix_uart_channel_6/ACLK] [get_bd_pins larpix_uart_channel_7/ACLK] [get_bd_pins larpix_uart_channel_8/ACLK] [get_bd_pins larpix_uart_channel_9/ACLK]
  connect_bd_net -net ARESETN_1 [get_bd_pins ARESETN] [get_bd_pins larpix_uart_channel_1/ARESETN] [get_bd_pins larpix_uart_channel_10/ARESETN] [get_bd_pins larpix_uart_channel_11/ARESETN] [get_bd_pins larpix_uart_channel_12/ARESETN] [get_bd_pins larpix_uart_channel_13/ARESETN] [get_bd_pins larpix_uart_channel_14/ARESETN] [get_bd_pins larpix_uart_channel_15/ARESETN] [get_bd_pins larpix_uart_channel_16/ARESETN] [get_bd_pins larpix_uart_channel_17/ARESETN] [get_bd_pins larpix_uart_channel_18/ARESETN] [get_bd_pins larpix_uart_channel_19/ARESETN] [get_bd_pins larpix_uart_channel_2/ARESETN] [get_bd_pins larpix_uart_channel_20/ARESETN] [get_bd_pins larpix_uart_channel_21/ARESETN] [get_bd_pins larpix_uart_channel_22/ARESETN] [get_bd_pins larpix_uart_channel_23/ARESETN] [get_bd_pins larpix_uart_channel_24/ARESETN] [get_bd_pins larpix_uart_channel_25/ARESETN] [get_bd_pins larpix_uart_channel_26/ARESETN] [get_bd_pins larpix_uart_channel_27/ARESETN] [get_bd_pins larpix_uart_channel_28/ARESETN] [get_bd_pins larpix_uart_channel_29/ARESETN] [get_bd_pins larpix_uart_channel_3/ARESETN] [get_bd_pins larpix_uart_channel_30/ARESETN] [get_bd_pins larpix_uart_channel_31/ARESETN] [get_bd_pins larpix_uart_channel_32/ARESETN] [get_bd_pins larpix_uart_channel_4/ARESETN] [get_bd_pins larpix_uart_channel_5/ARESETN] [get_bd_pins larpix_uart_channel_6/ARESETN] [get_bd_pins larpix_uart_channel_7/ARESETN] [get_bd_pins larpix_uart_channel_8/ARESETN] [get_bd_pins larpix_uart_channel_9/ARESETN]
  connect_bd_net -net MCLK_1 [get_bd_pins MCLK] [get_bd_pins larpix_uart_channel_1/MCLK] [get_bd_pins larpix_uart_channel_10/MCLK] [get_bd_pins larpix_uart_channel_11/MCLK] [get_bd_pins larpix_uart_channel_12/MCLK] [get_bd_pins larpix_uart_channel_13/MCLK] [get_bd_pins larpix_uart_channel_14/MCLK] [get_bd_pins larpix_uart_channel_15/MCLK] [get_bd_pins larpix_uart_channel_16/MCLK] [get_bd_pins larpix_uart_channel_17/MCLK] [get_bd_pins larpix_uart_channel_18/MCLK] [get_bd_pins larpix_uart_channel_19/MCLK] [get_bd_pins larpix_uart_channel_2/MCLK] [get_bd_pins larpix_uart_channel_20/MCLK] [get_bd_pins larpix_uart_channel_21/MCLK] [get_bd_pins larpix_uart_channel_22/MCLK] [get_bd_pins larpix_uart_channel_23/MCLK] [get_bd_pins larpix_uart_channel_24/MCLK] [get_bd_pins larpix_uart_channel_25/MCLK] [get_bd_pins larpix_uart_channel_26/MCLK] [get_bd_pins larpix_uart_channel_27/MCLK] [get_bd_pins larpix_uart_channel_28/MCLK] [get_bd_pins larpix_uart_channel_29/MCLK] [get_bd_pins larpix_uart_channel_3/MCLK] [get_bd_pins larpix_uart_channel_30/MCLK] [get_bd_pins larpix_uart_channel_31/MCLK] [get_bd_pins larpix_uart_channel_32/MCLK] [get_bd_pins larpix_uart_channel_4/MCLK] [get_bd_pins larpix_uart_channel_5/MCLK] [get_bd_pins larpix_uart_channel_6/MCLK] [get_bd_pins larpix_uart_channel_7/MCLK] [get_bd_pins larpix_uart_channel_8/MCLK] [get_bd_pins larpix_uart_channel_9/MCLK]
  connect_bd_net -net MISO_1 [get_bd_pins MISO] [get_bd_pins larpix_uart_channel_10_slice/Din] [get_bd_pins larpix_uart_channel_11_slice/Din] [get_bd_pins larpix_uart_channel_12_slice/Din] [get_bd_pins larpix_uart_channel_13_slice/Din] [get_bd_pins larpix_uart_channel_14_slice/Din] [get_bd_pins larpix_uart_channel_15_slice/Din] [get_bd_pins larpix_uart_channel_16_slice/Din] [get_bd_pins larpix_uart_channel_17_slice/Din] [get_bd_pins larpix_uart_channel_18_slice/Din] [get_bd_pins larpix_uart_channel_19_slice/Din] [get_bd_pins larpix_uart_channel_1_slice/Din] [get_bd_pins larpix_uart_channel_20_slice/Din] [get_bd_pins larpix_uart_channel_21_slice/Din] [get_bd_pins larpix_uart_channel_22_slice/Din] [get_bd_pins larpix_uart_channel_23_slice/Din] [get_bd_pins larpix_uart_channel_24_slice/Din] [get_bd_pins larpix_uart_channel_25_slice/Din] [get_bd_pins larpix_uart_channel_26_slice/Din] [get_bd_pins larpix_uart_channel_27_slice/Din] [get_bd_pins larpix_uart_channel_28_slice/Din] [get_bd_pins larpix_uart_channel_29_slice/Din] [get_bd_pins larpix_uart_channel_2_slice/Din] [get_bd_pins larpix_uart_channel_30_slice/Din] [get_bd_pins larpix_uart_channel_31_slice/Din] [get_bd_pins larpix_uart_channel_32_slice/Din] [get_bd_pins larpix_uart_channel_3_slice/Din] [get_bd_pins larpix_uart_channel_4_slice/Din] [get_bd_pins larpix_uart_channel_5_slice/Din] [get_bd_pins larpix_uart_channel_6_slice/Din] [get_bd_pins larpix_uart_channel_7_slice/Din] [get_bd_pins larpix_uart_channel_8_slice/Din] [get_bd_pins larpix_uart_channel_9_slice/Din]
  connect_bd_net -net PACMAN_TS_1 [get_bd_pins PACMAN_TS] [get_bd_pins larpix_uart_channel_1/PACMAN_TS] [get_bd_pins larpix_uart_channel_10/PACMAN_TS] [get_bd_pins larpix_uart_channel_11/PACMAN_TS] [get_bd_pins larpix_uart_channel_12/PACMAN_TS] [get_bd_pins larpix_uart_channel_13/PACMAN_TS] [get_bd_pins larpix_uart_channel_14/PACMAN_TS] [get_bd_pins larpix_uart_channel_15/PACMAN_TS] [get_bd_pins larpix_uart_channel_16/PACMAN_TS] [get_bd_pins larpix_uart_channel_17/PACMAN_TS] [get_bd_pins larpix_uart_channel_18/PACMAN_TS] [get_bd_pins larpix_uart_channel_19/PACMAN_TS] [get_bd_pins larpix_uart_channel_2/PACMAN_TS] [get_bd_pins larpix_uart_channel_20/PACMAN_TS] [get_bd_pins larpix_uart_channel_21/PACMAN_TS] [get_bd_pins larpix_uart_channel_22/PACMAN_TS] [get_bd_pins larpix_uart_channel_23/PACMAN_TS] [get_bd_pins larpix_uart_channel_24/PACMAN_TS] [get_bd_pins larpix_uart_channel_25/PACMAN_TS] [get_bd_pins larpix_uart_channel_26/PACMAN_TS] [get_bd_pins larpix_uart_channel_27/PACMAN_TS] [get_bd_pins larpix_uart_channel_28/PACMAN_TS] [get_bd_pins larpix_uart_channel_29/PACMAN_TS] [get_bd_pins larpix_uart_channel_3/PACMAN_TS] [get_bd_pins larpix_uart_channel_30/PACMAN_TS] [get_bd_pins larpix_uart_channel_31/PACMAN_TS] [get_bd_pins larpix_uart_channel_32/PACMAN_TS] [get_bd_pins larpix_uart_channel_4/PACMAN_TS] [get_bd_pins larpix_uart_channel_5/PACMAN_TS] [get_bd_pins larpix_uart_channel_6/PACMAN_TS] [get_bd_pins larpix_uart_channel_7/PACMAN_TS] [get_bd_pins larpix_uart_channel_8/PACMAN_TS] [get_bd_pins larpix_uart_channel_9/PACMAN_TS]
  connect_bd_net -net TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins larpix_uart_channel_10_en_slice/Din] [get_bd_pins larpix_uart_channel_11_en_slice/Din] [get_bd_pins larpix_uart_channel_12_en_slice/Din] [get_bd_pins larpix_uart_channel_13_en_slice/Din] [get_bd_pins larpix_uart_channel_14_en_slice/Din] [get_bd_pins larpix_uart_channel_15_en_slice/Din] [get_bd_pins larpix_uart_channel_16_en_slice/Din] [get_bd_pins larpix_uart_channel_17_en_slice/Din] [get_bd_pins larpix_uart_channel_18_en_slice/Din] [get_bd_pins larpix_uart_channel_19_en_slice/Din] [get_bd_pins larpix_uart_channel_1_en_slice/Din] [get_bd_pins larpix_uart_channel_20_en_slice/Din] [get_bd_pins larpix_uart_channel_21_en_slice/Din] [get_bd_pins larpix_uart_channel_22_en_slice/Din] [get_bd_pins larpix_uart_channel_23_en_slice/Din] [get_bd_pins larpix_uart_channel_24_en_slice/Din] [get_bd_pins larpix_uart_channel_25_en_slice/Din] [get_bd_pins larpix_uart_channel_26_en_slice/Din] [get_bd_pins larpix_uart_channel_27_en_slice/Din] [get_bd_pins larpix_uart_channel_28_en_slice/Din] [get_bd_pins larpix_uart_channel_29_en_slice/Din] [get_bd_pins larpix_uart_channel_2_en_slice/Din] [get_bd_pins larpix_uart_channel_30_en_slice/Din] [get_bd_pins larpix_uart_channel_31_en_slice/Din] [get_bd_pins larpix_uart_channel_32_en_slice/Din] [get_bd_pins larpix_uart_channel_3_en_slice/Din] [get_bd_pins larpix_uart_channel_4_en_slice/Din] [get_bd_pins larpix_uart_channel_5_en_slice/Din] [get_bd_pins larpix_uart_channel_6_en_slice/Din] [get_bd_pins larpix_uart_channel_7_en_slice/Din] [get_bd_pins larpix_uart_channel_8_en_slice/Din] [get_bd_pins larpix_uart_channel_9_en_slice/Din]
  connect_bd_net -net larpix_uart_channel_10_UART_RX_BUSY [get_bd_pins larpix_uart_channel_10/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In9]
  connect_bd_net -net larpix_uart_channel_10_UART_TX [get_bd_pins larpix_uart_channel_10/UART_TX] [get_bd_pins larpix_uart_channel_10_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_10_UART_TX_BUSY [get_bd_pins larpix_uart_channel_10/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In9]
  connect_bd_net -net larpix_uart_channel_10_en_slice_Dout [get_bd_pins larpix_uart_channel_10_en_slice/Dout] [get_bd_pins larpix_uart_channel_10_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_10_obuft_out_o [get_bd_pins larpix_uart_channel_10_obuft_out/o] [get_bd_pins mosi_merge/In9]
  connect_bd_net -net larpix_uart_channel_10_slice_Dout [get_bd_pins larpix_uart_channel_10/UART_RX] [get_bd_pins larpix_uart_channel_10_slice/Dout]
  connect_bd_net -net larpix_uart_channel_11_UART_RX_BUSY [get_bd_pins larpix_uart_channel_11/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In10]
  connect_bd_net -net larpix_uart_channel_11_UART_TX [get_bd_pins larpix_uart_channel_11/UART_TX] [get_bd_pins larpix_uart_channel_11_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_11_UART_TX_BUSY [get_bd_pins larpix_uart_channel_11/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In10]
  connect_bd_net -net larpix_uart_channel_11_en_slice_Dout [get_bd_pins larpix_uart_channel_11_en_slice/Dout] [get_bd_pins larpix_uart_channel_11_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_11_obuft_out_o [get_bd_pins larpix_uart_channel_11_obuft_out/o] [get_bd_pins mosi_merge/In10]
  connect_bd_net -net larpix_uart_channel_11_slice_Dout [get_bd_pins larpix_uart_channel_11/UART_RX] [get_bd_pins larpix_uart_channel_11_slice/Dout]
  connect_bd_net -net larpix_uart_channel_12_UART_RX_BUSY [get_bd_pins larpix_uart_channel_12/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In11]
  connect_bd_net -net larpix_uart_channel_12_UART_TX [get_bd_pins larpix_uart_channel_12/UART_TX] [get_bd_pins larpix_uart_channel_12_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_12_UART_TX_BUSY [get_bd_pins larpix_uart_channel_12/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In11]
  connect_bd_net -net larpix_uart_channel_12_en_slice_Dout [get_bd_pins larpix_uart_channel_12_en_slice/Dout] [get_bd_pins larpix_uart_channel_12_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_12_obuft_out_o [get_bd_pins larpix_uart_channel_12_obuft_out/o] [get_bd_pins mosi_merge/In11]
  connect_bd_net -net larpix_uart_channel_12_slice_Dout [get_bd_pins larpix_uart_channel_12/UART_RX] [get_bd_pins larpix_uart_channel_12_slice/Dout]
  connect_bd_net -net larpix_uart_channel_13_UART_RX_BUSY [get_bd_pins larpix_uart_channel_13/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In12]
  connect_bd_net -net larpix_uart_channel_13_UART_TX [get_bd_pins larpix_uart_channel_13/UART_TX] [get_bd_pins larpix_uart_channel_13_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_13_UART_TX_BUSY [get_bd_pins larpix_uart_channel_13/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In12]
  connect_bd_net -net larpix_uart_channel_13_en_slice_Dout [get_bd_pins larpix_uart_channel_13_en_slice/Dout] [get_bd_pins larpix_uart_channel_13_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_13_obuft_out_o [get_bd_pins larpix_uart_channel_13_obuft_out/o] [get_bd_pins mosi_merge/In12]
  connect_bd_net -net larpix_uart_channel_13_slice_Dout [get_bd_pins larpix_uart_channel_13/UART_RX] [get_bd_pins larpix_uart_channel_13_slice/Dout]
  connect_bd_net -net larpix_uart_channel_14_UART_RX_BUSY [get_bd_pins larpix_uart_channel_14/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In13]
  connect_bd_net -net larpix_uart_channel_14_UART_TX [get_bd_pins larpix_uart_channel_14/UART_TX] [get_bd_pins larpix_uart_channel_14_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_14_UART_TX_BUSY [get_bd_pins larpix_uart_channel_14/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In13]
  connect_bd_net -net larpix_uart_channel_14_en_slice_Dout [get_bd_pins larpix_uart_channel_14_en_slice/Dout] [get_bd_pins larpix_uart_channel_14_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_14_obuft_out_o [get_bd_pins larpix_uart_channel_14_obuft_out/o] [get_bd_pins mosi_merge/In13]
  connect_bd_net -net larpix_uart_channel_14_slice_Dout [get_bd_pins larpix_uart_channel_14/UART_RX] [get_bd_pins larpix_uart_channel_14_slice/Dout]
  connect_bd_net -net larpix_uart_channel_15_UART_RX_BUSY [get_bd_pins larpix_uart_channel_15/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In14]
  connect_bd_net -net larpix_uart_channel_15_UART_TX [get_bd_pins larpix_uart_channel_15/UART_TX] [get_bd_pins larpix_uart_channel_15_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_15_UART_TX_BUSY [get_bd_pins larpix_uart_channel_15/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In14]
  connect_bd_net -net larpix_uart_channel_15_en_slice_Dout [get_bd_pins larpix_uart_channel_15_en_slice/Dout] [get_bd_pins larpix_uart_channel_15_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_15_obuft_out_o [get_bd_pins larpix_uart_channel_15_obuft_out/o] [get_bd_pins mosi_merge/In14]
  connect_bd_net -net larpix_uart_channel_15_slice_Dout [get_bd_pins larpix_uart_channel_15/UART_RX] [get_bd_pins larpix_uart_channel_15_slice/Dout]
  connect_bd_net -net larpix_uart_channel_16_UART_RX_BUSY [get_bd_pins larpix_uart_channel_16/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In15]
  connect_bd_net -net larpix_uart_channel_16_UART_TX [get_bd_pins larpix_uart_channel_16/UART_TX] [get_bd_pins larpix_uart_channel_16_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_16_UART_TX_BUSY [get_bd_pins larpix_uart_channel_16/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In15]
  connect_bd_net -net larpix_uart_channel_16_en_slice_Dout [get_bd_pins larpix_uart_channel_16_en_slice/Dout] [get_bd_pins larpix_uart_channel_16_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_16_obuft_out_o [get_bd_pins larpix_uart_channel_16_obuft_out/o] [get_bd_pins mosi_merge/In15]
  connect_bd_net -net larpix_uart_channel_16_slice_Dout [get_bd_pins larpix_uart_channel_16/UART_RX] [get_bd_pins larpix_uart_channel_16_slice/Dout]
  connect_bd_net -net larpix_uart_channel_17_UART_RX_BUSY [get_bd_pins larpix_uart_channel_17/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In16]
  connect_bd_net -net larpix_uart_channel_17_UART_TX [get_bd_pins larpix_uart_channel_17/UART_TX] [get_bd_pins larpix_uart_channel_17_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_17_UART_TX_BUSY [get_bd_pins larpix_uart_channel_17/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In16]
  connect_bd_net -net larpix_uart_channel_17_en_slice_Dout [get_bd_pins larpix_uart_channel_17_en_slice/Dout] [get_bd_pins larpix_uart_channel_17_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_17_obuft_out_o [get_bd_pins larpix_uart_channel_17_obuft_out/o] [get_bd_pins mosi_merge/In16]
  connect_bd_net -net larpix_uart_channel_17_slice_Dout [get_bd_pins larpix_uart_channel_17/UART_RX] [get_bd_pins larpix_uart_channel_17_slice/Dout]
  connect_bd_net -net larpix_uart_channel_18_UART_RX_BUSY [get_bd_pins larpix_uart_channel_18/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In17]
  connect_bd_net -net larpix_uart_channel_18_UART_TX [get_bd_pins larpix_uart_channel_18/UART_TX] [get_bd_pins larpix_uart_channel_18_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_18_UART_TX_BUSY [get_bd_pins larpix_uart_channel_18/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In17]
  connect_bd_net -net larpix_uart_channel_18_en_slice_Dout [get_bd_pins larpix_uart_channel_18_en_slice/Dout] [get_bd_pins larpix_uart_channel_18_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_18_obuft_out_o [get_bd_pins larpix_uart_channel_18_obuft_out/o] [get_bd_pins mosi_merge/In17]
  connect_bd_net -net larpix_uart_channel_18_slice_Dout [get_bd_pins larpix_uart_channel_18/UART_RX] [get_bd_pins larpix_uart_channel_18_slice/Dout]
  connect_bd_net -net larpix_uart_channel_19_UART_RX_BUSY [get_bd_pins larpix_uart_channel_19/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In18]
  connect_bd_net -net larpix_uart_channel_19_UART_TX [get_bd_pins larpix_uart_channel_19/UART_TX] [get_bd_pins larpix_uart_channel_19_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_19_UART_TX_BUSY [get_bd_pins larpix_uart_channel_19/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In18]
  connect_bd_net -net larpix_uart_channel_19_en_slice_Dout [get_bd_pins larpix_uart_channel_19_en_slice/Dout] [get_bd_pins larpix_uart_channel_19_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_19_obuft_out_o [get_bd_pins larpix_uart_channel_19_obuft_out/o] [get_bd_pins mosi_merge/In18]
  connect_bd_net -net larpix_uart_channel_19_slice_Dout [get_bd_pins larpix_uart_channel_19/UART_RX] [get_bd_pins larpix_uart_channel_19_slice/Dout]
  connect_bd_net -net larpix_uart_channel_1_UART_RX_BUSY [get_bd_pins larpix_uart_channel_1/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In0]
  connect_bd_net -net larpix_uart_channel_1_UART_TX [get_bd_pins larpix_uart_channel_1/UART_TX] [get_bd_pins larpix_uart_channel_1_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_1_UART_TX_BUSY [get_bd_pins larpix_uart_channel_1/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In0]
  connect_bd_net -net larpix_uart_channel_1_en_slice_Dout [get_bd_pins larpix_uart_channel_1_en_slice/Dout] [get_bd_pins larpix_uart_channel_1_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_1_obuft_out_o [get_bd_pins larpix_uart_channel_1_obuft_out/o] [get_bd_pins mosi_merge/In0]
  connect_bd_net -net larpix_uart_channel_1_slice_Dout [get_bd_pins larpix_uart_channel_1/UART_RX] [get_bd_pins larpix_uart_channel_1_slice/Dout]
  connect_bd_net -net larpix_uart_channel_20_UART_RX_BUSY [get_bd_pins larpix_uart_channel_20/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In19]
  connect_bd_net -net larpix_uart_channel_20_UART_TX [get_bd_pins larpix_uart_channel_20/UART_TX] [get_bd_pins larpix_uart_channel_20_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_20_UART_TX_BUSY [get_bd_pins larpix_uart_channel_20/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In19]
  connect_bd_net -net larpix_uart_channel_20_en_slice_Dout [get_bd_pins larpix_uart_channel_20_en_slice/Dout] [get_bd_pins larpix_uart_channel_20_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_20_obuft_out_o [get_bd_pins larpix_uart_channel_20_obuft_out/o] [get_bd_pins mosi_merge/In19]
  connect_bd_net -net larpix_uart_channel_20_slice_Dout [get_bd_pins larpix_uart_channel_20/UART_RX] [get_bd_pins larpix_uart_channel_20_slice/Dout]
  connect_bd_net -net larpix_uart_channel_21_UART_RX_BUSY [get_bd_pins larpix_uart_channel_21/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In20]
  connect_bd_net -net larpix_uart_channel_21_UART_TX [get_bd_pins larpix_uart_channel_21/UART_TX] [get_bd_pins larpix_uart_channel_21_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_21_UART_TX_BUSY [get_bd_pins larpix_uart_channel_21/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In20]
  connect_bd_net -net larpix_uart_channel_21_en_slice_Dout [get_bd_pins larpix_uart_channel_21_en_slice/Dout] [get_bd_pins larpix_uart_channel_21_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_21_obuft_out_o [get_bd_pins larpix_uart_channel_21_obuft_out/o] [get_bd_pins mosi_merge/In20]
  connect_bd_net -net larpix_uart_channel_21_slice_Dout [get_bd_pins larpix_uart_channel_21/UART_RX] [get_bd_pins larpix_uart_channel_21_slice/Dout]
  connect_bd_net -net larpix_uart_channel_22_UART_RX_BUSY [get_bd_pins larpix_uart_channel_22/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In21]
  connect_bd_net -net larpix_uart_channel_22_UART_TX [get_bd_pins larpix_uart_channel_22/UART_TX] [get_bd_pins larpix_uart_channel_22_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_22_UART_TX_BUSY [get_bd_pins larpix_uart_channel_22/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In21]
  connect_bd_net -net larpix_uart_channel_22_en_slice_Dout [get_bd_pins larpix_uart_channel_22_en_slice/Dout] [get_bd_pins larpix_uart_channel_22_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_22_obuft_out_o [get_bd_pins larpix_uart_channel_22_obuft_out/o] [get_bd_pins mosi_merge/In21]
  connect_bd_net -net larpix_uart_channel_22_slice_Dout [get_bd_pins larpix_uart_channel_22/UART_RX] [get_bd_pins larpix_uart_channel_22_slice/Dout]
  connect_bd_net -net larpix_uart_channel_23_UART_RX_BUSY [get_bd_pins larpix_uart_channel_23/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In22]
  connect_bd_net -net larpix_uart_channel_23_UART_TX [get_bd_pins larpix_uart_channel_23/UART_TX] [get_bd_pins larpix_uart_channel_23_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_23_UART_TX_BUSY [get_bd_pins larpix_uart_channel_23/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In22]
  connect_bd_net -net larpix_uart_channel_23_en_slice_Dout [get_bd_pins larpix_uart_channel_23_en_slice/Dout] [get_bd_pins larpix_uart_channel_23_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_23_obuft_out_o [get_bd_pins larpix_uart_channel_23_obuft_out/o] [get_bd_pins mosi_merge/In22]
  connect_bd_net -net larpix_uart_channel_23_slice_Dout [get_bd_pins larpix_uart_channel_23/UART_RX] [get_bd_pins larpix_uart_channel_23_slice/Dout]
  connect_bd_net -net larpix_uart_channel_24_UART_RX_BUSY [get_bd_pins larpix_uart_channel_24/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In23]
  connect_bd_net -net larpix_uart_channel_24_UART_TX [get_bd_pins larpix_uart_channel_24/UART_TX] [get_bd_pins larpix_uart_channel_24_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_24_UART_TX_BUSY [get_bd_pins larpix_uart_channel_24/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In23]
  connect_bd_net -net larpix_uart_channel_24_en_slice_Dout [get_bd_pins larpix_uart_channel_24_en_slice/Dout] [get_bd_pins larpix_uart_channel_24_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_24_obuft_out_o [get_bd_pins larpix_uart_channel_24_obuft_out/o] [get_bd_pins mosi_merge/In23]
  connect_bd_net -net larpix_uart_channel_24_slice_Dout [get_bd_pins larpix_uart_channel_24/UART_RX] [get_bd_pins larpix_uart_channel_24_slice/Dout]
  connect_bd_net -net larpix_uart_channel_25_UART_RX_BUSY [get_bd_pins larpix_uart_channel_25/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In24]
  connect_bd_net -net larpix_uart_channel_25_UART_TX [get_bd_pins larpix_uart_channel_25/UART_TX] [get_bd_pins larpix_uart_channel_25_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_25_UART_TX_BUSY [get_bd_pins larpix_uart_channel_25/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In24]
  connect_bd_net -net larpix_uart_channel_25_en_slice_Dout [get_bd_pins larpix_uart_channel_25_en_slice/Dout] [get_bd_pins larpix_uart_channel_25_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_25_obuft_out_o [get_bd_pins larpix_uart_channel_25_obuft_out/o] [get_bd_pins mosi_merge/In24]
  connect_bd_net -net larpix_uart_channel_25_slice_Dout [get_bd_pins larpix_uart_channel_25/UART_RX] [get_bd_pins larpix_uart_channel_25_slice/Dout]
  connect_bd_net -net larpix_uart_channel_26_UART_RX_BUSY [get_bd_pins larpix_uart_channel_26/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In25]
  connect_bd_net -net larpix_uart_channel_26_UART_TX [get_bd_pins larpix_uart_channel_26/UART_TX] [get_bd_pins larpix_uart_channel_26_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_26_UART_TX_BUSY [get_bd_pins larpix_uart_channel_26/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In25]
  connect_bd_net -net larpix_uart_channel_26_en_slice_Dout [get_bd_pins larpix_uart_channel_26_en_slice/Dout] [get_bd_pins larpix_uart_channel_26_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_26_obuft_out_o [get_bd_pins larpix_uart_channel_26_obuft_out/o] [get_bd_pins mosi_merge/In25]
  connect_bd_net -net larpix_uart_channel_26_slice_Dout [get_bd_pins larpix_uart_channel_26/UART_RX] [get_bd_pins larpix_uart_channel_26_slice/Dout]
  connect_bd_net -net larpix_uart_channel_27_UART_RX_BUSY [get_bd_pins larpix_uart_channel_27/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In26]
  connect_bd_net -net larpix_uart_channel_27_UART_TX [get_bd_pins larpix_uart_channel_27/UART_TX] [get_bd_pins larpix_uart_channel_27_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_27_UART_TX_BUSY [get_bd_pins larpix_uart_channel_27/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In26]
  connect_bd_net -net larpix_uart_channel_27_en_slice_Dout [get_bd_pins larpix_uart_channel_27_en_slice/Dout] [get_bd_pins larpix_uart_channel_27_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_27_obuft_out_o [get_bd_pins larpix_uart_channel_27_obuft_out/o] [get_bd_pins mosi_merge/In26]
  connect_bd_net -net larpix_uart_channel_27_slice_Dout [get_bd_pins larpix_uart_channel_27/UART_RX] [get_bd_pins larpix_uart_channel_27_slice/Dout]
  connect_bd_net -net larpix_uart_channel_28_UART_RX_BUSY [get_bd_pins larpix_uart_channel_28/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In27]
  connect_bd_net -net larpix_uart_channel_28_UART_TX [get_bd_pins larpix_uart_channel_28/UART_TX] [get_bd_pins larpix_uart_channel_28_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_28_UART_TX_BUSY [get_bd_pins larpix_uart_channel_28/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In27]
  connect_bd_net -net larpix_uart_channel_28_en_slice_Dout [get_bd_pins larpix_uart_channel_28_en_slice/Dout] [get_bd_pins larpix_uart_channel_28_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_28_obuft_out_o [get_bd_pins larpix_uart_channel_28_obuft_out/o] [get_bd_pins mosi_merge/In27]
  connect_bd_net -net larpix_uart_channel_28_slice_Dout [get_bd_pins larpix_uart_channel_28/UART_RX] [get_bd_pins larpix_uart_channel_28_slice/Dout]
  connect_bd_net -net larpix_uart_channel_29_UART_RX_BUSY [get_bd_pins larpix_uart_channel_29/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In28]
  connect_bd_net -net larpix_uart_channel_29_UART_TX [get_bd_pins larpix_uart_channel_29/UART_TX] [get_bd_pins larpix_uart_channel_29_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_29_UART_TX_BUSY [get_bd_pins larpix_uart_channel_29/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In28]
  connect_bd_net -net larpix_uart_channel_29_en_slice_Dout [get_bd_pins larpix_uart_channel_29_en_slice/Dout] [get_bd_pins larpix_uart_channel_29_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_29_obuft_out_o [get_bd_pins larpix_uart_channel_29_obuft_out/o] [get_bd_pins mosi_merge/In28]
  connect_bd_net -net larpix_uart_channel_29_slice_Dout [get_bd_pins larpix_uart_channel_29/UART_RX] [get_bd_pins larpix_uart_channel_29_slice/Dout]
  connect_bd_net -net larpix_uart_channel_2_UART_RX_BUSY [get_bd_pins larpix_uart_channel_2/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In1]
  connect_bd_net -net larpix_uart_channel_2_UART_TX [get_bd_pins larpix_uart_channel_2/UART_TX] [get_bd_pins larpix_uart_channel_2_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_2_UART_TX_BUSY [get_bd_pins larpix_uart_channel_2/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In1]
  connect_bd_net -net larpix_uart_channel_2_en_slice_Dout [get_bd_pins larpix_uart_channel_2_en_slice/Dout] [get_bd_pins larpix_uart_channel_2_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_2_obuft_out_o [get_bd_pins larpix_uart_channel_2_obuft_out/o] [get_bd_pins mosi_merge/In1]
  connect_bd_net -net larpix_uart_channel_2_slice_Dout [get_bd_pins larpix_uart_channel_2/UART_RX] [get_bd_pins larpix_uart_channel_2_slice/Dout]
  connect_bd_net -net larpix_uart_channel_30_UART_RX_BUSY [get_bd_pins larpix_uart_channel_30/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In29]
  connect_bd_net -net larpix_uart_channel_30_UART_TX [get_bd_pins larpix_uart_channel_30/UART_TX] [get_bd_pins larpix_uart_channel_30_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_30_UART_TX_BUSY [get_bd_pins larpix_uart_channel_30/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In29]
  connect_bd_net -net larpix_uart_channel_30_en_slice_Dout [get_bd_pins larpix_uart_channel_30_en_slice/Dout] [get_bd_pins larpix_uart_channel_30_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_30_obuft_out_o [get_bd_pins larpix_uart_channel_30_obuft_out/o] [get_bd_pins mosi_merge/In29]
  connect_bd_net -net larpix_uart_channel_30_slice_Dout [get_bd_pins larpix_uart_channel_30/UART_RX] [get_bd_pins larpix_uart_channel_30_slice/Dout]
  connect_bd_net -net larpix_uart_channel_31_UART_RX_BUSY [get_bd_pins larpix_uart_channel_31/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In30]
  connect_bd_net -net larpix_uart_channel_31_UART_TX [get_bd_pins larpix_uart_channel_31/UART_TX] [get_bd_pins larpix_uart_channel_31_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_31_UART_TX_BUSY [get_bd_pins larpix_uart_channel_31/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In30]
  connect_bd_net -net larpix_uart_channel_31_en_slice_Dout [get_bd_pins larpix_uart_channel_31_en_slice/Dout] [get_bd_pins larpix_uart_channel_31_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_31_obuft_out_o [get_bd_pins larpix_uart_channel_31_obuft_out/o] [get_bd_pins mosi_merge/In30]
  connect_bd_net -net larpix_uart_channel_31_slice_Dout [get_bd_pins larpix_uart_channel_31/UART_RX] [get_bd_pins larpix_uart_channel_31_slice/Dout]
  connect_bd_net -net larpix_uart_channel_32_UART_RX_BUSY [get_bd_pins larpix_uart_channel_32/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In31]
  connect_bd_net -net larpix_uart_channel_32_UART_TX [get_bd_pins larpix_uart_channel_32/UART_TX] [get_bd_pins larpix_uart_channel_32_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_32_UART_TX_BUSY [get_bd_pins larpix_uart_channel_32/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In31]
  connect_bd_net -net larpix_uart_channel_32_en_slice_Dout [get_bd_pins larpix_uart_channel_32_en_slice/Dout] [get_bd_pins larpix_uart_channel_32_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_32_obuft_out_o [get_bd_pins larpix_uart_channel_32_obuft_out/o] [get_bd_pins mosi_merge/In31]
  connect_bd_net -net larpix_uart_channel_32_slice_Dout [get_bd_pins larpix_uart_channel_32/UART_RX] [get_bd_pins larpix_uart_channel_32_slice/Dout]
  connect_bd_net -net larpix_uart_channel_3_UART_RX_BUSY [get_bd_pins larpix_uart_channel_3/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In2]
  connect_bd_net -net larpix_uart_channel_3_UART_TX [get_bd_pins larpix_uart_channel_3/UART_TX] [get_bd_pins larpix_uart_channel_3_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_3_UART_TX_BUSY [get_bd_pins larpix_uart_channel_3/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In2]
  connect_bd_net -net larpix_uart_channel_3_en_slice_Dout [get_bd_pins larpix_uart_channel_3_en_slice/Dout] [get_bd_pins larpix_uart_channel_3_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_3_obuft_out_o [get_bd_pins larpix_uart_channel_3_obuft_out/o] [get_bd_pins mosi_merge/In2]
  connect_bd_net -net larpix_uart_channel_3_slice_Dout [get_bd_pins larpix_uart_channel_3/UART_RX] [get_bd_pins larpix_uart_channel_3_slice/Dout]
  connect_bd_net -net larpix_uart_channel_4_UART_RX_BUSY [get_bd_pins larpix_uart_channel_4/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In3]
  connect_bd_net -net larpix_uart_channel_4_UART_TX [get_bd_pins larpix_uart_channel_4/UART_TX] [get_bd_pins larpix_uart_channel_4_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_4_UART_TX_BUSY [get_bd_pins larpix_uart_channel_4/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In3]
  connect_bd_net -net larpix_uart_channel_4_en_slice_Dout [get_bd_pins larpix_uart_channel_4_en_slice/Dout] [get_bd_pins larpix_uart_channel_4_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_4_obuft_out_o [get_bd_pins larpix_uart_channel_4_obuft_out/o] [get_bd_pins mosi_merge/In3]
  connect_bd_net -net larpix_uart_channel_4_slice_Dout [get_bd_pins larpix_uart_channel_4/UART_RX] [get_bd_pins larpix_uart_channel_4_slice/Dout]
  connect_bd_net -net larpix_uart_channel_5_UART_RX_BUSY [get_bd_pins larpix_uart_channel_5/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In4]
  connect_bd_net -net larpix_uart_channel_5_UART_TX [get_bd_pins larpix_uart_channel_5/UART_TX] [get_bd_pins larpix_uart_channel_5_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_5_UART_TX_BUSY [get_bd_pins larpix_uart_channel_5/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In4]
  connect_bd_net -net larpix_uart_channel_5_en_slice_Dout [get_bd_pins larpix_uart_channel_5_en_slice/Dout] [get_bd_pins larpix_uart_channel_5_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_5_obuft_out_o [get_bd_pins larpix_uart_channel_5_obuft_out/o] [get_bd_pins mosi_merge/In4]
  connect_bd_net -net larpix_uart_channel_5_slice_Dout [get_bd_pins larpix_uart_channel_5/UART_RX] [get_bd_pins larpix_uart_channel_5_slice/Dout]
  connect_bd_net -net larpix_uart_channel_6_UART_RX_BUSY [get_bd_pins larpix_uart_channel_6/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In5]
  connect_bd_net -net larpix_uart_channel_6_UART_TX [get_bd_pins larpix_uart_channel_6/UART_TX] [get_bd_pins larpix_uart_channel_6_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_6_UART_TX_BUSY [get_bd_pins larpix_uart_channel_6/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In5]
  connect_bd_net -net larpix_uart_channel_6_en_slice_Dout [get_bd_pins larpix_uart_channel_6_en_slice/Dout] [get_bd_pins larpix_uart_channel_6_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_6_obuft_out_o [get_bd_pins larpix_uart_channel_6_obuft_out/o] [get_bd_pins mosi_merge/In5]
  connect_bd_net -net larpix_uart_channel_6_slice_Dout [get_bd_pins larpix_uart_channel_6/UART_RX] [get_bd_pins larpix_uart_channel_6_slice/Dout]
  connect_bd_net -net larpix_uart_channel_7_UART_RX_BUSY [get_bd_pins larpix_uart_channel_7/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In6]
  connect_bd_net -net larpix_uart_channel_7_UART_TX [get_bd_pins larpix_uart_channel_7/UART_TX] [get_bd_pins larpix_uart_channel_7_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_7_UART_TX_BUSY [get_bd_pins larpix_uart_channel_7/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In6]
  connect_bd_net -net larpix_uart_channel_7_en_slice_Dout [get_bd_pins larpix_uart_channel_7_en_slice/Dout] [get_bd_pins larpix_uart_channel_7_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_7_obuft_out_o [get_bd_pins larpix_uart_channel_7_obuft_out/o] [get_bd_pins mosi_merge/In6]
  connect_bd_net -net larpix_uart_channel_7_slice_Dout [get_bd_pins larpix_uart_channel_7/UART_RX] [get_bd_pins larpix_uart_channel_7_slice/Dout]
  connect_bd_net -net larpix_uart_channel_8_UART_RX_BUSY [get_bd_pins larpix_uart_channel_8/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In7]
  connect_bd_net -net larpix_uart_channel_8_UART_TX [get_bd_pins larpix_uart_channel_8/UART_TX] [get_bd_pins larpix_uart_channel_8_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_8_UART_TX_BUSY [get_bd_pins larpix_uart_channel_8/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In7]
  connect_bd_net -net larpix_uart_channel_8_en_slice_Dout [get_bd_pins larpix_uart_channel_8_en_slice/Dout] [get_bd_pins larpix_uart_channel_8_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_8_obuft_out_o [get_bd_pins larpix_uart_channel_8_obuft_out/o] [get_bd_pins mosi_merge/In7]
  connect_bd_net -net larpix_uart_channel_8_slice_Dout [get_bd_pins larpix_uart_channel_8/UART_RX] [get_bd_pins larpix_uart_channel_8_slice/Dout]
  connect_bd_net -net larpix_uart_channel_9_UART_RX_BUSY [get_bd_pins larpix_uart_channel_9/UART_RX_BUSY] [get_bd_pins or_uart_rx_busy/In8]
  connect_bd_net -net larpix_uart_channel_9_UART_TX [get_bd_pins larpix_uart_channel_9/UART_TX] [get_bd_pins larpix_uart_channel_9_obuft_out/i]
  connect_bd_net -net larpix_uart_channel_9_UART_TX_BUSY [get_bd_pins larpix_uart_channel_9/UART_TX_BUSY] [get_bd_pins or_uart_tx_busy/In8]
  connect_bd_net -net larpix_uart_channel_9_en_slice_Dout [get_bd_pins larpix_uart_channel_9_en_slice/Dout] [get_bd_pins larpix_uart_channel_9_obuft_out/en]
  connect_bd_net -net larpix_uart_channel_9_obuft_out_o [get_bd_pins larpix_uart_channel_9_obuft_out/o] [get_bd_pins mosi_merge/In8]
  connect_bd_net -net larpix_uart_channel_9_slice_Dout [get_bd_pins larpix_uart_channel_9/UART_RX] [get_bd_pins larpix_uart_channel_9_slice/Dout]
  connect_bd_net -net mosi_merge_dout [get_bd_pins MOSI] [get_bd_pins mosi_merge/dout]
  connect_bd_net -net or_uart_rx_busy_dout [get_bd_pins or_uart_rx_busy/dout] [get_bd_pins or_uart_rx_busy_logic/Op1]
  connect_bd_net -net or_uart_rx_busy_logic_Res [get_bd_pins UART_RX_BUSY] [get_bd_pins or_uart_rx_busy_logic/Res]
  connect_bd_net -net or_uart_tx_busy_dout [get_bd_pins or_uart_tx_busy/dout] [get_bd_pins or_uart_tx_busy_logic/Op1]
  connect_bd_net -net or_uart_tx_busy_logic_Res [get_bd_pins UART_TX_BUSY] [get_bd_pins or_uart_tx_busy_logic/Res]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: axis_merge
proc create_hier_cell_axis_merge { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_axis_merge() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M0_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M1_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M2_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M3_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M4_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M5_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M6_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M7_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S00_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S00_AXIS1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S00_AXIS2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S00_AXIS3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S00_AXIS4

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S00_AXIS5

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S00_AXIS6

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S00_AXIS7

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S01_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S01_AXIS1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S01_AXIS2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S01_AXIS3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S01_AXIS4

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S01_AXIS5

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S01_AXIS6

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S01_AXIS7

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S02_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S02_AXIS1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S02_AXIS2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S02_AXIS3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S02_AXIS4

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S02_AXIS5

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S02_AXIS6

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S02_AXIS7

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S03_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S03_AXIS1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S03_AXIS2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S03_AXIS3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S03_AXIS4

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S03_AXIS5

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S03_AXIS6

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S03_AXIS7


  # Create pins
  create_bd_pin -dir I -type clk ACLK
  create_bd_pin -dir I -type rst ARESETN

  # Create instance: axis_interconnect_0, and set properties
  set axis_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.ARB_ON_NUM_CYCLES {1} \
   CONFIG.ARB_ON_TLAST {1} \
   CONFIG.M00_FIFO_DEPTH {1024} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_FIFO_DEPTH {0} \
   CONFIG.S00_HAS_REGSLICE {0} \
   CONFIG.S01_FIFO_DEPTH {0} \
   CONFIG.S01_HAS_REGSLICE {0} \
   CONFIG.S02_FIFO_DEPTH {0} \
   CONFIG.S02_HAS_REGSLICE {0} \
   CONFIG.S03_FIFO_DEPTH {0} \
   CONFIG.S03_HAS_REGSLICE {0} \
 ] $axis_interconnect_0

  # Create instance: axis_interconnect_1, and set properties
  set axis_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_interconnect_1 ]
  set_property -dict [ list \
   CONFIG.ARB_ON_NUM_CYCLES {1} \
   CONFIG.ARB_ON_TLAST {1} \
   CONFIG.M00_FIFO_DEPTH {1024} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_FIFO_DEPTH {0} \
   CONFIG.S00_HAS_REGSLICE {0} \
   CONFIG.S01_FIFO_DEPTH {0} \
   CONFIG.S01_HAS_REGSLICE {0} \
   CONFIG.S02_FIFO_DEPTH {0} \
   CONFIG.S02_HAS_REGSLICE {0} \
   CONFIG.S03_FIFO_DEPTH {0} \
   CONFIG.S03_HAS_REGSLICE {0} \
 ] $axis_interconnect_1

  # Create instance: axis_interconnect_2, and set properties
  set axis_interconnect_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_interconnect_2 ]
  set_property -dict [ list \
   CONFIG.ARB_ON_NUM_CYCLES {1} \
   CONFIG.ARB_ON_TLAST {1} \
   CONFIG.M00_FIFO_DEPTH {1024} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_FIFO_DEPTH {0} \
   CONFIG.S00_HAS_REGSLICE {0} \
   CONFIG.S01_FIFO_DEPTH {0} \
   CONFIG.S01_HAS_REGSLICE {0} \
   CONFIG.S02_FIFO_DEPTH {0} \
   CONFIG.S02_HAS_REGSLICE {0} \
   CONFIG.S03_FIFO_DEPTH {0} \
   CONFIG.S03_HAS_REGSLICE {0} \
 ] $axis_interconnect_2

  # Create instance: axis_interconnect_3, and set properties
  set axis_interconnect_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_interconnect_3 ]
  set_property -dict [ list \
   CONFIG.ARB_ON_NUM_CYCLES {1} \
   CONFIG.ARB_ON_TLAST {1} \
   CONFIG.M00_FIFO_DEPTH {1024} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_FIFO_DEPTH {0} \
   CONFIG.S00_HAS_REGSLICE {0} \
   CONFIG.S01_FIFO_DEPTH {0} \
   CONFIG.S01_HAS_REGSLICE {0} \
   CONFIG.S02_FIFO_DEPTH {0} \
   CONFIG.S02_HAS_REGSLICE {0} \
   CONFIG.S03_FIFO_DEPTH {0} \
   CONFIG.S03_HAS_REGSLICE {0} \
 ] $axis_interconnect_3

  # Create instance: axis_interconnect_4, and set properties
  set axis_interconnect_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_interconnect_4 ]
  set_property -dict [ list \
   CONFIG.ARB_ON_NUM_CYCLES {1} \
   CONFIG.ARB_ON_TLAST {1} \
   CONFIG.M00_FIFO_DEPTH {1024} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_FIFO_DEPTH {0} \
   CONFIG.S00_HAS_REGSLICE {0} \
   CONFIG.S01_FIFO_DEPTH {0} \
   CONFIG.S01_HAS_REGSLICE {0} \
   CONFIG.S02_FIFO_DEPTH {0} \
   CONFIG.S02_HAS_REGSLICE {0} \
   CONFIG.S03_FIFO_DEPTH {0} \
   CONFIG.S03_HAS_REGSLICE {0} \
 ] $axis_interconnect_4

  # Create instance: axis_interconnect_5, and set properties
  set axis_interconnect_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_interconnect_5 ]
  set_property -dict [ list \
   CONFIG.ARB_ON_NUM_CYCLES {1} \
   CONFIG.ARB_ON_TLAST {1} \
   CONFIG.M00_FIFO_DEPTH {1024} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_FIFO_DEPTH {0} \
   CONFIG.S00_HAS_REGSLICE {0} \
   CONFIG.S01_FIFO_DEPTH {0} \
   CONFIG.S01_HAS_REGSLICE {0} \
   CONFIG.S02_FIFO_DEPTH {0} \
   CONFIG.S02_HAS_REGSLICE {0} \
   CONFIG.S03_FIFO_DEPTH {0} \
   CONFIG.S03_HAS_REGSLICE {0} \
 ] $axis_interconnect_5

  # Create instance: axis_interconnect_6, and set properties
  set axis_interconnect_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_interconnect_6 ]
  set_property -dict [ list \
   CONFIG.ARB_ON_NUM_CYCLES {1} \
   CONFIG.ARB_ON_TLAST {1} \
   CONFIG.M00_FIFO_DEPTH {1024} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_FIFO_DEPTH {0} \
   CONFIG.S00_HAS_REGSLICE {0} \
   CONFIG.S01_FIFO_DEPTH {0} \
   CONFIG.S01_HAS_REGSLICE {0} \
   CONFIG.S02_FIFO_DEPTH {0} \
   CONFIG.S02_HAS_REGSLICE {0} \
   CONFIG.S03_FIFO_DEPTH {0} \
   CONFIG.S03_HAS_REGSLICE {0} \
 ] $axis_interconnect_6

  # Create instance: axis_interconnect_7, and set properties
  set axis_interconnect_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_interconnect_7 ]
  set_property -dict [ list \
   CONFIG.ARB_ON_NUM_CYCLES {1} \
   CONFIG.ARB_ON_TLAST {1} \
   CONFIG.M00_FIFO_DEPTH {1024} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {4} \
   CONFIG.S00_FIFO_DEPTH {0} \
   CONFIG.S00_HAS_REGSLICE {0} \
   CONFIG.S01_FIFO_DEPTH {0} \
   CONFIG.S01_HAS_REGSLICE {0} \
   CONFIG.S02_FIFO_DEPTH {0} \
   CONFIG.S02_HAS_REGSLICE {0} \
   CONFIG.S03_FIFO_DEPTH {0} \
   CONFIG.S03_HAS_REGSLICE {0} \
 ] $axis_interconnect_7

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M0_AXIS] [get_bd_intf_pins axis_interconnect_0/M00_AXIS]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins M1_AXIS] [get_bd_intf_pins axis_interconnect_1/M00_AXIS]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins M2_AXIS] [get_bd_intf_pins axis_interconnect_2/M00_AXIS]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins M3_AXIS] [get_bd_intf_pins axis_interconnect_3/M00_AXIS]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins M4_AXIS] [get_bd_intf_pins axis_interconnect_4/M00_AXIS]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins M5_AXIS] [get_bd_intf_pins axis_interconnect_5/M00_AXIS]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins M6_AXIS] [get_bd_intf_pins axis_interconnect_6/M00_AXIS]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins M7_AXIS] [get_bd_intf_pins axis_interconnect_7/M00_AXIS]
  connect_bd_intf_net -intf_net S00_AXIS1_1 [get_bd_intf_pins S00_AXIS1] [get_bd_intf_pins axis_interconnect_1/S00_AXIS]
  connect_bd_intf_net -intf_net S00_AXIS2_1 [get_bd_intf_pins S00_AXIS2] [get_bd_intf_pins axis_interconnect_2/S00_AXIS]
  connect_bd_intf_net -intf_net S00_AXIS3_1 [get_bd_intf_pins S00_AXIS3] [get_bd_intf_pins axis_interconnect_3/S00_AXIS]
  connect_bd_intf_net -intf_net S00_AXIS4_1 [get_bd_intf_pins S00_AXIS4] [get_bd_intf_pins axis_interconnect_4/S00_AXIS]
  connect_bd_intf_net -intf_net S00_AXIS5_1 [get_bd_intf_pins S00_AXIS5] [get_bd_intf_pins axis_interconnect_5/S00_AXIS]
  connect_bd_intf_net -intf_net S00_AXIS6_1 [get_bd_intf_pins S00_AXIS6] [get_bd_intf_pins axis_interconnect_6/S00_AXIS]
  connect_bd_intf_net -intf_net S00_AXIS7_1 [get_bd_intf_pins S00_AXIS7] [get_bd_intf_pins axis_interconnect_7/S00_AXIS]
  connect_bd_intf_net -intf_net S00_AXIS_1 [get_bd_intf_pins S00_AXIS] [get_bd_intf_pins axis_interconnect_0/S00_AXIS]
  connect_bd_intf_net -intf_net S01_AXIS1_1 [get_bd_intf_pins S01_AXIS1] [get_bd_intf_pins axis_interconnect_1/S01_AXIS]
  connect_bd_intf_net -intf_net S01_AXIS2_1 [get_bd_intf_pins S01_AXIS2] [get_bd_intf_pins axis_interconnect_2/S01_AXIS]
  connect_bd_intf_net -intf_net S01_AXIS3_1 [get_bd_intf_pins S01_AXIS3] [get_bd_intf_pins axis_interconnect_3/S01_AXIS]
  connect_bd_intf_net -intf_net S01_AXIS4_1 [get_bd_intf_pins S01_AXIS4] [get_bd_intf_pins axis_interconnect_4/S01_AXIS]
  connect_bd_intf_net -intf_net S01_AXIS5_1 [get_bd_intf_pins S01_AXIS5] [get_bd_intf_pins axis_interconnect_5/S01_AXIS]
  connect_bd_intf_net -intf_net S01_AXIS6_1 [get_bd_intf_pins S01_AXIS6] [get_bd_intf_pins axis_interconnect_6/S01_AXIS]
  connect_bd_intf_net -intf_net S01_AXIS7_1 [get_bd_intf_pins S01_AXIS7] [get_bd_intf_pins axis_interconnect_7/S01_AXIS]
  connect_bd_intf_net -intf_net S01_AXIS_1 [get_bd_intf_pins S01_AXIS] [get_bd_intf_pins axis_interconnect_0/S01_AXIS]
  connect_bd_intf_net -intf_net S02_AXIS1_1 [get_bd_intf_pins S02_AXIS1] [get_bd_intf_pins axis_interconnect_1/S02_AXIS]
  connect_bd_intf_net -intf_net S02_AXIS2_1 [get_bd_intf_pins S02_AXIS2] [get_bd_intf_pins axis_interconnect_2/S02_AXIS]
  connect_bd_intf_net -intf_net S02_AXIS3_1 [get_bd_intf_pins S02_AXIS3] [get_bd_intf_pins axis_interconnect_3/S02_AXIS]
  connect_bd_intf_net -intf_net S02_AXIS4_1 [get_bd_intf_pins S02_AXIS4] [get_bd_intf_pins axis_interconnect_4/S02_AXIS]
  connect_bd_intf_net -intf_net S02_AXIS5_1 [get_bd_intf_pins S02_AXIS5] [get_bd_intf_pins axis_interconnect_5/S02_AXIS]
  connect_bd_intf_net -intf_net S02_AXIS6_1 [get_bd_intf_pins S02_AXIS6] [get_bd_intf_pins axis_interconnect_6/S02_AXIS]
  connect_bd_intf_net -intf_net S02_AXIS7_1 [get_bd_intf_pins S02_AXIS7] [get_bd_intf_pins axis_interconnect_7/S02_AXIS]
  connect_bd_intf_net -intf_net S02_AXIS_1 [get_bd_intf_pins S02_AXIS] [get_bd_intf_pins axis_interconnect_0/S02_AXIS]
  connect_bd_intf_net -intf_net S03_AXIS1_1 [get_bd_intf_pins S03_AXIS1] [get_bd_intf_pins axis_interconnect_1/S03_AXIS]
  connect_bd_intf_net -intf_net S03_AXIS2_1 [get_bd_intf_pins S03_AXIS2] [get_bd_intf_pins axis_interconnect_2/S03_AXIS]
  connect_bd_intf_net -intf_net S03_AXIS3_1 [get_bd_intf_pins S03_AXIS3] [get_bd_intf_pins axis_interconnect_3/S03_AXIS]
  connect_bd_intf_net -intf_net S03_AXIS4_1 [get_bd_intf_pins S03_AXIS4] [get_bd_intf_pins axis_interconnect_4/S03_AXIS]
  connect_bd_intf_net -intf_net S03_AXIS5_1 [get_bd_intf_pins S03_AXIS5] [get_bd_intf_pins axis_interconnect_5/S03_AXIS]
  connect_bd_intf_net -intf_net S03_AXIS6_1 [get_bd_intf_pins S03_AXIS6] [get_bd_intf_pins axis_interconnect_6/S03_AXIS]
  connect_bd_intf_net -intf_net S03_AXIS7_1 [get_bd_intf_pins S03_AXIS7] [get_bd_intf_pins axis_interconnect_7/S03_AXIS]
  connect_bd_intf_net -intf_net S03_AXIS_1 [get_bd_intf_pins S03_AXIS] [get_bd_intf_pins axis_interconnect_0/S03_AXIS]

  # Create port connections
  connect_bd_net -net ACLK_1 [get_bd_pins ACLK] [get_bd_pins axis_interconnect_0/ACLK] [get_bd_pins axis_interconnect_0/M00_AXIS_ACLK] [get_bd_pins axis_interconnect_0/S00_AXIS_ACLK] [get_bd_pins axis_interconnect_0/S01_AXIS_ACLK] [get_bd_pins axis_interconnect_0/S02_AXIS_ACLK] [get_bd_pins axis_interconnect_0/S03_AXIS_ACLK] [get_bd_pins axis_interconnect_1/ACLK] [get_bd_pins axis_interconnect_1/M00_AXIS_ACLK] [get_bd_pins axis_interconnect_1/S00_AXIS_ACLK] [get_bd_pins axis_interconnect_1/S01_AXIS_ACLK] [get_bd_pins axis_interconnect_1/S02_AXIS_ACLK] [get_bd_pins axis_interconnect_1/S03_AXIS_ACLK] [get_bd_pins axis_interconnect_2/ACLK] [get_bd_pins axis_interconnect_2/M00_AXIS_ACLK] [get_bd_pins axis_interconnect_2/S00_AXIS_ACLK] [get_bd_pins axis_interconnect_2/S01_AXIS_ACLK] [get_bd_pins axis_interconnect_2/S02_AXIS_ACLK] [get_bd_pins axis_interconnect_2/S03_AXIS_ACLK] [get_bd_pins axis_interconnect_3/ACLK] [get_bd_pins axis_interconnect_3/M00_AXIS_ACLK] [get_bd_pins axis_interconnect_3/S00_AXIS_ACLK] [get_bd_pins axis_interconnect_3/S01_AXIS_ACLK] [get_bd_pins axis_interconnect_3/S02_AXIS_ACLK] [get_bd_pins axis_interconnect_3/S03_AXIS_ACLK] [get_bd_pins axis_interconnect_4/ACLK] [get_bd_pins axis_interconnect_4/M00_AXIS_ACLK] [get_bd_pins axis_interconnect_4/S00_AXIS_ACLK] [get_bd_pins axis_interconnect_4/S01_AXIS_ACLK] [get_bd_pins axis_interconnect_4/S02_AXIS_ACLK] [get_bd_pins axis_interconnect_4/S03_AXIS_ACLK] [get_bd_pins axis_interconnect_5/ACLK] [get_bd_pins axis_interconnect_5/M00_AXIS_ACLK] [get_bd_pins axis_interconnect_5/S00_AXIS_ACLK] [get_bd_pins axis_interconnect_5/S01_AXIS_ACLK] [get_bd_pins axis_interconnect_5/S02_AXIS_ACLK] [get_bd_pins axis_interconnect_5/S03_AXIS_ACLK] [get_bd_pins axis_interconnect_6/ACLK] [get_bd_pins axis_interconnect_6/M00_AXIS_ACLK] [get_bd_pins axis_interconnect_6/S00_AXIS_ACLK] [get_bd_pins axis_interconnect_6/S01_AXIS_ACLK] [get_bd_pins axis_interconnect_6/S02_AXIS_ACLK] [get_bd_pins axis_interconnect_6/S03_AXIS_ACLK] [get_bd_pins axis_interconnect_7/ACLK] [get_bd_pins axis_interconnect_7/M00_AXIS_ACLK] [get_bd_pins axis_interconnect_7/S00_AXIS_ACLK] [get_bd_pins axis_interconnect_7/S01_AXIS_ACLK] [get_bd_pins axis_interconnect_7/S02_AXIS_ACLK] [get_bd_pins axis_interconnect_7/S03_AXIS_ACLK]
  connect_bd_net -net ARESETN_1 [get_bd_pins ARESETN] [get_bd_pins axis_interconnect_0/ARESETN] [get_bd_pins axis_interconnect_0/M00_AXIS_ARESETN] [get_bd_pins axis_interconnect_0/S00_AXIS_ARESETN] [get_bd_pins axis_interconnect_0/S01_AXIS_ARESETN] [get_bd_pins axis_interconnect_0/S02_AXIS_ARESETN] [get_bd_pins axis_interconnect_0/S03_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/ARESETN] [get_bd_pins axis_interconnect_1/M00_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/S00_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/S01_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/S02_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/S03_AXIS_ARESETN] [get_bd_pins axis_interconnect_2/ARESETN] [get_bd_pins axis_interconnect_2/M00_AXIS_ARESETN] [get_bd_pins axis_interconnect_2/S00_AXIS_ARESETN] [get_bd_pins axis_interconnect_2/S01_AXIS_ARESETN] [get_bd_pins axis_interconnect_2/S02_AXIS_ARESETN] [get_bd_pins axis_interconnect_2/S03_AXIS_ARESETN] [get_bd_pins axis_interconnect_3/ARESETN] [get_bd_pins axis_interconnect_3/M00_AXIS_ARESETN] [get_bd_pins axis_interconnect_3/S00_AXIS_ARESETN] [get_bd_pins axis_interconnect_3/S01_AXIS_ARESETN] [get_bd_pins axis_interconnect_3/S02_AXIS_ARESETN] [get_bd_pins axis_interconnect_3/S03_AXIS_ARESETN] [get_bd_pins axis_interconnect_4/ARESETN] [get_bd_pins axis_interconnect_4/M00_AXIS_ARESETN] [get_bd_pins axis_interconnect_4/S00_AXIS_ARESETN] [get_bd_pins axis_interconnect_4/S01_AXIS_ARESETN] [get_bd_pins axis_interconnect_4/S02_AXIS_ARESETN] [get_bd_pins axis_interconnect_4/S03_AXIS_ARESETN] [get_bd_pins axis_interconnect_5/ARESETN] [get_bd_pins axis_interconnect_5/M00_AXIS_ARESETN] [get_bd_pins axis_interconnect_5/S00_AXIS_ARESETN] [get_bd_pins axis_interconnect_5/S01_AXIS_ARESETN] [get_bd_pins axis_interconnect_5/S02_AXIS_ARESETN] [get_bd_pins axis_interconnect_5/S03_AXIS_ARESETN] [get_bd_pins axis_interconnect_6/ARESETN] [get_bd_pins axis_interconnect_6/M00_AXIS_ARESETN] [get_bd_pins axis_interconnect_6/S00_AXIS_ARESETN] [get_bd_pins axis_interconnect_6/S01_AXIS_ARESETN] [get_bd_pins axis_interconnect_6/S02_AXIS_ARESETN] [get_bd_pins axis_interconnect_6/S03_AXIS_ARESETN] [get_bd_pins axis_interconnect_7/ARESETN] [get_bd_pins axis_interconnect_7/M00_AXIS_ARESETN] [get_bd_pins axis_interconnect_7/S00_AXIS_ARESETN] [get_bd_pins axis_interconnect_7/S01_AXIS_ARESETN] [get_bd_pins axis_interconnect_7/S02_AXIS_ARESETN] [get_bd_pins axis_interconnect_7/S03_AXIS_ARESETN]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: axis_broadcast
proc create_hier_cell_axis_broadcast { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_axis_broadcast() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS2

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS3

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS4

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS5

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS6

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS7

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS2

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS3

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS4

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS5

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS6

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS7

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M02_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M02_AXIS1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M02_AXIS2

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M02_AXIS3

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M02_AXIS4

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M02_AXIS5

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M02_AXIS6

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M02_AXIS7

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M03_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M03_AXIS1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M03_AXIS2

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M03_AXIS3

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M03_AXIS4

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M03_AXIS5

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M03_AXIS6

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M03_AXIS7

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S0_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S1_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S2_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S3_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S4_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S5_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S6_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S7_AXIS


  # Create pins
  create_bd_pin -dir I -type clk ACLK
  create_bd_pin -dir I -type rst ARESETN

  # Create instance: axis_broadcaster_0, and set properties
  set axis_broadcaster_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {1} \
   CONFIG.M00_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M02_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M03_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M_TDATA_NUM_BYTES {16} \
   CONFIG.NUM_MI {4} \
   CONFIG.S_TDATA_NUM_BYTES {16} \
 ] $axis_broadcaster_0

  # Create instance: axis_broadcaster_1, and set properties
  set axis_broadcaster_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_1 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {1} \
   CONFIG.M00_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M02_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M03_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M_TDATA_NUM_BYTES {16} \
   CONFIG.NUM_MI {4} \
   CONFIG.S_TDATA_NUM_BYTES {16} \
 ] $axis_broadcaster_1

  # Create instance: axis_broadcaster_2, and set properties
  set axis_broadcaster_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_2 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {1} \
   CONFIG.M00_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M02_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M03_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M_TDATA_NUM_BYTES {16} \
   CONFIG.NUM_MI {4} \
   CONFIG.S_TDATA_NUM_BYTES {16} \
 ] $axis_broadcaster_2

  # Create instance: axis_broadcaster_3, and set properties
  set axis_broadcaster_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_3 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {1} \
   CONFIG.M00_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M02_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M03_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M_TDATA_NUM_BYTES {16} \
   CONFIG.NUM_MI {4} \
   CONFIG.S_TDATA_NUM_BYTES {16} \
 ] $axis_broadcaster_3

  # Create instance: axis_broadcaster_4, and set properties
  set axis_broadcaster_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_4 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {1} \
   CONFIG.M00_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M02_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M03_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M_TDATA_NUM_BYTES {16} \
   CONFIG.NUM_MI {4} \
   CONFIG.S_TDATA_NUM_BYTES {16} \
 ] $axis_broadcaster_4

  # Create instance: axis_broadcaster_5, and set properties
  set axis_broadcaster_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_5 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {1} \
   CONFIG.M00_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M02_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M03_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M_TDATA_NUM_BYTES {16} \
   CONFIG.NUM_MI {4} \
   CONFIG.S_TDATA_NUM_BYTES {16} \
 ] $axis_broadcaster_5

  # Create instance: axis_broadcaster_6, and set properties
  set axis_broadcaster_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_6 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {1} \
   CONFIG.M00_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M02_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M03_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M_TDATA_NUM_BYTES {16} \
   CONFIG.NUM_MI {4} \
   CONFIG.S_TDATA_NUM_BYTES {16} \
 ] $axis_broadcaster_6

  # Create instance: axis_broadcaster_7, and set properties
  set axis_broadcaster_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_7 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {1} \
   CONFIG.M00_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M02_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M03_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M_TDATA_NUM_BYTES {16} \
   CONFIG.NUM_MI {4} \
   CONFIG.S_TDATA_NUM_BYTES {16} \
 ] $axis_broadcaster_7

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S0_AXIS] [get_bd_intf_pins axis_broadcaster_0/S_AXIS]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S1_AXIS] [get_bd_intf_pins axis_broadcaster_1/S_AXIS]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins S2_AXIS] [get_bd_intf_pins axis_broadcaster_2/S_AXIS]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins S3_AXIS] [get_bd_intf_pins axis_broadcaster_3/S_AXIS]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins S4_AXIS] [get_bd_intf_pins axis_broadcaster_4/S_AXIS]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins S5_AXIS] [get_bd_intf_pins axis_broadcaster_5/S_AXIS]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins S6_AXIS] [get_bd_intf_pins axis_broadcaster_6/S_AXIS]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins S7_AXIS] [get_bd_intf_pins axis_broadcaster_7/S_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M00_AXIS [get_bd_intf_pins M00_AXIS] [get_bd_intf_pins axis_broadcaster_0/M00_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M01_AXIS [get_bd_intf_pins M01_AXIS] [get_bd_intf_pins axis_broadcaster_0/M01_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M02_AXIS [get_bd_intf_pins M02_AXIS] [get_bd_intf_pins axis_broadcaster_0/M02_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M03_AXIS [get_bd_intf_pins M03_AXIS] [get_bd_intf_pins axis_broadcaster_0/M03_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M00_AXIS [get_bd_intf_pins M00_AXIS1] [get_bd_intf_pins axis_broadcaster_1/M00_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M01_AXIS [get_bd_intf_pins M01_AXIS1] [get_bd_intf_pins axis_broadcaster_1/M01_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M02_AXIS [get_bd_intf_pins M02_AXIS1] [get_bd_intf_pins axis_broadcaster_1/M02_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_1_M03_AXIS [get_bd_intf_pins M03_AXIS1] [get_bd_intf_pins axis_broadcaster_1/M03_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_2_M00_AXIS [get_bd_intf_pins M00_AXIS2] [get_bd_intf_pins axis_broadcaster_2/M00_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_2_M01_AXIS [get_bd_intf_pins M01_AXIS2] [get_bd_intf_pins axis_broadcaster_2/M01_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_2_M02_AXIS [get_bd_intf_pins M02_AXIS2] [get_bd_intf_pins axis_broadcaster_2/M02_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_2_M03_AXIS [get_bd_intf_pins M03_AXIS2] [get_bd_intf_pins axis_broadcaster_2/M03_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_3_M00_AXIS [get_bd_intf_pins M00_AXIS3] [get_bd_intf_pins axis_broadcaster_3/M00_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_3_M01_AXIS [get_bd_intf_pins M01_AXIS3] [get_bd_intf_pins axis_broadcaster_3/M01_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_3_M02_AXIS [get_bd_intf_pins M02_AXIS3] [get_bd_intf_pins axis_broadcaster_3/M02_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_3_M03_AXIS [get_bd_intf_pins M03_AXIS3] [get_bd_intf_pins axis_broadcaster_3/M03_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_4_M00_AXIS [get_bd_intf_pins M00_AXIS4] [get_bd_intf_pins axis_broadcaster_4/M00_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_4_M01_AXIS [get_bd_intf_pins M01_AXIS4] [get_bd_intf_pins axis_broadcaster_4/M01_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_4_M02_AXIS [get_bd_intf_pins M02_AXIS4] [get_bd_intf_pins axis_broadcaster_4/M02_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_4_M03_AXIS [get_bd_intf_pins M03_AXIS4] [get_bd_intf_pins axis_broadcaster_4/M03_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_5_M00_AXIS [get_bd_intf_pins M00_AXIS5] [get_bd_intf_pins axis_broadcaster_5/M00_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_5_M01_AXIS [get_bd_intf_pins M01_AXIS5] [get_bd_intf_pins axis_broadcaster_5/M01_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_5_M02_AXIS [get_bd_intf_pins M02_AXIS5] [get_bd_intf_pins axis_broadcaster_5/M02_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_5_M03_AXIS [get_bd_intf_pins M03_AXIS5] [get_bd_intf_pins axis_broadcaster_5/M03_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_6_M00_AXIS [get_bd_intf_pins M00_AXIS6] [get_bd_intf_pins axis_broadcaster_6/M00_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_6_M01_AXIS [get_bd_intf_pins M01_AXIS6] [get_bd_intf_pins axis_broadcaster_6/M01_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_6_M02_AXIS [get_bd_intf_pins M02_AXIS6] [get_bd_intf_pins axis_broadcaster_6/M02_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_6_M03_AXIS [get_bd_intf_pins M03_AXIS6] [get_bd_intf_pins axis_broadcaster_6/M03_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_7_M00_AXIS [get_bd_intf_pins M00_AXIS7] [get_bd_intf_pins axis_broadcaster_7/M00_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_7_M01_AXIS [get_bd_intf_pins M01_AXIS7] [get_bd_intf_pins axis_broadcaster_7/M01_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_7_M02_AXIS [get_bd_intf_pins M02_AXIS7] [get_bd_intf_pins axis_broadcaster_7/M02_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_7_M03_AXIS [get_bd_intf_pins M03_AXIS7] [get_bd_intf_pins axis_broadcaster_7/M03_AXIS]

  # Create port connections
  connect_bd_net -net ACLK_1 [get_bd_pins ACLK] [get_bd_pins axis_broadcaster_0/aclk] [get_bd_pins axis_broadcaster_1/aclk] [get_bd_pins axis_broadcaster_2/aclk] [get_bd_pins axis_broadcaster_3/aclk] [get_bd_pins axis_broadcaster_4/aclk] [get_bd_pins axis_broadcaster_5/aclk] [get_bd_pins axis_broadcaster_6/aclk] [get_bd_pins axis_broadcaster_7/aclk]
  connect_bd_net -net ARESETN_1 [get_bd_pins ARESETN] [get_bd_pins axis_broadcaster_0/aresetn] [get_bd_pins axis_broadcaster_1/aresetn] [get_bd_pins axis_broadcaster_2/aresetn] [get_bd_pins axis_broadcaster_3/aresetn] [get_bd_pins axis_broadcaster_4/aresetn] [get_bd_pins axis_broadcaster_5/aresetn] [get_bd_pins axis_broadcaster_6/aresetn] [get_bd_pins axis_broadcaster_7/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: aximm
proc create_hier_cell_aximm { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_aximm() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M01_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M02_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M03_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M04_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M05_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M06_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M07_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M08_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M09_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M10_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M11_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M12_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M13_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M14_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M15_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M16_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M17_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M18_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M19_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M20_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M21_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M22_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M23_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M24_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M25_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M26_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M27_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M28_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M29_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M30_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M31_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXIMM


  # Create pins
  create_bd_pin -dir I -type clk ACLK
  create_bd_pin -dir I -type rst ARESETN

  # Create instance: aximm_interconnect_0, and set properties
  set aximm_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 aximm_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.M01_HAS_REGSLICE {1} \
   CONFIG.M02_HAS_REGSLICE {1} \
   CONFIG.M03_HAS_REGSLICE {1} \
   CONFIG.M04_HAS_REGSLICE {1} \
   CONFIG.M05_HAS_REGSLICE {1} \
   CONFIG.M06_HAS_REGSLICE {1} \
   CONFIG.M07_HAS_REGSLICE {1} \
   CONFIG.M08_HAS_REGSLICE {1} \
   CONFIG.M09_HAS_REGSLICE {1} \
   CONFIG.M10_HAS_REGSLICE {1} \
   CONFIG.M11_HAS_REGSLICE {1} \
   CONFIG.M12_HAS_REGSLICE {1} \
   CONFIG.M13_HAS_REGSLICE {1} \
   CONFIG.M14_HAS_REGSLICE {1} \
   CONFIG.M15_HAS_REGSLICE {1} \
   CONFIG.M16_HAS_REGSLICE {1} \
   CONFIG.M17_HAS_REGSLICE {1} \
   CONFIG.M18_HAS_REGSLICE {1} \
   CONFIG.M19_HAS_REGSLICE {1} \
   CONFIG.M20_HAS_REGSLICE {1} \
   CONFIG.M21_HAS_REGSLICE {1} \
   CONFIG.M22_HAS_REGSLICE {1} \
   CONFIG.M23_HAS_REGSLICE {1} \
   CONFIG.M24_HAS_REGSLICE {1} \
   CONFIG.M25_HAS_REGSLICE {1} \
   CONFIG.M26_HAS_REGSLICE {1} \
   CONFIG.M27_HAS_REGSLICE {1} \
   CONFIG.M28_HAS_REGSLICE {1} \
   CONFIG.M29_HAS_REGSLICE {1} \
   CONFIG.M30_HAS_REGSLICE {1} \
   CONFIG.M31_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {32} \
   CONFIG.S00_HAS_DATA_FIFO {0} \
   CONFIG.S00_HAS_REGSLICE {0} \
   CONFIG.STRATEGY {1} \
 ] $aximm_interconnect_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXIMM] [get_bd_intf_pins aximm_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M00_AXI [get_bd_intf_pins M00_AXI] [get_bd_intf_pins aximm_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M01_AXI [get_bd_intf_pins M01_AXI] [get_bd_intf_pins aximm_interconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M02_AXI [get_bd_intf_pins M02_AXI] [get_bd_intf_pins aximm_interconnect_0/M02_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M03_AXI [get_bd_intf_pins M03_AXI] [get_bd_intf_pins aximm_interconnect_0/M03_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M04_AXI [get_bd_intf_pins M04_AXI] [get_bd_intf_pins aximm_interconnect_0/M04_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M05_AXI [get_bd_intf_pins M05_AXI] [get_bd_intf_pins aximm_interconnect_0/M05_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M06_AXI [get_bd_intf_pins M06_AXI] [get_bd_intf_pins aximm_interconnect_0/M06_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M07_AXI [get_bd_intf_pins M07_AXI] [get_bd_intf_pins aximm_interconnect_0/M07_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M08_AXI [get_bd_intf_pins M08_AXI] [get_bd_intf_pins aximm_interconnect_0/M08_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M09_AXI [get_bd_intf_pins M09_AXI] [get_bd_intf_pins aximm_interconnect_0/M09_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M10_AXI [get_bd_intf_pins M10_AXI] [get_bd_intf_pins aximm_interconnect_0/M10_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M11_AXI [get_bd_intf_pins M11_AXI] [get_bd_intf_pins aximm_interconnect_0/M11_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M12_AXI [get_bd_intf_pins M12_AXI] [get_bd_intf_pins aximm_interconnect_0/M12_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M13_AXI [get_bd_intf_pins M13_AXI] [get_bd_intf_pins aximm_interconnect_0/M13_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M14_AXI [get_bd_intf_pins M14_AXI] [get_bd_intf_pins aximm_interconnect_0/M14_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M15_AXI [get_bd_intf_pins M15_AXI] [get_bd_intf_pins aximm_interconnect_0/M15_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M16_AXI [get_bd_intf_pins M16_AXI] [get_bd_intf_pins aximm_interconnect_0/M16_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M17_AXI [get_bd_intf_pins M17_AXI] [get_bd_intf_pins aximm_interconnect_0/M17_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M18_AXI [get_bd_intf_pins M18_AXI] [get_bd_intf_pins aximm_interconnect_0/M18_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M19_AXI [get_bd_intf_pins M19_AXI] [get_bd_intf_pins aximm_interconnect_0/M19_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M20_AXI [get_bd_intf_pins M20_AXI] [get_bd_intf_pins aximm_interconnect_0/M20_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M21_AXI [get_bd_intf_pins M21_AXI] [get_bd_intf_pins aximm_interconnect_0/M21_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M22_AXI [get_bd_intf_pins M22_AXI] [get_bd_intf_pins aximm_interconnect_0/M22_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M23_AXI [get_bd_intf_pins M23_AXI] [get_bd_intf_pins aximm_interconnect_0/M23_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M24_AXI [get_bd_intf_pins M24_AXI] [get_bd_intf_pins aximm_interconnect_0/M24_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M25_AXI [get_bd_intf_pins M25_AXI] [get_bd_intf_pins aximm_interconnect_0/M25_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M26_AXI [get_bd_intf_pins M26_AXI] [get_bd_intf_pins aximm_interconnect_0/M26_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M27_AXI [get_bd_intf_pins M27_AXI] [get_bd_intf_pins aximm_interconnect_0/M27_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M28_AXI [get_bd_intf_pins M28_AXI] [get_bd_intf_pins aximm_interconnect_0/M28_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M29_AXI [get_bd_intf_pins M29_AXI] [get_bd_intf_pins aximm_interconnect_0/M29_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M30_AXI [get_bd_intf_pins M30_AXI] [get_bd_intf_pins aximm_interconnect_0/M30_AXI]
  connect_bd_intf_net -intf_net aximm_interconnect_0_M31_AXI [get_bd_intf_pins M31_AXI] [get_bd_intf_pins aximm_interconnect_0/M31_AXI]

  # Create port connections
  connect_bd_net -net ACLK_1 [get_bd_pins ACLK] [get_bd_pins aximm_interconnect_0/ACLK] [get_bd_pins aximm_interconnect_0/M00_ACLK] [get_bd_pins aximm_interconnect_0/M01_ACLK] [get_bd_pins aximm_interconnect_0/M02_ACLK] [get_bd_pins aximm_interconnect_0/M03_ACLK] [get_bd_pins aximm_interconnect_0/M04_ACLK] [get_bd_pins aximm_interconnect_0/M05_ACLK] [get_bd_pins aximm_interconnect_0/M06_ACLK] [get_bd_pins aximm_interconnect_0/M07_ACLK] [get_bd_pins aximm_interconnect_0/M08_ACLK] [get_bd_pins aximm_interconnect_0/M09_ACLK] [get_bd_pins aximm_interconnect_0/M10_ACLK] [get_bd_pins aximm_interconnect_0/M11_ACLK] [get_bd_pins aximm_interconnect_0/M12_ACLK] [get_bd_pins aximm_interconnect_0/M13_ACLK] [get_bd_pins aximm_interconnect_0/M14_ACLK] [get_bd_pins aximm_interconnect_0/M15_ACLK] [get_bd_pins aximm_interconnect_0/M16_ACLK] [get_bd_pins aximm_interconnect_0/M17_ACLK] [get_bd_pins aximm_interconnect_0/M18_ACLK] [get_bd_pins aximm_interconnect_0/M19_ACLK] [get_bd_pins aximm_interconnect_0/M20_ACLK] [get_bd_pins aximm_interconnect_0/M21_ACLK] [get_bd_pins aximm_interconnect_0/M22_ACLK] [get_bd_pins aximm_interconnect_0/M23_ACLK] [get_bd_pins aximm_interconnect_0/M24_ACLK] [get_bd_pins aximm_interconnect_0/M25_ACLK] [get_bd_pins aximm_interconnect_0/M26_ACLK] [get_bd_pins aximm_interconnect_0/M27_ACLK] [get_bd_pins aximm_interconnect_0/M28_ACLK] [get_bd_pins aximm_interconnect_0/M29_ACLK] [get_bd_pins aximm_interconnect_0/M30_ACLK] [get_bd_pins aximm_interconnect_0/M31_ACLK] [get_bd_pins aximm_interconnect_0/S00_ACLK]
  connect_bd_net -net ARESETN_1 [get_bd_pins ARESETN] [get_bd_pins aximm_interconnect_0/ARESETN] [get_bd_pins aximm_interconnect_0/M00_ARESETN] [get_bd_pins aximm_interconnect_0/M01_ARESETN] [get_bd_pins aximm_interconnect_0/M02_ARESETN] [get_bd_pins aximm_interconnect_0/M03_ARESETN] [get_bd_pins aximm_interconnect_0/M04_ARESETN] [get_bd_pins aximm_interconnect_0/M05_ARESETN] [get_bd_pins aximm_interconnect_0/M06_ARESETN] [get_bd_pins aximm_interconnect_0/M07_ARESETN] [get_bd_pins aximm_interconnect_0/M08_ARESETN] [get_bd_pins aximm_interconnect_0/M09_ARESETN] [get_bd_pins aximm_interconnect_0/M10_ARESETN] [get_bd_pins aximm_interconnect_0/M11_ARESETN] [get_bd_pins aximm_interconnect_0/M12_ARESETN] [get_bd_pins aximm_interconnect_0/M13_ARESETN] [get_bd_pins aximm_interconnect_0/M14_ARESETN] [get_bd_pins aximm_interconnect_0/M15_ARESETN] [get_bd_pins aximm_interconnect_0/M16_ARESETN] [get_bd_pins aximm_interconnect_0/M17_ARESETN] [get_bd_pins aximm_interconnect_0/M18_ARESETN] [get_bd_pins aximm_interconnect_0/M19_ARESETN] [get_bd_pins aximm_interconnect_0/M20_ARESETN] [get_bd_pins aximm_interconnect_0/M21_ARESETN] [get_bd_pins aximm_interconnect_0/M22_ARESETN] [get_bd_pins aximm_interconnect_0/M23_ARESETN] [get_bd_pins aximm_interconnect_0/M24_ARESETN] [get_bd_pins aximm_interconnect_0/M25_ARESETN] [get_bd_pins aximm_interconnect_0/M26_ARESETN] [get_bd_pins aximm_interconnect_0/M27_ARESETN] [get_bd_pins aximm_interconnect_0/M28_ARESETN] [get_bd_pins aximm_interconnect_0/M29_ARESETN] [get_bd_pins aximm_interconnect_0/M30_ARESETN] [get_bd_pins aximm_interconnect_0/M31_ARESETN] [get_bd_pins aximm_interconnect_0/S00_ARESETN]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: axi_lite_reg_space
proc create_hier_cell_axi_lite_reg_space_2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_axi_lite_reg_space_2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I S_AXI_LITE_ACLK
  create_bd_pin -dir I S_AXI_LITE_ARESETN
  create_bd_pin -dir O -from 31 -to 0 periodic_trig_cycles
  create_bd_pin -dir O -from 0 -to 0 periodic_trig_en
  create_bd_pin -dir O -from 7 -to 0 trig0_mask
  create_bd_pin -dir O -from 7 -to 0 trig1_mask
  create_bd_pin -dir O -from 7 -to 0 trig2_mask
  create_bd_pin -dir O -from 7 -to 0 trig3_mask
  create_bd_pin -dir O -from 7 -to 0 trig_len

  # Create instance: axi_lite_reg_space_0, and set properties
  set block_name axi_lite_reg_space
  set block_cell_name axi_lite_reg_space_0
  if { [catch {set axi_lite_reg_space_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axi_lite_reg_space_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_RW_REG0_DEFAULT {0x00000004} \
   CONFIG.C_RW_REG2_DEFAULT {0x00989680} \
 ] $axi_lite_reg_space_0

  # Create instance: periodic_trig_en, and set properties
  set periodic_trig_en [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 periodic_trig_en ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DOUT_WIDTH {1} \
 ] $periodic_trig_en

  # Create instance: trig0_mask, and set properties
  set trig0_mask [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 trig0_mask ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {7} \
   CONFIG.DOUT_WIDTH {8} \
 ] $trig0_mask

  # Create instance: trig1_mask, and set properties
  set trig1_mask [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 trig1_mask ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {15} \
   CONFIG.DIN_TO {8} \
   CONFIG.DOUT_WIDTH {8} \
 ] $trig1_mask

  # Create instance: trig2_mask, and set properties
  set trig2_mask [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 trig2_mask ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {23} \
   CONFIG.DIN_TO {16} \
   CONFIG.DOUT_WIDTH {8} \
 ] $trig2_mask

  # Create instance: trig3_mask, and set properties
  set trig3_mask [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 trig3_mask ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {31} \
   CONFIG.DIN_TO {24} \
   CONFIG.DOUT_WIDTH {8} \
 ] $trig3_mask

  # Create instance: trig_len, and set properties
  set trig_len [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 trig_len ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {8} \
   CONFIG.DIN_TO {1} \
   CONFIG.DOUT_WIDTH {8} \
 ] $trig_len

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {32} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_LITE_1 [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_lite_reg_space_0/S_AXI_LITE]

  # Create port connections
  connect_bd_net -net S_AXI_LITE_ACLK_1 [get_bd_pins S_AXI_LITE_ACLK] [get_bd_pins axi_lite_reg_space_0/S_AXI_LITE_ACLK]
  connect_bd_net -net S_AXI_LITE_ARESETN_1 [get_bd_pins S_AXI_LITE_ARESETN] [get_bd_pins axi_lite_reg_space_0/S_AXI_LITE_ARESETN]
  connect_bd_net -net axi_lite_reg_space_0_RW_REG0 [get_bd_pins axi_lite_reg_space_0/RW_REG0] [get_bd_pins periodic_trig_en/Din] [get_bd_pins trig_len/Din]
  connect_bd_net -net axi_lite_reg_space_0_RW_REG1 [get_bd_pins axi_lite_reg_space_0/RW_REG1] [get_bd_pins trig0_mask/Din] [get_bd_pins trig1_mask/Din] [get_bd_pins trig2_mask/Din] [get_bd_pins trig3_mask/Din]
  connect_bd_net -net axi_lite_reg_space_0_RW_REG2 [get_bd_pins periodic_trig_cycles] [get_bd_pins axi_lite_reg_space_0/RW_REG2]
  connect_bd_net -net periodic_trig_en_Dout [get_bd_pins periodic_trig_en] [get_bd_pins periodic_trig_en/Dout]
  connect_bd_net -net trig0_mask_Dout [get_bd_pins trig0_mask] [get_bd_pins trig0_mask/Dout]
  connect_bd_net -net trig1_mask_Dout [get_bd_pins trig1_mask] [get_bd_pins trig1_mask/Dout]
  connect_bd_net -net trig2_mask_Dout [get_bd_pins trig2_mask] [get_bd_pins trig2_mask/Dout]
  connect_bd_net -net trig3_mask_Dout [get_bd_pins trig3_mask] [get_bd_pins trig3_mask/Dout]
  connect_bd_net -net trig_len_Dout [get_bd_pins trig_len] [get_bd_pins trig_len/Dout]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins axi_lite_reg_space_0/RO_REG0] [get_bd_pins axi_lite_reg_space_0/RO_REG1] [get_bd_pins axi_lite_reg_space_0/RO_REG2] [get_bd_pins axi_lite_reg_space_0/RO_REG3] [get_bd_pins xlconstant_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: axi_lite_reg_space
proc create_hier_cell_axi_lite_reg_space_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_axi_lite_reg_space_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I ACLK
  create_bd_pin -dir I ARESETN
  create_bd_pin -dir O -from 0 -to 0 clk_sel
  create_bd_pin -dir I -from 0 -to 0 clk_sel_stat
  create_bd_pin -dir I -from 0 -to 0 clk_valid
  create_bd_pin -dir O -from 31 -to 0 hb_cycles
  create_bd_pin -dir O -from 0 -to 0 hb_en
  create_bd_pin -dir O -from 7 -to 0 mclk_div
  create_bd_pin -dir I -from 1 -to 0 pll_locked
  create_bd_pin -dir O -from 31 -to 0 sw_rst_cycles
  create_bd_pin -dir O -from 0 -to 0 sw_rst_trig
  create_bd_pin -dir I -from 31 -to 0 timestamp

  # Create instance: axi_lite_reg_space_0, and set properties
  set block_name axi_lite_reg_space
  set block_cell_name axi_lite_reg_space_0
  if { [catch {set axi_lite_reg_space_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axi_lite_reg_space_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_RW_REG0_DEFAULT {0x00000002} \
   CONFIG.C_RW_REG1_DEFAULT {0x00000100} \
   CONFIG.C_RW_REG2_DEFAULT {0x3B9ACA00} \
   CONFIG.C_RW_REG3_DEFAULT {0x00000004} \
 ] $axi_lite_reg_space_0

  # Create instance: clk_sel, and set properties
  set clk_sel [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 clk_sel ]

  # Create instance: clk_stat, and set properties
  set clk_stat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 clk_stat ]
  set_property -dict [ list \
   CONFIG.IN0_WIDTH {2} \
   CONFIG.IN1_WIDTH {1} \
   CONFIG.IN2_WIDTH {1} \
   CONFIG.IN3_WIDTH {28} \
   CONFIG.NUM_PORTS {4} \
 ] $clk_stat

  # Create instance: hb_en, and set properties
  set hb_en [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 hb_en ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DOUT_WIDTH {1} \
 ] $hb_en

  # Create instance: mclk_div, and set properties
  set mclk_div [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mclk_div ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {7} \
   CONFIG.DOUT_WIDTH {8} \
 ] $mclk_div

  # Create instance: sw_rst_trig, and set properties
  set sw_rst_trig [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 sw_rst_trig ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DOUT_WIDTH {1} \
 ] $sw_rst_trig

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {32} \
 ] $xlconstant_1

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_LITE_1 [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_lite_reg_space_0/S_AXI_LITE]

  # Create port connections
  connect_bd_net -net ACLK_1 [get_bd_pins ACLK] [get_bd_pins axi_lite_reg_space_0/S_AXI_LITE_ACLK]
  connect_bd_net -net ARESETN_1 [get_bd_pins ARESETN] [get_bd_pins axi_lite_reg_space_0/S_AXI_LITE_ARESETN]
  connect_bd_net -net axi_lite_read_write_0_REG0 [get_bd_pins axi_lite_reg_space_0/RW_REG0] [get_bd_pins clk_sel/Din] [get_bd_pins hb_en/Din] [get_bd_pins sw_rst_trig/Din]
  connect_bd_net -net axi_lite_reg_space_0_RW_REG1 [get_bd_pins sw_rst_cycles] [get_bd_pins axi_lite_reg_space_0/RW_REG1]
  connect_bd_net -net axi_lite_reg_space_0_RW_REG2 [get_bd_pins hb_cycles] [get_bd_pins axi_lite_reg_space_0/RW_REG2]
  connect_bd_net -net axi_lite_reg_space_0_RW_REG3 [get_bd_pins axi_lite_reg_space_0/RW_REG3] [get_bd_pins mclk_div/Din]
  connect_bd_net -net clk_sel_Dout [get_bd_pins clk_sel] [get_bd_pins clk_sel/Dout]
  connect_bd_net -net clk_sel_stat_1 [get_bd_pins clk_sel_stat] [get_bd_pins clk_stat/In1]
  connect_bd_net -net clk_stat_dout [get_bd_pins axi_lite_reg_space_0/RO_REG0] [get_bd_pins clk_stat/dout]
  connect_bd_net -net clk_valid_1 [get_bd_pins clk_valid] [get_bd_pins clk_stat/In2]
  connect_bd_net -net hb_en_Dout [get_bd_pins hb_en] [get_bd_pins hb_en/Dout]
  connect_bd_net -net pll_locked_1 [get_bd_pins pll_locked] [get_bd_pins clk_stat/In0]
  connect_bd_net -net sw_rst_trig_Dout [get_bd_pins sw_rst_trig] [get_bd_pins sw_rst_trig/Dout]
  connect_bd_net -net timestamp_1 [get_bd_pins timestamp] [get_bd_pins axi_lite_reg_space_0/RO_REG1]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins axi_lite_reg_space_0/RO_REG2] [get_bd_pins axi_lite_reg_space_0/RO_REG3] [get_bd_pins clk_stat/In3] [get_bd_pins xlconstant_1/dout]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins mclk_div] [get_bd_pins mclk_div/Dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: tile_aux_7
proc create_hier_cell_tile_aux_7 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_tile_aux_7() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: CLK_OUT
  create_hier_cell_CLK_OUT_7 $hier_obj CLK_OUT

  # Create instance: RESETN_OUT
  create_hier_cell_RESETN_OUT_7 $hier_obj RESETN_OUT

  # Create instance: TRIG_OUT
  create_hier_cell_TRIG_OUT_7 $hier_obj TRIG_OUT

  # Create port connections
  connect_bd_net -net CLK_OUT_O_CLK [get_bd_pins O_CLK] [get_bd_pins CLK_OUT/O_CLK]
  connect_bd_net -net CLK_OUT_O_CLK_N [get_bd_pins O_CLK_N] [get_bd_pins CLK_OUT/O_CLK_N]
  connect_bd_net -net CLK_OUT_O_CLK_P [get_bd_pins O_CLK_P] [get_bd_pins CLK_OUT/O_CLK_P]
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins CLK_OUT/I_CLK]
  connect_bd_net -net I_RESETN_1 [get_bd_pins I_RESETN] [get_bd_pins RESETN_OUT/I_RESETN]
  connect_bd_net -net I_TRIG_1 [get_bd_pins I_TRIG] [get_bd_pins TRIG_OUT/I_TRIG]
  connect_bd_net -net RESETN_OUT_O_RESETN [get_bd_pins O_RESETN] [get_bd_pins RESETN_OUT/O_RESETN]
  connect_bd_net -net RESETN_OUT_O_RESETN_N [get_bd_pins O_RESETN_N] [get_bd_pins RESETN_OUT/O_RESETN_N]
  connect_bd_net -net RESETN_OUT_O_RESETN_P [get_bd_pins O_RESETN_P] [get_bd_pins RESETN_OUT/O_RESETN_P]
  connect_bd_net -net TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins CLK_OUT/TILE_EN] [get_bd_pins RESETN_OUT/TILE_EN] [get_bd_pins TRIG_OUT/TILE_EN]
  connect_bd_net -net TRIG_OUT_O_TRIG [get_bd_pins O_TRIG] [get_bd_pins TRIG_OUT/O_TRIG]
  connect_bd_net -net TRIG_OUT_O_TRIG_N [get_bd_pins O_TRIG_N] [get_bd_pins TRIG_OUT/O_TRIG_N]
  connect_bd_net -net TRIG_OUT_O_TRIG_P [get_bd_pins O_TRIG_P] [get_bd_pins TRIG_OUT/O_TRIG_P]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: tile_aux_6
proc create_hier_cell_tile_aux_6 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_tile_aux_6() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: CLK_OUT
  create_hier_cell_CLK_OUT_6 $hier_obj CLK_OUT

  # Create instance: RESETN_OUT
  create_hier_cell_RESETN_OUT_6 $hier_obj RESETN_OUT

  # Create instance: TRIG_OUT
  create_hier_cell_TRIG_OUT_6 $hier_obj TRIG_OUT

  # Create port connections
  connect_bd_net -net CLK_OUT_O_CLK [get_bd_pins O_CLK] [get_bd_pins CLK_OUT/O_CLK]
  connect_bd_net -net CLK_OUT_O_CLK_N [get_bd_pins O_CLK_N] [get_bd_pins CLK_OUT/O_CLK_N]
  connect_bd_net -net CLK_OUT_O_CLK_P [get_bd_pins O_CLK_P] [get_bd_pins CLK_OUT/O_CLK_P]
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins CLK_OUT/I_CLK]
  connect_bd_net -net I_RESETN_1 [get_bd_pins I_RESETN] [get_bd_pins RESETN_OUT/I_RESETN]
  connect_bd_net -net I_TRIG_1 [get_bd_pins I_TRIG] [get_bd_pins TRIG_OUT/I_TRIG]
  connect_bd_net -net RESETN_OUT_O_RESETN [get_bd_pins O_RESETN] [get_bd_pins RESETN_OUT/O_RESETN]
  connect_bd_net -net RESETN_OUT_O_RESETN_N [get_bd_pins O_RESETN_N] [get_bd_pins RESETN_OUT/O_RESETN_N]
  connect_bd_net -net RESETN_OUT_O_RESETN_P [get_bd_pins O_RESETN_P] [get_bd_pins RESETN_OUT/O_RESETN_P]
  connect_bd_net -net TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins CLK_OUT/TILE_EN] [get_bd_pins RESETN_OUT/TILE_EN] [get_bd_pins TRIG_OUT/TILE_EN]
  connect_bd_net -net TRIG_OUT_O_TRIG [get_bd_pins O_TRIG] [get_bd_pins TRIG_OUT/O_TRIG]
  connect_bd_net -net TRIG_OUT_O_TRIG_N [get_bd_pins O_TRIG_N] [get_bd_pins TRIG_OUT/O_TRIG_N]
  connect_bd_net -net TRIG_OUT_O_TRIG_P [get_bd_pins O_TRIG_P] [get_bd_pins TRIG_OUT/O_TRIG_P]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: tile_aux_5
proc create_hier_cell_tile_aux_5 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_tile_aux_5() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: CLK_OUT
  create_hier_cell_CLK_OUT_5 $hier_obj CLK_OUT

  # Create instance: RESETN_OUT
  create_hier_cell_RESETN_OUT_5 $hier_obj RESETN_OUT

  # Create instance: TRIG_OUT
  create_hier_cell_TRIG_OUT_5 $hier_obj TRIG_OUT

  # Create port connections
  connect_bd_net -net CLK_OUT_O_CLK [get_bd_pins O_CLK] [get_bd_pins CLK_OUT/O_CLK]
  connect_bd_net -net CLK_OUT_O_CLK_N [get_bd_pins O_CLK_N] [get_bd_pins CLK_OUT/O_CLK_N]
  connect_bd_net -net CLK_OUT_O_CLK_P [get_bd_pins O_CLK_P] [get_bd_pins CLK_OUT/O_CLK_P]
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins CLK_OUT/I_CLK]
  connect_bd_net -net I_RESETN_1 [get_bd_pins I_RESETN] [get_bd_pins RESETN_OUT/I_RESETN]
  connect_bd_net -net I_TRIG_1 [get_bd_pins I_TRIG] [get_bd_pins TRIG_OUT/I_TRIG]
  connect_bd_net -net RESETN_OUT_O_RESETN [get_bd_pins O_RESETN] [get_bd_pins RESETN_OUT/O_RESETN]
  connect_bd_net -net RESETN_OUT_O_RESETN_N [get_bd_pins O_RESETN_N] [get_bd_pins RESETN_OUT/O_RESETN_N]
  connect_bd_net -net RESETN_OUT_O_RESETN_P [get_bd_pins O_RESETN_P] [get_bd_pins RESETN_OUT/O_RESETN_P]
  connect_bd_net -net TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins CLK_OUT/TILE_EN] [get_bd_pins RESETN_OUT/TILE_EN] [get_bd_pins TRIG_OUT/TILE_EN]
  connect_bd_net -net TRIG_OUT_O_TRIG [get_bd_pins O_TRIG] [get_bd_pins TRIG_OUT/O_TRIG]
  connect_bd_net -net TRIG_OUT_O_TRIG_N [get_bd_pins O_TRIG_N] [get_bd_pins TRIG_OUT/O_TRIG_N]
  connect_bd_net -net TRIG_OUT_O_TRIG_P [get_bd_pins O_TRIG_P] [get_bd_pins TRIG_OUT/O_TRIG_P]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: tile_aux_4
proc create_hier_cell_tile_aux_4 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_tile_aux_4() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: CLK_OUT
  create_hier_cell_CLK_OUT_4 $hier_obj CLK_OUT

  # Create instance: RESETN_OUT
  create_hier_cell_RESETN_OUT_4 $hier_obj RESETN_OUT

  # Create instance: TRIG_OUT
  create_hier_cell_TRIG_OUT_4 $hier_obj TRIG_OUT

  # Create port connections
  connect_bd_net -net CLK_OUT_O_CLK [get_bd_pins O_CLK] [get_bd_pins CLK_OUT/O_CLK]
  connect_bd_net -net CLK_OUT_O_CLK_N [get_bd_pins O_CLK_N] [get_bd_pins CLK_OUT/O_CLK_N]
  connect_bd_net -net CLK_OUT_O_CLK_P [get_bd_pins O_CLK_P] [get_bd_pins CLK_OUT/O_CLK_P]
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins CLK_OUT/I_CLK]
  connect_bd_net -net I_RESETN_1 [get_bd_pins I_RESETN] [get_bd_pins RESETN_OUT/I_RESETN]
  connect_bd_net -net I_TRIG_1 [get_bd_pins I_TRIG] [get_bd_pins TRIG_OUT/I_TRIG]
  connect_bd_net -net RESETN_OUT_O_RESETN [get_bd_pins O_RESETN] [get_bd_pins RESETN_OUT/O_RESETN]
  connect_bd_net -net RESETN_OUT_O_RESETN_N [get_bd_pins O_RESETN_N] [get_bd_pins RESETN_OUT/O_RESETN_N]
  connect_bd_net -net RESETN_OUT_O_RESETN_P [get_bd_pins O_RESETN_P] [get_bd_pins RESETN_OUT/O_RESETN_P]
  connect_bd_net -net TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins CLK_OUT/TILE_EN] [get_bd_pins RESETN_OUT/TILE_EN] [get_bd_pins TRIG_OUT/TILE_EN]
  connect_bd_net -net TRIG_OUT_O_TRIG [get_bd_pins O_TRIG] [get_bd_pins TRIG_OUT/O_TRIG]
  connect_bd_net -net TRIG_OUT_O_TRIG_N [get_bd_pins O_TRIG_N] [get_bd_pins TRIG_OUT/O_TRIG_N]
  connect_bd_net -net TRIG_OUT_O_TRIG_P [get_bd_pins O_TRIG_P] [get_bd_pins TRIG_OUT/O_TRIG_P]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: tile_aux_3
proc create_hier_cell_tile_aux_3 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_tile_aux_3() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: CLK_OUT
  create_hier_cell_CLK_OUT_3 $hier_obj CLK_OUT

  # Create instance: RESETN_OUT
  create_hier_cell_RESETN_OUT_3 $hier_obj RESETN_OUT

  # Create instance: TRIG_OUT
  create_hier_cell_TRIG_OUT_3 $hier_obj TRIG_OUT

  # Create port connections
  connect_bd_net -net CLK_OUT_O_CLK [get_bd_pins O_CLK] [get_bd_pins CLK_OUT/O_CLK]
  connect_bd_net -net CLK_OUT_O_CLK_N [get_bd_pins O_CLK_N] [get_bd_pins CLK_OUT/O_CLK_N]
  connect_bd_net -net CLK_OUT_O_CLK_P [get_bd_pins O_CLK_P] [get_bd_pins CLK_OUT/O_CLK_P]
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins CLK_OUT/I_CLK]
  connect_bd_net -net I_RESETN_1 [get_bd_pins I_RESETN] [get_bd_pins RESETN_OUT/I_RESETN]
  connect_bd_net -net I_TRIG_1 [get_bd_pins I_TRIG] [get_bd_pins TRIG_OUT/I_TRIG]
  connect_bd_net -net RESETN_OUT_O_RESETN [get_bd_pins O_RESETN] [get_bd_pins RESETN_OUT/O_RESETN]
  connect_bd_net -net RESETN_OUT_O_RESETN_N [get_bd_pins O_RESETN_N] [get_bd_pins RESETN_OUT/O_RESETN_N]
  connect_bd_net -net RESETN_OUT_O_RESETN_P [get_bd_pins O_RESETN_P] [get_bd_pins RESETN_OUT/O_RESETN_P]
  connect_bd_net -net TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins CLK_OUT/TILE_EN] [get_bd_pins RESETN_OUT/TILE_EN] [get_bd_pins TRIG_OUT/TILE_EN]
  connect_bd_net -net TRIG_OUT_O_TRIG [get_bd_pins O_TRIG] [get_bd_pins TRIG_OUT/O_TRIG]
  connect_bd_net -net TRIG_OUT_O_TRIG_N [get_bd_pins O_TRIG_N] [get_bd_pins TRIG_OUT/O_TRIG_N]
  connect_bd_net -net TRIG_OUT_O_TRIG_P [get_bd_pins O_TRIG_P] [get_bd_pins TRIG_OUT/O_TRIG_P]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: tile_aux_2
proc create_hier_cell_tile_aux_2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_tile_aux_2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: CLK_OUT
  create_hier_cell_CLK_OUT_2 $hier_obj CLK_OUT

  # Create instance: RESETN_OUT
  create_hier_cell_RESETN_OUT_2 $hier_obj RESETN_OUT

  # Create instance: TRIG_OUT
  create_hier_cell_TRIG_OUT_2 $hier_obj TRIG_OUT

  # Create port connections
  connect_bd_net -net CLK_OUT_O_CLK [get_bd_pins O_CLK] [get_bd_pins CLK_OUT/O_CLK]
  connect_bd_net -net CLK_OUT_O_CLK_N [get_bd_pins O_CLK_N] [get_bd_pins CLK_OUT/O_CLK_N]
  connect_bd_net -net CLK_OUT_O_CLK_P [get_bd_pins O_CLK_P] [get_bd_pins CLK_OUT/O_CLK_P]
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins CLK_OUT/I_CLK]
  connect_bd_net -net I_RESETN_1 [get_bd_pins I_RESETN] [get_bd_pins RESETN_OUT/I_RESETN]
  connect_bd_net -net I_TRIG_1 [get_bd_pins I_TRIG] [get_bd_pins TRIG_OUT/I_TRIG]
  connect_bd_net -net RESETN_OUT_O_RESETN [get_bd_pins O_RESETN] [get_bd_pins RESETN_OUT/O_RESETN]
  connect_bd_net -net RESETN_OUT_O_RESETN_N [get_bd_pins O_RESETN_N] [get_bd_pins RESETN_OUT/O_RESETN_N]
  connect_bd_net -net RESETN_OUT_O_RESETN_P [get_bd_pins O_RESETN_P] [get_bd_pins RESETN_OUT/O_RESETN_P]
  connect_bd_net -net TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins CLK_OUT/TILE_EN] [get_bd_pins RESETN_OUT/TILE_EN] [get_bd_pins TRIG_OUT/TILE_EN]
  connect_bd_net -net TRIG_OUT_O_TRIG [get_bd_pins O_TRIG] [get_bd_pins TRIG_OUT/O_TRIG]
  connect_bd_net -net TRIG_OUT_O_TRIG_N [get_bd_pins O_TRIG_N] [get_bd_pins TRIG_OUT/O_TRIG_N]
  connect_bd_net -net TRIG_OUT_O_TRIG_P [get_bd_pins O_TRIG_P] [get_bd_pins TRIG_OUT/O_TRIG_P]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: tile_aux_1
proc create_hier_cell_tile_aux_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_tile_aux_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: CLK_OUT
  create_hier_cell_CLK_OUT_1 $hier_obj CLK_OUT

  # Create instance: RESETN_OUT
  create_hier_cell_RESETN_OUT_1 $hier_obj RESETN_OUT

  # Create instance: TRIG_OUT
  create_hier_cell_TRIG_OUT_1 $hier_obj TRIG_OUT

  # Create port connections
  connect_bd_net -net CLK_OUT_O_CLK [get_bd_pins O_CLK] [get_bd_pins CLK_OUT/O_CLK]
  connect_bd_net -net CLK_OUT_O_CLK_N [get_bd_pins O_CLK_N] [get_bd_pins CLK_OUT/O_CLK_N]
  connect_bd_net -net CLK_OUT_O_CLK_P [get_bd_pins O_CLK_P] [get_bd_pins CLK_OUT/O_CLK_P]
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins CLK_OUT/I_CLK]
  connect_bd_net -net I_RESETN_1 [get_bd_pins I_RESETN] [get_bd_pins RESETN_OUT/I_RESETN]
  connect_bd_net -net I_TRIG_1 [get_bd_pins I_TRIG] [get_bd_pins TRIG_OUT/I_TRIG]
  connect_bd_net -net RESETN_OUT_O_RESETN [get_bd_pins O_RESETN] [get_bd_pins RESETN_OUT/O_RESETN]
  connect_bd_net -net RESETN_OUT_O_RESETN_N [get_bd_pins O_RESETN_N] [get_bd_pins RESETN_OUT/O_RESETN_N]
  connect_bd_net -net RESETN_OUT_O_RESETN_P [get_bd_pins O_RESETN_P] [get_bd_pins RESETN_OUT/O_RESETN_P]
  connect_bd_net -net TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins CLK_OUT/TILE_EN] [get_bd_pins RESETN_OUT/TILE_EN] [get_bd_pins TRIG_OUT/TILE_EN]
  connect_bd_net -net TRIG_OUT_O_TRIG [get_bd_pins O_TRIG] [get_bd_pins TRIG_OUT/O_TRIG]
  connect_bd_net -net TRIG_OUT_O_TRIG_N [get_bd_pins O_TRIG_N] [get_bd_pins TRIG_OUT/O_TRIG_N]
  connect_bd_net -net TRIG_OUT_O_TRIG_P [get_bd_pins O_TRIG_P] [get_bd_pins TRIG_OUT/O_TRIG_P]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: tile_aux_0
proc create_hier_cell_tile_aux_0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_tile_aux_0() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir I I_TRIG
  create_bd_pin -dir O O_CLK
  create_bd_pin -dir O O_CLK_N
  create_bd_pin -dir O O_CLK_P
  create_bd_pin -dir O O_RESETN
  create_bd_pin -dir O O_RESETN_N
  create_bd_pin -dir O O_RESETN_P
  create_bd_pin -dir O O_TRIG
  create_bd_pin -dir O O_TRIG_N
  create_bd_pin -dir O O_TRIG_P
  create_bd_pin -dir I TILE_EN

  # Create instance: CLK_OUT
  create_hier_cell_CLK_OUT $hier_obj CLK_OUT

  # Create instance: RESETN_OUT
  create_hier_cell_RESETN_OUT $hier_obj RESETN_OUT

  # Create instance: TRIG_OUT
  create_hier_cell_TRIG_OUT $hier_obj TRIG_OUT

  # Create port connections
  connect_bd_net -net CLK_OUT_O_CLK [get_bd_pins O_CLK] [get_bd_pins CLK_OUT/O_CLK]
  connect_bd_net -net CLK_OUT_O_CLK_N [get_bd_pins O_CLK_N] [get_bd_pins CLK_OUT/O_CLK_N]
  connect_bd_net -net CLK_OUT_O_CLK_P [get_bd_pins O_CLK_P] [get_bd_pins CLK_OUT/O_CLK_P]
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins CLK_OUT/I_CLK]
  connect_bd_net -net I_RESETN_1 [get_bd_pins I_RESETN] [get_bd_pins RESETN_OUT/I_RESETN]
  connect_bd_net -net I_TRIG_1 [get_bd_pins I_TRIG] [get_bd_pins TRIG_OUT/I_TRIG]
  connect_bd_net -net RESETN_OUT_O_RESETN [get_bd_pins O_RESETN] [get_bd_pins RESETN_OUT/O_RESETN]
  connect_bd_net -net RESETN_OUT_O_RESETN_N [get_bd_pins O_RESETN_N] [get_bd_pins RESETN_OUT/O_RESETN_N]
  connect_bd_net -net RESETN_OUT_O_RESETN_P [get_bd_pins O_RESETN_P] [get_bd_pins RESETN_OUT/O_RESETN_P]
  connect_bd_net -net TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins CLK_OUT/TILE_EN] [get_bd_pins RESETN_OUT/TILE_EN] [get_bd_pins TRIG_OUT/TILE_EN]
  connect_bd_net -net TRIG_OUT_O_TRIG [get_bd_pins O_TRIG] [get_bd_pins TRIG_OUT/O_TRIG]
  connect_bd_net -net TRIG_OUT_O_TRIG_N [get_bd_pins O_TRIG_N] [get_bd_pins TRIG_OUT/O_TRIG_N]
  connect_bd_net -net TRIG_OUT_O_TRIG_P [get_bd_pins O_TRIG_P] [get_bd_pins TRIG_OUT/O_TRIG_P]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: larpix_uart_array
proc create_hier_cell_larpix_uart_array { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_larpix_uart_array() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M0_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M1_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M2_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M3_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M4_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M5_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M6_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M7_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S0_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S1_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S2_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S3_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S4_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S5_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S6_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S7_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXIMM


  # Create pins
  create_bd_pin -dir I -type clk ACLK
  create_bd_pin -dir I -type rst ARESETN
  create_bd_pin -dir I -type clk MCLK
  create_bd_pin -dir I -from 31 -to 0 MISO
  create_bd_pin -dir O -from 31 -to 0 MOSI
  create_bd_pin -dir I -from 31 -to 0 PACMAN_TS
  create_bd_pin -dir I -from 7 -to 0 TILE_EN
  create_bd_pin -dir O UART_RX_BUSY
  create_bd_pin -dir O UART_TX_BUSY

  # Create instance: aximm
  create_hier_cell_aximm $hier_obj aximm

  # Create instance: axis_broadcast
  create_hier_cell_axis_broadcast $hier_obj axis_broadcast

  # Create instance: axis_merge
  create_hier_cell_axis_merge $hier_obj axis_merge

  # Create instance: uart_channels
  create_hier_cell_uart_channels $hier_obj uart_channels

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXIS1_1 [get_bd_intf_pins axis_merge/S00_AXIS1] [get_bd_intf_pins uart_channels/M_AXIS4]
  connect_bd_intf_net -intf_net S00_AXIS2_1 [get_bd_intf_pins axis_merge/S00_AXIS2] [get_bd_intf_pins uart_channels/M_AXIS8]
  connect_bd_intf_net -intf_net S00_AXIS3_1 [get_bd_intf_pins axis_merge/S00_AXIS3] [get_bd_intf_pins uart_channels/M_AXIS12]
  connect_bd_intf_net -intf_net S00_AXIS4_1 [get_bd_intf_pins axis_merge/S00_AXIS4] [get_bd_intf_pins uart_channels/M_AXIS16]
  connect_bd_intf_net -intf_net S00_AXIS5_1 [get_bd_intf_pins axis_merge/S00_AXIS5] [get_bd_intf_pins uart_channels/M_AXIS20]
  connect_bd_intf_net -intf_net S00_AXIS6_1 [get_bd_intf_pins axis_merge/S00_AXIS6] [get_bd_intf_pins uart_channels/M_AXIS24]
  connect_bd_intf_net -intf_net S00_AXIS7_1 [get_bd_intf_pins axis_merge/S00_AXIS7] [get_bd_intf_pins uart_channels/M_AXIS28]
  connect_bd_intf_net -intf_net S00_AXIS_1 [get_bd_intf_pins axis_merge/S00_AXIS] [get_bd_intf_pins uart_channels/M_AXIS]
  connect_bd_intf_net -intf_net S01_AXIS1_1 [get_bd_intf_pins axis_merge/S01_AXIS1] [get_bd_intf_pins uart_channels/M_AXIS5]
  connect_bd_intf_net -intf_net S01_AXIS2_1 [get_bd_intf_pins axis_merge/S01_AXIS2] [get_bd_intf_pins uart_channels/M_AXIS9]
  connect_bd_intf_net -intf_net S01_AXIS3_1 [get_bd_intf_pins axis_merge/S01_AXIS3] [get_bd_intf_pins uart_channels/M_AXIS13]
  connect_bd_intf_net -intf_net S01_AXIS4_1 [get_bd_intf_pins axis_merge/S01_AXIS4] [get_bd_intf_pins uart_channels/M_AXIS17]
  connect_bd_intf_net -intf_net S01_AXIS5_1 [get_bd_intf_pins axis_merge/S01_AXIS5] [get_bd_intf_pins uart_channels/M_AXIS21]
  connect_bd_intf_net -intf_net S01_AXIS6_1 [get_bd_intf_pins axis_merge/S01_AXIS6] [get_bd_intf_pins uart_channels/M_AXIS25]
  connect_bd_intf_net -intf_net S01_AXIS7_1 [get_bd_intf_pins axis_merge/S01_AXIS7] [get_bd_intf_pins uart_channels/M_AXIS29]
  connect_bd_intf_net -intf_net S01_AXIS_1 [get_bd_intf_pins axis_merge/S01_AXIS] [get_bd_intf_pins uart_channels/M_AXIS1]
  connect_bd_intf_net -intf_net S02_AXIS1_1 [get_bd_intf_pins axis_merge/S02_AXIS1] [get_bd_intf_pins uart_channels/M_AXIS6]
  connect_bd_intf_net -intf_net S02_AXIS2_1 [get_bd_intf_pins axis_merge/S02_AXIS2] [get_bd_intf_pins uart_channels/M_AXIS10]
  connect_bd_intf_net -intf_net S02_AXIS3_1 [get_bd_intf_pins axis_merge/S02_AXIS3] [get_bd_intf_pins uart_channels/M_AXIS14]
  connect_bd_intf_net -intf_net S02_AXIS4_1 [get_bd_intf_pins axis_merge/S02_AXIS4] [get_bd_intf_pins uart_channels/M_AXIS18]
  connect_bd_intf_net -intf_net S02_AXIS5_1 [get_bd_intf_pins axis_merge/S02_AXIS5] [get_bd_intf_pins uart_channels/M_AXIS22]
  connect_bd_intf_net -intf_net S02_AXIS6_1 [get_bd_intf_pins axis_merge/S02_AXIS6] [get_bd_intf_pins uart_channels/M_AXIS26]
  connect_bd_intf_net -intf_net S02_AXIS7_1 [get_bd_intf_pins axis_merge/S02_AXIS7] [get_bd_intf_pins uart_channels/M_AXIS30]
  connect_bd_intf_net -intf_net S02_AXIS_1 [get_bd_intf_pins axis_merge/S02_AXIS] [get_bd_intf_pins uart_channels/M_AXIS2]
  connect_bd_intf_net -intf_net S03_AXIS1_1 [get_bd_intf_pins axis_merge/S03_AXIS1] [get_bd_intf_pins uart_channels/M_AXIS7]
  connect_bd_intf_net -intf_net S03_AXIS2_1 [get_bd_intf_pins axis_merge/S03_AXIS2] [get_bd_intf_pins uart_channels/M_AXIS11]
  connect_bd_intf_net -intf_net S03_AXIS3_1 [get_bd_intf_pins axis_merge/S03_AXIS3] [get_bd_intf_pins uart_channels/M_AXIS15]
  connect_bd_intf_net -intf_net S03_AXIS4_1 [get_bd_intf_pins axis_merge/S03_AXIS4] [get_bd_intf_pins uart_channels/M_AXIS19]
  connect_bd_intf_net -intf_net S03_AXIS5_1 [get_bd_intf_pins axis_merge/S03_AXIS5] [get_bd_intf_pins uart_channels/M_AXIS23]
  connect_bd_intf_net -intf_net S03_AXIS6_1 [get_bd_intf_pins axis_merge/S03_AXIS6] [get_bd_intf_pins uart_channels/M_AXIS27]
  connect_bd_intf_net -intf_net S03_AXIS7_1 [get_bd_intf_pins axis_merge/S03_AXIS7] [get_bd_intf_pins uart_channels/M_AXIS31]
  connect_bd_intf_net -intf_net S03_AXIS_1 [get_bd_intf_pins axis_merge/S03_AXIS] [get_bd_intf_pins uart_channels/M_AXIS3]
  connect_bd_intf_net -intf_net S0_AXIS_1 [get_bd_intf_pins S0_AXIS] [get_bd_intf_pins axis_broadcast/S0_AXIS]
  connect_bd_intf_net -intf_net S1_AXIS_1 [get_bd_intf_pins S1_AXIS] [get_bd_intf_pins axis_broadcast/S1_AXIS]
  connect_bd_intf_net -intf_net S2_AXIS_1 [get_bd_intf_pins S2_AXIS] [get_bd_intf_pins axis_broadcast/S2_AXIS]
  connect_bd_intf_net -intf_net S3_AXIS_1 [get_bd_intf_pins S3_AXIS] [get_bd_intf_pins axis_broadcast/S3_AXIS]
  connect_bd_intf_net -intf_net S4_AXIS_1 [get_bd_intf_pins S4_AXIS] [get_bd_intf_pins axis_broadcast/S4_AXIS]
  connect_bd_intf_net -intf_net S5_AXIS_1 [get_bd_intf_pins S5_AXIS] [get_bd_intf_pins axis_broadcast/S5_AXIS]
  connect_bd_intf_net -intf_net S6_AXIS_1 [get_bd_intf_pins S6_AXIS] [get_bd_intf_pins axis_broadcast/S6_AXIS]
  connect_bd_intf_net -intf_net S7_AXIS_1 [get_bd_intf_pins S7_AXIS] [get_bd_intf_pins axis_broadcast/S7_AXIS]
  connect_bd_intf_net -intf_net S_AXIMM_1 [get_bd_intf_pins S_AXIMM] [get_bd_intf_pins aximm/S_AXIMM]
  connect_bd_intf_net -intf_net aximm_M00_AXI [get_bd_intf_pins aximm/M00_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE]
  connect_bd_intf_net -intf_net aximm_M01_AXI [get_bd_intf_pins aximm/M01_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE1]
  connect_bd_intf_net -intf_net aximm_M02_AXI [get_bd_intf_pins aximm/M02_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE2]
  connect_bd_intf_net -intf_net aximm_M03_AXI [get_bd_intf_pins aximm/M03_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE3]
  connect_bd_intf_net -intf_net aximm_M04_AXI [get_bd_intf_pins aximm/M04_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE4]
  connect_bd_intf_net -intf_net aximm_M05_AXI [get_bd_intf_pins aximm/M05_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE5]
  connect_bd_intf_net -intf_net aximm_M06_AXI [get_bd_intf_pins aximm/M06_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE6]
  connect_bd_intf_net -intf_net aximm_M07_AXI [get_bd_intf_pins aximm/M07_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE7]
  connect_bd_intf_net -intf_net aximm_M08_AXI [get_bd_intf_pins aximm/M08_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE8]
  connect_bd_intf_net -intf_net aximm_M09_AXI [get_bd_intf_pins aximm/M09_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE9]
  connect_bd_intf_net -intf_net aximm_M10_AXI [get_bd_intf_pins aximm/M10_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE10]
  connect_bd_intf_net -intf_net aximm_M11_AXI [get_bd_intf_pins aximm/M11_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE11]
  connect_bd_intf_net -intf_net aximm_M12_AXI [get_bd_intf_pins aximm/M12_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE12]
  connect_bd_intf_net -intf_net aximm_M13_AXI [get_bd_intf_pins aximm/M13_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE13]
  connect_bd_intf_net -intf_net aximm_M14_AXI [get_bd_intf_pins aximm/M14_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE14]
  connect_bd_intf_net -intf_net aximm_M15_AXI [get_bd_intf_pins aximm/M15_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE15]
  connect_bd_intf_net -intf_net aximm_M16_AXI [get_bd_intf_pins aximm/M16_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE16]
  connect_bd_intf_net -intf_net aximm_M17_AXI [get_bd_intf_pins aximm/M17_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE17]
  connect_bd_intf_net -intf_net aximm_M18_AXI [get_bd_intf_pins aximm/M18_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE18]
  connect_bd_intf_net -intf_net aximm_M19_AXI [get_bd_intf_pins aximm/M19_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE19]
  connect_bd_intf_net -intf_net aximm_M20_AXI [get_bd_intf_pins aximm/M20_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE20]
  connect_bd_intf_net -intf_net aximm_M21_AXI [get_bd_intf_pins aximm/M21_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE21]
  connect_bd_intf_net -intf_net aximm_M22_AXI [get_bd_intf_pins aximm/M22_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE22]
  connect_bd_intf_net -intf_net aximm_M23_AXI [get_bd_intf_pins aximm/M23_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE23]
  connect_bd_intf_net -intf_net aximm_M24_AXI [get_bd_intf_pins aximm/M24_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE24]
  connect_bd_intf_net -intf_net aximm_M25_AXI [get_bd_intf_pins aximm/M25_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE25]
  connect_bd_intf_net -intf_net aximm_M26_AXI [get_bd_intf_pins aximm/M26_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE26]
  connect_bd_intf_net -intf_net aximm_M27_AXI [get_bd_intf_pins aximm/M27_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE27]
  connect_bd_intf_net -intf_net aximm_M28_AXI [get_bd_intf_pins aximm/M28_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE28]
  connect_bd_intf_net -intf_net aximm_M29_AXI [get_bd_intf_pins aximm/M29_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE29]
  connect_bd_intf_net -intf_net aximm_M30_AXI [get_bd_intf_pins aximm/M30_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE30]
  connect_bd_intf_net -intf_net aximm_M31_AXI [get_bd_intf_pins aximm/M31_AXI] [get_bd_intf_pins uart_channels/S_AXI_LITE31]
  connect_bd_intf_net -intf_net axis_broadcast_M00_AXIS [get_bd_intf_pins axis_broadcast/M00_AXIS] [get_bd_intf_pins uart_channels/S_AXIS]
  connect_bd_intf_net -intf_net axis_broadcast_M00_AXIS1 [get_bd_intf_pins axis_broadcast/M00_AXIS1] [get_bd_intf_pins uart_channels/S_AXIS4]
  connect_bd_intf_net -intf_net axis_broadcast_M00_AXIS2 [get_bd_intf_pins axis_broadcast/M00_AXIS2] [get_bd_intf_pins uart_channels/S_AXIS8]
  connect_bd_intf_net -intf_net axis_broadcast_M00_AXIS3 [get_bd_intf_pins axis_broadcast/M00_AXIS3] [get_bd_intf_pins uart_channels/S_AXIS12]
  connect_bd_intf_net -intf_net axis_broadcast_M00_AXIS4 [get_bd_intf_pins axis_broadcast/M00_AXIS4] [get_bd_intf_pins uart_channels/S_AXIS16]
  connect_bd_intf_net -intf_net axis_broadcast_M00_AXIS5 [get_bd_intf_pins axis_broadcast/M00_AXIS5] [get_bd_intf_pins uart_channels/S_AXIS20]
  connect_bd_intf_net -intf_net axis_broadcast_M00_AXIS6 [get_bd_intf_pins axis_broadcast/M00_AXIS6] [get_bd_intf_pins uart_channels/S_AXIS24]
  connect_bd_intf_net -intf_net axis_broadcast_M00_AXIS7 [get_bd_intf_pins axis_broadcast/M00_AXIS7] [get_bd_intf_pins uart_channels/S_AXIS28]
  connect_bd_intf_net -intf_net axis_broadcast_M01_AXIS [get_bd_intf_pins axis_broadcast/M01_AXIS] [get_bd_intf_pins uart_channels/S_AXIS1]
  connect_bd_intf_net -intf_net axis_broadcast_M01_AXIS1 [get_bd_intf_pins axis_broadcast/M01_AXIS1] [get_bd_intf_pins uart_channels/S_AXIS5]
  connect_bd_intf_net -intf_net axis_broadcast_M01_AXIS2 [get_bd_intf_pins axis_broadcast/M01_AXIS2] [get_bd_intf_pins uart_channels/S_AXIS9]
  connect_bd_intf_net -intf_net axis_broadcast_M01_AXIS3 [get_bd_intf_pins axis_broadcast/M01_AXIS3] [get_bd_intf_pins uart_channels/S_AXIS13]
  connect_bd_intf_net -intf_net axis_broadcast_M01_AXIS4 [get_bd_intf_pins axis_broadcast/M01_AXIS4] [get_bd_intf_pins uart_channels/S_AXIS17]
  connect_bd_intf_net -intf_net axis_broadcast_M01_AXIS5 [get_bd_intf_pins axis_broadcast/M01_AXIS5] [get_bd_intf_pins uart_channels/S_AXIS21]
  connect_bd_intf_net -intf_net axis_broadcast_M01_AXIS6 [get_bd_intf_pins axis_broadcast/M01_AXIS6] [get_bd_intf_pins uart_channels/S_AXIS25]
  connect_bd_intf_net -intf_net axis_broadcast_M01_AXIS7 [get_bd_intf_pins axis_broadcast/M01_AXIS7] [get_bd_intf_pins uart_channels/S_AXIS29]
  connect_bd_intf_net -intf_net axis_broadcast_M02_AXIS [get_bd_intf_pins axis_broadcast/M02_AXIS] [get_bd_intf_pins uart_channels/S_AXIS2]
  connect_bd_intf_net -intf_net axis_broadcast_M02_AXIS1 [get_bd_intf_pins axis_broadcast/M02_AXIS1] [get_bd_intf_pins uart_channels/S_AXIS6]
  connect_bd_intf_net -intf_net axis_broadcast_M02_AXIS2 [get_bd_intf_pins axis_broadcast/M02_AXIS2] [get_bd_intf_pins uart_channels/S_AXIS10]
  connect_bd_intf_net -intf_net axis_broadcast_M02_AXIS3 [get_bd_intf_pins axis_broadcast/M02_AXIS3] [get_bd_intf_pins uart_channels/S_AXIS14]
  connect_bd_intf_net -intf_net axis_broadcast_M02_AXIS4 [get_bd_intf_pins axis_broadcast/M02_AXIS4] [get_bd_intf_pins uart_channels/S_AXIS18]
  connect_bd_intf_net -intf_net axis_broadcast_M02_AXIS5 [get_bd_intf_pins axis_broadcast/M02_AXIS5] [get_bd_intf_pins uart_channels/S_AXIS22]
  connect_bd_intf_net -intf_net axis_broadcast_M02_AXIS6 [get_bd_intf_pins axis_broadcast/M02_AXIS6] [get_bd_intf_pins uart_channels/S_AXIS26]
  connect_bd_intf_net -intf_net axis_broadcast_M02_AXIS7 [get_bd_intf_pins axis_broadcast/M02_AXIS7] [get_bd_intf_pins uart_channels/S_AXIS30]
  connect_bd_intf_net -intf_net axis_broadcast_M03_AXIS [get_bd_intf_pins axis_broadcast/M03_AXIS] [get_bd_intf_pins uart_channels/S_AXIS3]
  connect_bd_intf_net -intf_net axis_broadcast_M03_AXIS1 [get_bd_intf_pins axis_broadcast/M03_AXIS1] [get_bd_intf_pins uart_channels/S_AXIS7]
  connect_bd_intf_net -intf_net axis_broadcast_M03_AXIS2 [get_bd_intf_pins axis_broadcast/M03_AXIS2] [get_bd_intf_pins uart_channels/S_AXIS11]
  connect_bd_intf_net -intf_net axis_broadcast_M03_AXIS3 [get_bd_intf_pins axis_broadcast/M03_AXIS3] [get_bd_intf_pins uart_channels/S_AXIS15]
  connect_bd_intf_net -intf_net axis_broadcast_M03_AXIS4 [get_bd_intf_pins axis_broadcast/M03_AXIS4] [get_bd_intf_pins uart_channels/S_AXIS19]
  connect_bd_intf_net -intf_net axis_broadcast_M03_AXIS5 [get_bd_intf_pins axis_broadcast/M03_AXIS5] [get_bd_intf_pins uart_channels/S_AXIS23]
  connect_bd_intf_net -intf_net axis_broadcast_M03_AXIS6 [get_bd_intf_pins axis_broadcast/M03_AXIS6] [get_bd_intf_pins uart_channels/S_AXIS27]
  connect_bd_intf_net -intf_net axis_broadcast_M03_AXIS7 [get_bd_intf_pins axis_broadcast/M03_AXIS7] [get_bd_intf_pins uart_channels/S_AXIS31]
  connect_bd_intf_net -intf_net axis_merge_M0_AXIS [get_bd_intf_pins M0_AXIS] [get_bd_intf_pins axis_merge/M0_AXIS]
  connect_bd_intf_net -intf_net axis_merge_M1_AXIS [get_bd_intf_pins M1_AXIS] [get_bd_intf_pins axis_merge/M1_AXIS]
  connect_bd_intf_net -intf_net axis_merge_M2_AXIS [get_bd_intf_pins M2_AXIS] [get_bd_intf_pins axis_merge/M2_AXIS]
  connect_bd_intf_net -intf_net axis_merge_M3_AXIS [get_bd_intf_pins M3_AXIS] [get_bd_intf_pins axis_merge/M3_AXIS]
  connect_bd_intf_net -intf_net axis_merge_M4_AXIS [get_bd_intf_pins M4_AXIS] [get_bd_intf_pins axis_merge/M4_AXIS]
  connect_bd_intf_net -intf_net axis_merge_M5_AXIS [get_bd_intf_pins M5_AXIS] [get_bd_intf_pins axis_merge/M5_AXIS]
  connect_bd_intf_net -intf_net axis_merge_M6_AXIS [get_bd_intf_pins M6_AXIS] [get_bd_intf_pins axis_merge/M6_AXIS]
  connect_bd_intf_net -intf_net axis_merge_M7_AXIS [get_bd_intf_pins M7_AXIS] [get_bd_intf_pins axis_merge/M7_AXIS]

  # Create port connections
  connect_bd_net -net ACLK_1 [get_bd_pins ACLK] [get_bd_pins aximm/ACLK] [get_bd_pins axis_broadcast/ACLK] [get_bd_pins axis_merge/ACLK] [get_bd_pins uart_channels/ACLK]
  connect_bd_net -net ARESETN_1 [get_bd_pins ARESETN] [get_bd_pins aximm/ARESETN] [get_bd_pins axis_broadcast/ARESETN] [get_bd_pins axis_merge/ARESETN] [get_bd_pins uart_channels/ARESETN]
  connect_bd_net -net MCLK_1 [get_bd_pins MCLK] [get_bd_pins uart_channels/MCLK]
  connect_bd_net -net MISO_1 [get_bd_pins MISO] [get_bd_pins uart_channels/MISO]
  connect_bd_net -net PACMAN_TS_1 [get_bd_pins PACMAN_TS] [get_bd_pins uart_channels/PACMAN_TS]
  connect_bd_net -net TILE_EN_1 [get_bd_pins TILE_EN] [get_bd_pins uart_channels/TILE_EN]
  connect_bd_net -net uart_channels_MOSI [get_bd_pins MOSI] [get_bd_pins uart_channels/MOSI]
  connect_bd_net -net uart_channels_UART_RX_BUSY [get_bd_pins UART_RX_BUSY] [get_bd_pins uart_channels/UART_RX_BUSY]
  connect_bd_net -net uart_channels_UART_TX_BUSY [get_bd_pins UART_TX_BUSY] [get_bd_pins uart_channels/UART_TX_BUSY]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: larpix_trig
proc create_hier_cell_larpix_trig { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_larpix_trig() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I ACLK
  create_bd_pin -dir I ARESETN
  create_bd_pin -dir I MCLK
  create_bd_pin -dir I -from 31 -to 0 TIMESTAMP
  create_bd_pin -dir O TRIG
  create_bd_pin -dir I TRIG1_IN
  create_bd_pin -dir I TRIG2_IN
  create_bd_pin -dir I TRIG3_IN
  create_bd_pin -dir O -from 7 -to 0 TRIG_MASKED
  create_bd_pin -dir O -from 3 -to 0 TRIG_TYPE

  # Create instance: axi_lite_reg_space
  create_hier_cell_axi_lite_reg_space_2 $hier_obj axi_lite_reg_space

  # Create instance: larpix_periodic_trig_0, and set properties
  set block_name larpix_periodic_trig_gen
  set block_cell_name larpix_periodic_trig_0
  if { [catch {set larpix_periodic_trig_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_periodic_trig_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_trig_gen_0, and set properties
  set block_name larpix_trig_gen
  set block_cell_name larpix_trig_gen_0
  if { [catch {set larpix_trig_gen_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_trig_gen_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_trig_to_axi_s_0, and set properties
  set block_name larpix_trig_to_axi_stream
  set block_cell_name larpix_trig_to_axi_s_0
  if { [catch {set larpix_trig_to_axi_s_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_trig_to_axi_s_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
   CONFIG.IN0_WIDTH {4} \
   CONFIG.IN1_WIDTH {4} \
 ] $xlconcat_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {4} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_LITE_1 [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_lite_reg_space/S_AXI_LITE]
  connect_bd_intf_net -intf_net larpix_trig_to_axi_s_0_M_AXIS [get_bd_intf_pins M_AXIS] [get_bd_intf_pins larpix_trig_to_axi_s_0/M_AXIS]

  # Create port connections
  connect_bd_net -net ACLK_1 [get_bd_pins ACLK] [get_bd_pins axi_lite_reg_space/S_AXI_LITE_ACLK] [get_bd_pins larpix_periodic_trig_0/ACLK] [get_bd_pins larpix_trig_to_axi_s_0/M_AXIS_ACLK]
  connect_bd_net -net ARESETN_1 [get_bd_pins ARESETN] [get_bd_pins axi_lite_reg_space/S_AXI_LITE_ARESETN] [get_bd_pins larpix_periodic_trig_0/ARESETN] [get_bd_pins larpix_trig_gen_0/RSTN] [get_bd_pins larpix_trig_to_axi_s_0/M_AXIS_ARESETN]
  connect_bd_net -net MCLK_1 [get_bd_pins MCLK] [get_bd_pins larpix_trig_gen_0/MCLK]
  connect_bd_net -net TIMESTAMP_1 [get_bd_pins TIMESTAMP] [get_bd_pins larpix_trig_to_axi_s_0/TRIG_TIMESTAMP]
  connect_bd_net -net TRIG1_IN_1 [get_bd_pins TRIG1_IN] [get_bd_pins larpix_trig_gen_0/TRIG1_IN]
  connect_bd_net -net TRIG2_IN_1 [get_bd_pins TRIG2_IN] [get_bd_pins larpix_trig_gen_0/TRIG2_IN]
  connect_bd_net -net TRIG3_IN_1 [get_bd_pins TRIG3_IN] [get_bd_pins larpix_trig_gen_0/TRIG3_IN]
  connect_bd_net -net axi_lite_reg_space_periodic_trig_cycles [get_bd_pins axi_lite_reg_space/periodic_trig_cycles] [get_bd_pins larpix_periodic_trig_0/CYCLES]
  connect_bd_net -net axi_lite_reg_space_periodic_trig_en [get_bd_pins axi_lite_reg_space/periodic_trig_en] [get_bd_pins larpix_periodic_trig_0/EN]
  connect_bd_net -net axi_lite_reg_space_trig0_mask [get_bd_pins axi_lite_reg_space/trig0_mask] [get_bd_pins larpix_trig_gen_0/TRIG0_MASK]
  connect_bd_net -net axi_lite_reg_space_trig1_mask [get_bd_pins axi_lite_reg_space/trig1_mask] [get_bd_pins larpix_trig_gen_0/TRIG1_MASK]
  connect_bd_net -net axi_lite_reg_space_trig2_mask [get_bd_pins axi_lite_reg_space/trig2_mask] [get_bd_pins larpix_trig_gen_0/TRIG2_MASK]
  connect_bd_net -net axi_lite_reg_space_trig3_mask [get_bd_pins axi_lite_reg_space/trig3_mask] [get_bd_pins larpix_trig_gen_0/TRIG3_MASK]
  connect_bd_net -net axi_lite_reg_space_trig_len [get_bd_pins axi_lite_reg_space/trig_len] [get_bd_pins larpix_trig_gen_0/TRIG_LEN]
  connect_bd_net -net larpix_periodic_trig_0_O [get_bd_pins larpix_periodic_trig_0/O] [get_bd_pins larpix_trig_gen_0/TRIG0_IN]
  connect_bd_net -net larpix_trig_gen_0_TRIG [get_bd_pins TRIG] [get_bd_pins larpix_trig_gen_0/TRIG]
  connect_bd_net -net larpix_trig_gen_0_TRIG_MASKED [get_bd_pins TRIG_MASKED] [get_bd_pins larpix_trig_gen_0/TRIG_MASKED]
  connect_bd_net -net larpix_trig_gen_0_TRIG_TYPE [get_bd_pins TRIG_TYPE] [get_bd_pins larpix_trig_gen_0/TRIG_TYPE] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins larpix_trig_to_axi_s_0/TRIG_TYPE] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins xlconcat_0/In1] [get_bd_pins xlconstant_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: larpix_clk
proc create_hier_cell_larpix_clk { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_larpix_clk() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I ACLK
  create_bd_pin -dir I CLK_AUX
  create_bd_pin -dir I HW_HARD_RST_TRIG
  create_bd_pin -dir I HW_STATE_RST_TRIG
  create_bd_pin -dir I HW_SYNC_TRIG
  create_bd_pin -dir O MCLK
  create_bd_pin -dir I RSTN
  create_bd_pin -dir O RST_SYNC_N
  create_bd_pin -dir O -from 31 -to 0 TIMESTAMP

  # Create instance: axi_lite_reg_space
  create_hier_cell_axi_lite_reg_space_1 $hier_obj axi_lite_reg_space

  # Create instance: larpix_clk_to_axi_st_0, and set properties
  set block_name larpix_clk_to_axi_stream
  set block_cell_name larpix_clk_to_axi_st_0
  if { [catch {set larpix_clk_to_axi_st_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_clk_to_axi_st_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_counter_0, and set properties
  set block_name larpix_counter
  set block_cell_name larpix_counter_0
  if { [catch {set larpix_counter_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_counter_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: larpix_mclk_sel_0, and set properties
  set block_name larpix_mclk_sel
  set block_cell_name larpix_mclk_sel_0
  if { [catch {set larpix_mclk_sel_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_mclk_sel_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_AUX_CLK_PERIOD {50} \
   CONFIG.C_MCLK_PERIOD {100} \
 ] $larpix_mclk_sel_0

  # Create instance: larpix_reset_gen_0, and set properties
  set block_name larpix_reset_gen
  set block_cell_name larpix_reset_gen_0
  if { [catch {set larpix_reset_gen_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $larpix_reset_gen_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {1} \
 ] $util_vector_logic_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_lite_reg_space/S_AXI_LITE]
  connect_bd_intf_net -intf_net larpix_clk_to_axi_st_0_M_AXIS [get_bd_intf_pins M_AXIS] [get_bd_intf_pins larpix_clk_to_axi_st_0/M_AXIS]

  # Create port connections
  connect_bd_net -net ACLK_1 [get_bd_pins ACLK] [get_bd_pins axi_lite_reg_space/ACLK] [get_bd_pins larpix_clk_to_axi_st_0/M_AXIS_ACLK] [get_bd_pins larpix_mclk_sel_0/ACLK]
  connect_bd_net -net CLK_AUX_1 [get_bd_pins CLK_AUX] [get_bd_pins larpix_mclk_sel_0/AUX_CLK]
  connect_bd_net -net HW_HARD_RST_TRIG_1 [get_bd_pins HW_HARD_RST_TRIG] [get_bd_pins larpix_reset_gen_0/HW_HARD_RST_TRIG]
  connect_bd_net -net HW_STATE_RST_TRIG_1 [get_bd_pins HW_STATE_RST_TRIG] [get_bd_pins larpix_reset_gen_0/HW_STATE_RST_TRIG]
  connect_bd_net -net HW_SYNC_TRIG_1 [get_bd_pins HW_SYNC_TRIG] [get_bd_pins larpix_reset_gen_0/HW_SYNC_TRIG]
  connect_bd_net -net RSTN_1 [get_bd_pins RSTN] [get_bd_pins axi_lite_reg_space/ARESETN] [get_bd_pins larpix_clk_to_axi_st_0/M_AXIS_ARESETN] [get_bd_pins larpix_mclk_sel_0/RSTN] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net axi_lite_reg_space_clk_sel [get_bd_pins axi_lite_reg_space/clk_sel] [get_bd_pins larpix_mclk_sel_0/CLK_SEL]
  connect_bd_net -net axi_lite_reg_space_hb_cycles [get_bd_pins axi_lite_reg_space/hb_cycles] [get_bd_pins larpix_clk_to_axi_st_0/HB_CYCLES]
  connect_bd_net -net axi_lite_reg_space_hb_en [get_bd_pins axi_lite_reg_space/hb_en] [get_bd_pins larpix_clk_to_axi_st_0/HB_EN]
  connect_bd_net -net axi_lite_reg_space_mclk_div -boundary_type upper [get_bd_pins axi_lite_reg_space/mclk_div]
  connect_bd_net -net axi_lite_reg_space_sw_rst_cycles [get_bd_pins axi_lite_reg_space/sw_rst_cycles] [get_bd_pins larpix_reset_gen_0/SW_RST_CYCLES]
  connect_bd_net -net axi_lite_reg_space_sw_rst_trig [get_bd_pins axi_lite_reg_space/sw_rst_trig] [get_bd_pins larpix_reset_gen_0/SW_RST_TRIG]
  connect_bd_net -net larpix_counter_0_COUNTER [get_bd_pins TIMESTAMP] [get_bd_pins axi_lite_reg_space/timestamp] [get_bd_pins larpix_clk_to_axi_st_0/TIMESTAMP] [get_bd_pins larpix_counter_0/COUNTER]
  connect_bd_net -net larpix_counter_0_COUNTER_PREV [get_bd_pins larpix_clk_to_axi_st_0/TIMESTAMP_PREV] [get_bd_pins larpix_counter_0/COUNTER_PREV]
  connect_bd_net -net larpix_counter_0_ROLLOVER_SYNC [get_bd_pins larpix_clk_to_axi_st_0/TIMESTAMP_SYNC] [get_bd_pins larpix_counter_0/ROLLOVER_SYNC]
  connect_bd_net -net larpix_mclk_sel_0_CLK_STAT [get_bd_pins axi_lite_reg_space/clk_sel_stat] [get_bd_pins larpix_clk_to_axi_st_0/CLK_SRC] [get_bd_pins larpix_mclk_sel_0/CLK_STAT_ACLK]
  connect_bd_net -net larpix_mclk_sel_0_CLK_VALID_ACLK [get_bd_pins axi_lite_reg_space/clk_valid] [get_bd_pins larpix_mclk_sel_0/CLK_VALID_ACLK] [get_bd_pins util_vector_logic_0/Op2]
  connect_bd_net -net larpix_mclk_sel_0_LOCKED [get_bd_pins axi_lite_reg_space/pll_locked] [get_bd_pins larpix_mclk_sel_0/LOCKED_ACLK]
  connect_bd_net -net larpix_mclk_sel_0_MCLK [get_bd_pins MCLK] [get_bd_pins larpix_counter_0/MCLK] [get_bd_pins larpix_mclk_sel_0/MCLK] [get_bd_pins larpix_reset_gen_0/MCLK]
  connect_bd_net -net larpix_reset_gen_0_RST_SYNC_N [get_bd_pins RST_SYNC_N] [get_bd_pins larpix_counter_0/RSTN] [get_bd_pins larpix_reset_gen_0/RST_SYNC_N]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins larpix_reset_gen_0/RSTN] [get_bd_pins util_vector_logic_0/Res]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: io
proc create_hier_cell_io { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_io() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I I_CLK
  create_bd_pin -dir I I_RESETN
  create_bd_pin -dir I -from 7 -to 0 I_TILE_EN
  create_bd_pin -dir I -from 7 -to 0 I_TRIG
  create_bd_pin -dir O -from 7 -to 0 O_CLK
  create_bd_pin -dir O -from 7 -to 0 O_CLK_N
  create_bd_pin -dir O -from 7 -to 0 O_CLK_P
  create_bd_pin -dir O -from 7 -to 0 O_RESETN
  create_bd_pin -dir O -from 7 -to 0 O_RESETN_N
  create_bd_pin -dir O -from 7 -to 0 O_RESETN_P
  create_bd_pin -dir O -from 7 -to 0 O_TRIG
  create_bd_pin -dir O -from 7 -to 0 O_TRIG_N
  create_bd_pin -dir O -from 7 -to 0 O_TRIG_P

  # Create instance: tile_aux_0
  create_hier_cell_tile_aux_0 $hier_obj tile_aux_0

  # Create instance: tile_aux_1
  create_hier_cell_tile_aux_1 $hier_obj tile_aux_1

  # Create instance: tile_aux_2
  create_hier_cell_tile_aux_2 $hier_obj tile_aux_2

  # Create instance: tile_aux_3
  create_hier_cell_tile_aux_3 $hier_obj tile_aux_3

  # Create instance: tile_aux_4
  create_hier_cell_tile_aux_4 $hier_obj tile_aux_4

  # Create instance: tile_aux_5
  create_hier_cell_tile_aux_5 $hier_obj tile_aux_5

  # Create instance: tile_aux_6
  create_hier_cell_tile_aux_6 $hier_obj tile_aux_6

  # Create instance: tile_aux_7
  create_hier_cell_tile_aux_7 $hier_obj tile_aux_7

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {8} \
 ] $xlconcat_0

  # Create instance: xlconcat_1, and set properties
  set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_1 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {8} \
 ] $xlconcat_1

  # Create instance: xlconcat_2, and set properties
  set xlconcat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_2 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {8} \
 ] $xlconcat_2

  # Create instance: xlconcat_3, and set properties
  set xlconcat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_3 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {8} \
 ] $xlconcat_3

  # Create instance: xlconcat_4, and set properties
  set xlconcat_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_4 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {8} \
 ] $xlconcat_4

  # Create instance: xlconcat_5, and set properties
  set xlconcat_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_5 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {8} \
 ] $xlconcat_5

  # Create instance: xlconcat_6, and set properties
  set xlconcat_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_6 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {8} \
 ] $xlconcat_6

  # Create instance: xlconcat_7, and set properties
  set xlconcat_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_7 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {8} \
 ] $xlconcat_7

  # Create instance: xlconcat_8, and set properties
  set xlconcat_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_8 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {8} \
 ] $xlconcat_8

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {8} \
 ] $xlslice_0

  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_1

  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_2 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_2

  # Create instance: xlslice_3, and set properties
  set xlslice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_3 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {3} \
   CONFIG.DIN_TO {3} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_3

  # Create instance: xlslice_4, and set properties
  set xlslice_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_4 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {4} \
   CONFIG.DIN_TO {4} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_4

  # Create instance: xlslice_5, and set properties
  set xlslice_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_5 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {5} \
   CONFIG.DIN_TO {5} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_5

  # Create instance: xlslice_6, and set properties
  set xlslice_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_6 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {6} \
   CONFIG.DIN_TO {6} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_6

  # Create instance: xlslice_7, and set properties
  set xlslice_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_7 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {7} \
   CONFIG.DIN_TO {7} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_7

  # Create instance: xlslice_8, and set properties
  set xlslice_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_8 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {8} \
 ] $xlslice_8

  # Create instance: xlslice_9, and set properties
  set xlslice_9 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_9 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_9

  # Create instance: xlslice_10, and set properties
  set xlslice_10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_10 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_10

  # Create instance: xlslice_11, and set properties
  set xlslice_11 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_11 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {3} \
   CONFIG.DIN_TO {3} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_11

  # Create instance: xlslice_12, and set properties
  set xlslice_12 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_12 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {4} \
   CONFIG.DIN_TO {4} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_12

  # Create instance: xlslice_13, and set properties
  set xlslice_13 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_13 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {5} \
   CONFIG.DIN_TO {5} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_13

  # Create instance: xlslice_14, and set properties
  set xlslice_14 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_14 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {6} \
   CONFIG.DIN_TO {6} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_14

  # Create instance: xlslice_15, and set properties
  set xlslice_15 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_15 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {7} \
   CONFIG.DIN_TO {7} \
   CONFIG.DIN_WIDTH {8} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_15

  # Create port connections
  connect_bd_net -net I_CLK_1 [get_bd_pins I_CLK] [get_bd_pins tile_aux_0/I_CLK] [get_bd_pins tile_aux_1/I_CLK] [get_bd_pins tile_aux_2/I_CLK] [get_bd_pins tile_aux_3/I_CLK] [get_bd_pins tile_aux_4/I_CLK] [get_bd_pins tile_aux_5/I_CLK] [get_bd_pins tile_aux_6/I_CLK] [get_bd_pins tile_aux_7/I_CLK]
  connect_bd_net -net I_RESETN_1 [get_bd_pins I_RESETN] [get_bd_pins tile_aux_0/I_RESETN] [get_bd_pins tile_aux_1/I_RESETN] [get_bd_pins tile_aux_2/I_RESETN] [get_bd_pins tile_aux_3/I_RESETN] [get_bd_pins tile_aux_4/I_RESETN] [get_bd_pins tile_aux_5/I_RESETN] [get_bd_pins tile_aux_6/I_RESETN] [get_bd_pins tile_aux_7/I_RESETN]
  connect_bd_net -net I_TILE_EN_1 [get_bd_pins I_TILE_EN] [get_bd_pins xlslice_0/Din] [get_bd_pins xlslice_1/Din] [get_bd_pins xlslice_2/Din] [get_bd_pins xlslice_3/Din] [get_bd_pins xlslice_4/Din] [get_bd_pins xlslice_5/Din] [get_bd_pins xlslice_6/Din] [get_bd_pins xlslice_7/Din]
  connect_bd_net -net I_TRIG_1 [get_bd_pins I_TRIG] [get_bd_pins xlslice_10/Din] [get_bd_pins xlslice_11/Din] [get_bd_pins xlslice_12/Din] [get_bd_pins xlslice_13/Din] [get_bd_pins xlslice_14/Din] [get_bd_pins xlslice_15/Din] [get_bd_pins xlslice_8/Din] [get_bd_pins xlslice_9/Din]
  connect_bd_net -net tile_aux_0_O_CLK [get_bd_pins tile_aux_0/O_CLK] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net tile_aux_0_O_CLK_N [get_bd_pins tile_aux_0/O_CLK_N] [get_bd_pins xlconcat_2/In0]
  connect_bd_net -net tile_aux_0_O_CLK_P [get_bd_pins tile_aux_0/O_CLK_P] [get_bd_pins xlconcat_1/In0]
  connect_bd_net -net tile_aux_0_O_RESETN [get_bd_pins tile_aux_0/O_RESETN] [get_bd_pins xlconcat_6/In0]
  connect_bd_net -net tile_aux_0_O_RESETN_N [get_bd_pins tile_aux_0/O_RESETN_N] [get_bd_pins xlconcat_8/In0]
  connect_bd_net -net tile_aux_0_O_RESETN_P [get_bd_pins tile_aux_0/O_RESETN_P] [get_bd_pins xlconcat_7/In0]
  connect_bd_net -net tile_aux_0_O_TRIG [get_bd_pins tile_aux_0/O_TRIG] [get_bd_pins xlconcat_3/In0]
  connect_bd_net -net tile_aux_0_O_TRIG_N [get_bd_pins tile_aux_0/O_TRIG_N] [get_bd_pins xlconcat_5/In0]
  connect_bd_net -net tile_aux_0_O_TRIG_P [get_bd_pins tile_aux_0/O_TRIG_P] [get_bd_pins xlconcat_4/In0]
  connect_bd_net -net tile_aux_1_O_CLK [get_bd_pins tile_aux_1/O_CLK] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net tile_aux_1_O_CLK_N [get_bd_pins tile_aux_1/O_CLK_N] [get_bd_pins xlconcat_2/In1]
  connect_bd_net -net tile_aux_1_O_CLK_P [get_bd_pins tile_aux_1/O_CLK_P] [get_bd_pins xlconcat_1/In1]
  connect_bd_net -net tile_aux_1_O_RESETN [get_bd_pins tile_aux_1/O_RESETN] [get_bd_pins xlconcat_6/In1]
  connect_bd_net -net tile_aux_1_O_RESETN_N [get_bd_pins tile_aux_1/O_RESETN_N] [get_bd_pins xlconcat_8/In1]
  connect_bd_net -net tile_aux_1_O_RESETN_P [get_bd_pins tile_aux_1/O_RESETN_P] [get_bd_pins xlconcat_7/In1]
  connect_bd_net -net tile_aux_1_O_TRIG [get_bd_pins tile_aux_1/O_TRIG] [get_bd_pins xlconcat_3/In1]
  connect_bd_net -net tile_aux_1_O_TRIG_N [get_bd_pins tile_aux_1/O_TRIG_N] [get_bd_pins xlconcat_5/In1]
  connect_bd_net -net tile_aux_1_O_TRIG_P [get_bd_pins tile_aux_1/O_TRIG_P] [get_bd_pins xlconcat_4/In1]
  connect_bd_net -net tile_aux_2_O_CLK [get_bd_pins tile_aux_2/O_CLK] [get_bd_pins xlconcat_0/In2]
  connect_bd_net -net tile_aux_2_O_CLK_N [get_bd_pins tile_aux_2/O_CLK_N] [get_bd_pins xlconcat_2/In2]
  connect_bd_net -net tile_aux_2_O_CLK_P [get_bd_pins tile_aux_2/O_CLK_P] [get_bd_pins xlconcat_1/In2]
  connect_bd_net -net tile_aux_2_O_RESETN [get_bd_pins tile_aux_2/O_RESETN] [get_bd_pins xlconcat_6/In2]
  connect_bd_net -net tile_aux_2_O_RESETN_N [get_bd_pins tile_aux_2/O_RESETN_N] [get_bd_pins xlconcat_8/In2]
  connect_bd_net -net tile_aux_2_O_RESETN_P [get_bd_pins tile_aux_2/O_RESETN_P] [get_bd_pins xlconcat_7/In2]
  connect_bd_net -net tile_aux_2_O_TRIG [get_bd_pins tile_aux_2/O_TRIG] [get_bd_pins xlconcat_3/In2]
  connect_bd_net -net tile_aux_2_O_TRIG_N [get_bd_pins tile_aux_2/O_TRIG_N] [get_bd_pins xlconcat_5/In2]
  connect_bd_net -net tile_aux_2_O_TRIG_P [get_bd_pins tile_aux_2/O_TRIG_P] [get_bd_pins xlconcat_4/In2]
  connect_bd_net -net tile_aux_3_O_CLK [get_bd_pins tile_aux_3/O_CLK] [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net tile_aux_3_O_CLK_N [get_bd_pins tile_aux_3/O_CLK_N] [get_bd_pins xlconcat_2/In3]
  connect_bd_net -net tile_aux_3_O_CLK_P [get_bd_pins tile_aux_3/O_CLK_P] [get_bd_pins xlconcat_1/In3]
  connect_bd_net -net tile_aux_3_O_RESETN [get_bd_pins tile_aux_3/O_RESETN] [get_bd_pins xlconcat_6/In3]
  connect_bd_net -net tile_aux_3_O_RESETN_N [get_bd_pins tile_aux_3/O_RESETN_N] [get_bd_pins xlconcat_8/In3]
  connect_bd_net -net tile_aux_3_O_RESETN_P [get_bd_pins tile_aux_3/O_RESETN_P] [get_bd_pins xlconcat_7/In3]
  connect_bd_net -net tile_aux_3_O_TRIG [get_bd_pins tile_aux_3/O_TRIG] [get_bd_pins xlconcat_3/In3]
  connect_bd_net -net tile_aux_3_O_TRIG_N [get_bd_pins tile_aux_3/O_TRIG_N] [get_bd_pins xlconcat_5/In3]
  connect_bd_net -net tile_aux_3_O_TRIG_P [get_bd_pins tile_aux_3/O_TRIG_P] [get_bd_pins xlconcat_4/In3]
  connect_bd_net -net tile_aux_4_O_CLK [get_bd_pins tile_aux_4/O_CLK] [get_bd_pins xlconcat_0/In4]
  connect_bd_net -net tile_aux_4_O_CLK_N [get_bd_pins tile_aux_4/O_CLK_N] [get_bd_pins xlconcat_2/In4]
  connect_bd_net -net tile_aux_4_O_CLK_P [get_bd_pins tile_aux_4/O_CLK_P] [get_bd_pins xlconcat_1/In4]
  connect_bd_net -net tile_aux_4_O_RESETN [get_bd_pins tile_aux_4/O_RESETN] [get_bd_pins xlconcat_6/In4]
  connect_bd_net -net tile_aux_4_O_RESETN_N [get_bd_pins tile_aux_4/O_RESETN_N] [get_bd_pins xlconcat_8/In4]
  connect_bd_net -net tile_aux_4_O_RESETN_P [get_bd_pins tile_aux_4/O_RESETN_P] [get_bd_pins xlconcat_7/In4]
  connect_bd_net -net tile_aux_4_O_TRIG [get_bd_pins tile_aux_4/O_TRIG] [get_bd_pins xlconcat_3/In4]
  connect_bd_net -net tile_aux_4_O_TRIG_N [get_bd_pins tile_aux_4/O_TRIG_N] [get_bd_pins xlconcat_5/In4]
  connect_bd_net -net tile_aux_4_O_TRIG_P [get_bd_pins tile_aux_4/O_TRIG_P] [get_bd_pins xlconcat_4/In4]
  connect_bd_net -net tile_aux_5_O_CLK [get_bd_pins tile_aux_5/O_CLK] [get_bd_pins xlconcat_0/In5]
  connect_bd_net -net tile_aux_5_O_CLK_N [get_bd_pins tile_aux_5/O_CLK_N] [get_bd_pins xlconcat_2/In5]
  connect_bd_net -net tile_aux_5_O_CLK_P [get_bd_pins tile_aux_5/O_CLK_P] [get_bd_pins xlconcat_1/In5]
  connect_bd_net -net tile_aux_5_O_RESETN [get_bd_pins tile_aux_5/O_RESETN] [get_bd_pins xlconcat_6/In5]
  connect_bd_net -net tile_aux_5_O_RESETN_N [get_bd_pins tile_aux_5/O_RESETN_N] [get_bd_pins xlconcat_8/In5]
  connect_bd_net -net tile_aux_5_O_RESETN_P [get_bd_pins tile_aux_5/O_RESETN_P] [get_bd_pins xlconcat_7/In5]
  connect_bd_net -net tile_aux_5_O_TRIG [get_bd_pins tile_aux_5/O_TRIG] [get_bd_pins xlconcat_3/In5]
  connect_bd_net -net tile_aux_5_O_TRIG_N [get_bd_pins tile_aux_5/O_TRIG_N] [get_bd_pins xlconcat_5/In5]
  connect_bd_net -net tile_aux_5_O_TRIG_P [get_bd_pins tile_aux_5/O_TRIG_P] [get_bd_pins xlconcat_4/In5]
  connect_bd_net -net tile_aux_6_O_CLK [get_bd_pins tile_aux_6/O_CLK] [get_bd_pins xlconcat_0/In6]
  connect_bd_net -net tile_aux_6_O_CLK_N [get_bd_pins tile_aux_6/O_CLK_N] [get_bd_pins xlconcat_2/In6]
  connect_bd_net -net tile_aux_6_O_CLK_P [get_bd_pins tile_aux_6/O_CLK_P] [get_bd_pins xlconcat_1/In6]
  connect_bd_net -net tile_aux_6_O_RESETN [get_bd_pins tile_aux_6/O_RESETN] [get_bd_pins xlconcat_6/In6]
  connect_bd_net -net tile_aux_6_O_RESETN_N [get_bd_pins tile_aux_6/O_RESETN_N] [get_bd_pins xlconcat_8/In6]
  connect_bd_net -net tile_aux_6_O_RESETN_P [get_bd_pins tile_aux_6/O_RESETN_P] [get_bd_pins xlconcat_7/In6]
  connect_bd_net -net tile_aux_6_O_TRIG [get_bd_pins tile_aux_6/O_TRIG] [get_bd_pins xlconcat_3/In6]
  connect_bd_net -net tile_aux_6_O_TRIG_N [get_bd_pins tile_aux_6/O_TRIG_N] [get_bd_pins xlconcat_5/In6]
  connect_bd_net -net tile_aux_6_O_TRIG_P [get_bd_pins tile_aux_6/O_TRIG_P] [get_bd_pins xlconcat_4/In6]
  connect_bd_net -net tile_aux_7_O_CLK [get_bd_pins tile_aux_7/O_CLK] [get_bd_pins xlconcat_0/In7]
  connect_bd_net -net tile_aux_7_O_CLK_N [get_bd_pins tile_aux_7/O_CLK_N] [get_bd_pins xlconcat_2/In7]
  connect_bd_net -net tile_aux_7_O_CLK_P [get_bd_pins tile_aux_7/O_CLK_P] [get_bd_pins xlconcat_1/In7]
  connect_bd_net -net tile_aux_7_O_RESETN [get_bd_pins tile_aux_7/O_RESETN] [get_bd_pins xlconcat_6/In7]
  connect_bd_net -net tile_aux_7_O_RESETN_N [get_bd_pins tile_aux_7/O_RESETN_N] [get_bd_pins xlconcat_8/In7]
  connect_bd_net -net tile_aux_7_O_RESETN_P [get_bd_pins tile_aux_7/O_RESETN_P] [get_bd_pins xlconcat_7/In7]
  connect_bd_net -net tile_aux_7_O_TRIG [get_bd_pins tile_aux_7/O_TRIG] [get_bd_pins xlconcat_3/In7]
  connect_bd_net -net tile_aux_7_O_TRIG_N [get_bd_pins tile_aux_7/O_TRIG_N] [get_bd_pins xlconcat_5/In7]
  connect_bd_net -net tile_aux_7_O_TRIG_P [get_bd_pins tile_aux_7/O_TRIG_P] [get_bd_pins xlconcat_4/In7]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins O_CLK] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconcat_1_dout [get_bd_pins O_CLK_P] [get_bd_pins xlconcat_1/dout]
  connect_bd_net -net xlconcat_2_dout [get_bd_pins O_CLK_N] [get_bd_pins xlconcat_2/dout]
  connect_bd_net -net xlconcat_3_dout [get_bd_pins O_TRIG] [get_bd_pins xlconcat_3/dout]
  connect_bd_net -net xlconcat_4_dout [get_bd_pins O_TRIG_P] [get_bd_pins xlconcat_4/dout]
  connect_bd_net -net xlconcat_5_dout [get_bd_pins O_TRIG_N] [get_bd_pins xlconcat_5/dout]
  connect_bd_net -net xlconcat_6_dout [get_bd_pins O_RESETN] [get_bd_pins xlconcat_6/dout]
  connect_bd_net -net xlconcat_7_dout [get_bd_pins O_RESETN_P] [get_bd_pins xlconcat_7/dout]
  connect_bd_net -net xlconcat_8_dout [get_bd_pins O_RESETN_N] [get_bd_pins xlconcat_8/dout]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins tile_aux_0/TILE_EN] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net xlslice_10_Dout [get_bd_pins tile_aux_2/I_TRIG] [get_bd_pins xlslice_10/Dout]
  connect_bd_net -net xlslice_11_Dout [get_bd_pins tile_aux_3/I_TRIG] [get_bd_pins xlslice_11/Dout]
  connect_bd_net -net xlslice_12_Dout [get_bd_pins tile_aux_4/I_TRIG] [get_bd_pins xlslice_12/Dout]
  connect_bd_net -net xlslice_13_Dout [get_bd_pins tile_aux_5/I_TRIG] [get_bd_pins xlslice_13/Dout]
  connect_bd_net -net xlslice_14_Dout [get_bd_pins tile_aux_6/I_TRIG] [get_bd_pins xlslice_14/Dout]
  connect_bd_net -net xlslice_15_Dout [get_bd_pins tile_aux_7/I_TRIG] [get_bd_pins xlslice_15/Dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins tile_aux_1/TILE_EN] [get_bd_pins xlslice_1/Dout]
  connect_bd_net -net xlslice_2_Dout [get_bd_pins tile_aux_2/TILE_EN] [get_bd_pins xlslice_2/Dout]
  connect_bd_net -net xlslice_3_Dout [get_bd_pins tile_aux_3/TILE_EN] [get_bd_pins xlslice_3/Dout]
  connect_bd_net -net xlslice_4_Dout [get_bd_pins tile_aux_4/TILE_EN] [get_bd_pins xlslice_4/Dout]
  connect_bd_net -net xlslice_5_Dout [get_bd_pins tile_aux_5/TILE_EN] [get_bd_pins xlslice_5/Dout]
  connect_bd_net -net xlslice_6_Dout [get_bd_pins tile_aux_6/TILE_EN] [get_bd_pins xlslice_6/Dout]
  connect_bd_net -net xlslice_7_Dout [get_bd_pins tile_aux_7/TILE_EN] [get_bd_pins xlslice_7/Dout]
  connect_bd_net -net xlslice_8_Dout [get_bd_pins tile_aux_0/I_TRIG] [get_bd_pins xlslice_8/Dout]
  connect_bd_net -net xlslice_9_Dout [get_bd_pins tile_aux_1/I_TRIG] [get_bd_pins xlslice_9/Dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: dma
proc create_hier_cell_dma { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_dma() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_MM2S

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I ACLK
  create_bd_pin -dir I ARESETN

  # Create instance: axi_dma_0, and set properties
  set axi_dma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0 ]
  set_property -dict [ list \
   CONFIG.c_addr_width {32} \
   CONFIG.c_enable_multi_channel {0} \
   CONFIG.c_include_mm2s {1} \
   CONFIG.c_include_mm2s_dre {0} \
   CONFIG.c_include_sg {1} \
   CONFIG.c_m_axi_mm2s_data_width {128} \
   CONFIG.c_m_axis_mm2s_tdata_width {128} \
   CONFIG.c_micro_dma {0} \
   CONFIG.c_mm2s_burst_size {16} \
   CONFIG.c_s2mm_burst_size {32} \
   CONFIG.c_sg_include_stscntrl_strm {0} \
   CONFIG.c_sg_length_width {16} \
 ] $axi_dma_0

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {3} \
   CONFIG.S00_HAS_REGSLICE {1} \
   CONFIG.S01_HAS_REGSLICE {1} \
   CONFIG.S02_HAS_REGSLICE {1} \
 ] $axi_interconnect_0

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins axi_dma_0/M_AXI_SG] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] [get_bd_intf_pins axi_interconnect_0/S01_AXI]
  connect_bd_intf_net -intf_net S02_AXI_1 [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] [get_bd_intf_pins axi_interconnect_0/S02_AXI]
  connect_bd_intf_net -intf_net S_AXIS_S2MM_1 [get_bd_intf_pins S_AXIS_S2MM] [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net S_AXI_LITE_1 [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_dma_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXIS_MM2S [get_bd_intf_pins M_AXIS_MM2S] [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins M00_AXI] [get_bd_intf_pins axi_interconnect_0/M00_AXI]

  # Create port connections
  connect_bd_net -net ACLK_1 [get_bd_pins ACLK] [get_bd_pins axi_dma_0/m_axi_mm2s_aclk] [get_bd_pins axi_dma_0/m_axi_s2mm_aclk] [get_bd_pins axi_dma_0/m_axi_sg_aclk] [get_bd_pins axi_dma_0/s_axi_lite_aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins axi_interconnect_0/S02_ACLK]
  connect_bd_net -net ARESETN_1 [get_bd_pins ARESETN] [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins axi_interconnect_0/S02_ARESETN]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: data_tx
proc create_hier_cell_data_tx { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_data_tx() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M01_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M02_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M03_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M04_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M05_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M06_AXIS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M07_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS


  # Create pins
  create_bd_pin -dir I aclk
  create_bd_pin -dir I aresetn

  # Create instance: axis_broadcaster_0, and set properties
  set axis_broadcaster_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TREADY {1} \
   CONFIG.M00_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M01_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M02_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M03_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M04_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M05_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M06_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M07_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M08_TDATA_REMAP {tdata[127:0]} \
   CONFIG.M_TDATA_NUM_BYTES {16} \
   CONFIG.NUM_MI {8} \
   CONFIG.S_TDATA_NUM_BYTES {16} \
 ] $axis_broadcaster_0

  # Create instance: axis_register_slice_0, and set properties
  set axis_register_slice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_0 ]

  # Create instance: axis_register_slice_1, and set properties
  set axis_register_slice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_1 ]

  # Create instance: axis_register_slice_2, and set properties
  set axis_register_slice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_2 ]

  # Create instance: axis_register_slice_3, and set properties
  set axis_register_slice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_3 ]

  # Create instance: axis_register_slice_4, and set properties
  set axis_register_slice_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_4 ]

  # Create instance: axis_register_slice_5, and set properties
  set axis_register_slice_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_5 ]

  # Create instance: axis_register_slice_6, and set properties
  set axis_register_slice_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_6 ]

  # Create instance: axis_register_slice_7, and set properties
  set axis_register_slice_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_7 ]

  # Create instance: axis_subset_converter_0, and set properties
  set axis_subset_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIS_1 [get_bd_intf_pins S_AXIS] [get_bd_intf_pins axis_subset_converter_0/S_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M00_AXIS [get_bd_intf_pins axis_broadcaster_0/M00_AXIS] [get_bd_intf_pins axis_register_slice_0/S_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M01_AXIS [get_bd_intf_pins axis_broadcaster_0/M01_AXIS] [get_bd_intf_pins axis_register_slice_1/S_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M02_AXIS [get_bd_intf_pins axis_broadcaster_0/M02_AXIS] [get_bd_intf_pins axis_register_slice_2/S_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M03_AXIS [get_bd_intf_pins axis_broadcaster_0/M03_AXIS] [get_bd_intf_pins axis_register_slice_3/S_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M04_AXIS [get_bd_intf_pins axis_broadcaster_0/M04_AXIS] [get_bd_intf_pins axis_register_slice_4/S_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M05_AXIS [get_bd_intf_pins axis_broadcaster_0/M05_AXIS] [get_bd_intf_pins axis_register_slice_5/S_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M06_AXIS [get_bd_intf_pins axis_broadcaster_0/M06_AXIS] [get_bd_intf_pins axis_register_slice_6/S_AXIS]
  connect_bd_intf_net -intf_net axis_broadcaster_0_M07_AXIS [get_bd_intf_pins axis_broadcaster_0/M07_AXIS] [get_bd_intf_pins axis_register_slice_7/S_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_0_M_AXIS [get_bd_intf_pins M00_AXIS] [get_bd_intf_pins axis_register_slice_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_1_M_AXIS [get_bd_intf_pins M01_AXIS] [get_bd_intf_pins axis_register_slice_1/M_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_2_M_AXIS [get_bd_intf_pins M02_AXIS] [get_bd_intf_pins axis_register_slice_2/M_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_3_M_AXIS [get_bd_intf_pins M03_AXIS] [get_bd_intf_pins axis_register_slice_3/M_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_3_M_AXIS1 [get_bd_intf_pins M04_AXIS] [get_bd_intf_pins axis_register_slice_4/M_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_3_M_AXIS2 [get_bd_intf_pins M05_AXIS] [get_bd_intf_pins axis_register_slice_5/M_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_3_M_AXIS3 [get_bd_intf_pins M06_AXIS] [get_bd_intf_pins axis_register_slice_6/M_AXIS]
  connect_bd_intf_net -intf_net axis_register_slice_3_M_AXIS4 [get_bd_intf_pins M07_AXIS] [get_bd_intf_pins axis_register_slice_7/M_AXIS]
  connect_bd_intf_net -intf_net axis_subset_converter_0_M_AXIS [get_bd_intf_pins axis_broadcaster_0/S_AXIS] [get_bd_intf_pins axis_subset_converter_0/M_AXIS]

  # Create port connections
  connect_bd_net -net aclk_1 [get_bd_pins aclk] [get_bd_pins axis_broadcaster_0/aclk] [get_bd_pins axis_register_slice_0/aclk] [get_bd_pins axis_register_slice_1/aclk] [get_bd_pins axis_register_slice_2/aclk] [get_bd_pins axis_register_slice_3/aclk] [get_bd_pins axis_register_slice_4/aclk] [get_bd_pins axis_register_slice_5/aclk] [get_bd_pins axis_register_slice_6/aclk] [get_bd_pins axis_register_slice_7/aclk] [get_bd_pins axis_subset_converter_0/aclk]
  connect_bd_net -net aresetn_1 [get_bd_pins aresetn] [get_bd_pins axis_broadcaster_0/aresetn] [get_bd_pins axis_register_slice_0/aresetn] [get_bd_pins axis_register_slice_1/aresetn] [get_bd_pins axis_register_slice_2/aresetn] [get_bd_pins axis_register_slice_3/aresetn] [get_bd_pins axis_register_slice_4/aresetn] [get_bd_pins axis_register_slice_5/aresetn] [get_bd_pins axis_register_slice_6/aresetn] [get_bd_pins axis_register_slice_7/aresetn] [get_bd_pins axis_subset_converter_0/aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: data_rx
proc create_hier_cell_data_rx { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_data_rx() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S00_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S01_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S02_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S03_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S04_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S05_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S06_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S07_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S08_AXIS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S09_AXIS


  # Create pins
  create_bd_pin -dir I -type clk ACLK
  create_bd_pin -dir I -type rst ARESETN

  # Create instance: axis_interconnect_1, and set properties
  set axis_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_interconnect_1 ]
  set_property -dict [ list \
   CONFIG.ARB_ON_NUM_CYCLES {1} \
   CONFIG.ARB_ON_TLAST {1} \
   CONFIG.ENABLE_ADVANCED_OPTIONS {0} \
   CONFIG.M00_FIFO_DEPTH {4096} \
   CONFIG.M00_HAS_REGSLICE {0} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {10} \
   CONFIG.S00_FIFO_DEPTH {0} \
   CONFIG.S00_HAS_REGSLICE {0} \
   CONFIG.S01_FIFO_DEPTH {0} \
   CONFIG.S01_HAS_REGSLICE {0} \
   CONFIG.S02_FIFO_DEPTH {0} \
   CONFIG.S02_HAS_REGSLICE {0} \
   CONFIG.S03_FIFO_DEPTH {0} \
   CONFIG.S03_HAS_REGSLICE {0} \
   CONFIG.S04_FIFO_DEPTH {0} \
   CONFIG.S04_HAS_REGSLICE {0} \
   CONFIG.S05_FIFO_DEPTH {0} \
   CONFIG.S05_HAS_REGSLICE {0} \
   CONFIG.S06_FIFO_DEPTH {0} \
   CONFIG.S06_HAS_REGSLICE {0} \
   CONFIG.S07_FIFO_DEPTH {0} \
   CONFIG.S07_HAS_REGSLICE {0} \
   CONFIG.S08_FIFO_DEPTH {1024} \
   CONFIG.S08_HAS_REGSLICE {1} \
   CONFIG.S09_FIFO_DEPTH {1024} \
   CONFIG.S09_HAS_REGSLICE {1} \
   CONFIG.S10_FIFO_DEPTH {32} \
   CONFIG.S11_FIFO_DEPTH {32} \
   CONFIG.S12_FIFO_DEPTH {32} \
   CONFIG.S13_FIFO_DEPTH {32} \
   CONFIG.S14_FIFO_DEPTH {32} \
   CONFIG.S15_FIFO_DEPTH {32} \
 ] $axis_interconnect_1

  # Create interface connections
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins M00_AXIS] [get_bd_intf_pins axis_interconnect_1/M00_AXIS]
  connect_bd_intf_net -intf_net S00_AXIS_1 [get_bd_intf_pins S00_AXIS] [get_bd_intf_pins axis_interconnect_1/S00_AXIS]
  connect_bd_intf_net -intf_net S01_AXIS_1 [get_bd_intf_pins S01_AXIS] [get_bd_intf_pins axis_interconnect_1/S01_AXIS]
  connect_bd_intf_net -intf_net S02_AXIS_1 [get_bd_intf_pins S02_AXIS] [get_bd_intf_pins axis_interconnect_1/S02_AXIS]
  connect_bd_intf_net -intf_net S03_AXIS_1 [get_bd_intf_pins S03_AXIS] [get_bd_intf_pins axis_interconnect_1/S03_AXIS]
  connect_bd_intf_net -intf_net S04_AXIS_1 [get_bd_intf_pins S04_AXIS] [get_bd_intf_pins axis_interconnect_1/S04_AXIS]
  connect_bd_intf_net -intf_net S05_AXIS_1 [get_bd_intf_pins S05_AXIS] [get_bd_intf_pins axis_interconnect_1/S05_AXIS]
  connect_bd_intf_net -intf_net S06_AXIS_1 [get_bd_intf_pins S06_AXIS] [get_bd_intf_pins axis_interconnect_1/S06_AXIS]
  connect_bd_intf_net -intf_net S07_AXIS_1 [get_bd_intf_pins S07_AXIS] [get_bd_intf_pins axis_interconnect_1/S07_AXIS]
  connect_bd_intf_net -intf_net S08_AXIS_1 [get_bd_intf_pins S08_AXIS] [get_bd_intf_pins axis_interconnect_1/S08_AXIS]
  connect_bd_intf_net -intf_net S09_AXIS_1 [get_bd_intf_pins S09_AXIS] [get_bd_intf_pins axis_interconnect_1/S09_AXIS]

  # Create port connections
  connect_bd_net -net ACLK_1 [get_bd_pins ACLK] [get_bd_pins axis_interconnect_1/ACLK] [get_bd_pins axis_interconnect_1/M00_AXIS_ACLK] [get_bd_pins axis_interconnect_1/S00_AXIS_ACLK] [get_bd_pins axis_interconnect_1/S01_AXIS_ACLK] [get_bd_pins axis_interconnect_1/S02_AXIS_ACLK] [get_bd_pins axis_interconnect_1/S03_AXIS_ACLK] [get_bd_pins axis_interconnect_1/S04_AXIS_ACLK] [get_bd_pins axis_interconnect_1/S05_AXIS_ACLK] [get_bd_pins axis_interconnect_1/S06_AXIS_ACLK] [get_bd_pins axis_interconnect_1/S07_AXIS_ACLK] [get_bd_pins axis_interconnect_1/S08_AXIS_ACLK] [get_bd_pins axis_interconnect_1/S09_AXIS_ACLK]
  connect_bd_net -net ARESETN_1 [get_bd_pins ARESETN] [get_bd_pins axis_interconnect_1/ARESETN] [get_bd_pins axis_interconnect_1/M00_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/S00_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/S01_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/S02_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/S03_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/S04_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/S05_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/S06_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/S07_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/S08_AXIS_ARESETN] [get_bd_pins axis_interconnect_1/S09_AXIS_ARESETN]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: axi_lite_reg_space
proc create_hier_cell_axi_lite_reg_space { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_axi_lite_reg_space() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I S_AXI_LITE_ACLK
  create_bd_pin -dir I S_AXI_LITE_ARESETN
  create_bd_pin -dir O -from 0 -to 0 analog_pwr_en
  create_bd_pin -dir O -from 7 -to 0 tile_en

  # Create instance: analog_pwr_en, and set properties
  set analog_pwr_en [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 analog_pwr_en ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DOUT_WIDTH {1} \
 ] $analog_pwr_en

  # Create instance: axi_lite_reg_space_0, and set properties
  set block_name axi_lite_reg_space
  set block_cell_name axi_lite_reg_space_0
  if { [catch {set axi_lite_reg_space_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axi_lite_reg_space_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.C_RW_REG0_DEFAULT {0x00000000} \
   CONFIG.C_RW_REG1_DEFAULT {0x00000000} \
 ] $axi_lite_reg_space_0

  # Create instance: tile_en, and set properties
  set tile_en [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 tile_en ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {7} \
   CONFIG.DOUT_WIDTH {8} \
 ] $tile_en

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {32} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_LITE_1 [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_lite_reg_space_0/S_AXI_LITE]

  # Create port connections
  connect_bd_net -net S_AXI_LITE_ACLK_1 [get_bd_pins S_AXI_LITE_ACLK] [get_bd_pins axi_lite_reg_space_0/S_AXI_LITE_ACLK]
  connect_bd_net -net S_AXI_LITE_ARESETN_1 [get_bd_pins S_AXI_LITE_ARESETN] [get_bd_pins axi_lite_reg_space_0/S_AXI_LITE_ARESETN]
  connect_bd_net -net analog_pwr_en_Dout [get_bd_pins analog_pwr_en] [get_bd_pins analog_pwr_en/Dout]
  connect_bd_net -net axi_lite_reg_space_0_RW_REG0 [get_bd_pins axi_lite_reg_space_0/RW_REG0] [get_bd_pins tile_en/Din]
  connect_bd_net -net axi_lite_reg_space_0_RW_REG1 [get_bd_pins analog_pwr_en/Din] [get_bd_pins axi_lite_reg_space_0/RW_REG1]
  connect_bd_net -net tile_en_0_Dout [get_bd_pins tile_en] [get_bd_pins tile_en/Dout]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins axi_lite_reg_space_0/RO_REG0] [get_bd_pins axi_lite_reg_space_0/RO_REG1] [get_bd_pins axi_lite_reg_space_0/RO_REG2] [get_bd_pins axi_lite_reg_space_0/RO_REG3] [get_bd_pins xlconstant_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]

  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]


  # Create ports
  set ANALOG_PWR_EN [ create_bd_port -dir O -from 0 -to 0 ANALOG_PWR_EN ]
  set CLK [ create_bd_port -dir O CLK ]
  set HW_SYNC_TRIG [ create_bd_port -dir I HW_SYNC_TRIG ]
  set MISO_0 [ create_bd_port -dir I -from 31 -to 0 MISO_0 ]
  set MOSI_0 [ create_bd_port -dir O -from 31 -to 0 MOSI_0 ]
  set RESETN [ create_bd_port -dir O RESETN ]
  set TILE_EN [ create_bd_port -dir O -from 7 -to 0 TILE_EN ]
  set TRIG [ create_bd_port -dir O -from 7 -to 0 TRIG ]
  set TRIG1_IN [ create_bd_port -dir I TRIG1_IN ]
  set UART_RX_BUSY [ create_bd_port -dir O UART_RX_BUSY ]
  set UART_TX_BUSY [ create_bd_port -dir O UART_TX_BUSY ]

  # Create instance: axi_lite_reg_space
  create_hier_cell_axi_lite_reg_space [current_bd_instance .] axi_lite_reg_space

  # Create instance: data_rx
  create_hier_cell_data_rx [current_bd_instance .] data_rx

  # Create instance: data_tx
  create_hier_cell_data_tx [current_bd_instance .] data_tx

  # Create instance: dma
  create_hier_cell_dma [current_bd_instance .] dma

  # Create instance: io
  create_hier_cell_io [current_bd_instance .] io

  # Create instance: larpix_clk
  create_hier_cell_larpix_clk [current_bd_instance .] larpix_clk

  # Create instance: larpix_trig
  create_hier_cell_larpix_trig [current_bd_instance .] larpix_trig

  # Create instance: larpix_uart_array
  create_hier_cell_larpix_uart_array [current_bd_instance .] larpix_uart_array

  # Create instance: processing_system7_0, and set properties
  set processing_system7_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0 ]
  set_property -dict [ list \
   CONFIG.PCW_ACT_APU_PERIPHERAL_FREQMHZ {666.666687} \
   CONFIG.PCW_ACT_CAN0_PERIPHERAL_FREQMHZ {23.8095} \
   CONFIG.PCW_ACT_CAN1_PERIPHERAL_FREQMHZ {23.8095} \
   CONFIG.PCW_ACT_CAN_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_DCI_PERIPHERAL_FREQMHZ {10.158730} \
   CONFIG.PCW_ACT_ENET0_PERIPHERAL_FREQMHZ {125.000000} \
   CONFIG.PCW_ACT_ENET1_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_FPGA0_PERIPHERAL_FREQMHZ {100.000000} \
   CONFIG.PCW_ACT_FPGA1_PERIPHERAL_FREQMHZ {20.000000} \
   CONFIG.PCW_ACT_FPGA2_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_FPGA3_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_I2C_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_ACT_PCAP_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_QSPI_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_SDIO_PERIPHERAL_FREQMHZ {25.000000} \
   CONFIG.PCW_ACT_SMC_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_SPI_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_TPIU_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_TTC0_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC0_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC0_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC1_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC1_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC1_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_ACT_UART_PERIPHERAL_FREQMHZ {100.000000} \
   CONFIG.PCW_ACT_USB0_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_ACT_USB1_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_ACT_WDT_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_APU_CLK_RATIO_ENABLE {6:2:1} \
   CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {666.666666} \
   CONFIG.PCW_ARMPLL_CTRL_FBDIV {40} \
   CONFIG.PCW_CAN0_GRP_CLK_ENABLE {0} \
   CONFIG.PCW_CAN0_PERIPHERAL_CLKSRC {External} \
   CONFIG.PCW_CAN0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_CAN1_GRP_CLK_ENABLE {0} \
   CONFIG.PCW_CAN1_PERIPHERAL_CLKSRC {External} \
   CONFIG.PCW_CAN1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_CAN_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_CAN_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_CAN_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_CAN_PERIPHERAL_VALID {0} \
   CONFIG.PCW_CLK0_FREQ {100000000} \
   CONFIG.PCW_CLK1_FREQ {20000000} \
   CONFIG.PCW_CLK2_FREQ {10000000} \
   CONFIG.PCW_CLK3_FREQ {10000000} \
   CONFIG.PCW_CORE0_FIQ_INTR {0} \
   CONFIG.PCW_CORE0_IRQ_INTR {0} \
   CONFIG.PCW_CORE1_FIQ_INTR {0} \
   CONFIG.PCW_CORE1_IRQ_INTR {0} \
   CONFIG.PCW_CPU_CPU_6X4X_MAX_RANGE {667} \
   CONFIG.PCW_CPU_CPU_PLL_FREQMHZ {1333.333} \
   CONFIG.PCW_CPU_PERIPHERAL_CLKSRC {ARM PLL} \
   CONFIG.PCW_CPU_PERIPHERAL_DIVISOR0 {2} \
   CONFIG.PCW_CRYSTAL_PERIPHERAL_FREQMHZ {33.333333} \
   CONFIG.PCW_DCI_PERIPHERAL_CLKSRC {DDR PLL} \
   CONFIG.PCW_DCI_PERIPHERAL_DIVISOR0 {15} \
   CONFIG.PCW_DCI_PERIPHERAL_DIVISOR1 {7} \
   CONFIG.PCW_DCI_PERIPHERAL_FREQMHZ {10.159} \
   CONFIG.PCW_DDRPLL_CTRL_FBDIV {32} \
   CONFIG.PCW_DDR_DDR_PLL_FREQMHZ {1066.667} \
   CONFIG.PCW_DDR_HPRLPR_QUEUE_PARTITION {HPR(0)/LPR(32)} \
   CONFIG.PCW_DDR_HPR_TO_CRITICAL_PRIORITY_LEVEL {15} \
   CONFIG.PCW_DDR_LPR_TO_CRITICAL_PRIORITY_LEVEL {2} \
   CONFIG.PCW_DDR_PERIPHERAL_CLKSRC {DDR PLL} \
   CONFIG.PCW_DDR_PERIPHERAL_DIVISOR0 {2} \
   CONFIG.PCW_DDR_PORT0_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_PORT1_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_PORT2_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_PORT3_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_RAM_BASEADDR {0x00100000} \
   CONFIG.PCW_DDR_RAM_HIGHADDR {0x3FFFFFFF} \
   CONFIG.PCW_DDR_WRITE_TO_CRITICAL_PRIORITY_LEVEL {2} \
   CONFIG.PCW_DM_WIDTH {4} \
   CONFIG.PCW_DQS_WIDTH {4} \
   CONFIG.PCW_DQ_WIDTH {32} \
   CONFIG.PCW_ENET0_BASEADDR {0xE000B000} \
   CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} \
   CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} \
   CONFIG.PCW_ENET0_GRP_MDIO_IO {MIO 52 .. 53} \
   CONFIG.PCW_ENET0_HIGHADDR {0xE000BFFF} \
   CONFIG.PCW_ENET0_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR0 {8} \
   CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_ENET0_PERIPHERAL_FREQMHZ {1000 Mbps} \
   CONFIG.PCW_ENET0_RESET_ENABLE {0} \
   CONFIG.PCW_ENET1_GRP_MDIO_ENABLE {0} \
   CONFIG.PCW_ENET1_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_ENET1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_ENET1_PERIPHERAL_FREQMHZ {1000 Mbps} \
   CONFIG.PCW_ENET1_RESET_ENABLE {0} \
   CONFIG.PCW_ENET_RESET_ENABLE {1} \
   CONFIG.PCW_ENET_RESET_POLARITY {Active Low} \
   CONFIG.PCW_ENET_RESET_SELECT {Share reset pin} \
   CONFIG.PCW_EN_4K_TIMER {0} \
   CONFIG.PCW_EN_CAN0 {0} \
   CONFIG.PCW_EN_CAN1 {0} \
   CONFIG.PCW_EN_CLK0_PORT {1} \
   CONFIG.PCW_EN_CLK1_PORT {1} \
   CONFIG.PCW_EN_CLK2_PORT {0} \
   CONFIG.PCW_EN_CLK3_PORT {0} \
   CONFIG.PCW_EN_CLKTRIG0_PORT {0} \
   CONFIG.PCW_EN_CLKTRIG1_PORT {0} \
   CONFIG.PCW_EN_CLKTRIG2_PORT {0} \
   CONFIG.PCW_EN_CLKTRIG3_PORT {0} \
   CONFIG.PCW_EN_DDR {1} \
   CONFIG.PCW_EN_EMIO_CAN0 {0} \
   CONFIG.PCW_EN_EMIO_CAN1 {0} \
   CONFIG.PCW_EN_EMIO_CD_SDIO0 {0} \
   CONFIG.PCW_EN_EMIO_CD_SDIO1 {0} \
   CONFIG.PCW_EN_EMIO_ENET0 {0} \
   CONFIG.PCW_EN_EMIO_ENET1 {0} \
   CONFIG.PCW_EN_EMIO_GPIO {0} \
   CONFIG.PCW_EN_EMIO_I2C0 {0} \
   CONFIG.PCW_EN_EMIO_I2C1 {0} \
   CONFIG.PCW_EN_EMIO_MODEM_UART0 {0} \
   CONFIG.PCW_EN_EMIO_MODEM_UART1 {0} \
   CONFIG.PCW_EN_EMIO_PJTAG {0} \
   CONFIG.PCW_EN_EMIO_SDIO0 {0} \
   CONFIG.PCW_EN_EMIO_SDIO1 {0} \
   CONFIG.PCW_EN_EMIO_SPI0 {0} \
   CONFIG.PCW_EN_EMIO_SPI1 {0} \
   CONFIG.PCW_EN_EMIO_SRAM_INT {0} \
   CONFIG.PCW_EN_EMIO_TRACE {0} \
   CONFIG.PCW_EN_EMIO_TTC0 {0} \
   CONFIG.PCW_EN_EMIO_TTC1 {0} \
   CONFIG.PCW_EN_EMIO_UART0 {0} \
   CONFIG.PCW_EN_EMIO_UART1 {0} \
   CONFIG.PCW_EN_EMIO_WDT {0} \
   CONFIG.PCW_EN_EMIO_WP_SDIO0 {0} \
   CONFIG.PCW_EN_EMIO_WP_SDIO1 {0} \
   CONFIG.PCW_EN_ENET0 {1} \
   CONFIG.PCW_EN_ENET1 {0} \
   CONFIG.PCW_EN_GPIO {1} \
   CONFIG.PCW_EN_I2C0 {1} \
   CONFIG.PCW_EN_I2C1 {0} \
   CONFIG.PCW_EN_MODEM_UART0 {0} \
   CONFIG.PCW_EN_MODEM_UART1 {0} \
   CONFIG.PCW_EN_PJTAG {0} \
   CONFIG.PCW_EN_PTP_ENET0 {0} \
   CONFIG.PCW_EN_PTP_ENET1 {0} \
   CONFIG.PCW_EN_QSPI {1} \
   CONFIG.PCW_EN_RST0_PORT {1} \
   CONFIG.PCW_EN_RST1_PORT {0} \
   CONFIG.PCW_EN_RST2_PORT {0} \
   CONFIG.PCW_EN_RST3_PORT {0} \
   CONFIG.PCW_EN_SDIO0 {1} \
   CONFIG.PCW_EN_SDIO1 {1} \
   CONFIG.PCW_EN_SMC {0} \
   CONFIG.PCW_EN_SPI0 {0} \
   CONFIG.PCW_EN_SPI1 {0} \
   CONFIG.PCW_EN_TRACE {0} \
   CONFIG.PCW_EN_TTC0 {0} \
   CONFIG.PCW_EN_TTC1 {0} \
   CONFIG.PCW_EN_UART0 {1} \
   CONFIG.PCW_EN_UART1 {0} \
   CONFIG.PCW_EN_USB0 {0} \
   CONFIG.PCW_EN_USB1 {0} \
   CONFIG.PCW_EN_WDT {0} \
   CONFIG.PCW_FCLK0_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR0 {5} \
   CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR1 {2} \
   CONFIG.PCW_FCLK1_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR0 {10} \
   CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR1 {5} \
   CONFIG.PCW_FCLK2_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FCLK3_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FCLK_CLK0_BUF {TRUE} \
   CONFIG.PCW_FCLK_CLK1_BUF {TRUE} \
   CONFIG.PCW_FCLK_CLK2_BUF {FALSE} \
   CONFIG.PCW_FCLK_CLK3_BUF {FALSE} \
   CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {20} \
   CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
   CONFIG.PCW_FPGA_FCLK1_ENABLE {1} \
   CONFIG.PCW_FPGA_FCLK2_ENABLE {0} \
   CONFIG.PCW_FPGA_FCLK3_ENABLE {0} \
   CONFIG.PCW_GP0_EN_MODIFIABLE_TXN {1} \
   CONFIG.PCW_GP0_NUM_READ_THREADS {4} \
   CONFIG.PCW_GP0_NUM_WRITE_THREADS {4} \
   CONFIG.PCW_GP1_EN_MODIFIABLE_TXN {1} \
   CONFIG.PCW_GP1_NUM_READ_THREADS {4} \
   CONFIG.PCW_GP1_NUM_WRITE_THREADS {4} \
   CONFIG.PCW_GPIO_BASEADDR {0xE000A000} \
   CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {0} \
   CONFIG.PCW_GPIO_HIGHADDR {0xE000AFFF} \
   CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {1} \
   CONFIG.PCW_GPIO_MIO_GPIO_IO {MIO} \
   CONFIG.PCW_GPIO_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_I2C0_BASEADDR {0xE0004000} \
   CONFIG.PCW_I2C0_GRP_INT_ENABLE {0} \
   CONFIG.PCW_I2C0_HIGHADDR {0xE0004FFF} \
   CONFIG.PCW_I2C0_I2C0_IO {MIO 10 .. 11} \
   CONFIG.PCW_I2C0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_I2C0_RESET_ENABLE {0} \
   CONFIG.PCW_I2C1_GRP_INT_ENABLE {0} \
   CONFIG.PCW_I2C1_GRP_INT_IO {<Select>} \
   CONFIG.PCW_I2C1_I2C1_IO {<Select>} \
   CONFIG.PCW_I2C1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_I2C1_RESET_ENABLE {0} \
   CONFIG.PCW_I2C_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_I2C_RESET_ENABLE {1} \
   CONFIG.PCW_I2C_RESET_POLARITY {Active Low} \
   CONFIG.PCW_I2C_RESET_SELECT {Share reset pin} \
   CONFIG.PCW_IMPORT_BOARD_PRESET {None} \
   CONFIG.PCW_INCLUDE_ACP_TRANS_CHECK {0} \
   CONFIG.PCW_IOPLL_CTRL_FBDIV {30} \
   CONFIG.PCW_IO_IO_PLL_FREQMHZ {1000.000} \
   CONFIG.PCW_IRQ_F2P_INTR {1} \
   CONFIG.PCW_IRQ_F2P_MODE {DIRECT} \
   CONFIG.PCW_MIO_0_DIRECTION {inout} \
   CONFIG.PCW_MIO_0_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_0_PULLUP {enabled} \
   CONFIG.PCW_MIO_0_SLEW {slow} \
   CONFIG.PCW_MIO_10_DIRECTION {inout} \
   CONFIG.PCW_MIO_10_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_10_PULLUP {enabled} \
   CONFIG.PCW_MIO_10_SLEW {slow} \
   CONFIG.PCW_MIO_11_DIRECTION {inout} \
   CONFIG.PCW_MIO_11_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_11_PULLUP {enabled} \
   CONFIG.PCW_MIO_11_SLEW {slow} \
   CONFIG.PCW_MIO_12_DIRECTION {inout} \
   CONFIG.PCW_MIO_12_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_12_PULLUP {enabled} \
   CONFIG.PCW_MIO_12_SLEW {slow} \
   CONFIG.PCW_MIO_13_DIRECTION {inout} \
   CONFIG.PCW_MIO_13_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_13_PULLUP {enabled} \
   CONFIG.PCW_MIO_13_SLEW {slow} \
   CONFIG.PCW_MIO_14_DIRECTION {in} \
   CONFIG.PCW_MIO_14_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_14_PULLUP {enabled} \
   CONFIG.PCW_MIO_14_SLEW {slow} \
   CONFIG.PCW_MIO_15_DIRECTION {out} \
   CONFIG.PCW_MIO_15_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_15_PULLUP {enabled} \
   CONFIG.PCW_MIO_15_SLEW {slow} \
   CONFIG.PCW_MIO_16_DIRECTION {out} \
   CONFIG.PCW_MIO_16_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_16_PULLUP {enabled} \
   CONFIG.PCW_MIO_16_SLEW {slow} \
   CONFIG.PCW_MIO_17_DIRECTION {out} \
   CONFIG.PCW_MIO_17_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_17_PULLUP {enabled} \
   CONFIG.PCW_MIO_17_SLEW {slow} \
   CONFIG.PCW_MIO_18_DIRECTION {out} \
   CONFIG.PCW_MIO_18_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_18_PULLUP {enabled} \
   CONFIG.PCW_MIO_18_SLEW {slow} \
   CONFIG.PCW_MIO_19_DIRECTION {out} \
   CONFIG.PCW_MIO_19_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_19_PULLUP {enabled} \
   CONFIG.PCW_MIO_19_SLEW {slow} \
   CONFIG.PCW_MIO_1_DIRECTION {out} \
   CONFIG.PCW_MIO_1_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_1_PULLUP {enabled} \
   CONFIG.PCW_MIO_1_SLEW {slow} \
   CONFIG.PCW_MIO_20_DIRECTION {out} \
   CONFIG.PCW_MIO_20_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_20_PULLUP {enabled} \
   CONFIG.PCW_MIO_20_SLEW {slow} \
   CONFIG.PCW_MIO_21_DIRECTION {out} \
   CONFIG.PCW_MIO_21_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_21_PULLUP {enabled} \
   CONFIG.PCW_MIO_21_SLEW {slow} \
   CONFIG.PCW_MIO_22_DIRECTION {in} \
   CONFIG.PCW_MIO_22_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_22_PULLUP {enabled} \
   CONFIG.PCW_MIO_22_SLEW {slow} \
   CONFIG.PCW_MIO_23_DIRECTION {in} \
   CONFIG.PCW_MIO_23_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_23_PULLUP {enabled} \
   CONFIG.PCW_MIO_23_SLEW {slow} \
   CONFIG.PCW_MIO_24_DIRECTION {in} \
   CONFIG.PCW_MIO_24_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_24_PULLUP {enabled} \
   CONFIG.PCW_MIO_24_SLEW {slow} \
   CONFIG.PCW_MIO_25_DIRECTION {in} \
   CONFIG.PCW_MIO_25_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_25_PULLUP {enabled} \
   CONFIG.PCW_MIO_25_SLEW {slow} \
   CONFIG.PCW_MIO_26_DIRECTION {in} \
   CONFIG.PCW_MIO_26_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_26_PULLUP {enabled} \
   CONFIG.PCW_MIO_26_SLEW {slow} \
   CONFIG.PCW_MIO_27_DIRECTION {in} \
   CONFIG.PCW_MIO_27_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_27_PULLUP {enabled} \
   CONFIG.PCW_MIO_27_SLEW {slow} \
   CONFIG.PCW_MIO_28_DIRECTION {inout} \
   CONFIG.PCW_MIO_28_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_28_PULLUP {enabled} \
   CONFIG.PCW_MIO_28_SLEW {slow} \
   CONFIG.PCW_MIO_29_DIRECTION {inout} \
   CONFIG.PCW_MIO_29_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_29_PULLUP {enabled} \
   CONFIG.PCW_MIO_29_SLEW {slow} \
   CONFIG.PCW_MIO_2_DIRECTION {inout} \
   CONFIG.PCW_MIO_2_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_2_PULLUP {disabled} \
   CONFIG.PCW_MIO_2_SLEW {slow} \
   CONFIG.PCW_MIO_30_DIRECTION {inout} \
   CONFIG.PCW_MIO_30_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_30_PULLUP {enabled} \
   CONFIG.PCW_MIO_30_SLEW {slow} \
   CONFIG.PCW_MIO_31_DIRECTION {inout} \
   CONFIG.PCW_MIO_31_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_31_PULLUP {enabled} \
   CONFIG.PCW_MIO_31_SLEW {slow} \
   CONFIG.PCW_MIO_32_DIRECTION {inout} \
   CONFIG.PCW_MIO_32_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_32_PULLUP {enabled} \
   CONFIG.PCW_MIO_32_SLEW {slow} \
   CONFIG.PCW_MIO_33_DIRECTION {inout} \
   CONFIG.PCW_MIO_33_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_33_PULLUP {enabled} \
   CONFIG.PCW_MIO_33_SLEW {slow} \
   CONFIG.PCW_MIO_34_DIRECTION {inout} \
   CONFIG.PCW_MIO_34_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_34_PULLUP {enabled} \
   CONFIG.PCW_MIO_34_SLEW {slow} \
   CONFIG.PCW_MIO_35_DIRECTION {inout} \
   CONFIG.PCW_MIO_35_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_35_PULLUP {enabled} \
   CONFIG.PCW_MIO_35_SLEW {slow} \
   CONFIG.PCW_MIO_36_DIRECTION {inout} \
   CONFIG.PCW_MIO_36_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_36_PULLUP {enabled} \
   CONFIG.PCW_MIO_36_SLEW {slow} \
   CONFIG.PCW_MIO_37_DIRECTION {inout} \
   CONFIG.PCW_MIO_37_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_37_PULLUP {enabled} \
   CONFIG.PCW_MIO_37_SLEW {slow} \
   CONFIG.PCW_MIO_38_DIRECTION {inout} \
   CONFIG.PCW_MIO_38_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_38_PULLUP {enabled} \
   CONFIG.PCW_MIO_38_SLEW {slow} \
   CONFIG.PCW_MIO_39_DIRECTION {inout} \
   CONFIG.PCW_MIO_39_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_39_PULLUP {enabled} \
   CONFIG.PCW_MIO_39_SLEW {slow} \
   CONFIG.PCW_MIO_3_DIRECTION {inout} \
   CONFIG.PCW_MIO_3_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_3_PULLUP {disabled} \
   CONFIG.PCW_MIO_3_SLEW {slow} \
   CONFIG.PCW_MIO_40_DIRECTION {inout} \
   CONFIG.PCW_MIO_40_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_40_PULLUP {disabled} \
   CONFIG.PCW_MIO_40_SLEW {slow} \
   CONFIG.PCW_MIO_41_DIRECTION {inout} \
   CONFIG.PCW_MIO_41_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_41_PULLUP {disabled} \
   CONFIG.PCW_MIO_41_SLEW {slow} \
   CONFIG.PCW_MIO_42_DIRECTION {inout} \
   CONFIG.PCW_MIO_42_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_42_PULLUP {disabled} \
   CONFIG.PCW_MIO_42_SLEW {slow} \
   CONFIG.PCW_MIO_43_DIRECTION {inout} \
   CONFIG.PCW_MIO_43_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_43_PULLUP {disabled} \
   CONFIG.PCW_MIO_43_SLEW {slow} \
   CONFIG.PCW_MIO_44_DIRECTION {inout} \
   CONFIG.PCW_MIO_44_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_44_PULLUP {disabled} \
   CONFIG.PCW_MIO_44_SLEW {slow} \
   CONFIG.PCW_MIO_45_DIRECTION {inout} \
   CONFIG.PCW_MIO_45_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_45_PULLUP {disabled} \
   CONFIG.PCW_MIO_45_SLEW {slow} \
   CONFIG.PCW_MIO_46_DIRECTION {inout} \
   CONFIG.PCW_MIO_46_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_46_PULLUP {enabled} \
   CONFIG.PCW_MIO_46_SLEW {slow} \
   CONFIG.PCW_MIO_47_DIRECTION {inout} \
   CONFIG.PCW_MIO_47_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_47_PULLUP {enabled} \
   CONFIG.PCW_MIO_47_SLEW {slow} \
   CONFIG.PCW_MIO_48_DIRECTION {inout} \
   CONFIG.PCW_MIO_48_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_48_PULLUP {enabled} \
   CONFIG.PCW_MIO_48_SLEW {slow} \
   CONFIG.PCW_MIO_49_DIRECTION {inout} \
   CONFIG.PCW_MIO_49_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_49_PULLUP {enabled} \
   CONFIG.PCW_MIO_49_SLEW {slow} \
   CONFIG.PCW_MIO_4_DIRECTION {inout} \
   CONFIG.PCW_MIO_4_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_4_PULLUP {disabled} \
   CONFIG.PCW_MIO_4_SLEW {slow} \
   CONFIG.PCW_MIO_50_DIRECTION {inout} \
   CONFIG.PCW_MIO_50_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_50_PULLUP {enabled} \
   CONFIG.PCW_MIO_50_SLEW {slow} \
   CONFIG.PCW_MIO_51_DIRECTION {inout} \
   CONFIG.PCW_MIO_51_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_51_PULLUP {enabled} \
   CONFIG.PCW_MIO_51_SLEW {slow} \
   CONFIG.PCW_MIO_52_DIRECTION {out} \
   CONFIG.PCW_MIO_52_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_52_PULLUP {enabled} \
   CONFIG.PCW_MIO_52_SLEW {slow} \
   CONFIG.PCW_MIO_53_DIRECTION {inout} \
   CONFIG.PCW_MIO_53_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_53_PULLUP {enabled} \
   CONFIG.PCW_MIO_53_SLEW {slow} \
   CONFIG.PCW_MIO_5_DIRECTION {inout} \
   CONFIG.PCW_MIO_5_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_5_PULLUP {disabled} \
   CONFIG.PCW_MIO_5_SLEW {slow} \
   CONFIG.PCW_MIO_6_DIRECTION {out} \
   CONFIG.PCW_MIO_6_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_6_PULLUP {disabled} \
   CONFIG.PCW_MIO_6_SLEW {slow} \
   CONFIG.PCW_MIO_7_DIRECTION {out} \
   CONFIG.PCW_MIO_7_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_7_PULLUP {disabled} \
   CONFIG.PCW_MIO_7_SLEW {slow} \
   CONFIG.PCW_MIO_8_DIRECTION {out} \
   CONFIG.PCW_MIO_8_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_8_PULLUP {disabled} \
   CONFIG.PCW_MIO_8_SLEW {slow} \
   CONFIG.PCW_MIO_9_DIRECTION {inout} \
   CONFIG.PCW_MIO_9_IOTYPE {LVCMOS 3.3V} \
   CONFIG.PCW_MIO_9_PULLUP {enabled} \
   CONFIG.PCW_MIO_9_SLEW {slow} \
   CONFIG.PCW_MIO_PRIMITIVE {54} \
   CONFIG.PCW_MIO_TREE_PERIPHERALS {GPIO#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#GPIO#Quad SPI Flash#GPIO#I2C 0#I2C 0#GPIO#GPIO#UART 0#UART 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 1#SD 1#SD 1#SD 1#SD 1#SD 1#Enet 0#Enet 0} \
   CONFIG.PCW_MIO_TREE_SIGNALS {gpio[0]#qspi0_ss_b#qspi0_io[0]#qspi0_io[1]#qspi0_io[2]#qspi0_io[3]/HOLD_B#qspi0_sclk#gpio[7]#qspi_fbclk#gpio[9]#scl#sda#gpio[12]#gpio[13]#rx#tx#tx_clk#txd[0]#txd[1]#txd[2]#txd[3]#tx_ctl#rx_clk#rxd[0]#rxd[1]#rxd[2]#rxd[3]#rx_ctl#gpio[28]#gpio[29]#gpio[30]#gpio[31]#gpio[32]#gpio[33]#gpio[34]#gpio[35]#gpio[36]#gpio[37]#gpio[38]#gpio[39]#clk#cmd#data[0]#data[1]#data[2]#data[3]#data[0]#cmd#clk#data[1]#data[2]#data[3]#mdc#mdio} \
   CONFIG.PCW_M_AXI_GP0_ENABLE_STATIC_REMAP {0} \
   CONFIG.PCW_M_AXI_GP0_ID_WIDTH {12} \
   CONFIG.PCW_M_AXI_GP0_SUPPORT_NARROW_BURST {0} \
   CONFIG.PCW_M_AXI_GP0_THREAD_ID_WIDTH {12} \
   CONFIG.PCW_NAND_CYCLES_T_AR {1} \
   CONFIG.PCW_NAND_CYCLES_T_CLR {1} \
   CONFIG.PCW_NAND_CYCLES_T_RC {11} \
   CONFIG.PCW_NAND_CYCLES_T_REA {1} \
   CONFIG.PCW_NAND_CYCLES_T_RR {1} \
   CONFIG.PCW_NAND_CYCLES_T_WC {11} \
   CONFIG.PCW_NAND_CYCLES_T_WP {1} \
   CONFIG.PCW_NAND_GRP_D8_ENABLE {0} \
   CONFIG.PCW_NAND_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_NOR_CS0_T_CEOE {1} \
   CONFIG.PCW_NOR_CS0_T_PC {1} \
   CONFIG.PCW_NOR_CS0_T_RC {11} \
   CONFIG.PCW_NOR_CS0_T_TR {1} \
   CONFIG.PCW_NOR_CS0_T_WC {11} \
   CONFIG.PCW_NOR_CS0_T_WP {1} \
   CONFIG.PCW_NOR_CS0_WE_TIME {0} \
   CONFIG.PCW_NOR_CS1_T_CEOE {1} \
   CONFIG.PCW_NOR_CS1_T_PC {1} \
   CONFIG.PCW_NOR_CS1_T_RC {11} \
   CONFIG.PCW_NOR_CS1_T_TR {1} \
   CONFIG.PCW_NOR_CS1_T_WC {11} \
   CONFIG.PCW_NOR_CS1_T_WP {1} \
   CONFIG.PCW_NOR_CS1_WE_TIME {0} \
   CONFIG.PCW_NOR_GRP_A25_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_CS0_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_CS1_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_CS0_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_CS1_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_INT_ENABLE {0} \
   CONFIG.PCW_NOR_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_NOR_SRAM_CS0_T_CEOE {1} \
   CONFIG.PCW_NOR_SRAM_CS0_T_PC {1} \
   CONFIG.PCW_NOR_SRAM_CS0_T_RC {11} \
   CONFIG.PCW_NOR_SRAM_CS0_T_TR {1} \
   CONFIG.PCW_NOR_SRAM_CS0_T_WC {11} \
   CONFIG.PCW_NOR_SRAM_CS0_T_WP {1} \
   CONFIG.PCW_NOR_SRAM_CS0_WE_TIME {0} \
   CONFIG.PCW_NOR_SRAM_CS1_T_CEOE {1} \
   CONFIG.PCW_NOR_SRAM_CS1_T_PC {1} \
   CONFIG.PCW_NOR_SRAM_CS1_T_RC {11} \
   CONFIG.PCW_NOR_SRAM_CS1_T_TR {1} \
   CONFIG.PCW_NOR_SRAM_CS1_T_WC {11} \
   CONFIG.PCW_NOR_SRAM_CS1_T_WP {1} \
   CONFIG.PCW_NOR_SRAM_CS1_WE_TIME {0} \
   CONFIG.PCW_OVERRIDE_BASIC_CLOCK {0} \
   CONFIG.PCW_P2F_ENET0_INTR {0} \
   CONFIG.PCW_P2F_GPIO_INTR {0} \
   CONFIG.PCW_P2F_I2C0_INTR {0} \
   CONFIG.PCW_P2F_QSPI_INTR {0} \
   CONFIG.PCW_P2F_SDIO0_INTR {0} \
   CONFIG.PCW_P2F_UART0_INTR {0} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY0 {0.063} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY1 {0.062} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY2 {0.065} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY3 {0.083} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_0 {-0.007} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_1 {-0.010} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_2 {-0.006} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_3 {-0.048} \
   CONFIG.PCW_PACKAGE_NAME {clg484} \
   CONFIG.PCW_PCAP_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_PCAP_PERIPHERAL_DIVISOR0 {5} \
   CONFIG.PCW_PCAP_PERIPHERAL_FREQMHZ {200} \
   CONFIG.PCW_PERIPHERAL_BOARD_PRESET {None} \
   CONFIG.PCW_PJTAG_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_PLL_BYPASSMODE_ENABLE {0} \
   CONFIG.PCW_PRESET_BANK0_VOLTAGE {LVCMOS 3.3V} \
   CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
   CONFIG.PCW_PS7_SI_REV {PRODUCTION} \
   CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {1} \
   CONFIG.PCW_QSPI_GRP_FBCLK_IO {MIO 8} \
   CONFIG.PCW_QSPI_GRP_IO1_ENABLE {0} \
   CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} \
   CONFIG.PCW_QSPI_GRP_SINGLE_SS_IO {MIO 1 .. 6} \
   CONFIG.PCW_QSPI_GRP_SS1_ENABLE {0} \
   CONFIG.PCW_QSPI_INTERNAL_HIGHADDRESS {0xFCFFFFFF} \
   CONFIG.PCW_QSPI_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_QSPI_PERIPHERAL_DIVISOR0 {5} \
   CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_QSPI_PERIPHERAL_FREQMHZ {200} \
   CONFIG.PCW_QSPI_QSPI_IO {MIO 1 .. 6} \
   CONFIG.PCW_SD0_GRP_CD_ENABLE {0} \
   CONFIG.PCW_SD0_GRP_POW_ENABLE {0} \
   CONFIG.PCW_SD0_GRP_WP_ENABLE {0} \
   CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_SD0_SD0_IO {MIO 40 .. 45} \
   CONFIG.PCW_SD1_GRP_CD_ENABLE {0} \
   CONFIG.PCW_SD1_GRP_POW_ENABLE {0} \
   CONFIG.PCW_SD1_GRP_WP_ENABLE {0} \
   CONFIG.PCW_SD1_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_SD1_SD1_IO {MIO 46 .. 51} \
   CONFIG.PCW_SDIO0_BASEADDR {0xE0100000} \
   CONFIG.PCW_SDIO0_HIGHADDR {0xE0100FFF} \
   CONFIG.PCW_SDIO_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_SDIO_PERIPHERAL_DIVISOR0 {40} \
   CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {25} \
   CONFIG.PCW_SDIO_PERIPHERAL_VALID {1} \
   CONFIG.PCW_SINGLE_QSPI_DATA_MODE {x4} \
   CONFIG.PCW_SMC_CYCLE_T0 {NA} \
   CONFIG.PCW_SMC_CYCLE_T1 {NA} \
   CONFIG.PCW_SMC_CYCLE_T2 {NA} \
   CONFIG.PCW_SMC_CYCLE_T3 {NA} \
   CONFIG.PCW_SMC_CYCLE_T4 {NA} \
   CONFIG.PCW_SMC_CYCLE_T5 {NA} \
   CONFIG.PCW_SMC_CYCLE_T6 {NA} \
   CONFIG.PCW_SMC_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_SMC_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_SMC_PERIPHERAL_VALID {0} \
   CONFIG.PCW_SPI0_GRP_SS0_ENABLE {0} \
   CONFIG.PCW_SPI0_GRP_SS1_ENABLE {0} \
   CONFIG.PCW_SPI0_GRP_SS2_ENABLE {0} \
   CONFIG.PCW_SPI0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_SPI1_GRP_SS0_ENABLE {0} \
   CONFIG.PCW_SPI1_GRP_SS1_ENABLE {0} \
   CONFIG.PCW_SPI1_GRP_SS2_ENABLE {0} \
   CONFIG.PCW_SPI1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_SPI_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_SPI_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_SPI_PERIPHERAL_VALID {0} \
   CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {64} \
   CONFIG.PCW_S_AXI_HP0_ID_WIDTH {6} \
   CONFIG.PCW_TPIU_PERIPHERAL_CLKSRC {External} \
   CONFIG.PCW_TPIU_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TPIU_PERIPHERAL_FREQMHZ {200} \
   CONFIG.PCW_TRACE_GRP_16BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_2BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_32BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_4BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_8BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_INTERNAL_WIDTH {2} \
   CONFIG.PCW_TRACE_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_TTC0_CLK0_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC0_CLK0_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC0_CLK0_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC0_CLK1_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC0_CLK1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC0_CLK1_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC0_CLK2_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC0_CLK2_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC0_CLK2_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_TTC1_CLK0_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC1_CLK0_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC1_CLK0_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC1_CLK1_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC1_CLK1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC1_CLK1_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC1_CLK2_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC1_CLK2_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC1_CLK2_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_UART0_BASEADDR {0xE0000000} \
   CONFIG.PCW_UART0_BAUD_RATE {115200} \
   CONFIG.PCW_UART0_GRP_FULL_ENABLE {0} \
   CONFIG.PCW_UART0_HIGHADDR {0xE0000FFF} \
   CONFIG.PCW_UART0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_UART0_UART0_IO {MIO 14 .. 15} \
   CONFIG.PCW_UART1_GRP_FULL_ENABLE {0} \
   CONFIG.PCW_UART1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_UART_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_UART_PERIPHERAL_DIVISOR0 {10} \
   CONFIG.PCW_UART_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_UART_PERIPHERAL_VALID {1} \
   CONFIG.PCW_UIPARAM_ACT_DDR_FREQ_MHZ {533.333374} \
   CONFIG.PCW_UIPARAM_DDR_ADV_ENABLE {0} \
   CONFIG.PCW_UIPARAM_DDR_AL {0} \
   CONFIG.PCW_UIPARAM_DDR_BANK_ADDR_COUNT {3} \
   CONFIG.PCW_UIPARAM_DDR_BL {8} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY0 {0.25} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY1 {0.25} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY2 {0.25} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY3 {0.25} \
   CONFIG.PCW_UIPARAM_DDR_BUS_WIDTH {32 Bit} \
   CONFIG.PCW_UIPARAM_DDR_CL {7} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_0_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_0_PACKAGE_LENGTH {61.0905} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_0_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_1_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_1_PACKAGE_LENGTH {61.0905} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_1_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_2_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_2_PACKAGE_LENGTH {61.0905} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_2_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_3_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_3_PACKAGE_LENGTH {61.0905} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_3_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_STOP_EN {0} \
   CONFIG.PCW_UIPARAM_DDR_COL_ADDR_COUNT {10} \
   CONFIG.PCW_UIPARAM_DDR_CWL {6} \
   CONFIG.PCW_UIPARAM_DDR_DEVICE_CAPACITY {4096 MBits} \
   CONFIG.PCW_UIPARAM_DDR_DQS_0_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_0_PACKAGE_LENGTH {68.4725} \
   CONFIG.PCW_UIPARAM_DDR_DQS_0_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_1_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_1_PACKAGE_LENGTH {71.086} \
   CONFIG.PCW_UIPARAM_DDR_DQS_1_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_2_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_2_PACKAGE_LENGTH {66.794} \
   CONFIG.PCW_UIPARAM_DDR_DQS_2_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_3_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_3_PACKAGE_LENGTH {108.7385} \
   CONFIG.PCW_UIPARAM_DDR_DQS_3_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_2 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_3 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_0_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_0_PACKAGE_LENGTH {64.1705} \
   CONFIG.PCW_UIPARAM_DDR_DQ_0_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQ_1_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_1_PACKAGE_LENGTH {63.686} \
   CONFIG.PCW_UIPARAM_DDR_DQ_1_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQ_2_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_2_PACKAGE_LENGTH {68.46} \
   CONFIG.PCW_UIPARAM_DDR_DQ_2_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQ_3_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_3_PACKAGE_LENGTH {105.4895} \
   CONFIG.PCW_UIPARAM_DDR_DQ_3_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DRAM_WIDTH {16 Bits} \
   CONFIG.PCW_UIPARAM_DDR_ECC {Disabled} \
   CONFIG.PCW_UIPARAM_DDR_ENABLE {1} \
   CONFIG.PCW_UIPARAM_DDR_FREQ_MHZ {533.333333} \
   CONFIG.PCW_UIPARAM_DDR_HIGH_TEMP {Normal (0-85)} \
   CONFIG.PCW_UIPARAM_DDR_MEMORY_TYPE {DDR 3} \
   CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41J256M16 RE-125} \
   CONFIG.PCW_UIPARAM_DDR_ROW_ADDR_COUNT {15} \
   CONFIG.PCW_UIPARAM_DDR_SPEED_BIN {DDR3_1066F} \
   CONFIG.PCW_UIPARAM_DDR_TRAIN_DATA_EYE {1} \
   CONFIG.PCW_UIPARAM_DDR_TRAIN_READ_GATE {1} \
   CONFIG.PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL {1} \
   CONFIG.PCW_UIPARAM_DDR_T_FAW {40.0} \
   CONFIG.PCW_UIPARAM_DDR_T_RAS_MIN {35.0} \
   CONFIG.PCW_UIPARAM_DDR_T_RC {48.91} \
   CONFIG.PCW_UIPARAM_DDR_T_RCD {7} \
   CONFIG.PCW_UIPARAM_DDR_T_RP {7} \
   CONFIG.PCW_UIPARAM_DDR_USE_INTERNAL_VREF {0} \
   CONFIG.PCW_UIPARAM_GENERATE_SUMMARY {NA} \
   CONFIG.PCW_USB0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_USB0_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_USB0_RESET_ENABLE {0} \
   CONFIG.PCW_USB1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_USB1_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_USB1_RESET_ENABLE {0} \
   CONFIG.PCW_USB_RESET_ENABLE {1} \
   CONFIG.PCW_USB_RESET_POLARITY {Active Low} \
   CONFIG.PCW_USE_AXI_FABRIC_IDLE {0} \
   CONFIG.PCW_USE_AXI_NONSECURE {0} \
   CONFIG.PCW_USE_CORESIGHT {0} \
   CONFIG.PCW_USE_CROSS_TRIGGER {0} \
   CONFIG.PCW_USE_CR_FABRIC {1} \
   CONFIG.PCW_USE_DDR_BYPASS {0} \
   CONFIG.PCW_USE_DEBUG {0} \
   CONFIG.PCW_USE_DMA0 {0} \
   CONFIG.PCW_USE_DMA1 {0} \
   CONFIG.PCW_USE_DMA2 {0} \
   CONFIG.PCW_USE_DMA3 {0} \
   CONFIG.PCW_USE_EXPANDED_IOP {0} \
   CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
   CONFIG.PCW_USE_HIGH_OCM {0} \
   CONFIG.PCW_USE_M_AXI_GP0 {1} \
   CONFIG.PCW_USE_M_AXI_GP1 {0} \
   CONFIG.PCW_USE_PROC_EVENT_BUS {0} \
   CONFIG.PCW_USE_PS_SLCR_REGISTERS {0} \
   CONFIG.PCW_USE_S_AXI_ACP {0} \
   CONFIG.PCW_USE_S_AXI_GP0 {0} \
   CONFIG.PCW_USE_S_AXI_GP1 {0} \
   CONFIG.PCW_USE_S_AXI_HP0 {1} \
   CONFIG.PCW_USE_S_AXI_HP1 {0} \
   CONFIG.PCW_USE_S_AXI_HP2 {0} \
   CONFIG.PCW_USE_S_AXI_HP3 {0} \
   CONFIG.PCW_USE_TRACE {0} \
   CONFIG.PCW_VALUE_SILVERSION {3} \
   CONFIG.PCW_WDT_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_WDT_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_WDT_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_WDT_PERIPHERAL_FREQMHZ {133.333333} \
 ] $processing_system7_0

  # Create instance: ps7_0_axi_periph, and set properties
  set ps7_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 ps7_0_axi_periph ]
  set_property -dict [ list \
   CONFIG.M00_HAS_REGSLICE {0} \
   CONFIG.M01_HAS_DATA_FIFO {0} \
   CONFIG.M01_HAS_REGSLICE {0} \
   CONFIG.M02_HAS_REGSLICE {0} \
   CONFIG.M03_HAS_REGSLICE {0} \
   CONFIG.M04_HAS_REGSLICE {0} \
   CONFIG.NUM_MI {5} \
 ] $ps7_0_axi_periph

  # Create instance: rst_ps7_0_100M, and set properties
  set rst_ps7_0_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_100M ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net S09_AXIS_1 [get_bd_intf_pins data_rx/S09_AXIS] [get_bd_intf_pins larpix_clk/M_AXIS]
  connect_bd_intf_net -intf_net S0_AXIS_1 [get_bd_intf_pins data_tx/M00_AXIS] [get_bd_intf_pins larpix_uart_array/S0_AXIS]
  connect_bd_intf_net -intf_net S1_AXIS_1 [get_bd_intf_pins data_tx/M01_AXIS] [get_bd_intf_pins larpix_uart_array/S1_AXIS]
  connect_bd_intf_net -intf_net S2_AXIS_1 [get_bd_intf_pins data_tx/M02_AXIS] [get_bd_intf_pins larpix_uart_array/S2_AXIS]
  connect_bd_intf_net -intf_net S3_AXIS_1 [get_bd_intf_pins data_tx/M03_AXIS] [get_bd_intf_pins larpix_uart_array/S3_AXIS]
  connect_bd_intf_net -intf_net S4_AXIS_1 [get_bd_intf_pins data_tx/M04_AXIS] [get_bd_intf_pins larpix_uart_array/S4_AXIS]
  connect_bd_intf_net -intf_net S5_AXIS_1 [get_bd_intf_pins data_tx/M05_AXIS] [get_bd_intf_pins larpix_uart_array/S5_AXIS]
  connect_bd_intf_net -intf_net S6_AXIS_1 [get_bd_intf_pins data_tx/M06_AXIS] [get_bd_intf_pins larpix_uart_array/S6_AXIS]
  connect_bd_intf_net -intf_net S7_AXIS_1 [get_bd_intf_pins data_tx/M07_AXIS] [get_bd_intf_pins larpix_uart_array/S7_AXIS]
  connect_bd_intf_net -intf_net S_AXIMM_1 [get_bd_intf_pins larpix_uart_array/S_AXIMM] [get_bd_intf_pins ps7_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net S_AXI_LITE_1 [get_bd_intf_pins dma/S_AXI_LITE] [get_bd_intf_pins ps7_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net S_AXI_LITE_2 [get_bd_intf_pins larpix_trig/S_AXI_LITE] [get_bd_intf_pins ps7_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net S_AXI_LITE_3 [get_bd_intf_pins axi_lite_reg_space/S_AXI_LITE] [get_bd_intf_pins ps7_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net data_rx_M00_AXIS [get_bd_intf_pins data_rx/M00_AXIS] [get_bd_intf_pins dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net dma_M00_AXI [get_bd_intf_pins dma/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
  connect_bd_intf_net -intf_net dma_M_AXIS_MM2S [get_bd_intf_pins data_tx/S_AXIS] [get_bd_intf_pins dma/M_AXIS_MM2S]
  connect_bd_intf_net -intf_net larpix_trig_M_AXIS [get_bd_intf_pins data_rx/S08_AXIS] [get_bd_intf_pins larpix_trig/M_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_array_M0_AXIS [get_bd_intf_pins data_rx/S00_AXIS] [get_bd_intf_pins larpix_uart_array/M0_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_array_M1_AXIS [get_bd_intf_pins data_rx/S01_AXIS] [get_bd_intf_pins larpix_uart_array/M1_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_array_M2_AXIS [get_bd_intf_pins data_rx/S02_AXIS] [get_bd_intf_pins larpix_uart_array/M2_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_array_M3_AXIS [get_bd_intf_pins data_rx/S03_AXIS] [get_bd_intf_pins larpix_uart_array/M3_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_array_M4_AXIS [get_bd_intf_pins data_rx/S04_AXIS] [get_bd_intf_pins larpix_uart_array/M4_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_array_M5_AXIS [get_bd_intf_pins data_rx/S05_AXIS] [get_bd_intf_pins larpix_uart_array/M5_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_array_M6_AXIS [get_bd_intf_pins data_rx/S06_AXIS] [get_bd_intf_pins larpix_uart_array/M6_AXIS]
  connect_bd_intf_net -intf_net larpix_uart_array_M7_AXIS [get_bd_intf_pins data_rx/S07_AXIS] [get_bd_intf_pins larpix_uart_array/M7_AXIS]
  connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins processing_system7_0/DDR]
  connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins processing_system7_0/FIXED_IO]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins ps7_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M03_AXI [get_bd_intf_pins larpix_clk/S_AXI_LITE] [get_bd_intf_pins ps7_0_axi_periph/M03_AXI]

  # Create port connections
  connect_bd_net -net HW_SYNC_TRIG_1 [get_bd_ports HW_SYNC_TRIG] [get_bd_pins larpix_clk/HW_SYNC_TRIG]
  connect_bd_net -net MCLK_1 [get_bd_ports CLK] [get_bd_pins io/I_CLK] [get_bd_pins larpix_clk/MCLK] [get_bd_pins larpix_trig/MCLK] [get_bd_pins larpix_uart_array/MCLK]
  connect_bd_net -net MISO_0_1 [get_bd_ports MISO_0] [get_bd_pins larpix_uart_array/MISO]
  connect_bd_net -net PACMAN_TS_1 [get_bd_pins larpix_clk/TIMESTAMP] [get_bd_pins larpix_trig/TIMESTAMP] [get_bd_pins larpix_uart_array/PACMAN_TS]
  connect_bd_net -net TRIG1_IN_1 [get_bd_ports TRIG1_IN] [get_bd_pins larpix_trig/TRIG1_IN]
  connect_bd_net -net axi_lite_reg_space_analog_pwr_en [get_bd_ports ANALOG_PWR_EN] [get_bd_pins axi_lite_reg_space/analog_pwr_en]
  connect_bd_net -net axi_lite_reg_space_tile_en [get_bd_ports TILE_EN] [get_bd_pins axi_lite_reg_space/tile_en] [get_bd_pins io/I_TILE_EN] [get_bd_pins larpix_uart_array/TILE_EN]
  connect_bd_net -net io_O_TRIG [get_bd_ports TRIG] [get_bd_pins io/O_TRIG]
  connect_bd_net -net larpix_clk_RST_SYNC_N [get_bd_ports RESETN] [get_bd_pins io/I_RESETN] [get_bd_pins larpix_clk/RST_SYNC_N]
  connect_bd_net -net larpix_trig_TRIG_MASKED [get_bd_pins io/I_TRIG] [get_bd_pins larpix_trig/TRIG_MASKED]
  connect_bd_net -net larpix_uart_array_MOSI [get_bd_ports MOSI_0] [get_bd_pins larpix_uart_array/MOSI]
  connect_bd_net -net larpix_uart_array_UART_RX_BUSY [get_bd_ports UART_RX_BUSY] [get_bd_pins larpix_uart_array/UART_RX_BUSY]
  connect_bd_net -net larpix_uart_array_UART_TX_BUSY1 [get_bd_ports UART_TX_BUSY] [get_bd_pins larpix_uart_array/UART_TX_BUSY]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins axi_lite_reg_space/S_AXI_LITE_ACLK] [get_bd_pins data_rx/ACLK] [get_bd_pins data_tx/aclk] [get_bd_pins dma/ACLK] [get_bd_pins larpix_clk/ACLK] [get_bd_pins larpix_trig/ACLK] [get_bd_pins larpix_uart_array/ACLK] [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] [get_bd_pins ps7_0_axi_periph/ACLK] [get_bd_pins ps7_0_axi_periph/M00_ACLK] [get_bd_pins ps7_0_axi_periph/M01_ACLK] [get_bd_pins ps7_0_axi_periph/M02_ACLK] [get_bd_pins ps7_0_axi_periph/M03_ACLK] [get_bd_pins ps7_0_axi_periph/M04_ACLK] [get_bd_pins ps7_0_axi_periph/S00_ACLK] [get_bd_pins rst_ps7_0_100M/slowest_sync_clk]
  connect_bd_net -net processing_system7_0_FCLK_CLK1 [get_bd_pins larpix_clk/CLK_AUX] [get_bd_pins processing_system7_0/FCLK_CLK1]
  connect_bd_net -net processing_system7_0_FCLK_RESET0_N [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins rst_ps7_0_100M/ext_reset_in]
  connect_bd_net -net rst_ps7_0_100M_peripheral_aresetn [get_bd_pins axi_lite_reg_space/S_AXI_LITE_ARESETN] [get_bd_pins data_rx/ARESETN] [get_bd_pins data_tx/aresetn] [get_bd_pins dma/ARESETN] [get_bd_pins larpix_clk/RSTN] [get_bd_pins larpix_trig/ARESETN] [get_bd_pins larpix_uart_array/ARESETN] [get_bd_pins ps7_0_axi_periph/ARESETN] [get_bd_pins ps7_0_axi_periph/M00_ARESETN] [get_bd_pins ps7_0_axi_periph/M01_ARESETN] [get_bd_pins ps7_0_axi_periph/M02_ARESETN] [get_bd_pins ps7_0_axi_periph/M03_ARESETN] [get_bd_pins ps7_0_axi_periph/M04_ARESETN] [get_bd_pins ps7_0_axi_periph/S00_ARESETN] [get_bd_pins rst_ps7_0_100M/peripheral_aresetn]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins larpix_clk/HW_HARD_RST_TRIG] [get_bd_pins larpix_clk/HW_STATE_RST_TRIG] [get_bd_pins larpix_trig/TRIG2_IN] [get_bd_pins larpix_trig/TRIG3_IN] [get_bd_pins xlconstant_0/dout]

  # Create address segments
  assign_bd_address -offset 0x40400000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs dma/axi_dma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x50001000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_clk/axi_lite_reg_space/axi_lite_reg_space_0/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50002000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_trig/axi_lite_reg_space/axi_lite_reg_space_0/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_lite_reg_space/axi_lite_reg_space_0/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50003000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_1/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50004000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_2/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50005000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_3/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50006000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_4/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50007000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_5/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50008000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_6/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50009000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_7/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x5000A000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_8/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x5000B000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_9/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x5000C000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_10/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x5000D000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_11/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x5000E000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_12/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x5000F000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_13/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50010000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_14/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50011000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_15/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50012000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_16/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50013000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_17/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50014000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_18/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50015000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_19/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50016000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_20/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50017000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_21/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50018000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_22/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50019000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_23/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x5001A000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_24/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x5001B000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_25/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x5001C000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_26/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x5001D000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_27/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x5001E000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_28/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x5001F000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_29/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50020000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_30/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50021000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_31/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x50022000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs larpix_uart_array/uart_channels/larpix_uart_channel_32/S_AXI_LITE/reg0] -force
  assign_bd_address -offset 0x30000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces dma/axi_dma_0/Data_SG] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] -force
  assign_bd_address -offset 0x30000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces dma/axi_dma_0/Data_MM2S] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] -force
  assign_bd_address -offset 0x30000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces dma/axi_dma_0/Data_S2MM] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


