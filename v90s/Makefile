# v90s

###########################################################

ifeq (,$(PLATFORM))
PLATFORM=$(UNION_PLATFORM)
endif

ifeq (,$(PLATFORM))
$(error please specify PLATFORM, eg. PLATFORM=v90s make)
endif

###########################################################

REQUIRES_UNZIP60=other/unzip60

# No overclock helper: on KNULLI the CPU ceiling is set from platform.c via
# scaling_max_freq, which works under the stock schedutil governor and needs
# no governor switch in launch.sh.

# `show` is not built: it needs all/common/SDL2_rotozoom.c, which does not
# exist in this tree (the RG351V release ships the prebuilt aarch64
# workspace/showpng.elf instead, and so does this one).

all: readmes

early: $(REQUIRES_UNZIP60)
	mkdir -p other

clean:

$(REQUIRES_UNZIP60):
	git clone --depth 1 https://github.com/shauninman/unzip60.git $(REQUIRES_UNZIP60)

include ../all/readmes/makefile
