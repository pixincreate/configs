# Personal Development Environment

Dotfiles and automated system setup for Fedora Linux and macOS.


                                        
 ▄██████▄    ▄▄▄▄███▄▄▄▄      ▄████████    ▄████████  ▄██████▄     ▄████████    ▄██████▄     ▄████████ 
███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███   ███    ███ ███    ███   ███    ███   ███    ███   ███    ███ 
███    ███ ███   ███   ███   ███    ███   ███    █▀  ███    ███   ███    ███   ███    █▀    ███    █▀  
███    ███ ███   ███   ███   ███    ███  ▄███▄▄▄     ███    ███  ▄███▄▄▄▄██▀  ▄███         ▄███▄▄▄     
███    ███ ███   ███   ███ ▀███████████ ▀▀███▀▀▀     ███    ███ ▀▀███▀▀▀▀▀   ▀▀███ ████▄  ▀▀███▀▀▀     
███    ███ ███   ███   ███   ███    ███   ███        ███    ███ ▀███████████   ███    ███   ███    █▄  
███    ███ ███   ███   ███   ███    ███   ███        ███    ███   ███    ███   ███    ███   ███    ███ 
 ▀██████▀   ▀█   ███   █▀    ███    █▀    ███         ▀██████▀    ███    ███   ████████▀    ██████████ 
                                                                  ███    ███                           


## Quick Start

### Fedora Linux

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

## What's Included

### Common (Both Platforms)

- Git and SSH setup with ed25519 keys
- NextDNS configuration
- Rust toolchain and cargo tools
- Dotfiles deployment via GNU Stow
- Font installation
- ZSH configuration

### Fedora-Specific

- DNF optimization and repository management
- Flatpak applications
- Hardware support (ASUS, NVIDIA)
- Performance tuning
- System services (PostgreSQL, Redis, Docker)

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

## Documentation

- [unix/fedora/README.md](unix/fedora/README.md) - Fedora platform details
- [unix/macos/README.md](unix/macos/README.md) - macOS platform details

## License

GPL 3.0 License
