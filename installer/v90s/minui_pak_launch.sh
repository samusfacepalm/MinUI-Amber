#!/bin/sh
# MinUI.pak launch script for the Powkiddy V90S on KNULLI.
#
# Differences from the RG351V/AmberELEC script, all of them consequences of
# the OS rather than the hardware:
#   - KNULLI is busybox-init, not systemd: no systemctl, no logind, so no
#     HandlePowerKey drop-in and no service masking dance
#   - audio is PulseAudio, not a raw ALSA mixer
#   - KNULLI runs a battery-saver daemon that MinUI has to stand down
#   - everything lives under /userdata, which survives a KNULLI update
#     (updates replace the read-only squashfs rootfs wholesale)

export PLATFORM="v90s"
export SDCARD_PATH="/userdata/roms/MinUIAmber"

# Boot instrumentation. /proc/uptime is monotonic since kernel start, so
# unlike `date` it cannot be moved by fake-hwclock restoring a saved time or
# by ntp stepping the clock. _mark is called at each stage below; if the
# uptime deltas are small while the wall-clock ones are large, the "slow
# boot" is a clock artefact rather than a stall.
_BOOTMARK=/tmp/minui_bootmark.txt
_mark() {
    printf '%s\tuptime=%s\tdate=%s\n' "$1" \
        "$(cut -d' ' -f1 /proc/uptime 2>/dev/null)" \
        "$(date +%H:%M:%S,%3N 2>/dev/null)" >> "$_BOOTMARK" 2>/dev/null
}
_mark launch.sh:entry
export BIOS_PATH="$SDCARD_PATH/Bios"
export ROMS_PATH="$SDCARD_PATH/Roms"
export SAVES_PATH="$SDCARD_PATH/Saves"
export CHEATS_PATH="$SDCARD_PATH/Cheats"
export SYSTEM_PATH="$SDCARD_PATH/.system/$PLATFORM"
export USERDATA_PATH="$SDCARD_PATH/.userdata/$PLATFORM"
export SHARED_USERDATA_PATH="$SDCARD_PATH/.userdata/shared"
export LOGS_PATH="$USERDATA_PATH/logs"
export HOME="$USERDATA_PATH"
export SDL_NOMOUSE=1

# Use KNULLI's own libretro cores rather than shipping our own. They are
# built against this exact BSP, and there are 100+ of them.
export CORES_PATH="/usr/lib/libretro"

# KNULLI's SDL2 has one video backend ("Mali EGL Video Driver").
#
# Audio: the sound server here is PIPEWIRE, not PulseAudio -- S06audio starts
# /usr/bin/pipewire, and pactl is just the pulse-compat client talking to
# pipewire-pulse. The device's SDL2 reports its drivers as
# "alsa, pipewire, dsp, disk, dummy" -- there is NO pulseaudio backend, so
# asking for one gave "SDL_OpenAudio error: Audio target 'pulseaudio' not
# available" and total silence. Talk to the server SDL can actually reach.
if [ -e /usr/lib/libpipewire-0.3.so.0 ] && pidof pipewire > /dev/null 2>&1; then
    export SDL_AUDIODRIVER=pipewire
else
    export SDL_AUDIODRIVER=alsa
fi

mkdir -p "$BIOS_PATH"
mkdir -p "$ROMS_PATH"
mkdir -p "$SAVES_PATH"
mkdir -p "$CHEATS_PATH"
mkdir -p "$USERDATA_PATH"
mkdir -p "$LOGS_PATH"
mkdir -p "$SHARED_USERDATA_PATH/.minui"

export LD_LIBRARY_PATH=$SYSTEM_PATH/lib:$LD_LIBRARY_PATH
export PATH=$SYSTEM_PATH/bin:$PATH

# pactl needs XDG_RUNTIME_DIR and the D-Bus address; S31emulationstation
# sources these before starting ES and so must we, or every volume change
# silently no-ops.
_mark after:mkdirs
[ -f /etc/profile.d/xdg.sh ]  && . /etc/profile.d/xdg.sh
[ -f /etc/profile.d/dbus.sh ] && . /etc/profile.d/dbus.sh
_mark after:profile.d

###############################################################################
# Stand down KNULLI's battery-saver daemon.
#
# /usr/bin/battery-saver.sh watches /dev/input with `inotifywait -e access`
# and, after system.batterysaver.timer (default 300s), dims the panel and
# mutes audio; after system.batterysaver.extendedtimer (default 900s) its
# extendedmode kicks in, which defaults to *suspend* — that is the "screen
# dims, inputs die, power button brings it back, then it dims again" fight.
#
# MinUI's polling doesn't reliably generate the IN_ACCESS events the daemon
# counts as activity, so it dims on a device that is being actively used.
# The daemon has a sanctioned opt-out: check_pause() disables all of it
# while any *.pause file exists in its run directory. Use that rather than
# killing the daemon, so ES gets its battery saving straight back when
# MinUI exits.
###############################################################################
BATTSAVER_PAUSE="/var/run/battery-saver/minui.pause"
mkdir -p /var/run/battery-saver 2>/dev/null
touch "$BATTSAVER_PAUSE" 2>/dev/null

# MinUI does its own sleep/wake on the power button, so nothing is lost.

# Make sure EmulationStation is not also running. Normally the installer
# has already set system.es.atstartup=0, but a KNULLI update can reset it.
_mark after:battsaver
if pidof emulationstation > /dev/null 2>&1; then
    /etc/init.d/S31emulationstation stop 2>/dev/null || true
fi
_mark after:es-check

# Disable console blanking on the framebuffer console
echo 0 > /sys/class/graphics/fbcon/cursor_blink 2>/dev/null || true

# rcS writes a millisecond timestamp per init script to /var/run/boot.log,
# which is tmpfs and gone by the time the card is back in a PC. Copy it to
# the card so boot time can actually be measured rather than guessed.
_mark after:fbcon
cp -f /var/run/boot.log "$LOGS_PATH/boot.log" 2>/dev/null
date +"%F %T,%3N: MinUI.pak launch.sh reached" >> "$LOGS_PATH/boot.log" 2>/dev/null
# monotonic stage marks, immune to clock jumps
{ echo "--- stage marks (uptime is monotonic) ---"; cat "$_BOOTMARK" 2>/dev/null; } \
    >> "$LOGS_PATH/boot.log" 2>/dev/null

###############################################################################
# Fast shutdown helper.
#
# KNULLI is sysvinit: `poweroff` runs rcK, which stops every /etc/init.d/S??
# script serially in reverse order (connman, dropbear, bluetooth, dnsmasq,
# nfs, network...). That is the "powering off takes forever".
#
# Skip it with `poweroff -f`, but unmount /userdata first so exFAT is left
# clean. The helper lives in /tmp precisely so that nothing is being read
# off /userdata at the moment we unmount it — launch.sh execs into this and
# releases its own file descriptor.
###############################################################################
cat > /tmp/minui_poweroff.sh <<'POWEROFF_EOF'
#!/bin/sh
cd /
# Save the clock; it's the one thing rcK does that we actually want, and
# this board has no battery-backed RTC.
/etc/init.d/S47fake-hwclock stop 2>/dev/null
sync
# Nothing of ours is on /userdata any more, so this should succeed. If some
# other daemon still holds it, read-only is nearly as good.
umount /userdata 2>/dev/null || mount -o remount,ro /userdata 2>/dev/null
sync
poweroff -f
POWEROFF_EOF
chmod +x /tmp/minui_poweroff.sh

###############################################################################
# Audio init, backgrounded.
#
# The A133 audio link settles late in boot and S31emulationstation spins up
# to ten seconds waiting for a default sink. Doing that inline delayed every
# boot by up to ten seconds before MinUI drew a single frame, so it now runs
# alongside MinUI instead of in front of it.
###############################################################################
(
    _i=0
    while [ $_i -lt 40 ]; do
        DEFAULT_SINK=$(pactl info 2>/dev/null | grep "Default Sink" | cut -d: -f2 | tr -d ' ')
        if [ -n "$DEFAULT_SINK" ]; then
            pactl list sinks short 2>/dev/null | awk '{print $2}' | grep -q "^$DEFAULT_SINK$" && break
        fi
        _i=$((_i + 1))
        sleep 0.25
    done

    pactl set-sink-mute @DEFAULT_SINK@ 0 2>/dev/null

    # Initialize volume on first run only; after that MinUI's saved volume wins
    if [ ! -f "$USERDATA_PATH/.volume_initialized" ]; then
        pactl set-sink-volume @DEFAULT_SINK@ 40% 2>/dev/null
        touch "$USERDATA_PATH/.volume_initialized"
    fi
) &

keymon.elf &

cd "$(dirname "$0")"

# MinUI Amber boot splash -- once per boot only, not per menu-return
showpng.elf "$SDCARD_PATH/.system/res/logo.png" 2>/dev/null || true

EXEC_PATH="/tmp/minui_exec"
NEXT_PATH="/tmp/next"
touch "$EXEC_PATH" && sync
while [ -f $EXEC_PATH ]; do
    minui.elf > "$LOGS_PATH/minui.txt" 2>&1
    sync

    if [ -f $NEXT_PATH ]; then
        CMD=$(cat $NEXT_PATH)
        echo "CMD: $CMD" >> "$LOGS_PATH/launch.log"
        eval "$CMD"
        echo "EXIT: $?" >> "$LOGS_PATH/launch.log"
        rm -f $NEXT_PATH
        sync
    fi

    # self-heal: ports (gptokeyb) can leave the pad grabbed or kill keymon
    killall gptokeyb 2>/dev/null
    pidof keymon.elf > /dev/null 2>&1 || keymon.elf &

    # keep the battery-saver stood down even if the daemon was restarted
    [ -f "$BATTSAVER_PAUSE" ] || touch "$BATTSAVER_PAUSE" 2>/dev/null

    if [ -f "/tmp/poweroff" ]; then
        rm -f "/tmp/poweroff"
        killall keymon.elf 2>/dev/null
        rm -f "$BATTSAVER_PAUSE"
        cd /
        sync
        # exec, so dash lets go of this file before /userdata is unmounted
        exec /bin/sh /tmp/minui_poweroff.sh
    fi
done

killall keymon.elf 2>/dev/null
rm -f "$BATTSAVER_PAUSE"
