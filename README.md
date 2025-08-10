# Configs

This repo contains all of my development configs. I never had a backup of these before and hence this repo.

## Contents

Check repo [tree](./docs/TREE.md) to get list of file contents.

## One line installer

### If the machine runs Windows, execute below command in [powershell](https://github.com/PowerShell/PowerShell)

> [!NOTE]
> If this is a fresh Windows installation, it is recommended to re-do the Windows installation with `MicroWin`:
>
> 1. Download the latest Windows 11 (recommended) ISO (international edition)
> 2. Open winutil (in elevated powershell, execute the following command: `irm "christitus.com/win" | iex`) and go to `MicroWin` tab
> 3. Follow the instructions (do not select any drivers or inject them)
> 4. Wait until ISO is created. Use `Rufus` to make a bootable drive
> 5. Re-do the installation by booting from USB (Change boot priority in `UEFI` menu)

```pwsh
irm "https://github.com/pixincreate/configs/raw/main/windows/powershell/setup.ps1" | iex
```

### Modern Python-based Setup System

> [!NOTE]
> The setup system has been completely rewritten in Python for better maintainability, error handling, and cross-platform support. It supports `WSL`, `Debian`, `Fedora`, `macOS`, and `Android/Termux`.

**Prerequisites:** Python 3.8+ is required. The setup script will automatically install Python dependencies.

If running on Windows with networking tools like [Portmaster](https://safing.io), WSL may have networking issues. Run this first in WSL:

```sh
echo 'nameserver 9.9.9.9' | sudo tee -a /etc/resolv.conf
```

> [!WARNING]
> If tools like Docker have connection issues, temporarily disable Portmaster.

**Quick Setup (All Platforms):**

First, clone the repository:

```sh
# Install prerequisites first
# For Debian/Ubuntu/WSL:
sudo apt-get update && sudo apt-get install -y curl git wget zsh python3 python3-pip

# For Fedora:
sudo dnf install -y curl git wget zsh python3 python3-pip

# For macOS (install Homebrew first if needed):
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git python3

# For Android/Termux:
pkg update && pkg upgrade -y && pkg install -y curl git wget zsh python3

# Clone the repository
git clone https://github.com/pixincreate/configs.git ~/Dev/.configs
cd ~/Dev/.configs

# Run the interactive setup
./scripts/setup --full-setup
```

**Advanced Usage:**

```sh
# Show all options
./scripts/setup --help

# Dry run (see what would be done without making changes)
./scripts/setup --dry-run --full-setup

# Install only specific components
./scripts/setup --install-packages    # Install packages only
./scripts/setup --setup-fonts         # Install fonts only
./scripts/setup --setup-git           # Setup Git configuration only
./scripts/setup --stow-configs        # Stow dotfiles only
./scripts/setup --setup-zsh           # Setup Zsh only

# Force mode (skip confirmations)
./scripts/setup --full-setup --force
```

**Platform-Specific Features:**

**🐧 Fedora KDE Complete Setup:**

- 🎮 **NVIDIA driver support** with automatic hardware detection
- 🛠 **Complete development environment** (Rust, Node.js, Python, Java, C/C++)
- 📱 **ASUS laptop utilities** (ROG gaming laptops)
- 🔋 **TLP power management** with service optimization
- 🎬 **Multimedia codecs** (FFmpeg, Intel/NVIDIA VA-API)
- 📦 **Flatpak applications** with automatic Flathub setup
- 🔒 **NextDNS integration** (optional)
- 📊 **System health monitoring** (`scripts/health-check.sh`)

**🍎 macOS Setup:**

- 🍺 **Homebrew integration** with automatic installation
- 📱 **macOS-specific applications** via Homebrew Casks
- ⚙️ **System optimizations** and developer tools

**🐧 Debian/Ubuntu Setup:**

- 📦 **APT package management** with repository updates
- 🛠 **Development tools** and libraries
- 🔧 **System configuration** and optimizations

**🤖 Android/Termux Setup:**

- 📱 **Termux-specific packages** and storage setup
- 🔧 **Development environment** for mobile development
- 🎯 **Android-optimized configurations**

#### Vanguard Controller

To learn about what Vanguard controller is and how to use it, refer to [Vanguard Controller](./docs/VANGUARD.md)

## Credits

- SanchithHegde for [dotfiles](https://github.com/SanchithHegde/dotfiles)
- Chris Titus for [powershell-profile](https://github.com/ChrisTitusTech/powershell-profile), [bash-profile](https://github.com/ChrisTitusTech/mybash) and [winutil](https://github.com/ChrisTitusTech/winutil)
- Mike Battista for [Powershell - WSL Interop](https://github.com/mikebattista/PowerShell-WSL-Interop)
- AndrewMast for [disable_vanguard.vbs](https://gist.github.com/AndrewMast/742ac7e07c37096017e907b0fd8ec7bb?permalink_comment_id=4616472#gistcomment-4616472)
