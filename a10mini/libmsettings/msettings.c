// a10mini (YMC A10 Mini, Rockchip RK3326, ArkOS4Clone)
//
// Same shared-memory settings store as the other MinUIAmber platforms.
//   brightness  standard sysfs backlight class (pwm-backlight); scaled to
//               max_brightness at runtime since the DTB ceiling has changed
//               between clone firmware releases (102 -> 160)
//   volume      rk817 codec via ALSA, `amixer sset Playback N` raw 130-150 (3.75 dB/step)
//               (the control goes to 255 but clips well before that)
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <errno.h>
#include <sys/stat.h>
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

int getInt(char* path) {
	int i = 0;
	FILE *file = fopen(path, "r");
	if (file!=NULL) {
		fscanf(file, "%i", &i);
		fclose(file);
	}
	return i;
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
	.brightness = 5,
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
	else { // host, should always be keymon
		is_host = 1;
		ftruncate(shm_fd, shm_size);
		settings = mmap(NULL, shm_size, PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);

		int fd = open(SettingsPath, O_RDONLY);
		if (fd>=0) {
			read(fd, settings, shm_size);
			close(fd);
		}
		else {
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

	// Scale to whatever ceiling the DTB advertises: the June-2026 clone DTB
	// stops at 102 (0x66), lcdyk's current one at 160 (0xa0) -- the same
	// panel, 57% more backlight, and the difference between "too dark" and
	// fine. Level 0 stays faintly visible rather than blanking the panel;
	// sleep handles blanking through bl_power.
	int max = getInt("/sys/class/backlight/backlight/max_brightness");
	if (max<=0) max = 102;
	int raw = 2 + (value * (max - 2)) / 10;
	SetRawBrightness(raw);
	SaveSettings();
}

int GetVolume(void) { // 0-20
	return settings->jack ? settings->headphones : settings->speaker;
}
void SetVolume(int value) {
	if (value<0) value = 0;
	if (value>20) value = 20;
	if (settings->jack) settings->headphones = value;
	else settings->speaker = value;

	SetRawVolume(value);
	SaveSettings();
}

#define BRIGHTNESS_PATH "/sys/class/backlight/backlight/brightness"
void SetRawBrightness(int val) { // 0 - max_brightness
	putInt(BRIGHTNESS_PATH, val);
}

void SetRawVolume(int val) { // 0 - 20
	// The rk817 "Playback Volume" control is 0-255 but NOT linear: amixer
	// reports dBscale-min=-54dB, step=3.75dB, and the driver says the range
	// is -54..0 dB. So 152 is 0 dB, each raw step below it is -3.75 dB, and
	// anything under ~130 is silence. (A raw cap of 140 was "very quiet":
	// 45 dB down.) Map MinUI's 0-20 onto 130..150 (-82.5 .. -7.5 dB), keeping
	// 2 steps of headroom under 0 dB where loud passages clipped.
	char cmd[128];
	sprintf(cmd, "amixer -q sset Playback %d 2>/dev/null", 130 + val);
	system(cmd);
}

// monitored and set by thread in keymon
int GetJack(void) {
	return settings->jack;
}
void SetJack(int value) {
	settings->jack = value;
	SetVolume(GetVolume());
}

int GetHDMI(void) { return 0; }
void SetHDMI(int value) { }
void SetMute(int mute) {
	char cmd[128];
	sprintf(cmd, "amixer -q sset Playback %s 2>/dev/null", mute ? "mute" : "unmute");
	system(cmd);
}
