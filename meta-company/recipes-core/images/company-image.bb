SUMMARY = "Company appliance image"

inherit core-image

IMAGE_FSTYPES += "wic"

QB_FSINFO = "wic:no-kernel-in-fs"
QB_KERNEL_ROOT = "/dev/vda3"

IMAGE_INSTALL += " \
    containerd-opencontainers \
    runc-opencontainers \
    nerdctl \
    http-echo \
    libseccomp \
    packagegroup-core-boot \
    curl \
"

# DEV tooling

IMAGE_INSTALL += " \
    curl \
    util-linux \
    parted \
"

SYSTEMD_AUTO_ENABLE = "enable"

WKS_FILE = "company-image.wks"

WKS_FILE_DEPENDS += "u-boot company-u-boot-script"

IMAGE_BOOT_FILES += "boot.scr"
