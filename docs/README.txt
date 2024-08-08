
This file constains complete instructions for building the PACMAN firmware from the git repository.

Conventions:
 - Xilinx tools are all 2023.2.
 - Confirmed to work with Ubuntu 22.04
 - Xilinx is installed at /tools/Xilinx/ (if not, just change path below as needed.)

Xilinx Software and Git:

The use of git and Xilinx has gotten better.  We are following the approach described here:

https://www.fpgadeveloper.com/2014/08/version-control-for-vivado-projects.html/

In short, we build the board file from tcl (which can be generated
with vivado) and we maintain our own top-level tcl file for creating
the tcl project.

We have started with a Trenz TE0720 test board design, which we
imported into our tcl build scripts.

For petalinux, we also start with the Trenz provided petalinux
project-spec directory.  We are keeping track of which changes we have
made ourselves, because petalinux handles project upgrades poorly.

See flow.txt for details.
