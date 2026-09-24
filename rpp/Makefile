# rpp (RK3326, AmberELEC)

###########################################################

ifeq (,$(PLATFORM))
PLATFORM=$(UNION_PLATFORM)
endif

ifeq (,$(PLATFORM))
$(error please specify PLATFORM, eg. PLATFORM=trimui make)
endif

###########################################################

REQUIRES_UNZIP60=other/unzip60

# `show` is not built: it needs all/common/SDL2_rotozoom.c, which does not
# exist in this tree. Every device ships the prebuilt aarch64
# workspace/showpng.elf instead (see platform/makefile.copy).

all: readmes

early: $(REQUIRES_UNZIP60)
	mkdir -p other
	cd $(REQUIRES_UNZIP60) && make -f unix/Makefile.trimuismart unzip

clean:
	cd other/unzip60 && make -f unix/Makefile.trimuismart clean

$(REQUIRES_UNZIP60):
	git clone --depth 1 https://github.com/shauninman/unzip60.git $(REQUIRES_UNZIP60)

include ../all/readmes/makefile
