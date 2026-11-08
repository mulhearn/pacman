#! /bin/bash
find ghdl vivado/src vivado/ip_repo -type f -name '*.vhd' | xargs -n1 sed --in-place 's/[[:space:]]\+$//'
find apps -type f -name '*.c' | xargs -n1 sed --in-place 's/[[:space:]]\+$//'
find apps -type f -name '*.h' | xargs -n1 sed --in-place 's/[[:space:]]\+$//'
find apps vivado/tcl -type f -name '*.tcl' | xargs -n1 sed --in-place 's/[[:space:]]\+$//'
find docs -type f -name '*.txt' | xargs -n1 sed --in-place 's/[[:space:]]\+$//'

find petalinux/pkg -type f -name '*.c' | xargs -n1 sed --in-place 's/[[:space:]]\+$//'
find petalinux/pkg -type f -name '*.h' | xargs -n1 sed --in-place 's/[[:space:]]\+$//'
find petalinux/pkg -type f -name '*.cc' | xargs -n1 sed --in-place 's/[[:space:]]\+$//'
find petalinux/pkg -type f -name '*.hh' | xargs -n1 sed --in-place 's/[[:space:]]\+$//'
find petalinux/pkg -type f -name '*.bb' | xargs -n1 sed --in-place 's/[[:space:]]\+$//'
find petalinux/scripts -type f -name '*.sh' | xargs -n1 sed --in-place 's/[[:space:]]\+$//'
