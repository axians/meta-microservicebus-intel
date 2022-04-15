SUMMARY = "Enable watchdogd"
DESCRIPTION = "Enable watchdogd"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI_append = " \
  file://intel-aaeon-watchdog.conf \
  file://edge-health-check.sh \
  "

do_install () {

	# Enable watchdog
	install -d ${D}${sysconfdir}/systemd/system.conf.d/
	install -m 0644 ${WORKDIR}/intel-aaeon-watchdog.conf ${D}${sysconfdir}/systemd/system.conf.d/

	install -d ${D}${bindir}/
        install -m 0755 ${WORKDIR}/edge-health-check.sh ${D}${bindir}/
}

FILES_${PN} = "${sysconfdir}/systemd/system.conf.d"
FILES_${PN} += " ${bindir}/edge-health-check.sh"
