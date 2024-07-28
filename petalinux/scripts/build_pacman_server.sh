#  
#  build_pacman_server.sh
#
# Cross-compile only the pacman-server application and grab the produced rpm.
#
# For testing on the PACMAN card, you can extract the rpm contents via:
#
#   $ rpm2cpio pacman-server-1.0-r0.9.cortexa9t2hf_neon.rpm | cpio -idmv
#

#petalinux-build -c pacman-server -x build
ls -alh build/tmp/deploy/rpm/cortexa*_neon/pacman-server-1.0-r*.cortexa*_neon.rpm 
cp -v build/tmp/deploy/rpm/cortexa*_neon/pacman-server-1.0-r*.cortexa*_neon.rpm pacman-server-latest.rpm
