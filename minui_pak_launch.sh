#!/bin/sh
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

mkdir -p "$BIOS_PATH"
mkdir -p "$ROMS_PATH"
mkdir -p "$SAVES_PATH"
mkdir -p "$CHEATS_PATH"
mkdir -p "$USERDATA_PATH"
mkdir -p "$LOGS_PATH"
mkdir -p "$SHARED_USERDATA_PATH/.minui"

export LD_LIBRARY_PATH=$SYSTEM_PATH/lib:$LD_LIBRARY_PATH
export PATH=$SYSTEM_PATH/bin:$PATH

# Disable system sleep
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null || true

# Disable screen blanking
echo 0 > /sys/class/graphics/fbcon/cursor_blink 2>/dev/null || true

CPU_PATH=/sys/devices/system/cpu/cpufreq/policy0/scaling_setspeed
CPU_SPEED_PERF=1296000
echo $CPU_SPEED_PERF > $CPU_PATH 2>/dev/null || true

# Initialize volume
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
        eval $CMD
        echo "EXIT: $?" >> $LOGS_PATH/launch.log
        rm -f $NEXT_PATH
        echo $CPU_SPEED_PERF > $CPU_PATH 2>/dev/null || true
        sync
    fi

    if [ -f "/tmp/poweroff" ]; then
        rm -f "/tmp/poweroff"
        killall keymon.elf 2>/dev/null
        poweroff
        exit 0
    fi
done

killall keymon.elf 2>/dev/null
