// v90s (Powkiddy V90S, Allwinner A133P, KNULLI/Batocera)
//
// The RG351V keymon had to sniff /dev/input/by-path to tell five RK3326
// boards apart. This one targets a single board, so it just opens every
// evdev node and filters by key code.
//
//   volume rocker alone  -> volume
//   hotkey + rocker      -> brightness
//   START + SELECT       -> kill the app named in /tmp/killstandalone.txt
//                           (nothing in MinUI Amber writes that file yet, so
//                           in practice this never fires)

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <fcntl.h>
#include <dirent.h>
#include <string.h>
#include <sys/time.h>
#include <linux/input.h>

#include <msettings.h>

#define VOLUME_MIN 		0
#define VOLUME_MAX 		20
#define BRIGHTNESS_MIN 	0
#define BRIGHTNESS_MAX 	10

// Volume rocker: Allwinner LRADC, "keyboard" node in v90s_kernel.dts
// key0 = <0x2d0 0x73> (KEY_VOLUMEUP), key1 = <0x438 0x72> (KEY_VOLUMEDOWN)
#define CODE_PLUS		115
#define CODE_MINUS		114

// Gamepad, from KNULLI es_input.cfg "Powkiddy V90s Controller".
// The V90S has no dedicated menu button; es_input assigns "hotkey" to 316.
#define CODE_MENU		316
#define CODE_SELECT		314
#define CODE_START		315

//	for ev.value
#define RELEASED	0
#define PRESSED		1
#define REPEAT		2

#define INPUT_COUNT 16
static int inputs[INPUT_COUNT];
static int input_count = 0;
static struct input_event ev;

#define KILLSTANDALONE_PATH "/tmp/killstandalone.txt"

static void openInputs(void) {
	DIR* dir = opendir("/dev/input");
	if (!dir) return;

	struct dirent* entry;
	while ((entry=readdir(dir)) && input_count<INPUT_COUNT) {
		if (strncmp(entry->d_name, "event", 5)!=0) continue;

		char path[64];
		snprintf(path, sizeof(path), "/dev/input/%s", entry->d_name);
		int fd = open(path, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
		if (fd>=0) inputs[input_count++] = fd;
	}
	closedir(dir);

	printf("keymon: opened %i input device(s)\n", input_count); fflush(stdout);
}

int main (int argc, char *argv[]) {
	InitSettings();
	openInputs();

	uint32_t val;
	uint32_t menu_pressed = 0;
	uint32_t select_pressed = 0;
	uint32_t start_pressed = 0;

	uint32_t up_pressed = 0;
	uint32_t up_just_pressed = 0;
	uint32_t up_repeat_at = 0;

	uint32_t down_pressed = 0;
	uint32_t down_just_pressed = 0;
	uint32_t down_repeat_at = 0;

	uint8_t ignore;
	uint32_t then;
	uint32_t now;
	struct timeval tod;

	gettimeofday(&tod, NULL);
	then = tod.tv_sec * 1000 + tod.tv_usec / 1000; // essentially SDL_GetTicks()
	ignore = 0;
	while (1) {
		gettimeofday(&tod, NULL);
		now = tod.tv_sec * 1000 + tod.tv_usec / 1000;
		if (now-then>1000) ignore = 1; // ignore input that arrived during sleep

		for (int i=0; i<input_count; i++) {
			int input_fd = inputs[i];
			while(read(input_fd, &ev, sizeof(ev))==sizeof(ev)) {
				if (ignore) continue;
				val = ev.value;

				if (( ev.type != EV_KEY ) || ( val > REPEAT )) continue;

				if (ev.code == CODE_MENU) {
					menu_pressed = val;
				}
				if (ev.code == CODE_SELECT) {
					select_pressed = val;
				}
				if (ev.code == CODE_START) {
					start_pressed = val;
				}
				if (ev.code == CODE_PLUS) {
					up_pressed = up_just_pressed = val;
					if (val) up_repeat_at = now + 300;
				}
				if (ev.code == CODE_MINUS) {
					down_pressed = down_just_pressed = val;
					if (val) down_repeat_at = now + 300;
				}
			}
		}

		if (ignore) {
			menu_pressed = 0;
			up_pressed = up_just_pressed = 0;
			down_pressed = down_just_pressed = 0;
			up_repeat_at = 0;
			down_repeat_at = 0;
		}

		if (access(KILLSTANDALONE_PATH,F_OK)==0) {
			if (start_pressed && select_pressed) {
				char cmd[512];
				sprintf(cmd, "kill -9 $(pidof $(cat %s))", KILLSTANDALONE_PATH);
				if (system(cmd) == 0) {
					unlink(KILLSTANDALONE_PATH);
				}
			}
		}

		if (up_just_pressed || (up_pressed && now>=up_repeat_at)) {
			if (menu_pressed) {
				val = GetBrightness();
				if (val<BRIGHTNESS_MAX) SetBrightness(++val);
			}
			else {
				val = GetVolume();
				if (val<VOLUME_MAX) SetVolume(++val);
			}
			if (up_just_pressed) up_just_pressed = 0;
			else up_repeat_at += 100;
		}

		if (down_just_pressed || (down_pressed && now>=down_repeat_at)) {
			if (menu_pressed) {
				val = GetBrightness();
				if (val>BRIGHTNESS_MIN) SetBrightness(--val);
			}
			else {
				val = GetVolume();
				if (val>VOLUME_MIN) SetVolume(--val);
			}
			if (down_just_pressed) down_just_pressed = 0;
			else down_repeat_at += 100;
		}

		then = now;
		ignore = 0;

		usleep(16667); // 60fps
	}

}
