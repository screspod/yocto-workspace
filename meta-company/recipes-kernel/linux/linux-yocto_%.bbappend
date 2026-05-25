FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://seccomp.cfg"

KERNEL_CONFIG_FRAGMENTS += "seccomp.cfg"