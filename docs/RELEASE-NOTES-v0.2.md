# MinUI Amber v0.2

Bugfix release, plus a third device.

| Package | Device | Firmware |
|---|---|---|
| `MinUIAmber-v0.2-rg351v.zip` | Anbernic RG351V | AmberELEC |
| `MinUIAmber-v0.2-rpp.zip` | Retro Pixel Pocket | AmberELEC |
| `MinUIAmber-v0.2-v90s.zip` | Powkiddy V90S | KNULLI |
| `MinUIAmber-v0.2-pico8-native-addon.zip` | optional add-on | RPP |

Verify downloads against `SHA256SUMS.txt`.

## All devices

- **Boot time is much faster.**
- **PortMaster support added.** Tested with AM2R; other games should work.
  PortMaster comes by default now, on every device.
- **Shutdown is much faster and works properly.**
- **Audio issues fixed.**
- **Clock works.**

## RG351V

- **Analogue stick fixed** — works perfectly now.

## Retro Pixel Pocket

- **Brightness wheel now works.**

## Powkiddy V90S

- **Initial support.** A port of opportunity.

## Installing

Install instructions are unchanged for the **351V and RPP**: copy `MinUIAmber/`
to `/storage/roms/`, merge `ports/` into `/storage/roms/ports/`, then run
**Enable MinUI Amber** from EmulationStation's PORTS menu. Full steps in each
zip's `INSTALL.txt`.

**V90S:** MinUI runs over the top of KNULLI. This is because stock isn't that
good, and because KNULLI was already on the card being used. If you don't have
KNULLI, flash your card with it first, then extract the files to `/roms/` (the
`roms` folder on the card's SHARE partition, i.e. `/userdata/roms`) and run
**Enable MinUI Amber** in PORTS. That runs the script and sets MinUI Amber up
for all further boots.

Uninstalling is **Disable MinUI Amber**, in the same PORTS menu, on all three.
Nothing is deleted, and it puts back everything enabling switched off.

## PICO-8 native add-on

Optional. Runs the real PICO-8, Splore included, instead of the fake-08 core in
the main release. **You supply your own PICO-8** — it's commercial software.
Built and tested on the RPP; the pak needs its controller GUID edited for the
other two. See the add-on's own README.

## Upgrading from v0.1.1

Copy the new `MinUIAmber/` over the old one and add the `ports/` contents.
Do **not** delete the old folder first — `MinUIAmber/Saves/` and, on the V90S,
`MinUIAmber/.userdata/` hold your saves and settings.

The install path moved from AmberELEC's Homebrew menu to the PORTS menu, so
after upgrading you can delete `/storage/roms/homebrew/EnableMinUIAmber.sh`.
If you had a V90S pre-release on the card, its ports entries were named
`Enable MinUIAmber.sh` / `Disable MinUIAmber.sh` — delete those two, or you'll
see each entry twice.

## What's in the box, licence-wise

No games. No BIOS images. No saves. `Roms/`, `Bios/`, `Saves/` and `Cheats/`
ship empty — you supply your own.

What is bundled is other people's free software: MinUI itself, NextUI's
Files.pak, libretro emulator cores (RG351V and RPP only), PortMaster 8.6.1,
and two font families. `THIRD-PARTY.md` in each zip lists all of it with
upstream links. A few of the bundled cores (MAME 2003-Plus, FinalBurn Neo,
Snes9x) carry non-commercial licences, so **MinUI Amber must not be sold** —
give it away, don't charge for it, don't put it on a card you sell.

The V90S build ships **no cores at all**; it uses KNULLI's own, which is why
that zip is a fifth the size of the other two.

## Known gaps

- PortMaster is bundled at version 8.6.1 straight from the PortMaster project.
  It was exercised with AM2R on the RG351V. The RPP and V90S ship the same
  payload but it hasn't been run on those devices yet.
- On KNULLI the PortMaster shim creates a `/roms` symlink to `/userdata/roms`,
  because PortMaster looks for its control folder there and KNULLI, unlike
  AmberELEC, doesn't ship that link.
- **[RPP]** Controls can still stop responding until the power switch is
  briefly slid. The RG351V fix for this isn't in the RPP build, whose launch
  script is deliberately kept close to the verified-working v0.1 original.
