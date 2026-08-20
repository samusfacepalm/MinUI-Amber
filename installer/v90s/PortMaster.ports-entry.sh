#!/bin/bash
# Roms/Ports (PORTS)/PortMaster.sh
#
# Thin shim so PortMaster shows up in MinUI. The real payload lives at the
# standard KNULLI path so ES's own Ports menu keeps working too.
#
# PortMaster is not installed by default on KNULLI: run
# /userdata/roms/ports/Install.PortMaster.sh once (from ES → Ports) first.
chmod 666 /dev/tty1 2>/dev/null
PM=/userdata/roms/ports/PortMaster/PortMaster.sh
if [ ! -x "$PM" ]; then
    echo "PortMaster is not installed."
    echo "Run 'Install.PortMaster.sh' from EmulationStation's Ports menu first."
    sleep 5
    exit 1
fi
exec "$PM" "$@"
