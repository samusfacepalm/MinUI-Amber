#!/bin/bash
# Enable (or disable) MinUIAmber as the front end on KNULLI.
#
#   EnableMinUIAmber.sh          -> enable, then reboot
#   EnableMinUIAmber.sh off      -> restore EmulationStation, then reboot
#   EnableMinUIAmber.sh status   -> report current state, change nothing
#
# Everything this touches is inside /userdata, so a KNULLI system update
# (which replaces the read-only squashfs rootfs) leaves it intact. The one
# exception is the empty /boot/minuiamber-enabled marker that arms the
# optional boot-custom.sh trimmer.

set -u

MINUI_ROOT="/userdata/roms/MinUIAmber"
MINUI_LAUNCH="$MINUI_ROOT/.system/v90s/paks/MinUI.pak/launch.sh"
CUSTOM_SH="/userdata/system/custom.sh"
CUSTOM_BACKUP="/userdata/system/custom.sh.pre-minuiamber"

# The optional /boot/boot-custom.sh trimmer only acts while this marker
# exists, so disabling MinUI Amber also gives KNULLI its init scripts back.
BOOT_CUSTOM="/boot/boot-custom.sh"
BOOT_MARKER="/boot/minuiamber-enabled"

log() { echo "[MinUIAmber] $*"; }

# set_boot_marker on|off -- /boot is KNULLI's FAT32 partition, mounted
# read-only, so remount around the change (and leave it as we found it).
set_boot_marker() {
    local was_rw=0 rc
    grep -qs '^[^ ]* /boot [^ ]* rw[, ]' /proc/mounts && was_rw=1
    if [ $was_rw = 0 ] && ! mount -o remount,rw /boot 2>/dev/null; then
        log "WARNING: could not remount /boot read-write"
        return 1
    fi
    if [ "$1" = on ]; then
        touch "$BOOT_MARKER"
    else
        rm -f "$BOOT_MARKER"
    fi
    rc=$?
    sync
    [ $was_rw = 1 ] || mount -o remount,ro /boot 2>/dev/null
    return $rc
}

status() {
    local es
    es=$(batocera-settings-get system.es.atstartup 2>/dev/null)
    log "es.atstartup      = ${es:-<unset, defaults to on>}"
    if [ -f "$CUSTOM_SH" ] && grep -q MinUIAmber "$CUSTOM_SH" 2>/dev/null; then
        log "custom.sh         = MinUIAmber"
    elif [ -f "$CUSTOM_SH" ]; then
        log "custom.sh         = present, not ours"
    else
        log "custom.sh         = absent"
    fi
    [ -f "$MINUI_LAUNCH" ] && log "payload           = found" || log "payload           = MISSING ($MINUI_LAUNCH)"
    if [ ! -f "$BOOT_CUSTOM" ]; then
        log "boot-custom.sh    = not installed"
    elif [ -f "$BOOT_MARKER" ]; then
        log "boot-custom.sh    = installed, active"
    else
        log "boot-custom.sh    = installed, inactive"
    fi
}

enable_minui() {
    if [ ! -f "$MINUI_LAUNCH" ]; then
        log "ERROR: $MINUI_LAUNCH not found."
        log "Extract the MinUIAmber release into /userdata/roms/MinUIAmber first."
        exit 1
    fi

    # Don't clobber someone else's custom.sh
    if [ -f "$CUSTOM_SH" ] && ! grep -q MinUIAmber "$CUSTOM_SH" 2>/dev/null; then
        log "Backing up existing custom.sh -> $(basename "$CUSTOM_BACKUP")"
        cp -f "$CUSTOM_SH" "$CUSTOM_BACKUP"
    fi

    mkdir -p /userdata/system
    cp -f "$MINUI_ROOT/.system/v90s/custom.sh" "$CUSTOM_SH"
    chmod +x "$CUSTOM_SH"

    # Stop ES from taking the framebuffer at S31, long before our S99 hook
    batocera-settings-set system.es.atstartup 0

    # Arm the optional boot trimmer. Harmless if it isn't installed.
    set_boot_marker on || log "The optional boot-custom.sh trimmer will stay inactive."

    find "$MINUI_ROOT" -name '*.sh' -exec chmod +x {} \; 2>/dev/null
    chmod +x "$MINUI_ROOT"/.system/v90s/bin/* 2>/dev/null

    sync
    log "Enabled. Rebooting into MinUI."
}

disable_minui() {
    # Disarm the boot trimmer first. Left armed, it would keep
    # EmulationStation from starting at all once custom.sh is gone, so if
    # that can't be done, change nothing.
    if [ -f "$BOOT_MARKER" ] && ! set_boot_marker off && [ -f "$BOOT_CUSTOM" ]; then
        log "ERROR: could not remove $BOOT_MARKER, and boot-custom.sh would"
        log "then keep EmulationStation from starting. Nothing was changed."
        log "Delete boot-custom.sh from the BATOCERA partition on a PC, then retry."
        sleep 5
        exit 1
    fi

    if [ -f "$CUSTOM_SH" ] && grep -q MinUIAmber "$CUSTOM_SH" 2>/dev/null; then
        rm -f "$CUSTOM_SH"
        if [ -f "$CUSTOM_BACKUP" ]; then
            log "Restoring previous custom.sh"
            mv -f "$CUSTOM_BACKUP" "$CUSTOM_SH"
        fi
    fi

    batocera-settings-set system.es.atstartup 1

    sync
    log "Disabled. Rebooting into EmulationStation."
}

case "${1:-on}" in
    status)     status; exit 0 ;;
    off|disable) disable_minui ;;
    on|enable|"") enable_minui ;;
    *)          log "usage: $(basename "$0") [on|off|status]"; exit 1 ;;
esac

sleep 2
reboot
