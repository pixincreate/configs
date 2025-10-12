# Fedora Setup

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

## Package Lists

Plain text files in `packages/` (one per line, `#` for comments):

- `base.packages` - Core utilities
- `development.packages` - Dev tools
- `tools.packages` - User apps
- `system.packages` - System libraries
- `flatpak.packages` - Flatpak apps

## Adding Packages

```bash
# Add DNF package
echo "neofetch" >> packages/base.packages

# Add Flatpak app
echo "org.mozilla.firefox" >> packages/flatpak.packages

# Run setup (idempotent - safe to re-run)
./fedora-setup
```

## What It Does

- DNF optimization and system updates
- Repository setup (RPM Fusion, COPR, external)
- Package installation (DNF, Flatpak, Rust)
- Hardware support (ASUS, NVIDIA)
- Performance tuning (zram, fstrim)
- Git/SSH, NextDNS, dotfiles, ZSH
- System services (PostgreSQL, Redis, Docker)

## Post-Installation

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

## Troubleshooting

### Package install fails

```bash
# Verify repositories
dnf repolist

# Refresh cache
dnf makecache
```

### Git config issues

```bash
# Check Git config
git config --list

# Check SSH keys
ls -la ~/.ssh/
```

### Services don't start

```bash
# Check service status
systemctl status service-name

# View logs
journalctl -u service-name
```

## Notes

- All scripts are idempotent (safe to re-run)
- Uses common scripts from `unix/common/`
