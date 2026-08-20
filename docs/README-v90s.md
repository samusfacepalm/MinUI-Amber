# MinUI Amber v0.2 — Powkiddy V90S (KNULLI)

MinUI as the front end on a Powkiddy V90S running KNULLI, installed entirely
inside `/userdata` so a KNULLI system update can't remove it.

**Status: running on hardware.** Video, input, battery and CPU scaling all
confirmed working from the device's own logs. See *Fixed after first boot* and
*Still open* at the bottom.

KNULLI's role here is deliberately narrow: bring up the kernel, PowerVR
driver, input, audio and wifi, then hand over to MinUI. MinUI supplies the
front end, the emulators and the settings. Everything else KNULLI starts is
switched off — see *Boot trimming*.

---

## Device facts

Read out of the card itself (`/boot/batocera` squashfs and
`partitions/output_blocks/v90s_kernel.dts`), not from spec sheets:

| | |
|---|---|
| Board | `powkiddy-v90s`, capabilities `adb lid` |
| OS | KNULLI `gladiator-ii` 2025/08/12 (Batocera fork, buildroot 2024.11) |
| SoC | Allwinner A133P, 4x Cortex-A53, PowerVR GE8300 |
| Kernel | 4.9.191 Allwinner BSP (`pvrsrvkm.ko`) |
| Userspace | aarch64 glibc, `/bin/sh` is **dash** |
| Panel | 640x480 (`lcd_x = <0x280>`, `lcd_y = <0x1e0>`) |
| Backlight | PWM via the sunxi `/dev/disp` ioctl, 0-255, driven by `/usr/bin/brightness` |
| Audio | PulseAudio (`pactl`) |
| SDL2 | 2.30.12, single video backend: "Mali EGL Video Driver" — no KMSDRM, no fbdev, no X11 |
| Init | sysvinit (`/etc/init.d/S*`), **not** systemd |

Same SoC family as the TrimUI Smart Pro / Brick, which is MinUI's `tg5040`
platform — which is why the `tg5040-toolchain` docker image is the right
compiler for this board.

## Input map

From KNULLI's `es_input.cfg` entry *Powkiddy V90s Controller*
(GUID `19000000330100009011000000000000`) and the device tree:

- Face/shoulder: A 304, B 305, X 307, Y 308, L1 310, R1 311, L2 312, R2 313
- SELECT 314, START 315, **MENU = "hotkey" 316** (there is no dedicated menu button)
- D-pad is a **HAT** (`ABS_HAT0X`/`ABS_HAT0Y`), not key events
- **No analog stick** (absent from `BOARD_CAPABILITIES[analogstick]`)
- Volume rocker on the Allwinner LRADC: `key0 = <0x2d0 0x73>` / `key1 = <0x438 0x72>`
  = `KEY_VOLUMEUP` 115 / `KEY_VOLUMEDOWN` 114
- Power on the AXP2202 PMIC PEK, `KEY_POWER` 116

`platform.c` and `keymon.c` open **every** `/dev/input/event*` node and filter
by code rather than hardcoding event numbers — the RG351V port lost a whole
round to guessing those wrong.

Controls: volume rocker alone changes volume; **hotkey + rocker** changes
brightness; START+SELECT kills a stuck standalone app.

## What differs from the RG351V/AmberELEC build

All of it follows from the OS, not the hardware:

| | RG351V (AmberELEC) | V90S (KNULLI) |
|---|---|---|
| Init | systemd | sysvinit — no `systemctl`, no logind power-key fight |
| Volume | `amixer` on rk817 `Playback` | `pactl set-sink-volume @DEFAULT_SINK@ N%` |
| Brightness | `/sys/class/backlight/.../brightness` | `brightness set N` (0-255, `/dev/disp` ioctl) |
| CPU speed | `scaling_setspeed` + userspace governor | `scaling_max_freq`, works under stock schedutil |
| Cores | shipped in `.system/<plat>/cores` | KNULLI's own 100+ at `/usr/lib/libretro` |
| Install root | `/storage/roms/MinUIAmber` | `/userdata/roms/MinUIAmber` |

The CPU frequency table is **read at runtime** from
`scaling_available_frequencies` rather than hardcoded — the A133P BSP kernel
carries its OPP table internally and doesn't declare one in the device tree,
so there was nothing to copy.

`HAS_HDMI` is deliberately **not** defined. `defines.h` then aliases `HDMI_*`
to `FIXED_*`, which is what makes minarch fold `SCALE_CROPPED` into
`SCALE_NATIVE` on a display that can't change mode.

## Core mapping

KNULLI has no `race`, `mednafen_pce_fast`, `mednafen_supafaust` or
`stella2014`, so those paks were remapped:

| Pak | RG351V core | V90S core |
|---|---|---|
| NGP / NGPC | `race` | `mednafen_ngp` |
| PCE | `mednafen_pce_fast` | `pce_fast` |
| SUPA | `mednafen_supafaust` | `snes9x_next` |
| A2600 | `stella2014` | `stella` |

All 23 emulator paks were checked against the card's actual
`/usr/lib/libretro` — every one resolves. Each pak also falls back to
`$SYSTEM_PATH/cores` if a KNULLI update ever renames a core.

SUPA is the one real compromise: supafaust is the fast SNES core MinUI
prefers and KNULLI doesn't carry it. `snes9x_next` (snes9x2005) is the closest
equivalent, and it plays fine on this board.

## Install

**MinUI Amber runs on top of KNULLI on this device.** Two reasons: the stock
firmware isn't much good, and KNULLI was already on the card. KNULLI's job here
is narrow — bring up the kernel, PowerVR driver, input, audio and wifi, then
hand over. MinUI supplies the front end, the emulators and the settings.

**If you don't already run KNULLI, flash your card with it first.**

Then:

1. Extract the zip. You get a `MinUIAmber/` folder, a `ports/` folder and
   `boot-custom.sh`.

2. Put the card in a PC. It shows two partitions: **BATOCERA** (small, FAT32,
   the boot partition) and **SHARE** (the big one — this is `/userdata`).

3. Copy `MinUIAmber/` into SHARE's `roms` folder, so it lands at:
   ```
   /userdata/roms/MinUIAmber/
   ```

4. Copy the **contents** of `ports/` into `SHARE/roms/ports/`, merging with
   whatever is there:
   ```
   /userdata/roms/ports/Enable MinUI Amber.sh
   /userdata/roms/ports/Disable MinUI Amber.sh
   /userdata/roms/ports/PortMaster/...
   ```

5. *Optional, for faster boot:* copy `boot-custom.sh` to the root of the
   **BATOCERA** partition (`/boot/boot-custom.sh`). See *Boot trimming* below.
   Undo it by deleting the file from any PC.

6. Boot to EmulationStation, then **PORTS → Enable MinUI Amber**. That runs the
   script, sets MinUI Amber up for all further boots, and reboots into it.

To go back: **Ports → Disable MinUI Amber**, or from a shell
`/userdata/roms/MinUIAmber/EnableMinUIAmber.sh off`. Use `status` instead of
`off` to see the current state without changing anything.

Enabling does exactly two things, both inside `/userdata`:

- writes `/userdata/system/custom.sh` (backing up any existing one to
  `custom.sh.pre-minuiamber`)
- sets `system.es.atstartup 0` in `batocera.conf`

Disabling reverses both. Nothing outside `/userdata` is touched, so a KNULLI
update leaves the install intact — though an update *can* reset
`es.atstartup`, which is why `MinUI.pak/launch.sh` also stops ES defensively
if it finds it running.

## Ports

Same two-part scheme as the RG351V build: the real payload and launch script
live at `/userdata/roms/ports/` so ES's own Ports menu works too, and MinUI
lists thin `exec` shims under `Roms/Ports (PORTS)/`. A port with no shim is
invisible in MinUI.

PortMaster 8.6.1 is bundled and appears as a system inside MinUI. One KNULLI
wrinkle: PortMaster resolves its control folder to `/roms/ports/PortMaster`.
AmberELEC ships `/roms` as a symlink to `/storage/roms`; KNULLI has no such
link, so the shim creates one pointing at `/userdata/roms` and recreates it if
a KNULLI update wipes it. Tested on the device.

## Build

```
docker run --rm -v '<path-to>/MinUI-upstream/workspace:/root/workspace' \
  tg5040-toolchain /bin/bash -lc 'bash /root/workspace/build_v90s.sh'
```

Source tree is `~/MinUI-upstream/workspace/v90s` (forked from `rg351v`, which
already had the right 640x480 geometry). Staging tree is
`~/MinUIAmber-release/v90s`; `~/stage_v90s.sh` rebuilds it from the rg351v
tree plus fresh binaries, `~/package_v90s.sh` zips it.

Note `-mtune=cortex-a53 -march=armv8-a`: the A133P is A53, not the A55 the
RG351V build targeted.

## Boot trimming

`/boot/boot-custom.sh` (on the FAT32 BATOCERA partition — editable from any
PC) runs first, in the foreground, via `S00bootcustom`. It bind-mounts
`/dev/null` over the init scripts this device has no use for, which makes
rcS's own `[ ! -f "$i" ] && continue` guard skip them without even forking.

Nothing is modified: bind mounts are ephemeral, cost none of the 100 MB
overlay budget, and leave the read-only squashfs untouched. **To undo, delete
the file** — no shell or device access needed.

Disabled: avahi (+setup), nfs, dnsmasq, bluetooth (+name, sixad),
triggerhappy, rgbled, toggle-switch, stats, debugmount, emulationstation,
battery-saver.

Kept on purpose: dbus, udev, modules, populate, **audio/PipeWire**, share +
populateshare, **network + connman (wifi)**, ntp + fake-hwclock + rngd (this
board has no battery-backed RTC — that's why early logs are dated 1980),
dropbear (ssh), usbmode (adb), governor, brightness, system, and
**S99userservices**, which is what runs `custom.sh` and therefore MinUI.
Never disable that one.

Why: these daemons are useless on a board with no ethernet, and on 1 GB of
RAM they are not free. `S50triggerhappy` also grabs `/dev/input`, which MinUI
reads directly, so removing it is a correctness win too.

**It is not a boot-time fix.** It was originally done believing `boot.log`'s
43.2 s gap between `S60nfs` and `S65values4boot` was a stall in those daemons.
It wasn't — see below.

### The "43 second boot stall" was a clock jump

`S47fake-hwclock` is **backgrounded** by rcS, so `fake-hwclock load` lands
asynchronously partway through boot and steps the clock forward to the saved
value. `/userdata/system/fake-hwclock.data` contained `1980-01-01 00:00:48`;
the device timezone is Europe/Paris (+1), so that reads as **01:00:48** —
exactly the timestamp of every post-"gap" log line.

The tell: after the trim the gap *moved* (`S60nfs`→`S65values4boot` before,
`S99userservices`→`launch.sh` after) rather than shrinking. A real stall
doesn't relocate.

Comparing the pre-jump portions of both logs, init reached **~4.7 s in both**.

**Never trust `date` in this device's boot logs.** `launch.sh` now records
`/proc/uptime` — monotonic since kernel start, immune to clock steps — at six
stages, appended to `.userdata/v90s/logs/boot.log`.

### Where userspace boot time actually goes

Measured, ~4.5 s total (each timestamp is written *after* that script runs):

| Script | Cost |
|---|---|
| `S12populateshare` | 1.6 s |
| `S11share` (mount /userdata) | 1.0 s |
| `S06audio` (waits for a PipeWire sink) | 0.83 s |
| `S05udev` | 0.4 s |
| everything else | single-digit ms |

The bootloader is already `bootdelay=0` (`partitions/env.img`), so there is
nothing to win there. Whatever remains is kernel + `pvrsrvctl --start` before
rcS, which `boot.log` cannot see — the uptime marks will.

## Fixed after first boot

Three real bugs, all caught by the device's own logs rather than by
inspection:

1. **No sound.** `launch.sh` exported `SDL_AUDIODRIVER=pulseaudio`. The sound
   server on this device is **PipeWire** (`S06audio` starts
   `/usr/bin/pipewire`; `pactl` is just the pulse-compat client), and the
   device's SDL2 reports `alsa, pipewire, dsp, disk, dummy` — no pulseaudio
   backend at all. The log said it outright:
   `SDL_OpenAudio error: Audio target 'pulseaudio' not available`.
   Now picks `pipewire` when the server is up, `alsa` otherwise.
2. **Brightness reset to 20% on every wake.** `PLAT_enableBacklight` used
   `batocera-brightness dispoff/dispon`; `dispon` restores from
   `/var/run/batocera-brightness`, a percentage written by whoever last called
   `dispoff` — often the battery-saver, not us. Now re-applies MinUI's own
   stored level.
3. **Dim/suspend fight.** KNULLI's battery-saver infers activity from
   `inotifywait -e access /dev/input`, which MinUI's polling doesn't reliably
   trip, so it dimmed and then suspended a device in active use. Now disabled
   outright at boot, with the `*.pause` marker kept as a backstop.

Also tuned: idle CPU moved off the bottom step (408 MHz was sluggish), and
the audio sample rate cap raised 44100 → 48000 to match `asound.conf`'s dmix
slave and PipeWire's graph rate, removing a pointless resample.

## Still open

- **SNES performance** on `snes9x_next` — KNULLI has no supafaust. First thing
  to look at if SNES chugs.
- **Brightness step latency** — one `fork`+`exec` of `brightness` per step. If
  it feels laggy, reimplement the `/dev/disp` ioctl directly.
- **Wifi** is not configured. `connman` is kept running for it; set it up from
  ES (Ports → Disable MinUI Amber, configure, re-enable) or put `wifi.enabled`,
  `wifi.ssid` and `wifi.key` in `/userdata/system/batocera.conf`.
- **Tekken 3** is a Namco System 12 arcade romset, well past `mame078plus`.
