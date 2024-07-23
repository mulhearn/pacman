#! /bin/bash

SPEC=vanilla
PROJ=$SPEC

if [ -d "$PROJ" ]; then
    echo "petalinux project directory: $PROJ already exists...delete for scratch start."
    return 0
fi

petalinux-create -t project -n $PROJ --template zynq
