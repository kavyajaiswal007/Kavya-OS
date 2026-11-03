# KAVYA OS
> *"A Minimal Debian-Based Linux Distribution"*

KAVYA OS is a clean, ultra-lightweight, bootable Linux distribution based on Debian GNU/Linux 12 (Bookworm) for x86_64 / amd64 PCs.

---

## 🎯 Project Goals & Philosophy

* **Target Architecture:** `x86_64` / `amd64`
* **Base:** Debian GNU/Linux 12 (Bookworm) stable
* **Kernel:** Debian stable Linux kernel (`linux-image-amd64`)
* **Bootloader:** GRUB / ISOLINUX with hybrid BIOS & UEFI support
* **Window Manager:** Openbox + Tint2 + PCManFM (featherweight, fast, and responsive)
* **Design Philosophy:** Minimal, useful, and clean. No duplicate applications, no office suites, no games, no background bloat.

### The 7 Essential Applications
1. **Settings:** LXAppearance, ObConf, ARandR, Pavucontrol
2. **File Manager:** PCManFM
3. **Terminal:** LXTerminal
4. **Web Browser:** NetSurf GTK (Ultra-lightweight, fast, featherweight footprint)
5. **Text Editor:** FeatherPad (GUI) + Nano (CLI)
6. **Calculator:** Galculator
7. **System Monitor:** LXTask (GUI) + Htop (CLI)

---

## 🎓 OS Concepts & PBL Alignment

KAVYA OS is engineered to demonstrate core Operating Systems principles through hands-on tools:

| Topic | Learning Concept | KAVYA OS Feature |
| :--- | :--- | :--- |
| **Linux Architecture** | Kernel vs Userspace, VFS, systemd services | `ksys`, `/etc/issue`, `/proc` inspection |
| **Memory Management** | Virtual memory, page cache, VFS buffers, swap | `kmem`, `/proc/meminfo` visualizer |
| **Process Lifecycle** | Process states (R, S, D, T, Z), PCB structure | `kps`, `/proc/<PID>/status` deep-dive |
| **Processes vs Threads**| Shared address space vs clone tasks | `kps <PID>`, thread counter |
| **CPU Scheduling** | FCFS vs Round Robin vs CFS (vruntime) | `kschedule` interactive theory & Gantt charts |
| **System Diagnostics** | Load averages, resource thresholds, zombies | `khealth` rating & health diagnostics |
| **Storage & Backup** | Archiving, tar/gzip, SHA256 integrity verification | `kbackup` automated backup tool |
| **Log Management** | Kernel ring buffer (dmesg) & systemd journal | `klog` priority error analyzer |

---

## ⚡ Custom Commands Reference

All custom tools are installed to `/usr/local/bin` and can be executed from any terminal or Openbox menu:

* `kinfo` - System specifications and ASCII art branding overview.
* `ksys` - Kernel release, architecture, sysctl VM parameters, and running services.
* `kmem` - Detailed physical RAM, page cache, buffers, and swap breakdown.
* `kps` - Process lifecycle inspector (or `kps <PID>` for Process Control Block details).
* `kschedule` - CPU scheduling demonstration (FCFS, Round Robin, CFS vruntime).
* `khealth` - Live system health audit with 0–100 score and alerts.
* `kbackup` - Automated compressed archive creator with SHA256 verification.
* `klog` - Prioritized system and kernel error log viewer.

---

## 📁 Project Structure

```text
kavya-os/
├── Makefile                     # Build & test shortcuts (make build, make test)
├── README.md                    # OS documentation and architecture
├── build.sh                     # Host orchestrator script (launches containerized build)
├── builder/                     # Container build environment
│   ├── Dockerfile               # Debian Bookworm container definition
│   └── run-builder.sh           # Internal build runner (debootstrap, chroot, squashfs, ISO)
├── config/                      # System configuration
│   ├── boot/                    # GRUB bootloader configuration (grub.cfg)
│   ├── desktop/                 # Openbox autostart, menu.xml, rc.xml, tint2rc
│   ├── network/                 # NetworkManager & networking defaults
│   ├── skel/                    # Skeleton user home (.bashrc with custom prompt)
│   └── system/                  # Hostname, hosts, /etc/issue, lightdm autologin
├── branding/                    # Visual assets
│   ├── generate_branding.py     # Python script to generate wallpaper and splash
│   ├── wallpaper/               # Official KAVYA OS wallpaper
│   └── grub/                    # GRUB boot splash image
├── packages/                    # Declarative package lists (strictly minimal)
│   ├── core.list                # Kernel, init, systemd, drivers, firmware
│   ├── desktop.list             # Xorg, Openbox, Tint2, 7 essential applications
│   └── learning.list            # Utilities for OS & PBL learning
├── scripts/                     # Custom KAVYA OS commands (installed to /usr/local/bin)
│   ├── kinfo, ksys, kmem, kps, kschedule, khealth, kbackup, klog
├── tests/                       # Testing harness
│   └── test-iso.sh              # Launches QEMU x86_64 on Apple Silicon Mac
└── build/                       # Build output directory (contains KAVYA-OS.iso)
```

---

## 🛠️ How to Build KAVYA OS

### Prerequisites
On Apple Silicon Mac:
```bash
brew install colima docker qemu
```

### 1. Build the ISO
Run the automated build pipeline:
```bash
make build
# or
./build.sh
```

The build script will:
1. Ensure Colima/Docker is running.
2. Build the `kavya-builder` container image.
3. Bootstrap Debian 12 amd64 with `debootstrap`.
4. Install all whitelisted packages, configurations, branding, and custom tools.
5. Compress the root filesystem into an ultra-compact `filesystem.squashfs` with XZ.
6. Assemble hybrid BIOS + UEFI bootloaders and generate `build/KAVYA-OS.iso`.

---

## 📦 How to Run on VirtualBox

KAVYA OS comes with built-in VirtualBox Guest kernel modules (`vboxguest`, `vboxsf`, `vboxvideo`), providing seamless mouse integration, dynamic resolution auto-resizing, and shared folders.

### Automated Setup
On any system with VirtualBox installed, run:
```bash
make vbox
# or
./scripts/run-vbox.sh
```

### Manual VM Configuration
When creating a virtual machine manually in VirtualBox:
1. **Name & OS:** Name: `KAVYA-OS` | Type: `Linux` | Version: `Debian (64-bit)`
2. **Memory (RAM):** `2048 MB` (2 GB) minimum
3. **Processors:** `2 CPUs`
4. **Display:**
   - Graphics Controller: `VMSVGA`
   - Video Memory: `128 MB` (Prevents Xorg allocation issues)
5. **Storage:** Attach `build/KAVYA-OS.iso` to the Optical (IDE/SATA) Drive
6. **System / Pointing Device:** `USB Tablet` (Enables seamless mouse capture)
7. **Credentials:**
   - Standard user: `kavya` / password: `kavya` (*automatic login enabled*)
   - Root user: `root` / password: `kavya`

> [!NOTE]
> **Apple Silicon Mac Note:** VirtualBox 7.x on Apple Silicon Macs currently only virtualizes ARM64 guests and cannot emulate x86_64 (`VBOX_E_PLATFORM_ARCH_NOT_SUPPORTED`). To test this amd64 ISO on Apple Silicon Macs, use **`make test`** (which runs QEMU x86_64 emulation). To run on VirtualBox, test on any Windows, Linux, or Intel PC.

---

## 🖥️ Run in UTM

To run KAVYA OS in UTM (especially on macOS):

1. **Emulate:** Select **Emulate** (do not select Virtualize on Apple Silicon).
2. **Architecture:** `x86_64`
3. **Memory:** `2048 MB` (2 GB)
4. **CPU:** `2` cores
5. **Storage:** No hard disk needed (live system). Attach `build/KAVYA-OS.iso` to the **CD/DVD** drive.
6. **Display:** `VirtIO-GPU`
7. **Boot:** Set to **Boot from CD**.

> [!NOTE]
> On Apple Silicon Macs, UTM runs this ISO under x86 emulation (QEMU TCG), so it is slower than running natively or in VirtualBox on an Intel PC.

---

## 💻 How to Test on Apple Silicon Mac

Because M1/M2/M3/M4 Macs run ARM64 and the target ISO is amd64, test using QEMU emulation:

```bash
make test
# or
./tests/test-iso.sh
```

This launches a virtual x86_64 PC window running KAVYA OS with graphics, sound, and networking.

---

## 💾 Booting on Real PC Hardware

To boot on physical x86_64 PC hardware, write the ISO to a USB flash drive:

```bash
# On Linux / macOS (replace /dev/sdX or /dev/rdiskN with your actual USB disk):
sudo dd if=build/KAVYA-OS.iso of=/dev/sdX bs=4M status=progress conv=fdatasync
```
Plug the USB drive into your PC, select Boot Options (F12 / F11 / Del), and select KAVYA OS. Both UEFI and Legacy BIOS are fully supported.
