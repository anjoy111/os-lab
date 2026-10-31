# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository state

`os-lab` currently contains a Nix flake (host dev shells), a Yocto/kas project for Linux in `linux/`, and the planning docs. There is no application source, test suite, or lint step yet. Commit `flake.nix` and `flake.lock` together so tool versions stay pinned.

The roadmap (Linux and QNX images for Raspberry Pi 4 and QEMU, app build, lifecycle, resource limits, later hardening and OTA) is in `docs/project-plan.md`. Update this file as phases add real build and test commands.

## Linux image (Yocto Wrynose 6.0.4, Raspberry Pi 4 and QEMU)

Driven by [kas](https://kas.readthedocs.io); run inside `nix develop` (the `build` shell provides `kas`). Always go through the Makefile: it sets `KAS_WORK_DIR=linux/` and `KAS_BUILD_DIR=linux/build`, and unsets `TMPDIR`. Layers, the build dir, and caches live under `linux/` (git-ignored: `layers/`, `build/`, `cache/`).

This is a BitBake **multiconfig** project: one build dir and one BitBake server build several machines. The multiconfigs are `rpi4` (`raspberrypi4-64`) and `qemu` (`qemuarm64`), each building `oslab-image`.

```sh
make linux-checkout            # clone the pinned layers
make linux-build               # build all multiconfigs (mc:rpi4 and mc:qemu)
make linux-build MC=qemu       # build just one multiconfig (rpi4 or qemu)
make linux-run-qemu            # boot the qemu image (nographic; SSH on 127.0.0.1:2222; exit with Ctrl+A X)
make linux-shell               # kas shell (then: bitbake -p, bitbake -e mc:qemu:oslab-image, ...)
make linux-clean               # remove linux/build (keeps downloads and sstate in linux/cache)
```

Each multiconfig has its own `TMPDIR`, so images land in `linux/build/tmp-rpi4/deploy/images/raspberrypi4-64/` (wic for the SD card) and `linux/build/tmp-qemu/deploy/images/qemuarm64/`. Use the `mc:<name>:` prefix for any BitBake target, e.g. `bitbake -c cleansstate mc:qemu:linux-yocto`. A fast config check that avoids a full build: `make linux-shell`, then `bitbake -p && bitbake -n mc:rpi4:oslab-image mc:qemu:oslab-image`.

Gotchas:
- `nix develop` exports `TMPDIR` and kas forwards it to BitBake, which silently moves the whole build tree to `/tmp/nix-shell.*`. The Makefile's `env -u TMPDIR` prevents this; keep it if you invoke kas some other way.
- Only one BitBake command can run per build dir; a second one blocks on the first's server. Don't start a check while a build is running.
- kas derives `BBMULTICONFIG` from the `mc:` entries in the config's `target` list. Passing `--target mc:X:...` (what `MC=` does) therefore enables only that multiconfig for that run.
- Multiconfig files are parsed before `bitbake.conf`, so they set `MACHINE`, but the machine file is parsed after `local.conf`. A variable the machine sets with a plain `=` (e.g. `QB_CPU`) needs `:forcevariable` to be overridden.

Structure:
- `linux/kas/oslab.yml` is the single kas config: it pins every layer by commit and sets the distro and the `mc:` targets.
- `linux/meta-oslab/conf/multiconfig/<name>.conf` defines one multiconfig (`MACHINE`, its own `TMPDIR`, machine-specific settings). To add a target, add a `.conf` there and an `mc:<name>:oslab-image` entry to `target` in `oslab.yml`.
- `qemu` is the stock oe-core generic `virt` machine with the emulated CPU overridden to Cortex-A72 (the Pi 4 core), 4 cores, 1 GB RAM. It uses virtio devices and `linux-yocto`, not the Pi kernel, so it matches the Pi's CPU and userland but not its peripherals.
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
