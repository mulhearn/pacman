#  
#  build_hwutil.sh
#
# Cross-compile only the pacman-server application and grab the produced rpm.
#
# For testing on the PACMAN card, you can extract the rpm contents via:
#
#   $ rpm2cpio pacman-server-1.0-r0.9.cortexa9t2hf_neon.rpm | cpio -idmv
#

petalinux-build -c hwutil -x build
ls -alh build/tmp/deploy/rpm/cortexa*_neon/hwutil-1.0-r*.cortexa*_neon.rpm 
cp -v build/tmp/deploy/rpm/cortexa*_neon/hwutil-1.0-r*.cortexa*_neon.rpm hwutil-latest.rpm
