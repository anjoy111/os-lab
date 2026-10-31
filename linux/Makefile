# nix develop exports TMPDIR and kas forwards it to BitBake, which would move the build tree to /tmp.
KAS ?= env -u TMPDIR kas
KAS_CONFIG ?= kas/oslab.yml
MC ?=

export KAS_WORK_DIR := $(CURDIR)
export KAS_BUILD_DIR := $(CURDIR)/build

QEMUBOOT := $(KAS_BUILD_DIR)/tmp-qemu/deploy/images/qemuarm64/oslab-image-qemuarm64.rootfs.qemuboot.conf

.PHONY: all checkout build shell run-qemu clean

all: build

checkout:
	mkdir -p build
	$(KAS) checkout $(KAS_CONFIG)

build:
	mkdir -p build
	$(KAS) build $(KAS_CONFIG) $(if $(MC),--target mc:$(MC):oslab-image)

shell:
	mkdir -p build
	$(KAS) shell $(KAS_CONFIG)

run-qemu:
	mkdir -p build
	$(KAS) shell $(KAS_CONFIG) -c "runqemu $(QEMUBOOT) nographic slirp"

clean:
	rm -rf build
