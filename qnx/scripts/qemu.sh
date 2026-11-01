#!/usr/bin/env bash
# Start and stop the QNX raspi4b QEMU image.
#   QEMU               qemu-system-aarch64 command (needs raspi4b support, QEMU 9+)
#   QEMU_BOOT_TIMEOUT  seconds to wait for the guest to finish booting (default 60)
set -euo pipefail

cd "$(dirname "$0")/.."

BUILD_DIR=build
IMAGE=$BUILD_DIR/ifs-rpi4-qemu.bin
PID_FILE=$BUILD_DIR/qemu.pid
LOG_FILE=$BUILD_DIR/qemu-serial.log
BOOT_OK="QNX startup complete"
BOOT_FAILED="QNX startup failed"
QEMU=${QEMU:-qemu-system-aarch64}
QEMU_BOOT_TIMEOUT=${QEMU_BOOT_TIMEOUT:-60}

usage() {
    cat <<EOF
Usage: $0 <command>
    start [-b|--background]  boot the image; in the foreground the serial console is
                             this terminal (exit with Ctrl+A X), in the background the
                             console goes to $LOG_FILE
    stop                     stop the background instance
    log                      print the background console log
EOF
}

is_running() {
    [ -r "$PID_FILE" ] && kill -0 "$(<"$PID_FILE")" 2>/dev/null
}

start() {
    local background=false
    while [ $# -gt 0 ]; do
        case $1 in
        -b | --background) background=true ;;
        -h | --help) usage; exit 0 ;;
        *) echo "Invalid argument: $1" >&2; exit 1 ;;
        esac
        shift
    done

    if [ ! -r "$IMAGE" ]; then
        echo "Image $IMAGE not found, build it first (make ifs)" >&2
        exit 1
    fi
    if is_running; then
        echo "QEMU is already running (pid $(<"$PID_FILE"))" >&2
        exit 1
    fi
    rm -f "$PID_FILE"

    # QEMU assigns -serial options in order: the first one is UART0, the QNX console.
    local args=(-machine raspi4b -kernel "$IMAGE" -display none -pidfile "$PID_FILE")

    if [ "$background" = false ]; then
        $QEMU "${args[@]}" -serial mon:stdio -serial null
        rm -f "$PID_FILE"
        return
    fi

    : > "$LOG_FILE"
    $QEMU "${args[@]}" -serial "file:$LOG_FILE" -serial null -daemonize

    echo "Waiting for boot"
    # Wall-clock deadline: the guest is emulated (TCG), so boot time varies with host load.
    local deadline=$((SECONDS + QEMU_BOOT_TIMEOUT))
    until grep -q "$BOOT_OK" "$LOG_FILE"; do
        if grep -q "$BOOT_FAILED" "$LOG_FILE"; then
            echo
            echo "The guest reported a failed boot, see $LOG_FILE" >&2
            stop
            exit 1
        fi
        echo -n "."
        sleep 0.5
        if ((SECONDS > deadline)); then
            echo
            echo "Aborting after waiting ${QEMU_BOOT_TIMEOUT} seconds for the guest to boot, see $LOG_FILE" >&2
            stop
            exit 1
        fi
    done
    echo
    echo "Booted (pid $(<"$PID_FILE")), console log: $LOG_FILE"
}

stop() {
    if ! is_running; then
        echo "QEMU is not running"
        rm -f "$PID_FILE"
        return
    fi
    kill "$(<"$PID_FILE")"
    rm -f "$PID_FILE"
}

cmd=${1:-}
shift || true

case $cmd in
start) start "$@" ;;
stop) stop ;;
log) cat "$LOG_FILE" ;;
*) usage; exit 1 ;;
esac
