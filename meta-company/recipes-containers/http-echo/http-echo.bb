SUMMARY = "HTTP Echo containerd service"

LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI += " \
    file://hashicorp-http-echo_1.0.0_arm64.oci.tar;unpack=0 \
    file://http-echo.service \
"

inherit systemd

SYSTEMD_PACKAGES = "${PN}"

SYSTEMD_SERVICE:${PN} = "http-echo.service"

SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} += " \
    /opt/containers/hashicorp-http-echo_1.0.0_arm64.oci.tar \
    ${systemd_system_unitdir}/http-echo.service \
"

do_install() {
    install -d ${D}/opt/containers

    install -m 0644 \
        ${WORKDIR}/hashicorp-http-echo_1.0.0_arm64.oci.tar \
        ${D}/opt/containers/hashicorp-http-echo_1.0.0_arm64.oci.tar

    install -d ${D}${systemd_system_unitdir}

    install -m 0644 \
        ${WORKDIR}/http-echo.service \
        ${D}${systemd_system_unitdir}/http-echo.service
}