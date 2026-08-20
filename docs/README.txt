===============================================================================
 MinUI Amber v0.2
 A port of MinUI for AmberELEC on RK3326 devices
===============================================================================

Supported devices:
  - Anbernic RG351V
  - Retro Pixel Pocket (RPP)
  - Powkiddy V90S (KNULLI) -- initial support, separate build,
    see its own README

Planned devices:
  - Anbernic RG351M (in progress — requires full platform port due to
    320x480 display, different from the RG351V)
  - V90S (planned, running BatoCera)
  - Odroid Go Advance (planned, hardware pending verification)

Unofficial / may work:
  MinUI Amber will most likely boot on any AmberELEC-compatible RK3326
  device, with the exception of the RG552 (which uses a different SoC).
  However, inputs may be wrong and behaviour may be buggy. Use at your
  own risk and back up your AmberELEC configuration first.

  Known to potentially work (untested, unsupported):
    - Anbernic RG351M
    - Anbernic RG351MP
    - Anbernic RG351P

MinUI Amber is more or less intended to be a straight port in the spirit of
the original MinUI. Simple UI, simple SD card, a frontend that is designed
to get the hell out of your way so you can play games.

This means no boxart, no Portmaster, no whizbang super duper high-falutin'
handhelds that do your taxes in a KDE desktop environment.

However, unlike original MinUI, this is designed to work with a single SD
card. Two SD card setups on the RG351V have not been tested, and the RPP
only has a single slot anyway — and you could fit the entire library of
games you'd want to play on these devices on a single card anyway.

However, if you want those features — it's only a tool away. MinUI Amber
comes with Return to EmulationStation, where you can use the full AmberELEC
environment. The device will still boot into MinUI next boot.

-------------------------------------------------------------------------------
 INSTALLATION
-------------------------------------------------------------------------------

MinUI Amber is switched on and off from EmulationStation's PORTS menu.
This is the same install path on every supported device.

1. Extract the zip. You get a MinUIAmber/ folder and a ports/ folder.

2. Copy the MinUIAmber/ folder to your SD card so it sits at:
     /storage/roms/MinUIAmber/

3. Copy the CONTENTS of ports/ into the card's existing ports folder,
   merging with whatever is already there:
     /storage/roms/ports/Enable MinUI Amber.sh
     /storage/roms/ports/Disable MinUI Amber.sh
     /storage/roms/ports/PortMaster/...
   The two .sh files must sit DIRECTLY in ports/, not inside a
   subfolder -- that is all EmulationStation scans for. PortMaster is
   included so ports show up as a system inside MinUI; if you already
   run it and have ports installed, keep your copy and take only the
   two .sh files.

4. Boot your device into EmulationStation as normal.

5. Go to PORTS and run "Enable MinUI Amber".
   The device will reboot into MinUI Amber automatically.

To go back temporarily, run "Return to EmulationStation" from MinUI
Tools. The next boot returns to MinUI.

To go back permanently, from EmulationStation run
PORTS -> "Disable MinUI Amber". That removes the boot hook, restores the
AmberELEC services MinUI Amber masks for faster boot, and reboots into
EmulationStation. Nothing is deleted, so PORTS -> "Enable MinUI Amber"
switches back whenever you want.

Over SSH the same script does all three:
     /storage/roms/MinUIAmber/EnableMinUIAmber.sh on
     /storage/roms/MinUIAmber/EnableMinUIAmber.sh off
     /storage/roms/MinUIAmber/EnableMinUIAmber.sh status

If you removed custom_start.sh by hand instead of using
"Disable MinUI Amber", restore the services over SSH with:
     systemctl unmask syncthing.service smbd.service nmbd.service        webui.service avahi-daemon.service avahi-defaults.service        lastgame.service wsdd2.service pulseaudio.service

-------------------------------------------------------------------------------
 YOUR ROMS
-------------------------------------------------------------------------------

Place your ROMs in the matching folder inside MinUIAmber/Roms/:

  Famicom (NES)                      NES and Famicom Disk System
  Game Boy Color (MGBA)              Game Boy and Game Boy Color
  Game Gear (GG)                     Sega Game Gear
  Neo Geo Pocket (NGP)               Neo Geo Pocket
  Neo Geo Pocket Color (NGPC)        Neo Geo Pocket Color
  PC Engine (PCE)                    PC Engine and PC Engine CD
  PICO 8                             PICO-8 (fake-08)
  PICO 8 NATIVE                      PICO-8 (native)
  Pokemon Mini (PKM)                 Pokemon Mini
  Sega CD (SEGACD)                   Sega CD / Mega CD
  Sega Master System (SMS)           Sega Master System
  SG-1000 (SG1000)                   Sega SG-1000
  Super Game Boy (SGB)               Super Game Boy enhanced games
  Super Nintendo Entertainment System (SUPA)   SNES

The name in parentheses must match the pak name in Emus/ exactly --
that is how MinUI picks the emulator. The text before the parentheses
is what shows in the menu.

If you already have ROMs set up in AmberELEC, a migration tool is available
in MinUI Tools to move them to the correct folders automatically.

-------------------------------------------------------------------------------
 EXTRAS
-------------------------------------------------------------------------------

The Extras/ folder contains additional emulator paks for less common systems:

  Amstrad CPC, Atari 2600, Atari 7800, Atari Lynx, Commodore 64,
  Commodore Amiga, Doom (PRBOOM), Final Burn Neo, MSX, Sega 32X

To use extras, copy the relevant pak from Extras/Emus/<platform>/ into
Emus/<platform>/, and create a matching folder in Roms/ if needed.
Extras are unsupported — your mileage may vary.

-------------------------------------------------------------------------------
 CONTROLS
-------------------------------------------------------------------------------

In menus:
  D-pad         Navigate
  A             Select / confirm
  B             Back / cancel
  Menu          Sleep (press) / Power off (hold)

In games:
  Menu          Open in-game menu (save states, options, exit)
  Menu + Volume Up/Down   Adjust brightness

-------------------------------------------------------------------------------
 KNOWN ISSUES
-------------------------------------------------------------------------------

- You will occasionally see the original boot logo before MinUI starts.
  This is normal — AmberELEC boots first, then hands off to MinUI.

- [RG351V] The device could previously sleep instead of powering down,
  freezing controls. AmberELEC's power-key handling (logind suspending
  the device behind MinUI's back) is now overridden at boot. Hold the
  power button to force a reset if it ever happens anyway. This
  override does not ship on the RPP build (see below).

- If the device loses power unexpectedly while in a game, progress since
  your last save state will be lost. Use the in-game menu (Menu button)
  to save regularly.

- This version differs from stock MinUI in its Game Boy handling. MGBA
  is used for all Game Boy systems. This lets you do things like run
  Super Game Boy Colour mode in GBC games, have better palette access,
  and so on. SGB is still included separately for games you want to play
  with borders, games that are specifically SGB enhanced, hacks, or if
  you want to lose the use of your eyes gazing upon the beauty of
  Metroid 2's built-in palette on the SGB.

- [RPP] Controls can occasionally stop responding until the power switch
  is briefly slid. This is not a hardware bug: AmberELEC's power-key
  handling suspends the device when the power slider emits a stray key
  event, and sliding it again resumes it. The RG351V build disables that
  handling; the fix is not in the RPP build yet, because the RPP launch
  script is kept close to the verified-working v0.1 original. Sliding
  the power switch again is the workaround until it is tested on
  device.

- [RPP] MinUI would sometimes close but leave the screen on for a
  minute or two before the device powered off (a slow shutdown sequence
  in the Funnyplaying firmware). MinUI now forces immediate power-off
  after syncing saves.

- PortMaster ships as version 8.6.1, straight from the PortMaster
  project. It has been exercised with AM2R on the RG351V; the RPP and
  V90S bundles are the same payload but have not been run on those
  devices yet. Report anything that misbehaves.

-------------------------------------------------------------------------------
 FAQ
-------------------------------------------------------------------------------

Q: I see the WiFi icon!
A: MinUI Amber runs on top of AmberELEC, so it inherits your AmberELEC
   network settings. SSH is available using your AmberELEC credentials.
   You will need to configure WiFi in AmberELEC first if you want it.

   Default SSH credentials:
     RG351V:  root / amberelec
     RPP:     root / retropixel

Q: Can I still use EmulationStation?
A: Yes. Run "Return to EmulationStation" from MinUI Tools at any time
   -- that is a one-off trip, and the next boot goes back to MinUI. To
   make ES your default again for good, run PORTS -> "Disable
   MinUIAmber" from EmulationStation.

Q: Will my AmberELEC saves and settings be affected?
A: No. MinUI Amber stores its data in /storage/roms/MinUIAmber/ and does
   not touch your AmberELEC configuration.

Q: Any changes from stock MinUI?
A: Yes. MinUI Amber includes platform-specific fixes for AmberELEC:
   - Audio output configured for hardware compatibility
   - Button mappings adjusted for RG351V and RPP hardware
   - Boot integration via AmberELEC's custom_start.sh hook
   - Service masking for faster boot times

Q: It takes ages to boot???
A: I've done my best, but this is as fast as it will go. The time to boot
   is an AmberELEC thing, and unless I spent a month gutting it (at which
   point I would be better off porting MOSS to these devices), it ain't
   gonna happen.

Q: It stinks, it stinks, it stinks!
A: Yes Mr Sherman, everything stinks. No, seriously, this is the first time
   I've ever done anything like this. Please let me know if it does stink.

-------------------------------------------------------------------------------
 CHANGELOG
-------------------------------------------------------------------------------

v0.2

ALL DEVICES
  - Faster boot. The heavy services MinUI does not need are switched
    off; on the V90S the unwanted KNULLI init scripts are skipped.
  - PortMaster is now included by default on every device and appears
    as a system inside MinUI. Tested with AM2R; other ports should
    work.
  - Faster, cleaner shutdown. Power-off no longer waits on the
    firmware's own service teardown, and saves are synced first.
  - Audio fixed. The output path is initialised when MinUI boots
    straight into itself, volume scales across the full range, and the
    sample rate matches the hardware.
  - Clock works.
  - Changed: install and uninstall now live in EmulationStation's
    PORTS menu on every device, instead of Homebrew on AmberELEC.
    ports/Enable MinUI Amber.sh and ports/Disable MinUI Amber.sh are
    thin shims over MinUIAmber/EnableMinUIAmber.sh, which also takes
    on, off and status from a shell.
  - Added: "Disable MinUI Amber" -- a real uninstall. It removes the
    boot hook, restores any custom_start.sh it had backed up, and
    unmasks every service that enabling masked.
  - Fixed: GBC, SNES, Sega CD and SG-1000 games would not launch (rom
    folder tags did not match the emulator pak names).
  - Fixed: CPU speed control did nothing; games can now clock up.

RG351V
  - Analogue stick fixed -- it now works properly. The v0.1 binary was
    built without the stick support code.
  - Fixed: the device could suspend instead of powering off, freezing
    controls until the power switch was used again.
  - Fixed: volume buttons required select/start to be held, and the
    saved volume was overwritten on every boot.

RETRO PIXEL POCKET
  - Brightness wheel now works.
  - Added: Files.pak file manager, and PortMaster (previously RG351V
    only).

POWKIDDY V90S
  - Initial support -- a port of opportunity, running on top of
    KNULLI. See the V90S README for what that means and what is still
    untested.

v0.1.1
  - Fixed: GBC, SNES, Sega CD and SG-1000 games would not launch (rom
    folder tags did not match the emulator pak names).
  - Fixed: [RG351V] analogue stick did not work (the v0.1 binary was
    built without the stick support code).
  - Fixed: [RG351V] device could suspend instead of powering off,
    freezing controls until the power switch/button was used again --
    AmberELEC's power-key handling was racing MinUI, and is now disabled
    while MinUI runs. (Not yet applied to the RPP build.)
  - Fixed: [RPP] shutdown could leave the screen frozen on for a minute
    or two; power-off is now immediate after saves are synced.
  - Fixed: [RG351V] volume buttons required select/start to be held
    (keymon treated the V as a 351P).
  - Fixed: audio path was never initialised when booting straight into
    MinUI (AmberELEC sets it after MinUI's boot hook), and volume now
    scales correctly across the full range.
  - Added: [RG351V] PORTS emulator pak plus the PortMaster payload, so
    ports appear as a system; MinUI also restarts keymon and clears
    stray gptokeyb after a port exits.
  - Fixed: CPU speed control did nothing (missing governor setup and
    environment); games can now clock up to 1.5GHz.
  - Fixed: installing via SSH (INSTALL.sh) did not disable the heavy
    AmberELEC services, leaving boot slow; services are also re-disabled
    every boot so "Return to EmulationStation" can't leave boot slow
    permanently.
  - Fixed: [RG351V] saved volume was overwritten on every boot.
  - Added: [RPP] Files.pak file manager (previously RG351V only).
  - Fixed: EnableMinUIAmber never appeared in EmulationStation -- it
    shipped as a .pak folder, but AmberELEC's Homebrew menu only scans
    for bare .sh files. It's now EnableMinUIAmber.sh, placed directly in
    /storage/roms/homebrew/.
  - Docs: rom folder table corrected; install/uninstall instructions now
    match this AmberELEC build (homebrew, not tools); uninstall
    instructions restore AmberELEC services.

v0.1
  - Initial release.

-------------------------------------------------------------------------------
 DISCLAIMER
-------------------------------------------------------------------------------

THIS IS FREE SOFTWARE. I am not responsible if your house burns down, your
wife leaves you, or your handheld decides to join the circus as a result of
you installing this software.

All included software is still covered under its original licenses.

-------------------------------------------------------------------------------
 CREDITS
-------------------------------------------------------------------------------

Shaun Inman (shauninman) — MinUI, retro handheld frontend Jesus himself
  https://github.com/shauninman/MinUI

NextUI — updated Files.pak for the RG351V and improved binaries
  https://github.com/ryanmsartor/NextUI

Turro75 — MyMinUI, original RK3326 port which this is partially based on
  https://github.com/Turro75/MyMinUI

Frysee — help with the Retro Pixel Pocket port

MinUI Amber port by MinUI Installer
Built on AmberELEC — https://amberelec.org

===============================================================================
