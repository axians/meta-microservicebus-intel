SUMMARY = "Manage users for microservicebus"
DESCRIPTION = "Create user for microservicebus-node"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit useradd

USERADD_PACKAGES = "${PN}"

GROUPADD_PARAM_${PN} = "-g 350 msb"

# Create mongodb user
USERADD_PARAM_${PN} = "-u 400 -g 350 -r -s /bin/nologin mongodb"

do_install() {
	install -d ${D}${sysconfdir}/dummy/
}

# Prevents do_package failures with:
# debugsources.list: No such file or directory:
#INHIBIT_PACKAGE_DEBUG_SPLIT = "1"