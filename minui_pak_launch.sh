#!/bin/sh
# MinUI.pak launch script for RG351V on AmberELEC

export PLATFORM="rg351v"
export SDCARD_PATH="/storage/roms/MinUIAmber"
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
export SDL_AUDIODRIVER=alsa

# CPU speeds consumed by minui/minarch (PLAT_setCPUSpeed). A value that is not
# a real operating point is silently ignored by the kernel, leaving the clock
# wherever it was, so derive them from the OPP list this kernel actually
# publishes rather than hardcoding. (The old table asked for 1416000/1512000 on
# a board whose points stop at 1368000, so "performance" never left 1296000.)
_CPU_AVAIL=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_available_frequencies 2>/dev/null)
if [ -n "$_CPU_AVAIL" ]; then
	_CPU_TOP=$(echo "$_CPU_AVAIL" | tr ' ' '
' | grep -E '^[0-9]+$' | sort -n | tail -1)
	_CPU_BOT=$(echo "$_CPU_AVAIL" | tr ' ' '
' | grep -E '^[0-9]+$' | sort -n | head -1)
	_CPU_MID=$(echo "$_CPU_AVAIL" | tr ' ' '
' | grep -E '^[0-9]+$' | sort -n | awk '{a[NR]=$1} END {print a[int(NR*3/4)]}')
fi
export CPU_SPEED_MENU=${_CPU_BOT:-816000}
export CPU_SPEED_POWERSAVE=${_CPU_BOT:-816000}
export CPU_SPEED_GAME=${_CPU_MID:-1296000}
export CPU_SPEED_PERF=${_CPU_TOP:-1368000}
export CPU_SPEED_MAX=${_CPU_TOP:-1368000}

mkdir -p "$BIOS_PATH"
mkdir -p "$ROMS_PATH"
mkdir -p "$SAVES_PATH"
mkdir -p "$CHEATS_PATH"
mkdir -p "$USERDATA_PATH"
mkdir -p "$LOGS_PATH"
mkdir -p "$SHARED_USERDATA_PATH/.minui"

export LD_LIBRARY_PATH=$SYSTEM_PATH/lib:$LD_LIBRARY_PATH
export PATH=$SYSTEM_PATH/bin:$PATH

# Keep boot fast: re-mask the heavy services every boot so a prior
# "Return to EmulationStation" (which unmasks them) doesn't leave boot slow forever
systemctl mask syncthing.service smbd.service nmbd.service webui.service avahi-daemon.service avahi-defaults.service lastgame.service wsdd2.service pulseaudio.service 2>/dev/null || true

# Disable system sleep
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null || true

# AmberELEC ships HandlePowerKey=suspend, so logind races MinUI for the power
# button and suspends the device ("sleeps instead of powering off" bug).
# Override via /run drop-in: tmpfs, so it vanishes on reboot and never
# touches the AmberELEC config.
if [ ! -f /run/systemd/logind.conf.d/minui.conf ]; then
    mkdir -p /run/systemd/logind.conf.d
    printf '[Login]\nHandlePowerKey=ignore\nHandleSuspendKey=ignore\n' > /run/systemd/logind.conf.d/minui.conf
    systemctl try-restart systemd-logind 2>/dev/null || true
fi

# Disable screen blanking
echo 0 > /sys/class/graphics/fbcon/cursor_blink 2>/dev/null || true

# CPU governor: userspace is required for scaling_setspeed writes to take effect
GOVERNOR_PATH=/sys/devices/system/cpu/cpufreq/policy0/scaling_governor
CPU_PATH=/sys/devices/system/cpu/cpufreq/policy0/scaling_setspeed
MAXFREQ_PATH=/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
echo userspace > $GOVERNOR_PATH 2>/dev/null || true
# scaling_max_freq can boot clamped below the top operating point,
# which caps every later setspeed write; raise it first.
cat /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq > $MAXFREQ_PATH 2>/dev/null || true
echo $CPU_SPEED_PERF > $CPU_PATH 2>/dev/null || true

# The GPU and memory-controller devfreq nodes also boot clamped below their
# top operating point (RG351V: GPU 520 of 560MHz, DMC 786 of 840MHz), which
# silently costs performance in anything GPU or bandwidth bound. Lift each to
# the highest frequency it advertises.
for _df in /sys/class/devfreq/*.gpu /sys/class/devfreq/dmc; do
	[ -d "$_df" ] || continue
	_dftop=$(tr ' ' '
' < "$_df/available_frequencies" 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -1)
	if [ -n "$_dftop" ]; then
		echo "$_dftop" > "$_df/max_freq" 2>/dev/null || true
	fi
done


# Audio: the rk817 codec can probe after we start; early amixer calls fail
# silently and sound stays dead until the first volume keypress re-applies
# the mixer. Wait (bounded) for the card before touching it.
for _i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    [ -e /proc/asound/card0 ] && break
    sleep 0.5
done

# Audio routing: AmberELEC's autostart.sh sets the Playback Path AFTER the
# custom_start "before" hook we launch from, so MinUI must set it itself or
# audio routing is undefined
amixer -c 0 cset iface=MIXER,name='Playback Path' SPK_HP 2>/dev/null || true
amixer sset 'Playback' unmute 2>/dev/null || true

# Initialize volume on first run only; after that MinUI's saved volume wins
if [ ! -f "$USERDATA_PATH/.volume_initialized" ]; then
    amixer sset 'Playback' 40% 2>/dev/null || true
    touch "$USERDATA_PATH/.volume_initialized"
fi

keymon.elf &

cd $(dirname "$0")

# MinUI Amber boot splash -- once per boot only, not per menu-return
showpng.elf "$SDCARD_PATH/.system/res/logo.png" 2>/dev/null || true

EXEC_PATH="/tmp/minui_exec"
NEXT_PATH="/tmp/next"
touch "$EXEC_PATH" && sync
while [ -f $EXEC_PATH ]; do
    minui.elf > $LOGS_PATH/minui.txt 2>&1
    echo $CPU_SPEED_PERF > $CPU_PATH 2>/dev/null || true
    sync

    if [ -f $NEXT_PATH ]; then
        CMD=$(cat $NEXT_PATH)
        echo "CMD: $CMD" >> $LOGS_PATH/launch.log
        eval $CMD
        echo "EXIT: $?" >> $LOGS_PATH/launch.log
        rm -f $NEXT_PATH
        echo $CPU_SPEED_PERF > $CPU_PATH 2>/dev/null || true
        sync
    fi

    # self-heal: ports (gptokeyb) can leave the pad grabbed or kill keymon
    killall gptokeyb 2>/dev/null
    pidof keymon.elf > /dev/null 2>&1 || keymon.elf &

    if [ -f "/tmp/poweroff" ]; then
        rm -f "/tmp/poweroff"
        killall keymon.elf 2>/dev/null
        sync
        # -f skips the slow systemd shutdown sequence; everything is already synced.
        # On the RPP the orderly path took a minute+ with the screen frozen on.
        poweroff -f
        exit 0
    fi
done

killall keymon.elf 2>/dev/null
