#!/bin/bash
# Enable, disable or uninstall MinUI Amber on ArkOS4Clone (A10 Mini v1/v2/V4).
# Run from EmulationStation's Ports menu (the three "... MinUI Amber" entries).
#
#   EnableMinUIAmber.sh            install/repair the boot hook, set the panel
#                                  to 60 Hz, enable, reboot into MinUI
#   EnableMinUIAmber.sh off        keep everything, boot to EmulationStation
#   EnableMinUIAmber.sh uninstall  restore the original BOOT files, reboot
#   EnableMinUIAmber.sh status     report, change nothing
#
# Enabling always re-runs the installer, so if an ArkOS update or the DTB
# selector replaces firstboot.sh or the DTB, "Enable MinUI Amber" repairs it.

set -u

MINUI_ROOT="/roms/MinUIAmber"
SYS="$MINUI_ROOT/.system/a10mini"
FLAG="$MINUI_ROOT/.disabled"

# Ports run as "ark"; make the console visible and writable for messages.
sudo chmod 666 /dev/tty1 2>/dev/null
printf "\033c" > /dev/tty1 2>/dev/null
out() { echo "$*"; echo "$*" > /dev/tty1 2>/dev/null; }
run() { sudo /bin/bash "$SYS/install.sh" "$@" 2>&1 | while IFS= read -r l; do out "$l"; done; return "${PIPESTATUS[0]}"; }

[ -f "$SYS/install.sh" ] || { out "MinUI Amber is not on this card: $SYS missing"; sleep 5; exit 1; }

case "${1:-on}" in
	status)
		run status; sleep 5; exit 0 ;;
	on|enable|"")
		out "Installing MinUI Amber..."
		if ! run install; then
			out "Install failed; nothing was enabled. See $MINUI_ROOT/.userdata/a10mini/logs/install.log"
			sleep 8; exit 1
		fi
		rm -f "$FLAG"; sync
		out "Enabled. Rebooting into MinUI." ;;
	off|disable)
		touch "$FLAG"; sync
		out "Disabled. Rebooting into EmulationStation." ;;
	uninstall)
		run uninstall
		rm -f "$FLAG"; sync
		out "Uninstalled. You can delete $MINUI_ROOT and the three MinUI Amber"
		out "entries in ports/ from a PC. Rebooting into EmulationStation." ;;
	*)
		out "usage: $(basename "$0") [on|off|uninstall|status]"; exit 1 ;;
esac

sleep 4
sudo reboot
