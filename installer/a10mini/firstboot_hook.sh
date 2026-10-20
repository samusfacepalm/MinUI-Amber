
# >>> MinUIAmber boot hijack >>>
# firstboot.service is Type=oneshot with no timeout and
# emulationstation.service waits for it, so running MinUI here in the
# foreground means ES never starts while MinUI is up. Ports > Uninstall
# MinUI Amber removes this block; Ports > Disable MinUI Amber (or creating
# /roms/MinUIAmber/.disabled) skips it and boots ArkOS as normal.
MINUI_BOOT="/roms/MinUIAmber/.system/a10mini/boot.sh"
if [[ -f "$MINUI_BOOT" && ! -f /roms/MinUIAmber/.disabled ]]; then
  type msg >/dev/null 2>&1 && msg "MinUIAmber: hijacking boot"
  /bin/bash "$MINUI_BOOT"
  type msg >/dev/null 2>&1 && msg "MinUIAmber: returned, handing over to EmulationStation"
fi
# <<< MinUIAmber boot hijack <<<
