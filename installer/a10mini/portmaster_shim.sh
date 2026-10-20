#!/bin/bash
# Roms/Portmaster (PORTS)/PortMaster.sh
# ArkOS ships its own PortMaster at /roms/tools/PortMaster (bind-mounted at
# /opt/system/Tools); this just opens it from inside MinUI.
if [ -f /roms/tools/PortMaster.sh ]; then
	exec /bin/bash /roms/tools/PortMaster.sh
elif [ -f /roms/ports/PortMaster/PortMaster.sh ]; then
	exec /bin/bash /roms/ports/PortMaster/PortMaster.sh
else
	echo "PortMaster is not installed. Install it from ArkOS first." > /dev/tty1
	sleep 4
fi
