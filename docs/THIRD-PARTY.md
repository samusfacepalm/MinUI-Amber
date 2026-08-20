# Third-party software in MinUI Amber

MinUI Amber bundles other people's work. Nothing here is a game, a game ROM,
a BIOS image or a save file — **the release ships no copyrighted game content
of any kind, and the `Roms/`, `Bios/`, `Saves/` and `Cheats/` folders are
deliberately empty.** You supply your own.

What *is* bundled is free software, listed below with where it comes from.
Each component keeps its own licence; this file is an inventory, not a
substitute for those licences.

## MinUI and this port

| | |
|---|---|
| **MinUI** | Shaun Inman — https://github.com/shauninman/MinUI |
| **NextUI** | Files.pak (NextCommander) and improved binaries — https://github.com/ryanmsartor/NextUI |
| **MyMinUI** | Turro75's RK3326 port, which this is partly based on — https://github.com/Turro75/MyMinUI |
| **MinUI Amber** | This port. Source: https://github.com/samusfacepalm/MinUI-Amber |

`minui.elf`, `minarch.elf`, `keymon.elf`, `clock.elf`, `minput.elf`,
`say.elf`, `syncsettings.elf`, `showpng.elf` and `libmsettings.so` are built
from that source.

## libretro emulator cores

The RG351V and RPP builds ship prebuilt libretro cores under
`.system/<platform>/cores/` and inside some emulator paks. The V90S build
ships **no** cores — it uses KNULLI's own at `/usr/lib/libretro`.

Cores bundled: a5200, bluemsx, cap32, dosbox, fake08, fbneo, fceumm,
gambatte, gearcoleco, gpsp, handy, mame2003_plus, mednafen_ngp,
mednafen_pce_fast, mednafen_supafaust, mednafen_vb, mednafen_wswan, mesen,
mgba, neocd, pcsx_rearmed, picodrive, pokemini, prboom, prosystem,
puae2021, race, snes9x, snes9x2005_plus, stella2014, tyrquake, and the VICE
family (x64, x128, xpet, xplus4, xvic).

Each core is a separate upstream project with its own licence — most are
GPLv2 or GPLv3, mGBA is MPL-2.0, and a few (MAME 2003-Plus, FinalBurn Neo,
Snes9x) carry **non-commercial** licences that permit free redistribution but
forbid selling. Start at https://github.com/libretro for any given core, and
at https://docs.libretro.com for what each one is.

**Consequence: MinUI Amber must not be sold.** Give it away, don't charge for
it, and don't put it on a card you sell.

**GPL source:** these cores are redistributed unmodified from the builds
shipped by AmberELEC (https://github.com/AmberELEC/AmberELEC) and NextUI.
If you want the corresponding source for a GPL core, it is available from
that core's upstream project and from the AmberELEC build system; open an
issue on the MinUI Amber repo if you have trouble getting it.

## PortMaster

Bundled at version 8.6.1, unmodified, from
https://github.com/PortsMaster/PortMaster-New — MIT licensed. Its payload
includes `gptokeyb` (https://github.com/christianhaitian/gptokeyb),
`oga_controls` (https://github.com/christianhaitian/oga_controls), and
`wget`, `grep`, `libpcre`, `libpcre2`, `libpsl` and `libunistring` binaries,
each under its own GPL/LGPL terms. `gamecontrollerdb.txt` comes from
https://github.com/mdqinc/SDL_GameControllerDB (zlib/simple).

## Fonts and assets

| | |
|---|---|
| `BPreplayBold-unhinted.otf` | BPreplay by George Triantafyllakos, as shipped by upstream MinUI |
| `SourceCodePro-Regular.ttf`, `SourceCodePro-Semibold.ttf` | Adobe Source Code Pro, SIL Open Font License 1.1 |
| `assets@1x-4x.png`, `charging-*.png`, `logo.png`, Files.pak icons | Upstream MinUI / NextUI interface art |

## PICO-8 native add-on

The add-on ships a launcher script and a controller mapping. **It contains no
part of PICO-8.** PICO-8 is commercial software by Lexaloffle Games; buy it at
https://www.lexaloffle.com/pico-8.php and supply the binary yourself. The
`P8` pak in the main release uses **fake-08**, an independent reimplementation,
not PICO-8 itself.

## Firmware

MinUI Amber runs on top of AmberELEC (RG351V, RPP) and KNULLI (V90S). Neither
firmware is bundled or redistributed here; you install those yourself.

---

If something in this list is wrong, or your project is bundled and you'd
rather it wasn't, open an issue on the repo and it will be fixed.
