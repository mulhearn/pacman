Getting started:

git clone <>
cd pacman


#
# Firmware:
#

# create the project:
# (first setup your vivado environment)
vivado -mode batch -source tcl/recreate.tcl

# sythesize, implement, write bitstream, and export hardware:
vivado -mode batch -source tcl/build.tcl

#
# Peta-Linux:
#






