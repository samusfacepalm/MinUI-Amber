# Bugfix release v0.2

**All devices:**

Boot time is now much faster.

Portmaster support added - tested with AM2R, other games should work. Portmaster comes by default.

Shutdown is now much faster and works properly.

Audio issues fixed.

Clock works

CPU speed control fixed - games can now clock up.

**RG351V**

Analogue stick fixed and now works perfectly.

**RPP**

Brightness wheel now works.

**V90S**

Initial support. Port of opportunity.

---

Install instructions remain the same for the 351V and RPP.

To install on the V90S - MinUI runs over the top of Knulli. This is because stock isn't that good, and also I had Knulli on the card I was using. If you don't have Knulli, flash your card with it, then extract files to /roms/, execute 'Enable MinUI Amber' in PORTS, which will run the script and set up MinUI Amber for all further boots.

**Updating from an earlier version:** extract the new release over the top of
your existing MinUIAmber folder, then run **Enable MinUI Amber** from PORTS
again to pick up the new start script. Your ROMs, saves and settings are left
alone.

---

| Download | Device |
|---|---|
| `MinUIAmber-v0.2-rg351v.zip` | Anbernic RG351V |
| `MinUIAmber-v0.2-rpp.zip` | Retro Pixel Pocket |
| `MinUIAmber-v0.2-v90s.zip` | Powkiddy V90S |
| `MinUIAmber-v0.2-pico8-native-addon.zip` | optional, RPP — needs your own PICO-8 |

Checksums in `SHA256SUMS.txt`. Full documentation, ROM folders and known issues in `README.md` inside each zip.
