inherit systemd

SUMMARY = "Install init script for AAEON gateway"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI += "file://intel-aaeon-init.service \
            file://intel-aaeon-init.sh \
            file://remove-raid.sh" 


S = "${WORKDIR}"

SYSTEMD_PACKAGES = "${PN}"

SYSTEMD_SERVICE_${PN} = " intel-aaeon-init.service"

FILES_${PN} += "${systemd_system_unitdir}/intel-aaeon-init.service \
                ${bindir}/intel-aaeon-init.sh \
                ${bindir}/remove-raid.sh"

# Dynamic parameters
MSB_HOME_DIR_PATH ??= "/data/home/msb"
MSB_NODE_USER ??= "msb"
MSB_NODE_GROUP ??= "msb"
RAUC_VAR_DIR ?= "/data/var/rauc"
IOTEDGE ??= "FALSE"

do_install() {
             
    # Replace parameters in script
    sed -i -e 's:@MSB_NODE_USER@:${MSB_NODE_USER}:g' ${WORKDIR}/intel-aaeon-init.sh
    sed -i -e 's:@MSB_NODE_GROUP@:${MSB_NODE_GROUP}:g' ${WORKDIR}/intel-aaeon-init.sh
    sed -i -e 's:@MSB_HOME_DIR_PATH@:${MSB_HOME_DIR_PATH}:g' ${WORKDIR}/intel-aaeon-init.sh
    sed -i -e 's:@RAUC_VAR_DIR@:${RAUC_VAR_DIR}:g' ${WORKDIR}/intel-aaeon-init.sh
    sed -i -e 's:@IOTEDGE@:${IOTEDGE}:g' ${WORKDIR}/intel-aaeon-init.sh

    # Install service file
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/intel-aaeon-init.service ${D}${systemd_system_unitdir}

    # Install script
    install -d ${D}${bindir}
    install -m 0550 ${WORKDIR}/intel-aaeon-init.sh ${D}${bindir}/
    install -m 0550 ${WORKDIR}/remove-raid.sh ${D}${bindir}/

}

REQUIRED_DISTRO_FEATURES= "systemd"

