# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository state

`os-lab` currently contains only a Nix flake (`flake.nix`, `flake.lock`) and no source code, build files, tests, or README. It defines dev shells for embedded/Yocto development; there is no build, lint, or test step in this repo itself. Commit `flake.nix` and `flake.lock` together so tool versions stay pinned.

The roadmap (Linux and QNX images for Raspberry Pi 4 and QEMU, app build, lifecycle, resource limits, later hardening and OTA) is in `docs/project-plan.md`. Update this file as phases add real build and test commands.

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
