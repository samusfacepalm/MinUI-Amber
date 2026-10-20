===============================================================================
 MinUI Amber v0.3
===============================================================================
 A port of MinUI for AmberELEC on RK3326 devices, KNULLI on the V90S, and
 ArkOS4Clone on the A10 Mini

MinUI Amber is more or less intended to be a straight port in the spirit of
the original MinUI. Simple UI, simple SD card, a frontend that is designed to
get the hell out of your way so you can play games.

This means no boxart, no whizbang super duper high-falutin' handhelds that do
your taxes in a KDE desktop environment.

However, unlike original MinUI, this is designed to work with a single SD
card. Two SD card setups on the RG351V have not been tested, and the RPP only
has a single slot anyway -- and you could fit the entire library of games
you'd want to play on these devices on a single card anyway.

If you want those features -- it's only a tool away. MinUI Amber comes with
Return to EmulationStation, where you can use the full AmberELEC environment.
The device will still boot into MinUI next boot.

MinUI Amber runs on top of AmberELEC. It runs over the top of KNULLI on the
V90S, and over the A10 Mini's own ArkOS4Clone. It does not replace your
firmware. You can return to EmulationStation at
any time.

-------------------------------------------------------------------------------
 SUPPORTED DEVICES
-------------------------------------------------------------------------------

  Device                            Status
  Anbernic RG351V                   ✅ Supported
  Retro Pixel Pocket (RPP)          ✅ Supported
  Powkiddy V90S (KNULLI)            ✅ Supported
  YMC A10 Mini v1 / v2              ✅ Supported
  YMC A10 Mini V4                   ⚠️ Should work, untested

 Planned Devices
- Anbernic RG351M -- in progress (requires full platform port, 320x480
  display differs from RG351V)
- Odroid Go Advance -- planned (hardware pending verification)

 Unofficial / May Work
MinUI Amber will most likely boot on any AmberELEC-compatible RK3326 device,
with the exception of the RG552 (different SoC). However, inputs may be wrong
and behaviour may be buggy. Back up your AmberELEC configuration before
trying.

- Anbernic RG351M
- Anbernic RG351MP
- Anbernic RG351P

-------------------------------------------------------------------------------
 INSTALLATION
-------------------------------------------------------------------------------

MinUI Amber is switched on and off from EmulationStation's Ports menu. This is
the same install path on every supported device.

1. Extract the zip. You get a MinUIAmber/ folder and a ports/ folder.

2. Copy the MinUIAmber/ folder to your SD card so it sits at:
   ```
   /storage/roms/MinUIAmber/
   ```
   This may be the root folder of your GAMES partition.

3. Copy the contents of ports/ into the card's existing ports folder, merging
with whatever is already there:
   ```
   /storage/roms/ports/Enable MinUI Amber.sh
   /storage/roms/ports/Disable MinUI Amber.sh
   /storage/roms/ports/PortMaster/...
   ```
   The two .sh files must sit directly in ports/, not inside a subfolder --
that is all EmulationStation scans for. PortMaster is included so ports show
up as a system inside MinUI; if you already run it and have ports installed,
keep your copy and take only the two .sh files.

4. Boot your device into EmulationStation as normal.

5. Go to Ports and run Enable MinUI Amber. The device reboots into MinUI Amber
automatically.

To go back temporarily: run Return to EmulationStation from MinUI Tools. The
next boot returns to MinUI.

To go back permanently: from EmulationStation, Ports -> Disable MinUI Amber.
That removes the boot hook, restores the AmberELEC services MinUI Amber masks
for faster boot, and reboots into EmulationStation. Nothing is deleted, so
Ports -> Enable MinUI Amber switches back whenever you want.

YMC A10 Mini

Same idea, different paths. The big partition is called EASYROMS, and it's
/roms on the device.

1. Copy MinUIAmber/ to the top of EASYROMS, so it sits at /roms/MinUIAmber/.
2. Copy the three .sh files from ports/ into EASYROMS/ports/. There's an
   Uninstall MinUI Amber on this one as well.
3. Boot to EmulationStation, then Ports -> Enable MinUI Amber.

Enable changes two files on the BOOT partition, and backs each one up first as
<name>.minuiamber-orig: firstboot.sh, so MinUI starts before EmulationStation,
and the screen's DTB, so the screen runs at 60 Hz. Ports -> Uninstall MinUI
Amber puts both back. If the device ever won't boot at all, copy the
.minuiamber-orig files back over the originals from a PC.

One download covers every A10 Mini. The V4's bigger screen is picked up on its
own.

-------------------------------------------------------------------------------
 YOUR ROMS
-------------------------------------------------------------------------------

Place your ROMs in the matching folder inside MinUIAmber/Roms/:

  Folder                            System
  Famicom (NES)                     NES and Famicom Disk System
  Game Boy Color (GBC)              Game Boy and Game Boy Color
  Game Boy Advance (MGBA)           Game Boy Advance (MGBA)
  Game Gear (GG)                    Sega Game Gear
  Neo Geo Pocket (NGP)              Neo Geo Pocket
  Neo Geo Pocket Color (NGPC)       Neo Geo Pocket Color
  PC Engine (PCE)                   PC Engine and PC Engine CD
  PICO 8 (P8)                       PICO-8 (fake-08)
  Pokemon Mini (PKM)                Pokemon Mini
  Sega CD (SEGACD)                  Sega CD / Mega CD
  Sega Master System (SMS)          Sega Master System
  SG-1000 (SG1000)                  Sega SG-1000
  Super Game Boy (SGB)              Super Game Boy enhanced games
  Super Nintendo Entertainment System (SUPA)  SNES
  Playstation (PS)                  PS1
  Portmaster (PORTS)                Portmaster
  Sega Genesis (MD)                 Mega Drive / Genesis (A10 Mini only for now)
  WonderSwan Colour (WSC)           WonderSwan and WonderSwan Colour (A10 Mini
                                    only for now)

Please note MinUI Amber doesn't use GPSP or Gambatte. MGBA is used for
all Gameboy emulation.

The name in parentheses must match the pak name in Emus/ exactly -- that's how
MinUI picks the emulator. The text before the parentheses is what shows in the
menu, so name that part whatever you like.

Native PICO-8 is available separately. Splore requires your own PICO-8
binaries in the BIOS folder. Replace fake-08 with native PICO-8.

Playstation is not included on the Retro Pixel Pocket as it does not have L2
or R2 available.

-------------------------------------------------------------------------------
 EXTRAS
-------------------------------------------------------------------------------

The Extras/ folder contains additional emulator paks for less common systems:

Amstrad CPC, Atari 2600, Atari 7800, Atari Lynx, Commodore 64, Commodore
Amiga, Doom (PRBOOM), Final Burn Neo, MSX, Sega 32X

To use extras, copy the relevant pak from Extras/Emus/<platform>/ into
Emus/<platform>/, and create a matching folder in Roms/ if needed. Extras are
unsupported -- your mileage may vary.

Additionally, any 64-bit libretro core from other MinUI versions should work
fine.

-------------------------------------------------------------------------------
 CONTROLS
-------------------------------------------------------------------------------

In menus:
  Input                             Action
  D-pad                             Navigate
  A                                 Select / confirm
  B                                 Back / cancel
  Power                             Sleep (press) / Power off (hold).
                                    On the A10 Mini, a press powers off

In games:
  Input                             Action
  Menu                              Open in-game menu (save states, options, exit)
  Menu + Volume Up/Down             Adjust brightness

-------------------------------------------------------------------------------
 KNOWN ISSUES
-------------------------------------------------------------------------------

- You will see the original boot logo before MinUI starts. This is normal --
  AmberELEC boots first, then hands off to MinUI.

- This version differs from stock MinUI in its Game Boy handling. MGBA is
  used for all Game Boy systems. This lets you do things like run Super Game
  Boy Colour mode in GBC games, have better palette access, and so on. SGB
  is still included separately for games you want to play with borders,
  games that are specifically SGB enhanced, hacks, or if you want to lose
  the use of your eyes gazing upon the beauty of Metroid 2's built-in
  palette on the SGB.

- [RPP] Controls can occasionally stop responding when the device goes into
  standby until the power switch is briefly slid.

- [A10 Mini] A lot of these screens look dark and washed out head on, and fine
  at an angle. That's the panel, not MinUI. Tools -> Display Fix helps; run it
  again to turn it off.

- [A10 Mini V4] I don't have one. It should work, since it's the same board
  with a bigger screen, but nobody has tried it yet. Tell me if it doesn't.

-------------------------------------------------------------------------------
 FAQ
-------------------------------------------------------------------------------

Q: I see the WiFi icon!
A: MinUI Amber runs on top of AmberELEC and KNULLI so it inherits your network
settings. You will need to configure WiFi in AmberELEC/KNULLI first if you
want it.

Q: Can I still use EmulationStation?
A: Yes. Run "Return to EmulationStation" from MinUI Tools at any time -- that
is a one-off trip, and the next boot goes back to MinUI. To make ES your
default again for good, run Ports -> Disable MinUI Amber from
EmulationStation.

Q: Will my saves and settings be affected?
A: No. MinUI Amber stores its data in /storage/roms/MinUIAmber/ and leaves
your AmberELEC saves and settings alone. The only system changes are its boot
hook (backing up any existing custom_start.sh) and a few boot services it
switches off for speed, and Ports -> Disable MinUI Amber reverses both.

Q: Native Pico-8??
A: Available as a separate add-on. You supply your own PICO-8 binaries -- I'm
not shipping software I'd have to pirate to give you. Drop them in the BIOS
folder and Splore works. Fake-08 is still included and still the default. The
add-on was built and tested on the Retro Pixel Pocket; there's no reason a
PICO-8 Native pak compiled for the RK3326 shouldn't work elsewhere, but it
hasn't been tried.

Q: Why did my A10 Mini's screen change to 60 Hz?
A: Out of the box it runs at 57.7 Hz (61.7 on the V4). Games expect 60, so
they ran slow, or fast, and the sound crackled trying to keep up. Enable speeds
the screen's clock up or down to 60 and leaves everything else in the file
alone. EmulationStation gets the 60 Hz too.

Q: It stinks, it stinks, it stinks!
A: Yes Mr Sherman, everything stinks. No, seriously, this is the first time
I've ever done anything like this. Please let me know if it does stink.

-------------------------------------------------------------------------------
 CHANGELOG
-------------------------------------------------------------------------------

v0.3

YMC A10 Mini
- Initial support: v1, v2 and V4, on the ArkOS4Clone it ships with. Tested on
  a v1.
- Screen runs at 60 Hz, so games run at the right speed without crackle.
- Sega Genesis and WonderSwan added.
- Display Fix in Tools for the dark screens.
- A press of the power button turns it off.

The RG351V, RPP and V90S are unchanged from v0.2.1.

v0.2.1

All devices
- PlayStation L2 and R2 now work -- before, they couldn't even be mapped.
- Return to EmulationStation no longer leaves MinUI's volume and brightness
  keys running underneath ES.
- Rom folders now match this README: Game Boy Advance (MGBA), Playstation
  (PS), Portmaster (PORTS).

RG351V and RPP
- Disable MinUI Amber gives AmberELEC its suspend back. v0.2 switched it off
  for good; the first boot of this version clears that up.
- Return to EmulationStation brings back suspend, the power button and the
  services you had turned on (Samba, the web UI and so on).
- ROMs with double spaces in their names now launch.

RPP
- Files now uses the whole 720x720 screen.

V90S
- Disable MinUI Amber no longer boots to a black screen when the optional
  boot-custom.sh is installed.
- Ports, PortMaster, and EmulationStation after Return to EmulationStation,
  no longer run at the menu's CPU speed.

v0.2

All devices
- Boot time is now much faster.
- PortMaster support added -- tested with AM2R, other games should work.
  PortMaster comes by default.
- Shutdown is now much faster and works properly.
- Audio issues fixed.
- Clock works.
- CPU speed control fixed -- games can now clock up.

RG351V
- Analogue stick fixed and now works perfectly.

RPP
- Brightness wheel now works.

V90S
- Initial support. Port of opportunity. No issues in my limited testing.

v0.1
- Initial release.

-------------------------------------------------------------------------------
 DISCLAIMER
-------------------------------------------------------------------------------

THIS IS FREE SOFTWARE. I am not responsible if your house burns down, your
wife leaves you, or your handheld decides to run away and join the circus as a
result of you installing this software.

All included software is still covered under its original licenses.

-------------------------------------------------------------------------------
 CREDITS
-------------------------------------------------------------------------------

- Shaun Inman (shauninman) -- MinUI, retro handheld frontend Jesus himself
  -- https://github.com/shauninman/MinUI
- NextUI -- updated Files.pak for the RG351V and improved binaries --
  https://github.com/ryanmsartor/NextUI
- Turro75 -- MyMinUI, original RK3326 port which this is partially based on
  -- https://github.com/Turro75/MyMinUI
- Frysee -- help with the Retro Pixel Pocket port

MinUI Amber port by MinUI Installer
Built on AmberELEC -- https://amberelec.org
Built on KNULLI - Knulli.org
Built on ArkOS4Clone, a build of ArkOS for clone devices

