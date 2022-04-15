FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# SRC_URI += " \
#     file://edge-health-check.sh \
# "

# #FILES_${PN} += " ${bindir}/edge-health-check.sh"
# FILES_${PN} += " ${bindir}"
# DIRFILES = "1"
# DEPENDS += " wireguard-tools"

# do_install_append() {
#     install -Dm 0755 ${WORKDIR}/edge-health-check.sh ${D}${bindir}
# }
