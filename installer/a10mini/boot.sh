#!/bin/bash
# /roms/MinUIAmber/.system/a10mini/boot.sh
#
# Run by the hook appended to /boot/firstboot.sh, which ArkOS4Clone runs as
# root on every boot from firstboot.service. That unit is Type=oneshot with
# no start timeout, and emulationstation.service is ordered After= it, so
# while this script is running EmulationStation cannot start. When MinUI
# exits (Tools > Return to EmulationStation) we return, firstboot.service
# completes, and systemd starts ES exactly as it would have. Next reboot
# comes back to MinUI unless /roms/MinUIAmber/.disabled exists.

MINUI_LAUNCH="/roms/MinUIAmber/.system/a10mini/paks/MinUI.pak/launch.sh"

# Boot instrumentation: /proc/uptime is monotonic, so the number here is
# seconds from kernel start to this hook, whatever the wall clock says.
LOGDIR=/roms/MinUIAmber/.userdata/a10mini/logs
mkdir -p "$LOGDIR"
{
	echo "boot.sh reached at uptime $(cut -d' ' -f1 /proc/uptime)s  ($(date '+%F %T'))"
	echo "--- units still activating/running at that point:"
	systemctl list-units --no-legend --no-pager --state=activating,running 2>/dev/null | awk '{print $1, $3, $4}'
	echo "--- network interfaces: $(ls /sys/class/net 2>/dev/null | xargs)"
	echo "--- kernel milestones (dmesg seconds):"
	dmesg 2>/dev/null | grep -E "Freeing unused kernel|VFS: Mounted root|EXT4-fs \(mmcblk0p2\): mounted|Run /(s?bin/)?init|systemd\[1\]: Detected" | head -8
	echo "--- kernel cmdline: $(cat /proc/cmdline)"
} > "$LOGDIR/boot.log" 2>&1

###############################################################################
# USB network + SSH for development (only while /roms/MinUIAmber/usbnet exists).
# The RK3326 OTG port becomes a USB Ethernet gadget (g_ether: RNDIS for
# Windows, CDC-ECM for everything else). The device is 192.168.7.1, hands the
# PC 192.168.7.10-20 by DHCP, and sshd listens: ssh ark@192.168.7.1
###############################################################################
if [ -e /roms/MinUIAmber/usbnet ]; then
	# Force the OTG port into device role: the Rockchip usb2phy defaults to
	# host/otg and only some boards have ID-pin detection wired.
	for _m in /sys/devices/platform/*/*usb2-phy*/otg_mode /sys/devices/platform/*usb2-phy*/otg_mode /sys/kernel/debug/usb/*/otg_mode; do
		[ -e "$_m" ] && { echo peripheral > "$_m" 2>/dev/null; echo "usbnet: set $_m=$(cat "$_m" 2>/dev/null)" >> "$LOGDIR/boot.log"; }
	done
	modprobe dwc2 2>>"$LOGDIR/boot.log" || echo "usbnet: modprobe dwc2 failed" >> "$LOGDIR/boot.log"
	modprobe g_ether iManufacturer=MinUIAmber iProduct="A10 Mini USB Ethernet" 2>>"$LOGDIR/boot.log" || echo "usbnet: modprobe g_ether failed" >> "$LOGDIR/boot.log"
	lsmod 2>/dev/null | grep -E "g_ether|dwc2|libcomposite|u_ether|rndis" >> "$LOGDIR/boot.log"
	ls /sys/class/udc/ >> "$LOGDIR/boot.log" 2>&1
	cat /sys/class/udc/*/state >> "$LOGDIR/boot.log" 2>&1
	for _i in 1 2 3 4 5 6 7 8 9 10; do [ -e /sys/class/net/usb0 ] && break; sleep 0.5; done
	if [ -e /sys/class/net/usb0 ]; then
		ip addr flush dev usb0 2>/dev/null || true
		ip addr add 192.168.7.1/24 dev usb0
		ip link set usb0 up
		dnsmasq --conf-file=/dev/null --interface=usb0 --bind-interfaces --except-interface=lo \
			--dhcp-range=192.168.7.10,192.168.7.20,12h --no-resolv --no-hosts \
			--pid-file=/run/minuiamber-dnsmasq.pid 2>>"$LOGDIR/boot.log" || true
		systemctl start ssh.service 2>/dev/null || true
		echo "usbnet: usb0 up at 192.168.7.1, dnsmasq + sshd started ($(cat /sys/class/net/usb0/address))" >> "$LOGDIR/boot.log"
	else
		echo "usbnet: g_ether loaded but no usb0 appeared" >> "$LOGDIR/boot.log"
		dmesg | grep -iE "dwc2|gadget|g_ether|rndis|usb0" | tail -8 >> "$LOGDIR/boot.log"
	fi
fi

# Kill the ArkOS4Clone splash before drawing anything
plymouth quit 2>/dev/null || true
printf "\033c" > /dev/tty1 2>/dev/null || true

if [ -f "$MINUI_LAUNCH" ]; then
	/bin/bash "$MINUI_LAUNCH"
	rm -f /tmp/minui_exec
	killall minui.elf minarch.elf keymon.elf 2>/dev/null
fi

# Give ArkOS back what launch.sh stood down, then let ES start: the hotkey
# daemon, auto-suspend only if the user had it enabled, and the CPU governor
# and ceiling that launch.sh / MinUI changed.
systemctl start oga_events.service 2>/dev/null || true
systemctl is-enabled --quiet autosuspend.service 2>/dev/null && systemctl start autosuspend.service 2>/dev/null
echo ondemand > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor 2>/dev/null || true
cat /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq \
	> /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq 2>/dev/null || true
printf "\033c" > /dev/tty1 2>/dev/null || true
exit 0
