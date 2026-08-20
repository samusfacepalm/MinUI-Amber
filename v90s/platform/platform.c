// v90s (Powkiddy V90S, Allwinner A133P, KNULLI/Batocera)
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <linux/fb.h>
#include <sys/ioctl.h>
#include <sys/mman.h>

#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

#include <msettings.h>

#include "defines.h"
#include "platform.h"
#include "api.h"
#include "utils.h"

#include "scaler.h"

///////////////////////////////

// Raw evdev codes for the Powkiddy V90S.
//
// Gamepad codes come from KNULLI's es_input.cfg entry
// "Powkiddy V90s Controller" (GUID 19000000330100009011000000000000).
// Note these differ from the RG351V: X/Y are 307/308 (not 306/307) and
// L1/R1 are 310/311 (not 308/309).
#define RAW_A		304
#define RAW_B		305
#define RAW_X		307
#define RAW_Y		308
#define RAW_L1		310
#define RAW_R1		311
#define RAW_L2		312
#define RAW_R2		313
#define RAW_SELECT	314
#define RAW_START	315
// The V90S has no dedicated MENU button; es_input.cfg assigns the
// "hotkey" role to code 316, and that is the key MinUI uses as MENU.
#define RAW_MENU	316

// The d-pad reports as ABS_HAT0X/ABS_HAT0Y, not as key events
// (es_input.cfg: type="hat" id="0"). There is no analog stick.
#define RAW_HATX	0x10 // ABS_HAT0X
#define RAW_HATY	0x11 // ABS_HAT0Y

// Volume rocker is on the Allwinner LRADC ("keyboard" node in
// v90s_kernel.dts): key_cnt=2, key0=<0x2d0 0x73>, key1=<0x438 0x72>
// i.e. KEY_VOLUMEUP (115) and KEY_VOLUMEDOWN (114).
#define RAW_PLUS	115
#define RAW_MINUS	114

// Power key is the AXP2202 PMIC PEK (x-powers,axp2101-pek), KEY_POWER.
#define RAW_POWER	116

// Open every evdev node rather than hardcoding event numbers. The A133P
// BSP enumerates the gamepad, LRADC and PMIC nodes in an order that is
// not stable across boots (USB gamepad probe timing), and guessing wrong
// is how the RG351V port lost input for a whole round.
#define INPUT_COUNT 16
static int inputs[INPUT_COUNT];
static int input_count = 0;

void PLAT_initInput(void) {
	input_count = 0;

	DIR* dir = opendir("/dev/input");
	if (dir) {
		struct dirent* entry;
		while ((entry=readdir(dir)) && input_count<INPUT_COUNT) {
			if (strncmp(entry->d_name, "event", 5)!=0) continue;

			char path[64];
			snprintf(path, sizeof(path), "/dev/input/%s", entry->d_name);
			int fd = open(path, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
			if (fd>=0) inputs[input_count++] = fd;
		}
		closedir(dir);
	}

	LOG_info("opened %i input device(s)\n", input_count);
}
void PLAT_quitInput(void) {
	for (int i=0; i<input_count; i++) {
		close(inputs[i]);
	}
	input_count = 0;
}

// from <linux/input.h> which has BTN_ constants that conflict with platform.h
struct input_event {
	struct timeval time;
	__u16 type;
	__u16 code;
	__s32 value;
};
#define EV_KEY			0x01
#define EV_ABS			0x03

void PLAT_pollInput(void) {
	// reset transient state
	pad.just_pressed = BTN_NONE;
	pad.just_released = BTN_NONE;
	pad.just_repeated = BTN_NONE;

	uint32_t tick = SDL_GetTicks();
	for (int i=0; i<BTN_ID_COUNT; i++) {
		int btn = 1 << i;
		if ((pad.is_pressed & btn) && (tick>=pad.repeat_at[i])) {
			pad.just_repeated |= btn; // set
			pad.repeat_at[i] += PAD_REPEAT_INTERVAL;
		}
	}

	// the actual poll
	int input;
	static struct input_event event;
	for (int i=0; i<input_count; i++) {
		input = inputs[i];
		while (read(input, &event, sizeof(event))==sizeof(event)) {
			if (event.type!=EV_KEY && event.type!=EV_ABS) continue;

			int btn = BTN_NONE;
			int pressed = 0; // 0=up,1=down
			int id = -1;
			int type = event.type;
			int code = event.code;
			int value = event.value;

			if (type==EV_KEY) {
				if (value>1) continue; // ignore repeats
				pressed = value;
				     if (code==RAW_A)      { btn = BTN_A;      id = BTN_ID_A; }
				else if (code==RAW_B)      { btn = BTN_B;      id = BTN_ID_B; }
				else if (code==RAW_X)      { btn = BTN_X;      id = BTN_ID_X; }
				else if (code==RAW_Y)      { btn = BTN_Y;      id = BTN_ID_Y; }
				else if (code==RAW_L1)     { btn = BTN_L1;     id = BTN_ID_L1; }
				else if (code==RAW_R1)     { btn = BTN_R1;     id = BTN_ID_R1; }
				else if (code==RAW_L2)     { btn = BTN_L2;     id = BTN_ID_L2; }
				else if (code==RAW_R2)     { btn = BTN_R2;     id = BTN_ID_R2; }
				else if (code==RAW_START)  { btn = BTN_START;  id = BTN_ID_START; }
				else if (code==RAW_SELECT) { btn = BTN_SELECT; id = BTN_ID_SELECT; }
				else if (code==RAW_MENU)   { btn = BTN_MENU;   id = BTN_ID_MENU; }
				else if (code==RAW_POWER)  { btn = BTN_POWER;  id = BTN_ID_POWER; }
				else if (code==RAW_PLUS)   { btn = BTN_PLUS;   id = BTN_ID_PLUS; }
				else if (code==RAW_MINUS)  { btn = BTN_MINUS;  id = BTN_ID_MINUS; }
				else { btn = BTN_NONE; }
			}
			else if (type==EV_ABS) {
				if (code==RAW_HATX) {
					     if (value<0) { btn = BTN_DPAD_LEFT;  id = BTN_ID_DPAD_LEFT;  pressed = 1; }
					else if (value>0) { btn = BTN_DPAD_RIGHT; id = BTN_ID_DPAD_RIGHT; pressed = 1; }
					else {
						pad.is_pressed		&= ~(BTN_DPAD_LEFT | BTN_DPAD_RIGHT);
						pad.just_released	|=  (BTN_DPAD_LEFT | BTN_DPAD_RIGHT);
						pad.just_repeated	&= ~(BTN_DPAD_LEFT | BTN_DPAD_RIGHT);
						continue;
					}
				}
				else if (code==RAW_HATY) {
					     if (value<0) { btn = BTN_DPAD_UP;   id = BTN_ID_DPAD_UP;   pressed = 1; }
					else if (value>0) { btn = BTN_DPAD_DOWN; id = BTN_ID_DPAD_DOWN; pressed = 1; }
					else {
						pad.is_pressed		&= ~(BTN_DPAD_UP | BTN_DPAD_DOWN);
						pad.just_released	|=  (BTN_DPAD_UP | BTN_DPAD_DOWN);
						pad.just_repeated	&= ~(BTN_DPAD_UP | BTN_DPAD_DOWN);
						continue;
					}
				}
				else { btn = BTN_NONE; }
			}

			if (btn==BTN_NONE) continue;

			if (!pressed) {
				pad.is_pressed		&= ~btn; // unset
				pad.just_repeated	&= ~btn; // unset
				pad.just_released	|= btn; // set
			}
			else if ((pad.is_pressed & btn)==BTN_NONE) {
				pad.just_pressed	|= btn; // set
				pad.just_repeated	|= btn; // set
				pad.is_pressed		|= btn; // set
				pad.repeat_at[id]	= tick + PAD_REPEAT_DELAY;
			}
		}
	}
}

int PLAT_shouldWake(void) {
	int input;
	static struct input_event event;
	for (int i=0; i<input_count; i++) {
		input = inputs[i];
		while (read(input, &event, sizeof(event))==sizeof(event)) {
			if (event.type==EV_KEY && event.code==RAW_POWER && event.value==0) return 1;
		}
	}
	return 0;
}

///////////////////////////////

// based on rg35xxplus / rg351v
//
// KNULLI's SDL2 (2.30.12) exposes only the vendor "Mali EGL Video Driver"
// backend — no KMSDRM, no fbdev, no X11. That's fine: everything below is
// plain SDL_Window + SDL_Renderer, no direct framebuffer access.

static struct VID_Context {
	SDL_Window* window;
	SDL_Renderer* renderer;
	SDL_Texture* texture;
	SDL_Texture* target;
	SDL_Texture* effect;

	SDL_Surface* buffer;
	SDL_Surface* screen;

	GFX_Renderer* blit; // yeesh

	int width;
	int height;
	int pitch;
	int sharpness;
} vid;

static int device_width;
static int device_height;
static int device_pitch;
SDL_Surface* PLAT_initVideo(void) {
	SDL_InitSubSystem(SDL_INIT_VIDEO);
	SDL_ShowCursor(0);

	LOG_info("current video driver: %s\n", SDL_GetCurrentVideoDriver());

	int w = FIXED_WIDTH;
	int h = FIXED_HEIGHT;
	int p = FIXED_PITCH;
	vid.window   = SDL_CreateWindow("", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, w,h, SDL_WINDOW_SHOWN);
	LOG_info("window size: %ix%i\n", w,h);

	vid.renderer = SDL_CreateRenderer(vid.window,-1,SDL_RENDERER_ACCELERATED|SDL_RENDERER_PRESENTVSYNC);
	if (!vid.renderer) {
		// the mali backend has exactly one accelerated renderer; if it
		// refuses, fall back rather than dying with a NULL renderer
		LOG_info("accelerated renderer failed (%s), falling back\n", SDL_GetError());
		vid.renderer = SDL_CreateRenderer(vid.window,-1,0);
	}

	int renderer_width,renderer_height;
	SDL_GetRendererOutputSize(vid.renderer, &renderer_width, &renderer_height);
	LOG_info("output size: %ix%i\n", renderer_width, renderer_height);

	SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY,"1"); // linear
	vid.texture = SDL_CreateTexture(vid.renderer,SDL_PIXELFORMAT_RGB565, SDL_TEXTUREACCESS_STREAMING, w,h);
	vid.target	= NULL; // only needed for non-native sizes

	vid.buffer	= SDL_CreateRGBSurfaceFrom(NULL, w,h, FIXED_DEPTH, p, RGBA_MASK_565);
	vid.screen	= SDL_CreateRGBSurface(SDL_SWSURFACE, w,h, FIXED_DEPTH, RGBA_MASK_565);
	vid.width	= w;
	vid.height	= h;
	vid.pitch	= p;

	device_width	= w;
	device_height	= h;
	device_pitch	= p;

	vid.sharpness = SHARPNESS_SOFT;

	return vid.screen;
}

static void clearVideo(void) {
	SDL_FillRect(vid.screen, NULL, 0);
	for (int i=0; i<3; i++) {
		SDL_RenderClear(vid.renderer);
		SDL_RenderPresent(vid.renderer);
	}
}

void PLAT_quitVideo(void) {
	SDL_FreeSurface(vid.screen);
	SDL_FreeSurface(vid.buffer);
	if (vid.target) SDL_DestroyTexture(vid.target);
	if (vid.effect) SDL_DestroyTexture(vid.effect);
	SDL_DestroyTexture(vid.texture);
	SDL_DestroyRenderer(vid.renderer);
	SDL_DestroyWindow(vid.window);

	SDL_Quit();
}

void PLAT_clearVideo(SDL_Surface* screen) {
	SDL_FillRect(screen, NULL, 0);
}
void PLAT_clearAll(void) {
	PLAT_clearVideo(vid.screen);
	SDL_RenderClear(vid.renderer);
}

void PLAT_setVsync(int vsync) {
	// buh
}

static int hard_scale = 4; // TODO: base src size, eg. 160x144 can be 4

static void resizeVideo(int w, int h, int p) {
	if (w==vid.width && h==vid.height && p==vid.pitch) return;

	if (w>=device_width && h>=device_height) hard_scale = 1;
	else if (h>=160) hard_scale = 2; // limits gba and up to 2x (seems sufficient)
	else hard_scale = 4;

	LOG_info("resizeVideo(%i,%i,%i) hard_scale: %i crisp: %i\n",w,h,p, hard_scale,vid.sharpness==SHARPNESS_CRISP);

	SDL_FreeSurface(vid.buffer);
	SDL_DestroyTexture(vid.texture);
	if (vid.target) SDL_DestroyTexture(vid.target);

	SDL_SetHintWithPriority(SDL_HINT_RENDER_SCALE_QUALITY, vid.sharpness==SHARPNESS_SOFT?"1":"0", SDL_HINT_OVERRIDE);
	vid.texture = SDL_CreateTexture(vid.renderer,SDL_PIXELFORMAT_RGB565, SDL_TEXTUREACCESS_STREAMING, w,h);

	if (vid.sharpness==SHARPNESS_CRISP) {
		SDL_SetHintWithPriority(SDL_HINT_RENDER_SCALE_QUALITY, "1", SDL_HINT_OVERRIDE);
		vid.target = SDL_CreateTexture(vid.renderer,SDL_PIXELFORMAT_RGB565, SDL_TEXTUREACCESS_TARGET, w * hard_scale,h * hard_scale);
	}
	else {
		vid.target = NULL;
	}

	vid.buffer	= SDL_CreateRGBSurfaceFrom(NULL, w,h, FIXED_DEPTH, p, RGBA_MASK_565);

	vid.width	= w;
	vid.height	= h;
	vid.pitch	= p;
}

SDL_Surface* PLAT_resizeVideo(int w, int h, int p) {
	resizeVideo(w,h,p);
	return vid.screen;
}

void PLAT_setVideoScaleClip(int x, int y, int width, int height) {
	// buh
}
void PLAT_setNearestNeighbor(int enabled) {
	// buh
}
void PLAT_setSharpness(int sharpness) {
	if (vid.sharpness==sharpness) return;
	int p = vid.pitch;
	vid.pitch = 0;
	vid.sharpness = sharpness;
	resizeVideo(vid.width,vid.height,p);
}

static struct FX_Context {
	int scale;
	int type;
	int color;
	int next_scale;
	int next_type;
	int next_color;
	int live_type;
} effect = {
	.scale = 1,
	.next_scale = 1,
	.type = EFFECT_NONE,
	.next_type = EFFECT_NONE,
	.live_type = EFFECT_NONE,
	.color = 0,
	.next_color = 0,
};
static void rgb565_to_rgb888(uint32_t rgb565, uint8_t *r, uint8_t *g, uint8_t *b) {
	uint8_t red = (rgb565 >> 11) & 0x1F;
	uint8_t green = (rgb565 >> 5) & 0x3F;
	uint8_t blue = rgb565 & 0x1F;

	*r = (red << 3) | (red >> 2);
	*g = (green << 2) | (green >> 4);
	*b = (blue << 3) | (blue >> 2);
}
static void updateEffect(void) {
	if (effect.next_scale==effect.scale && effect.next_type==effect.type && effect.next_color==effect.color) return; // unchanged

	int live_scale = effect.scale;
	int live_color = effect.color;
	effect.scale = effect.next_scale;
	effect.type = effect.next_type;
	effect.color = effect.next_color;

	if (effect.type==EFFECT_NONE) return; // disabled
	if (effect.type==effect.live_type && effect.scale==live_scale && effect.color==live_color) return; // already loaded

	char* effect_path;
	int opacity = 128; // 1 - 1/2 = 50%
	if (effect.type==EFFECT_LINE) {
		if (effect.scale<3) {
			effect_path = RES_PATH "/line-2.png";
		}
		else if (effect.scale<4) {
			effect_path = RES_PATH "/line-3.png";
		}
		else if (effect.scale<5) {
			effect_path = RES_PATH "/line-4.png";
		}
		else if (effect.scale<6) {
			effect_path = RES_PATH "/line-5.png";
		}
		else if (effect.scale<8) {
			effect_path = RES_PATH "/line-6.png";
		}
		else {
			effect_path = RES_PATH "/line-8.png";
		}
	}
	else if (effect.type==EFFECT_GRID) {
		if (effect.scale<3) {
			effect_path = RES_PATH "/grid-2.png";
			opacity = 64; // 1 - 3/4 = 25%
		}
		else if (effect.scale<4) {
			effect_path = RES_PATH "/grid-3.png";
			opacity = 112; // 1 - 5/9 = ~44%
		}
		else if (effect.scale<5) {
			effect_path = RES_PATH "/grid-4.png";
			opacity = 144; // 1 - 7/16 = ~56%
		}
		else if (effect.scale<6) {
			effect_path = RES_PATH "/grid-5.png";
			opacity = 160; // 1 - 9/25 = ~64%
		}
		else if (effect.scale<8) {
			effect_path = RES_PATH "/grid-6.png";
			opacity = 112; // 1 - 5/9 = ~44%
		}
		else if (effect.scale<11) {
			effect_path = RES_PATH "/grid-8.png";
			opacity = 144; // 1 - 7/16 = ~56%
		}
		else {
			effect_path = RES_PATH "/grid-11.png";
			opacity = 136; // 1 - 57/121 = ~52%
		}
	}
	else {
		return; // unknown effect, nothing to load
	}

	SDL_Surface* tmp = IMG_Load(effect_path);
	if (tmp) {
		if (effect.type==EFFECT_GRID) {
			if (effect.color) {
				uint8_t r,g,b;
				rgb565_to_rgb888(effect.color,&r,&g,&b);

				uint32_t* pixels = (uint32_t*)tmp->pixels;
				int width = tmp->w;
				int height = tmp->h;
				for (int y = 0; y < height; ++y) {
					for (int x = 0; x < width; ++x) {
						uint32_t pixel = pixels[y * width + x];
						uint8_t _,a;
						SDL_GetRGBA(pixel, tmp->format, &_, &_, &_, &a);
						if (a) pixels[y * width + x] = SDL_MapRGBA(tmp->format, r,g,b, a);
					}
				}
			}
		}

		if (vid.effect) SDL_DestroyTexture(vid.effect);
		vid.effect = SDL_CreateTextureFromSurface(vid.renderer, tmp);
		SDL_SetTextureAlphaMod(vid.effect, opacity);
		SDL_FreeSurface(tmp);
		effect.live_type = effect.type;
	}
}
void PLAT_setEffect(int next_type) {
	effect.next_type = next_type;
}
void PLAT_setEffectColor(int next_color) {
	effect.next_color = next_color;
}
void PLAT_vsync(int remaining) {
	if (remaining>0) SDL_Delay(remaining);
}

scaler_t PLAT_getScaler(GFX_Renderer* renderer) {
	effect.next_scale = renderer->scale;
	return scale1x1_c16;
}

void PLAT_blitRenderer(GFX_Renderer* renderer) {
	vid.blit = renderer;
	SDL_RenderClear(vid.renderer);
	resizeVideo(vid.blit->true_w,vid.blit->true_h,vid.blit->src_p);
}

void PLAT_flip(SDL_Surface* IGNORED, int ignored) {
	if (!vid.blit) {
		resizeVideo(device_width,device_height,FIXED_PITCH);
		SDL_UpdateTexture(vid.texture,NULL,vid.screen->pixels,vid.screen->pitch);
		SDL_RenderCopy(vid.renderer, vid.texture, NULL,NULL);
		SDL_RenderPresent(vid.renderer);
		return;
	}

	SDL_UpdateTexture(vid.texture,NULL,vid.blit->src,vid.blit->src_p);

	SDL_Texture* target = vid.texture;
	int x = vid.blit->src_x;
	int y = vid.blit->src_y;
	int w = vid.blit->src_w;
	int h = vid.blit->src_h;
	if (vid.sharpness==SHARPNESS_CRISP) {
		SDL_SetRenderTarget(vid.renderer,vid.target);
		SDL_RenderCopy(vid.renderer, vid.texture, NULL,NULL);
		SDL_SetRenderTarget(vid.renderer,NULL);
		x *= hard_scale;
		y *= hard_scale;
		w *= hard_scale;
		h *= hard_scale;
		target = vid.target;
	}

	SDL_Rect* src_rect = &(SDL_Rect){x,y,w,h};
	SDL_Rect* dst_rect = &(SDL_Rect){0,0,device_width,device_height};
	if (vid.blit->aspect==0) { // native or cropped
		int w = vid.blit->src_w * vid.blit->scale;
		int h = vid.blit->src_h * vid.blit->scale;
		int x = (device_width - w) / 2;
		int y = (device_height - h) / 2;
		dst_rect->x = x;
		dst_rect->y = y;
		dst_rect->w = w;
		dst_rect->h = h;
	}
	else if (vid.blit->aspect>0) { // aspect
		int h = device_height;
		int w = h * vid.blit->aspect;
		if (w>device_width) {
			double ratio = 1 / vid.blit->aspect;
			w = device_width;
			h = w * ratio;
		}
		int x = (device_width - w) / 2;
		int y = (device_height - h) / 2;
		dst_rect->x = x;
		dst_rect->y = y;
		dst_rect->w = w;
		dst_rect->h = h;
	}

	SDL_RenderCopy(vid.renderer, target, src_rect, dst_rect);

	updateEffect();
	if (vid.blit && effect.type!=EFFECT_NONE && vid.effect) {
		SDL_RenderCopy(vid.renderer, vid.effect, &(SDL_Rect){0,0,dst_rect->w,dst_rect->h},dst_rect);
	}

	SDL_RenderPresent(vid.renderer);
	vid.blit = NULL;
}

int PLAT_supportsOverscan(void) { return 1; }

///////////////////////////////

#define OVERLAY_WIDTH PILL_SIZE // unscaled
#define OVERLAY_HEIGHT PILL_SIZE // unscaled
#define OVERLAY_BPP 4
// 32, not 16: the mask below is ARGB8888 and SDL2 2.30 rejects the
// mismatched depth outright (the RG351V crash-loop had the same shape).
#define OVERLAY_DEPTH 32
#define OVERLAY_PITCH (OVERLAY_WIDTH * OVERLAY_BPP) // unscaled
#define OVERLAY_RGBA_MASK 0x00ff0000,0x0000ff00,0x000000ff,0xff000000 // ARGB
static struct OVL_Context {
	SDL_Surface* overlay;
} ovl;

SDL_Surface* PLAT_initOverlay(void) {
	ovl.overlay = SDL_CreateRGBSurface(SDL_SWSURFACE, SCALE2(OVERLAY_WIDTH,OVERLAY_HEIGHT),OVERLAY_DEPTH,OVERLAY_RGBA_MASK);
	return ovl.overlay;
}
void PLAT_quitOverlay(void) {
	if (ovl.overlay) SDL_FreeSurface(ovl.overlay);
}
void PLAT_enableOverlay(int enable) {

}

///////////////////////////////

// The AXP2202 PMIC registers its supplies under names we can't assume
// (axp2202-battery / battery / axp2202-usb / usb depending on BSP build),
// so resolve them once at first use by walking /sys/class/power_supply.
static char battery_capacity_path[128] = "";
static char charger_online_path[128] = "";

static void findPowerSupplies(void) {
	static int resolved = 0;
	if (resolved) return;
	resolved = 1;

	DIR* dir = opendir("/sys/class/power_supply");
	if (!dir) return;

	struct dirent* entry;
	while ((entry=readdir(dir))) {
		if (entry->d_name[0]=='.') continue;

		char path[128];

		// a supply exposing "capacity" is the battery
		if (!battery_capacity_path[0]) {
			snprintf(path, sizeof(path), "/sys/class/power_supply/%s/capacity", entry->d_name);
			if (access(path, R_OK)==0) {
				strcpy(battery_capacity_path, path);
				continue;
			}
		}

		// a supply exposing "online" that isn't the battery is the charger
		if (!charger_online_path[0]) {
			snprintf(path, sizeof(path), "/sys/class/power_supply/%s/capacity", entry->d_name);
			if (access(path, R_OK)==0) continue; // that's the battery

			snprintf(path, sizeof(path), "/sys/class/power_supply/%s/online", entry->d_name);
			if (access(path, R_OK)==0) strcpy(charger_online_path, path);
		}
	}
	closedir(dir);

	LOG_info("battery: %s\ncharger: %s\n",
		battery_capacity_path[0] ? battery_capacity_path : "(none)",
		charger_online_path[0]   ? charger_online_path   : "(none)");
}

static int online = 0;
void PLAT_getBatteryStatus(int* is_charging, int* charge) {
	findPowerSupplies();

	*is_charging = charger_online_path[0] ? getInt(charger_online_path) : 0;

	int i = battery_capacity_path[0] ? getInt(battery_capacity_path) : 100;
	// worry less about battery and more about the game you're playing
	     if (i>80) *charge = 100;
	else if (i>60) *charge =  80;
	else if (i>40) *charge =  60;
	else if (i>20) *charge =  40;
	else if (i>10) *charge =  20;
	else           *charge =  10;

	// The V90S has no wifi (powkiddy-v90s is absent from
	// BOARD_CAPABILITIES[wifi]) but read the node anyway so a USB dongle
	// or a future board revision reports correctly.
	char status[16];
	getFile("/sys/class/net/wlan0/operstate", status,16);
	online = prefixMatch("up", status);
}

void PLAT_enableBacklight(int enable) {
	// Backlight is PWM behind the sunxi /dev/disp ioctl interface, not a
	// sysfs backlight class node.
	//
	// Do NOT use `batocera-brightness dispoff/dispon` here. dispon restores
	// from /var/run/batocera-brightness, a percentage written by whoever
	// last called dispoff -- which may well be KNULLI's battery-saver
	// daemon, not us. The first build did use it, and every sleep/wake cycle
	// came back at 20% (raw 51) instead of the user's setting; the logs show
	// "Brightness set to: 0" followed by "Brightness set to: 51" each time.
	//
	// Re-apply MinUI's own stored level instead, so wake restores exactly
	// what the user set.
	if (enable) SetBrightness(GetBrightness());
	else        SetRawBrightness(0);
}

void PLAT_powerOff(void) {
	sleep(2);

	SetRawVolume(MUTE_VOLUME_RAW);
	PLAT_enableBacklight(0);
	SND_quit();
	VIB_quit();
	PWR_quit();
	GFX_quit();

	// Hand off to launch.sh, which syncs and calls `poweroff`. Doing it
	// here would race our own unmount of /userdata.
	system("touch /tmp/poweroff");
	exit(0);
}

///////////////////////////////

// A133P cpufreq. The BSP kernel carries its own OPP table rather than
// declaring one in the device tree, so read the available frequencies at
// runtime instead of hardcoding a guess.
//
// We cap via scaling_max_freq rather than scaling_setspeed: setspeed
// requires the userspace governor, and KNULLI ships schedutil
// (batocera.conf system.cpu.governor=schedutil). Capping the ceiling
// works under any governor and needs no launch.sh governor dance.

#define CPUFREQ_DIR "/sys/devices/system/cpu/cpufreq/policy0"
#define MAX_FREQS 32

static int freqs[MAX_FREQS];
static int freq_count = 0;

static void loadFreqs(void) {
	static int loaded = 0;
	if (loaded) return;
	loaded = 1;

	char buffer[512];
	getFile(CPUFREQ_DIR "/scaling_available_frequencies", buffer, sizeof(buffer));

	char* tok = strtok(buffer, " \t\n");
	while (tok && freq_count<MAX_FREQS) {
		int f = atoi(tok);
		if (f>0) freqs[freq_count++] = f;
		tok = strtok(NULL, " \t\n");
	}

	// the kernel usually lists ascending, but don't rely on it
	for (int i=0; i<freq_count; i++) {
		for (int j=i+1; j<freq_count; j++) {
			if (freqs[j]<freqs[i]) {
				int t = freqs[i]; freqs[i] = freqs[j]; freqs[j] = t;
			}
		}
	}

	LOG_info("cpufreq: %i step(s), %i - %i kHz\n",
		freq_count,
		freq_count ? freqs[0] : 0,
		freq_count ? freqs[freq_count-1] : 0);
}

void PLAT_setCPUSpeed(int speed) {
	loadFreqs();
	if (freq_count==0) return; // nothing we can do, leave the governor alone

	// Measured on the device: 8 steps, 408000 - 1800000 kHz. Index 0 (408MHz)
	// makes the menu sluggish, so idle sits one step up -- the RG351V build
	// settled on 600MHz for the same reason.
	int i;
	switch (speed) {
		case CPU_SPEED_MENU: 		i = (freq_count>1) ? 1 : 0; break;
		case CPU_SPEED_POWERSAVE:	i = freq_count / 3; break;
		case CPU_SPEED_NORMAL: 		i = (freq_count * 2) / 3; break;
		case CPU_SPEED_PERFORMANCE:	i = freq_count - 1; break;
		default:					i = freq_count - 1; break;
	}
	if (i<0) i = 0;
	if (i>=freq_count) i = freq_count - 1;

	putInt(CPUFREQ_DIR "/scaling_max_freq", freqs[i]);
}

void PLAT_setRumble(int strength) {
	// no rumble motor (powkiddy-v90s is absent from BOARD_CAPABILITIES[rumble])
}

int PLAT_pickSampleRate(int requested, int max) {
	// 48000, not the usual 44100: /etc/asound.conf pins the dmix slave to
	// "rate 48000" and PipeWire runs the graph at 48k, so capping at 44100
	// bought nothing but an extra resample on every buffer.
	return MIN(MIN(requested, max), 48000);
}

static char model[256];
char* PLAT_getModel(void) {
	char buffer[256];
	getFile("/proc/device-tree/model", buffer, 256);

	if (buffer[0]) strcpy(model, buffer);
	else strcpy(model, "V90S");

	return model;
}

int PLAT_isOnline(void) {
	return online;
}

int GetMute(void) { return 0; }
