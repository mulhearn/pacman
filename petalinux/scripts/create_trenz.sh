#! /bin/bash

SRC=./src
SPEC=trenz
#PROJ=proj
PROJ=$SPEC

# create project in the correct location no matter where the script is run from:
cd "$(dirname "$0")/.."

echo "working directory is:  "
pwd

if [ -d "$PROJ" ]; then
    echo "petalinux project directory: $PROJ already exists...delete for scratch start."
    exit 0
fi

petalinux-create -t project -n $PROJ --template zynq

mv $PROJ/project-spec $PROJ/project-spec.orig
cp -r $SRC/trenz/project-spec $PROJ/

# we'll keep the trenz project-spec directory as provided by trenz and keep our own changes separate:
echo "our changes:"
cp -v $SRC/trenz/changes/system-user.dtsi $PROJ/project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi


