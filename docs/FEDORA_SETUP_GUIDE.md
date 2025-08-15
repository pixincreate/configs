# Fedora Linux Complete Setup Guide

> **Comprehensive Manual Setup Guide Based on `unix/setup.py`**
>
> This guide mirrors exactly what the automated setup script does. If you want to perform the setup manually instead of running the script, follow this guide step-by-step.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [System Preparation](#system-preparation)
- [Repository Configuration](#repository-configuration)
- [System Updates and Firmware](#system-updates-and-firmware)
- [Package Installation](#package-installation)
- [Multimedia and Hardware Acceleration](#multimedia-and-hardware-acceleration)
- [NVIDIA Configuration](#nvidia-configuration)
- [ASUS System Optimization](#asus-system-optimization)
- [Development Environment](#development-environment)
- [Git Configuration and SSH](#git-configuration-and-ssh)
- [Font Installation](#font-installation)
- [ZSH Configuration](#zsh-configuration)
- [Dotfiles Management](#dotfiles-management)
- [System Services](#system-services)
- [Performance Optimizations](#performance-optimizations)
- [Directory Structure](#directory-structure)
- [Troubleshooting](#troubleshooting)

## Overview

This guide provides step-by-step manual instructions for setting up a complete Fedora development environment. It covers everything from system repositories to development tools, multimedia support, and hardware optimization.

### What This Guide Covers

- ✅ **Complete repository setup** (RPM Fusion, COPR, external repos)
- ✅ **Intelligent hardware detection** (Intel/AMD/NVIDIA graphics)
- ✅ **Multimedia optimization** (official Fedora recommendations)
- ✅ **ASUS laptop support** with CachyOS kernel
- ✅ **Development environment** (Git, SSH, dotfiles)
- ✅ **Performance tuning** (boot optimization, CPU settings)
- ✅ **Service configuration** (Docker, PostgreSQL, Redis)

### Equivalent Script Command

Instead of following this manual guide, you can run:

```bash
cd ~/Dev/.configs
unix/setup.py --full-setup
```

## Prerequisites

### System Requirements

- Fedora Linux (any recent version)
- Internet connection
- Sudo privileges
- At least 8GB RAM (16GB recommended)
- 50GB free disk space

### Installation Media Preparation

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

### UEFI/BIOS Settings

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

1. **Update your system first:**

   ```bash
   sudo dnf update -y --refresh
   sudo reboot
   ```

2. **Install essential tools:**

   ```bash
   sudo dnf install -y curl wget git vim nano htop tree
   ```

## System Preparation

### 1. Create Essential Directories

```bash
# Create configuration directories
mkdir -p ~/.config
mkdir -p ~/.ssh
mkdir -p ~/.zsh
mkdir -p ~/.zsh/.zgenom
mkdir -p ~/Pictures/Wallpapers
mkdir -p ~/Pictures/Screenshots
mkdir -p ~/.local/share/fonts

# For Android/Termux users only
# mkdir -p ~/.rish
```

### 2. Clone Configuration Repository

```bash
# Create development directory structure
mkdir -p ~/Dev

# Clone the configs repository
cd ~/Dev
git clone --recurse-submodules https://github.com/pixincreate/configs.git .configs
cd .configs
```

## Repository Configuration

### 1. Enable RPM Fusion Repositories

```bash
# Install RPM Fusion Free and Non-Free repositories
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Enable Cisco OpenH264 repository
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
```

### 2. Add Terra Repository

```bash
# Install Terra repository for additional packages
sudo dnf install -y \
  --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
```

### 3. Enable COPR Repositories

```bash
# Enable essential COPR repositories
sudo dnf copr enable -y atim/starship
sudo dnf copr enable -y lilay/topgrade
sudo dnf copr enable -y lukenukem/asus-linux
sudo dnf copr enable -y wezfurlong/wezterm-nightly
sudo dnf copr enable -y bieszczaders/kernel-cachyos
```

### 4. Add External Repositories

**NextDNS Repository:**

```bash
sudo curl -Ls https://repo.nextdns.io/nextdns.repo -o /etc/yum.repos.d/nextdns.repo
```

**Microsoft Visual Studio Code:**

```bash
# Import Microsoft GPG key
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

# Add VS Code repository
sudo tee /etc/yum.repos.d/vscode.repo << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
```

**Tailscale Repository:**

```bash
sudo dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
```

### 5. Update Repository Cache

```bash
sudo dnf update -y --refresh
```

## System Updates and Firmware

### 1. Set System Hostname

```bash
# Set your desired hostname (replace 'your-hostname' with your preferred name)
sudo hostnamectl set-hostname your-hostname
```

### 2. Update System Firmware

```bash
# Install firmware update tools
sudo dnf install -y fwupd

# Refresh firmware metadata
sudo fwupdmgr refresh --force

# Check for available firmware updates
sudo fwupdmgr get-devices
sudo fwupdmgr get-updates

# Apply firmware updates (if available)
sudo fwupdmgr update
```

### 3. Setup AppImage Support

```bash
# Install FUSE for AppImage compatibility
sudo dnf install -y fuse
```

## Package Installation

### 1. Terminal Tools (Common + Platform Specific)

**Common Development Tools:**

```bash
sudo dnf install -y \
  htop btop tealdeer git wget curl zsh vim neovim micro bat direnv \
  fastfetch fzf git-delta jq pipx ripgrep tar tmux tree xclip zoxide \
  croc openssh atuin topgrade starship gh coreutils binutils protobuf \
  nextdns gcc node python rustup sqlite ollama llvm ffmpeg parallel \
  redis docker kubectl uv grpc stow
```

**Fedora-Specific Tools:**

```bash
sudo dnf install -y \
  java-latest-openjdk postgresql-server postgresql-devel code \
  dnf-plugins-core btrfs-assistant lm_sensors pkg-config dpkg tailscale
```

### 2. GUI Applications (Flatpak)

**Enable Flathub:**

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

**Install Applications:**

```bash
# Install GUI applications via Flatpak
flatpak install -y flathub app.zen_browser.zen
flatpak install -y flathub com.brave.Browser
flatpak install -y flathub dev.zed.Zed
flatpak install -y flathub org.signal.Signal
flatpak install -y flathub md.obsidian.Obsidian
flatpak install -y flathub org.localsend.localsend_app
flatpak install -y flathub com.bitwarden.desktop
flatpak install -y flathub org.onlyoffice.desktopeditors
flatpak install -y flathub com.obsproject.Studio
flatpak install -y flathub org.mozilla.Thunderbird
flatpak install -y flathub org.davinci.DaVinciResolve
flatpak install -y flathub com.valvesoftware.Steam
```

## Multimedia and Hardware Acceleration

### 1. Install Multimedia Group

```bash
# Install official Fedora multimedia group
sudo dnf group install -y multimedia

# Swap to full FFmpeg (with all codecs)
sudo dnf swap ffmpeg-free ffmpeg --allowerasing

# Update multimedia packages
sudo dnf groupupdate multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf groupupdate sound-and-video

# Install essential multimedia libraries
sudo dnf install -y ffmpeg-libs libva libva-utils
```

### 2. Install Additional Codecs

```bash
# Install GStreamer plugins and codecs
sudo dnf install -y \
  gstreamer1-plugins-bad-* gstreamer1-plugins-good-* gstreamer1-plugins-base \
  gstreamer1-plugin-openh264 gstreamer1-libav

# Install LAME for MP3 encoding
sudo dnf install -y lame* --exclude=lame-devel

# Enable and install OpenH264 for browsers
sudo dnf config-manager --set-enabled fedora-cisco-openh264
sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264
```

### 3. Hardware Acceleration Setup

**Check for Intel Graphics:**

```bash
# Check if Intel graphics are present
if lspci | grep -i intel.*graphics; then
    echo "Intel graphics detected, installing drivers..."
    sudo dnf swap libva-intel-media-driver intel-media-driver --allowerasing
    echo "Intel hardware acceleration configured"
else
    echo "No Intel graphics detected"
fi
```

**Check for AMD Graphics:**

```bash
# Check if AMD graphics are present
if lspci | grep -i amd.*graphics; then
    echo "AMD graphics detected, installing drivers..."
    sudo dnf install -y mesa-va-drivers mesa-vdpau-drivers
    echo "AMD hardware acceleration configured"
else
    echo "No AMD graphics detected"
fi
```

**Check for NVIDIA Graphics:**

```bash
# Check if NVIDIA graphics are present
if lspci | grep -i nvidia; then
    echo "NVIDIA graphics detected, installing VAAPI drivers..."
    sudo dnf install -y libva-nvidia-driver.{i686,x86_64}
    echo "NVIDIA VAAPI driver installed"
else
    echo "No NVIDIA graphics detected"
fi
```

## NVIDIA Configuration

### 1. Install NVIDIA Drivers (if NVIDIA GPU detected)

```bash
# Only run this section if you have NVIDIA graphics
# Check first: lspci | grep -i nvidia

# Install kernel development headers
sudo dnf install -y kernel-devel

# Install NVIDIA drivers and CUDA support
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda

# Install NVIDIA settings GUI
sudo dnf install -y nvidia-settings

# Install 32-bit libraries for gaming
sudo dnf install -y xorg-x11-drv-nvidia-libs.i686

# Install additional NVIDIA tools
sudo dnf install nvidia-vaapi-driver vdpauinfo

# Force rebuild of kernel modules
sudo akmods --force

# Enable NVIDIA services
sudo systemctl enable nvidia-hibernate.service nvidia-suspend.service nvidia-resume.service nvidia-powerd.service

# Enable NVIDIA modeset (for better compatibility)
sudo grubby --update-kernel=ALL --args="nvidia-drm.modeset=1"

echo "NVIDIA drivers installed. Reboot required to activate."
```

## ASUS System Optimization

### 1. ASUS Hardware Detection and Basic Setup

```bash
# Only run this section if you have an ASUS system
# Check first: sudo dmidecode -s system-manufacturer | grep -i asus

# Install basic ASUS utilities
sudo dnf install -y asusctl supergfxctl

# Enable and start ASUS services
sudo systemctl enable supergfxd.service
sudo systemctl start asusd
```

### 2. CPU Architecture Check for CachyOS Kernel

```bash
# Check CPU architecture support
echo "Checking CPU architecture support..."
if /lib64/ld-linux-x86-64.so.2 --help | grep "x86_64_v3 (supported, searched)"; then
    echo "✅ CPU supports x86_64_v3 - CachyOS kernel compatible"
    CACHYOS_COMPATIBLE=true
elif /lib64/ld-linux-x86-64.so.2 --help | grep "x86_64_v2 (supported, searched)"; then
    echo "✅ CPU supports x86_64_v2 - can use LTS kernel"
    CACHYOS_COMPATIBLE=true
else
    echo "❌ CPU doesn't support required architecture"
    CACHYOS_COMPATIBLE=false
fi
```

### 3. CachyOS Kernel Installation (if compatible)

```bash
# Only proceed if CACHYOS_COMPATIBLE=true

# Configure SELinux for kernel modules
sudo setsebool -P domain_kernel_load_modules on

# Choose kernel type (standard is recommended for most users)
echo "Choose CachyOS kernel type:"
echo "1) Standard (recommended)"
echo "2) Realtime (lower latency, less stable)"
echo "3) Skip"
read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        echo "Installing standard CachyOS kernel..."
        sudo dnf install -y kernel-cachyos kernel-cachyos-devel-matched
        ;;
    2)
        echo "Installing realtime CachyOS kernel..."
        echo "⚠️  Realtime kernel provides lower latency but may be less stable"
        sudo dnf install -y kernel-cachyos-rt kernel-cachyos-rt-devel-matched
        ;;
    3)
        echo "Skipping CachyOS kernel installation"
        ;;
    *)
        echo "Invalid choice, skipping"
        ;;
esac
```

## Development Environment

### 1. Programming Languages Setup

**Rust:**

```bash
# Rust is typically installed via rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
rustup default stable
```

**Node.js and Python:**

```bash
# Node.js and Python should already be installed from the package list above
# Verify installations:
node --version
python3 --version
java --version
```

## Git Configuration and SSH

### 1. Configure Git Identity

```bash
# Set Git user name (replace with your actual name)
read -p "Enter your Git user.name: " git_name
git config --global user.name "$git_name"

# Set Git user email (replace with your actual email)
read -p "Enter your Git user.email: " git_email
git config --global user.email "$git_email"

# Set Git pull behavior
git config pull.rebase false
```

### 2. Create .gitconfig.local

```bash
# Create directory for gitconfig
mkdir -p ~/.config/gitconfig

# Create local git configuration
cat > ~/.config/gitconfig/.gitconfig.local << EOF
[user]
  name = "$git_name"
  email = "$git_email"
  signingkey = "~/.ssh/id_ed25519_sign.pub"
EOF
```

### 3. Generate SSH Key

```bash
# Create SSH directory
mkdir -p ~/.ssh

# Generate SSH key
ssh-keygen -t ed25519 -C "$git_email" -f ~/.ssh/id_ed25519 -N ""

# Add SSH key to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Display public key for adding to GitHub
echo "📋 Your SSH public key (add this to GitHub → Settings → SSH Keys):"
echo "=================================================================="
cat ~/.ssh/id_ed25519.pub
echo "=================================================================="
```

### 4. Convert Repository Remote to SSH

```bash
# Navigate to configs directory and update remote URL
cd ~/Dev/.configs

# Check current remote
current_remote=$(git remote get-url origin)

# Convert HTTPS to SSH if needed
if [[ "$current_remote" == https://github.com/* ]]; then
    ssh_remote="${current_remote/https:\/\/github.com\//git@github.com:}"
    git remote set-url origin "$ssh_remote"
    echo "✅ Remote URL updated to SSH"
else
    echo "✅ Remote already uses SSH"
fi

git remote -v
```

## Font Installation

```bash
# Copy fonts from the configs repository to system fonts directory
if [ -d "~/Dev/.configs/fonts" ]; then
    # Copy all font files
    find ~/Dev/.configs/fonts -name "*.ttf" -o -name "*.otf" -o -name "*.woff" -o -name "*.woff2" | \
    while read font_file; do
        cp "$font_file" ~/.local/share/fonts/
        echo "Installed font: $(basename "$font_file")"
    done

    # Refresh font cache
    fc-cache -fv
    echo "✅ Font installation completed"
else
    echo "⚠️  Fonts directory not found"
fi
```

## ZSH Configuration

### 1. Install ZGenom (ZSH Plugin Manager)

```bash
# Clone ZGenom
git clone https://github.com/jandamm/zgenom.git ~/.zsh/.zgenom
```

### 2. Update .zshrc

```bash
# Copy the main zshrc configuration
if [ -f "~/Dev/.configs/home/zsh/.zsh/.zshrc" ]; then
    cp ~/Dev/.configs/home/zsh/.zsh/.zshrc ~/.zsh/.zshrc
    echo "✅ .zshrc updated"
else
    echo "⚠️  Source .zshrc not found"
fi
```

### 3. Create Platform-Specific Configuration

```bash
# Create Fedora-specific additional configurations
cat > ~/.zsh/.additionals.zsh << 'EOF'
# Platform-specific configurations

# Fedora specific configurations
export SYS_HEALTH="${HOME}/Dev/.configs/unix/fedora/health-check.sh"
alias cleanup="sudo dnf autoremove && flatpak uninstall --unused"
export CONFIGS=${HOME}/Dev/.configs
EOF

echo "✅ Created .additionals.zsh for Fedora"
```

## Dotfiles Management

### 1. Install GNU Stow

```bash
# Stow should already be installed from the package list
# If not: sudo dnf install -y stow
```

### 2. Stow Configuration Packages

```bash
# Navigate to the configs directory
cd ~/Dev/.configs

# Stow each configuration package
stow_packages=("config" "git" "ssh" "vscode" "zsh" "wallpaper")

for package in "${stow_packages[@]}"; do
    if [ -d "home/$package" ]; then
        echo "Stowing package: $package"
        stow --no-folding --restow --dir=home --target=$HOME $package
        echo "✅ Successfully stowed: $package"
    else
        echo "⚠️  Package directory not found: $package"
    fi
done
```

## System Services

### 1. PostgreSQL Setup

```bash
# Initialize PostgreSQL database
if command -v postgresql-setup >/dev/null; then
    sudo postgresql-setup --initdb
    sudo systemctl enable postgresql.service
    sudo systemctl start postgresql.service
    echo "✅ PostgreSQL configured"
fi
```

### 2. Redis Setup

```bash
# Enable and start Redis
if command -v redis-server >/dev/null; then
    sudo systemctl enable redis.service
    sudo systemctl start redis.service
    echo "✅ Redis configured"
fi
```

### 3. Docker Setup

```bash
# Enable Docker and add user to docker group
if command -v docker >/dev/null; then
    sudo systemctl enable docker.service
    sudo systemctl start docker.service
    sudo usermod -aG docker $USER
    echo "✅ Docker configured (logout/login required for group changes)"
fi
```

## Performance Optimizations

### 1. CPU Mitigations (Optional)

```bash
# Disable CPU mitigations for better performance (less secure)
echo "Disable CPU mitigations for better performance? (Less secure but faster)"
read -p "y/N: " disable_mitigations

if [[ "$disable_mitigations" =~ ^[Yy]$ ]]; then
    sudo grubby --update-kernel=ALL --args="mitigations=off"
    echo "✅ CPU mitigations disabled"
else
    echo "✅ Keeping CPU mitigations enabled for security"
fi
```

### 2. Boot Time Optimization

```bash
# Disable NetworkManager-wait-online.service to improve boot time
sudo systemctl disable NetworkManager-wait-online.service
echo "✅ NetworkManager-wait-online.service disabled (saves ~15-20s boot time)"
```

## Directory Structure

After completing this setup, your directory structure should look like:

```txt
~/
├── .config/
│   ├── gitconfig/
│   │   └── .gitconfig.local
│   └── (other application configs via stow)
├── .ssh/
│   ├── id_ed25519
│   └── id_ed25519.pub
├── .zsh/
│   ├── .zgenom/
│   ├── .zshrc
│   └── .additionals.zsh
├── .local/share/fonts/
│   └── (installed fonts)
├── Pictures/
│   ├── Wallpapers/
│   └── Screenshots/
└── Dev/
    └── .configs/
        ├── unix/
        │   ├── setup.py
        │   └── config.toml
        ├── fonts/
        ├── home/
        └── (other config directories)
```

## Troubleshooting

### 1. NVIDIA Issues

**Driver not loading:**

```bash
# Check driver status
lsmod | grep nvidia
nvidia-smi

# Rebuild kernel modules
sudo akmods --force
sudo dracut --force
sudo reboot
```

**Performance issues:**

```bash
# Check power management
cat /proc/driver/nvidia/gpus/*/power/runtime_status

# Reset power management
sudo systemctl restart nvidia-powerd
```

### 2. Repository Issues

**COPR repository failures:**

```bash
# Disable and re-enable COPR repo
sudo dnf copr disable repo-name
sudo dnf copr enable repo-name
```

**Package conflicts:**

```bash
# Check for conflicts
sudo dnf check

# Force reinstall
sudo dnf reinstall package-name
```

### 3. Service Issues

**Service not starting:**

```bash
# Check service status
sudo systemctl status service-name

# Check logs
sudo journalctl -u service-name

# Reset service
sudo systemctl reset-failed service-name
sudo systemctl restart service-name
```

## Verification Commands

After completing the setup, verify everything is working:

```bash
# Check system info
fastfetch

# Check NVIDIA (if applicable)
nvidia-smi

# Check services
sudo systemctl status postgresql redis docker

# Check ZSH plugins
zsh -c "source ~/.zshrc"

# Check Git configuration
git config --list | grep user

# Check SSH key
ssh-add -l

# Check fonts
fc-list | grep -i "cascadia\|fira"
```

## Final Steps

1. **Reboot your system:**

   ```bash
   sudo reboot
   ```

2. **After reboot, verify:**
   - NVIDIA drivers (if installed): `nvidia-smi`
   - Services: `sudo systemctl status postgresql redis docker`
   - ZSH: Open terminal and check prompt
   - Applications: Test installed Flatpak apps

3. **Set ZSH as default shell:**

   ```bash
   chsh -s $(which zsh)
   ```

## Equivalent Automation

Instead of following this entire manual process, you can achieve the same result by running:

```bash
cd ~/Dev/.configs
unix/setup.py --full-setup
```

The automated script performs all these steps intelligently with hardware detection, error handling, and interactive prompts where needed.

---

**Note:** This guide represents exactly what the `unix/setup.py` script does when run with `--full-setup`. The script includes additional error handling, hardware detection, and dry-run capabilities that make it safer and more convenient than manual execution.
