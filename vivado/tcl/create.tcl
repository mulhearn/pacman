#
# create.tcl:  tcl-based vivado project creation for PACMAN
#

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir [file dirname [info script]]/..

# Set the project name
set proj_name "trenz-fw"

# Create project
create_project $proj_name $origin_dir/$proj_name -part xc7z010clg400-1

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [current_project]
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/$proj_name.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "part" -value "xc7z020clg484-1" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${proj_name}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
#set_property -name "source_mgmt_mode" -value "DisplayOnly" -objects $obj
set_property -name "source_mgmt_mode" -value "All" -objects $obj
set_property -name "target_language" -value "VHDL" -objects $obj
set_property -name "xpm_libraries" -value "XPM_CDC XPM_MEMORY" -objects $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set IP repository paths
set obj [get_filesets sources_1]
if { $obj != {} } {
   set_property "ip_repo_paths" "[file normalize "$origin_dir/ip_repo"]" $obj

   # Rebuild user ip_repo's index before adding any source files
   update_ip_catalog -rebuild
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
# add all vhd files in src/hdl to project:
set files {}
foreach file [glob src/hdl/*.vhd] {lappend files [file normalize $file]}
puts "HDL files:  $files"
add_files -norecurse -fileset sources_1 $files
#update_compile_order -fileset sources_1

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "zsys_wrapper" -objects $obj

#Create block design
source $origin_dir/src/bd/zsys.tcl

# Generate the wrapper
set design_name [get_bd_designs]
make_wrapper -files [get_files ${design_name}.bd] -top -import

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}
set obj [get_filesets constrs_1]
set files {}
foreach file [glob src/constraints/*.xdc] {lappend files [file normalize $file]}
puts "HDL files:  $files"
add_files -norecurse -fileset sources_1 $files
puts "Constraint files:  $files"
add_files -norecurse -fileset $obj $files

set file_obj [get_files -of_objects [get_filesets constrs_1]]
set_property -name "file_type" -value "XDC" -objects $file_obj

set obj [get_filesets constrs_1]
set_property -name "target_part" -value "xc7z020clg484-1" -objects $obj

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}
