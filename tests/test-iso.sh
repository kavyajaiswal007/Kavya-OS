#!/usr/bin/env bash
# KAVYA OS - QEMU ISO Boot & Test Script for Apple Silicon Mac
# Emulates amd64/x86_64 PC hardware via QEMU TCG

set -e

FULLSCREEN_ARG=""
ISO_PATH="build/KAVYA-OS.iso"

for arg in "$@"; do
    if [[ "$arg" == "--fullscreen" || "$arg" == "-f" ]]; then
        FULLSCREEN_ARG="-full-screen"
    elif [[ -f "$arg" ]]; then
        ISO_PATH="$arg"
    fi
done

if [[ ! -f "$ISO_PATH" ]]; then
    echo "Error: ISO not found at $ISO_PATH"
    echo "Please build the ISO first using ./build.sh or make build"
    exit 1
fi

KVM_ARGS=()
if [[ "$(uname -s)" == "Linux" && -c /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
    KVM_ARGS=("-enable-kvm")
fi

qemu-system-x86_64 \
    "${KVM_ARGS[@]}" \
    -m 2048 \
    -smp 2 \
    -cdrom "$ISO_PATH" \
    -boot d \
    -vga virtio \
    -display default \
    $FULLSCREEN_ARG \
    -device intel-hda \
    -device hda-output \
    -nic user,model=virtio
