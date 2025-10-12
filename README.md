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

### Fedora

```bash
git clone --recurse-submodules https://github.com/pixincreate/configs.git ~/Dev/.configs
cd ~/Dev/.configs/unix/fedora
./fedora-setup
```

### macOS

```bash
git clone --recurse-submodules https://github.com/pixincreate/configs.git ~/Dev/.configs
cd ~/Dev/.configs/unix/macos
./macos-setup
```

## Features

### Common (Both Platforms)

- Git and SSH with ed25519 keys
- NextDNS configuration
- Rust toolchain (rustup + cargo tools)
- Dotfiles via GNU Stow
- Font installation
- ZSH with zgenom

### Fedora

- DNF optimization
- Repositories (RPM Fusion, COPR, Terra)
- Flatpak from Flathub
- Web apps (Twitter, ChatGPT, Grok)
- Hardware (ASUS, NVIDIA)
- Performance (zram, fstrim)
- Services (PostgreSQL, Redis, Docker)

### macOS

- Homebrew setup
- CLI tools and GUI apps
- System configuration

## Structure

```
.
├── home/           # Dotfiles (GNU Stow)
├── fonts/          # Font files
└── unix/
    ├── common/    # Cross-platform scripts
    ├── fedora/    # Fedora setup
    └── macos/     # macOS setup
```

## Configuration

Edit `config.json` in the platform directory:

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

## Documentation

- [Fedora Setup](unix/fedora/README.md)
- [macOS Setup](unix/macos/README.md)

## License

GPL 3.0 License
