#!/bin/bash
#
# tcl/build_fw15.sh   (Vivado 2021.1 settings sourced)
#
# Builds the pacman-fw15 project (893, 883) from this checkout and copies the bitstream to
#
#     products/zsys_wrapper.bit
#
# tcl/pacman-fw15.tcl is Armin's export, unchanged:  the files it requires are staged in its layout under build/fw15.

set -euo pipefail
R=$(cd "$(dirname "$0")/.." && pwd)
B=$R/build/fw15
S=$B/a/b/c

# stage the files in the layout the export expects:
rm -rf "$B"; mkdir -p "$S" "$B/srcs" "$R/products"
cp -r "$R/srcs/ip" "$B/srcs/ip"
cp "$R/tcl/pacman-fw15.tcl" "$S/"
sed -n '/^proc checkRequiredFiles/,/^}/p' "$R/tcl/pacman-fw15.tcl" | grep -o 'origin_dir/x/[^"]*' | sed 's|origin_dir/x/||' |
while read -r f; do
    b=$(basename "$f")
    case $f in
        */archive_project_summary.txt) src=/dev/null ;;
        *constrs_1*)  src=$R/constraints/$b ;;
        *ip/*)        src=$R/srcs/ip/$(basename "$(dirname "$f")")/$b ;;
        *sim_1*tb/*)  src=$R/srcs/fw/tb/$b ;;
        *)            src=$R/srcs/fw/$b ;;
    esac
    mkdir -p "$S/x/$(dirname "$f")"; cp "$src" "$S/x/$f"
done
# the export's IP-repository check names origin_dir/<absolute path>:
mkdir -p "$S$(cd "$S/../../.." && pwd)/srcs/ip"

# recreate the project, then build:
( cd "$S" && vivado -mode batch -nojournal -log "$B/recreate.log" -source pacman-fw15.tcl -tclargs --origin_dir "$S" )
( cd "$S" && vivado -mode batch -nojournal -log "$B/build.log" -source "$R/tcl/build_fw15.tcl" \
      -tclargs "$S/pacman-fw15/pacman-fw15.xpr" )
cp "$S/pacman-fw15/pacman-fw15.runs/impl_1/zsys_wrapper.bit" "$R/products/zsys_wrapper.bit"
echo "build_fw15:  products/zsys_wrapper.bit"
