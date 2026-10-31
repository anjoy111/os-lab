# os-lab Project Plan

## Purpose

os-lab is a hands-on lab for building small embedded operating-system images and
experimenting with OS-level behaviour on them. The same experiments are run on
two OS families (Linux and QNX) and two targets (Raspberry Pi 4 hardware and a
QEMU image), so the differences between the OSes become visible side by side.

The work grows one step at a time. Each phase builds on the previous one and ends
with something that boots, runs, and can be demonstrated.

## Scope

In scope, in order:

1. Build bootable OS images (Linux, QNX) for Raspberry Pi 4 and QEMU.
2. Build and ship applications into those images.
3. Manage application lifecycle (start, stop, restart, supervision).
4. Apply resource limits to applications (RAM, CPU, and related).
5. Later: OS hardening.
6. Later: OTA updates and further components.

Out of scope for now: other boards, graphical stacks, networking services beyond
what debugging needs, production certification.

## Target matrix

| OS    | Raspberry Pi 4 (BCM2711)        | QEMU                                   |
|-------|---------------------------------|----------------------------------------|
| Linux | Yocto (or Buildroot) image, SD  | Same userland, QEMU aarch64 machine    |
| QNX   | QNX SDP 8 RPi4 BSP, IFS image   | IFS booted via QEMU (see qemu-bringup) |

Goal for every phase: the QEMU image is the fast inner loop, the Pi 4 image is
the proof on real hardware. A feature is "done" when it works on QEMU for both
OSes, and on hardware where QEMU cannot model it faithfully.

## Principles

- **Reproducible host tooling.** All host tools come from the Nix flake
  (`nix develop .#build | .#runtime | .#analysis`). Nothing is installed globally.
- **QNX stays external.** The QNX SDP (`~/qnx800`) and the RPi4 BSP are
  license-gated. They are referenced as local impure inputs and never vendored,
  fetched, or committed.
- **Cross-compile from x86_64.** The host is x86_64-linux; all targets are
  aarch64.
- **One experiment, two OSes.** Where a concept exists on both (limits,
  supervision), implement it on both and record the differences.
- **Everything scripted.** Build, boot, and test run from documented commands,
  not manual steps.

## Proposed repository layout

Created incrementally as phases need it, not up front.

```
os-lab/
  flake.nix, flake.lock     host dev shells (exists)
  docs/                     plan, per-phase write-ups, comparison notes
  linux/                    Yocto: kas configs (kas/) and the meta-oslab layer
  qnx/                      QNX buildfiles, startup config, SLM config
  apps/                     sample applications shared by both OSes
  cmake/                    toolchain files (linux-aarch64, qnx-aarch64le)
  scripts/                  build / run / test helpers
  Makefile                  thin entry point delegating to scripts/
```

## Phases

### Phase 0: Foundation (mostly done)

- Nix flake with `build`, `runtime`, `analysis` shells. **Done.**
- Linux build system: Yocto Wrynose 6.0.4 driven by kas, in `linux/`. **Done.**
- Decide how this repo reuses `qemu-bringup` (copy, submodule, or reference).
- Add `Makefile` and `scripts/` skeleton; update `CLAUDE.md` with real commands.

Exit: a fresh clone can enter `nix develop` and run `make help`.

### Phase 1: Boot images

Goal: boot a minimal OS to a shell, on QEMU first, then on the Pi 4.

- **QNX:** adapt the RPi4 BSP buildfile (watchdog off, console on PL011 UART0)
  into an IFS, boot it in QEMU, then write it to an SD card for hardware. Much of
  this exists in `qemu-bringup`.
- **Linux:** minimal aarch64 image with kernel, init, and a serial console.
  Boot in QEMU, then produce an SD-card image for the Pi 4.
- Scripted `make`, `make run-qemu`, `make stop-qemu` targets for each OS.

Exit: both OSes reach a serial shell on QEMU and on a Pi 4. Document boot flow
differences (bootloader, kernel/IFS, root filesystem, init).

### Phase 2: Building and shipping applications

Goal: get our own code into the images.

- Toolchain files for Linux aarch64 and QNX aarch64le, selected from CMake.
- A small sample app in `apps/` with a gtest-based test, built for both OSes.
- Install the binary into each image (Linux: image recipe or overlay; QNX: add to
  the IFS or a mounted image).
- Run the unit tests inside QEMU as an automated check.

Exit: `make` produces images containing the sample app; the app runs at boot or
by hand; tests pass in QEMU for both OSes.

### Phase 3: Application lifecycle

Goal: apps start in order, are supervised, and recover from failure.

- **Linux:** systemd units: ordering and dependencies, `Restart=` policies,
  start/stop timeouts, watchdog integration, journald logging.
- **QNX:** Service Launch Manager (SLM) configuration: startup ordering,
  dependencies, restart-on-failure, plus the QNX logging path (`slog2`).
- Sample apps that exit cleanly, crash, hang, and ignore SIGTERM, to exercise
  each path.
- Compare: startup ordering model, restart semantics, shutdown behaviour,
  how a hung process is detected.

Exit: a documented matrix of lifecycle scenarios with observed behaviour on both
OSes, reproducible with scripts.

### Phase 4: Resource limits

Goal: constrain what an application can consume and observe what happens when it
hits the limit.

- **Linux:** cgroups v2 via systemd (`MemoryMax`, `CPUQuota`, `TasksMax`,
  `IOWeight`), plus rlimits (`LimitNOFILE`, `LimitCORE`, and similar).
- **QNX:** `setrlimit`/`ulimit`, scheduling priority and policy, and the
  partitioning facilities available in SDP 8 (adaptive partitioning for CPU
  budgets; confirm what memory-partitioning support exists in 8.0 before
  committing).
- Stress apps that deliberately leak memory, spin the CPU, and fork or open files
  without bound.
- Measure and record: OOM behaviour, CPU throttling, impact on neighbouring
  processes, and what logs are produced.

Exit: for each limit type, a repeatable experiment on both OSes with recorded
results and a note on where the two diverge.

### Phase 5: Observability and debugging (cross-cutting)

Introduced as needed during phases 2 to 4, and written up here.

- Remote debugging with gdb against QEMU and the Pi 4.
- Linux: strace, perf, valgrind. QNX: the SDP tracing and profiling tools.
- A short guide to diagnosing a crash and a resource-limit kill on each OS.

### Later phases (not scheduled)

Detailed planning waits until phases 1 to 4 are done.

- **Hardening.** Linux: read-only root filesystem, dropped capabilities,
  namespaces, seccomp, MAC (SELinux or AppArmor), dm-verity, secure boot. QNX:
  security policy and per-process abilities, secure boot options. Includes
  measuring the cost of each measure.
- **OTA updates.** A/B partitioning and rollback; candidates are RAUC, SWUpdate,
  or Mender on Linux, and a custom A/B scheme on QNX. Depends on a stable image
  layout and hardening decisions.
- **Further components** as ideas arise (secure storage, remote management,
  and so on).

## Open decisions

| Decision | Options | Notes |
|---|---|---|
| Linux QEMU machine | `raspi4b` vs generic `virt` | `raspi4b` mirrors the Pi 4 but models few peripherals. `virt` is more capable but differs from hardware. May use `raspi4b` for boot parity and `virt` for feature work. |
| QNX reuse | Reference `qemu-bringup` vs copy into `qnx/` | Reference avoids duplication; copy makes this repo self-contained. |
| Shared apps vs per-OS apps | One source tree, two builds vs separate | Prefer one tree behind a thin portability layer. |

## Risks

- **QNX licensing and access.** SDP and BSP must be present locally; CI or other
  machines cannot build QNX images without them.
- **QEMU fidelity.** The emulated Pi 4 lacks parts of the real hardware, so some
  results (timing, peripherals, thermal) only count on a Pi.
- **Yocto build cost.** First builds are long and disk-hungry; plan for a shared
  sstate/download cache.
- **Cross-OS comparability.** Limit mechanisms are not one-to-one, so write-ups
  must state exactly what each experiment measures.

## Definition of done per phase

- Build and boot steps are scripted and documented in `docs/`.
- Works on QEMU for both OSes, and on a Pi 4 where applicable.
- Observed behaviour and OS differences are written down.
- `CLAUDE.md` is updated with the new commands and architecture.
