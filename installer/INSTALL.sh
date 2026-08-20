#!/bin/sh
# MinUIAmber SSH installer for AmberELEC (RG351V / RPP).
#
#   ssh root@<device> sh /storage/roms/MinUIAmber/INSTALL.sh
#
# This is only a convenience wrapper. The supported install path is the
# EmulationStation PORTS menu:
#
#   Ports -> Enable MinUIAmber     (switch to MinUI, reboots)
#   Ports -> Disable MinUIAmber    (back to EmulationStation, reboots)
#
# Copy ports/Enable MinUIAmber.sh and ports/Disable MinUIAmber.sh into
# /storage/roms/ports/ to get those entries.

exec /storage/roms/MinUIAmber/EnableMinUIAmber.sh "${1:-on}"
