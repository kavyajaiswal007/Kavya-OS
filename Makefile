# KAVYA OS - Makefile

.PHONY: all build test test-fullscreen vbox branding clean help

all: build

help:
	@echo "KAVYA OS Build Targets:"
	@echo "  make build           - Build ultra-compact KAVYA-OS.iso inside container"
	@echo "  make test            - Test KAVYA-OS.iso in QEMU x86_64 on Apple Silicon"
	@echo "  make test-fullscreen - Test KAVYA-OS.iso in true Full Screen"
	@echo "  make vbox            - Launch or configure VirtualBox VM with optimal settings"
	@echo "  make branding        - Re-generate wallpaper and GRUB splash images"
	@echo "  make clean           - Remove build artifacts and temporary ISO files"

build:
	@./build.sh

vbox:
	@./scripts/run-vbox.sh

test:
	@./tests/test-iso.sh

test-fullscreen:
	@./tests/test-iso.sh --fullscreen

branding:
	@python3 branding/generate_branding.py

clean:
	@rm -rf build/*
	@echo "Cleaned build directory."
