#!/usr/bin/env bash
# ============================================================
# ESP32-P4C6 Demo — standalone flash script (macOS / Linux)
#
# Flashes the prebuilt ESP32-P4 and/or ESP32-C6 firmware shipped in this
# bundle. The only dependency is esptool (pip install esptool, or any
# Python with esptool available).
#
# Usage:
#   ./flash.sh --p4 /dev/cu.usbmodemXXXX
#   ./flash.sh --c6 /dev/cu.usbserial-XXXX
#   ./flash.sh --p4 /dev/cu.usbmodemXXXX --c6 /dev/cu.usbserial-XXXX
# ============================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P4_PORT=""; C6_PORT=""

while [ $# -gt 0 ]; do
    case "$1" in
        --p4)   P4_PORT="$2"; shift ;;
        --p4=*) P4_PORT="${1#*=}" ;;
        --c6)   C6_PORT="$2"; shift ;;
        --c6=*) C6_PORT="${1#*=}" ;;
        -h|--help)
            grep '^#' "$0" | sed 's/^#//'; exit 0 ;;
        *) echo "Unknown arg: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$P4_PORT" ] && [ -z "$C6_PORT" ]; then
    echo "ERROR: pass at least --p4 <port> or --c6 <port>"
    echo "       run with --help for examples"
    exit 1
fi

# Pick a python that has esptool. Prefer python3, then python.
PY=""
for cand in python3 python; do
    if command -v "$cand" >/dev/null 2>&1; then
        if "$cand" -c "import esptool" 2>/dev/null; then
            PY="$cand"; break
        fi
    fi
done

if [ -z "$PY" ]; then
    echo "ERROR: esptool not found. Install with:"
    echo "       python3 -m pip install --user esptool"
    exit 1
fi

flash_p4() {
    echo "=== Flashing ESP32-P4 on $P4_PORT ==="
    cd "$SCRIPT_DIR/../firmware/p4"
    "$PY" -m esptool --chip esp32p4 -p "$P4_PORT" -b 460800 \
        --before default_reset --after hard_reset \
        write_flash --flash_mode dio --flash_freq 80m --flash_size 4MB \
        0x2000  bootloader.bin \
        0x8000  partition-table.bin \
        0x10000 esp32p4c6_demo.bin
}

flash_c6() {
    echo "=== Flashing ESP32-C6 on $C6_PORT ==="
    cd "$SCRIPT_DIR/../firmware/c6"
    "$PY" -m esptool --chip esp32c6 -p "$C6_PORT" -b 460800 \
        --before default_reset --after hard_reset \
        write_flash --flash_mode dio --flash_freq 80m --flash_size 4MB \
        0x0     bootloader.bin \
        0x8000  partition-table.bin \
        0x10000 esp32c6_wifi_bt.bin
}

[ -n "$P4_PORT" ] && flash_p4
[ -n "$C6_PORT" ] && flash_c6

echo ""
echo "Done. Power-cycle the board (unplug/replug USB-C) so both chips boot cleanly."
