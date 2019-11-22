#! /bin/bash

cp images/linux/rootfs.tar.gz images/linux/rootfs-wlocal.tar.gz
gunzip images/linux/rootfs-wlocal.tar.gz
tar -C local/root -r -f images/linux/rootfs-wlocal.tar .
gzip images/linux/rootfs-wlocal.tar

