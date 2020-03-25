#
# This file is the pacman-server recipe.
#

SUMMARY = "Simple pacman-server application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
DEPENDS = "zeromq"

SRC_URI = "file://pacman-cmdserver.cc \
           file://pacman-dataserver.cc \
           file://dma.cc \
           file://larpix.cc \
           file://fw-addr-conf.hh \
	   file://Makefile \
		  "

S = "${WORKDIR}"

do_compile() {
	     oe_runmake
}

do_install() {
	     install -d ${D}${bindir}
	     install -m 0755 ${S}/pacman-cmdserver ${D}${bindir}
             install -m 0755 ${S}/pacman-dataserver ${D}${bindir}
}
