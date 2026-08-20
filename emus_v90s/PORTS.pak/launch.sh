#!/bin/sh
# PORTS.pak launch.sh — runs .sh entries from Roms/Ports (PORTS)/.
# Invoked directly (not via `sh`) so each port's own shebang (#!/bin/bash,
# required by PortMaster's control.txt which uses bash-only `source`) is honored.

ROM="$1"
EMU_TAG=$(basename "$(dirname "$0")" .pak)
mkdir -p "$SAVES_PATH/$EMU_TAG" 2>/dev/null
HOME="$USERDATA_PATH"
export HOME
chmod +x "$ROM" 2>/dev/null
cd "$(dirname "$ROM")"
"$ROM" > "$LOGS_PATH/$EMU_TAG.txt" 2>&1

# Ports (gptokeyb in particular) can leave the pad grabbed or take keymon
# down with them on exit; clean up and self-heal so emulated games still
# have input afterwards
killall gptokeyb 2>/dev/null
pidof keymon.elf > /dev/null 2>&1 || keymon.elf &
