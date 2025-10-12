# Omaforge

Dotfiles and automated system setup for Fedora Linux and macOS.

```text
 ▄██████▄    ▄▄▄▄███▄▄▄▄      ▄████████    ▄████████  ▄██████▄     ▄████████    ▄██████▄     ▄████████
███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███   ███    ███ ███    ███   ███    ███   ███    ███   ███    ███
███    ███ ███   ███   ███   ███    ███   ███    █▀  ███    ███   ███    ███   ███    █▀    ███    █▀
███    ███ ███   ███   ███   ███    ███  ▄███▄▄▄     ███    ███  ▄███▄▄▄▄██▀  ▄███         ▄███▄▄▄
███    ███ ███   ███   ███ ▀███████████ ▀▀███▀▀▀     ███    ███ ▀▀███▀▀▀▀▀   ▀▀███ ████▄  ▀▀███▀▀▀
███    ███ ███   ███   ███   ███    ███   ███        ███    ███ ▀███████████   ███    ███   ███    █▄
███    ███ ███   ███   ███   ███    ███   ███        ███    ███   ███    ███   ███    ███   ███    ███
 ▀██████▀   ▀█   ███   █▀    ███    █▀    ███         ▀██████▀    ███    ███   ████████▀    ██████████
                                                                  ███    ███
```

## Quick Start

### One-line Installer

```bash
curl -fsSL https://raw.githubusercontent.com/pixincreate/configs/main/unix/setup | bash
```

The installer automatically:

- Detects your platform (Fedora or macOS)
- Clones the repository to `~/Dev/.configs`
- Runs the appropriate setup script

### Manual Installation

#### Fedora

```bash
git clone --recurse-submodules https://github.com/pixincreate/configs.git ~/Dev/.configs
cd ~/Dev/.configs/unix/fedora
./fedora-setup
```

#### macOS

```bash
git clone --recurse-submodules https://github.com/pixincreate/configs.git ~/Dev/.configs
cd ~/Dev/.configs/unix/macos
./macos-setup
```

## Features

### Common (Both Platforms)

- **Git & SSH**: ed25519 keys with automatic configuration
- **Shell**: ZSH with zgenom plugin manager
- **Dotfiles**: GNU Stow for symlink management
- **Fonts**: Nerd Fonts and custom fonts
- **Rust**: Rustup with configurable cargo tools
- **NextDNS**: Automated DNS configuration

### Fedora-Specific

- **Package Management**: DNF optimization, Flatpak, Rust tools
- **Repositories**: RPM Fusion, COPR, Terra
- **Web Applications**: Twitter, ChatGPT (incognito), Grok (incognito)
- **Hardware Support**: ASUS laptops, NVIDIA drivers
- **Performance**: zram, fstrim, systemd-oomd
- **Services**: PostgreSQL, Redis, Docker
- **Security**: Firmware updates, Secure Boot

### macOS-Specific

- **Package Management**: Homebrew, Cask, Rust tools
- **Applications**: CLI tools and GUI applications
- **System**: Hostname and system preferences

## Package Management

### Interactive Package Manager

```bash
# Fedora
cd ~/Dev/.configs/unix/fedora
./bin/omaforge-pkg-manage

# macOS
cd ~/Dev/.configs/unix/macos
./bin/omaforge-pkg-manage
```

Features:

- Add packages with availability checking
- Remove packages
- Search repositories
- List installed packages

### Manual Package Management

Add packages to plain text files:

```bash
# Fedora
echo "neofetch" >> unix/fedora/packages/base.packages

# macOS
echo "neofetch" >> unix/macos/packages/brew.packages
```

## Web Applications (Fedora)

Install web apps that appear in your application menu:

```bash
./bin/omaforge-webapp-install "App Name" "https://example.com" "https://example.com/icon.png"

# With incognito mode
./bin/omaforge-webapp-install "App" "https://example.com" "icon.png" \
  "omaforge-launch-browser --private https://example.com/"
```

Pre-installed web apps:

- **Twitter (X)** - Standard mode
- **ChatGPT** - Incognito mode
- **Grok** - Incognito mode

Remove web apps:

```bash
./bin/omaforge-webapp-remove           # Interactive
./bin/omaforge-webapp-remove ChatGPT   # Specific app
```

## Reset Components

If you need to reset or re-run specific components:

```bash
# Fedora
./bin/omaforge-reset

# macOS
./bin/omaforge-reset
```

Interactive menu to reset:

- ZSH configuration
- Dotfiles (stow)
- Fonts
- Git & SSH
- Services (Fedora)
- Hardware (Fedora)
- Web apps (Fedora)
- Rust tools

## Project Structure

```
.
├── README.md
├── LICENSE
├── home/                   # Dotfiles managed by GNU Stow
│   ├── config/            # Application configs (~/.config/)
│   ├── git/               # Git configuration
│   ├── ssh/               # SSH configuration
│   ├── zsh/               # ZSH with zgenom
│   ├── local/             # Local binaries
│   └── Pictures/          # Wallpapers
├── fonts/                  # Font files
└── unix/
    ├── setup              # One-line installer
    ├── common/            # Cross-platform scripts
    │   ├── config/       # git.sh, nextdns.sh, rust.sh
    │   ├── dotfiles/     # directories.sh, stow.sh, fonts.sh, zsh.sh
    │   └── helpers/      # platform.sh
    ├── fedora/
    │   ├── fedora-setup
    │   ├── config.json
    │   ├── bin/          # omaforge-* utilities
    │   ├── install/      # Modular installation scripts
    │   └── packages/     # Plain text package lists
    └── macos/
        ├── macos-setup
        ├── config.json
        ├── bin/          # omaforge-* utilities
        ├── install/      # Modular installation scripts
        └── packages/     # Plain text package lists
```

## Configuration

Each platform has a `config.json` for declarative configuration:

```json
{
  "system": {
    "hostname": "your-hostname"
  },
  "git": {
    "user_name": "Your Name",
    "user_email": "your@email.com"
  },
  "nextdns": {
    "config_id": ""
  },
  "rust": {
    "tools": ["bat", "eza", "ripgrep", "fd-find", "zoxide", "starship"]
  },
  "hardware": {
    "asus": { "auto_detect": true },
    "nvidia": { "auto_detect": true, "prefer_open_driver": true }
  }
}
```

Package lists are plain text files (one per line, `#` for comments).

## Documentation

- **[Fedora Setup Guide](unix/fedora/README.md)** - Fedora-specific documentation
- **[macOS Setup Guide](unix/macos/README.md)** - macOS-specific documentation

## Post-Installation

### Fedora

1. **Logout/login** - Group changes take effect (docker, etc.)
2. **Reboot** - If NVIDIA drivers were installed
3. **Add SSH key to GitHub:**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
4. **Reload shell:**
   ```bash
   exec zsh
   ```

### macOS

1. **Add SSH key to GitHub:**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
2. **Reload shell:**
   ```bash
   exec zsh
   ```

## Utilities

### Fedora

- `omaforge-pkg-manage` - Interactive package manager
- `omaforge-webapp-install` - Install web applications
- `omaforge-webapp-remove` - Remove web applications
- `omaforge-launch-browser` - Launch browser (supports Zen, Brave, Helium)
- `omaforge-launch-webapp` - Launch web app in app mode
- `omaforge-reset` - Reset/re-run specific components

### macOS

- `omaforge-pkg-manage` - Interactive package manager
- `omaforge-reset` - Reset/re-run specific components

## Architecture

- **Modular**: Small, single-purpose scripts organized by phase
- **Declarative**: JSON-based configuration
- **Idempotent**: Safe to run multiple times
- **Cross-platform**: Shared common scripts where possible

Installation phases:

1. **Preflight** - System checks and validation
2. **Repositories** - Add package repositories
3. **Packaging** - Install packages (DNF, Flatpak, Homebrew, Rust)
4. **Config** - System configuration (Git, SSH, services, hardware)
5. **Dotfiles** - Deploy dotfiles and configure shell
6. **Post-install** - Cleanup and final steps

## Contributing

This is a personal configuration repository, but feel free to:

- Fork and customize for your own use
- Report issues or suggest improvements
- Submit pull requests for bug fixes

## License

GPL 3.0 License
