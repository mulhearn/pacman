#!/bin/bash
#
# tcl/build_resethack1.8.sh   (Vivado 2021.1 settings sourced)
#
# Builds the resethack 1.8 project (894) from this checkout and copies the bitstream to
#
#     products/zsys_wrapper.bit
#
# tcl/pacman_resethack1.8.tcl is Armin's script:  tcl/recreate_resethack1.8.tcl stages its files under
# build/resethack1.8 and runs it.

set -euo pipefail
R=$(cd "$(dirname "$0")/.." && pwd)
B=$R/build/resethack1.8
rm -rf "$B"; mkdir -p "$B" "$R/products"

# recreate the project, then build:
( cd "$B" && vivado -mode batch -nojournal -log "$B/recreate.log" -source "$R/tcl/recreate_resethack1.8.tcl" \
      -tclargs "$R" "$B" )
X=$B/proj/pacman_resethack1.8
( cd "$B" && vivado -mode batch -nojournal -log "$B/build.log" -source "$R/tcl/build_resethack1.8.tcl" \
      -tclargs "$X/pacman_resethack1.8.xpr" )
cp "$X/pacman_resethack1.8.runs/impl_1/zsys_wrapper.bit" "$R/products/zsys_wrapper.bit"
echo "build_resethack1.8:  products/zsys_wrapper.bit"
