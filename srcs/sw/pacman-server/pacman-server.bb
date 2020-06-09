#
# This file is the pacman-server recipe.
#

SUMMARY = "Simple pacman-server application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
DEPENDS = "zeromq"

SRC_URI = "file://src \
           file://include \
           file://pacman-server.sh \
	   file://Makefile \
		  "
                  
INITSCRIPT_NAME = "pacman-server"
INITSCRIPT_PARAMS = "start 99 S ."

S = "${WORKDIR}"

inherit update-rc.d

do_compile() {
	     oe_runmake
}

do_install() {
	     install -d ${D}${bindir}
	     install -m 0755 ${S}/pacman-cmdserver ${D}${bindir}
             install -m 0755 ${S}/pacman-dataserver ${D}${bindir}
             install -d ${D}${sysconfdir}/init.d
	     install -m 0755 ${S}/pacman-server.sh ${D}${sysconfdir}/init.d/pacman-server
             install -m 0755 ${S}/pacman-server.sh ${D}${bindir}
}

FILES_${PN} += "${sysconfdir}/*"