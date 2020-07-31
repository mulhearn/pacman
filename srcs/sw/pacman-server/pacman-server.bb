#
# This file is the pacman-server recipe.
#

SUMMARY = "Simple pacman-server application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
DEPENDS = "zeromq python python-pyzmq"

SRC_URI = "file://src \
           file://include \
           file://pacman_server.sh \
           file://power_up.sh \
           file://power_down.sh \
           file://README.md \
           file://pacman_util.py \
	   file://Makefile \
		  "
                  
INITSCRIPT_NAME = "pacman_server"
INITSCRIPT_PARAMS = "start 99 S ."

S = "${WORKDIR}"
homedir = "/home/root/"

inherit update-rc.d

do_compile() {
	     oe_runmake
}

do_install() {
	     install -d ${D}${bindir}
	     install -m 0755 ${S}/pacman_cmdserver ${D}${bindir}
             install -m 0755 ${S}/pacman_dataserver ${D}${bindir}

             install -d ${D}${homedir}
             install ${S}/README.md ${D}${homedir}
             install -m 0755 ${S}/pacman_util.py ${D}${homedir}
             install -m 0755 ${S}/power_up.sh ${D}${homedir}
             install -m 0755 ${S}/power_down.sh ${D}${homedir}             
             
             install -d ${D}${sysconfdir}/init.d
	     install -m 0755 ${S}/pacman_server.sh ${D}${sysconfdir}/init.d/pacman_server
             install -m 0755 ${S}/pacman_server.sh ${D}${bindir}/pacman_server
}

FILES_${PN} += "${sysconfdir}/*"
FILES_${PN} += "${homedir}/*"

RDEPENDS_${PN} += "python python-pyzmq"