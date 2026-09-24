#!/bin/sh
# Tools/<platform>/Return to EmulationStation.pak/launch.sh  (AmberELEC)
#
# One-shot: drops back to ES for this session only. MinUI is still the boot
# front end next time; Ports -> Disable MinUI Amber makes ES permanent.
#
# Ending the MinUI.pak loop is all this has to do. When the loop ends,
# MinUI.pak/launch.sh gives back the services it masked, suspend and the
# power button, and AmberELEC's autostart then brings ES up.
rm -f /tmp/minui_exec
