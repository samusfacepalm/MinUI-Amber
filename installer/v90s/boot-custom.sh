#!/bin/bash
# /boot/boot-custom.sh  --  MinUIAmber boot trimmer for the Powkiddy V90S
#
# KNULLI's job on this device is to bring up the kernel, the PowerVR driver,
# input, audio and wifi, then hand over to MinUI. Everything else it starts
# is dead weight: MinUI supplies its own emulators, menu and settings.
#
# Measured on this board (rcS writes /var/run/boot.log):
#     01:00:04,772  S60nfs        <- the network/discovery swarm launches
#     01:00:48,015  S65values4boot   ... 43.2 SECONDS later
# Boot spent three quarters of its time inside daemons this device cannot
# even use -- there is no ethernet, and NFS/mDNS/DHCP-server serve nothing.
#
# HOW THIS WORKS
# S00bootcustom runs this script in the FOREGROUND, before every other init
# script. Binding /dev/null over an init script makes rcS's own
# `[ ! -f "$i" ] && continue` guard skip it outright -- not even a fork.
#
# Nothing is modified. These are bind mounts on a tmpfs-backed namespace:
# they evaporate on reboot, they consume none of the 100 MB overlay budget,
# and the read-only squashfs rootfs is untouched. A KNULLI update cannot
# conflict with any of it.
#
# ONLY WHILE MINUI AMBER IS ENABLED
# EnableMinUIAmber.sh creates /boot/minuiamber-enabled and "Disable MinUI
# Amber" removes it. Without that marker this script does nothing, so a
# disabled install boots stock KNULLI -- EmulationStation, hotkeys, battery
# saver and all -- even with this file still on the card. The marker has to
# live on /boot: /userdata is not mounted yet when S00bootcustom runs.
#
# TO UNDO: delete or rename this file. It lives on the FAT32 BATOCERA
# partition, so any PC can do it -- no shell, no device access needed.

test "$1" = "start" || exit 0
[ -f /boot/minuiamber-enabled ] || exit 0

# --- disabled -------------------------------------------------------------
# avahi        mDNS/service discovery -- nothing to discover
# nfs          network file server -- serves nothing, no ethernet on board
# dnsmasq      DHCP/DNS server, for hosting a hotspot we never host
# bluetooth    controllers.bluetooth.enabled=0 already; V90S has no BT radio
# sixad        PS3 pad daemon over bluetooth -- see above
# triggerhappy multimedia hotkey daemon; also grabs /dev/input, which MinUI
#              reads directly, so this is a correctness win as well as speed
# rgbled       powkiddy-v90s is absent from BOARD_CAPABILITIES[rgb]
# toggleswitch trimui-only hardware (BOARD_CAPABILITIES[toggleswitch])
# stats        usage telemetry
# debugmount   developer helper
# emulationstation  MinUI is the front end; belt-and-braces alongside
#              es.atstartup=0, and "Return to EmulationStation" still works
#              because that pak calls the binary directly, not this script
# battery-saver  dims and then SUSPENDS a device that is in active use,
#              because it infers activity from inotify on /dev/input and
#              MinUI's polling doesn't reliably trip it
DISABLE="
S05avahi-setup.sh
S50avahi-daemon
S60nfs
S80dnsmasq
S29namebluetooth
S32bluetooth
S31sixad
S50triggerhappy
S28rgbled
S99toggle-switch
S97stats
S27debugmount
S31emulationstation
S96battery-saver-daemon
"

# --- deliberately KEPT ----------------------------------------------------
# S01dbus, S05udev, S03modules, S04populate   core plumbing
# S06audio, S27audioconfig, S32audioconfig-delay   PipeWire; MinUI needs sound
# S11share, S12populateshare                  mounts and seeds /userdata
# S07network, S20connman                      WIFI -- explicitly wanted
# S49ntp, S47fake-hwclock, S33rngd            this board has no battery RTC,
#                                             so the clock depends on these
#                                             (that's why logs read "1980")
# S50dropbear                                 ssh, the debugging lifeline
# S28usbmode                                  adb, ditto
# S18governor, S27brightness, S26system       CPU, backlight, locale/timezone
# S99userservices                             RUNS custom.sh -> MinUI. Never
#                                             disable this one.

for s in $DISABLE; do
    if [ -f "/etc/init.d/$s" ]; then
        mount -o bind /dev/null "/etc/init.d/$s" 2>/dev/null
    fi
done

exit 0
