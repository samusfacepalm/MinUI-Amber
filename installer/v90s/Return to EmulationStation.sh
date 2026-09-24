#!/bin/sh
# Tools/v90s/Return to EmulationStation.pak/launch.sh
#
# One-shot: drops back to ES for this session only. MinUI is still the boot
# front end next time. To change that permanently run
#   /userdata/roms/MinUIAmber/EnableMinUIAmber.sh off

# End the MinUI.pak loop once minui.elf returns
rm -f /tmp/minui_exec

killall keymon.elf 2>/dev/null

# Hand battery saving back to KNULLI (MinUI pauses it while it runs)
rm -f /var/run/battery-saver/minui.pause

# ES needs these; S31emulationstation sources them before launching
[ -f /etc/profile.d/xdg.sh ]  && . /etc/profile.d/xdg.sh
[ -f /etc/profile.d/dbus.sh ] && . /etc/profile.d/dbus.sh

# ...but not MinUI's own environment. MinUI.pak/launch.sh put .system/v90s in
# front of PATH and LD_LIBRARY_PATH, and ES passes its environment on to
# everything it launches. (emulationstation-standalone sets HOME itself.)
PATH=${PATH#"$SYSTEM_PATH/bin:"}
LD_LIBRARY_PATH=${LD_LIBRARY_PATH#"$SYSTEM_PATH/lib:"}
[ -n "$LD_LIBRARY_PATH" ] || unset LD_LIBRARY_PATH
unset SDL_AUDIODRIVER SDL_NOMOUSE PLATFORM SDCARD_PATH BIOS_PATH ROMS_PATH \
      SAVES_PATH CHEATS_PATH SYSTEM_PATH CORES_PATH USERDATA_PATH \
      SHARED_USERDATA_PATH LOGS_PATH
cd /userdata 2>/dev/null || cd /

# Start ES directly rather than via /etc/init.d/S31emulationstation: that
# script honours system.es.atstartup, which the installer set to 0, so it
# would decline to start.
emulationstation-standalone &

exit 0
