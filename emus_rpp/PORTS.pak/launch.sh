#!/bin/sh
# PORTS.pak launch.sh — runs .sh entries from Roms/Portmaster (PORTS)/.
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

# Ports (gptokeyb in particular) can leave the pad grabbed on exit; let go of
# it so emulated games still have input afterwards. If the port took keymon
# down too, the MinUI.pak loop restarts it as soon as this returns -- doing it
# here as well could start a second one.
killall gptokeyb 2>/dev/null
