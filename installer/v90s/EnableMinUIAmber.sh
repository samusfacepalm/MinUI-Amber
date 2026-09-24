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

# boot_rw CMD... -- run CMD with /boot writable. It is KNULLI's FAT32
# partition, mounted read-only, so remount around the change (and leave it
# as we found it).
boot_rw() {
    local was_rw=0 rc
    grep -qs '^[^ ]* /boot [^ ]* rw[, ]' /proc/mounts && was_rw=1
    if [ $was_rw = 0 ] && ! mount -o remount,rw /boot 2>/dev/null; then
        log "WARNING: could not remount /boot read-write"
        return 1
    fi
    "$@"
    rc=$?
    sync
    [ $was_rw = 1 ] || mount -o remount,ro /boot 2>/dev/null
    return $rc
}

# Is /boot/boot-custom.sh our trimmer (rather than someone else's script)?
our_boot_custom() {
    [ -f "$BOOT_CUSTOM" ] && grep -q "MinUIAmber boot trimmer" "$BOOT_CUSTOM" 2>/dev/null
}

# Our trimmer, but from v0.2: it trims on every boot and ignores the marker.
old_boot_custom() {
    our_boot_custom && ! grep -q "minuiamber-enabled" "$BOOT_CUSTOM" 2>/dev/null
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
    elif old_boot_custom; then
        log "boot-custom.sh    = installed, v0.2 (always active; replace it)"
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
    boot_rw touch "$BOOT_MARKER" || log "The optional boot-custom.sh trimmer will stay inactive."

    find "$MINUI_ROOT" -name '*.sh' -exec chmod +x {} \; 2>/dev/null
    chmod +x "$MINUI_ROOT"/.system/v90s/bin/* 2>/dev/null

    sync
    log "Enabled. Rebooting into MinUI."
}

disable_minui() {
    # Disarm the boot trimmer first. Left active, it would keep
    # EmulationStation from starting at all once custom.sh is gone, so if
    # that can't be done, change nothing. v0.2's trimmer ignores the marker,
    # so it is set aside (renamed, not deleted).
    if old_boot_custom; then
        boot_rw mv -f "$BOOT_CUSTOM" "$BOOT_CUSTOM.v0.2-off" &&
            log "Set aside the v0.2 boot-custom.sh as boot-custom.sh.v0.2-off"
    fi
    if [ -f "$BOOT_MARKER" ]; then
        boot_rw rm -f "$BOOT_MARKER"
    fi
    if our_boot_custom && { old_boot_custom || [ -f "$BOOT_MARKER" ]; }; then
        log "ERROR: could not update /boot, and boot-custom.sh would then keep"
        log "EmulationStation from starting. Nothing else was changed."
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
