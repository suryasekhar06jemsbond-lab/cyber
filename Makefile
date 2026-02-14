CC ?= cc
CFLAGS ?= -O2 -std=c99 -Wall -Wextra -Werror
NYX_LANG_VERSION ?= 0.6.13
VERSION_DEFINE := -DNYX_LANG_VERSION=\"$(NYX_LANG_VERSION)\"

.PHONY: all clean

all: build/nyx

build/nyx: native/nyx.c
	mkdir -p build
	$(CC) $(CFLAGS) $(VERSION_DEFINE) -o build/nyx native/nyx.c

clean:
	rm -f build/nyx nyx.exe
