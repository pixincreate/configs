# Fedora Linux KDE Installation and Customization Guide

> **A Complete Guide for Privacy Enthusiasts and Developers**
> From Windows frustration to Linux freedom with NVIDIA compatibility and developer workflow optimization

## Table of Contents

- [Overview](#overview)
- [Pre-Installation Planning](#pre-installation-planning)
- [Installation Process](#installation-process)
- [Post-Installation System Setup](#post-installation-system-setup)
- [NVIDIA GPU Configuration](#nvidia-gpu-configuration)
- [Desktop Environment Customization](#desktop-environment-customization)
- [Development Environment](#development-environment)
- [Applications and Media](#applications-and-media)
- [System Maintenance and Stability](#system-maintenance-and-stability)
- [Exit Strategy and Dual Boot](#exit-strategy-and-dual-boot)
- [Troubleshooting](#troubleshooting)

## Overview

This guide provides a comprehensive, stability-focused approach to installing and customizing Fedora Linux with KDE Plasma. It's specifically designed for:

- **Privacy enthusiasts** moving away from Windows 11
- **Developers** working with Rust, JavaScript, Python, Kotlin, C/C++
- **Content creators** needing video editing capabilities
- **Gamers** requiring NVIDIA GPU support
- **Users prioritizing system stability** over bleeding-edge features

### Key Features of This Setup

- ✅ **NVIDIA GTX 1650Ti fully supported** with stable drivers
- ✅ **Kanagawa Dragon aesthetic** throughout the system
- ✅ **Developer workflow optimization** with your existing dotfiles
- ✅ **Single source of truth** for package management
- ✅ **Stability-first approach** - nothing breaks with updates
- ✅ **Privacy hardening** from day one
- ✅ **Exit strategy** for dual boot gaming setup

## Pre-Installation Planning

### 1. Hardware Compatibility Verification

**Critical Requirements Check:**

```bash
# Verify your exact hardware (run this on current Windows system)
# GPU Information
dxdiag  # Look for NVIDIA GeForce GTX 1650 Ti

# CPU Information
wmic cpu get name,manufacturer

# Memory
wmic memorychip get capacity,manufacturer

# Storage
wmic diskdrive get model,size,interfacetype
```

**Known Compatible Configuration:**

- ✅ Intel Core i5-10300H @ 2.50GHz (excellent Linux support)
- ✅ 16GB RAM (optimal for KDE Plasma + development)
- ✅ NVIDIA GTX 1650Ti (well-supported with proper drivers)
- ✅ Dual SSD setup (perfect for dual boot)

### 2. Backup Strategy and Risk Assessment

**Before You Begin - Critical Backups:**

1. **Windows System Backup** (if you want to keep dual boot option):

   ```powershell
   # Create Windows system image
   wbAdmin start backup -backupTarget:E: -include:C: -allCritical -quiet
   ```

2. **Important Data Backup**:
   - Documents, code repositories
   - Browser bookmarks and passwords
   - Development environment configurations
   - Windows license key: `wmic path softwarelicensingservice get OA3xOriginalProductKey`

3. **Hardware Driver Backup**:
   - Download latest NVIDIA drivers for Windows (just in case)
   - Note current driver versions

**Risk Assessment:**

- 🟢 **Low Risk**: Your hardware is well-supported
- 🟡 **Medium Risk**: NVIDIA drivers (mitigated by our approach)
- 🟢 **Low Risk**: Data loss (with proper backups)
- 🟢 **Exit Strategy**: Dual boot setup preserves Windows option

### 3. Installation Media Preparation

**Download Fedora KDE Spin:**

```bash
# Latest stable release (recommended for stability)
wget https://download.fedoraproject.org/pub/fedora/linux/releases/41/Spins/x86_64/iso/Fedora-KDE-Live-x86_64-41-1.4.iso

# Verify checksum (important for security)
curl -O https://download.fedoraproject.org/pub/fedora/linux/releases/41/Spins/x86_64/iso/Fedora-41-1.4-x86_64-CHECKSUM
sha256sum -c Fedora-41-1.4-x86_64-CHECKSUM
```

**Create Bootable USB:**

- **Windows**: Use [Rufus](https://rufus.ie/) with DD mode
- **macOS**: Use `dd` command or [balenaEtcher](https://www.balena.io/etcher/)
- **Linux**: Use `dd` command

```bash
# Linux/macOS method (replace /dev/sdX with your USB device)
sudo dd if=Fedora-KDE-Live-x86_64-41-1.4.iso of=/dev/sdX bs=4M status=progress && sync
```

### 4. UEFI/BIOS Settings

**Required BIOS Changes:**

1. **Disable Secure Boot** (temporarily, we'll re-enable after NVIDIA setup)
2. **Enable UEFI Boot Mode**
3. **Disable Fast Boot**
4. **Set USB as first boot priority**
5. **Disable Windows Boot Manager** (temporarily)

## Installation Process

### 1. Live Environment Testing

**Boot from USB and verify hardware:**

```bash
# Test GPU detection
lspci | grep -i nvidia

# Test wireless (if applicable)
ip link show

# Test audio
speaker-test -c 2

# Check system info
neofetch
```

### 2. Disk Partitioning Strategy

**Recommended Partition Layout** (for 500GB SSD):

```txt
/dev/nvme0n1p1    512MB    /boot/efi    (EFI System)
/dev/nvme0n1p2    1GB      /boot        (ext4)
/dev/nvme0n1p3    16GB     [SWAP]       (swap)
/dev/nvme0n1p4    50GB     /            (btrfs)
/dev/nvme0n1p5    430GB    /home        (btrfs)
```

**Why this layout:**

- **EFI partition**: Shared with Windows (if dual boot)
- **Separate /boot**: NVIDIA driver compatibility
- **Large swap**: Hibernation support (matches 16GB RAM)
- **btrfs for / and /home**: Snapshots for stability
- **Generous /home**: Your development files

### 3. Installation Steps

**Step-by-step installation:**

1. **Select "Install to Hard Drive"**
2. **Language**: English (US)
3. **Installation Destination**:
   - Select your 500GB SSD
   - Choose "Custom" partitioning
   - Create partitions as outlined above
4. **Network & Host Name**:
   - Set hostname: `fedora-dev` (or your preference)
   - Connect to WiFi if needed
5. **User Creation**:
   - Create user account (avoid "admin" or "root" as username)
   - Enable "Make this user administrator"
   - Use strong password
6. **Root Account**:
   - Enable root account with strong password
   - You'll need this for NVIDIA driver installation

**Installation Time**: ~15-20 minutes

## Post-Installation System Setup

### 1. First Boot Configuration

**Initial system update (critical for stability):**

```bash
# Update system packages
sudo dnf update -y

# Install essential tools
sudo dnf install -y curl wget git vim nano htop tree

# Reboot to ensure kernel updates are applied
sudo reboot
```

### 2. RPM Fusion Repository Setup

**Enable RPM Fusion for NVIDIA drivers and multimedia:**

```bash
# Free repository (essential)
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

# Non-free repository (for NVIDIA)
sudo dnf install -y \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Update package cache
sudo dnf update -y
```

### 3. DNF Configuration for Stability

**Optimize DNF for reliability:**

```bash
# Create DNF configuration for stability
sudo tee /etc/dnf/dnf.conf << 'EOF'
[main]
gpgcheck=1
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True

# Performance optimizations
deltarpm=true
max_parallel_downloads=10
defaultyes=True

# Stability settings
exclude_packages=kernel*
EOF
```

**Set up automatic security updates only:**

```bash
# Install dnf-automatic
sudo dnf install -y dnf-automatic

# Configure for security updates only
sudo sed -i 's/upgrade_type = default/upgrade_type = security/' /etc/dnf/automatic.conf
sudo sed -i 's/apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf

# Enable the service
sudo systemctl enable --now dnf-automatic.timer
```

## NVIDIA GPU Configuration

### 1. NVIDIA Driver Installation (Stability First)

**Install NVIDIA drivers from RPM Fusion (most stable approach):**

```bash
# Install NVIDIA drivers and tools
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda

# Install NVIDIA settings GUI
sudo dnf install -y nvidia-settings

# Install 32-bit libraries for gaming
sudo dnf install -y xorg-x11-drv-nvidia-libs.i686

# Regenerate initramfs
sudo akmods --force

# Reboot to load new drivers
sudo reboot
```

### 2. NVIDIA Configuration Verification

**Verify NVIDIA setup:**

```bash
# Check driver loading
nvidia-smi

# Verify OpenGL support
glxinfo | grep -i nvidia

# Check CUDA support (for development)
nvidia-smi -q | grep "CUDA Version"

# Test 3D acceleration
glxgears
```

### 3. NVIDIA Power Management

**Optimize for laptop usage:**

```bash
# Create NVIDIA power management configuration
sudo tee /etc/modprobe.d/nvidia-power-management.conf << 'EOF'
options nvidia-drm modeset=1
options nvidia NVreg_DynamicPowerManagement=0x02
EOF

# Update initramfs
sudo dracut --force

# Reboot to apply changes
sudo reboot
```

### 4. Re-enable Secure Boot

**Once NVIDIA is working, re-enable Secure Boot:**

1. Reboot to BIOS/UEFI
2. Enable Secure Boot
3. NVIDIA drivers should continue working (signed by RPM Fusion)

## Desktop Environment Customization

### 1. Essential Keyboard Shortcuts Setup

**Configure efficient keybindings first:**

Open System Settings → Shortcuts and configure:

```txt
# Essential bindings (based on your workflow)
Super + Enter         → Konsole (Terminal)
Super + D            → Application Launcher (KRunner)
Super + F            → Dolphin (File Manager)
Super + B            → Firefox (Browser)
Super + Q            → Close Window
Super + Shift + Q    → Logout
Super + Shift + F    → Maximize Window

# Window management
Super + Left         → Snap Left
Super + Right        → Snap Right
Super + Up           → Maximize
Super + Down         → Minimize
```

### 2. Terminal Customization (Konsole)

**Optimize Konsole for development:**

```bash
# Install necessary fonts (your existing nerd fonts)
sudo dnf install -y cascadia-fonts-all

# Create custom Konsole profile
mkdir -p ~/.local/share/konsole

# Copy your existing terminal configuration
# (This will be handled by your dotfiles setup)
```

**Konsole Configuration:**

- Font: Cascadia Code NerdFont, 12pt
- Color scheme: Kanagawa Dragon (custom)
- Transparency: 10%
- Hide menu bar and scroll bar
- Enable unlimited scrollback

### 3. Kanagawa Dragon Theme Implementation

**Install base theming packages:**

```bash
# Install theming tools
sudo dnf install -y \
  plasma-workspace-wallpapers \
  kde-plasma-addons \
  kvantum \
  papirus-icon-theme

# Install Qt theming tools
sudo dnf install -y qt5ct qt6ct
```

**Download and install Kanagawa Dragon theme:**

```bash
# Create theme directories
mkdir -p ~/.local/share/color-schemes
mkdir -p ~/.local/share/plasma/desktoptheme
mkdir -p ~/.local/share/aurorae/themes

# Download Kanagawa Dragon color scheme
curl -o ~/.local/share/color-schemes/KanagawaDragon.colors \
  https://raw.githubusercontent.com/rebelot/kanagawa.nvim/master/extras/kanagawa.kcsrc

# Apply via System Settings
```

**Manual Theme Configuration:**

1. **System Settings** → **Colors** → Import Kanagawa Dragon
2. **System Settings** → **Icons** → Select Papirus Dark
3. **System Settings** → **Application Style** → Configure transparency
4. **System Settings** → **Plasma Style** → Choose dark variant

### 4. Panel and Widget Configuration

**Minimal top panel setup:**

```bash
# Panel configuration (adjust to taste)
# Right-click panel → Panel Options → Panel Settings
```

**Recommended panel layout:**

- Position: Top
- Height: 32px
- Widgets (left to right):
  - Application Launcher (icon only)
  - Spacer (flexible)
  - Digital Clock
  - System Tray
  - User Switcher

**Remove unnecessary widgets:**

- Task Manager (use Alt+Tab instead)
- Peek at Desktop
- Show Activities

### 5. Enhanced Visual Effects

**Enable subtle but effective animations:**

System Settings → Desktop Effects:

```txt
# Enable these effects:
- Blur (50% strength, minimal noise)
- Fade (for smooth transitions)
- Geometry Change (smooth window animations)
- Magic Lamp (minimize effect)
- Wobbly Windows (optional, for fun)

# Disable resource-heavy effects:
- Desktop Cube
- Coverswitch
- Flip Switch
```

**Animation speed optimization:**

- Set animation speed to 75% for responsiveness
- Test on your hardware and adjust as needed

## Development Environment

### 1. Programming Languages Installation

**Install development languages via your package management system:**

```bash
# Rust (latest stable)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Node.js (LTS via dnf)
sudo dnf install -y nodejs npm

# Python development
sudo dnf install -y python3-devel python3-pip python3-virtualenv

# Kotlin (via SDKMAN)
curl -s "https://get.sdkman.io" | bash
source ~/.sdkman/bin/sdkman-init.sh
sdk install kotlin

# C/C++ development
sudo dnf install -y gcc gcc-c++ gdb cmake make

# Java (for Android development)
sudo dnf install -y java-17-openjdk java-17-openjdk-devel
```

### 2. Development Tools Setup

**Install essential development tools:**

```bash
# Version control and tools
sudo dnf install -y git git-lfs lazygit

# Terminal enhancements
sudo dnf install -y \
  bat eza ripgrep fd-find fzf \
  zoxide direnv tmux \
  tree htop neofetch fastfetch

# Text editors and IDEs
sudo dnf install -y vim neovim micro

# Container and cloud tools
sudo dnf install -y docker docker-compose podman
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

### 3. IDE Installation and Configuration

**Visual Studio Code:**

```bash
# Add Microsoft repository
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

# Install VS Code
sudo dnf install -y code
```

**Zed Editor (latest):**

```bash
# Download and install Zed
curl -f https://zed.dev/install.sh | sh
```

**Android Studio:**

```bash
# Download from official site and install
wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2023.3.1.18/android-studio-2023.3.1.18-linux.tar.gz

# Extract and install
sudo tar -xzf android-studio-*-linux.tar.gz -C /opt/
sudo ln -sf /opt/android-studio/bin/studio.sh /usr/local/bin/android-studio
```

### 4. Dotfiles Integration

**Clone and setup your existing configurations:**

```bash
# Clone your configs repository
git clone git@github.com:pixincreate/configs.git ~/Dev/scripts/.configs

# Navigate to configs directory
cd ~/Dev/scripts/.configs

# Run your existing setup script with Fedora adaptations
./unix/setup.sh --setup

# Stow your configurations
./unix/setup.sh --stow-all
```

**Verify dotfiles integration:**

```bash
# Check if configurations are properly linked
ls -la ~/
ls -la ~/.config/

# Test zsh configuration
zsh --version
echo $SHELL

# Verify git configuration
git config --list
```

## Applications and Media

### 1. Web Browsers Setup

**Firefox with privacy hardening:**

```bash
# Install Firefox (if not already installed)
sudo dnf install -y firefox

# Download Arkenfox user.js for privacy
mkdir -p ~/.mozilla/firefox/$(ls ~/.mozilla/firefox/ | grep default)/
curl -o ~/.mozilla/firefox/$(ls ~/.mozilla/firefox/ | grep default)/user.js \
  https://raw.githubusercontent.com/arkenfox/user.js/master/user.js

# Install uBlock Origin manually or via Firefox add-ons
```

**Zen Browser (your preferred browser):**

```bash
# Download Zen browser
wget https://github.com/zen-browser/desktop/releases/latest/download/zen-browser.linux-x86_64.tar.xz

# Extract and install
sudo tar -xf zen-browser.linux-x86_64.tar.xz -C /opt/
sudo ln -sf /opt/zen/zen /usr/local/bin/zen-browser
```

**Brave Browser (backup option):**

```bash
# Add Brave repository
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

# Install Brave
sudo dnf install -y brave-browser
```

### 2. Gaming Setup

**Steam installation and configuration:**

```bash
# Enable Steam repository
sudo dnf install -y steam

# Install gaming dependencies
sudo dnf install -y \
  wine lutris \
  vulkan-loader vulkan-tools \
  mesa-vulkan-drivers nvidia-driver-libs.i686

# Install Proton GE for better game compatibility
mkdir -p ~/.steam/root/compatibilitytools.d/
wget https://github.com/GloriousEggroll/proton-ge-custom/releases/latest/download/GE-Proton*.tar.gz
tar -xf GE-Proton*.tar.gz -C ~/.steam/root/compatibilitytools.d/
```

**Gaming optimizations:**

```bash
# Install GameMode for performance
sudo dnf install -y gamemode

# Configure gaming-specific settings
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf

# Install MangoHud for performance monitoring
sudo dnf install -y mangohud

# Configure Steam launch options for games:
# gamemoderun mangohud %command%
```

### 3. Video Editing - DaVinci Resolve

**Install DaVinci Resolve:**

```bash
# Install required dependencies
sudo dnf install -y \
  libxcrypt-compat \
  xcb-util-wm \
  xcb-util-image \
  libxkbcommon-x11 \
  pulseaudio-libs \
  xcb-util-keysyms \
  xcb-util-renderutil

# Download DaVinci Resolve from BlackMagic website
# (Free version available, requires registration)

# Make installer executable and run
chmod +x DaVinci_Resolve_*_Linux.run
sudo ./DaVinci_Resolve_*_Linux.run
```

**DaVinci Resolve optimizations:**

```bash
# Increase shared memory for DaVinci Resolve
echo 'tmpfs /tmp tmpfs defaults,noatime,mode=1777,size=8G 0 0' | sudo tee -a /etc/fstab

# Configure GPU acceleration
# (This will be handled automatically with NVIDIA drivers)
```

### 4. Essential Applications

**Productivity and utilities:**

```bash
# Communication
sudo dnf install -y discord telegram-desktop

# Media and graphics
sudo dnf install -y \
  vlc mpv \
  gimp inkscape blender \
  obs-studio

# Office suite
sudo dnf install -y libreoffice

# Archive management
sudo dnf install -y ark unzip p7zip

# Password manager
sudo dnf install -y keepassxc

# Note-taking (if Obsidian unavailable via dnf)
# Download from https://obsidian.md/
```

**Flatpak applications (for additional software):**

```bash
# Enable Flathub repository
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install applications not available in dnf
flatpak install -y flathub md.obsidian.Obsidian
flatpak install -y flathub com.bitwarden.desktop
flatpak install -y flathub org.signal.Signal
```

## System Maintenance and Stability

### 1. Update Strategy (Best of Both Worlds)

**Automated security updates with manual control:**

```bash
# Create update management script
sudo tee /usr/local/bin/system-update << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/system-updates.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Log update session
echo "[$DATE] Update session started" >> $LOG_FILE

# Check for updates
UPDATES=$(dnf check-update --quiet | wc -l)

if [ $UPDATES -gt 0 ]; then
    echo "[$DATE] $UPDATES updates available" >> $LOG_FILE

    # Create system snapshot (if using btrfs)
    if command -v snapper >/dev/null 2>&1; then
        snapper create --description "Pre-update snapshot $(date '+%Y%m%d_%H%M%S')"
        echo "[$DATE] Snapshot created" >> $LOG_FILE
    fi

    # Apply updates
    dnf update -y >> $LOG_FILE 2>&1

    echo "[$DATE] Updates applied successfully" >> $LOG_FILE
else
    echo "[$DATE] No updates available" >> $LOG_FILE
fi

echo "[$DATE] Update session completed" >> $LOG_FILE
echo "---" >> $LOG_FILE
EOF

# Make executable
sudo chmod +x /usr/local/bin/system-update
```

**Schedule updates safely:**

```bash
# Create systemd timer for weekly updates
sudo tee /etc/systemd/system/system-update.service << 'EOF'
[Unit]
Description=System Update Service
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/system-update
User=root
EOF

sudo tee /etc/systemd/system/system-update.timer << 'EOF'
[Unit]
Description=Weekly System Update
Requires=system-update.service

[Timer]
OnCalendar=Sun 02:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable the timer
sudo systemctl enable --now system-update.timer
```

### 2. System Snapshots (BTRFS)

**Configure automatic snapshots:**

```bash
# Install snapper for BTRFS snapshots
sudo dnf install -y snapper

# Configure snapper for root filesystem
sudo snapper -c root create-config /
sudo snapper -c home create-config /home

# Configure automatic snapshots
sudo tee /etc/snapper/configs/root << 'EOF'
SUBVOLUME="/"
FSTYPE="btrfs"
QGROUP=""
SPACE_LIMIT="0.5"
FREE_LIMIT="0.2"
ALLOW_USERS=""
ALLOW_GROUPS=""
SYNC_ACL="no"
NUMBER_CLEANUP="yes"
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="10"
NUMBER_LIMIT_IMPORTANT="10"
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="10"
TIMELINE_LIMIT_DAILY="10"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="10"
TIMELINE_LIMIT_YEARLY="10"
EOF

# Enable snapper timers
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
```

### 3. System Monitoring and Health

**Install monitoring tools:**

```bash
# System monitoring
sudo dnf install -y \
  htop btop iotop \
  smartmontools \
  lm_sensors \
  nvidia-ml-py3

# Configure sensors
sudo sensors-detect --auto

# Create system health check script
tee ~/bin/health-check << 'EOF'
#!/bin/bash

echo "=== System Health Check ==="
echo "Date: $(date)"
echo

echo "=== CPU Temperature ==="
sensors | grep "Core"

echo "=== GPU Temperature ==="
nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits

echo "=== Memory Usage ==="
free -h

echo "=== Disk Usage ==="
df -h | grep -E '^/dev/'

echo "=== System Load ==="
uptime

echo "=== Failed Services ==="
systemctl --failed

echo "=== Recent Errors ==="
journalctl --since "1 hour ago" --priority=err --no-pager | tail -10
EOF

chmod +x ~/bin/health-check
```

### 4. NVIDIA Driver Protection

**Prevent accidental NVIDIA driver breakage:**

```bash
# Pin NVIDIA packages to prevent automatic updates
sudo tee /etc/dnf/protected.d/nvidia.conf << 'EOF'
akmod-nvidia
nvidia-driver
nvidia-driver-libs
nvidia-driver-cuda
nvidia-settings
xorg-x11-drv-nvidia
xorg-x11-drv-nvidia-libs
EOF

# Create NVIDIA update script
sudo tee /usr/local/bin/update-nvidia << 'EOF'
#!/bin/bash

echo "Updating NVIDIA drivers..."

# Create snapshot before NVIDIA update
if command -v snapper >/dev/null 2>&1; then
    snapper create --description "Pre-NVIDIA-update-$(date '+%Y%m%d_%H%M%S')"
fi

# Update NVIDIA packages
dnf update --enablerepo=rpmfusion-nonfree-updates akmod-nvidia nvidia-driver*

# Rebuild kernel modules
akmods --force

echo "NVIDIA update complete. Reboot required."
echo "Run 'sudo reboot' to load new drivers."
EOF

sudo chmod +x /usr/local/bin/update-nvidia
```

## Exit Strategy and Dual Boot

### 1. Windows 11 Installation Preparation

**When you get your new 500GB SSD:**

```bash
# Check current disk layout
lsblk
fdisk -l

# Backup current EFI partition (just in case)
sudo dd if=/dev/nvme0n1p1 of=/home/$USER/efi-backup.img bs=1M

# The new SSD will be /dev/nvme1n1 (second NVMe slot)
# Install Windows 11 on the new SSD
# Use entire disk for Windows
```

**Steps for Windows installation:**

1. **Install new SSD** in second slot
2. **Boot from Windows 11 installation media**
3. **Install Windows on new SSD** (full disk)
4. **Update GRUB** to detect Windows:

   ```bash
   sudo grub2-mkconfig -o /boot/grub2/grub.cfg
   ```

### 2. GRUB Configuration for Dual Boot

**Configure GRUB for optimal dual boot experience:**

```bash
# Edit GRUB configuration
sudo vim /etc/default/grub

# Recommended settings:
GRUB_TIMEOUT=10
GRUB_DEFAULT=0
GRUB_SAVEDEFAULT=true
GRUB_DISABLE_OS_PROBER=false

# Update GRUB
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

### 3. Data Sharing Between Systems

**Create shared data partition:**

```bash
# Create NTFS partition for shared data (on either SSD)
sudo fdisk /dev/nvme0n1  # or nvme1n1

# Format as NTFS
sudo mkfs.ntfs -f /dev/nvme0n1pX

# Create mount point
sudo mkdir /mnt/shared

# Add to fstab for automatic mounting
echo '/dev/nvme0n1pX /mnt/shared ntfs-3g defaults,uid=1000,gid=1000,umask=022 0 0' | sudo tee -a /etc/fstab

# Mount the partition
sudo mount -a
```

### 4. System Backup Strategy

**Complete system backup before dual boot:**

```bash
# Create full system backup
sudo tee /usr/local/bin/full-backup << 'EOF'
#!/bin/bash

BACKUP_DIR="/mnt/external/fedora-backup-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup root filesystem (excluding unnecessary directories)
sudo rsync -aAXv / "$BACKUP_DIR/root/" \
  --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found}

# Backup home directory
rsync -aAXv /home/ "$BACKUP_DIR/home/"

# Backup package list
dnf list installed > "$BACKUP_DIR/installed-packages.txt"

# Backup configurations
cp -r /etc "$BACKUP_DIR/etc-backup"

echo "Backup completed: $BACKUP_DIR"
EOF

sudo chmod +x /usr/local/bin/full-backup
```

## Troubleshooting

### 1. NVIDIA Issues

**NVIDIA driver not loading:**

```bash
# Check driver status
modinfo nvidia
lsmod | grep nvidia

# Rebuild kernel modules
sudo akmods --force
sudo dracut --force

# Check for conflicts
dmesg | grep -i nvidia

# Reinstall if necessary
sudo dnf reinstall akmod-nvidia
```

**Performance issues:**

```bash
# Check power management
cat /proc/driver/nvidia/gpus/*/power/runtime_status

# Reset power management
sudo systemctl restart nvidia-powerd

# Check GPU utilization
nvidia-smi dmon -s pucvmet -d 2
```

### 2. Audio Issues

**No audio output:**

```bash
# Check audio devices
pactl list short sinks

# Restart PulseAudio
systemctl --user restart pulseaudio

# Check for muted channels
amixer
alsamixer
```

**Bluetooth audio problems:**

```bash
# Restart Bluetooth service
sudo systemctl restart bluetooth

# Re-pair device
bluetoothctl
> scan on
> pair XX:XX:XX:XX:XX:XX
> connect XX:XX:XX:XX:XX:XX
```

### 3. Network Issues

**WiFi connectivity problems:**

```bash
# Check network interfaces
ip link show

# Restart NetworkManager
sudo systemctl restart NetworkManager

# Check driver status
lspci -nnk | grep -iA2 net

# Reset network stack
sudo nmcli networking off
sudo nmcli networking on
```

### 4. Boot Issues

**GRUB rescue mode:**

```bash
# From GRUB rescue prompt
grub rescue> ls
grub rescue> set root=(hd0,gpt2)  # Adjust based on your setup
grub rescue> linux /vmlinuz root=/dev/nvme0n1p4 ro
grub rescue> initrd /initramfs
grub rescue> boot
```

**Kernel panic after updates:**

```bash
# Boot from previous kernel (use GRUB menu)
# Rollback to previous snapshot
sudo snapper rollback

# Or manually restore
sudo btrfs subvolume snapshot /.snapshots/X/snapshot /
```

### 5. Performance Issues

**System feels slow:**

```bash
# Check system resources
htop
iotop -ao

# Check for thermal throttling
sensors
journalctl | grep -i thermal

# Disable unnecessary services
sudo systemctl disable bluetooth  # if not needed
sudo systemctl disable cups       # if no printer
```

### 6. Package Management Issues

**DNF is slow:**

```bash
# Clear DNF cache
sudo dnf clean all

# Rebuild cache
sudo dnf makecache

# Use fastest mirror
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.fedoraproject.org/pub/fedora/linux/releases/
```

**Dependency conflicts:**

```bash
# Check for conflicts
sudo dnf check

# Force reinstall problematic package
sudo dnf reinstall PACKAGE_NAME

# Downgrade if needed
sudo dnf downgrade PACKAGE_NAME
```

## Quick Reference Commands

### Essential Commands

```bash
# System update (manual)
sudo dnf update

# Install package
sudo dnf install PACKAGE_NAME

# Search for package
dnf search KEYWORD

# Package information
dnf info PACKAGE_NAME

# List installed packages
dnf list installed

# Check system health
~/bin/health-check

# Create snapshot
sudo snapper create --description "Manual snapshot"

# List snapshots
sudo snapper list

# Update NVIDIA drivers
sudo /usr/local/bin/update-nvidia
```

### Emergency Recovery

```bash
# Boot to previous kernel from GRUB menu
# Rollback system snapshot
sudo snapper rollback

# Reinstall NVIDIA drivers
sudo dnf reinstall akmod-nvidia
sudo akmods --force
sudo dracut --force

# Reset user configurations
mv ~/.config ~/.config.backup
./unix/setup.sh --stow-all
```

## Additional Resources

- **Fedora Documentation**: [https://docs.fedoraproject.org/](https://docs.fedoraproject.org/)
- **RPM Fusion**: [https://rpmfusion.org/](https://rpmfusion.org/)
- **Fedora Magazine**: [https://fedoramagazine.org/](https://fedoramagazine.org/)
- **Ask Fedora**: [https://ask.fedoraproject.org/](https://ask.fedoraproject.org/)
- **NVIDIA Linux Drivers**: [https://www.nvidia.com/en-us/drivers/unix/](https://www.nvidia.com/en-us/drivers/unix/)
- **KDE Documentation**: [https://docs.kde.org/](https://docs.kde.org/)
- **Arch Wiki** (general Linux info): [https://wiki.archlinux.org/](https://wiki.archlinux.org/)

---

**Remember**: This setup prioritizes stability over bleeding-edge features. Take snapshots before major changes, keep NVIDIA drivers pinned, and update manually during low-activity periods.

---

This guide has been generated by an AI based on the prompts and information provided. It is recommended to review and adapt the steps according to your specific hardware and software requirements. Always ensure you have backups before making significant changes to your system.
