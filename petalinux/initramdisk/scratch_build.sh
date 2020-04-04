#! /bin/bash

SRC=./petalinux
SPEC=initramdisk
PROJ=./petalinux-$SPEC

if [ -d "$PROJ" ]; then
    echo "petalinux project directory: $PROJ already exists..."
    return 0
fi

petalinux-create -t project -n $PROJ --template zynq

# add our own changes:
cp $SRC/common/build.sh             $PROJ/
cp $SRC/common/reset.tcl            $PROJ/
cp $SRC/common/jtag_boot.sh         $PROJ/
cp $SRC/common/program_flash.sh         $PROJ/
cp $SRC/common/platform-top.h       $PROJ/project-spec/meta-user/recipes-bsp/u-boot/files/
cp $SRC/common/system-user.dtsi     $PROJ/project-spec/meta-user/recipes-bsp/device-tree/files/
cp $SRC/common/petalinux-image-full.bbappend  $PROJ/project-spec/meta-user/recipes-core/images/

cp $SRC/$SPEC/config                $PROJ/project-spec/configs/
cp $SRC/$SPEC/rootfs_config         $PROJ/project-spec/configs/

#cd $PROJ
#source build.sh
#cd ..
