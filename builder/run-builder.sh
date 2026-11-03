#!/usr/bin/env bash
# KAVYA OS - Distribution Image Builder Script
# Runs inside the Debian build container to produce KAVYA-OS.iso

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "\n${BOLD}${CYAN}======================================================${NC}"
echo -e "${BOLD}${CYAN}   KAVYA OS - Automated Distribution ISO Builder      ${NC}"
echo -e "${BOLD}${CYAN}======================================================${NC}\n"

BUILD_DIR="/tmp/kavya_build"
ROOTFS="${BUILD_DIR}/rootfs"
ISO_DIR="${BUILD_DIR}/iso"
OUTPUT_ISO="/workspace/build/KAVYA-OS.iso"

# Cleanup trap to ensure mounts are released cleanly
cleanup() {
    echo -e "${YELLOW}Cleaning up mounts...${NC}"
    if mountpoint -q "${ROOTFS}/dev/pts" 2>/dev/null; then umount -lf "${ROOTFS}/dev/pts" || true; fi
    if mountpoint -q "${ROOTFS}/dev" 2>/dev/null; then umount -lf "${ROOTFS}/dev" || true; fi
    if mountpoint -q "${ROOTFS}/proc" 2>/dev/null; then umount -lf "${ROOTFS}/proc" || true; fi
    if mountpoint -q "${ROOTFS}/sys" 2>/dev/null; then umount -lf "${ROOTFS}/sys" || true; fi
}
trap cleanup EXIT

echo -e "${GREEN}[1/8] Cleaning and preparing build workspace...${NC}"
rm -rf "${BUILD_DIR}"
mkdir -p "${ROOTFS}" "${ISO_DIR}/live" "${ISO_DIR}/boot/grub" "${ISO_DIR}/isolinux" "${ISO_DIR}/EFI/BOOT" "/workspace/build"

echo -e "${GREEN}[2/8] Bootstrapping Debian 12 (Bookworm amd64)...${NC}"
debootstrap --arch=amd64 --variant=minbase bookworm "${ROOTFS}" http://deb.debian.org/debian/

echo -e "${GREEN}[3/8] Mounting virtual filesystems for chroot...${NC}"
mkdir -p "${ROOTFS}/dev" "${ROOTFS}/dev/pts" "${ROOTFS}/proc" "${ROOTFS}/sys"
mount --bind /dev "${ROOTFS}/dev"
mount --bind /dev/pts "${ROOTFS}/dev/pts"
mount -t proc proc "${ROOTFS}/proc"
mount -t sysfs sysfs "${ROOTFS}/sys"

echo -e "${GREEN}[4/8] Configuring APT repositories & disabling recommended packages...${NC}"
cat << 'EOF' > "${ROOTFS}/etc/apt/sources.list"
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

cat << 'EOF' > "${ROOTFS}/etc/apt/apt.conf.d/01norecommends"
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF

# Prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive

# Prevent daemons from trying to start inside chroot during package installation
cat << 'EOF' > "${ROOTFS}/usr/sbin/policy-rc.d"
#!/bin/sh
exit 101
EOF
chmod +x "${ROOTFS}/usr/sbin/policy-rc.d"

DEBIAN_FRONTEND=noninteractive chroot "${ROOTFS}" apt-get update

echo -e "${GREEN}[5/8] Installing whitelisted packages (Core, Desktop, Learning)...${NC}"

# Read package lists excluding comments and empty lines
read_pkg_list() {
    grep -vE '^\s*#|^\s*$' "$1" | tr '\n' ' '
}

CORE_PKGS=$(read_pkg_list /workspace/packages/core.list)
DESKTOP_PKGS=$(read_pkg_list /workspace/packages/desktop.list)
LEARNING_PKGS=$(read_pkg_list /workspace/packages/learning.list)

DEBIAN_FRONTEND=noninteractive chroot "${ROOTFS}" apt-get install -y --no-install-recommends $CORE_PKGS
DEBIAN_FRONTEND=noninteractive chroot "${ROOTFS}" apt-get install -y --no-install-recommends $DESKTOP_PKGS
DEBIAN_FRONTEND=noninteractive chroot "${ROOTFS}" apt-get install -y --no-install-recommends $LEARNING_PKGS

echo -e "${GREEN}[6/8] Configuring KAVYA OS system, user, and branding...${NC}"

# Configure Hostname and Hosts
cp /workspace/config/system/hostname "${ROOTFS}/etc/hostname"
cp /workspace/config/system/hosts "${ROOTFS}/etc/hosts"
cp /workspace/config/system/issue "${ROOTFS}/etc/issue"

# Set locale to en_US.UTF-8
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' "${ROOTFS}/etc/locale.gen"
echo "LANG=en_US.UTF-8" > "${ROOTFS}/etc/default/locale"
chroot "${ROOTFS}" locale-gen

# Create standard user 'kavya' with password 'kavya'
# Also create 'autologin' and 'vboxsf' groups for VirtualBox shared folders & passwordless desktop login
chroot "${ROOTFS}" groupadd -r -f autologin
chroot "${ROOTFS}" groupadd -r -f vboxsf
if ! chroot "${ROOTFS}" id -u kavya >/dev/null 2>&1; then
    chroot "${ROOTFS}" useradd -m -s /bin/bash -U -G sudo,audio,video,netdev,cdrom,plugdev,autologin,vboxsf kavya
fi
chroot "${ROOTFS}" usermod -a -G autologin,vboxsf,sudo,audio,video,netdev,cdrom,plugdev kavya
echo "kavya:kavya" | chroot "${ROOTFS}" chpasswd
echo "root:kavya" | chroot "${ROOTFS}" chpasswd

# VirtualBox Guest Services & Kernel Modules
cat << 'EOF' >> "${ROOTFS}/etc/modules"
vboxguest
vboxsf
vboxvideo
EOF

# Passwordless sudo for live session
mkdir -p "${ROOTFS}/etc/sudoers.d"
echo "kavya ALL=(ALL) NOPASSWD:ALL" > "${ROOTFS}/etc/sudoers.d/kavya"
chmod 0440 "${ROOTFS}/etc/sudoers.d/kavya"

# Passwordless PAM autologin configuration for LightDM
mkdir -p "${ROOTFS}/etc/pam.d"
cat << 'EOF' > "${ROOTFS}/etc/pam.d/lightdm-autologin"
#%PAM-1.0
auth    requisite   pam_nologin.so
auth    required    pam_permit.so
@include common-account
@include common-session
EOF

# Install custom KAVYA OS commands to /usr/local/bin
cp /workspace/scripts/k* "${ROOTFS}/usr/local/bin/"
chmod +x "${ROOTFS}/usr/local/bin/"k*

# Configure user home directory skeleton and configs
mkdir -p "${ROOTFS}/home/kavya/.config/openbox"
mkdir -p "${ROOTFS}/home/kavya/.config/tint2"
mkdir -p "${ROOTFS}/etc/skel/.config/openbox"
mkdir -p "${ROOTFS}/etc/skel/.config/tint2"

cp /workspace/config/skel/.bashrc "${ROOTFS}/home/kavya/.bashrc"
cp /workspace/config/skel/.bashrc "${ROOTFS}/etc/skel/.bashrc"

cp /workspace/config/desktop/autostart "${ROOTFS}/home/kavya/.config/openbox/autostart"
cp /workspace/config/desktop/menu.xml "${ROOTFS}/home/kavya/.config/openbox/menu.xml"
cp /workspace/config/desktop/rc.xml "${ROOTFS}/home/kavya/.config/openbox/rc.xml"
cp /workspace/config/desktop/tint2rc "${ROOTFS}/home/kavya/.config/tint2/tint2rc"

cp /workspace/config/desktop/autostart "${ROOTFS}/etc/skel/.config/openbox/autostart"
cp /workspace/config/desktop/menu.xml "${ROOTFS}/etc/skel/.config/openbox/menu.xml"
cp /workspace/config/desktop/rc.xml "${ROOTFS}/etc/skel/.config/openbox/rc.xml"
cp /workspace/config/desktop/tint2rc "${ROOTFS}/etc/skel/.config/tint2/tint2rc"

chmod +x "${ROOTFS}/home/kavya/.config/openbox/autostart"
chmod +x "${ROOTFS}/etc/skel/.config/openbox/autostart"

# Wallpaper branding
mkdir -p "${ROOTFS}/usr/share/backgrounds/kavya-os"
cp /workspace/branding/wallpaper/wallpaper.png "${ROOTFS}/usr/share/backgrounds/kavya-os/wallpaper.png"

# LightDM Autologin
mkdir -p "${ROOTFS}/etc/lightdm/lightdm.conf.d"
cp /workspace/config/system/lightdm.conf "${ROOTFS}/etc/lightdm/lightdm.conf"
cp /workspace/config/system/lightdm.conf "${ROOTFS}/etc/lightdm/lightdm.conf.d/01_kavya.conf"

# Fix ownership
chroot "${ROOTFS}" chown -R kavya:kavya /home/kavya

# Configure high-compression initramfs (XZ) to shrink initrd from 42MB to ~13MB
echo -e "${GREEN}Compressing initramfs with XZ...${NC}"
sed -i 's/^COMPRESS=.*/COMPRESS=xz/' "${ROOTFS}/etc/initramfs-tools/initramfs.conf"
chroot "${ROOTFS}" update-initramfs -u -k all

# Remove build-only and unneeded packages, policy-rc.d
rm -f "${ROOTFS}/usr/sbin/policy-rc.d"
chroot "${ROOTFS}" apt-get autoremove --purge -y
chroot "${ROOTFS}" apt-get clean

# Strip documentation, manual pages, info, groff, and foreign locales to keep ISO ultra-lightweight
echo -e "${GREEN}Stripping documentation, manpages, and unused locales...${NC}"
find "${ROOTFS}/usr/share/doc" -mindepth 1 -delete 2>/dev/null || true
find "${ROOTFS}/usr/share/man" -mindepth 1 -delete 2>/dev/null || true
find "${ROOTFS}/usr/share/info" -mindepth 1 -delete 2>/dev/null || true
find "${ROOTFS}/usr/share/groff" -mindepth 1 -delete 2>/dev/null || true

# Keep only the en_US locale under /usr/share/locale (delete the rest)
find "${ROOTFS}/usr/share/locale" -mindepth 1 -maxdepth 1 ! -name 'en_US*' ! -name 'locale.alias' -exec rm -rf {} + 2>/dev/null || true

# Purge cache and unneeded files to keep image tiny
find "${ROOTFS}/var/lib/apt/lists" -mindepth 1 -delete 2>/dev/null || true
find "${ROOTFS}/var/cache/apt" -mindepth 1 -delete 2>/dev/null || true
find "${ROOTFS}/tmp" -mindepth 1 -delete 2>/dev/null || true
find "${ROOTFS}/var/tmp" -mindepth 1 -delete 2>/dev/null || true
find "${ROOTFS}/var/log" -mindepth 1 -delete 2>/dev/null || true
rm -f "${ROOTFS}/etc/machine-id" "${ROOTFS}/var/lib/dbus/machine-id"

# Unmount cleanly before squashfs creation
cleanup

echo -e "${GREEN}[7/8] Compressing live root filesystem (SquashFS XZ with x86 BCJ)...${NC}"
# Extract kernel & initrd for live bootloader
VMLINUZ=$(ls -1 "${ROOTFS}/boot"/vmlinuz-* 2>/dev/null | sort -V | tail -n 1)
INITRD=$(ls -1 "${ROOTFS}/boot"/initrd.img-* 2>/dev/null | sort -V | tail -n 1)

if [[ -z "$VMLINUZ" || -z "$INITRD" ]]; then
    echo -e "${RED}Error: Kernel or initramfs not found in chroot /boot!${NC}"
    exit 1
fi

cp "$VMLINUZ" "${ISO_DIR}/live/vmlinuz"
cp "$INITRD" "${ISO_DIR}/live/initrd.img"

# Compress into filesystem.squashfs using optimal x86 BCJ filter and 1M blocks with 100% dictionary
mksquashfs "${ROOTFS}" "${ISO_DIR}/live/filesystem.squashfs" \
    -comp xz -b 1M -Xdict-size 100% -Xbcj x86 -noappend -e boot

echo -e "${GREEN}[8/8] Mastering bootloader and generating KAVYA-OS.iso...${NC}"

# 1. GRUB Configuration
cp /workspace/config/boot/grub.cfg "${ISO_DIR}/boot/grub/grub.cfg"
cp /workspace/branding/grub/splash.png "${ISO_DIR}/boot/grub/splash.png"

# 2. UEFI Boot Setup (standalone GRUB EFI executable)
grub-mkstandalone \
    --format=x86_64-efi \
    --output="${ISO_DIR}/EFI/BOOT/BOOTX64.EFI" \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=/workspace/config/boot/grub.cfg"

# Create FAT EFI boot image
dd if=/dev/zero of="${ISO_DIR}/boot/grub/efiboot.img" bs=1M count=10 status=none
mkfs.vfat "${ISO_DIR}/boot/grub/efiboot.img"
mmd -i "${ISO_DIR}/boot/grub/efiboot.img" ::EFI ::EFI/BOOT
mcopy -i "${ISO_DIR}/boot/grub/efiboot.img" "${ISO_DIR}/EFI/BOOT/BOOTX64.EFI" ::EFI/BOOT/BOOTX64.EFI

# 3. BIOS ISOLINUX Boot Setup
cp /usr/lib/ISOLINUX/isolinux.bin "${ISO_DIR}/isolinux/"
cp /usr/lib/syslinux/modules/bios/* "${ISO_DIR}/isolinux/"

cat << 'EOF' > "${ISO_DIR}/isolinux/isolinux.cfg"
UI vesamenu.c32
PROMPT 0
TIMEOUT 0
DEFAULT live

MENU TITLE KAVYA OS Boot Menu
MENU COLOR border       30;44   #40ffffff #a0000000 std
MENU COLOR title        1;36;44 #9033ccff #a0000000 std
MENU COLOR sel          7;37;40 #e0ffffff #20ffffff all
MENU COLOR unsel        37;44   #50ffffff #a0000000 std

LABEL live
  MENU LABEL KAVYA OS (Live Desktop)
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd.img boot=live components hostname=kavya-os username=kavya locales=en_US.UTF-8 keyboard-layouts=us timezone=Etc/UTC quiet loglevel=0 vt.global_cursor_default=0

LABEL failsafe
  MENU LABEL KAVYA OS (Failsafe Mode)
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd.img boot=live components hostname=kavya-os username=kavya nomodeset noapic noacpi nosplash
EOF

# Find isohdpfx.bin for MBR hybrid boot
ISOHDPFX="/usr/lib/ISOLINUX/isohdpfx.bin"
if [[ ! -f "$ISOHDPFX" ]]; then
    ISOHDPFX=$(find /usr -name isohdpfx.bin | head -n 1)
fi

# 4. Generate Hybrid ISO with xorriso
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "KAVYA_OS" \
    -eltorito-boot isolinux/isolinux.bin \
    -eltorito-catalog isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -isohybrid-mbr "${ISOHDPFX}" \
    -eltorito-alt-boot \
    -e boot/grub/efiboot.img \
    -no-emul-boot -isohybrid-gpt-basdat \
    -output "${OUTPUT_ISO}" \
    "${ISO_DIR}"

ISO_SIZE=$(ls -lh "${OUTPUT_ISO}" | awk '{print $5}')

echo -e "\n${BOLD}${GREEN}======================================================${NC}"
echo -e "${BOLD}${GREEN}  BUILD COMPLETE: KAVYA-OS.iso successfully created!   ${NC}"
echo -e "  Location: ${OUTPUT_ISO}"
echo -e "  Size:     ${ISO_SIZE}"
echo -e "${BOLD}${GREEN}======================================================${NC}\n"
