// v90s (Powkiddy V90S, Allwinner A133P, KNULLI/Batocera)
//
// Two things differ from the RG351V/AmberELEC build:
//
//   brightness  the panel backlight is PWM behind the sunxi /dev/disp
//               ioctl interface, not a /sys/class/backlight node, so we
//               drive it through KNULLI's own `brightness` helper (0-255,
//               see v90s_kernel.dts lcd_pwm_max_limit = <0xff>)
//   volume      audio is PulseAudio, not a raw ALSA mixer, so volume is a
//               percentage via pactl rather than an amixer control value

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <linux/fb.h>
#include <errno.h>
#include <sys/stat.h>
#include <dlfcn.h>
#include <sys/ioctl.h>
#include <string.h>

#include "msettings.h"


void putFile(char* path, char* contents) {
	FILE* file = fopen(path, "w");
	if (file) {
		fputs(contents, file);
		fclose(file);
	}
}


void putInt(char* path, int value) {
	char buffer[8];
	sprintf(buffer, "%d", value);
	putFile(path, buffer);
}
///////////////////////////////////////

#define SETTINGS_VERSION 1
typedef struct Settings {
	int version; // future proofing
	int brightness;
	int headphones; // available?
	int speaker;
	int unused[2]; // for future use
	// NOTE: doesn't really need to be persisted but still needs to be shared
	int jack;
} Settings;
static Settings DefaultSettings = {
	.version = SETTINGS_VERSION,
	.brightness = 3,
	.headphones = 4,
	.speaker = 8,
	.jack = 0,
};
static Settings *settings;

#define SHM_KEY "/SharedSettings"
static char SettingsPath[256];
static int shm_fd = -1;
static int is_host = 0;
static int shm_size = sizeof(Settings);
static int preinitialized = 0;

void preInitSettings(void) {
	sprintf(SettingsPath, "%s/msettings.bin", getenv("USERDATA_PATH"));
	shm_fd = shm_open(SHM_KEY, O_RDWR | O_CREAT | O_EXCL, 0644); // see if it exists
	if (shm_fd==-1 && errno==EEXIST) { // already exists
		shm_fd = shm_open(SHM_KEY, O_RDWR, 0644);
		settings = mmap(NULL, shm_size, PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
	}
	else { // host
		is_host = 1;
		// we created it so set initial size and populate
		ftruncate(shm_fd, shm_size);
		settings = mmap(NULL, shm_size, PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);

		int fd = open(SettingsPath, O_RDONLY);
		if (fd>=0) {
			read(fd, settings, shm_size);
			close(fd);
		}
		else {
			// load defaults
			memcpy(settings, &DefaultSettings, shm_size);
		}
	}
	preinitialized = 1;
}
void InitSettings(void) {
	if (!preinitialized) preInitSettings();

	printf("brightness: %i \nspeaker: %i\n", settings->brightness, settings->speaker); fflush(stdout);

	SetVolume(GetVolume());
	SetBrightness(GetBrightness());
}
static inline void SaveSettings(void) {
	int fd = open(SettingsPath, O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (fd>=0) {
		write(fd, settings, shm_size);
		close(fd);
	}
}
void QuitSettings(void) {
	munmap(settings, shm_size);
	if (is_host) shm_unlink(SHM_KEY);
}

int GetBrightness(void) { // 0-10
	return settings->brightness;
}
void SetBrightness(int value) {
	if (value<0) value = 0;
	if (value>10) value = 10;
	settings->brightness = value;

	// 0-255 to match lcd_pwm_max_limit; KNULLI's own floor is 3, below
	// which the panel is indistinguishable from off
	static const int raw_levels[11] = { 3, 15, 30, 50, 75, 100, 130, 160, 190, 220, 255 };

	SetRawBrightness(raw_levels[value]);
	SaveSettings();
}

int GetVolume(void) { // 0-20
	return settings->jack ? settings->headphones : settings->speaker;
}
void SetVolume(int value) {
	if (settings->jack) settings->headphones = value;
	else settings->speaker = value;

	SetRawVolume(value);
	SaveSettings();
}

void SetRawBrightness(int val) { // 0-255
	char cmd[128];
	sprintf(cmd, "brightness set %d >/dev/null 2>&1", val);
	system(cmd);
}

long map(int x, int in_min, int in_max, int out_min, int out_max) {
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}
void SetRawVolume(int val) { // 0-20
	char cmd[256];
	int percent = map(val, 0, 20, 0, 100);
	if (percent<0) percent = 0;
	if (percent>100) percent = 100;

	// @DEFAULT_SINK@ rather than a fixed sink name: S31emulationstation
	// spins waiting for the default sink to come up because the A133
	// audio link settles late, so the sink index is not stable.
	sprintf(cmd, "pactl set-sink-volume @DEFAULT_SINK@ %d%% >/dev/null 2>&1", percent);
	system(cmd);
	printf("SetRawVolume(%i->%i%%)\n", val, percent); fflush(stdout);
}
// monitored and set by thread in keymon
int GetJack(void) {
	return settings->jack;
}
void SetJack(int value) {
	settings->jack = value;
	SetVolume(GetVolume());
}

int getInt(char* path) {
	int i = 0;
	FILE *file = fopen(path, "r");
	if (file!=NULL) {
		fscanf(file, "%i", &i);
		fclose(file);
	}
	return i;
}

// No HDMI on this board (powkiddy-v90s is absent from
// BOARD_CAPABILITIES[hdmi] in S02generate-capability).
int GetHDMI(void) { return 0; }
void SetHDMI(int value) { }

void SetMute(int mute) {
	char cmd[128];
	sprintf(cmd, "pactl set-sink-mute @DEFAULT_SINK@ %d >/dev/null 2>&1", mute ? 1 : 0);
	system(cmd);
}
