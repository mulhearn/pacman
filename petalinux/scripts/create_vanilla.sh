#! /bin/bash

SPEC=vanilla
PROJ=$SPEC

# create project in the correct location no matter where the script is run from:
cd "$(dirname "$0")/.."

if [ -d "$PROJ" ]; then
    echo "petalinux project directory: $PROJ already exists...delete for scratch start."
    return 0
fi

petalinux-create -t project -n $PROJ --template zynq
