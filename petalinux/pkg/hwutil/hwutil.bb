#
# This file is the hwutil recipe.
#

SUMMARY = "Linux-based hardware utility for PACMAN card"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
DEPENDS = "i2c-tools"

SRC_URI = "file://src \
           file://include \
	   file://Makefile \
	   file://gpio_init.sh \


INITSCRIPT_NAME = "gpio_init"
INITSCRIPT_PARAMS = "start 99 S ."

S = "${WORKDIR}"
homedir = "/home/root"

inherit update-rc.d

do_compile() {
	     oe_runmake
}

do_install() {
	     install -d ${D}${bindir}
	     install -m 0755 ${S}/hwutil ${D}${bindir}
	     install -m 0755 ${S}/pacman_menu ${D}${bindir}

	     install -d ${D}${sysconfdir}/init.d
	     install -m 0755 ${S}/gpio_init.sh ${D}${sysconfdir}/init.d/gpio_init
             install -m 0755 ${S}/gpio_init.sh ${D}${bindir}/gpio_init
}

FILES:${PN} += "${sysconfdir}/*"