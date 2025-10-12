# Personal Development Environment

DotfilesCross-platformCross-platformDotfiles and automated automated system setup automationfor macOSFedoraLinuxFedoraLinuxmacOSFedoraLinuxmacOS.

## SupportedPlatformsPlatforms

### Fedora Linux

### Fedora Linux

````bash
# Clone repository
git clone --recurse-submodules https://github.com/yourusername/.configs.git ~/Dev/.configs
cd ~/Dev/.configs/unix/fedora

# Run setup
./fedora-setup

# Non-interactive (for CI/CD)
NON_INTERACTIVE=true ./fedora-setup
gitclone--recurse-submodules https://github.compixincreate/configs.~/Dev/.configscd~/Dev/.configs/unix/fedora./fedorasetupgitclone--recurse-submodules https://github.compixincreate/configs.~/Dev/.configscd~/Dev/.configs/unix/fedora./fedorasetupgitclone--recurse-submodules https://github.compixincreate/configs.~/Dev/.configscd~/Dev/.configs/unix/fedora./fedorasetup```

See### macOS

```bash
# One-liner setup (downloads and runs setup.sh)
curl -fsSL https://raw.githubusercontent.com/yourusername/.configs/main/git clonegit clonegit clone --recurse-submodules https://github.com/pixincreate/configs.git ~/Dev/.configs
cd ~/Dev/.configs/unix/macos
./macosrecurse-submodules https://github.com/pixincreate/configs.git ~/Dev/.configs
cd ~/Dev/.configs/unix/macos
./macosrecurse-submodules https://github.com/pixincreate/configs.git ~/Dev/.configs
cd ~/Dev/.configs/unix/macos
./macos-setup
````

#### What's Included

### Common (Both Platforms)

- Git and SSH setup with ed25519 keys
- NextDNS configuration
- Rust toolchain and cargo tools
- Dotfiles deployment via GNU Stow
- Font installation
- ZSH configuration with platform-specific tweaks

### Fedora-Specific

- DNF optimization and repository management
- Flatpak applications
- Hardware support (ASUS, NVIDIA)
- Performance tuning
- System services (PostgreSQL, Redis, Docker)
- Firmware updates and Secure Boot

### macOS-Specific

- Homebrew installation and management
- Homebrew packages and Cask applications
- Xcode Command Line Tools

## Structure

```
.
├── home/                 # Dotfiles (GNU Stow)
├── fonts/                # Font files
└── unix/
    ├── common/          # Cross-platform scripts
    ├── fedora/          # Fedora setup
    └── macos/           # macOS setup
```

## Configuration

Both platforms use `config.json`:

```json
{
  "system": { "hostname": "your-hostname" },
  "git": {
    "user_name": "Your Name",
    "user_email": "your@email.com"
  },
  "rust": {
    "tools": ["bat", "eza", "ripgrep", "zoxide", "starship"]
  }
}
```

Package lists are plain text files (one per line, `#` for comments).

## Usage

### Adding Packages

### Dotfiles (home/)

Managed with GNU Stow:

- **config/** - Application configs (`~/.config/`)
- **git/** - Git configuration
- **ssh/** - SSH configuration
- **zsh/** - ZSH shell with zgenom plugin manager
- **local/** - Local binaries and scripts
- **Pictures/** - Wallpapers

### Setup Scripts

**Fedora (unix/fedora/)** - Bash-based declarative setup:

- DNF optimization and repositories (RPM Fusion, COPR, external)
- Package installation from categorized plain text lists
- Flatpak applications from Flathub
- Hardware support (ASUS laptops, NVIDIA drivers)
- Performance optimization (zram, fstrim, systemd-oomd)
- Security (Secure Boot, firmware updates)
- Development environment (Git, SSH, Docker, PostgreSQL)
- Dotfiles deployment and ZSH configuration

**Python-based (unix/setup.py)** - Cross-platform setup for macOS/Debian/Android:

- Platform detection and package installation
- Homebrew setup (macOS)
- Git configuration and SSH key generation
- Font installation
- ZSH configuration with platform-specific aliases
- Dotfiles deployment with GNU Stow
- Dry run mode and rich terminal output

### Common Scripts (unix/common/)

Platform-agnostic bash scripts used by both setup systems:

- **config/git.sh** - Git and SSH key setup
- **config/nextdns.sh** - NextDNS configuration
- **dotfiles/stow.sh** - GNU Stow deployment
- **dotfiles/fonts.sh** - Font installation
- **dotfiles/zsh.sh** - ZSH configuration
- **dotfiles/directories.sh** - Directory structure creation
- **helpers/platform.sh** - Platform detection

These scripts support both interactive and non-interactive mode via `NON_INTERACTIVE` environment variable.

## Configuration

### Fedora (config.json)

````json
{
  "system": { "hostname": "fedora-laptop" },
  "git": { "user_name": "Your Name", "user_email": "your@email.com" },
  "hardware": {
    "asus": { "auto_detect": true },
    "nvidia": { "auto_detect": true, "prefer_open_driver": true }
  }
}
#Fedoraecho "neofetch" >> fedora/packages/basepackages

#macOS
echo"neofetch">>unix/macos/packages/brew.packagesNON_INTERACTIVE=true /fedoraNON_INTERACTIVE=true /macossetupNON_INTERACTIVE=true /fedoraNON_INTERACTIVE=true /macossetup```

PackageThen## Features

### Common (Both Platforms)

- **Git and SSH** - ed25519 keys, signing key, GitHub integration
- **NextDNS** - DNS configuration and management
- **Rust** - Rustup toolchain and cargo tools
- **Dotfiles** - GNU Stow deployment, fonts, ZSH with zgenom
- **Non-Interactive Mode** - Full automation support for CI/CD

### Fedora-Specific

- DNF optimization and repository management (RPM Fusion, COPR, Terra)
- Flatpak applications from Flathub
- Hardware support (ASUS laptops, NVIDIA drivers)
- Performance tuning (zram, fstrim, systemd-oomd)
- System services (PostgreSQL, Redis, Docker)
- Firmware updates and Secure Boot support
- Multimedia codecs and hardware acceleration
- Bloatware removal

### macOS-Specific

- Homebrew installation and management
- Homebrew packages (CLI tools)
- Homebrew Cask (GUI applications)
- Xcode Command Line Tools validation
- System hostname configuration

## Structure

```
.
├── ARCHITECTURE.yml      # Complete architecture documentation
├── README.md             # This file
├── home/                 # Dotfiles (GNU Stow packages)
│   ├── config/          # Application configs
│   ├── git/             # Git configuration
│   ├── ssh/             # SSH configuration
│   ├── zsh/             # ZSH configuration
│   └── local/           # Local binaries
├── fonts/                # Font files
└── unix/
    ├── common/          # Cross-platform scripts
    │   ├── config/      # git.sh, nextdns.sh, rust.sh
    │   ├── dotfiles/    # directories.sh, stow.sh, fonts.sh, zsh.sh
    │   └── helpers/     # platform.sh
    ├── fedora/          # Fedora setup
    │   ├── fedora-setup
    │   ├── config.json
    │   ├── packages/
    │   └── install/
    └── macos/           # macOS setup
        ├── macos-setup
        ├── config.json
        ├── packages/
        └── install/
```

## Configuration

Both platforms use `config.json` for configuration:

### Fedora

```json
{
  "system": { "hostname": "fedora-laptop" },
  "git": {
    "user_name": "Your Name",
    "user_email": "your@email.com"
  },
  "nextdns": { "config_id": "" },
  "rust": {
    "tools": ["bat", "eza", "ripgrep", "fd-find", "zoxide", "starship"]
  },
  "hardware": {
    "asus": { "auto_detect": true },
    "nvidia": { "auto_detect": true, "prefer_open_driver": true }
  }
}
```

### macOS

```json
{
  "system": { "hostname": "pixmac" },
  "git": {
    "user_name": "Your Name",
    "user_email": "your@email.com"
  },
  "nextdns": { "config_id": "" },
  "rust": {
    "tools": ["bat", "eza", "ripgrep", "fd-find", "zoxide", "starship"]
  }
}
```

## Package Lists

Plain text files (one per line, `#` for comments):

**Fedora** (`unix/fedora/packages/`):
- `base.packages` - Core utilities
- `development.packages` - Dev tools
- `tools.packages` - User apps
- `system.packages` - System libraries
- `flatpak.packages` - Flatpak apps

**macOS** (`unix/macos/packages/`):
- `brew.packages` - CLI tools
- `cask.packages` - GUI apps

## Usage

### Full Setup
re-runsetup(idempotent - safe to re-run).
### Python Setup (config.toml)
###Post-Installation1.Logout/loginfor group changes
2. Add SSH key to GitHub `cat ~/.ssh/id_ed25519.pub`
3. Reload shell: `exec zsh`##Documentation-[ARCHITECTURE.yml](ARCHITECTURE.yml)** - Complete system documentation
- **[unix/fedora/README.md](unix/fedora/README.md)** - Fedora details
- **[unix/macos/README.md](unix/macos/README.md)** - macOS details##LicenseMIT License
````
