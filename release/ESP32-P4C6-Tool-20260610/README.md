# ESP32-P4C6 Demo — Prebuilt Bundle

Everything you need to verify a board out of the box: the GUI as a standalone
app, prebuilt firmware for both chips, and small flash scripts that only need
`esptool` (no ESP-IDF install required).

## What's inside

```
ESP32-P4C6-Tool-<DATE>/
├── macos/
│   └── ESP32-P4C6-Tool.app          GUI for macOS (Apple Silicon)
├── windows/
│   └── ESP32-P4C6-Tool.exe          GUI for Windows (x64, single-file)
├── firmware/
│   ├── p4/                          ESP32-P4 firmware
│   │   ├── bootloader.bin
│   │   ├── partition-table.bin
│   │   ├── esp32p4c6_demo.bin
│   │   └── flash_args               offsets, for reference
│   └── c6/                          ESP32-C6 Wi-Fi/BLE co-processor firmware
│       ├── bootloader.bin
│       ├── partition-table.bin
│       ├── esp32c6_wifi_bt.bin
│       └── flash_args
└── scripts/
    ├── flash.sh                     standalone flasher (macOS / Linux)
    └── flash.ps1                    standalone flasher (Windows)
```

## 1. Flash the board

You need [`esptool`](https://github.com/espressif/esptool) on PATH:

```bash
python3 -m pip install --user esptool
```

Plug the board in over USB-C. **Three** serial ports appear — see the
identification table in the main repo's README for VID/PID details. The two you
need to flash are:

| Chip | USB ID | Port name (example) |
|------|--------|---------------------|
| ESP32-P4 (USB-Serial/JTAG) | `303A:1001` | `COM5` / `/dev/cu.usbmodem...` |
| ESP32-C6 (CH340G)          | `1A86:7523` | `COM4` / `/dev/cu.usbserial-...` |

### macOS / Linux

```bash
chmod +x scripts/flash.sh
./scripts/flash.sh --p4 /dev/cu.usbmodemXXXX --c6 /dev/cu.usbserial-XXXX
```

### Windows

```powershell
.\scripts\flash.ps1 -P4 COM5 -C6 COM4
```

Pass only `--p4` / `-P4` (or only `--c6` / `-C6`) to flash a single chip. After
flashing, **power-cycle the board** (unplug/replug the USB-C cable) so both
chips boot cleanly.

## 2. Run the GUI

### macOS

```bash
open macos/ESP32-P4C6-Tool.app
```

The first time, macOS Gatekeeper may complain because the bundle isn't
notarised. Right-click the app → **Open** → **Open** in the dialog. You only
need to do this once.

### Windows

Double-click `windows/ESP32-P4C6-Tool.exe`. It's a self-contained executable —
no Python install required.

If SmartScreen warns, click **More info** → **Run anyway**.

## 3. Connect

1. In the GUI top bar, click **Refresh**, then pick the **P4 USB-CDC** port
   (`303A:4001`, shown as *USB Serial Device* on Windows or
   `/dev/cu.usbmodem...` on macOS). This is **not** the same as the P4 flash
   port — it's the third port that appears.
2. Click **Aliases…** to give your ports friendly names if you have multiple
   boards plugged in.
3. **Connect** → green dot, firmware version in the status bar.
4. **Ping board** → confirms two-way traffic.

From there, work through the tabs (GPIO, CAN, Wi-Fi, etc.). The CAN tab's
**Self-test (loopback)** button verifies the TWAI controller without any
external wiring.

## Bundle vs. building from source

This bundle is everything you need to flash and run a board. If you want to
modify the firmware or rebuild the GUI from source, clone the main repo and
follow `docs/getting_started.md` — the **Setup** and **Flash** tabs in the GUI
let you build straight from source without using shell scripts.

## Troubleshooting

- **"esptool not found"** — install it: `python3 -m pip install --user esptool`
- **GUI: "Failed to open port"** — close any other program holding the port (a
  serial monitor, a previous GUI instance, `idf.py monitor`).
- **CAN self-test fails** — the firmware build is bad; re-flash from this bundle.
- **Wi-Fi / BLE scan shows nothing** — power-cycle the board. The C6's reset
  line is on the CH340's DTR/RTS, and a dangling open of the C6 port can hold
  it in reset.

For deeper issues, see `docs/troubleshooting.md` in the main repo.
