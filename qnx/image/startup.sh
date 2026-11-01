#!/bin/sh
# Platform setup, run once from the IFS boot script after the console is up.

setconf TIMEZONE UTC0
setconf _CS_HOSTNAME qnx-rpi4-qemu

slogger2
waitfor /dev/slog

dumper -d /tmp
mqueue
random

on -d slm -v /etc/system/slm/config/slm-qemu.xml

# SLM marks the end of the boot sequence by creating this file.
if waitfor /tmp/boot-complete 10; then
    echo "QNX startup complete"
else
    echo "QNX startup failed: SLM did not finish the boot sequence"
fi
