CC ?= cc
CFLAGS ?= -O2 -std=c99 -Wall -Wextra -Werror
CY_LANG_VERSION ?= 0.6.7
VERSION_DEFINE := -DCY_LANG_VERSION=\"$(CY_LANG_VERSION)\"

.PHONY: all clean

all: build/cyper

build/cyper: native/cy.c
	mkdir -p build
	$(CC) $(CFLAGS) $(VERSION_DEFINE) -o build/cyper native/cy.c

build/cy: build/cyper
	cp build/cyper build/cy

clean:
	rm -f build/cy build/cyper cy.exe cyper.exe
