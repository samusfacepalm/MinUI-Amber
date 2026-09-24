#!/bin/sh
# MinUI.pak launch script for RPP (Retro Pixel Pocket) on AmberELEC
# Built from the verified-working v0.1 original, with only additions that
# don't touch power/suspend/input/audio behavior (those were the ones that
# broke when blindly carried over from the RG351V build).

export PLATFORM="rpp"
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

# CPU speeds for this script's own clock bumps (at start, after minui exits and
# after each pak). Derive them from the OPP list this kernel actually publishes
# rather than hardcoding: the old table asked for 1416000/1512000 on a board
# whose points stop at 1368000. minui and minarch don't read these -- they set
# their own speeds in PLAT_setCPUSpeed, which snaps to the same list.
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
# "Return to EmulationStation" (which unmasks them) doesn't leave boot slow
# forever. Not touching pulseaudio here -- the original script never masked
# it and audio worked; leave that alone.
SERVICES="syncthing.service smbd.service nmbd.service webui.service avahi-daemon.service avahi-defaults.service lastgame.service wsdd2.service"
systemctl mask $SERVICES 2>/dev/null || true

# Disable system sleep for as long as MinUI runs. --runtime puts the mask in
# /run: it lasts this boot only and can never outlive MinUI Amber. v0.2
# masked these permanently (AmberELEC keeps masks in
# /storage/.config/system.d), which broke suspend even after "Disable MinUI
# Amber" -- clear that out on installs that still carry it.
SLEEP_TARGETS="sleep.target suspend.target hibernate.target hybrid-sleep.target"
for _t in $SLEEP_TARGETS; do
    if [ -L "/storage/.config/system.d/$_t" ]; then
        systemctl unmask $SLEEP_TARGETS 2>/dev/null || true
        break
    fi
done
systemctl mask --runtime $SLEEP_TARGETS 2>/dev/null || true

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


# Audio routing: stock EmulationStation boot runs odroidgoa_utils.sh setaudio,
# which does `amixer cset name='Playback Path' SPK` -- verified in this
# device's own SYSTEM image (usr/bin/odroidgoa_utils.sh). MinUI's early hook
# bypasses that, leaving the rk817 codec's output path at its driver default
# (no output on current firmware). SPK_HP drives speaker and headphone jack
# together; fall back to stock's plain SPK if the enum rejects it.
amixer cset name='Playback Path' SPK_HP 2>/dev/null || amixer cset name='Playback Path' SPK 2>/dev/null || true

# Initialize volume -- unchanged from the working v0.1 original
amixer sset 'Playback' 94 2>/dev/null || true

keymon.elf &

cd $(dirname "$0")

EXEC_PATH="/tmp/minui_exec"
NEXT_PATH="/tmp/next"
touch "$EXEC_PATH" && sync
while [ -f $EXEC_PATH ]; do
    showpng.elf "$SDCARD_PATH/.system/res/logo.png" 2>/dev/null || true
    minui.elf > $LOGS_PATH/minui.txt 2>&1
    echo $CPU_SPEED_PERF > $CPU_PATH 2>/dev/null || true
    sync

    if [ -f $NEXT_PATH ]; then
        CMD=$(cat $NEXT_PATH)
        echo "CMD: $CMD" >> $LOGS_PATH/launch.log
        # quoted: unquoted, runs of spaces in a rom path collapse to one
        eval "$CMD"
        echo "EXIT: $?" >> $LOGS_PATH/launch.log
        rm -f $NEXT_PATH
        echo $CPU_SPEED_PERF > $CPU_PATH 2>/dev/null || true
        sync
    fi

    # self-heal: ports (gptokeyb) can leave the pad grabbed or kill keymon.
    # Check synchronously and only while the loop is going round again:
    # `pidof ... || keymon.elf &` backgrounds the pidof too, which then
    # races the killall below and can leave a stray keymon running under ES.
    killall gptokeyb 2>/dev/null
    if [ -f "$EXEC_PATH" ] && ! pidof keymon.elf > /dev/null 2>&1; then
        keymon.elf &
    fi

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

# The loop only ends through "Return to EmulationStation". Hand the rest of
# this boot back to AmberELEC before its autostart brings ES up: the services
# masked above (started only if AmberELEC has them enabled) and suspend.
# pulseaudio and logind are left exactly as this script found them.
systemctl unmask $SERVICES 2>/dev/null || true
for _svc in $SERVICES; do
    if systemctl is-enabled --quiet "$_svc" 2>/dev/null; then
        systemctl start --no-block "$_svc" 2>/dev/null || true
    fi
done
systemctl unmask --runtime $SLEEP_TARGETS 2>/dev/null || true
