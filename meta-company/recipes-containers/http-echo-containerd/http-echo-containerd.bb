SUMMARY = "HTTP Echo containerd service"

LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI += " \
    file://http-echo.tar;unpack=0 \
    file://http-echo-containerd.service \
"

inherit systemd

SYSTEMD_PACKAGES = "${PN}"

SYSTEMD_SERVICE:${PN} = "http-echo-containerd.service"

SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} += " \
    /opt/containers/http-echo.tar \
    ${systemd_system_unitdir}/http-echo-containerd.service \
"

do_install() {
    install -d ${D}/opt/containers

    install -m 0644 \
        ${WORKDIR}/http-echo.tar \
        ${D}/opt/containers/http-echo.tar

    install -d ${D}${systemd_system_unitdir}

    install -m 0644 \
        ${WORKDIR}/http-echo-containerd.service \
        ${D}${systemd_system_unitdir}/http-echo-containerd.service
}