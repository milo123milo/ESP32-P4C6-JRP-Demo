# ============================================================
# ESP32-P4C6 Demo — standalone flash script (Windows)
#
# Flashes the prebuilt ESP32-P4 and/or ESP32-C6 firmware shipped in this
# bundle. The only dependency is esptool (pip install esptool).
#
# Usage:
#   .\flash.ps1 -P4 COM5
#   .\flash.ps1 -C6 COM4
#   .\flash.ps1 -P4 COM5 -C6 COM4
# ============================================================

param(
    [string]$P4 = "",
    [string]$C6 = ""
)

$ErrorActionPreference = "Stop"
$ROOT = Split-Path -Parent $PSScriptRoot
$P4DIR = Join-Path $ROOT "firmware\p4"
$C6DIR = Join-Path $ROOT "firmware\c6"

if (-not $P4 -and -not $C6) {
    Write-Host "ERROR: pass at least -P4 <port> or -C6 <port>" -ForegroundColor Red
    Write-Host "       e.g.  .\flash.ps1 -P4 COM5 -C6 COM4"
    exit 1
}

# Find a Python with esptool
$PY = $null
foreach ($cand in @("python", "py")) {
    $p = (Get-Command $cand -ErrorAction SilentlyContinue)
    if ($p) {
        $ErrorActionPreference = "Continue"
        & $p.Source -c "import esptool" 2>$null
        $rc = $LASTEXITCODE
        $ErrorActionPreference = "Stop"
        if ($rc -eq 0) { $PY = $p.Source; break }
    }
}

if (-not $PY) {
    Write-Host "ERROR: esptool not found. Install with:" -ForegroundColor Red
    Write-Host "       python -m pip install --user esptool"
    exit 1
}

function Flash-P4 {
    Write-Host "=== Flashing ESP32-P4 on $P4 ===" -ForegroundColor Cyan
    Push-Location $P4DIR
    & $PY -m esptool --chip esp32p4 -p $P4 -b 460800 `
        --before default_reset --after hard_reset `
        write_flash --flash_mode dio --flash_freq 80m --flash_size 4MB `
        0x2000  bootloader.bin `
        0x8000  partition-table.bin `
        0x10000 esp32p4c6_demo.bin
    Pop-Location
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

function Flash-C6 {
    Write-Host "=== Flashing ESP32-C6 on $C6 ===" -ForegroundColor Cyan
    Push-Location $C6DIR
    & $PY -m esptool --chip esp32c6 -p $C6 -b 460800 `
        --before default_reset --after hard_reset `
        write_flash --flash_mode dio --flash_freq 80m --flash_size 4MB `
        0x0     bootloader.bin `
        0x8000  partition-table.bin `
        0x10000 esp32c6_wifi_bt.bin
    Pop-Location
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if ($P4) { Flash-P4 }
if ($C6) { Flash-C6 }

Write-Host ""
Write-Host "Done. Power-cycle the board (unplug/replug USB-C) so both chips boot cleanly." -ForegroundColor Green
