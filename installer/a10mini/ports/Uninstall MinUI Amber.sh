#!/bin/bash
# /roms/ports/Uninstall MinUI Amber.sh
# Puts back the original firstboot.sh and panel DTB on the BOOT partition and
# reboots into EmulationStation. Your games, saves and the MinUIAmber folder
# are left alone.
exec /bin/bash /roms/MinUIAmber/EnableMinUIAmber.sh uninstall
