# os-lab

A hands-on lab for building small embedded OS images and experimenting with OS-level behaviour on them: building and shipping applications, managing their lifecycle, and limiting their resources (RAM, CPU). Hardening and OTA updates come later.

The plan is to run the same experiments on Linux and QNX, on a Raspberry Pi 4 and on QEMU. See [docs/project-plan.md](docs/project-plan.md) for the phases, decisions, and risks.

## Status

| OS    | Raspberry Pi 4                | QEMU                          |
|-------|-------------------------------|-------------------------------|
| Linux | Yocto config done, not built  | Yocto config done, not built  |
| QNX   | Not started                   | Not started                   |

The Linux configuration parses and dry-runs cleanly; no image has been built and booted yet.

## Requirements

- Linux x86_64 host (developed on Ubuntu 24.04).
- [Nix](https://nixos.org/download) with flakes enabled. All host tools (kas, cmake, QEMU, ...) come from the flake.
- Disk and time for Yocto: tens of GB, and a first build takes hours.
- For the QNX work later: a local QNX SDP 8 install and the Raspberry Pi 4 BSP. These are license-gated and are never committed to this repo.

## Quick start (Linux image)

```sh
nix develop                    # host tools, including kas
make linux-checkout            # clone the pinned Yocto layers
make linux-build               # build the Pi 4 and QEMU images
make linux-run-qemu            # boot the QEMU image (exit with Ctrl+A, then X)
```

Build one image only with `make linux-build MC=rpi4` or `MC=qemu`. Output goes to `linux/build/tmp-rpi4/deploy/images/raspberrypi4-64/` (an SD-card `.wic` image) and `linux/build/tmp-qemu/deploy/images/qemuarm64/`.

The QEMU image listens for SSH on `127.0.0.1:2222`. Images have an empty root password and an autologin serial console for lab use; this is removed when hardening.

## Layout

```
flake.nix        host dev shells: build, runtime, analysis
Makefile         entry points for the Linux build
linux/
  kas/oslab.yml  kas config: pinned layers, distro, multiconfig targets
  meta-oslab/    project layer: oslab distro (systemd), oslab-image,
                 multiconfig files for rpi4 and qemu
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

- Always build through the `Makefile`; it unsets the `TMPDIR` that `nix develop` exports, which would otherwise send the BitBake build tree to `/tmp`.
- Only one BitBake command can run per build directory at a time.
- More detail for working in this repo is in [CLAUDE.md](CLAUDE.md).
