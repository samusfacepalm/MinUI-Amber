#!/bin/sh
# Tools > Display Fix
#
# Toggles the panel colour correction for the A10 Mini's 2.8" panel, which on
# many units looks dark and off-colour straight on and fine off-axis. Two
# stages, both DRM gamma LUTs:
#   gamma.cfg            applied at boot by ArkOS's gamma helper (0.9/0.85/0.9)
#   gamma-inprocess.cfg  applied by minui/minarch once they own the display (1.35)
# Off = both files renamed *.off. Takes effect from the next game or menu return.

S="$SYSTEM_PATH"
cd "$S"

GAMMA_TOOL="$S/bin/gamma"
[ -x "$GAMMA_TOOL" ] || GAMMA_TOOL="/roms/tools/Gamma/gamma"

if [ -f gamma.cfg ]; then
	mv -f gamma.cfg gamma.cfg.off
	[ -f gamma-inprocess.cfg ] && mv -f gamma-inprocess.cfg gamma-inprocess.cfg.off
	# The LUT already loaded stays in the display hardware until something
	# replaces it, so load a straight one now (nothing holds DRM master
	# while a tool pak runs).
	[ -x "$GAMMA_TOOL" ] && "$GAMMA_TOOL" -r 1.0 -g 1.0 -b 1.0 >/dev/null 2>&1
	MSG="Display fix: OFF"
else
	if [ -f gamma.cfg.off ]; then mv -f gamma.cfg.off gamma.cfg
	else printf -- '-r 0.9 -g 0.85 -b 0.9\n' > gamma.cfg; fi
	if [ -f gamma-inprocess.cfg.off ]; then mv -f gamma-inprocess.cfg.off gamma-inprocess.cfg
	else printf -- '-r 1.35 -g 1.35 -b 1.35\n' > gamma-inprocess.cfg; fi
	MSG="Display fix: ON"
fi
sync

say.elf "$MSG
(A to continue)"
