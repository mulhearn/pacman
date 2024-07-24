#! /bin/bash

cp images/linux/rootfs.tar.gz images/linux/rootfs-wlocal.tar.gz
gunzip images/linux/rootfs-wlocal.tar.gz
if test -d local/root; then   
    tar -C local/root -r -f images/linux/rootfs-wlocal.tar .
fi
gzip images/linux/rootfs-wlocal.tar

