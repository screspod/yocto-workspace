SUMMARY = "Company appliance image"

inherit core-image

# ADD FOR DOCKER: add these below for docker approach
# docker
# docker-compose

IMAGE_INSTALL += " \
    containerd-opencontainers \
    runc-opencontainers \
    nerdctl \
    http-echo-containerd \
    libseccomp \
"

IMAGE_INSTALL += " \
    packagegroup-core-boot \
"

SYSTEMD_AUTO_ENABLE = "enable"