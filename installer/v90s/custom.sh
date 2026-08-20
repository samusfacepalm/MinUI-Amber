#!/bin/bash
# /userdata/system/custom.sh
#
# KNULLI's S99userservices runs this at the end of boot ("start") and at
# shutdown ("stop"). It is the only hook we need: MinUIAmber lives entirely
# under /userdata, so a KNULLI update cannot remove it.
#
# EmulationStation must already be disabled at startup, which
# EnableMinUIAmber.sh does via `batocera-settings-set system.es.atstartup 0`.
# Without that, S31emulationstation (which runs long before S99) would grab
# the framebuffer first.

MINUI_LAUNCH="/userdata/roms/MinUIAmber/.system/v90s/paks/MinUI.pak/launch.sh"

case "$1" in
    start)
        if [ -f "$MINUI_LAUNCH" ]; then
            chmod +x "$MINUI_LAUNCH" 2>/dev/null
            exec /bin/sh "$MINUI_LAUNCH"
        else
            echo "custom.sh: $MINUI_LAUNCH not found, leaving ES alone" >&2
        fi
        ;;
    stop)
        rm -f /tmp/minui_exec
        rm -f /var/run/battery-saver/minui.pause
        killall minui.elf   2>/dev/null
        killall minarch.elf 2>/dev/null
        killall keymon.elf  2>/dev/null
        ;;
esac

exit 0
