#!/bin/bash
# Build MinUIAmber for the Powkiddy V90S (KNULLI / Allwinner A133P).
# Run inside the tg5040-toolchain image with /root/workspace mounted:
#   docker run --rm -v <workspace>:/root/workspace tg5040-toolchain \
#     /bin/bash -lc '. ~/.bashrc; bash /root/workspace/build_v90s.sh'

. ~/.bashrc

export UNION_PLATFORM=v90s
export PLATFORM=v90s

W=/root/workspace
FAIL=0

# noise from the HAS_HDMI aliasing and other known-harmless warnings
QUIET='warning:|note:|^In file included|^ +from |^ +#define|^ *$|^\^|~~~'

step() {
	local dir="$1"
	cd "$W/$dir" || { echo "MISSING $dir"; FAIL=1; return; }
	local out rc
	out=$(make 2>&1); rc=$?
	if [ $rc -ne 0 ]; then
		echo "=== FAIL $dir (rc=$rc)"
		echo "$out" | tail -40
		FAIL=1
	else
		echo "=== ok   $dir"
		echo "$out" | grep -E 'error|Error' | head -5
	fi
}

step v90s/libmsettings
step v90s/keymon
step all/minui
step all/minarch
step all/clock
step all/minput
step all/syncsettings
step all/say

echo
echo "=== artifacts ==="
ls -l "$W"/v90s/keymon/keymon.elf \
      "$W"/v90s/libmsettings/libmsettings.so \
      "$W"/all/minui/build/v90s/minui.elf \
      "$W"/all/minarch/build/v90s/minarch.elf \
      "$W"/all/clock/build/v90s/clock.elf \
      "$W"/all/minput/build/v90s/minput.elf \
      "$W"/all/syncsettings/build/v90s/syncsettings.elf \
      "$W"/all/say/build/v90s/say.elf 2>&1

exit $FAIL
