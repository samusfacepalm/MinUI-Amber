#!/bin/bash
# Build MinUIAmber for the YMC A10 Mini (ArkOS4Clone / RK3326).
# Runs INSIDE a chroot of the device's own rootfs (native gcc 9.2, glibc 2.30)
# with the MinUI workspace bind-mounted at /root/workspace.
export CROSS_COMPILE=aarch64-linux-gnu-
export PREFIX=/usr
export UNION_PLATFORM=a10mini
export PLATFORM=a10mini
export LC_ALL=C

W=/root/workspace
FAIL=0
step() {
	local dir="$1"
	cd "$W/$dir" || { echo "MISSING $dir"; FAIL=1; return; }
	local out rc
	out=$(make 2>&1); rc=$?
	if [ $rc -ne 0 ]; then
		echo "=== FAIL $dir (rc=$rc)"
		echo "$out" | grep -vE 'warning:|note:|^In file included|^ +from |^ +#define|^ *$|^\^|~~~' | tail -40
		FAIL=1
	else
		echo "=== ok   $dir"
		echo "$out" | grep -E 'error|Error' | head -5
	fi
}
gcc --version | head -1
step a10mini/libmsettings
step a10mini/keymon
step all/minui
step all/minarch
step all/clock
step all/minput
step all/syncsettings
step all/say
echo
echo "=== artifacts ==="
ls -l "$W"/a10mini/keymon/keymon.elf \
      "$W"/a10mini/libmsettings/libmsettings.so \
      "$W"/all/minui/build/a10mini/minui.elf \
      "$W"/all/minarch/build/a10mini/minarch.elf \
      "$W"/all/clock/build/a10mini/clock.elf \
      "$W"/all/minput/build/a10mini/minput.elf \
      "$W"/all/syncsettings/build/a10mini/syncsettings.elf \
      "$W"/all/say/build/a10mini/say.elf 2>&1
exit $FAIL
