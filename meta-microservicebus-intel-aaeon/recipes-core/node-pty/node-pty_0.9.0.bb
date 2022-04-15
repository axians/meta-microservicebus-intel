# Recipe created by recipetool
# This is the basis of a recipe and may need further editing in order to be fully functional.
# (Feel free to remove these comments when editing.)

SUMMARY = "Fork pseudoterminals in Node.JS"
HOMEPAGE = "https://github.com/Tyriar/node-pty"
# WARNING: the following LICENSE and LIC_FILES_CHKSUM values are best guesses - it is
# your responsibility to verify that the values are complete and correct.
#
# The following license files were not able to be identified and are
# represented as "Unknown" below, you will need to check them yourself:
#   LICENSE
#   node_modules/nan/LICENSE.md
#
# NOTE: multiple licenses have been detected; they have been separated with &
# in the LICENSE value for now since it is a reasonable assumption that all
# of the licenses apply. If instead there is a choice between the multiple
# licenses then you should change the value to separate the licenses with |
# instead of &. If there is any doubt, check the accompanying documentation
# to determine which situation is applicable.
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=c52651784ba3971ee506ab612dd90b72 \
                    file://deps/winpty/LICENSE;md5=f789abd9371883d4d06ae23a32aad961 \
                    file://node_modules/nan/LICENSE.md;md5=e6270b7774528599f2623a4aeb625829"

SRC_URI = "npm://registry.npmjs.org/;name=node-pty;version=${PV}"

NPM_SHRINKWRAP := "${THISDIR}/${PN}/npm-shrinkwrap.json"
NPM_LOCKDOWN := "${THISDIR}/${PN}/lockdown.json"
NPMPN = "node-pty"

inherit npm

# Must be set after inherit npm since that itself sets S
S = "${WORKDIR}/npmpkg"
LICENSE_${PN}-nan = "MIT"
LICENSE_${PN} = "MIT"


