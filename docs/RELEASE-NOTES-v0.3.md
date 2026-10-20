# MinUI Amber v0.3

**New device: YMC A10 Mini**

Initial support for the YMC A10 Mini, on the ArkOS4Clone firmware it ships with.

There is one A10 Mini download, and it is the right one for every version: v1, v2 and V4. It works out which screen you have when it starts, so there's no wrong zip to pick.

- The screen now runs at 60 Hz, so games run at the right speed without crackle. Out of the box it's 57.7 Hz (61.7 on the V4).
- Sega Genesis and WonderSwan added.
- Display Fix in Tools, for the screens that look dark head on.
- A press of the power button turns it off.
- Install, disable and uninstall all live in the Ports menu. See INSTALL.txt in the zip.

Tested on a v1. The V4 should work, but nobody has tried one yet. Let me know if it doesn't.

**V90S**

Disable MinUI Amber no longer boots to a black screen when the optional boot-custom.sh is installed.

Ports, PortMaster, and EmulationStation after Return to EmulationStation, no longer run at the menu's CPU speed.

**All devices**

PlayStation L2 and R2 now work. Before, they couldn't even be mapped.

Return to EmulationStation no longer leaves MinUI's volume and brightness keys running underneath ES.

**RG351V and RPP**

Disable MinUI Amber gives AmberELEC its suspend back. v0.2 switched it off for good; the first boot of this version clears that up.

Return to EmulationStation brings back suspend, the power button and the services you had turned on (Samba, the web UI and so on).

ROMs with double spaces in their names now launch.

**RPP**

Files now uses the whole 720x720 screen.

---

**Updating from v0.2:**

1. Extract the new zip over the top of your existing MinUIAmber folder.
2. V90S with boot-custom.sh: copy the new boot-custom.sh over the old one on the BATOCERA partition.
3. Boot, go to Tools → Return to EmulationStation, and run **Enable MinUI Amber** from PORTS again.

Your ROMs, saves and settings are left alone.

**Rom folders when updating:** extracting over v0.2 adds the new folder names next to your old ones rather than renaming them, and your old folders keep working.

- Game Boy Advance (GBA) keeps running on the v0.2 pak, and its saves live in `Saves/GBA`. If you move those games to Game Boy Advance (MGBA), move `Saves/GBA` to `Saves/MGBA` along with them.
- You'll see both "Ports" and "Portmaster" in the menu. Move anything you added to Ports (PORTS) into Portmaster (PORTS), then delete Ports (PORTS).

---

| Download | Device |
|---|---|
| `MinUIAmber-v0.3-a10mini.zip` | YMC A10 Mini: v1, v2 and V4 |
| `MinUIAmber-v0.3-rg351v.zip` | Anbernic RG351V |
| `MinUIAmber-v0.3-rpp.zip` | Retro Pixel Pocket |
| `MinUIAmber-v0.3-v90s.zip` | Powkiddy V90S |
| `MinUIAmber-v0.2-pico8-native-addon.zip` | optional, RPP — needs your own PICO-8 (unchanged from v0.2) |

Checksums in `SHA256SUMS.txt`. Full documentation, ROM folders and known issues in `README.md` inside each zip.
