
This file constains complete instructions for building the PACMAN firmware from the git repository.

Conventions:
 - Xilinx tools are all 2020.2.
 - Confirmed to work with Ubuntu 18.04 and Ubunntu 22.04
 - Xilinx is installed at /tools/Xilinx/
   (if not, just change path below as needed.)
 - Shell commands beging with $.

Xilinx Software and Git:

The use of git and Xilinx has gotten better.  We are following the approach described here:

https://www.fpgadeveloper.com/2014/08/version-control-for-vivado-projects.html/

In short, we build the board file from tcl (which can be generated
with vivado) and we maintain our own top-level tcl file for creating
the tcl project.  

For petalinux, we try to keep as close to a vanilla install as possible.  Instead of saving the entire project, we save only the rather few files which we must change.

See flow.txt for now.
