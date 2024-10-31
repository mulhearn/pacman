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
    echo "The petalinux project directory $PROJ already exists."
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

echo "Overwriting project-spec directory with version provided by TRENZ"
mv $PROJ/project-spec $PROJ/project-spec.prev
cp -r $SRC/trenz/project-spec $PROJ/

# we'll keep the trenz project-spec directory as provided by trenz and keep our own changes separate:
#echo "our changes:"
#cp -v $SRC/trenz/changes/system-user.dtsi $PROJ/project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi


