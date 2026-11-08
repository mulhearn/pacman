# version_info.tcl:  generate version-related information as integer constants at synthesis

# set the reference directory relative to the script
set origin_dir [file dirname [info script]]/..

# path and filename of the generated package
set outfile "gen/hdl/version_info_pkg.vhd"

# current time:
set now [clock seconds]
puts "INFO: Current Unix timestamp (SYNTHESIS_DATE): $now"

# Get git hash (full 64-bit value) as 7-char short hash, pad to 8 chars if needed
set git_hash "nogit__"  ;# default 8 chars
catch {
    set raw_hash [exec git rev-parse --short HEAD]
    puts "INFO: Raw Git hash from repo: $raw_hash"
    set git_hash [string range "$raw_hash        " 0 7]
    append git_hash "_"
}
puts "INFO: Git hash (padded to 8 chars): $git_hash"

# Split the 8-char git hash into two 4-char parts
set git_hash_upper_str [string range $git_hash 0 3]
set git_hash_lower_str [string range $git_hash 4 7]

# convert a four character string to integer:
proc ascii_to_int {str} {
    set result 0
    for {set i 0} {$i < 4} {incr i} {
        set c [scan [string index $str $i] %c]
        set result [expr {($result << 8) | $c}]
    }
    return $result
}

# convert to integers
set git_hash_upper [ascii_to_int $git_hash_upper_str]
set git_hash_lower [ascii_to_int $git_hash_lower_str]
puts "INFO: GIT_HASH_UPPER (int): $git_hash_upper"
puts "INFO: GIT_HASH_LOWER (int): $git_hash_lower"

# get the Vivado version numbers as integers (major, minor)
set version_string [version]
puts "INFO: Vivado version string:\n$version_string"

if {[regexp {v(\d+)\.(\d+)} $version_string match major minor]} {
    set vivado_major $major
    set vivado_minor $minor
} else {
    set vivado_major 0
    set vivado_minor 0
    puts "INFO: Failed to parse Vivado version string."
}

puts "INFO: Vivado version major: $vivado_major"
puts "INFO: Vivado version minor: $vivado_minor"

# Prepare for output:
file mkdir [file dirname $outfile]
puts "INFO: Writing version_info_pkg.vhd to $outfile"
set fh [open $outfile "w"]

# Write the package header and constants
puts $fh "-- Auto-generated version_info_pkg --"
puts $fh "-- Synthesis date: [clock format $now -format {%Y-%m-%d %H:%M:%S}]"
puts $fh "-- Git hash: $git_hash"
puts $fh "-- Vivado version: $vivado_major.$vivado_minor"
puts $fh "library ieee;"
puts $fh "use ieee.std_logic_1164.all;"
puts $fh ""
puts $fh "package version_info_pkg is"
puts $fh "  constant C_SYNTHESIS_DATE  : integer := $now;"
puts $fh "  constant C_GIT_HASH_UPPER  : integer := $git_hash_upper;"
puts $fh "  constant C_GIT_HASH_LOWER  : integer := $git_hash_lower;"
puts $fh "  constant C_VIVADO_MAJOR    : integer := $vivado_major;"
puts $fh "  constant C_VIVADO_MINOR    : integer := $vivado_minor;"
puts $fh "end package;"
puts $fh ""
close $fh

puts "INFO: version_info_pkg.vhd generation complete."


