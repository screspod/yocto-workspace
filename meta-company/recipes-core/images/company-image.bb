SUMMARY = "Company appliance image"

inherit core-image

IMAGE_INSTALL += " \
    containerd-opencontainers \
    runc-opencontainers \
    nerdctl \
    http-echo \
    libseccomp \
    packagegroup-core-boot \
    curl \
"

SYSTEMD_AUTO_ENABLE = "enable"