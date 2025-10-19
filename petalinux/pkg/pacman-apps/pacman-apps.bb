#
# This file is the pacman package recipe.
#

SUMMARY = "PACMAN petalinux applications"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
DEPENDS = "zeromq i2c-tools"

SRC_URI = " \
   file://src \
   file://include \
   file://Makefile \
   file://utils \
   file://tests \
"

INITSCRIPT_NAME = "pacman_server"
INITSCRIPT_PARAMS = "start 99 S ."

S = "${WORKDIR}"
homedir = "/home/root"

inherit update-rc.d

do_compile() {
	oe_runmake
}

do_install() {

	# Install bin directory:
	install -d ${D}${bindir}

	# Install app binaries (ELFs)
	for elf in $(find ${WORKDIR}/bin -name "*.elf"); do
	    app=$(basename "$elf")
	    install -m 0755 "$elf" "${D}${bindir}/$app"
	done

	# Install app binaries (ELFs)
	for elf in $(find ${WORKDIR}/bin -name "*.elf"); do
	    app=$(basename $elf)
	    install -m 0755 $elf ${D}${bindir}/$app
	done

	# Install home directory:
	install -d ${D}${homedir}

	# Install utility scripts
	install -d ${D}${homedir}/utils
	cp -a ${WORKDIR}/utils/* ${D}${homedir}/utils/

	# Install test scripts
	install -d ${D}${homedir}/tests
	cp -a ${WORKDIR}/tests/* ${D}${homedir}/tests/

	# Install init script:
	install -d ${D}${sysconfdir}/init.d
	install -m 0755 ${WORKDIR}/utils/pacman_server.sh ${D}${sysconfdir}/init.d/pacman_server
	install -m 0755 ${WORKDIR}/utils/pacman_server.sh ${D}${bindir}/pacman_server
}

FILES:${PN} += "${sysconfdir}/*"
FILES:${PN} += "${homedir}/utils/*"
FILES:${PN} += "${homedir}/tests/*"
FILES:${PN} += "${bindir}/*"

RDEPENDS:${PN} = "python3-core python3-pyzmq"
