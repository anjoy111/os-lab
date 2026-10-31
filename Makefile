KAS ?= kas
KAS_CONFIG ?= linux/kas/raspberrypi4-64.yml

export KAS_WORK_DIR := $(CURDIR)/linux

.PHONY: linux-checkout linux-build linux-shell linux-clean

linux-checkout:
	$(KAS) checkout $(KAS_CONFIG)

linux-build:
	$(KAS) build $(KAS_CONFIG)

linux-shell:
	$(KAS) shell $(KAS_CONFIG)

linux-clean:
	rm -rf linux/build
