#!/bin/bash
# Roms/Ports (PORTS)/PortMaster.sh  —  AmberELEC (RG351V / RPP)
#
# Thin shim so PortMaster's own UI shows up as an entry inside MinUI. The real
# payload lives at the standard AmberELEC path /storage/roms/ports/PortMaster,
# so EmulationStation's own Ports menu keeps working too.
PM=/storage/roms/ports/PortMaster/PortMaster.sh
chmod 666 /dev/tty0 /dev/tty1 2>/dev/null
if [ ! -f "$PM" ]; then
    echo "PortMaster is not installed."
    echo "Copy the release's ports/PortMaster folder to /storage/roms/ports/."
    sleep 5
    exit 1
fi
chmod +x "$PM" 2>/dev/null
exec "$PM" "$@"
