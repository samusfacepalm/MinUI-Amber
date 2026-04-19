# MinUI Amber v0.1
### A port of MinUI for AmberELEC on RK3326 devices

MinUI Amber is more or less intended to be a straight port in the spirit of the original MinUI. Simple UI, simple SD card, a frontend that is designed to get the hell out of your way so you can play games.

This means no boxart, no Portmaster, no whizbang super duper high-falutin' handhelds that do your taxes in a KDE desktop environment.

However, unlike original MinUI, this is designed to work with a single SD card. Two SD card setups on the RG351V have not been tested, and the RPP only has a single slot anyway — and you could fit the entire library of games you'd want to play on these devices on a single card anyway.

If you want those features — it's only a tool away. MinUI Amber comes with Return to EmulationStation, where you can use the full AmberELEC environment. The device will still boot into MinUI next boot.

MinUI Amber runs on top of AmberELEC. It does not replace your firmware. You can return to EmulationStation at any time.

---

## Supported Devices

| Device | Status |
|--------|--------|
| Anbernic RG351V | ✅ Supported |
| Retro Pixel Pocket (RPP) | ✅ Supported |

### Planned Devices
- **Anbernic RG351M** — in progress (requires full platform port, 320x480 display differs from RG351V)
- **V90S** — planned (BatoCera)
- **Odroid Go Advance** — planned (hardware pending verification)

### Unofficial / May Work
MinUI Amber will most likely boot on any AmberELEC-compatible RK3326 device, with the exception of the RG552 (different SoC). However, inputs may be wrong and behaviour may be buggy. **Back up your AmberELEC configuration before trying.**

- Anbernic RG351M
- Anbernic RG351MP
- Anbernic RG351P

---

## Installation

1. Extract the zip. You will get a folder called `MinUIAmber/`.

2. Copy the `MinUIAmber/` folder to your SD card so it sits at:
   ```
   /storage/roms/MinUIAmber/
   ```

3. Copy `EnableMinUIAmber.pak` to:
   ```
   /storage/roms/tools/
   ```

4. Boot your device into EmulationStation as normal.

5. Go to **Tools** and run **Enable MinUI Amber**. The device will reboot into MinUI Amber automatically.

**To uninstall:** delete `/storage/.config/custom_start.sh` and reboot. You will return to EmulationStation.

---

## Your ROMs

Place your ROMs in the matching folder inside `MinUIAmber/Roms/`:

| Folder | System |
|--------|--------|
| `Famicom (NES)` | NES and Famicom Disk System |
| `Game Boy Color (GBC)` | Game Boy and Game Boy Color |
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
| `Super Nintendo Entertainment System (SNES)` | SNES |

If you already have ROMs set up in AmberELEC, a migration tool is available in MinUI Tools to move them to the correct folders automatically.

---

## Extras

The `Extras/` folder contains additional emulator paks for less common systems:

> Amstrad CPC, Atari 2600, Atari 7800, Atari Lynx, Commodore 64, Commodore Amiga, Doom (PRBOOM), Final Burn Neo, MSX, Sega 32X

To use extras, copy the relevant pak from `Extras/Emus/<platform>/` into `Emus/<platform>/`, and create a matching folder in `Roms/` if needed. Extras are unsupported — your mileage may vary.

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

- **[RG351V]** The analogue stick does not work. This is a known issue and is planned for a future release.

- You will occasionally see the original boot logo before MinUI starts. This is normal — AmberELEC boots first, then hands off to MinUI.

- The device may occasionally sleep instead of powering down, causing controls to stop responding. Hold the power button to force a reset (or push the RG351V reset button). This bug has been mostly squashed on the RG351V but it can still occur occasionally.

- If the device loses power unexpectedly while in a game, progress since your last save state will be lost. Use the in-game menu (Menu button) to save regularly.

- This version differs from stock MinUI in its Game Boy handling. MGBA is used for all Game Boy systems. This lets you do things like run Super Game Boy Colour mode in GBC games, have better palette access, and so on. SGB is still included separately for games you want to play with borders, games that are specifically SGB enhanced, hacks, or if you want to lose the use of your eyes gazing upon the beauty of Metroid 2's built-in palette on the SGB.

- **[RPP]** Controls may occasionally stop responding. This is a hardware bug on the Retro Pixel Pocket. Briefly sliding the power switch will restore input immediately.

- **[RPP]** Occasionally, MinUI will close but the screen will stay on. This is a weird hardware thing Funnyplaying have done where the shutdown command takes a minute or so before it runs. The device is off and your games are saved — it will turn off on its own after a minute or two. Yes, it's annoying.

---

## FAQ

**Q: I see the WiFi icon!**
A: MinUI Amber runs on top of AmberELEC, so it inherits your AmberELEC network settings. SSH is available using your AmberELEC credentials. You will need to configure WiFi in AmberELEC first if you want it.

Default SSH credentials:
- RG351V: `root` / `amberelec`
- RPP: `root` / `retropixel`

**Q: Can I still use EmulationStation?**
A: Yes. Run "Return to EmulationStation" from MinUI Tools at any time. To make ES your default again, delete `/storage/.config/custom_start.sh` and reboot.

**Q: Will my AmberELEC saves and settings be affected?**
A: No. MinUI Amber stores its data in `/storage/roms/MinUIAmber/` and does not touch your AmberELEC configuration.

**Q: Any changes from stock MinUI?**
A: Yes. MinUI Amber includes platform-specific fixes for AmberELEC:
- Audio output configured for hardware compatibility
- Button mappings adjusted for RG351V and RPP hardware
- Boot integration via AmberELEC's `custom_start.sh` hook
- Service masking for faster boot times

**Q: It takes ages to boot???**
A: I've done my best, but this is as fast as it will go. The time to boot is an AmberELEC thing, and unless I spent a month gutting it (at which point I would be better off porting MOSS to these devices), it ain't gonna happen.

**Q: It stinks, it stinks, it stinks!**
A: Yes Mr Sherman, everything stinks. No, seriously, this is the first time I've ever done anything like this. Please let me know if it does stink.

---

## Disclaimer

THIS IS FREE SOFTWARE. I am not responsible if your house burns down, your wife leaves you, or your handheld decides to join the circus as a result of you installing this software.

All included software is still covered under its original licenses.

---

## Credits

- **Shaun Inman (shauninman)** — MinUI, retro handheld frontend Jesus himself — https://github.com/shauninman/MinUI
- **NextUI** — updated Files.pak for the RG351V and improved binaries — https://github.com/ryanmsartor/NextUI
- **Turro75** — MyMinUI, original RK3326 port which this is partially based on — https://github.com/Turro75/MyMinUI
- **Frysee** — help with the Retro Pixel Pocket port

MinUI Amber port by MinUI Installer
Built on AmberELEC — https://amberelec.org
