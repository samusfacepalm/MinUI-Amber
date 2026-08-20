# MinUI Amber v0.2
### A port of MinUI for AmberELEC on RK3326 devices, and KNULLI on the V90S

MinUI Amber is more or less intended to be a straight port in the spirit of the original MinUI. Simple UI, simple SD card, a frontend that is designed to get the hell out of your way so you can play games.

This means no boxart, no whizbang super duper high-falutin' handhelds that do your taxes in a KDE desktop environment.

However, unlike original MinUI, this is designed to work with a single SD card. Two SD card setups on the RG351V have not been tested, and the RPP only has a single slot anyway — and you could fit the entire library of games you'd want to play on these devices on a single card anyway.

If you want those features — it's only a tool away. MinUI Amber comes with Return to EmulationStation, where you can use the full AmberELEC environment. The device will still boot into MinUI next boot.

MinUI Amber runs on top of AmberELEC. It runs over the top of KNULLI on the V90S. It does not replace your firmware. You can return to EmulationStation at any time.

---

## Supported Devices

| Device | Status |
|--------|--------|
| Anbernic RG351V | ✅ Supported |
| Retro Pixel Pocket (RPP) | ✅ Supported |
| Powkiddy V90S (KNULLI) | ✅ Supported |

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

MinUI Amber is switched on and off from EmulationStation's **Ports** menu. This is the same install path on every supported device.

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

---

## Your ROMs

Place your ROMs in the matching folder inside `MinUIAmber/Roms/`:

| Folder | System |
|--------|--------|
| `Famicom (NES)` | NES and Famicom Disk System |
| `Game Boy Color (GBC)` | Game Boy and Game Boy Color |
| `Game Boy Advance (MGBA)` | Game Boy Advance (MGBA) |
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
| `Playstation`| PS1 |
| `Portmaster` | Portmaster |

Please note MinUI Amber does not include GPSP or Gambatte. MGBA is used for all Gameboy emulation.

> The name in parentheses must match the pak name in `Emus/` exactly — that's how MinUI picks the emulator. The text before the parentheses is what shows in the menu, so name that part whatever you like.

Native PICO-8 is available separately. Splore requires your own PICO-8 binaries in the BIOS folder. Replace fake-08 with native PICO-8.

Playstation is not included on the Retro Pixel Pocket as it does not have L2 or R2 available.

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

- You will see the original boot logo before MinUI starts. This is normal — AmberELEC boots first, then hands off to MinUI.

- This version differs from stock MinUI in its Game Boy handling. MGBA is used for all Game Boy systems. This lets you do things like run Super Game Boy Colour mode in GBC games, have better palette access, and so on. SGB is still included separately for games you want to play with borders, games that are specifically SGB enhanced, hacks, or if you want to lose the use of your eyes gazing upon the beauty of Metroid 2's built-in palette on the SGB.

- **[RPP]** Controls can occasionally stop responding when the device goes into standby until the power switch is briefly slid. 


---

## FAQ

**Q: I see the WiFi icon!**
A: MinUI Amber runs on top of AmberELEC and KNULLI so it inherits your network settings. You will need to configure WiFi in AmberELEC/KNULLI first if you want it.

**Q: Can I still use EmulationStation?**
A: Yes. Run "Return to EmulationStation" from MinUI Tools at any time — that is a one-off trip, and the next boot goes back to MinUI. To make ES your default again for good, run **Ports → Disable MinUI Amber** from EmulationStation.

**Q: Will my saves and settings be affected?**
A: No. MinUI Amber stores its data in `/storage/roms/MinUIAmber/` and does not touch your AmberELEC configuration.

**Q: Native Pico-8??**
A: Available as a separate add-on. You supply your own PICO-8 binaries — I'm not shipping software I'd have to pirate to give you. Drop them in the BIOS folder and Splore works. Fake-08 is still included and still the default. The add-on was built and tested on the Retro Pixel Pocket; there's no reason a PICO-8 Native pak compiled for the RK3326 shouldn't work elsewhere, but it hasn't been tried.

**Q: It stinks, it stinks, it stinks!**
A: Yes Mr Sherman, everything stinks. No, seriously, this is the first time I've ever done anything like this. Please let me know if it does stink.

---

## Changelog

### v0.2

**All devices**
- Boot time is now much faster.
- PortMaster support added — tested with AM2R, other games should work. PortMaster comes by default.
- Shutdown is now much faster and works properly.
- Audio issues fixed.
- Clock works.
- CPU speed control fixed — games can now clock up.

**RG351V**
- Analogue stick fixed and now works perfectly.

**RPP**
- Brightness wheel now works.

**V90S**
- Initial support. Port of opportunity. No issues in my limited testing.

### v0.1
- Initial release.

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
Built on KNULLI - Knulli.org
