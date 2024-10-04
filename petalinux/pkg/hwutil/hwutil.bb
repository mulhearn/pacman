#
# This file is the pacman-server recipe.
#

SUMMARY = "linux-based hardware utility for checkout, etc"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
DEPENDS = "i2c-tools"

SRC_URI = "file://src \
           file://include \
	   file://Makefile \
		  "

S = "${WORKDIR}"

#inherit update-rc.d

do_compile() {
	     oe_runmake
}

do_install() {
	     install -d ${D}${bindir}
	     install -m 0755 ${S}/hwutil ${D}${bindir}
}


