# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository state

`os-lab` currently contains a Nix flake (host dev shells), a Yocto/kas project for Linux in `linux/`, and the planning docs. There is no application source, test suite, or lint step yet. Commit `flake.nix` and `flake.lock` together so tool versions stay pinned.

The roadmap (Linux and QNX images for Raspberry Pi 4 and QEMU, app build, lifecycle, resource limits, later hardening and OTA) is in `docs/project-plan.md`. Update this file as phases add real build and test commands.

## Linux image (Yocto Wrynose 6.0.4, Raspberry Pi 4)

Driven by [kas](https://kas.readthedocs.io); run inside `nix develop` (the `build` shell provides `kas`). The Makefile sets `KAS_WORK_DIR=linux/`, so layers, the build dir, and caches all live under `linux/` (git-ignored: `layers/`, `build/`, `cache/`).

```sh
make linux-checkout   # clone the pinned layers
make linux-build      # kas build -> oslab-image for raspberrypi4-64
make linux-shell      # kas shell (then: bitbake -p, bitbake -e oslab-image, ...)
make linux-clean      # remove linux/build (keeps downloads and sstate)
```

Build output (wic images) lands in `linux/build/tmp/deploy/images/raspberrypi4-64/`. A fast config check that avoids a full build: `make linux-shell`, then `bitbake -p && bitbake -n oslab-image`.

Structure:
- `linux/kas/base.yml` pins every layer by commit and sets the distro/target; `linux/kas/raspberrypi4-64.yml` adds the machine. Add new machines as another small file that includes `base.yml`.
- Wrynose has no `poky` repo: BitBake, `openembedded-core`, `meta-yocto` (for `meta-poky`) and `meta-raspberrypi` are separate repos. The first three are pinned to the `yocto-6.0.4` tag commits; `meta-raspberrypi` has no tags, so it is pinned to a `wrynose` branch commit. Bump pins deliberately, together.
- `linux/meta-oslab` is the project layer: the `oslab` distro (poky plus systemd as init manager, so lifecycle and cgroup experiments use systemd) and `oslab-image`. The image installs only `packagegroup-core-boot` on purpose; `core-image`'s default pulls in Wi-Fi/Bluetooth packages that need the restricted Broadcom firmware licence.
- `oslab-image` enables empty-password root and serial autologin for lab use only; remove these when hardening.
- Wrynose renamed some variables (e.g. `DISTRO_FEATURES_BACKFILL_CONSIDERED` is now `DISTRO_FEATURES_OPTED_OUT`); `bitbake -p` reports these as errors.

## Dev shells

Single flake, `x86_64-linux` only, pinned to `nixpkgs` `nixos-26.05`. Each shell sets `PROJECT_ENV` to its name and prints a banner on entry.

```sh
nix develop            # same as .#build (default)
nix develop .#build    # gcc/make, cmake, ninja, python3, gtest, catch2, Yocto/BitBake host tools
nix develop .#runtime  # qemu, gdb, valgrind, perf, strace/ltrace, elfutils, networking tools
nix develop .#analysis # clang-tools (clang-format, clang-tidy), cppcheck, include-what-you-use
nix flake check        # evaluate the flake
nix flake update       # bump the nixpkgs pin (rewrites flake.lock)
```

The shells are deliberately split by purpose: compile-time tooling lives in `build`, execution/debugging in `runtime`, and formatting/static analysis in `analysis`. Add a tool to the shell matching its role instead of duplicating it across shells. `shellHook` in `runtime` calls `qemu-system-x86_64`, so keep `qemu` there.
