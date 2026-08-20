# MinUI Amber v0.2
### A port of MinUI for AmberELEC on RK3326 handhelds, and for KNULLI on the Powkiddy V90S

MinUI Amber is more or less intended to be a straight port in the spirit of the original MinUI. Simple UI, simple SD card, a frontend that is designed to get the hell out of your way so you can play games.

This means no boxart, no whizbang super duper high-falutin' handhelds that do your taxes in a KDE desktop environment.

However, unlike original MinUI, this is designed to work with a single SD card. Two-card setups on the RG351V have not been tested, and the RPP only has one slot — and you could fit the entire library of games you'd want to play on these devices onto a single card regardless.

If you want those features — it's only a tool away. MinUI Amber comes with Return to EmulationStation, where you can use the full AmberELEC environment. The device will still boot into MinUI next boot.

MinUI Amber runs on top of the firmware that is already on your device — AmberELEC on the RG351V and Retro Pixel Pocket, KNULLI on the Powkiddy V90S. It does not replace that firmware. You can return to EmulationStation at any time.

---

## Supported Devices

| Device | Firmware | Status |
|--------|----------|--------|
| Anbernic RG351V | AmberELEC | ✅ Supported |
| Retro Pixel Pocket (RPP) | AmberELEC | ✅ Supported |
| Powkiddy V90S | KNULLI | ✅ Initial support — separate build and [its own README](https://github.com/samusfacepalm/MinUI-Amber/blob/main/docs/README-v90s.md) |

The V90S is a different SoC (Allwinner A133P, not RK3326) running a different
firmware, so it gets its own build and its own documentation. Everything below
describes the AmberELEC builds unless it says otherwise.

### Planned Devices
- **Anbernic RG351M** — in progress (requires full platform port, 320x480 display differs from RG351V)
- **Odroid Go Advance** — planned (hardware pending verification)

### Unofficial / May Work
MinUI Amber will most likely boot on any AmberELEC-compatible RK3326 device, with the exception of the RG552 (different SoC). However, inputs may be wrong and behaviour may be buggy. **Back up your AmberELEC configuration before trying.**

- Anbernic RG351M
- Anbernic RG351MP
- Anbernic RG351P

---

## Installation

MinUI Amber is switched on and off from EmulationStation's **Ports** menu. The steps are the same on every supported device; only the paths differ. The ones below are AmberELEC's — on the V90S, `/storage/roms` is `/userdata/roms` instead, and the [V90S README](https://github.com/samusfacepalm/MinUI-Amber/blob/main/docs/README-v90s.md) walks through it.

1. Extract the zip. You get a `MinUIAmber/` folder and a `ports/` folder.

2. Copy the `MinUIAmber/` folder to your SD card so it sits at:
   ```
   /storage/roms/MinUIAmber/
   ```
   This may be the root folder of your GAMES partition.

3. Copy the **contents** of `ports/` into the card's existing ports folder, merging with whatever is already there:
   ```
   /storage/roms/ports/Enable MinUI Amber.sh
   /storage/roms/ports/Disable MinUI Amber.sh
   /storage/roms/ports/PortMaster/...
   ```
   The two `.sh` files must sit **directly** in `ports/`, not inside a subfolder — that is all EmulationStation scans for. PortMaster is included so ports show up as a system inside MinUI; if you already run it and have ports installed, keep your copy and take only the two `.sh` files.

4. Boot your device into EmulationStation as normal.

5. Go to **Ports** and run **Enable MinUI Amber**. The device reboots into MinUI Amber automatically.

**To go back temporarily:** run **Return to EmulationStation** from MinUI Tools. The next boot returns to MinUI.

**To go back permanently:** from EmulationStation, **Ports → Disable MinUI Amber**. That removes the boot hook, restores the AmberELEC services MinUI Amber masks for faster boot, and reboots into EmulationStation. Nothing is deleted, so **Ports → Enable MinUI Amber** switches back whenever you want.

Over SSH the same script does all three:
```
/storage/roms/MinUIAmber/EnableMinUIAmber.sh on
/storage/roms/MinUIAmber/EnableMinUIAmber.sh off
/storage/roms/MinUIAmber/EnableMinUIAmber.sh status
```

If you removed `custom_start.sh` by hand instead of using **Disable MinUI Amber**, restore the services over SSH with:
```
systemctl unmask syncthing.service smbd.service nmbd.service webui.service avahi-daemon.service avahi-defaults.service lastgame.service wsdd2.service pulseaudio.service
```

---

## Your ROMs

Place your ROMs in the matching folder inside `MinUIAmber/Roms/`:

| Folder | System |
|--------|--------|
| `Famicom (NES)` | NES and Famicom Disk System |
| `Game Boy Color (MGBA)` | Game Boy and Game Boy Color |
| `Game Gear (GG)` | Sega Game Gear |
| `Neo Geo Pocket (NGP)` | Neo Geo Pocket |
| `Neo Geo Pocket Color (NGPC)` | Neo Geo Pocket Color |
| `PC Engine (PCE)` | PC Engine and PC Engine CD |
| `PICO 8 (P8)` | PICO-8 (fake-08) |
| `Pokemon Mini (PKM)` | Pokemon Mini |
| `Sega CD (SEGACD)` | Sega CD / Mega CD |
| `Sega Master System (SMS)` | Sega Master System |
| `SG-1000 (SG1000)` | Sega SG-1000 |
| `Super Game Boy (SGB)` | Super Game Boy enhanced games |
| `Super Nintendo Entertainment System (SUPA)` | SNES |

> The name in parentheses must match the pak name in `Emus/` exactly — that's how MinUI picks the emulator. The text before the parentheses is what shows in the menu, so name that part whatever you like.

The V90S build adds `Game Boy Advance (GBA)` and `Arcade (MAME)` on top of the list above, because KNULLI carries cores for both.

Native PICO-8 is available separately. Splore requires your own PICO-8 binaries in the BIOS folder. Replace fake-08 with native PICO-8.

PlayStation is not included, as the Retro Pixel Pocket has no L2 or R2.

---

## Extras

The `Extras/` folder contains additional emulator paks for less common systems:

> Amstrad CPC, Atari 2600, Atari 7800, Atari Lynx, Commodore 64, Commodore Amiga, Doom (PRBOOM), Final Burn Neo, MSX, Sega 32X

To use extras, copy the relevant pak from `Extras/Emus/<platform>/` into `Emus/<platform>/`, and create a matching folder in `Roms/` if needed. Extras are unsupported — your mileage may vary.

Additionally, any 64-bit libretro core from other MinUI versions should work fine.

---

## Controls

**In menus:**
| Input | Action |
|-------|--------|
| D-pad | Navigate |
| A | Select / confirm |
| B | Back / cancel |
| Menu | Sleep (press) / Power off (hold) |

**In games:**
| Input | Action |
|-------|--------|
| Menu | Open in-game menu (save states, options, exit) |
| Menu + Volume Up/Down | Adjust brightness |

---

## Known Issues

- **[RPP]** Controls can stop responding until you slide the power switch. AmberELEC suspends on a stray key event from the slider; sliding it again wakes it. The RG351V build disables that handling, the RPP build doesn't — its launch script stays close to the working v0.1 one.
- **[V90S]** SNES runs on `snes9x_next` — KNULLI carries no supafaust, which is what MinUI normally uses.
- **[V90S]** No cores in the zip, it uses KNULLI's. If a KNULLI update drops one, that pak stops working — drop a replacement into `.system/v90s/cores`.
- **[V90S]** No battery clock. Dates read 1980 until the device has been online.
- Extras are unsupported. Included because they might work, not because they were tested.
- You'll see the firmware's boot logo before MinUI. Normal — it boots first, then hands over.
- Lose power mid-game and you lose everything since your last save state.
- MGBA runs every Game Boy system, not just GBA — SGB colour modes in GBC games, better palettes. SGB is still there for borders, genuinely SGB-enhanced games, hacks, or losing the use of your eyes gazing upon Metroid 2's built-in palette.
- **Don't sell it.** MAME 2003-Plus, FinalBurn Neo and Snes9x are non-commercial licences. See `THIRD-PARTY.md`.

---

## FAQ

**Q: I see the WiFi icon!**
A: MinUI Amber runs on top of AmberELEC, so it inherits your AmberELEC network settings. SSH is available. You will need to configure WiFi in AmberELEC first if you want it.

Default SSH credentials:
- RG351V: `root` / `amberelec`
- RPP: `root` / `retropixel`
- V90S: KNULLI sets its own — look under System Settings → Security in EmulationStation

**Q: Can I still use EmulationStation?**
A: Yes. Run "Return to EmulationStation" from MinUI Tools at any time — that is a one-off trip, and the next boot goes back to MinUI. To make ES your default again for good, run **Ports → Disable MinUI Amber** from EmulationStation.

**Q: Will my AmberELEC saves and settings be affected?**
A: No. MinUI Amber stores its data in `/storage/roms/MinUIAmber/` and does not touch your AmberELEC configuration.

**Q: Any changes from stock MinUI?**
A: Yes. MinUI Amber includes platform-specific fixes for AmberELEC:
- Audio output configured for hardware compatibility
- Button mappings adjusted for RG351V and RPP hardware
- Boot integration via AmberELEC's `custom_start.sh` hook, or KNULLI's `custom.sh` on the V90S, toggled from the Ports menu
- Service masking for faster boot times

**Q: It takes ages to boot???**
A: Less than it did — v0.2 switches off the services MinUI doesn't need, and on the V90S it skips the KNULLI init scripts entirely. But most of what's left is the firmware coming up before MinUI gets a look in, and short of spending a month gutting it (at which point I'd be better off porting MOSS to these devices), that's as fast as it goes.

**Q: Native Pico-8??**
A: Available as a separate add-on. You supply your own PICO-8 binaries — I'm not shipping software I'd have to pirate to give you. Drop them in the BIOS folder and Splore works. Fake-08 is still included and still the default. The add-on was built and tested on the Retro Pixel Pocket. A PICO-8 Native pak built for the RK3326 should be fine on the RG351V too, but it hasn't been tried; the V90S is a different SoC and would need its own pak.

**Q: It stinks, it stinks, it stinks!**
A: Yes Mr Sherman, everything stinks. No, seriously, this is the first time I've ever done anything like this. Please let me know if it does stink.

---

## Changelog

### v0.2

**All devices**
- **Faster boot.** The heavy services MinUI doesn't need are switched off; on the V90S the unwanted KNULLI init scripts are skipped outright.
- **PortMaster is now included by default on every device** and appears as a system inside MinUI. Tested with AM2R; other ports should work.
- **Faster, cleaner shutdown.** Power-off no longer waits on the firmware's own service teardown, and saves are synced first.
- **Audio fixed.** The output path is initialised when MinUI boots straight into itself, volume scales across the full range, and the sample rate matches the hardware.
- **Clock works.**
- **Changed:** install and uninstall now live in EmulationStation's **Ports** menu on every device, instead of Homebrew on AmberELEC. `ports/Enable MinUI Amber.sh` and `ports/Disable MinUI Amber.sh` are thin shims over `MinUIAmber/EnableMinUIAmber.sh`, which also takes `on`, `off` and `status` from a shell.
- **Added: Disable MinUI Amber — a real uninstall.** It removes the boot hook, restores any `custom_start.sh` it had backed up, and unmasks every service that enabling masked. Previously this meant deleting a file over SSH and unmasking services by hand.
- **Fixed:** GBC, SNES, Sega CD and SG-1000 games would not launch (rom folder tags did not match the emulator pak names).
- **Fixed:** CPU speed control did nothing; games can now clock up.

**RG351V**
- **Analogue stick fixed** — it now works properly. The v0.1 binary was built without the stick support code.
- **Fixed:** the device could suspend instead of powering off, freezing controls until the power button was used again.
- **Fixed:** volume buttons required select/start to be held, and the saved volume was overwritten on every boot.

**Retro Pixel Pocket**
- **Brightness wheel now works.**
- **Added:** Files.pak file manager, and PortMaster (previously RG351V only).

**Powkiddy V90S**
- **Initial support** — a port of opportunity, running on top of KNULLI. See the V90S README.

### v0.1.1

*Never released publicly — these fixes reached you as part of v0.2.*

- **Fixed:** GBC, SNES, Sega CD and SG-1000 games would not launch (rom folder tags did not match the emulator pak names).
- **Fixed:** [RG351V] analogue stick did not work (the v0.1 binary was built without the stick support code).
- **Fixed:** [RG351V] device could suspend instead of powering off, freezing controls until the power button was used again — AmberELEC's power-key handling was racing MinUI, and is now disabled while MinUI runs. (Not yet applied to the RPP build.)
- **Fixed:** [RPP] shutdown could leave the screen frozen on for a minute or two; power-off is now immediate after saves are synced.
- **Fixed:** [RG351V] volume buttons required select/start to be held (keymon treated the V as a 351P).
- **Fixed:** audio path was never initialised when booting straight into MinUI (AmberELEC sets it after MinUI's boot hook), and volume now scales correctly across the full range.
- **Added:** [RG351V] PORTS emulator pak plus the PortMaster payload, so ports appear as a system; MinUI also restarts keymon and clears stray gptokeyb after a port exits.
- **Fixed:** CPU speed control did nothing (missing governor setup and environment); games can now clock up to 1.5GHz.
- **Fixed:** installing via SSH (INSTALL.sh) did not disable the heavy AmberELEC services, leaving boot slow; services are also re-disabled every boot so "Return to EmulationStation" can't leave boot slow permanently.
- **Fixed:** [RG351V] saved volume was overwritten on every boot.
- **Added:** [RPP] Files.pak file manager (previously RG351V only).
- **Fixed:** EnableMinUIAmber never appeared in EmulationStation — it shipped as a `.pak` folder, but AmberELEC's Homebrew menu only scans for bare `.sh` files. It's now `EnableMinUIAmber.sh`, placed directly in `/storage/roms/homebrew/`.
- **Docs:** rom folder table corrected; install/uninstall instructions now match this AmberELEC build (`homebrew`, not `tools`); uninstall instructions restore AmberELEC services.

### v0.1
- Initial release.

---

## Building it yourself

Source, repository layout and the docker build recipe for all three platforms:
[docs/DEVELOPING.md](https://github.com/samusfacepalm/MinUI-Amber/blob/main/docs/DEVELOPING.md).

---

## Disclaimer

THIS IS FREE SOFTWARE. I am not responsible if your house burns down, your wife leaves you, or your handheld decides to run away and join the circus as a result of you installing this software.

All included software is still covered under its original licenses.

---

## Credits

- **Shaun Inman (shauninman)** — MinUI, retro handheld frontend Jesus himself — https://github.com/shauninman/MinUI
- **NextUI** — updated Files.pak for the RG351V and improved binaries — https://github.com/ryanmsartor/NextUI
- **Turro75** — MyMinUI, original RK3326 port which this is partially based on — https://github.com/Turro75/MyMinUI
- **Frysee** — help with the Retro Pixel Pocket port

MinUI Amber port by MinUI Installer
Built on AmberELEC — https://amberelec.org
