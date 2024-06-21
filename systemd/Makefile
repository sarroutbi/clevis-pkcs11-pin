VERSION=v0.0.1
GIT_VERSION=$(shell git rev-parse --short HEAD)

.PHONY: all clean test

all:
	$(CC) *.c -DGIT_VERSION=\"$(VERSION)-$(GIT_VERSION)\" -o clevis-afunix-socket-unlock
clean:
	rm -v  clevis-afunix-socket-unlock
test:
