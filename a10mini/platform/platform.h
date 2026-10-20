// a10mini (YMC A10 Mini, Rockchip RK3326, ArkOS4Clone / Ubuntu 19.10)

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

// SDL joystick indices, from ArkOS's es_input.cfg for this board:
//   <inputConfig deviceName="GO-Super Gamepad"
//                deviceGUID="190000004b4800000011000000010000">
// The d-pad is four buttons (8-11), not a hat. There is no analog stick
// (odroidgo3-joypad node has amux-count = 0). Input is read from evdev
// directly (see platform.c) so these are reference only.

#define JOY_UP			8
#define JOY_DOWN		9
#define JOY_LEFT		10
#define JOY_RIGHT		11

#define JOY_SELECT		12
#define JOY_START		13

#define JOY_A			1
#define JOY_B			0
#define JOY_X			2
#define JOY_Y			3

#define JOY_L1			4
#define JOY_R1			5
#define JOY_L2			6
#define JOY_R2			7
#define JOY_L3			14
#define JOY_R3			15

#define JOY_MENU		16 // "F" button, raw code 708 (BTN_TRIGGER_HAPPY5)
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

// A press of POWER shuts the device down rather than sleeping it. Idle
// autosleep still just blanks the screen. (MinUIAmber policy on V90S and
// A10 Mini; RG351V/RPP builds still sleep.)
#define SLEEP_IS_POWEROFF	1

// Neither panel runs at exactly 60 Hz on its factory timing (v1/v2 57.72 Hz,
// V4 61.71 Hz), and the installer's 60 Hz fix may not be applied. api.c
// matches core audio to the measured refresh when vsync is on; see
// PLAT_displayHz.
#define HAS_DISPLAY_HZ		1
double PLAT_displayHz(void);

///////////////////////////////

// v1/v2 panel is 640x480; the V4 revision is 720x540 with the same board
// and pad. One build serves both: is_v4 comes from the panel mode, read at
// the top of PLAT_initVideo before anything sizes a surface (the same
// pattern as rg35xxplus's is_cubexx).
extern int is_v4;
#define FIXED_SCALE		2
#define FIXED_WIDTH		(is_v4?720:640)
#define FIXED_HEIGHT	(is_v4?540:480)
#define FIXED_BPP		2
#define FIXED_DEPTH		(FIXED_BPP * 8)
#define FIXED_PITCH		(FIXED_WIDTH * FIXED_BPP)
#define FIXED_SIZE		(FIXED_PITCH * FIXED_HEIGHT)

// No HDMI on this board, so deliberately do NOT define HAS_HDMI or the
// HDMI_* geometry. defines.h then aliases HDMI_* to FIXED_*, which is what
// makes minarch fold SCALE_CROPPED into SCALE_NATIVE on a display that
// can't change mode.

///////////////////////////////

#define MAIN_ROW_COUNT (is_v4?7:6) // 270 vs 240 logical lines
#define PADDING 10

///////////////////////////////

// ArkOS mounts the exFAT EASYROMS partition at /roms; everything of ours
// lives there so a stock reflash of the OS partition leaves it alone.
#define SDCARD_PATH "/roms/MinUIAmber"
#define MUTE_VOLUME_RAW 0
// 1024, not MinUI's usual 400: ArkOS's dmix layer runs 1024-frame periods, and
// feeding it 400-frame SDL periods left residual crackle even at 60Hz.
#define SAMPLES 1024

///////////////////////////////

#endif
