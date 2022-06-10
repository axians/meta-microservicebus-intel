FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
RDEPENDS_${PN} += " bash"

SRC_URI_append = " \
  file://quintus-backup.sh \
  file://quintus-backup-cron \
  "

do_install_append () {
    install -m 0644 ${WORKDIR}/quintus-backup-cron ${D}${sysconfdir}/cron.d/quintus-backup-cron
    install -m 0755 ${WORKDIR}/quintus-backup.sh ${D}${bindir}/quintus-backup.sh
}
