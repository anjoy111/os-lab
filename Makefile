# nix develop exports TMPDIR and kas forwards it to BitBake, which would move the build tree to /tmp.
KAS ?= env -u TMPDIR kas
KAS_CONFIG ?= linux/kas/oslab.yml
MC ?=

export KAS_WORK_DIR := $(CURDIR)/linux
export KAS_BUILD_DIR := $(CURDIR)/linux/build

QEMUBOOT := $(KAS_BUILD_DIR)/tmp-qemu/deploy/images/qemuarm64/oslab-image-qemuarm64.rootfs.qemuboot.conf

.PHONY: linux-checkout linux-build linux-shell linux-run-qemu linux-clean

linux/build:
	mkdir -p $@

linux-checkout: | linux/build
	$(KAS) checkout $(KAS_CONFIG)

linux-build: | linux/build
	$(KAS) build $(KAS_CONFIG) $(if $(MC),--target mc:$(MC):oslab-image)

linux-shell: | linux/build
	$(KAS) shell $(KAS_CONFIG)

linux-run-qemu: | linux/build
	$(KAS) shell $(KAS_CONFIG) -c "runqemu $(QEMUBOOT) nographic slirp"

linux-clean:
	rm -rf linux/build
