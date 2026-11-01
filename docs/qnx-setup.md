# QNX setup

The QNX SDP and the Raspberry Pi 4 BSP are license-gated. They stay outside this
repository and outside Nix; the build only reads them.

## License

1. Register at qnx.com.
1. In your account, add the license "QNX Software Development Platform 8.0 -
   Perpetual - Developer License - Non-Commercial Single-User License
   (Non-Commercial/Academic License Class) (ver. 8.0)" and note the license key.
1. Activate the key on this machine:

```sh
~ qlicense -userEmail your@email.com -activateLicenseKey XXXX-XXXX-XXXX-XXXX-XXXX
License key is added: XXXX-XXXX-XXXX-XXXX-XXXX
Info: Remote license activation is not required for this key

~ qlicense -listLicenseKeys
[XXXX-XXXX-XXXX-XXXX-XXXX] - Activated - QNX Software Development Platform 8.0 Education
```

## SDP

1. Download the SDP with QNX Software Center and extract it to `~/qnx800`.
1. Source the environment script **from bash**, before `nix develop`:

```sh
bash
. ~/qnx800/qnxsdp-env.sh
```

This sets, among others:

```sh
QNX_HOST=~/qnx800/host/linux/x86_64
QNX_TARGET=~/qnx800/target/qnx
MAKEFLAGS=-I~/qnx800/target/qnx/usr/include
```

## Raspberry Pi 4 BSP

1. Open QNX Software Center.
1. Select **Install New Packages**.
1. Search for **Raspberry Pi 4**.
1. Install the QNX SDP 8 BSP for Raspberry Pi 4 (BCM2711).
1. The BSP ZIP lands in the `bsp` directory of the SDP. Extract it to `~/qnx800-rpi4`:

```sh
mkdir -p ~/qnx800-rpi4
unzip ~/qnx800/bsp/BSP_raspberrypi-bcm2711-rpi4_*.zip -d ~/qnx800-rpi4
```

Use another location with `make qnx-ifs BSP_DIR=/path/to/qnx800-rpi4`. The first
build copies the BSP's `prebuilt/` tree into its `install/` tree, as the BSP's own
Makefile does; no compiler or license check is involved, only `mkifs`.

## Debug symbols

`mkifs` writes two `.sym` files into the git-ignored `qnx/build/` directory:

- `startup-bcm2711-rpi4.sym`: symbols for the BCM2711 startup executable, which
  initializes the CPU, RAM, MMU, GIC, timers, UART, and the QNX system page before
  the kernel starts.
- `procnto-smp-instr.sym`: symbols for the instrumented SMP QNX Neutrino kernel and
  process manager. `smp` indicates multiprocessor support and `instr` indicates
  kernel instrumentation support.

They are not executable and are not part of the IFS. They are useful for
source-level debugging, resolving crash addresses, interpreting dumps, and
profiling.
