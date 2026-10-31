SUMMARY = "os-lab base image: systemd, serial root shell, SSH"
LICENSE = "MIT"

inherit core-image

IMAGE_INSTALL = "packagegroup-core-boot ${CORE_IMAGE_EXTRA_INSTALL}"

# Development-only access; remove when hardening.
IMAGE_FEATURES += "ssh-server-dropbear allow-empty-password allow-root-login empty-root-password serial-autologin-root"
