#!/bin/bash
# MinUI.pak launch script for the YMC A10 Mini on ArkOS (ArkOS4Clone build).
#
# Differences from the RG351V/AmberELEC script, all of them consequences of
# the OS rather than the hardware (same RK3326; 640x480 panel, 720x540 on
# the V4, which platform.c detects from the panel mode):
#   - ArkOS is Ubuntu 19.10 with systemd; ES runs as user "ark" from
#     emulationstation.service. We run before it, as root, from a hook in
#     /boot/firstboot.sh (see boot.sh) which holds ES off until MinUI exits
#   - ArkOS runs its own hotkey daemon (oga_events / ogage) and, optionally,
#     an input-idle auto-suspend service; both have to be stood down while
#     MinUI owns the input nodes
#   - /bin/sh is dash here too, so this file says #!/bin/bash and is run
#     with bash; nothing below needs bash but nothing below is dash-only
#   - everything of ours lives on the exFAT EASYROMS partition at /roms,
#     which an ArkOS reflash of the OS partition leaves alone

export PLATFORM="a10mini"
export SDCARD_PATH="/roms/MinUIAmber"
export BIOS_PATH="$SDCARD_PATH/Bios"
export ROMS_PATH="$SDCARD_PATH/Roms"
export SAVES_PATH="$SDCARD_PATH/Saves"
export CHEATS_PATH="$SDCARD_PATH/Cheats"
export SYSTEM_PATH="$SDCARD_PATH/.system/$PLATFORM"
export CORES_PATH="$SYSTEM_PATH/cores"
export USERDATA_PATH="$SDCARD_PATH/.userdata/$PLATFORM"
export SHARED_USERDATA_PATH="$SDCARD_PATH/.userdata/shared"
export LOGS_PATH="$USERDATA_PATH/logs"
export HOME="$USERDATA_PATH"
export SDL_NOMOUSE=1

# ArkOS's SDL2 is a KMSDRM build (Rockchip DRM + libmali for GLES). Say so
# explicitly rather than letting SDL probe; there is no X11 or Wayland here.
export SDL_VIDEODRIVER=KMSDRM

# CPU ceiling, kHz. lcdyk's boot.ini caps this board at 1296 MHz even though
# the current DTB lists OPPs up to 1512; platform.c drops steps above this.
export CPU_SPEED_MAX=1296000
export SDL_AUDIODRIVER=alsa


mkdir -p "$BIOS_PATH"
mkdir -p "$ROMS_PATH"
mkdir -p "$SAVES_PATH"
mkdir -p "$CHEATS_PATH"
mkdir -p "$USERDATA_PATH"
mkdir -p "$LOGS_PATH"
mkdir -p "$SHARED_USERDATA_PATH/.minui"

# Per-boot logs: start fresh each boot so they never grow without bound.
: > "$LOGS_PATH/launch.log"
: > "$LOGS_PATH/gamma.log"
rm -f "$LOGS_PATH/alsa.log" # retired diagnostic

export LD_LIBRARY_PATH=$SYSTEM_PATH/lib:$LD_LIBRARY_PATH
export PATH=$SYSTEM_PATH/bin:$PATH

###############################################################################
# Stand down the ArkOS daemons that would fight MinUI for the pad.
#
# oga_events (ogage) is ArkOS's global hotkey listener: F + d-pad for
# brightness/volume, and it can also suspend the device. MinUI's keymon does
# the same job, so two listeners would double every press. autosuspend
# (auto_suspend.py) is off by default on ArkOS but if the user turned it on it
# watches for input idle and suspends; MinUI polls evdev directly, which that
# script does not see as activity. Both are started again by boot.sh when
# control goes back to EmulationStation.
###############################################################################
systemctl stop oga_events.service 2>/dev/null || true
systemctl stop autosuspend.service 2>/dev/null || true
pkill -9 -f /usr/local/bin/ogage 2>/dev/null || true
pkill -9 -f auto_suspend.py 2>/dev/null || true

# Disable console blanking on the framebuffer console
echo 0 > /sys/class/graphics/fbcon/cursor_blink 2>/dev/null || true

###############################################################################
# CPU / GPU / memory clocks.
#
# The platform code caps the CPU via scaling_max_freq, which works under any
# governor, so pick "performance" here and let MinUI's cap be the effective
# speed. (ArkOS itself does the same dance per game with perfmax/perfnorm.)
# The devfreq nodes boot clamped below their top operating point on RK3326
# (GPU 480 of 520MHz, DMC 666 of 786MHz on the RG351V); lift each to the
# highest frequency it advertises.
###############################################################################
echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor 2>/dev/null || true
cat /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq \
	> /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq 2>/dev/null || true
for _df in /sys/class/devfreq/*.gpu /sys/class/devfreq/dmc; do
	[ -d "$_df" ] || continue
	_dftop=$(tr ' ' '\n' < "$_df/available_frequencies" 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -1)
	if [ -n "$_dftop" ]; then
		echo performance > "$_df/governor" 2>/dev/null || true
		echo "$_dftop" > "$_df/max_freq" 2>/dev/null || true
	fi
done

###############################################################################
# Audio: rk817 codec on ALSA card 0. Wait (bounded) for the card, route to
# speaker+headphone like ArkOS's own fixvolume.sh does, and unmute.
###############################################################################
for _i in 1 2 3 4 5 6 7 8 9 10 11 12; do
	[ -e /proc/asound/card0 ] && break
	sleep 0.5
done

# ALSA config. There is no /etc/asound.conf on ArkOS; the dmix setup lives in
# /home/ark/.asoundrc, which we never see because HOME is USERDATA_PATH. Two
# things were tried and measured on the device:
#   plug -> hw:0,0 direct   very quiet and very crackly on the rk817
#   dmix (ArkOS's layout)   loud, clean except on the loudest passages
# so this is ArkOS's dmix with a larger buffer (8192 frames, ~186 ms at
# 44.1 kHz) for headroom. Rewritten every boot so no older variant lingers.
cat > "$HOME/.asoundrc" << 'ASOUND'
pcm.!default {
	type plug
	slave.pcm "dmixer"
}
pcm.dmixer {
	type dmix
	ipc_key 1024
	slave {
		pcm "hw:0,0"
		period_time 0
		period_size 1024
		buffer_size 8192
		rate 44100
	}
	bindings {
		0 0
		1 1
	}
}
ctl.!default { type hw card 0 }
ASOUND

# Panel colour correction (Tools > Display Fix). ArkOS ships a DRM gamma-LUT
# tool for the clone panels at /roms/tools/Gamma/gamma. If gamma.cfg exists
# in the platform tree, apply it before every launch, i.e. whenever nothing
# else holds DRM master. A copy in our own bin/ wins if present.
GAMMA_TOOL="$SYSTEM_PATH/bin/gamma"
[ -x "$GAMMA_TOOL" ] || GAMMA_TOOL="/roms/tools/Gamma/gamma"
GAMMA_CFG="$SYSTEM_PATH/gamma.cfg"
apply_gamma() {
	if [ -x "$GAMMA_TOOL" ] && [ -s "$GAMMA_CFG" ]; then
		"$GAMMA_TOOL" $(cat "$GAMMA_CFG") >> "$LOGS_PATH/gamma.log" 2>&1 || true
	fi
}
apply_gamma

# Second stage, from inside minui/minarch once SDL owns the display: the
# boot-time helper alone left the picture too dark; lifting the LUT again
# (1.35) once MinUI is up is what looked right. Off if the file is absent.
gamma_env() {
	if [ -s "$SYSTEM_PATH/gamma-inprocess.cfg" ]; then
		export MINUI_GAMMA_CFG="$SYSTEM_PATH/gamma-inprocess.cfg"
	else
		unset MINUI_GAMMA_CFG
	fi
}
gamma_env
amixer -c 0 cset iface=MIXER,name='Playback Path' SPK_HP 2>/dev/null || true
amixer -q sset 'Playback' unmute 2>/dev/null || true
# (volume itself: keymon sets MinUI's saved level as soon as it starts)

keymon.elf &

cd "$(dirname "$0")"

# No showpng splash: the menu is up within a second of this point, and a
# logo flashed in between just reads as a flicker.
printf "\033c" > /dev/tty1 2>/dev/null || true

EXEC_PATH="/tmp/minui_exec"
NEXT_PATH="/tmp/next"
touch "$EXEC_PATH" && sync
while [ -f $EXEC_PATH ]; do
	gamma_env
	minui.elf > "$LOGS_PATH/minui.txt" 2>&1
	sync
	apply_gamma

	if [ -f $NEXT_PATH ]; then
		CMD=$(cat $NEXT_PATH)
		echo "CMD: $CMD" >> "$LOGS_PATH/launch.log"
		gamma_env
		# minui leaves the CPU capped at menu speed; minarch sets its own,
		# but ports (PortMaster) would otherwise run at menu speed
		echo "$CPU_SPEED_MAX" > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq 2>/dev/null
		eval "$CMD"
		echo "EXIT: $?" >> "$LOGS_PATH/launch.log"
		rm -f $NEXT_PATH
		sync
		gamma_env
		apply_gamma
	fi

	# self-heal: ports (gptokeyb) can leave the pad grabbed or kill keymon.
	# Not when the loop is about to end (Return to EmulationStation): a
	# keymon started now could miss the killall below and live on under ES.
	# (synchronous check: `pidof ... || keymon.elf &` backgrounds the pidof too)
	killall gptokeyb 2>/dev/null
	if [ -f "$EXEC_PATH" ] && ! pidof keymon.elf > /dev/null 2>&1; then
		keymon.elf &
	fi

	if [ -f "/tmp/poweroff" ]; then
		rm -f "/tmp/poweroff"
		killall keymon.elf 2>/dev/null
		sync
		# Skip the orderly systemd sequence, which on these boards takes a
		# minute with the screen frozen on. Remount the exFAT card read-only
		# first so it is not left marked dirty (Windows would offer to
		# repair it). Nothing of ours is open for writing at this point.
		cd /
		mount -o remount,ro /roms 2>/dev/null || sync
		poweroff -f
		exit 0
	fi
done

killall keymon.elf 2>/dev/null
