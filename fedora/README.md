# Fedora Linux KDE Setup

This directory contains scripts and configurations for setting up Fedora Linux KDE with a complete development environment, gaming setup, and Kanagawa Dragon theming.

## Features

- 🎮 **NVIDIA GTX 1650Ti support** with stable drivers
- 🛠 **Complete development environment** (Rust, Node.js, Python, Java, C/C++)
- 🎨 **Kanagawa Dragon theme** system-wide
- 📦 **Single source of truth** for package management
- 🔒 **Stability-first approach** - nothing breaks with updates
- 🎯 **Gaming setup** with Steam, Lutris, and optimizations
- 🎬 **DaVinci Resolve** ready for video editing
- 🔧 **ASUS laptop utilities** (if applicable)
- 🛡️ **NextDNS** privacy protection

## Quick Start

### Option 1: Direct Fedora Setup (Recommended)

If you already have Fedora KDE installed and want to run the complete setup:

```bash
# Clone the repository
git clone https://github.com/pixincreate/configs.git ~/Dev/scripts/.configs
cd ~/Dev/scripts/.configs

# Run the Fedora-specific setup
chmod +x fedora/setup-fedora.sh
./fedora/setup-fedora.sh
```

### Option 2: Using the Main Setup Script

If you want to use the main setup script that will detect Fedora and call the appropriate scripts:

```bash
# Clone the repository
git clone https://github.com/pixincreate/configs.git ~/Dev/scripts/.configs
cd ~/Dev/scripts/.configs

# Run the main setup script
chmod +x unix/setup.sh
./unix/setup.sh --setup
```

### Option 3: Individual Components

You can also run individual components:

```bash
# Only install applications
./unix/setup.sh --install

# Only setup configurations
./unix/setup.sh --config-setup

# Only setup git
./unix/setup.sh --git-setup
```

## What Gets Installed

### Base System Utilities

- Modern CLI tools: `bat`, `eza`, `ripgrep`, `fzf`, `zoxide`
- Development essentials: `git`, `wget`, `curl`, `vim`, `neovim`
- System monitoring: `htop`, `btop`, `fastfetch`
- Terminal utilities: `tmux`, `tree`, `xclip`, `stow`

### Development Environment

- **Languages**: Rust, Node.js, Python, Java, C/C++
- **Tools**: VS Code, Docker, kubectl, PostgreSQL, Redis
- **Rust tools**: cargo-wipe, eza, just, diesel_cli

### Gaming & Media

- **Gaming**: Steam, Lutris, Wine, GameMode, MangoHUD
- **Media**: VLC, FFmpeg, GStreamer plugins
- **Video editing**: DaVinci Resolve (via Flatpak)

### Applications (via Flatpak)

- **Browsers**: Zen Browser, Brave
- **Development**: Zed editor
- **Communication**: Signal, Thunderbird
- **Productivity**: Obsidian, OnlyOffice, Bitwarden
- **Media**: OBS Studio, Blender

## Hardware-Specific Features

### NVIDIA Support

Automatically detects and installs:

- NVIDIA proprietary drivers
- CUDA support
- Power management services
- Hibernation support

### ASUS Laptop Support

If running on an ASUS laptop, automatically installs:

- `asusctl` for hardware control
- `supergfxctl` for hybrid graphics
- ROG Control Center GUI
- RGB lighting configuration

## Configuration Details

### Shell Configuration

The setup configures Zsh with:

- **Aliases**: Modern CLI replacements (ls→eza, cat→bat, etc.)
- **Environment**: Proper PATH, JAVA_HOME, Rust environment
- **DNF shortcuts**: Quick package management
- **Git aliases**: Streamlined git workflow

### System Services

Automatically configures:

- PostgreSQL database
- Redis server
- Docker daemon
- NVIDIA services (if applicable)

### Privacy & Security

- **NextDNS**: DNS-level ad blocking and privacy
- **Hardened Firefox**: Via arkenfox user.js (manual setup)
- **Flatpak sandboxing**: Isolated applications

## Customization

### Package Lists

Package lists are organized in `fedora/packages/`:

- `base-system.txt`: Core system utilities
- `development.txt`: Development tools and languages
- `media.txt`: Media and multimedia packages
- `gaming.txt`: Gaming-related packages
- `flatpaks.txt`: Flatpak applications

You can edit these files before running the setup to customize what gets installed.

### COPR Repositories

The script enables these COPR repositories:

- `lilay/topgrade`: System updater
- `wezfurlong/wezterm-nightly`: Modern terminal
- `lukenukem/asus-linux`: ASUS laptop utilities

### External Repositories

- **RPM Fusion**: For multimedia codecs and proprietary software
- **Microsoft**: For VS Code
- **NextDNS**: For DNS privacy tools

## Post-Installation

After running the setup:

1. **Reboot your system** to ensure all drivers and services are loaded
2. **Verify NVIDIA drivers** (if applicable):

   ```bash
   sudo cat /sys/module/nvidia_drm/parameters/modeset
   # Should return 'Y'
   ```

3. **Configure NextDNS** with your config ID when prompted
4. **Install KDE themes manually** from the KDE Store for Kanagawa Dragon
5. **Configure development environments** as needed

## Troubleshooting

### Common Issues

**DNF package conflicts:**

```bash
sudo dnf distro-sync
```

**Flatpak permission issues:**

```bash
flatpak repair --user
```

**NVIDIA driver issues:**

```bash
# Reinstall drivers
sudo dnf reinstall akmod-nvidia xorg-x11-drv-nvidia-cuda
sudo dracut --force
reboot
```

**Docker permission denied:**

```bash
# Log out and back in, or:
newgrp docker
```

### Package Management

**Update everything:**

```bash
topgrade
```

**Clean up:**

```bash
sudo dnf autoremove && flatpak uninstall --unused
```

## Requirements

- **OS**: Fedora Linux (KDE Plasma recommended)
- **Hardware**:
  - 8GB+ RAM recommended
  - NVIDIA GPU (optional, auto-detected)
  - ASUS laptop (optional, auto-detected)
- **Network**: Internet connection for downloading packages
- **Storage**: ~10GB free space for full installation

## Safety Features

- **Rollback capability**: All changes are logged
- **Non-destructive**: Won't overwrite existing configurations without warning
- **Hardware detection**: Only installs relevant drivers
- **Error handling**: Continues on non-critical failures
- **Dry-run option**: Review changes before applying (planned feature)

## Contributing

To modify or extend the setup:

1. Edit package lists in `fedora/packages/`
2. Modify functions in `fedora/setup-fedora.sh`
3. Test changes in a VM first
4. Submit pull requests with clear descriptions

## License

This setup script is part of the larger configs repository and follows the same license terms.

---

**Note**: This setup is based on the user's specific requirements for a privacy-focused, development-ready Fedora system with gaming capabilities and ASUS laptop support. Adjust the configuration files as needed for your specific use case.
