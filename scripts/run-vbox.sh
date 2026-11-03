#!/usr/bin/env bash
# KAVYA OS - VirtualBox Runner & Configuration Helper
# Sets up and launches KAVYA OS in VirtualBox with optimal drivers & settings

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

VM_NAME="KAVYA-OS"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO_PATH="${PROJECT_DIR}/build/KAVYA-OS.iso"

echo -e "\n${BOLD}${CYAN}======================================================${NC}"
echo -e "${BOLD}${CYAN}      KAVYA OS - VirtualBox Setup & Runner            ${NC}"
echo -e "${BOLD}${CYAN}======================================================${NC}\n"

# 1. Check if ISO exists
if [[ ! -f "$ISO_PATH" ]]; then
    echo -e "${RED}Error: ISO not found at ${ISO_PATH}${NC}"
    echo -e "Please build the ISO first by running: ${BOLD}make build${NC} or ${BOLD}./build.sh${NC}\n"
    exit 1
fi

ISO_SIZE=$(ls -lh "$ISO_PATH" | awk '{print $5}')
echo -e "ISO Image: ${WHITE}${ISO_PATH}${NC} (${GREEN}${ISO_SIZE}${NC})"

# 2. Check VirtualBox installation
if ! command -v VBoxManage >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: 'VBoxManage' CLI tool was not found in PATH.${NC}"
    echo -e "If you are on Windows or Linux, ensure VirtualBox is installed."
    echo -e "On macOS, install it via: ${BOLD}brew install --cask virtualbox${NC}\n"
    echo -e "${BOLD}Manual VirtualBox VM Setup Guide:${NC}"
    echo -e "  1. Name:              ${WHITE}KAVYA-OS${NC}"
    echo -e "  2. Type:              ${WHITE}Linux${NC} | Version: ${WHITE}Debian (64-bit)${NC}"
    echo -e "  3. Memory:            ${WHITE}2048 MB (2 GB)${NC}"
    echo -e "  4. Processors:        ${WHITE}2 CPUs${NC}"
    echo -e "  5. Graphics:          ${WHITE}VMSVGA${NC} with ${WHITE}128 MB Video Memory${NC}"
    echo -e "  6. Storage:           Attach ${WHITE}${ISO_PATH}${NC} to Optical Drive"
    echo -e "  7. Credentials:       User: ${WHITE}kavya${NC} | Pass: ${WHITE}kavya${NC} (autologin enabled)"
    exit 0
fi

VBOX_VER=$(VBoxManage --version 2>/dev/null || echo "Unknown")
echo -e "VirtualBox: ${WHITE}${VBOX_VER}${NC}"

# 3. Architecture Compatibility Check
HOST_ARCH=$(uname -m)

if [[ "$HOST_ARCH" == "arm64" || "$HOST_ARCH" == "aarch64" ]]; then
    echo -e "\n${YELLOW}------------------------------------------------------${NC}"
    echo -e "${BOLD}${YELLOW}📌 NOTE FOR APPLE SILICON MAC USERS (M1/M2/M3/M4):${NC}"
    echo -e "${YELLOW}------------------------------------------------------${NC}"
    echo -e "VirtualBox on Apple Silicon Mac hypervisors currently only virtualizes"
    echo -e "ARM64 guests and ${BOLD}cannot emulate x86_64/amd64 platforms${NC}."
    echo -e "Running an x86_64 ISO directly in VirtualBox on this Mac will produce:"
    echo -e "  ${RED}VBOX_E_PLATFORM_ARCH_NOT_SUPPORTED${NC}"
    echo -e ""
    echo -e "To run KAVYA OS seamlessly on this Apple Silicon Mac, use:"
    echo -e "  👉 ${BOLD}${GREEN}make test${NC}  or  ${BOLD}${GREEN}./tests/test-iso.sh${NC}"
    echo -e "  (Launches QEMU high-performance x86_64 emulation with audio & display)"
    echo -e ""
    echo -e "To run this ISO inside VirtualBox:"
    echo -e "  • Transfer ${WHITE}build/KAVYA-OS.iso${NC} to any Windows PC, Linux PC, or Intel Mac"
    echo -e "  • Create a Debian 64-bit VM in VirtualBox using the settings below:"
    echo -e "    - Memory:       ${WHITE}2048 MB${NC}"
    echo -e "    - Graphics:     ${WHITE}VMSVGA${NC} (128 MB VRAM)"
    echo -e "    - Pointing:     ${WHITE}USB Tablet${NC} (seamless mouse integration)"
    echo -e "    - Network:      ${WHITE}NAT / Intel PRO/1000 MT${NC}"
    echo -e "${YELLOW}------------------------------------------------------${NC}\n"
    
    read -p "Would you like to test in QEMU right now instead? (Y/n): " -r choice || choice="y"
    choice=${choice:-y}
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        exec "${PROJECT_DIR}/tests/test-iso.sh" "$ISO_PATH"
    fi
    exit 0
fi

# 4. For x86_64 / Intel / PC Hosts: Automated VirtualBox Setup
echo -e "\n${GREEN}Configuring VirtualBox VM '${VM_NAME}'...${NC}"

# Unregister if previously exists
if VBoxManage list vms | grep -q "\"${VM_NAME}\""; then
    echo -e "${YELLOW}Existing VM '${VM_NAME}' found. Powering off and replacing...${NC}"
    VBoxManage controlvm "${VM_NAME}" poweroff 2>/dev/null || true
    sleep 1
    VBoxManage unregistervm "${VM_NAME}" --delete 2>/dev/null || true
fi

# Create and register VM
VBoxManage createvm --name "${VM_NAME}" --ostype "Debian_64" --register

# Configure CPU, Memory, Display, and Peripherals
VBoxManage modifyvm "${VM_NAME}" \
    --memory 2048 \
    --cpus 2 \
    --graphicscontroller vmsvga \
    --vram 128 \
    --mouse usbtablet \
    --audio-controller hda \
    --audio-driver default \
    --nic1 nat \
    --nictype1 82540EM \
    --boot1 dvd \
    --boot2 none \
    --boot3 none \
    --boot4 none

# Add Storage Controller and attach ISO
VBoxManage storagectl "${VM_NAME}" --name "IDE Controller" --add ide
VBoxManage storageattach "${VM_NAME}" \
    --storagectl "IDE Controller" \
    --port 0 \
    --device 0 \
    --type dvddrive \
    --medium "${ISO_PATH}"

echo -e "\n${BOLD}${GREEN}Successfully configured '${VM_NAME}'!${NC}"
echo -e "Starting VirtualBox VM..."
VBoxManage startvm "${VM_NAME}"
