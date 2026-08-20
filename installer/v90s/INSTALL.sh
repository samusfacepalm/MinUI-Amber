#!/bin/sh
# MinUIAmber SSH installer for KNULLI (V90S).
#
#   ssh root@<device> sh /userdata/roms/MinUIAmber/INSTALL.sh
#
# Convenience wrapper only. The supported install path is the
# EmulationStation PORTS menu:
#
#   Ports -> Enable MinUI Amber     (switch to MinUI, reboots)
#   Ports -> Disable MinUI Amber    (back to EmulationStation, reboots)

exec /userdata/roms/MinUIAmber/EnableMinUIAmber.sh "${1:-on}"
