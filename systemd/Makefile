VERSION=v0.0.1
EXE_FILE?=clevis-pkcs11-afunix-socket-unlock
GIT_VERSION=$(shell git rev-parse --short HEAD)
CC=gcc

.PHONY: all clean test

all:
	$(CC) *.c -DGIT_VERSION=\"$(VERSION)-$(GIT_VERSION)\" -o $(EXE_FILE)
clean:
	rm -fv $(EXE_FILE)
test:
