#!/bin/sh
# Tools > Return to EmulationStation
# Ends MinUI's loop for this session; boot.sh then starts ES. The next
# reboot comes back to MinUI until "Disable MinUI Amber" is run from Ports.
rm -f /tmp/minui_exec
