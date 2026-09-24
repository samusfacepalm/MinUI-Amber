#!/bin/bash
# Roms/Portmaster (PORTS)/PortMaster.sh  —  KNULLI (V90S)
#
# Thin shim so PortMaster's own UI shows up as an entry inside MinUI. The real
# payload lives at the standard KNULLI path /userdata/roms/ports/PortMaster,
# so EmulationStation's own Ports menu keeps working too.
#
# PortMaster resolves its control folder to /roms/ports/PortMaster. AmberELEC
# ships /roms as a symlink to /storage/roms; KNULLI has no such link, so make
# one. It costs a few bytes in the overlay, is recreated here if a KNULLI
# update wipes it, and nothing else on the system looks at /roms.
PM=/userdata/roms/ports/PortMaster/PortMaster.sh
chmod 666 /dev/tty0 /dev/tty1 2>/dev/null
[ -e /roms ] || ln -s /userdata/roms /roms 2>/dev/null
if [ ! -f "$PM" ]; then
    echo "PortMaster is not installed."
    echo "Copy the release's ports/PortMaster folder to /userdata/roms/ports/."
    sleep 5
    exit 1
fi
chmod +x "$PM" 2>/dev/null
exec "$PM" "$@"
