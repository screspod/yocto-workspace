SUMMARY = "HTTP echo container"

LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI += "file://docker-compose.yml"
SRC_URI += "file://http-echo.service"

inherit systemd

do_install() {
    install -d ${D}/opt/http-echo
    install -m 0644 ${WORKDIR}/docker-compose.yml ${D}/opt/http-echo/docker-compose.yml

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/http-echo.service \
        ${D}${systemd_system_unitdir}/http-echo.service
}

SYSTEMD_SERVICE:${PN} = "http-echo.service"
