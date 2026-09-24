# Repository layout and building

This repo is the MinUI workspace tree for the MinUI Amber platforms, plus the
glue that installs them and the documentation that ships with each release.

## Layout

| Path | What it is |
|---|---|
| `all/` | Upstream MinUI code shared by every platform (minui, minarch, clock, minput, say, syncsettings, common). |
| `rg351v/` | RG351V platform: `platform/`, `keymon/`, `libmsettings/`, `cores/`, and `show/` (kept for reference, not built). |
| `rpp/` | Retro Pixel Pocket platform. Same shape; the RPP has no dedicated code path and falls into the shared r36s GPIO branch. |
| `v90s/` | Powkiddy V90S platform, forked from `rg351v/` (also 640x480). Built for KNULLI, not AmberELEC. |
| `emus_<device>/` | The emulator paks as shipped in that device's zip, under `MinUIAmber/Emus/<device>/`. |
| `tools_<device>/` | The tool paks as shipped, under `MinUIAmber/Tools/<device>/`. |
| `extras_emus/` | Paks that ship in `MinUIAmber/Extras/`, plus older paks kept for reference. Unsupported. |
| `installer/` | The boot glue: enable/disable scripts, the EmulationStation Ports entries, the PortMaster shims, and each device's `MinUI.pak/launch.sh`. |
| `docs/` | Per-device INSTALL text, the plain-text README, the V90S README and the release notes. |
| `minui_pak_launch.sh` | The RG351V's `MinUI.pak/launch.sh` as shipped. The RPP's is `installer/rpp/minui_pak_launch.sh` and is deliberately different (it leaves pulseaudio and logind alone and has its own audio init); the V90S's is `installer/v90s/minui_pak_launch.sh`. |

## Building

Everything is built inside the `tg5040-toolchain` docker image, which carries
the `aarch64-linux-gnu` gcc. **All three devices run a 64-bit userspace** —
the `rg351v-toolchain` image is a symlink to the armhf `r36s-toolchain` and is
the wrong compiler here.

RG351V and RPP:

```
docker run --rm -v '<workspace>:/root/workspace' tg5040-toolchain /bin/bash -c \
  '. ~/.bashrc; export UNION_PLATFORM=rg351v PLATFORM=rg351v; cd /root/workspace/all/minui && make'
```

Repeat per component (`all/minarch`, `rg351v/keymon`, `rg351v/libmsettings`),
and again with `PLATFORM=rpp` for the Retro Pixel Pocket.

V90S — one script builds the lot (libmsettings, keymon, minui, minarch, clock,
minput, syncsettings, say):

```
docker run --rm -v '<workspace>:/root/workspace' tg5040-toolchain /bin/bash -lc \
  'bash /root/workspace/build_v90s.sh'
```

Notes that cost time to learn:

- `OVERLAY_DEPTH` must be 32. Newer SDL2 rejects 16, and the overlay masks are
  ARGB8888.
- Do **not** define `HAS_HDMI` on the V90S. Letting `defines.h` alias `HDMI_*`
  to `FIXED_*` is what makes minarch fold `SCALE_CROPPED` into `SCALE_NATIVE`
  on a panel that cannot change mode.
- `show` is not built on any of these platforms; they ship the prebuilt
  `showpng.elf`.
- On the V90S, `/bin/sh` is dash, where `&>` is not a redirect at all:
  `cmd &> file` runs `cmd` in the background and truncates `file`, so a pak
  returns at once and MinUI relaunches on top of the running game. Pak
  scripts use `> file 2>&1`.
- `-march` matters. The RG351V and RPP are RK3326 (Cortex-A35, plain
  ARMv8-A) and the V90S is an A133P (Cortex-A53). The rgb30's
  `-march=armv8.2-a` lets gcc emit ARMv8.1 atomics (`ldaddal`) that the A35
  cannot execute.
- MinUI maps a rom folder's `(TAG)` to `Emus/<platform>/TAG.pak` exactly. A
  mismatch means the game simply will not launch.
