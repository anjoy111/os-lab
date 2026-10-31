BSP_DIR ?= $(HOME)/qnx800-rpi4
BSP_STARTUP := $(BSP_DIR)/install/aarch64le/boot/sys/startup-bcm2711-rpi4
# raspi4b needs QEMU 9+, newer than most distro packages, so use the one from the flake
QNX_QEMU ?= nix develop $(abspath $(CURDIR)/..)\#runtime -c qemu-system-aarch64

.PHONY: all ifs inspect run-qemu clean check

all: ifs

ifs: build/ifs-rpi4-qemu.bin

check:
	@test -n "$(QNX_TARGET)" || { echo "Source ~/qnx800/qnxsdp-env.sh from bash first" >&2; exit 1; }
	@test -r "$(BSP_DIR)/images/rpi4.build" || { echo "Raspberry Pi 4 BSP not found in BSP_DIR=$(BSP_DIR)" >&2; exit 1; }

$(BSP_STARTUP): | check
	cp -rf "$(BSP_DIR)/prebuilt/." "$(BSP_DIR)/install/"

build/rpi4-qemu.build: $(BSP_DIR)/images/rpi4.build derive-qemu-buildfile.sh | check
	mkdir -p build
	./derive-qemu-buildfile.sh $< $@

build/ifs-rpi4-qemu.bin: build/rpi4-qemu.build $(BSP_STARTUP)
	cd build && mkifs -r"$(BSP_DIR)/install" rpi4-qemu.build ifs-rpi4-qemu.bin

inspect: build/ifs-rpi4-qemu.bin
	dumpifs $<

run-qemu: build/ifs-rpi4-qemu.bin
	$(QNX_QEMU) -machine raspi4b -kernel $< -serial mon:stdio -serial null -display none

clean:
	rm -rf build
