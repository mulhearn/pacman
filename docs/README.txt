
This file constains complete instructions for building the PACMAN firmware from the git repository.

Supporting notes are in:
 - docs/notes/install.txt
	notes on installing Vivado w/ Ubuntu
 - docs/notes/test_board_import.txt
	notes on how the TRENZ TE0720 reference design was imported
 - docs/notes/coldstart.txt
	strategies for getting starting with limited network and hardware

Conventions:
 - OS is latest version of Ubuntu 16.04 LTS
 - Xilinx tools are all 2018.3
 - Unless explicitly stated otherwise, all commands are issued from
   the root directory of the git repository, and most will not work
   from elsewhere.
- Xilinx is installed at /tools/Xilinx/
   (if not, just change path below as needed.)
 - Shell commands beging with $.

Xilinx Software and Git:

All builds are based on TCL-based command line Xilinx tools.  As
recommended by Xilinx, to version control the Vivado project in git we
export it as a tcl file ("tcl/recreate_xpr.tcl").  That file plus
orginal source files is sufficient to rebuild the Xilinx project,
which can then be viewed and editted with the Vivado GUI.  For this
approach to work, source cannot be *imported* into the Vivado project.
Instead, keep source files in src/xpr/ and reference them
(with add sources) to the project.

The bare-metal applications, such as "Hello World" and the custom
first stage boot loader (zynq_fsbl) needed for the TE0720, are built
with the Xilinx Software Commandline Tool (XSCT) from tcl scripts.

The linux operating system uses peta-linux command line tools.

The installation of all of these tools for Ubuntu 16.04 is detailed in tools/install

--------------------
1) Getting started:
--------------------

# clone and enter the git repository
$git clone https://github.com/mulhearn/pacman.git
$cd pacman

# setup vivado:
$source /tools/Xilinx/Vivado/2018.3/settings64.sh

# create the Xilinx project (xpr) from tcl file:
$vivado -mode batch -source tcl/recreate_xpr.tcl

# sythesize, implement, write bitstream, and export hardware:
$vivado -mode batch -source tcl/build_xpr.tcl

A successful build produces the file:
products/zsys_wrapper.hdf

# on another terminal, connect to USB serial device with TE0720 connected:
$busybox microcom -s 115200 /dev/ttyUSB1
# (your tty device may vary!  Try "dmesg | grep tty")
# Exit with Ctrl-x or Ctrl-X

# create, build, and run the hello world bare metal application:
xsct tcl/hello.tcl

If everything goes correctly, you should see "Hello World" output on
the USB terminal.  Well hello there, world!

-----------------------------------------
2) Write your own bare metal application:
-----------------------------------------

You can easily adapt the hello world application into a free standing bare metal application.

#rename it and move in:
$mv hello serious_task
$cd serious_task

# edit bareapp/src/bareapp.c as needed... for now just change the message.

# build and run your own the bare metal application:
$xsct build.tcl
$xsct run.tcl

# remember to go back out to root directory:
$cd ..


-----------------------------------------
3) Build the supporting applications:
-----------------------------------------

Build supporting bare applications from sources,

# build and copy to products
xsct tcl/build_sw.tcl

Successful build produces the file:
products/zynq_fsbl.elf

-----------------------------------------
4) Build and install Peta-Linux:
-----------------------------------------

In a new shell, setup petalinux:
$source /tools/Xilinx/petalinux/2018.3/settings.sh
(Petalinux is very fussy about the shell.  Make sure you are using
bash, and try hiding e.g. your .bash_aliases file if you having trouble.)

Build Peta-Linux by running the build script:
$chmod ugo+x ./petalinux/build.sh
$./petalinux/build.sh

You can add local files to the rootfs by adding them to local/root.  For example, I include:
petalinux/local/root/dropbear/dropbear_rsa_host_key
petalinux/local/root/shadow
so that the host_key doesn't change and to set the root password to something not in the git.

To install, format an SD card:
  ~ 1 GB - FAT - label: BOOT
  remainder - Linux - label: rootfs

From the petalinux/images/linux directory copy BOOT.bin and image.ub to the boot partition

Untar the rootfs tarball onto the rootfs partition


If you just want to update the firmware, you can just do:
petalinux-package --boot --force --fsbl ../products/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot

--------------------------------------------------------------
5) Update the Xilinx project from an updated TCL project file:
--------------------------------------------------------------

Suppose someone updates the repository with an updated
"recreate_xpr.tcl" file.  Some additional steps are needed to
propogate these updates into the project.  You'll need to move the
pacman directory elsewhere, e.g.:

$mv pacman-fw pacman-fw.old

And then proceed as above with the recreate_xpr.tcl

You can then manually merge any of your local changes from
pacman-fw.old into the reconstituted new project at pacman-fw.
Another approach is to merge the changes at the project TCL level (see
below).  Note that changes to source files are version controlled like
ordinary source files.

-----------------------------------------------------------------------
6) Update the TCL project file after making changes to the Xilinx project 
-----------------------------------------------------------------------

If you make changes to the Xilinx projects (not just the referenced
sources), you'll need to update the project TCL file:

$vivado -mode batch -source tcl/export_xpr.tcl

One merge strategy is to export your project as TCL, merge the changes
made by others to the TCL file, then rebuild the the project.






