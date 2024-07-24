#! /bin/bash

SRC=./src
PKG=./pkg
SPEC=ramdisk
PROJ=$SPEC

if [ -d "$PROJ" ]; then
    echo "The petalinux project directory $PROJ already exists."
    echo "*** You must delete or move project directory to start the process from scratch. ***"
    # uncomment return below to require starting from scratch.
    # return 0
    echo "WARNING   Updating an *existing* project with only our *local* changes."
    echo "          This will not *remove* any existing new files in project directory, even if they would not be"
    echo "          created if the process started from scratch.  If you need to remove files, you will have to delete"
    echo "          the existing petalinux project directory and start from scratch."
else
    echo "Creating new project directory $PROJ"
    petalinux-create -t project -n $PROJ --template zynq
fi

# add configs specfic to this option
cp -v $SRC/config-$SPEC                $PROJ/project-spec/configs/config
cp -v $SRC/rootfs_config-$SPEC         $PROJ/project-spec/configs/rootfs_config

# add configs not specific to this option
cp -v $SRC/platform-top.h       $PROJ/project-spec/meta-user/recipes-bsp/u-boot/files/
cp -v $SRC/system-user.dtsi     $PROJ/project-spec/meta-user/recipes-bsp/device-tree/files/
cp -v $SRC/system-user.dtsi     $PROJ/project-spec/meta-user/meta-xilinx-tools/recipes-bsp/uboot-device-tree/files/
cp -v $SRC/user-rootfsconfig    $PROJ/project-spec/meta-user/conf/

# add custom software packages
#cp -v -r $PKG/startup            $PROJ/project-spec/meta-user/recipes-apps/
#cp -v -r $PKG/webfwu             $PROJ/project-spec/meta-user/recipes-apps/
cp -v -r $PKG/pacman-server      $PROJ/project-spec/meta-user/recipes-apps/

#cd $PROJ
#source build.sh
#cd ..
