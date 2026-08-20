#!/bin/sh
# Enable (or disable) MinUIAmber as the front end on AmberELEC.
#
#   EnableMinUIAmber.sh            -> enable, then reboot
#   EnableMinUIAmber.sh off        -> restore EmulationStation, then reboot
#   EnableMinUIAmber.sh status     -> report current state, change nothing
#
# Lives at /storage/roms/MinUIAmber/EnableMinUIAmber.sh and is normally run
# from EmulationStation's Ports menu via the thin shims in /storage/roms/ports/.
# Everything it touches is inside /storage, so it survives a reboot but can be
# undone at any time from the same menu.

set -u

MINUI_ROOT="/storage/roms/MinUIAmber"
CUSTOM_SH="/storage/.config/custom_start.sh"
CUSTOM_BACKUP="/storage/.config/custom_start.sh.pre-minuiamber"

# Services AmberELEC starts that MinUI does not need. Masked on enable,
# unmasked on disable so EmulationStation gets its full environment back.
SERVICES="syncthing.service smbd.service nmbd.service webui.service avahi-daemon.service avahi-defaults.service lastgame.service wsdd2.service pulseaudio.service"

log() { echo "[MinUIAmber] $*"; }

# One script serves both the RG351V and the RPP: find whichever platform
# payload is actually present rather than hardcoding the name.
find_launch() {
    for p in "$MINUI_ROOT"/.system/*/paks/MinUI.pak/launch.sh; do
        [ -f "$p" ] && { echo "$p"; return 0; }
    done
    return 1
}

status() {
    launch=$(find_launch) && log "payload           = found ($launch)" \
                          || log "payload           = MISSING under $MINUI_ROOT/.system/"
    if [ -f "$CUSTOM_SH" ] && grep -q MinUIAmber "$CUSTOM_SH" 2>/dev/null; then
        log "custom_start.sh   = MinUIAmber (boots into MinUI)"
    elif [ -f "$CUSTOM_SH" ]; then
        log "custom_start.sh   = present, not ours"
    else
        log "custom_start.sh   = absent (boots into EmulationStation)"
    fi
}

enable_minui() {
    launch=$(find_launch)
    if [ -z "${launch:-}" ]; then
        log "ERROR: MinUI.pak/launch.sh not found under $MINUI_ROOT/.system/"
        log "Copy the MinUIAmber folder to /storage/roms/ first."
        sleep 5
        exit 1
    fi

    # Don't clobber someone else's boot hook
    if [ -f "$CUSTOM_SH" ] && ! grep -q MinUIAmber "$CUSTOM_SH" 2>/dev/null; then
        log "Backing up existing custom_start.sh"
        cp -f "$CUSTOM_SH" "$CUSTOM_BACKUP"
    fi

    mkdir -p /storage/.config
    cat > "$CUSTOM_SH" << HOOK
#!/bin/sh
. /etc/profile
case "\${1}" in
"before")
MINUI_LAUNCH="$launch"
if [ -e "\$MINUI_LAUNCH" ]; then
    systemctl stop emustation 2>/dev/null || true
    sh "\$MINUI_LAUNCH"
    systemctl start emustation 2>/dev/null || true
fi
    exit 0
    ;;
*)
    exit 0
    ;;
esac
exit 0
HOOK
    chmod +x "$CUSTOM_SH"

    # Faster boot. Re-applied every boot by MinUI.pak/launch.sh as well.
    systemctl mask $SERVICES 2>/dev/null || true

    find "$MINUI_ROOT" -name '*.sh' -exec chmod +x {} \; 2>/dev/null
    sync
    log "Enabled. Rebooting into MinUI."
}

disable_minui() {
    if [ -f "$CUSTOM_SH" ] && grep -q MinUIAmber "$CUSTOM_SH" 2>/dev/null; then
        rm -f "$CUSTOM_SH"
        if [ -f "$CUSTOM_BACKUP" ]; then
            log "Restoring previous custom_start.sh"
            mv -f "$CUSTOM_BACKUP" "$CUSTOM_SH"
        fi
    elif [ -f "$CUSTOM_SH" ]; then
        log "custom_start.sh is not ours - leaving it alone."
    fi

    # Give EmulationStation everything back
    systemctl unmask $SERVICES 2>/dev/null || true
    systemctl start pulseaudio.service 2>/dev/null || true

    sync
    log "Disabled. Rebooting into EmulationStation."
}

case "${1:-on}" in
    status)       status; exit 0 ;;
    off|disable)  disable_minui ;;
    on|enable|"") enable_minui ;;
    *)            log "usage: $(basename "$0") [on|off|status]"; exit 1 ;;
esac

sleep 3
reboot
