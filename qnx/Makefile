BSP_DIR ?= $(HOME)/qnx800-rpi4
BSP_STARTUP := $(BSP_DIR)/install/aarch64le/boot/sys/startup-bcm2711-rpi4
# raspi4b needs QEMU 9+, newer than most distro packages, so use the one from the flake
QNX_QEMU ?= nix develop $(abspath $(CURDIR)/..)\#runtime -c qemu-system-aarch64
export QEMU = $(QNX_QEMU)

# help comes first for readability; the top-level Makefile relies on `all` being the default
.DEFAULT_GOAL := all
.PHONY: help all ifs inspect run-qemu start-qemu stop-qemu qemu-log clean check check-qemu

help: ## Show this help
	@echo "Usage: make -C qnx <target> [BSP_DIR=$(BSP_DIR)]   (from the top level: make qnx-<target>)"
	@echo
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

all: ifs ## Build the IFS (default)

ifs: build/ifs-rpi4-qemu.bin ## Build build/ifs-rpi4-qemu.bin

check:
	@test -n "$(QNX_TARGET)" || { echo "Source ~/qnx800/qnxsdp-env.sh from bash first" >&2; exit 1; }
	@test -r "$(BSP_DIR)/images/rpi4.build" || { echo "Raspberry Pi 4 BSP not found in BSP_DIR=$(BSP_DIR)" >&2; exit 1; }

check-qemu:
	@$(QNX_QEMU) -machine help 2>/dev/null | grep -q '^raspi4b ' || { echo "QEMU 9+ with raspi4b support is required (QNX_QEMU=$(QNX_QEMU))" >&2; exit 1; }

$(BSP_STARTUP): | check
	cp -rf "$(BSP_DIR)/prebuilt/." "$(BSP_DIR)/install/"

build/rpi4-qemu.build: $(BSP_DIR)/images/rpi4.build image/rpi4-qemu.extra.build scripts/derive-qemu-buildfile.sh | check
	mkdir -p build
	scripts/derive-qemu-buildfile.sh $< $@ image/rpi4-qemu.extra.build

build/ifs-rpi4-qemu.bin: build/rpi4-qemu.build image/startup.sh image/slm.xml $(BSP_STARTUP)
	cd build && mkifs -r"$(BSP_DIR)/install" rpi4-qemu.build ifs-rpi4-qemu.bin

inspect: build/ifs-rpi4-qemu.bin ## Dump the contents of the IFS
	dumpifs $<

run-qemu: build/ifs-rpi4-qemu.bin | check-qemu ## Boot in the foreground (Ctrl+A X to exit)
	scripts/qemu.sh start

start-qemu: build/ifs-rpi4-qemu.bin | check-qemu ## Boot in the background and wait for startup
	scripts/qemu.sh start --background

stop-qemu: ## Stop the background QEMU instance
	scripts/qemu.sh stop

qemu-log: ## Print the background console log
	scripts/qemu.sh log

clean: ## Remove build/
	rm -rf build
