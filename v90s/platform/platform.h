// v90s (Powkiddy V90S, Allwinner A133P, KNULLI/Batocera)

#ifndef PLATFORM_H
#define PLATFORM_H

///////////////////////////////

#include "sdl.h"

///////////////////////////////

#define BUTTON_UP		BUTTON_NA
#define BUTTON_DOWN		BUTTON_NA
#define BUTTON_LEFT		BUTTON_NA
#define BUTTON_RIGHT	BUTTON_NA

#define BUTTON_SELECT	BUTTON_NA
#define BUTTON_START	BUTTON_NA

#define BUTTON_A		BUTTON_NA
#define BUTTON_B		BUTTON_NA
#define BUTTON_X		BUTTON_NA
#define BUTTON_Y		BUTTON_NA

#define BUTTON_L1		BUTTON_NA
#define BUTTON_R1		BUTTON_NA
#define BUTTON_L2		BUTTON_NA
#define BUTTON_R2		BUTTON_NA
#define BUTTON_L3		BUTTON_NA
#define BUTTON_R3		BUTTON_NA

#define BUTTON_MENU		BUTTON_NA
#define BUTTON_MENU_ALT	BUTTON_NA
#define	BUTTON_POWER	SDLK_POWER
#define	BUTTON_PLUS		BUTTON_NA
#define	BUTTON_MINUS	BUTTON_NA

///////////////////////////////

#define CODE_UP			CODE_NA
#define CODE_DOWN		CODE_NA
#define CODE_LEFT		CODE_NA
#define CODE_RIGHT		CODE_NA

#define CODE_SELECT		CODE_NA
#define CODE_START		CODE_NA

#define CODE_A			CODE_NA
#define CODE_B			CODE_NA
#define CODE_X			CODE_NA
#define CODE_Y			CODE_NA

#define CODE_L1			CODE_NA
#define CODE_R1			CODE_NA
#define CODE_L2			CODE_NA
#define CODE_R2			CODE_NA
#define CODE_L3			CODE_NA
#define CODE_R3			CODE_NA

#define CODE_MENU		CODE_NA
#define CODE_MENU_ALT	CODE_NA
#define CODE_POWER		102 // SDL_SCANCODE_POWER

#define CODE_PLUS		128 // SDL_SCANCODE_VOLUMEUP
#define CODE_MINUS		129 // SDL_SCANCODE_VOLUMEDOWN

///////////////////////////////
// SDL joystick indices, from KNULLI es_input.cfg
//   <inputConfig deviceName="Powkiddy V90s Controller"
//                deviceGUID="19000000330100009011000000000000">
// The d-pad is a HAT (id 0), not buttons, so JOY_UP/DOWN/LEFT/RIGHT are N/A.
// There is no analog stick on this device (see S02generate-capability:
// powkiddy-v90s is absent from BOARD_CAPABILITIES[analogstick]).

#define JOY_UP			JOY_NA
#define JOY_DOWN		JOY_NA
#define JOY_LEFT		JOY_NA
#define JOY_RIGHT		JOY_NA

#define JOY_SELECT		8
#define JOY_START		9

#define JOY_A			0
#define JOY_B			1
#define JOY_X			2
#define JOY_Y			3

#define JOY_L1			4
#define JOY_R1			5
#define JOY_L2			6
#define JOY_R2			7
#define JOY_L3			JOY_NA
#define JOY_R3			JOY_NA

#define JOY_MENU		10 // "hotkey", raw code 316
#define JOY_MENU_ALT	JOY_NA
#define JOY_POWER		JOY_NA
#define JOY_PLUS		JOY_NA
#define JOY_MINUS		JOY_NA

///////////////////////////////

#define BTN_RESUME			BTN_X
#define BTN_SLEEP 			BTN_POWER
#define BTN_WAKE 			BTN_POWER
#define BTN_MOD_VOLUME 		BTN_NONE
#define BTN_MOD_BRIGHTNESS 	BTN_MENU
#define BTN_MOD_PLUS 		BTN_PLUS
#define BTN_MOD_MINUS 		BTN_MINUS

///////////////////////////////
// Panel is 640x480, straight from the device tree:
//   v90s_kernel.dts lcd0: lcd_x = <0x280>; lcd_y = <0x1e0>;

#define FIXED_SCALE		2
#define FIXED_WIDTH		640
#define FIXED_HEIGHT	480
#define FIXED_BPP		2
#define FIXED_DEPTH		(FIXED_BPP * 8)
#define FIXED_PITCH		(FIXED_WIDTH * FIXED_BPP)
#define FIXED_SIZE		(FIXED_PITCH * FIXED_HEIGHT)

// No HDMI on this board (powkiddy-v90s is not in BOARD_CAPABILITIES[hdmi]),
// so deliberately do NOT define HAS_HDMI or the HDMI_* geometry. defines.h
// then aliases HDMI_* to FIXED_*, which is what makes minarch fold
// SCALE_CROPPED into SCALE_NATIVE on a display that can't change mode.

///////////////////////////////

#define MAIN_ROW_COUNT 6
#define PADDING 10

///////////////////////////////

// KNULLI userdata partition; survives OS updates (which replace the
// read-only squashfs rootfs wholesale).
#define SDCARD_PATH "/userdata/roms/MinUIAmber"
#define MUTE_VOLUME_RAW 0
#define SAMPLES 400

///////////////////////////////

#endif
