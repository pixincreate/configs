# 🎯 Personal Development Environment Configurations

A comprehensive dotfiles and system setup repository for multi-platform development environments. This repository contains configuration files, setup scripts, and automation tools to quickly bootstrap a development environment on any supported platform.

## 🚀 Quick Start

**One-liner setup (Unix/Linux/macOS):**

> [!NOTE]
> This assumes you've installed Python 3 and Git on your system already. If note, see the [Prerequisites](#prerequisites) section below.

```bash
git clone --recurse-submodules https://github.com/pixincreate/configs.git ~/Dev/.configs && ~/Dev/.configs/unix/setup.py --full-setup
```

## 🖥️ Supported Platforms

- **macOS** - Complete setup with Homebrew and Cask applications
- **Fedora Linux** - System configuration with DNF and Flatpak packages
- **Debian/Ubuntu** - APT packages with optional Homebrew tools
- **Android (Termux)** - Termux-specific package and tool setup
- **Windows** - PowerShell scripts and registry configurations

---

## 🐧 Unix/Linux/macOS Setup

### Prerequisites

- **Python 3.6+** (usually pre-installed)
- **Git** (for cloning repository)
- **Internet connection** (for downloading packages)

The setup script automatically installs required Python dependencies (`toml`, `rich`) if not present.

To install the prerequisites, run:

```bash
# On Debian/Ubuntu
sudo apt-get update && sudo apt-get install -y python3 git zsh curl wget
# On Fedora
sudo dnf update && sudo dnf install -y python3 git zsh curl wget
# On macOS (Homebrew required)
brew install python git zsh curl wget
# On Android (Termux)
pkg install python git zsh curl wget
```

### Setup Script (`unix/setup.py`)

A modern Python-based setup script that replaces traditional shell scripts with:

#### ✨ Key Features

- **🎨 Beautiful Interface** - Rich terminal output with colors, progress bars, and emoji
- **🔍 Dry Run Mode** - Preview changes before applying them
- **🎯 Platform Detection** - Automatically detects and configures for your OS
- **📦 Multi Package Manager** - Supports brew, dnf, apt, flatpak, pkg (Termux)
- **🔧 Modular Design** - Run full setup or individual components
- **⚙️ Conflict Resolution** - Interactive handling of file conflicts

#### 🎛️ Usage

**Full environment setup:**

```bash
unix/setup.py --full-setup
```

**Preview what will be installed:**

```bash
unix/setup.py --dry-run --full-setup
unix/setup.py --dry-run install --category terminal
```

**Install specific package categories:**

```bash
unix/setup.py install --category terminal     # Terminal tools only
unix/setup.py install --category gui          # GUI applications only
unix/setup.py install                         # All packages
```

**Individual setup components:**

```bash
unix/setup.py git-config                      # Git identity & SSH keys
unix/setup.py fonts                           # Install fonts
unix/setup.py zsh                             # ZSH configuration
unix/setup.py stow                            # Link all dotfiles
unix/setup.py stow --package zsh              # Link specific dotfiles
unix/setup.py services                        # System services (Fedora only)
```

**Advanced options:**

```bash
unix/setup.py --verbose install               # Detailed output
unix/setup.py --help                          # Show all options
```

### 🔧 What It Does

1. **Repository Management** - Clones repo with submodules if not present
2. **Platform Detection** - Identifies macOS, Fedora, Debian, or Android
3. **Package Installation** - Installs development tools and applications
4. **Git Configuration** - Sets up Git identity and SSH keys with GitHub integration
5. **Font Installation** - Copies fonts to system font directory
6. **Shell Setup** - Configures ZSH with platform-specific settings
7. **Dotfiles Management** - Uses GNU Stow to symlink configuration files
8. **Service Configuration** - Enables system services (PostgreSQL, Redis, Docker)

### 📋 Package Categories

The script installs packages based on your platform from `unix/packages.toml`:

**Terminal Tools:**

- Development: `git`, `neovim`, `tmux`, `zsh`
- File Management: `bat`, `eza`, `fzf`, `tree`, `zoxide`
- System: `htop`, `fastfetch`, `croc`, `stow`
- Languages: `python`, `node`, `rustup`, `gcc`

**GUI Applications:**

- **macOS**: VS Code, Brave Browser, Zen Browser, Obsidian, Rectangle
- **Fedora**: Flatpak apps from Flathub (Brave, Zed, Signal, OBS Studio)

### 🛠️ Platform-Specific Features

#### macOS

- **Homebrew** installation and management
- **Cask applications** for GUI software
- **GNU tools** to replace BSD versions
- **Development environment** optimization

#### Fedora Linux

- **System repositories** (COPR, RPM Fusion, external repos)
- **Hardware drivers** (NVIDIA, ASUS utilities)
- **Multimedia support** (ffmpeg, codecs)
- **Flatpak applications** from Flathub
- **System services** (PostgreSQL, Redis, Docker)

#### Debian/Ubuntu

- **APT packages** for system tools
- **Homebrew** for additional development tools
- **WSL integration** (Windows Subsystem for Linux)

#### Android (Termux)

- **Termux packages** via pkg manager
- **Development tools** adapted for mobile
- **Backup/restore** aliases for Termux data

---

## 🪟 Windows Setup

### PowerShell Scripts

Located in `windows/powershell/` - Collection of PowerShell scripts for Windows environment setup.

### Registry Modifications

Located in `windows/registry_edits/` - Registry files for system customization and optimization.

### Theme Configuration

Located in `windows/theme/` - Windows theming and appearance customization files.

### Tools and Utilities

Located in `windows/tools/` - Portable tools and utilities for Windows development.

---

## 📝 Configuration Management

## Dotfiles (GNU Stow)

Dotfiles are organized in `home/` directory and managed using [GNU Stow](https://www.gnu.org/software/stow/):

```bash
home/
├── config/    # Application configs (~/.config/)
├── git/       # Git configuration (~/.gitconfig)
├── ssh/       # SSH configuration (~/.ssh/)
├── vscode/    # VS Code settings
├── zsh/       # ZSH shell configuration (~/.zsh/)
└── wallpaper/ # Desktop wallpapers
```

**Manual stow management:**

```bash
# From repository root
cd home
stow config     # Link ~/.config/ files
stow zsh        # Link ZSH configuration
stow --delete zsh  # Remove ZSH links
```

### Package Configuration

All package lists are centralized in `unix/packages.toml` using TOML format for easy maintenance:

```toml
[platforms.macos.terminal_tools]
common = ["git", "zsh", "neovim", "fzf"]
specific = ["gnu-sed", "openjdk"]

[platforms.fedora.gui_apps]
flatpak = ["com.brave.Browser", "dev.zed.Zed"]
```

### Git Configuration

The setup script configures Git with:

- **User identity** (name and email)
- **SSH key generation** (ed25519)
- **GitHub integration** (optional key upload via API)
- **Repository URL conversion** (HTTPS → SSH)

---

## 🔧 Customization

### Adding New Packages

Edit `unix/packages.toml` to add packages for your platform:

```toml
[platforms.your_platform.terminal_tools]
your_package_manager = ["new-package-name"]
```

### Platform-Specific Settings

The setup script creates `~/.zsh/.additionals.zsh` with platform-specific configurations:

- **macOS**: Homebrew paths, development tools
- **Fedora**: System aliases, health check tools
- **Debian**: WSL integration, build tools
- **Android**: Termux-specific aliases and paths

### Custom Configuration

Add your personal settings to dotfiles in `home/` directory. The setup script preserves user customizations during updates.

---

## 🐛 Troubleshooting

## Common Issues

**Permission errors:**

```bash
chmod +x unix/setup.py  # Make script executable
```

**Missing Python dependencies:**

```bash
pip install --user toml rich  # Install manually
```

**Stow conflicts:**
The script will prompt you to resolve conflicts automatically or skip conflicting files.

**Platform detection issues:**
Check that your system has the expected platform files (e.g., `/etc/fedora-release` for Fedora).

## Getting Help

```bash
unix/setup.py --help           # Show all options
unix/setup.py install --help   # Show install options
```

### Dry Run Testing

Always test with dry run mode first:

```bash
unix/setup.py --dry-run --full-setup
```

---

## 🎉 Post-Setup

After running the setup:

1. **Reboot** your system (especially on Fedora after driver installation)
2. **Verify Git**: `git config --global --list`
3. **Test SSH**: `ssh -T git@github.com`
4. **Check fonts**: `fc-list | grep -i your-font`
5. **Reload shell**: `exec zsh` or open new terminal

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

This is a personal configuration repository, but feel free to:

- Fork and adapt for your own use
- Submit issues for bugs or improvements
- Share your own configuration ideas
