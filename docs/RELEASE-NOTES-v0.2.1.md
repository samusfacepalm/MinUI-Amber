# Bugfix release v0.2.1

A scripts-and-settings update: the menu, emulator and core binaries are the same ones v0.2 shipped. The code fixes in the source (build flags for the RG351V/RPP CPU, CPU speeds snapped to what the board offers, the in-game Power hint reading SLEEP again) need a toolchain rebuild and will ship with the next full build.

**All devices:**

PlayStation L2 and R2 now work — before, they couldn't even be mapped.

Return to EmulationStation no longer leaves MinUI's volume and brightness keys running underneath ES.

Rom folders now match the README: Game Boy Advance (MGBA), Playstation (PS), Portmaster (PORTS).

**RG351V and RPP**

Disable MinUI Amber gives AmberELEC its suspend back. v0.2 switched it off for good; the first boot of this version clears that up.

Return to EmulationStation brings back suspend, the power button and the services you had turned on (Samba, the web UI and so on).

ROMs with double spaces in their names now launch.

**RPP**

Files now uses the whole 720x720 screen.

**V90S**

Disable MinUI Amber no longer boots to a black screen when the optional boot-custom.sh is installed.

Ports, PortMaster, and EmulationStation after Return to EmulationStation, no longer run at the menu's CPU speed.

---

**Updating from v0.2:**

1. Extract the new zip over the top of your existing MinUIAmber folder.
2. V90S with boot-custom.sh: copy the new boot-custom.sh over the old one on the BATOCERA partition.
3. Boot, go to Tools → Return to EmulationStation, and run **Enable MinUI Amber** from PORTS again.

Your ROMs, saves and settings are left alone.

**Rom folders when updating:** extracting over v0.2 adds the new folder names next to your old ones rather than renaming them, and your old folders keep working. The simplest thing is to leave them be.

- Game Boy Advance (GBA) keeps running on the v0.2 pak, and its saves live in `Saves/GBA`. If you move those games to Game Boy Advance (MGBA), move `Saves/GBA` to `Saves/MGBA` along with them.
- The new Playstation (PS) and Game Boy Advance (MGBA) folders are empty, and MinUI hides empty folders.
- You'll see both "Ports" and "Portmaster" in the menu. Move anything you added to Ports (PORTS) into Portmaster (PORTS), then delete Ports (PORTS).

---

| Download | Device |
|---|---|
| `MinUIAmber-v0.2.1-rg351v.zip` | Anbernic RG351V |
| `MinUIAmber-v0.2.1-rpp.zip` | Retro Pixel Pocket |
| `MinUIAmber-v0.2.1-v90s.zip` | Powkiddy V90S |
| `MinUIAmber-v0.2.1-pico8-native-addon.zip` | optional, RPP — needs your own PICO-8 (unchanged from v0.2) |

Checksums in `SHA256SUMS.txt`. Full documentation, ROM folders and known issues in `README.md` inside each zip.
