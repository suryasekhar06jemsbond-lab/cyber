CC ?= cc
CFLAGS ?= -O2 -std=c99 -Wall -Wextra -Werror
CY_LANG_VERSION ?= 0.6.13
VERSION_DEFINE := -DCY_LANG_VERSION=\"$(CY_LANG_VERSION)\"

.PHONY: all clean

all: build/nyx

build/nyx: native/cy.c
	mkdir -p build
	$(CC) $(CFLAGS) $(VERSION_DEFINE) -o build/nyx native/cy.c

clean:
	rm -f build/nyx nyx.exe
