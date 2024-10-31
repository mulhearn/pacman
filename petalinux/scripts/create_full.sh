#! /bin/bash

SRC=./src
PKG=./pkg
SPEC=full
PROJ=$SPEC

# create project in the correct location no matter where the script is run from:
cd "$(dirname "$0")/.."
echo "working directory is:  "
pwd

if [ -d "$PROJ" ]; then
    echo "The petalinux project directory $PROJ already exists."
    echo "*** You must delete or move project directory to start the process from scratch. ***"
    # uncomment return below to require starting from scratch.
    # return 0
    echo "WARNING   Updating an *existing* project without starting from scratch."
else
    echo "Creating new project directory $PROJ"
    petalinux-create -t project -n $PROJ --template zynq
fi

if [ -d "$PROJ/project-spec.prev" ]; then
    echo "Please delete $PROJ/project-spec.prev then retry ..."
    exit 0
fi

# BASELINE is the project-spec directory provided by TRENZ for the test board design:
mv $PROJ/project-spec $PROJ/project-spec.prev
cp -r $SRC/trenz/project-spec $PROJ/

# Our changes:
echo "our changes:"
cp -v $SRC/$SPEC/system-user.dtsi  $PROJ/project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi
cp -v $SRC/$SPEC/user-rootfsconfig $PROJ/project-spec/meta-user/conf/
cp -v $SRC/$SPEC/rootfs_config     $PROJ/project-spec/configs/rootfs_config
cp -v $SRC/$SPEC/config            $PROJ/project-spec/configs/config

# add custom software packages
cp -v -r $PKG/pacman-server      $PROJ/project-spec/meta-user/recipes-apps/
cp -v -r $PKG/hwutil             $PROJ/project-spec/meta-user/recipes-apps/

