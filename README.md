# os-lab

A hands-on lab for building small embedded OS images and experimenting with OS-level behaviour on them: building and shipping applications, managing their lifecycle, and limiting their resources (RAM, CPU). Hardening and OTA updates come later.

The plan is to run the same experiments on Linux and QNX, on a Raspberry Pi 4 and on QEMU. See [docs/project-plan.md](docs/project-plan.md) for the phases, decisions, and risks.

## Status

| OS    | Raspberry Pi 4                | QEMU                          |
|-------|-------------------------------|-------------------------------|
| Linux | Yocto config done, not built  | Yocto config done, not built  |
| QNX   | Not started                   | IFS builds, boots to a shell  |

The Linux configuration parses and dry-runs cleanly; no Linux image has been built and booted yet. The QNX image has been built and booted to a serial shell on QEMU's `raspi4b` machine.

## Requirements

- Linux x86_64 host (developed on Ubuntu 24.04).
- [Nix](https://nixos.org/download) with flakes enabled. All host tools (kas, cmake, QEMU, ...) come from the flake.
- Disk and time for Yocto: tens of GB, and a first build takes hours.
- For QNX: a local QNX SDP 8 install at `~/qnx800` (with a license) and the Raspberry Pi 4 BSP extracted to `~/qnx800-rpi4` from the zip in `~/qnx800/bsp`. These are license-gated and are never committed to this repo.

## Quick start (Linux image)

```sh
nix develop                    # host tools, including kas
make linux-checkout            # clone the pinned Yocto layers
make linux-build               # build the Pi 4 and QEMU images
make linux-run-qemu            # boot the QEMU image (exit with Ctrl+A, then X)
```

Build one image only with `make linux-build MC=rpi4` or `MC=qemu`. Output goes to `linux/build/tmp-rpi4/deploy/images/raspberrypi4-64/` (an SD-card `.wic` image) and `linux/build/tmp-qemu/deploy/images/qemuarm64/`.

The QEMU image listens for SSH on `127.0.0.1:2222`. Images have an empty root password and an autologin serial console for lab use; this is removed when hardening.

## Quick start (QNX image)

```sh
bash
. ~/qnx800/qnxsdp-env.sh       # must be sourced from bash, before nix develop
nix develop
make qnx-ifs                   # build qnx/build/ifs-rpi4-qemu.bin from the BSP
make qnx-run-qemu              # boot it on QEMU raspi4b (exit with Ctrl+A, then X)
```

The image boots straight to a serial shell. Only what QEMU models works (CPU, memory, serial console); the BSP's PCIe, SPI, SD, USB and network services are not started.

## Layout

```
flake.nix        host dev shells: build, runtime, analysis
Makefile         top level: delegates to the Makefile of each component
linux/
  Makefile       Yocto/kas targets (checkout, build, shell, run-qemu, clean)
  kas/oslab.yml  kas config: pinned layers, distro, multiconfig targets
  meta-oslab/    project layer: oslab distro (systemd), oslab-image,
                 multiconfig files for rpi4 and qemu
qnx/
  Makefile       QNX targets (ifs, inspect, run-qemu, clean)
  derive-qemu-buildfile.sh   turns the BSP buildfile into a QEMU one
docs/            project plan
```

The Linux side is a Yocto Wrynose 6.0.4 [BitBake multiconfig](https://docs.yoctoproject.org/) project driven by [kas](https://kas.readthedocs.io): one build directory and one BitBake server build both machines, each with its own `TMPDIR`. Wrynose no longer ships a `poky` repo, so BitBake, OpenEmbedded-Core, `meta-yocto`, and `meta-raspberrypi` are fetched separately and pinned by commit in `linux/kas/oslab.yml`.

The QEMU image is the generic `qemuarm64` (`virt`) machine with a Cortex-A72 CPU, matching the Pi 4 core but not its peripherals.

## Dev shells

```sh
nix develop .#build      # compile and Yocto host tools, kas (default)
nix develop .#runtime    # QEMU, gdb, valgrind, perf, strace
nix develop .#analysis   # clang-format, clang-tidy, cppcheck
```

## Notes

- `make <component>-<target>` from the top level is the same as `make -C <component> <target>`, so `make linux-shell` equals `make -C linux shell`. Bare `make` builds everything, including the hours-long Yocto build.
- Always build Linux through its Makefile; it unsets the `TMPDIR` that `nix develop` exports, which would otherwise send the BitBake build tree to `/tmp`.
- Only one BitBake command can run per build directory at a time.
- More detail for working in this repo is in [CLAUDE.md](CLAUDE.md).
