#!/usr/bin/env bash
# Derive a QEMU raspi4b buildfile from the Raspberry Pi 4 BSP buildfile.
#   - console moves from the mini UART to QEMU's PL011 UART0 (0xfe201000, IRQ 153)
#   - hardware watchdog (-W) and early register-mapped UART (-u reg) are dropped
#   - an interactive shell starts right after `pipe`, ahead of the board-specific
#     services (PCIe, SPI, SD, ...) that QEMU does not model and would block on
set -euo pipefail

in=${1:?usage: $0 <bsp rpi4.build> <output.build>}
out=${2:?usage: $0 <bsp rpi4.build> <output.build>}

sed -e 's/-D miniuart/-D pl011-3.fe201000^0.115200.48000000/' \
    -e 's/ -W 2500//' \
    -e 's/ -u reg//' \
    -e '/^[[:space:]]*pipe[[:space:]]*$/a\
    devc-serpl011 -b115200 -c48000000 -e -F -u1 0xfe201000,153\
    waitfor /dev/ser1\
    reopen /dev/ser1\
    display_msg "QNX on QEMU raspi4b"\
    [+session] ksh' \
    "$in" > "$out"

for expected in 'pl011-3.fe201000' 'devc-serpl011 -b115200' '\[+session\] ksh$'; do
    grep -q -- "$expected" "$out" || {
        echo "error: BSP buildfile changed, edit for '$expected' did not apply" >&2
        exit 1
    }
done
grep -q -- '-W 2500\|-u reg' "$out" && {
    echo "error: BSP buildfile changed, watchdog/early-UART options still present" >&2
    exit 1
}
exit 0
