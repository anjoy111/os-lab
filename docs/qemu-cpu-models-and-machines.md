# QEMU: CPU models, machine types, and where to find what's supported

## What is QEMU

QEMU (Quick EMUlator) is a generic, open-source machine emulator and
virtualizer. It has two main modes:

- **System emulation** (`qemu-system-<arch>`) — emulates a full machine:
  CPU, RAM, and a set of peripherals (the *machine type*/*board*). This is
  what boots a full OS image, e.g. the QNX IFS images built in this repo
  (`make qnx-start-qemu`) or a Linux kernel.
- **User-mode emulation** (`qemu-<arch>`) — runs a single foreign-architecture
  binary on the host by translating its instructions on the fly, without
  emulating a whole machine (used for things like cross-arch CI/build steps,
  not for booting an OS).

Under KVM/Xen, QEMU can also act as the userspace/device-model half of a
hypervisor, with the hardware doing the actual CPU virtualization instead of
QEMU's software translation (TCG).

Two independent choices determine what QEMU boots:

- **Machine type** (`-machine`) — the virtual board/platform: what SoC,
  memory map, interrupt controller, and peripherals are present (e.g.
  `virt`, `raspi4b`).
- **CPU model** (`-cpu`) — which CPU core/features are exposed to the guest
  inside that machine.

Not every CPU model is valid on every machine type — the machine's
architecture and sometimes the specific board constrain which CPUs it can
host (see below).

## Selecting a CPU model

Pass `-cpu <model>[,<feature>=<on|off>,...]` to `qemu-system-<arch>`:

```sh
# Named model: emulates a specific real CPU generation
qemu-system-x86_64 -cpu Westmere

# Host passthrough: expose the host CPU's own features 1:1 (KVM only,
# fastest, but not safe to live-migrate to a different host CPU)
qemu-system-x86_64 -cpu host

# Named model with individual feature toggles
qemu-system-x86_64 -cpu Westmere,pcid=on,+vmx

# Arm example, as used for the aarch64 QNX targets in this repo
qemu-system-aarch64 -machine raspi4b -cpu cortex-a72
```

There are three broad kinds of CPU model:

- **Named/versioned models** (`Westmere`, `cortex-a72`, `qemu64`, ...) —
  a fixed, reproducible feature set. Good for reproducible builds/CI and
  for migration between hosts.
- **`host`** — passthrough of the actual host CPU (only meaningful with
  KVM acceleration, not with plain TCG software emulation).
- **`max`** — the most feature-complete CPU QEMU can emulate for that
  target, useful for testing against future/newest features under TCG.

Features can be added or removed on top of any named model with
`+feature` / `-feature` or `feature=on|off`.

### Finding out what's available *on the binary you actually have*

The authoritative source for "what can *this* QEMU do" is always the binary
itself, not a doc page, since support varies by version and build config:

```sh
qemu-system-aarch64 -cpu help        # list CPU models for this target
qemu-system-aarch64 -machine help    # list machine types for this target
qemu-system-aarch64 -M raspi4b -cpu help   # CPUs valid for one machine
```

From the QEMU monitor (HMP) or QMP on a running instance:

```
(qemu) info cpu-models
(qemu) info machines
```

or the QMP equivalents `query-cpu-definitions` / `query-machines`.

## Where to find the supported machines/CPUs per QEMU version

- **Per-target machine/CPU docs (current development docs):**
  <https://www.qemu.org/docs/master/system/targets.html> — the index of
  system-emulation targets (Arm, x86, PowerPC, RISC-V, s390x, MIPS, etc.),
  linking to each architecture's own page (e.g.
  [Arm 'virt' platform](https://www.qemu.org/docs/master/system/arm/virt.html))
  which lists the boards/machines and CPUs that target supports.
- **CPU model reference:**
  <https://www.qemu.org/docs/master/system/qemu-cpu-models.html> —
  explains `host` vs. named models vs. `max`, aliases, and x86/MIPS model
  catalogs in detail.
- **KVM-on-x86 recommendations:**
  <https://www.qemu.org/docs/master/system/i386/cpu.html>

`.../docs/master/...` always reflects the current development branch (i.e.
what's newest, not yet released). **For a specific released version**, the
versioned docs are hosted on Read the Docs, not qemu.org:

```
https://qemu.readthedocs.io/en/v<version>/system/targets.html
https://qemu.readthedocs.io/en/v<version>/system/qemu-cpu-models.html
```

e.g. <https://qemu.readthedocs.io/en/v8.1.5/system/qemu-cpu-models.html>.
Swap `v8.1.5` for the version you have (`qemu-system-<arch> --version`).

- **Per-release changes** (new machines/CPUs added in a given release) are
  announced in the release blog posts under <https://www.qemu.org/blog/>,
  e.g. [QEMU version 10.0.0 released](https://www.qemu.org/2025/04/23/qemu-10-0-0/).

In short: use `-cpu help` / `-machine help` against your actual binary for
ground truth, and the docs above when you want the full picture (including
machines/CPUs your build might not have enabled) or history of when support
was added.

Sources:
- [QEMU System Emulator Targets](https://www.qemu.org/docs/master/system/targets.html)
- [QEMU / KVM CPU model configuration](https://www.qemu.org/docs/master/system/qemu-cpu-models.html)
- [Recommendations for KVM CPU model configuration on x86 hosts](https://www.qemu.org/docs/master/system/i386/cpu.html)
- [QEMU documentation](https://www.qemu.org/documentation)
- [QEMU / KVM CPU model configuration — QEMU 8.1.5 (versioned docs example)](https://qemu.readthedocs.io/en/v8.1.5/system/qemu-cpu-models.html)
- [QEMU version 10.0.0 released](https://www.qemu.org/2025/04/23/qemu-10-0-0/)
