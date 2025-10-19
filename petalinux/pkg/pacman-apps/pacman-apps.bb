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
   file://pylib \
   file://utils \
   file://tests \
"

S = "${WORKDIR}"
homedir = "/home/root"

#inherit update-rc.d

do_compile() {
	oe_runmake
}

do_install() {
	# Install bin directory:
	install -d ${D}${bindir}

	# Install app binaries (strip .elf extension)
	for elf in $(find ${S}/bin -name "*.elf"); do
	    app=$(basename "${elf}" .elf)
	    install -m 0755 "${elf}" "${D}${bindir}/${app}"
	done

	# Install home directory:
	install -d ${D}${homedir}

	# Install pylib
	install -d ${D}${homedir}/pylib
	install -m 0755 ${S}/pylib/* ${D}${homedir}/pylib/

	# Install utility scripts
	install -d ${D}${homedir}/utils
	install -m 0755 ${S}/utils/* ${D}${homedir}/utils/

	# Install test scripts
	install -d ${D}${homedir}/tests
	install -m 0755 ${S}/tests/* ${D}${homedir}/tests/

	# Install init scripts:
	install -d ${D}${sysconfdir}/init.d
	install -m 0755 ${S}/utils/pacman_server.sh ${D}${sysconfdir}/init.d/pacman_server
	install -m 0755 ${S}/utils/pacman_gpio_init.sh ${D}${sysconfdir}/init.d/pacman_gpio_init
	# expected by legacy users here as well:
	install -m 0755 ${S}/utils/pacman_server.sh ${D}${bindir}/pacman_server

}


# run on target, post install:
pkg_postinst_ontarget:${PN} () {
    echo "Registering pacman init scripts..."

    if [ -x /etc/init.d/pacman_gpio_init ]; then
        update-rc.d pacman_gpio_init defaults
    fi
    if [ -x /etc/init.d/pacman_server ]; then
        update-rc.d pacman_server defaults
    fi
}

FILES:${PN} += "${sysconfdir}/*"
FILES:${PN} += "${homedir}/pylib/*"
FILES:${PN} += "${homedir}/utils/*"
FILES:${PN} += "${homedir}/tests/*"
FILES:${PN} += "${bindir}/*"

RDEPENDS:${PN} = "python3-core python3-pyzmq"
