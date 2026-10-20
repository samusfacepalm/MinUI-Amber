#!/bin/bash
# /roms/MinUIAmber/.system/a10mini/install.sh  (run as root)
#
# Installs MinUI Amber's boot hook on an A10 Mini (v1, v2 or V4) running
# ArkOS4Clone, and sets the panel to 60 Hz. Called by EnableMinUIAmber.sh,
# i.e. from EmulationStation's Ports menu. Safe to run any number of times:
# each step checks before it changes anything, and every file it changes on
# the BOOT partition is first copied to <name>.minuiamber-orig.
#
#   install.sh install     hook firstboot.sh, fix the refresh rate
#   install.sh uninstall   put the original firstboot.sh and DTB back
#   install.sh status      report, change nothing
#
# What it touches, all on the FAT BOOT partition (/boot):
#   firstboot.sh   ArkOS4Clone runs this as root on every boot, before
#                  EmulationStation. The hook runs MinUI from there.
#   <the DTB that boot.ini loads>   one 32-bit cell: the panel's pixel clock.

set -u

SYS=/roms/MinUIAmber/.system/a10mini
LOGDIR=/roms/MinUIAmber/.userdata/a10mini/logs
FB=/boot/firstboot.sh
INI=/boot/boot.ini
MARK="MinUIAmber boot hijack"
ORIG=minuiamber-orig

mkdir -p "$LOGDIR"
exec > >(tee -a "$LOGDIR/install.log") 2>&1
echo "===== install.sh $* ($(date '+%F %T'))"

say() { echo "$*"; }
die() { echo "ERROR: $*"; exit 1; }

[ "$(id -u)" = 0 ] || die "must run as root"
[ -f "$FB" ] || die "$FB not found - is this ArkOS4Clone?"

dtb_name() {
	# load mmc 1:1 ${dtb_loadaddr} rk3326-a10mini-linux.dtb
	tr -d '\r' < "$INI" 2>/dev/null | sed -n 's/^[[:space:]]*load mmc [^ ]* ${dtb_loadaddr} \([^ ]*\).*/\1/p' | head -1
}

install_hook() {
	if grep -q "$MARK" "$FB"; then
		say "boot hook: already in $FB"
		return 0
	fi
	[ -f "$FB.$ORIG" ] || cp -p "$FB" "$FB.$ORIG" || die "could not back up $FB"
	# Insert the hook just before clone.sh's `main "$@"` so MinUI starts
	# before clone.sh's per-boot chores; append if that line is not there.
	awk -v hook="$SYS/firstboot_hook.sh" '
		/^main "\$@"/ && !done { while ((getline l < hook) > 0) print l; done = 1 }
		{ print }
		END { if (!done) while ((getline l < hook) > 0) print l }
	' "$FB" > "$FB.new" || die "could not write $FB.new"
	grep -q "$MARK" "$FB.new" || { rm -f "$FB.new"; die "hook text missing from $FB.new"; }
	bash -n "$FB.new" || { rm -f "$FB.new"; die "patched firstboot.sh fails a syntax check; left unchanged"; }
	mv -f "$FB.new" "$FB" && sync
	say "boot hook: installed in $FB (original kept as $FB.$ORIG)"
}

fix_refresh() {
	local name dtb
	name=$(dtb_name)
	[ -n "$name" ] || { say "refresh: could not find the DTB name in $INI; skipped"; return 0; }
	dtb="/boot/$name"
	[ -f "$dtb" ] || { say "refresh: $dtb not found; skipped"; return 0; }
	if python3 "$SYS/bin/fixrefresh.py" check "$dtb" | grep -q "already 60 Hz"; then
		python3 "$SYS/bin/fixrefresh.py" check "$dtb"
		return 0
	fi
	[ -f "$dtb.$ORIG" ] || cp -p "$dtb" "$dtb.$ORIG" || { say "refresh: could not back up $dtb; skipped"; return 0; }
	python3 "$SYS/bin/fixrefresh.py" apply "$dtb" && sync
	say "refresh: original DTB kept as $dtb.$ORIG (takes effect after reboot)"
}

uninstall() {
	local name
	if [ -f "$FB.$ORIG" ]; then
		cp -p "$FB.$ORIG" "$FB" && rm -f "$FB.$ORIG" && say "boot hook: original $FB restored"
	elif grep -q "^# >>> $MARK >>>" "$FB"; then
		# no backup: cut the marked block out
		sed "/^# >>> $MARK >>>/,/^# <<< $MARK <<</d" "$FB" > "$FB.new" \
			&& ! grep -q "$MARK" "$FB.new" && bash -n "$FB.new" \
			&& mv -f "$FB.new" "$FB" && say "boot hook: removed from $FB"
	elif grep -q "$MARK" "$FB"; then
		say "boot hook: an older unmarked hook is in $FB and there is no backup;"
		say "  remove the MinUIAmber block from firstboot.sh on the BOOT partition by hand"
	else
		say "boot hook: not installed"
	fi
	name=$(dtb_name)
	if [ -n "$name" ] && [ -f "/boot/$name.$ORIG" ]; then
		cp -p "/boot/$name.$ORIG" "/boot/$name" && rm -f "/boot/$name.$ORIG" && say "refresh: original /boot/$name restored"
	fi
	sync
}

status() {
	grep -q "$MARK" "$FB" && say "boot hook: installed" || say "boot hook: not installed"
	local name; name=$(dtb_name)
	[ -n "$name" ] && [ -f "/boot/$name" ] && python3 "$SYS/bin/fixrefresh.py" check "/boot/$name"
	[ -f /roms/MinUIAmber/.disabled ] && say "state: disabled (boots to EmulationStation)" || say "state: enabled (boots to MinUI)"
}

case "${1:-}" in
	install)   install_hook; fix_refresh ;;
	uninstall) uninstall ;;
	status)    status ;;
	*)         die "usage: install.sh install|uninstall|status" ;;
esac
exit 0
