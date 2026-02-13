CC ?= cc
CFLAGS ?= -O2 -std=c99 -Wall -Wextra -Werror

.PHONY: all clean

all: build/cy cy

build/cy: native/cy.c
	mkdir -p build
	$(CC) $(CFLAGS) -o build/cy native/cy.c

cy: native/cy.c
	$(CC) $(CFLAGS) -o cy native/cy.c

clean:
	rm -f build/cy cy
