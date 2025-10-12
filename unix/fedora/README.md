# omaforge - Fedora

Automated Fedora system setup.

## Quick Start

```bash
cd ~/Dev/.configs/unix/fedora
./fedora-setup
```

## Configuration

Edit `config.json`:

```json
{
  "system": { "hostname": "fedora-laptop" },
  "git": {
    "user_name": "Your Name",
    "user_email": "your@email.com"
  },
  "rust": {
    "tools": ["bat", "eza", "ripgrep", "zoxide", "starship"]
  }
}
```

## Package Management

### Interactive

```bash
./bin/omaforge-pkg-manage
```

Add, remove, search packages with availability checking.

### Manual

```bash
echo "fastfetch" >> packages/base.packages
./fedora-setup
```

### Package Lists

- `base.packages` - Core utilities
- `development.packages` - Dev tools
- `tools.packages` - User applications
- `system.packages` - System libraries
- `flatpak.packages` - Flatpak apps

## Web Applications

Installed by default:

- **Twitter (X)** - Standard
- **ChatGPT** - Incognito mode
- **Grok** - Incognito mode

### Install Custom

```bash
./bin/omaforge-webapp-install "App Name" "https://example.com" "https://example.com/icon.png"

# Incognito mode
./bin/omaforge-webapp-install "App" "https://example.com" "icon.png" \
  "omaforge-launch-browser --private https://example.com/"
```

### Remove

```bash
./bin/omaforge-webapp-remove           # Interactive
./bin/omaforgeomaforge-webapp-remove ChatGPT   # Specific
./bin/omaforgeomaforge-webapp-remove all       # All
```

## What's Installed

- DNF optimization and system updates
- Repositories (RPM Fusion, COPR, Terra)
- Packages (DNF, Flatpak, Rust)
- Web apps (Twitter, ChatGPT, Grok)
- Hardware support (ASUS, NVIDIA)
- Performance tuning (zram, fstrim)
- Git/SSH, NextDNS, dotfiles, ZSH
- Services (PostgreSQL, Redis, Docker)

## Post-Install

1. Logout/login for group changes (docker, etc.)
2. Reboot if NVIDIA drivers were installed
3. Add SSH key to GitHub:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
4. Reload shell:
   ```bash
   exec zsh
   ```

## Troubleshooting

### Package install fails

```bash
dnf repolist
dnf makecache
```

### Git config issues

```bash
git config --list
ls -la ~/.ssh/
```

### Services don't start

```bash
systemctl status service-name
journalctl -u service-name
```

## Notes

- All scripts are idempotent (safe to re-run)
- Uses shared scripts from `unix/common/`
- See [main README](../../README.md) for overview
