#!/bin/sh

EMU_EXE=puae2021

###############################

EMU_TAG=$(basename "$(dirname "$0")" .pak)
ROM="$1"
mkdir -p "$BIOS_PATH/$EMU_TAG"
mkdir -p "$SAVES_PATH/$EMU_TAG"
mkdir -p "$CHEATS_PATH/$EMU_TAG"
HOME="$USERDATA_PATH"
cd "$HOME"
CORE_SO="$CORES_PATH/${EMU_EXE}_libretro.so"; [ -f "$CORE_SO" ] || CORE_SO="$SYSTEM_PATH/cores/${EMU_EXE}_libretro.so"; minarch.elf "$CORE_SO" "$ROM" > "$LOGS_PATH/$EMU_TAG.txt" 2>&1
