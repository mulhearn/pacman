#! /bin/bash

SRC=./src
SPEC=vanilla
PROJ=$SPEC

if [ -d "$PROJ" ]; then
    echo "petalinux project directory: $PROJ already exists..."
    return 0
fi

petalinux-create -t project -n $PROJ --template zynq

