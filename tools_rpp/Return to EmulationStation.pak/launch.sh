#!/bin/sh
systemctl unmask syncthing.service smbd.service nmbd.service webui.service avahi-daemon.service avahi-defaults.service lastgame.service wsdd2.service 2>/dev/null || true
rm -f /tmp/minui_exec
